import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBidDto, UpdateBidDto } from './dto';
import { AuctionStatus, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { MailService } from '../mail/mail.service';
import { SmsService } from '../sms/sms.service';

@Injectable()
export class BidsService {
  private readonly logger = new Logger(BidsService.name);

  constructor(
    private prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly mailService: MailService,
    private readonly smsService: SmsService,
  ) {}

  async create(createBidDto: CreateBidDto) {
    const { auctionId, bidderId, amount } = createBidDto;

    // Check if the auction exists and is active
    const auction = await this.prisma.auction.findUnique({
      where: { id: auctionId },
      include: {
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
      throw new NotFoundException('Không tìm thấy cuộc đấu giá');
    }

    if (auction.status !== AuctionStatus.ACTIVE) {
      throw new BadRequestException('Cuộc đấu giá không còn hoạt động');
    }

    // Check if auction has ended
    if (auction.endTime < new Date()) {
      throw new BadRequestException('Cuộc đấu giá đã kết thúc');
    }

    // Check if the bid amount is higher than the current price
    const currentPrice = Number(auction.currentPrice);
    const bidStep = Number(auction.bidStep);

    if (amount <= currentPrice) {
      throw new BadRequestException(
        `Giá đặt phải cao hơn giá hiện tại (${currentPrice})`,
      );
    }

    // Check if the bid meets the minimum bid step
    if (amount < currentPrice + bidStep) {
      throw new BadRequestException(
        `Giá đặt phải cao hơn giá hiện tại ít nhất ${bidStep}`,
      );
    }

    // Check if the bidder exists
    const bidder = await this.prisma.user.findUnique({
      where: { id: bidderId },
    });

    if (!bidder) {
      throw new NotFoundException('Không tìm thấy người đặt giá');
    }

    // Check if the bidder is not the seller
    if (bidderId === auction.sellerId) {
      throw new BadRequestException(
        'Người bán không thể đặt giá trong cuộc đấu giá của mình',
      );
    }

    // Create the bid and update the current price of the auction
    const bid = await this.prisma.$transaction(async (prisma) => {
      // Create the bid
      const newBid = await prisma.bid.create({
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
              email: true,
              avatar: true,
            },
          },
          auction: true,
        },
      });

      // Update the current price of the auction
      await prisma.auction.update({
        where: { id: auctionId },
        data: { currentPrice: amount },
      });

      return newBid;
    });

    if (auction.sellerId) {
      try {
        await this.notificationsService.create({
          userId: auction.sellerId,
          title: 'Có lượt đặt giá mới',
          message: `Phiên đấu giá ${auction.title} vừa nhận lượt đặt giá mới.`,
          type: NotificationType.BID_PLACED,
          metadata: {
            auctionId,
            amount: amount.toString(),
            bidderId,
          },
        });
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Unknown error';
        this.logger.warn(`Failed to notify seller: ${message}`);
      }

      if (auction.seller?.email) {
        void this.mailService
          .sendMail({
            to: auction.seller.email,
            subject: 'EVN Market: Có lượt đặt giá mới',
            text: `Phiên đấu giá ${auction.title} vừa có lượt đặt giá mới.`,
          })
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send bid email: ${message}`);
          });
      }

      if (auction.seller?.phone) {
        void this.smsService
          .sendSms(
            auction.seller.phone,
            `EVN Market: Co luot dat gia moi cho ${auction.title}.`,
          )
          .catch((err) => {
            const message =
              err instanceof Error ? err.message : 'Unknown error';
            this.logger.warn(`Failed to send bid SMS: ${message}`);
          });
      }
    }

    return bid;
  }

  async findAll(page = 1, limit = 10, auctionId?: string) {
    const skip = (page - 1) * limit;

    // Build filter conditions
    const where: any = {};

    if (auctionId) {
      where.auctionId = auctionId;
    }

    // Get total count for pagination
    const totalCount = await this.prisma.bid.count({ where });

    // Get bids with pagination
    const bids = await this.prisma.bid.findMany({
      skip,
      take: limit,
      where,
      include: {
        bidder: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        auction: {
          select: {
            id: true,
            title: true,
            currentPrice: true,
            endTime: true,
            status: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      data: bids,
      meta: {
        totalCount,
        page,
        limit,
        pageCount: Math.ceil(totalCount / limit),
      },
    };
  }

  async findOne(id: string) {
    const bid = await this.prisma.bid.findUnique({
      where: { id },
      include: {
        bidder: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        auction: {
          include: {
            seller: {
              select: {
                id: true,
                fullName: true,
                email: true,
                avatar: true,
              },
            },
          },
        },
      },
    });

    if (!bid) {
      throw new NotFoundException('Không tìm thấy lượt đặt giá');
    }

    return bid;
  }

  async update(id: string, updateBidDto: UpdateBidDto) {
    // In real auctions, bids typically cannot be updated
    // This functionality might be limited to admins for correcting errors

    // Check if the bid exists
    const bid = await this.prisma.bid.findUnique({
      where: { id },
      include: {
        auction: true,
      },
    });

    if (!bid) {
      throw new NotFoundException('Không tìm thấy lượt đặt giá');
    }

    // Check if the auction is still active
    if (bid.auction.status !== AuctionStatus.ACTIVE) {
      throw new BadRequestException(
        'Không thể cập nhật lượt đặt giá cho cuộc đấu giá không còn hoạt động',
      );
    }

    // Check if the auction has ended
    if (bid.auction.endTime < new Date()) {
      throw new BadRequestException(
        'Không thể cập nhật lượt đặt giá cho cuộc đấu giá đã kết thúc',
      );
    }

    // Check if this is the highest bid
    const highestBid = await this.prisma.bid.findFirst({
      where: { auctionId: bid.auctionId },
      orderBy: { amount: 'desc' },
    });

    if (highestBid && highestBid.id !== id) {
      throw new BadRequestException(
        'Chỉ có thể cập nhật lượt đặt giá cao nhất',
      );
    }

    // Update the bid and the auction's current price if needed
    return this.prisma.$transaction(async (prisma) => {
      const updatedBid = await prisma.bid.update({
        where: { id },
        data: updateBidDto,
        include: {
          bidder: {
            select: {
              id: true,
              fullName: true,
              email: true,
              avatar: true,
            },
          },
          auction: true,
        },
      });

      // If the amount was updated, also update the auction's current price
      if (updateBidDto.amount) {
        await prisma.auction.update({
          where: { id: bid.auctionId },
          data: { currentPrice: updateBidDto.amount },
        });
      }

      return updatedBid;
    });
  }

  async remove(id: string) {
    // In real auctions, bids typically cannot be deleted
    // This functionality might be limited to admins for correcting errors

    // Check if the bid exists
    const bid = await this.prisma.bid.findUnique({
      where: { id },
      include: {
        auction: true,
      },
    });

    if (!bid) {
      throw new NotFoundException('Không tìm thấy lượt đặt giá');
    }

    // Check if the auction is still active
    if (bid.auction.status !== AuctionStatus.ACTIVE) {
      throw new BadRequestException(
        'Không thể xóa lượt đặt giá cho cuộc đấu giá không còn hoạt động',
      );
    }

    // Check if the auction has ended
    if (bid.auction.endTime < new Date()) {
      throw new BadRequestException(
        'Không thể xóa lượt đặt giá cho cuộc đấu giá đã kết thúc',
      );
    }

    // Check if this is the highest bid
    const highestBid = await this.prisma.bid.findFirst({
      where: { auctionId: bid.auctionId },
      orderBy: { amount: 'desc' },
    });

    // If deleting the highest bid, we need to update the auction's current price
    if (highestBid && highestBid.id === id) {
      // Find the second highest bid
      const secondHighestBid = await this.prisma.bid.findFirst({
        where: {
          auctionId: bid.auctionId,
          id: { not: id },
        },
        orderBy: { amount: 'desc' },
      });

      // Delete the bid and update the auction's current price
      await this.prisma.$transaction(async (prisma) => {
        await prisma.bid.delete({ where: { id } });

        // If there is a second highest bid, set that as the current price
        // Otherwise, revert to starting price
        await prisma.auction.update({
          where: { id: bid.auctionId },
          data: {
            currentPrice: secondHighestBid
              ? secondHighestBid.amount
              : bid.auction.startingPrice,
          },
        });
      });
    } else {
      // If it's not the highest bid, just delete it
      await this.prisma.bid.delete({ where: { id } });
    }

    return { message: 'Lượt đặt giá đã được xóa thành công' };
  }

  // Additional methods

  async findByAuction(auctionId: string, page = 1, limit = 10) {
    return this.findAll(page, limit, auctionId);
  }

  async findByBidder(bidderId: string, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const where = { bidderId };

    // Get total count for pagination
    const totalCount = await this.prisma.bid.count({ where });

    // Get bids with pagination
    const bids = await this.prisma.bid.findMany({
      skip,
      take: limit,
      where,
      include: {
        bidder: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        auction: {
          include: {
            seller: {
              select: {
                id: true,
                fullName: true,
                email: true,
                avatar: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      data: bids,
      meta: {
        totalCount,
        page,
        limit,
        pageCount: Math.ceil(totalCount / limit),
      },
    };
  }

  async getHighestBidForAuction(auctionId: string) {
    const highestBid = await this.prisma.bid.findFirst({
      where: { auctionId },
      orderBy: { amount: 'desc' },
      include: {
        bidder: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
      },
    });

    if (!highestBid) {
      throw new NotFoundException(
        'Không tìm thấy lượt đặt giá nào cho cuộc đấu giá này',
      );
    }

    return highestBid;
  }
}
