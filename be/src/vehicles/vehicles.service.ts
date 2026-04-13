import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Prisma, VehicleStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { ContentModerationService } from '../moderation/content-moderation.service';
import {
  APPROVAL_STATUS,
  ApprovalStatusValue,
} from '../common/approval-status.constant';

@Injectable()
export class VehiclesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moderation: ContentModerationService,
  ) {}

  async create(createVehicleDto: CreateVehicleDto, sellerId?: string) {
    if (!sellerId) {
      throw new UnauthorizedException(
        'Authentication required to create vehicles',
      );
    }

    const moderationResult = await this.moderation.analyzeVehicle({
      name: createVehicleDto.name,
      brand: createVehicleDto.brand,
      model: createVehicleDto.model,
      description: createVehicleDto.description,
      price: createVehicleDto.price,
    });

    const dataWithApproval = {
      ...createVehicleDto,
      sellerId,
      spamScore: moderationResult.score,
      spamReasons: moderationResult.reasons.length
        ? moderationResult.reasons
        : undefined,
      isSpamSuspicious: moderationResult.flagged,
      spamCheckedAt: new Date(),
      approvalStatus: APPROVAL_STATUS.PENDING,
    } as any;

    return this.prisma.vehicle.create({
      data: dataWithApproval,
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
  }

  async findAll(
    params: {
      page: number;
      limit: number;
      brand?: string;
      minPrice?: number;
      maxPrice?: number;
      year?: number;
      location?: string;
      approvalStatus?: string;
    },
    options: { includeAllStatuses?: boolean } = {},
  ) {
    const {
      page,
      limit,
      brand,
      minPrice,
      maxPrice,
      year,
      location,
      approvalStatus,
    } = params;
    const skip = (page - 1) * limit;

    const where: Prisma.VehicleWhereInput & {
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

    if (brand) {
      where.brand = {
        contains: brand,
        mode: 'insensitive',
      };
    }

    if (minPrice || maxPrice) {
      where.price = {};
      if (minPrice) where.price.gte = minPrice;
      if (maxPrice) where.price.lte = maxPrice;
    }

    if (year) {
      where.year = year;
    }

    if (location) {
      where.location = {
        contains: location,
        mode: 'insensitive',
      };
    }

    try {
      const [vehicles, total] = await Promise.all([
        this.prisma.vehicle.findMany({
          where,
          skip,
          take: limit,
          include: {
            seller: {
              select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
              },
            },
            reviews: {
              select: {
                id: true,
                rating: true,
                comment: true,
                reviewer: {
                  select: {
                    fullName: true,
                  },
                },
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
        }),
        this.prisma.vehicle.count({ where }),
      ]);

      return {
        data: vehicles,
        pagination: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      console.error('Failed to fetch vehicles list', {
        error,
        filters: {
          page,
          limit,
          brand,
          minPrice,
          maxPrice,
          year,
          location,
          approvalStatus: resolvedApprovalStatus,
          includeAllStatuses: options.includeAllStatuses,
        },
      });
      throw error;
    }
  }

  async findByUser(
    userId: string,
    params: {
      page?: number;
      limit?: number;
      sortBy?: string;
      sortOrder?: 'asc' | 'desc';
    } = {},
  ) {
    const allowedSortFields: Array<
      keyof Prisma.VehicleOrderByWithRelationInput
    > = ['createdAt', 'updatedAt', 'price', 'year'];

    const pageNumber = Math.max(1, Math.floor(params.page ?? 1));
    const limitNumber = Math.min(
      100,
      Math.max(1, Math.floor(params.limit ?? 10)),
    );

    const sortField = allowedSortFields.includes(
      params.sortBy as keyof Prisma.VehicleOrderByWithRelationInput,
    )
      ? (params.sortBy as keyof Prisma.VehicleOrderByWithRelationInput)
      : 'createdAt';

    const sortDirection: 'asc' | 'desc' =
      params.sortOrder === 'asc' ? 'asc' : 'desc';

    const orderBy: Prisma.VehicleOrderByWithRelationInput = {
      [sortField]: sortDirection,
    } as Prisma.VehicleOrderByWithRelationInput;

    const baseWhere: Prisma.VehicleWhereInput = {
      sellerId: userId,
      isActive: true,
      approvalStatus: APPROVAL_STATUS.APPROVED,
    };

    const [vehicles, total] = await Promise.all([
      this.prisma.vehicle.findMany({
        where: baseWhere,
        skip: (pageNumber - 1) * limitNumber,
        take: limitNumber,
        orderBy,
        include: {
          _count: {
            select: {
              reviews: true,
            },
          },
        },
      }),
      this.prisma.vehicle.count({ where: baseWhere }),
    ]);

    return {
      data: vehicles,
      pagination: {
        total,
        page: pageNumber,
        limit: limitNumber,
        totalPages: Math.ceil(total / limitNumber),
      },
    };
  }

  async findOne(id: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
          },
        },
        reviews: {
          include: {
            reviewer: {
              select: {
                fullName: true,
              },
            },
          },
        },
      },
    });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return vehicle;
  }

  async update(id: string, updateVehicleDto: UpdateVehicleDto) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id },
      select: {
        id: true,
        sellerId: true,
        name: true,
        brand: true,
        model: true,
        description: true,
        price: true,
      },
    });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    const moderationResult = await this.moderation.analyzeVehicle({
      name: updateVehicleDto.name ?? vehicle.name,
      brand: updateVehicleDto.brand ?? vehicle.brand,
      model: updateVehicleDto.model ?? vehicle.model,
      description: updateVehicleDto.description ?? vehicle.description,
      price: updateVehicleDto.price ?? Number(vehicle.price),
    });

    const { sellerId: _ignoredSellerId, ...safeUpdates } =
      updateVehicleDto as Record<string, unknown>;

    return this.prisma.vehicle.update({
      where: { id },
      data: {
        ...(safeUpdates as Omit<UpdateVehicleDto, 'sellerId'>),
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
            phone: true,
          },
        },
      },
    });
  }

  async remove(id: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id },
    });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return this.prisma.vehicle.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async approve(id: string, adminId?: string, notes?: string) {
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id } });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return this.prisma.vehicle.update({
      where: { id },
      data: {
        approvalStatus: APPROVAL_STATUS.APPROVED,
        approvalNotes: notes,
        approvedAt: new Date(),
        approvedById: adminId,
        isActive: true,
        status: VehicleStatus.AVAILABLE,
      } as any,
    });
  }

  async reject(id: string, adminId?: string, reason?: string) {
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id } });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return this.prisma.vehicle.update({
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
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id } });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return this.prisma.vehicle.update({
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
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id } });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return this.prisma.vehicle.update({
      where: { id },
      data: {
        isVerified: true,
        verifiedAt: new Date(),
        verifiedById: adminId,
      } as any,
    });
  }

  async unverify(id: string, adminId?: string) {
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id } });

    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    return this.prisma.vehicle.update({
      where: { id },
      data: {
        isVerified: false,
        verifiedAt: null,
        verifiedById: adminId ?? null,
      } as any,
    });
  }
}
