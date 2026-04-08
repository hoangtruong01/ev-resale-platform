import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  AuctionStatus,
  NotificationType,
  UserRole,
  AuctionItemType,
} from '@prisma/client';
import { CreateAuctionDto, SearchAuctionDto, PlaceBidDto } from './dto';
import { ContentModerationService } from '../moderation/content-moderation.service';
import {
  APPROVAL_STATUS,
  ApprovalStatusValue,
} from '../common/approval-status.constant';
import { NotificationsService } from '../notifications/notifications.service';
import {
  ALLOWED_AUCTION_ITEM_TYPES,
  AllowedAuctionItemType,
  MAX_AUCTION_PRICE,
} from './auction.constants';
import { MailService } from '../mail/mail.service';
import { SmsService } from '../sms/sms.service';

@Injectable()
export class AuctionsService {
  private readonly logger = new Logger(AuctionsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ContentModerationService,
    private readonly notificationsService: NotificationsService,
    private readonly mailService: MailService,
    private readonly smsService: SmsService,
  ) {}

  private async createNotificationSafely(
    payload: Parameters<NotificationsService['create']>[0],
  ) {
    try {
      await this.notificationsService.create(payload);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown notification error';
      this.logger.warn(`Failed to send notification: ${message}`);
    }
  }

  private async notifyAuctionSubmission(auction: {
    id: string;
    title: string;
    sellerId: string;
    seller?: {
      fullName?: string | null;
      email?: string | null;
    } | null;
    startTime: Date;
    endTime: Date;
    startingPrice: any;
    itemType: AuctionItemType;
    lotQuantity: number;
  }) {
    let approvalRecipients: Array<{ id: string }> = [];

    try {
      approvalRecipients = await this.prisma.user.findMany({
        where: {
          role: { in: [UserRole.ADMIN, UserRole.MODERATOR] },
          isActive: true,
        },
        select: { id: true },
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown admin lookup error';
      this.logger.warn(
        `Failed to load approvers for auction ${auction.id}: ${message}`,
      );
      approvalRecipients = [];
    }

    const normalizeValue = (value: unknown): string | undefined => {
      if (value === null || value === undefined) {
        return undefined;
      }

      if (typeof value === 'object') {
        const maybeToString = (value as { toString?: () => string }).toString;
        if (typeof maybeToString === 'function') {
          return maybeToString.call(value);
        }
      }

      return String(value);
    };

    const sellerName =
      auction.seller?.fullName?.trim() ||
      auction.seller?.email?.trim() ||
      'Người bán';

    const metadata = {
      auctionId: auction.id,
      sellerId: auction.sellerId,
      startTime: auction.startTime.toISOString(),
      endTime: auction.endTime.toISOString(),
      startingPrice: normalizeValue(auction.startingPrice),
      itemType: auction.itemType,
      lotQuantity: auction.lotQuantity,
    } as Record<string, unknown>;

    const adminNotifications = approvalRecipients
      .filter((recipient) => recipient.id !== auction.sellerId)
      .map((recipient) =>
        this.createNotificationSafely({
          userId: recipient.id,
          title: 'Phiên đấu giá mới chờ duyệt',
          message: `Người dùng ${sellerName} vừa tạo phiên đấu giá "${auction.title}" cần kiểm duyệt.`,
          type: NotificationType.SYSTEM_ALERT,
          metadata,
        }),
      );

    await Promise.all([
      ...adminNotifications,
      this.createNotificationSafely({
        userId: auction.sellerId,
        title: 'Phiên đấu giá đang chờ duyệt',
        message: `Phiên đấu giá "${auction.title}" của bạn đã được gửi tới đội ngũ kiểm duyệt.`,
        type: NotificationType.SYSTEM_ALERT,
        metadata,
      }),
    ]);
  }

  async findAll(
    query: SearchAuctionDto,
    options: { includeAllStatuses?: boolean } = {},
  ) {
    const {
      search,
      status,
      minPrice,
      maxPrice,
      itemType,
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      approvalStatus,
    } = query;

    const toNumber = (value: unknown): number | null => {
      if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
      }
      if (typeof value === 'string' && value.trim() !== '') {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
      }
      return null;
    };

    const pageNumber = Math.max(1, toNumber(page) ?? 1);
    const limitNumber = Math.min(100, Math.max(1, toNumber(limit) ?? 10));
    const minPriceNumber = toNumber(minPrice ?? undefined);
    const maxPriceNumber = toNumber(maxPrice ?? undefined);

    const allowedSortFields = [
      'createdAt',
      'startTime',
      'endTime',
      'currentPrice',
    ];
    const sortField = allowedSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const sortDirection = sortOrder === 'asc' ? 'asc' : 'desc';

    const where: any = {};

    const resolvedApprovalStatus =
      approvalStatus &&
      Object.values(APPROVAL_STATUS).includes(
        approvalStatus as ApprovalStatusValue,
      )
        ? approvalStatus
        : undefined;

    if (resolvedApprovalStatus) {
      where.approvalStatus = resolvedApprovalStatus;
    } else if (!options.includeAllStatuses) {
      where.approvalStatus = APPROVAL_STATUS.APPROVED;
    }

    // Build search conditions
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status) where.status = status;

    // Price range
    if (minPriceNumber !== null || maxPriceNumber !== null) {
      where.startingPrice = {};
      if (minPriceNumber !== null) where.startingPrice.gte = minPriceNumber;
      if (maxPriceNumber !== null) where.startingPrice.lte = maxPriceNumber;
    }

    // Item type filter
    if (itemType) {
      const normalizedType = itemType.toUpperCase();
      if (
        ALLOWED_AUCTION_ITEM_TYPES.includes(
          normalizedType as AllowedAuctionItemType,
        )
      ) {
        where.itemType = normalizedType;
      }
    }

    const skip = (pageNumber - 1) * limitNumber;
    const orderBy = { [sortField]: sortDirection } as const;

    const [auctions, total] = await Promise.all([
      this.prisma.auction.findMany({
        where,
        skip,
        take: limitNumber,
        orderBy,
        include: {
          seller: {
            select: {
              id: true,
              fullName: true,
              email: true,
            },
          },
          bids: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            include: {
              bidder: {
                select: {
                  id: true,
                  fullName: true,
                },
              },
            },
          },
          media: {
            orderBy: { sortOrder: 'asc' },
          },
          _count: {
            select: {
              bids: true,
            },
          },
        },
      }),
      this.prisma.auction.count({ where }),
    ]);

    return {
      data: auctions,
      pagination: {
        total,
        page: pageNumber,
        limit: limitNumber,
        totalPages: Math.ceil(total / limitNumber),
      },
    };
  }

  async findOne(id: string) {
    const auction = await this.prisma.auction.findUnique({
      where: { id },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            createdAt: true,
          },
        },
        media: {
          orderBy: { sortOrder: 'asc' },
        },
        bids: {
          orderBy: { createdAt: 'desc' },
          include: {
            bidder: {
              select: {
                id: true,
                fullName: true,
                avatar: true,
              },
            },
          },
        },
        _count: {
          select: {
            bids: true,
          },
        },
      },
    });

    if (!auction) {
      throw new NotFoundException(`Auction with ID ${id} not found`);
    }

    return auction;
  }

  async create(createAuctionDto: CreateAuctionDto, sellerId: string) {
    const {
      title,
      description,
      startingPrice,
      bidStep,
      buyNowPrice,
      startTime,
      endTime,
      itemType,
      lotQuantity,
      itemBrand,
      itemModel,
      itemYear,
      itemMileage,
      itemCapacity,
      itemCondition,
      location,
      contactPhone,
      contactEmail,
      imageUrls,
    } = createAuctionDto;

    const parsedStart = new Date(startTime);
    const parsedEnd = new Date(endTime);

    const exceedsMax = (value: number | null | undefined) =>
      typeof value === 'number' && value > MAX_AUCTION_PRICE;

    if (
      exceedsMax(startingPrice) ||
      exceedsMax(bidStep) ||
      exceedsMax(buyNowPrice ?? undefined)
    ) {
      throw new BadRequestException(
        `Giá trị tiền tệ không được vượt quá ${MAX_AUCTION_PRICE.toLocaleString('vi-VN')} VND`,
      );
    }

    if (
      Number.isNaN(parsedStart.getTime()) ||
      Number.isNaN(parsedEnd.getTime())
    ) {
      throw new BadRequestException('Invalid start or end time');
    }

    if (parsedStart >= parsedEnd) {
      throw new BadRequestException('End time must be after start time');
    }

    if (parsedStart < new Date()) {
      throw new BadRequestException('Start time cannot be in the past');
    }

    if (
      itemCondition !== undefined &&
      (itemCondition < 0 || itemCondition > 100)
    ) {
      throw new BadRequestException('Item condition must be between 0 and 100');
    }

    if (buyNowPrice !== undefined && buyNowPrice !== null) {
      if (Number(buyNowPrice) <= Number(startingPrice)) {
        throw new BadRequestException(
          'Buy now price must be greater than starting price',
        );
      }
    }

    const moderationResult = await this.moderation.analyzeAuction({
      title,
      description,
      startingPrice,
      itemType,
      itemBrand,
      itemModel,
      itemCapacity,
    });

    const auction = await this.prisma.auction.create({
      data: {
        title: title.trim(),
        description: description?.trim() || null,
        startingPrice,
        currentPrice: startingPrice,
        bidStep,
        buyNowPrice: buyNowPrice ?? null,
        startTime: parsedStart,
        endTime: parsedEnd,
        itemType,
        lotQuantity,
        itemBrand: itemBrand?.trim() || null,
        itemModel: itemModel?.trim() || null,
        itemYear: itemYear ?? null,
        itemMileage: itemMileage ?? null,
        itemCapacity: itemCapacity ?? null,
        itemCondition: itemCondition ?? null,
        location: location.trim(),
        contactPhone: contactPhone.trim(),
        contactEmail: contactEmail?.trim() || null,
        sellerId,
        status: AuctionStatus.PENDING,
        approvalStatus: APPROVAL_STATUS.PENDING,
        spamScore: moderationResult.score,
        spamReasons:
          moderationResult.reasons && moderationResult.reasons.length
            ? moderationResult.reasons
            : undefined,
        isSpamSuspicious: moderationResult.flagged,
        spamCheckedAt: new Date(),
        media:
          imageUrls && imageUrls.length
            ? {
                create: imageUrls.map((url, index) => ({
                  url,
                  sortOrder: index,
                })),
              }
            : undefined,
      },
      include: {
        seller: true,
        media: true,
      },
    });

    try {
      await this.notifyAuctionSubmission({
        ...auction,
        itemType: auction.itemType,
        lotQuantity: auction.lotQuantity,
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown notification error';
      this.logger.warn(
        `Failed to dispatch submission notifications for auction ${auction.id}: ${message}`,
      );
    }

    return auction;
  }

  async placeBid(
    auctionId: string,
    placeBidDto: PlaceBidDto,
    bidderId: string,
  ) {
    const { amount } = placeBidDto;
    return this.prisma.$transaction(async (tx) => {
      const auction = await tx.auction.findUnique({
        where: { id: auctionId },
        include: {
          bids: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            include: {
              bidder: { select: { id: true } },
            },
          },
        },
      });

      if (!auction) {
        throw new NotFoundException('Auction not found');
      }

      if (auction.sellerId === bidderId) {
        throw new BadRequestException('You cannot bid on your own auction');
      }

      if (auction.status !== AuctionStatus.ACTIVE) {
        throw new BadRequestException('Auction is not active');
      }

      if (new Date() > auction.endTime) {
        throw new BadRequestException('Auction has ended');
      }

      const currentPrice = Number(auction.currentPrice);
      const minBidAmount = currentPrice + Number(auction.bidStep);
      if (amount < minBidAmount) {
        throw new BadRequestException(
          `Bid must be at least ${minBidAmount} VND`,
        );
      }

      const lastBid = auction.bids[0];
      if (lastBid && lastBid.bidder.id === bidderId) {
        throw new BadRequestException('You already have the highest bid');
      }

      const updateResult = await tx.auction.updateMany({
        where: { id: auctionId, currentPrice: auction.currentPrice },
        data: { currentPrice: amount },
      });

      if (updateResult.count === 0) {
        throw new BadRequestException(
          'Another bidder just placed a higher offer. Please refresh and try again.',
        );
      }

      return tx.bid.create({
        data: {
          amount,
          bidderId,
          auctionId,
        },
        include: {
          bidder: {
            select: {
              id: true,
              fullName: true,
              avatar: true,
            },
          },
        },
      });
    });
  }

  async getBidsForAuction(auctionId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [bids, total] = await Promise.all([
      this.prisma.bid.findMany({
        where: { auctionId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          bidder: {
            select: {
              id: true,
              fullName: true,
              avatar: true,
            },
          },
        },
      }),
      this.prisma.bid.count({ where: { auctionId } }),
    ]);

    return {
      data: bids,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getMyAuctions(userId: string, query: SearchAuctionDto) {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;
    const skip = (page - 1) * limit;
    const orderBy = { [sortBy]: sortOrder };

    const [auctions, total] = await Promise.all([
      this.prisma.auction.findMany({
        where: { sellerId: userId },
        skip,
        take: limit,
        orderBy,
        include: {
          bids: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            include: {
              bidder: {
                select: {
                  id: true,
                  fullName: true,
                },
              },
            },
          },
          media: {
            orderBy: { sortOrder: 'asc' },
          },
          _count: {
            select: {
              bids: true,
            },
          },
        },
      }),
      this.prisma.auction.count({ where: { sellerId: userId } }),
    ]);

    return {
      data: auctions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getMyBids(userId: string, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [bids, total] = await Promise.all([
      this.prisma.bid.findMany({
        where: { bidderId: userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          auction: {
            include: {
              media: {
                orderBy: { sortOrder: 'asc' },
              },
              seller: {
                select: {
                  id: true,
                  fullName: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.bid.count({ where: { bidderId: userId } }),
    ]);

    return {
      data: bids,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async approve(id: string, adminId?: string, notes?: string) {
    const auction = await this.prisma.auction.findUnique({ where: { id } });

    if (!auction) {
      throw new NotFoundException(`Auction with ID ${id} not found`);
    }

    const now = new Date();
    const shouldActivate = auction.startTime <= now;

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.auction.update({
        where: { id },
        data: {
          approvalStatus: APPROVAL_STATUS.APPROVED,
          approvalNotes: notes,
          approvedAt: now,
          approvedById: adminId,
          status: shouldActivate ? AuctionStatus.ACTIVE : AuctionStatus.PENDING,
        } as any,
        include: {
          seller: true,
          media: {
            orderBy: { sortOrder: 'asc' },
          },
        },
      });

      return updated;
    });
  }

  async reject(id: string, adminId?: string, reason?: string) {
    const auction = await this.prisma.auction.findUnique({ where: { id } });

    if (!auction) {
      throw new NotFoundException(`Auction with ID ${id} not found`);
    }

    const now = new Date();

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.auction.update({
        where: { id },
        data: {
          approvalStatus: APPROVAL_STATUS.REJECTED,
          approvalNotes: reason,
          approvedAt: now,
          approvedById: adminId,
          status: AuctionStatus.CANCELLED,
        } as any,
        include: {
          seller: true,
          media: {
            orderBy: { sortOrder: 'asc' },
          },
        },
      });

      return updated;
    });
  }

  async endAuction(auctionId: string, requesterId?: string, force = false) {
    const auction = await this.prisma.auction.findUnique({
      where: { id: auctionId },
      include: {
        bids: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { bidder: true },
        },
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
          },
        },
      },
    });

    if (!auction) {
      throw new NotFoundException('Auction not found');
    }

    if (!force && requesterId && auction.sellerId !== requesterId) {
      throw new ForbiddenException('You are not allowed to end this auction');
    }

    if (auction.status !== AuctionStatus.ACTIVE) {
      throw new BadRequestException('Auction is not active');
    }

    const highestBid = auction.bids[0];

    await this.prisma.$transaction(async (tx) => {
      await tx.auction.update({
        where: { id: auctionId },
        data: { status: AuctionStatus.ENDED },
      });

      if (highestBid) {
        const transaction = await tx.transaction.create({
          data: {
            amount: highestBid.amount,
            sellerId: auction.sellerId,
            auctionId,
            status: 'PENDING',
          },
        });

        await tx.purchase.create({
          data: {
            buyerId: highestBid.bidderId,
            transactionId: transaction.id,
            status: 'PENDING',
          },
        });
      }
    });

    if (highestBid) {
      await this.createNotificationSafely({
        userId: highestBid.bidderId,
        title: 'Bạn đã thắng phiên đấu giá',
        message: `Bạn đã thắng phiên đấu giá ${auction.title} với giá ${highestBid.amount.toString()}.`,
        type: NotificationType.AUCTION_WON,
        metadata: {
          auctionId,
          amount: highestBid.amount.toString(),
          sellerId: auction.sellerId,
        },
      });

      await this.createNotificationSafely({
        userId: auction.sellerId,
        title: 'Phiên đấu giá đã có người thắng',
        message: `Phiên đấu giá ${auction.title} kết thúc với giá ${highestBid.amount.toString()}.`,
        type: NotificationType.ITEM_SOLD,
        metadata: {
          auctionId,
          buyerId: highestBid.bidderId,
          amount: highestBid.amount.toString(),
        },
      });

      if (highestBid.bidder?.email) {
        void this.mailService
          .sendMail({
            to: highestBid.bidder.email,
            subject: 'EVN Market: Ban da thang dau gia',
            text: `Ban da thang dau gia ${auction.title} voi gia ${highestBid.amount.toString()}.`,
          })
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send winner email: ${message}`);
          });
      }

      if (highestBid.bidder?.phone) {
        void this.smsService
          .sendSms(
            highestBid.bidder.phone,
            `EVN Market: Ban da thang dau gia ${auction.title}.`,
          )
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send winner SMS: ${message}`);
          });
      }

      if (auction.seller?.email) {
        void this.mailService
          .sendMail({
            to: auction.seller.email,
            subject: 'EVN Market: Dau gia da ket thuc',
            text: `Phien dau gia ${auction.title} da ket thuc voi gia ${highestBid.amount.toString()}.`,
          })
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send seller email: ${message}`);
          });
      }

      if (auction.seller?.phone) {
        void this.smsService
          .sendSms(
            auction.seller.phone,
            `EVN Market: Dau gia ${auction.title} da ket thuc.`,
          )
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send seller SMS: ${message}`);
          });
      }
    } else {
      await this.createNotificationSafely({
        userId: auction.sellerId,
        title: 'Phiên đấu giá kết thúc',
        message:
          'Phiên đấu giá của bạn đã kết thúc nhưng không có lượt đặt giá nào. Bạn có thể chỉnh sửa thông tin và tạo lại phiên mới khi sẵn sàng.',
        type: NotificationType.SYSTEM_ALERT,
        metadata: { auctionId },
      });

      if (auction.seller?.email) {
        void this.mailService
          .sendMail({
            to: auction.seller.email,
            subject: 'EVN Market: Phien dau gia khong co luot dat gia',
            text: `Phien dau gia ${auction.title} da ket thuc nhung khong co luot dat gia.`,
          })
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send no-bid email: ${message}`);
          });
      }

      if (auction.seller?.phone) {
        void this.smsService
          .sendSms(
            auction.seller.phone,
            `EVN Market: Phien dau gia ${auction.title} ket thuc, chua co dat gia.`,
          )
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send no-bid SMS: ${message}`);
          });
      }
    }

    return this.findOne(auctionId);
  }

  async activateScheduledAuctions(): Promise<number> {
    const now = new Date();

    const scheduledAuctions = await this.prisma.auction.findMany({
      where: {
        status: AuctionStatus.PENDING,
        approvalStatus: APPROVAL_STATUS.APPROVED,
        startTime: { lte: now },
      },
      select: { id: true },
    });

    if (!scheduledAuctions.length) {
      return 0;
    }

    await this.prisma.auction.updateMany({
      where: { id: { in: scheduledAuctions.map((auction) => auction.id) } },
      data: { status: AuctionStatus.ACTIVE },
    });

    return scheduledAuctions.length;
  }

  async endExpiredAuctions(): Promise<number> {
    const now = new Date();

    const expiredAuctions = await this.prisma.auction.findMany({
      where: {
        status: AuctionStatus.ACTIVE,
        endTime: { lte: now },
      },
      select: { id: true },
    });

    if (!expiredAuctions.length) {
      return 0;
    }

    let ended = 0;

    for (const auction of expiredAuctions) {
      try {
        await this.endAuction(auction.id, undefined, true);
        ended += 1;
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Unknown scheduler error';
        this.logger.warn(
          `Failed to auto-close auction ${auction.id}: ${message}`,
        );
      }
    }

    return ended;
  }

  async getStatistics() {
    const [totalAuctions, activeAuctions, endedAuctions, totalBids] =
      await Promise.all([
        this.prisma.auction.count(),
        this.prisma.auction.count({ where: { status: 'ACTIVE' } }),
        this.prisma.auction.count({ where: { status: 'ENDED' } }),
        this.prisma.bid.count(),
      ]);

    const averageBids = await this.prisma.auction.aggregate({
      _avg: { currentPrice: true },
    });

    return {
      totalAuctions,
      activeAuctions,
      endedAuctions,
      totalBids,
      averagePrice: averageBids._avg.currentPrice,
    };
  }
}
