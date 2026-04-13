import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { Prisma, AccessoryStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ContentModerationService } from '../moderation/content-moderation.service';
import {
  APPROVAL_STATUS,
  ApprovalStatusValue,
} from '../common/approval-status.constant';
import {
  CreateAccessoryDto,
  UpdateAccessoryDto,
  SearchAccessoryDto,
} from './dto';

@Injectable()
export class AccessoriesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ContentModerationService,
  ) {}

  async findAll(
    query: SearchAccessoryDto,
    options: { includeAllStatuses?: boolean } = {},
  ) {
    const {
      search,
      category,
      minPrice,
      maxPrice,
      status,
      location,
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      approvalStatus,
    } = query;

    const toNumber = (value: unknown) => {
      if (value === undefined || value === null || value === '') {
        return undefined;
      }

      const numeric = Number(value);
      return Number.isFinite(numeric) ? numeric : undefined;
    };

    const safePage = Math.max(1, Math.floor(toNumber(page) ?? 1));
    const safeLimit = Math.min(
      100,
      Math.max(1, Math.floor(toNumber(limit) ?? 10)),
    );

    const where: Prisma.AccessoryWhereInput & {
      approvalStatus?: ApprovalStatusValue;
    } = {};

    if (!options.includeAllStatuses) {
      where.isActive = true;
    }

    const resolvedApprovalStatus =
      approvalStatus &&
      Object.values(APPROVAL_STATUS).includes(
        approvalStatus as ApprovalStatusValue,
      )
        ? (approvalStatus as ApprovalStatusValue)
        : undefined;

    if (resolvedApprovalStatus) {
      where.approvalStatus = resolvedApprovalStatus;
    } else if (!options.includeAllStatuses) {
      where.approvalStatus = APPROVAL_STATUS.APPROVED;
    }

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { brand: { contains: search, mode: 'insensitive' } },
        { compatibleModel: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (category) where.category = category;
    if (status) where.status = status;
    if (location) where.location = { contains: location, mode: 'insensitive' };

    const priceMin = toNumber(minPrice);
    const priceMax = toNumber(maxPrice);

    if (priceMin !== undefined || priceMax !== undefined) {
      where.price = {};
      if (priceMin !== undefined) where.price.gte = priceMin;
      if (priceMax !== undefined) where.price.lte = priceMax;
    }

    const skip = (safePage - 1) * safeLimit;
    const orderBy = {
      [sortBy]: sortOrder,
    } as Prisma.AccessoryOrderByWithRelationInput;

    const [accessories, total] = await Promise.all([
      this.prisma.accessory.findMany({
        where,
        skip,
        take: safeLimit,
        orderBy,
        include: {
          seller: {
            select: {
              id: true,
              fullName: true,
              email: true,
              rating: true,
              totalRatings: true,
            },
          },
        },
      }),
      this.prisma.accessory.count({ where }),
    ]);

    return {
      data: accessories,
      pagination: {
        total,
        page: safePage,
        limit: safeLimit,
        totalPages: Math.ceil(total / safeLimit),
      },
    };
  }

  async findOne(id: string) {
    const accessory = await this.prisma.accessory.findUnique({
      where: { id },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            rating: true,
            totalRatings: true,
            createdAt: true,
          },
        },
      },
    });

    if (!accessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    return accessory;
  }

  async create(createAccessoryDto: CreateAccessoryDto, sellerId: string) {
    const moderationResult = await this.moderation.analyzeAccessory({
      name: createAccessoryDto.name,
      category: createAccessoryDto.category,
      description: createAccessoryDto.description,
      price: createAccessoryDto.price,
    });

    return this.prisma.accessory.create({
      data: {
        ...createAccessoryDto,
        sellerId,
        status: AccessoryStatus.AVAILABLE,
        spamScore: moderationResult.score,
        spamReasons: moderationResult.reasons.length
          ? moderationResult.reasons
          : undefined,
        isSpamSuspicious: moderationResult.flagged,
        spamCheckedAt: new Date(),
        approvalStatus: APPROVAL_STATUS.PENDING,
      } as any,
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
          },
        },
      },
    });
  }

  async update(
    id: string,
    updateAccessoryDto: UpdateAccessoryDto,
    userId: string,
  ) {
    const existingAccessory = await this.prisma.accessory.findUnique({
      where: { id },
      select: {
        sellerId: true,
        name: true,
        category: true,
        description: true,
        price: true,
      },
    });

    if (!existingAccessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    if (existingAccessory.sellerId !== userId) {
      throw new ForbiddenException(
        'You can only update your own accessory listings',
      );
    }

    const moderationResult = await this.moderation.analyzeAccessory({
      name: updateAccessoryDto.name ?? existingAccessory.name,
      category: updateAccessoryDto.category ?? existingAccessory.category,
      description:
        updateAccessoryDto.description ?? existingAccessory.description,
      price: updateAccessoryDto.price ?? Number(existingAccessory.price),
    });

    const { sellerId: _ignoredSellerId, ...safeUpdates } =
      updateAccessoryDto as Record<string, unknown>;

    return this.prisma.accessory.update({
      where: { id },
      data: {
        ...(safeUpdates as Omit<UpdateAccessoryDto, 'sellerId'>),
        spamScore: moderationResult.score,
        spamReasons: moderationResult.reasons.length
          ? moderationResult.reasons
          : undefined,
        isSpamSuspicious: moderationResult.flagged,
        spamCheckedAt: new Date(),
      },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
          },
        },
      },
    });
  }

  async remove(id: string, userId: string) {
    const existingAccessory = await this.prisma.accessory.findUnique({
      where: { id },
      select: { sellerId: true },
    });

    if (!existingAccessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    if (existingAccessory.sellerId !== userId) {
      throw new ForbiddenException(
        'You can only delete your own accessory listings',
      );
    }

    return this.prisma.accessory.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async approve(id: string, adminId?: string, notes?: string) {
    const accessory = await this.prisma.accessory.findUnique({ where: { id } });

    if (!accessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    return this.prisma.accessory.update({
      where: { id },
      data: {
        approvalStatus: APPROVAL_STATUS.APPROVED,
        approvalNotes: notes,
        approvedAt: new Date(),
        approvedById: adminId,
        isActive: true,
        status: AccessoryStatus.AVAILABLE,
      } as any,
    });
  }

  async reject(id: string, adminId?: string, reason?: string) {
    const accessory = await this.prisma.accessory.findUnique({ where: { id } });

    if (!accessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    return this.prisma.accessory.update({
      where: { id },
      data: {
        approvalStatus: APPROVAL_STATUS.REJECTED,
        approvalNotes: reason,
        approvedAt: new Date(),
        approvedById: adminId,
        isActive: false,
      } as any,
    });
  }

  async markSpam(id: string, adminId?: string, reason?: string) {
    const accessory = await this.prisma.accessory.findUnique({ where: { id } });

    if (!accessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    return this.prisma.accessory.update({
      where: { id },
      data: {
        isSpamSuspicious: true,
        spamScore: 1,
        spamReasons: reason ? [reason] : undefined,
        spamCheckedAt: new Date(),
        approvalStatus: APPROVAL_STATUS.REJECTED,
        approvalNotes: reason,
        approvedAt: new Date(),
        approvedById: adminId,
        isActive: false,
      } as any,
    });
  }

  async verify(id: string, adminId?: string) {
    const accessory = await this.prisma.accessory.findUnique({ where: { id } });

    if (!accessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    return this.prisma.accessory.update({
      where: { id },
      data: {
        isVerified: true,
        verifiedAt: new Date(),
        verifiedById: adminId,
      } as any,
    });
  }

  async unverify(id: string, adminId?: string) {
    const accessory = await this.prisma.accessory.findUnique({ where: { id } });

    if (!accessory) {
      throw new NotFoundException(`Accessory with ID ${id} not found`);
    }

    return this.prisma.accessory.update({
      where: { id },
      data: {
        isVerified: false,
        verifiedAt: null,
        verifiedById: adminId ?? null,
      } as any,
    });
  }

  async findByUser(userId: string, query: SearchAccessoryDto) {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;

    const skip = (page - 1) * limit;
    const orderBy = {
      [sortBy]: sortOrder,
    } as Prisma.AccessoryOrderByWithRelationInput;

    const [accessories, total] = await Promise.all([
      this.prisma.accessory.findMany({
        where: { sellerId: userId, isActive: true },
        skip,
        take: limit,
        orderBy,
      }),
      this.prisma.accessory.count({
        where: { sellerId: userId, isActive: true },
      }),
    ]);

    return {
      data: accessories,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
