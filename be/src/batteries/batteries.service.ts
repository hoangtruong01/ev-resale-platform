import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BatteryType, BatteryStatus } from '@prisma/client';
import { CreateBatteryDto, UpdateBatteryDto, SearchBatteryDto } from './dto';
import { ContentModerationService } from '../moderation/content-moderation.service';
import {
  APPROVAL_STATUS,
  ApprovalStatusValue,
} from '../common/approval-status.constant';

@Injectable()
export class BatteriesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ContentModerationService,
  ) {}

  async findAll(
    query: SearchBatteryDto,
    options: { includeAllStatuses?: boolean } = {},
  ) {
    const {
      search,
      type,
      minCapacity,
      maxCapacity,
      minPrice,
      maxPrice,
      minCondition,
      maxCondition,
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

    const where: any = {};

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

    // Build search conditions
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (type) where.type = type;
    if (status) where.status = status;
    if (location) where.location = { contains: location, mode: 'insensitive' };

    // Capacity range
    const capacityMin = toNumber(minCapacity);
    const capacityMax = toNumber(maxCapacity);

    if (capacityMin !== undefined || capacityMax !== undefined) {
      where.capacity = {};
      if (capacityMin !== undefined) where.capacity.gte = capacityMin;
      if (capacityMax !== undefined) where.capacity.lte = capacityMax;
    }

    // Price range
    const priceMin = toNumber(minPrice);
    const priceMax = toNumber(maxPrice);

    if (priceMin !== undefined || priceMax !== undefined) {
      where.price = {};
      if (priceMin !== undefined) where.price.gte = priceMin;
      if (priceMax !== undefined) where.price.lte = priceMax;
    }

    // Condition range
    const conditionMin = toNumber(minCondition);
    const conditionMax = toNumber(maxCondition);

    if (conditionMin !== undefined || conditionMax !== undefined) {
      where.condition = {};
      if (conditionMin !== undefined) where.condition.gte = conditionMin;
      if (conditionMax !== undefined) where.condition.lte = conditionMax;
    }

    const skip = (safePage - 1) * safeLimit;
    const orderBy = { [sortBy]: sortOrder };

    const [batteries, total] = await Promise.all([
      this.prisma.battery.findMany({
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
          reviews: {
            take: 3,
            orderBy: { createdAt: 'desc' },
            include: {
              reviewer: {
                select: {
                  id: true,
                  fullName: true,
                },
              },
            },
          },
          _count: {
            select: {
              reviews: true,
            },
          },
        },
      }),
      this.prisma.battery.count({ where }),
    ]);

    return {
      data: batteries,
      pagination: {
        total,
        page: safePage,
        limit: safeLimit,
        totalPages: Math.ceil(total / safeLimit),
      },
    };
  }

  async findOne(id: string) {
    const battery = await this.prisma.battery.findUnique({
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
        reviews: {
          orderBy: { createdAt: 'desc' },
          include: {
            reviewer: {
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
            reviews: true,
          },
        },
      },
    });

    if (!battery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    return battery;
  }

  async create(createBatteryDto: CreateBatteryDto, sellerId: string) {
    const moderationResult = await this.moderation.analyzeBattery({
      name: createBatteryDto.name,
      type: createBatteryDto.type,
      capacity: createBatteryDto.capacity,
      description: createBatteryDto.description,
      price: createBatteryDto.price,
    });

    const battery = await this.prisma.battery.create({
      data: {
        ...createBatteryDto,
        sellerId,
        status: BatteryStatus.AVAILABLE,
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

    return battery;
  }

  async update(id: string, updateBatteryDto: UpdateBatteryDto, userId: string) {
    // Check if battery exists and user is the owner
    const existingBattery = await this.prisma.battery.findUnique({
      where: { id },
      select: {
        sellerId: true,
        name: true,
        type: true,
        capacity: true,
        description: true,
        price: true,
      },
    });

    if (!existingBattery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    if (existingBattery.sellerId !== userId) {
      throw new ForbiddenException(
        'You can only update your own battery listings',
      );
    }

    const moderationResult = await this.moderation.analyzeBattery({
      name: updateBatteryDto.name ?? existingBattery.name,
      type: updateBatteryDto.type ?? existingBattery.type,
      capacity: updateBatteryDto.capacity ?? Number(existingBattery.capacity),
      description: updateBatteryDto.description ?? existingBattery.description,
      price: updateBatteryDto.price ?? Number(existingBattery.price),
    });

    const { sellerId: _ignoredSellerId, ...safeUpdates } =
      updateBatteryDto as Record<string, unknown>;

    return this.prisma.battery.update({
      where: { id },
      data: {
        ...(safeUpdates as Omit<UpdateBatteryDto, 'sellerId'>),
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
    // Check if battery exists and user is the owner
    const existingBattery = await this.prisma.battery.findUnique({
      where: { id },
      select: { sellerId: true },
    });

    if (!existingBattery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    if (existingBattery.sellerId !== userId) {
      throw new ForbiddenException(
        'You can only delete your own battery listings',
      );
    }

    return this.prisma.battery.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async approve(id: string, adminId?: string, notes?: string) {
    const battery = await this.prisma.battery.findUnique({ where: { id } });

    if (!battery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    return this.prisma.battery.update({
      where: { id },
      data: {
        approvalStatus: APPROVAL_STATUS.APPROVED,
        approvalNotes: notes,
        approvedAt: new Date(),
        approvedById: adminId,
        isActive: true,
        status: BatteryStatus.AVAILABLE,
      } as any,
    });
  }

  async reject(id: string, adminId?: string, reason?: string) {
    const battery = await this.prisma.battery.findUnique({ where: { id } });

    if (!battery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    return this.prisma.battery.update({
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
    const battery = await this.prisma.battery.findUnique({ where: { id } });

    if (!battery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    return this.prisma.battery.update({
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
    const battery = await this.prisma.battery.findUnique({ where: { id } });

    if (!battery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    return this.prisma.battery.update({
      where: { id },
      data: {
        isVerified: true,
        verifiedAt: new Date(),
        verifiedById: adminId,
      } as any,
    });
  }

  async unverify(id: string, adminId?: string) {
    const battery = await this.prisma.battery.findUnique({ where: { id } });

    if (!battery) {
      throw new NotFoundException(`Battery with ID ${id} not found`);
    }

    return this.prisma.battery.update({
      where: { id },
      data: {
        isVerified: false,
        verifiedAt: null,
        verifiedById: adminId ?? null,
      } as any,
    });
  }

  async findByUser(userId: string, query: SearchBatteryDto) {
    const {
      page = 1,
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;
    const skip = (page - 1) * limit;
    const orderBy = { [sortBy]: sortOrder };

    const [batteries, total] = await Promise.all([
      this.prisma.battery.findMany({
        where: { sellerId: userId, isActive: true },
        skip,
        take: limit,
        orderBy,
        include: {
          _count: {
            select: {
              reviews: true,
            },
          },
        },
      }),
      this.prisma.battery.count({
        where: { sellerId: userId, isActive: true },
      }),
    ]);

    return {
      data: batteries,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async suggestPrice(batteryData: {
    type: BatteryType;
    capacity: number;
    condition: number;
  }) {
    // Simple AI-like price suggestion based on similar batteries
    const similarBatteries = await this.prisma.battery.findMany({
      where: {
        type: batteryData.type,
        capacity: {
          gte: batteryData.capacity * 0.8,
          lte: batteryData.capacity * 1.2,
        },
        condition: {
          gte: batteryData.condition - 10,
          lte: batteryData.condition + 10,
        },
        isActive: true,
        status: { in: ['SOLD', 'AVAILABLE'] },
      },
      select: { price: true, condition: true },
    });

    if (similarBatteries.length === 0) {
      // Default pricing based on capacity and condition
      const basePrice = batteryData.capacity * 5000000; // 5M VND per kWh
      const conditionMultiplier = batteryData.condition / 100;
      return Math.round(basePrice * conditionMultiplier);
    }

    // Calculate average price adjusted for condition
    const avgPrice =
      similarBatteries.reduce((sum, battery) => {
        const conditionAdjustedPrice =
          Number(battery.price) * (batteryData.condition / battery.condition);
        return sum + conditionAdjustedPrice;
      }, 0) / similarBatteries.length;

    return Math.round(avgPrice);
  }

  async getStatistics() {
    const [totalBatteries, activeBatteries, soldBatteries, averagePrice] =
      await Promise.all([
        this.prisma.battery.count(),
        this.prisma.battery.count({
          where: { isActive: true, status: 'AVAILABLE' },
        }),
        this.prisma.battery.count({ where: { status: 'SOLD' } }),
        this.prisma.battery.aggregate({
          where: { isActive: true, status: 'AVAILABLE' },
          _avg: { price: true },
        }),
      ]);

    const batteryTypes = await this.prisma.battery.groupBy({
      by: ['type'],
      where: { isActive: true },
      _count: { type: true },
    });

    return {
      totalBatteries,
      activeBatteries,
      soldBatteries,
      averagePrice: averagePrice._avg.price,
      batteryTypes: batteryTypes.map((item) => ({
        type: item.type,
        count: item._count.type,
      })),
    };
  }
}
