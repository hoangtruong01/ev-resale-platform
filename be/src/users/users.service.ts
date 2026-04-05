import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { KycStatus, UserRole, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  UpdateProfileDto,
  SubmitKycDto,
  ReviewKycDto,
  CreateReviewDto,
} from './dto';
import { join } from 'path';
import { unlink } from 'fs/promises';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  private get favoriteModel() {
    const client = this.prisma as PrismaService & {
      favorite?: {
        count: (args: Prisma.FavoriteCountArgs) => Promise<number>;
      };
    };
    return client.favorite;
  }

  async findAll(query?: { page?: number; limit?: number; search?: string }) {
    const { page = 1, limit = 10, search } = query || {};

    const where: Prisma.UserWhereInput = { isActive: true };

    if (search) {
      where.OR = [
        { fullName: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        select: {
          id: true,
          email: true,
          fullName: true,
          name: true,
          role: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
          avatar: true,
          phone: true,
          address: true,
          rating: true,
          totalRatings: true,
          _count: {
            select: {
              batteries: true,
              vehicles: true,
              auctions: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id, isActive: true },
      select: {
        id: true,
        email: true,
        fullName: true,
        name: true,
        avatar: true,
        totalRatings: true,
        createdAt: true,
        profile: true,
        _count: {
          select: {
            batteries: true,
            vehicles: true,
            auctions: true,
            reviews: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId, isActive: true },
      include: {
        profile: true,
        _count: {
          select: {
            batteries: true,
            vehicles: true,
            auctions: true,
            reviews: true,
            bids: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const favoriteModel = this.favoriteModel;

    const [purchases, favoriteCount] = await Promise.all([
      this.prisma.purchase.findMany({
        where: { buyerId: userId },
        include: {
          transaction: {
            select: {
              amount: true,
            },
          },
        },
      }),
      favoriteModel
        ? favoriteModel.count({ where: { userId } })
        : Promise.resolve(0),
    ]);

    const totalSpent = purchases.reduce((sum, purchase) => {
      const amount = purchase.transaction?.amount;
      return sum + (amount ? Number(amount) : 0);
    }, 0);

    return {
      ...user,
      rating: user.rating ? Number(user.rating) : null,
      totalOrders: purchases.length,
      favoriteCount,
      totalSpent,
    };
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto) {
    const userRecord = await this.prisma.user.findUnique({
      where: { id: userId, isActive: true },
      include: {
        profile: true,
      },
    });

    if (!userRecord) {
      throw new NotFoundException('User not found');
    }

    const sanitizeNullable = (value?: string) => {
      if (value === undefined || value === null) {
        return undefined;
      }
      const trimmed = value.trim();
      return trimmed.length > 0 ? trimmed : null;
    };

    const streetAddressInput =
      updateProfileDto.streetAddress ?? updateProfileDto.location;
    const sanitizedStreetAddress = sanitizeNullable(streetAddressInput);
    const sanitizedWard = sanitizeNullable(updateProfileDto.ward);
    const sanitizedDistrict = sanitizeNullable(updateProfileDto.district);
    const sanitizedProvince = sanitizeNullable(updateProfileDto.province);
    const sanitizedPhone = sanitizeNullable(updateProfileDto.phone);
    const sanitizedBio = sanitizeNullable(updateProfileDto.bio);
    const sanitizedWebsite = sanitizeNullable(updateProfileDto.website);

    const addressParts = [
      sanitizedStreetAddress ?? undefined,
      sanitizedWard ?? undefined,
      sanitizedDistrict ?? undefined,
      sanitizedProvince ?? undefined,
    ].filter((part): part is string => typeof part === 'string');

    const composedAddress =
      addressParts.length > 0 ? addressParts.join(', ') : null;

    const userUpdateData: Record<string, unknown> = {};

    if (sanitizedPhone !== undefined) {
      userUpdateData.phone = sanitizedPhone;
    }

    if (
      updateProfileDto.streetAddress !== undefined ||
      updateProfileDto.location !== undefined ||
      updateProfileDto.ward !== undefined ||
      updateProfileDto.district !== undefined ||
      updateProfileDto.province !== undefined
    ) {
      userUpdateData.address = composedAddress;
    }

    if (!userRecord.isProfileComplete) {
      userUpdateData.isProfileComplete = true;
      userUpdateData.profileCompletedAt = new Date();
    }

    const profileUpdatePayload: Record<string, unknown> = {};
    const profileCreatePayload: Record<string, unknown> = { userId };

    const setProfileValue = (key: string, value: unknown) => {
      (profileUpdatePayload as Record<string, unknown>)[key] = value;
      (profileCreatePayload as Record<string, unknown>)[key] = value;
    };

    if (sanitizedBio !== undefined) {
      setProfileValue('bio', sanitizedBio);
    }

    if (sanitizedStreetAddress !== undefined) {
      setProfileValue('location', sanitizedStreetAddress);
    }

    if (sanitizedWard !== undefined) {
      setProfileValue('ward', sanitizedWard);
    }

    if (sanitizedDistrict !== undefined) {
      setProfileValue('district', sanitizedDistrict);
    }

    if (sanitizedProvince !== undefined) {
      setProfileValue('city', sanitizedProvince);
    }

    if (sanitizedWebsite !== undefined) {
      setProfileValue('website', sanitizedWebsite);
    }

    if (updateProfileDto.socialLinks !== undefined) {
      setProfileValue(
        'socialLinks',
        updateProfileDto.socialLinks as Prisma.JsonValue,
      );
    }

    if (updateProfileDto.preferences !== undefined) {
      setProfileValue(
        'preferences',
        updateProfileDto.preferences as Prisma.JsonValue,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      if (Object.keys(userUpdateData).length > 0) {
        await tx.user.update({
          where: { id: userId },
          data: userUpdateData,
        });
      }

      const shouldHandleProfile =
        Object.keys(profileUpdatePayload).length > 0 || !userRecord.profile;

      if (shouldHandleProfile) {
        await tx.profile.upsert({
          where: { userId },
          update: profileUpdatePayload as any,
          create: profileCreatePayload as any,
        });
      }
    });

    const updatedUser = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        fullName: true,
        name: true,
        avatar: true,
        role: true,
        isProfileComplete: true,
        phone: true,
        address: true,
        profile: true,
      },
    });

    return {
      message: 'Profile updated successfully',
      user: updatedUser,
    };
  }

  // ─── eKYC ──────────────────────────────────────────────────────────────────

  /**
   * Submit KYC request. User provides their ID details.
   * Sets kycStatus to PENDING and stores the info in Profile.
   */
  async submitKyc(
    userId: string,
    dto: SubmitKycDto,
    files: {
      idFrontImage?: string;
      idBackImage?: string;
      faceImage?: string;
    },
  ) {
    const userRecord = await this.prisma.user.findUnique({
      where: { id: userId, isActive: true },
      include: { profile: true },
    });

    if (!userRecord) {
      throw new NotFoundException('User not found');
    }

    // If already approved, do not allow re-submission
    if ((userRecord.profile as any)?.kycStatus === 'APPROVED') {
      throw new BadRequestException(
        'Tài khoản đã được xác thực danh tính. Không thể nộp lại.',
      );
    }

    // Must upload at least front image
    if (!files.idFrontImage) {
      throw new BadRequestException(
        'Ảnh mặt trước CMND/CCCD là bắt buộc.',
      );
    }

    const profileData: Prisma.ProfileUpdateInput = {
      kycStatus: KycStatus.PENDING,
      idNumber: dto.idNumber,
      idType: dto.idType,
      idFrontImage: files.idFrontImage,
      idBackImage: files.idBackImage ?? null,
      faceImage: files.faceImage ?? null,
      idIssueDate: dto.idIssueDate ? new Date(dto.idIssueDate) : undefined,
      idIssuePlace: dto.idIssuePlace,
    };

    if (dto.fullNameOnId) {
      // Store as fullName update if provided
      await this.prisma.user.update({
        where: { id: userId },
        data: { fullName: dto.fullNameOnId },
      });
    }

    await this.prisma.profile.upsert({
      where: { userId },
      update: profileData as any,
      create: { userId, ...profileData } as any,
    });

    return {
      message: 'Hồ sơ xác thực danh tính đã được nộp. Vui lòng chờ xét duyệt.',
      kycStatus: 'PENDING',
    };
  }

  /**
   * Get KYC status for own profile
   */
  async getKycStatus(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      select: {
        kycStatus: true,
        idNumber: true,
        idType: true,
        idFrontImage: true,
        idBackImage: true,
        faceImage: true,
        idIssueDate: true,
        idIssuePlace: true,
      },
    });

    return {
      kycStatus: (profile as any)?.kycStatus ?? 'UNVERIFIED',
      profile: profile ?? null,
    };
  }

  /**
   * Admin-only: Review (approve/reject) a user's KYC
   */
  async reviewKyc(
    adminId: string,
    adminRole: UserRole,
    targetUserId: string,
    dto: ReviewKycDto,
  ) {
    if (adminRole !== 'ADMIN' && adminRole !== 'MODERATOR') {
      throw new ForbiddenException('Chỉ quản trị viên mới có thể duyệt KYC.');
    }

    const profile = await this.prisma.profile.findUnique({
      where: { userId: targetUserId },
    });

    if (!profile) {
      throw new NotFoundException('Không tìm thấy hồ sơ KYC của người dùng này.');
    }

    if ((profile as any).kycStatus !== 'PENDING') {
      throw new BadRequestException(
        'Hồ sơ KYC không ở trạng thái chờ duyệt.',
      );
    }

    await this.prisma.profile.update({
      where: { userId: targetUserId },
      data: { kycStatus: dto.decision } as any,
    });

    return {
      message:
        dto.decision === 'APPROVED'
          ? 'Đã chấp thuận xác thực danh tính.'
          : 'Đã từ chối xác thực danh tính.',
      kycStatus: dto.decision,
      notes: dto.notes,
    };
  }

  async listPendingKyc(adminRole: UserRole) {
    if (adminRole !== UserRole.ADMIN && adminRole !== UserRole.MODERATOR) {
      throw new ForbiddenException('Chỉ quản trị viên mới có thể xem danh sách KYC.');
    }

    const profiles = await this.prisma.profile.findMany({
      where: { kycStatus: KycStatus.PENDING },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            avatar: true,
            createdAt: true,
          },
        },
      },
    });

    return profiles;
  }

  // ─── Existing methods ──────────────────────────────────────────────────────

  async getTransactions(
    userId: string,
    query: {
      page?: number;
      limit?: number;
      type?: 'sales' | 'purchases' | 'all';
    },
  ) {
    const { page = 1, limit = 10 } = query;
    const transactions: any[] = [];
    const total = 0;
    return {
      data: transactions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getReviews(userId: string, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewer: {
            select: {
              id: true,
              fullName: true,
              avatar: true,
            },
          },
          vehicle: {
            select: {
              id: true,
              name: true,
              brand: true,
              model: true,
            },
          },
          battery: {
            select: {
              id: true,
              name: true,
              type: true,
              capacity: true,
            },
          },
        },
      }),
      this.prisma.review.count({ where: { userId } }),
    ]);

    return {
      data: reviews,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async createReview(reviewerId: string, createReviewDto: CreateReviewDto) {
    const { userId, vehicleId, batteryId, ...reviewData } = createReviewDto;

    if (reviewerId === userId) {
      throw new BadRequestException('You cannot review yourself');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const review = await this.prisma.review.create({
      data: {
        ...reviewData,
        reviewerId,
        userId,
        vehicleId,
        batteryId,
      },
      include: {
        reviewer: {
          select: {
            id: true,
            fullName: true,
            avatar: true,
          },
        },
        user: {
          select: {
            id: true,
            fullName: true,
          },
        },
      },
    });

    await this.updateUserRating(userId);

    return review;
  }

  private async updateUserRating(userId: string) {
    const reviews = await this.prisma.review.findMany({
      where: { userId },
      select: { rating: true },
    });

    if (reviews.length > 0) {
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          totalRatings: reviews.length,
        },
      });
    }
  }

  async getUserListings(
    userId: string,
    query: {
      page?: number;
      limit?: number;
      type?: 'batteries' | 'vehicles' | 'all';
    },
  ) {
    const { page = 1, limit = 10, type = 'all' } = query;
    const skip = (page - 1) * limit;

    let batteries: any[] = [];
    let vehicles: any[] = [];
    let totalBatteries = 0;
    let totalVehicles = 0;

    if (type === 'batteries' || type === 'all') {
      [batteries, totalBatteries] = await Promise.all([
        this.prisma.battery.findMany({
          where: { sellerId: userId, isActive: true, status: 'AVAILABLE' },
          skip: type === 'batteries' ? skip : 0,
          take: type === 'batteries' ? limit : limit / 2,
          include: { _count: { select: { reviews: true } } },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.battery.count({
          where: { sellerId: userId, isActive: true, status: 'AVAILABLE' },
        }),
      ]);
    }

    if (type === 'vehicles' || type === 'all') {
      [vehicles, totalVehicles] = await Promise.all([
        this.prisma.vehicle.findMany({
          where: { sellerId: userId, isActive: true, status: 'AVAILABLE' },
          skip: type === 'vehicles' ? skip : 0,
          take: type === 'vehicles' ? limit : limit / 2,
          include: { _count: { select: { reviews: true } } },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.vehicle.count({
          where: { sellerId: userId, isActive: true, status: 'AVAILABLE' },
        }),
      ]);
    }

    const data =
      type === 'batteries'
        ? batteries
        : type === 'vehicles'
          ? vehicles
          : [...batteries, ...vehicles];

    const total =
      type === 'batteries'
        ? totalBatteries
        : type === 'vehicles'
          ? totalVehicles
          : totalBatteries + totalVehicles;

    return {
      data,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateAvatar(userId: string, avatarUrl: string) {
    const existingUser = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        avatar: true,
        email: true,
        fullName: true,
        name: true,
        role: true,
        isProfileComplete: true,
      },
    });

    if (!existingUser) {
      throw new NotFoundException('User not found');
    }

    const previousAvatar = existingUser.avatar;

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: { avatar: avatarUrl },
      select: {
        id: true,
        email: true,
        fullName: true,
        name: true,
        avatar: true,
        role: true,
        isProfileComplete: true,
        updatedAt: true,
      },
    });

    if (previousAvatar && previousAvatar.startsWith('/uploads/')) {
      const normalizedPath = previousAvatar.replace(/^\/+/, '');
      const absolutePath = join(process.cwd(), normalizedPath);
      await unlink(absolutePath).catch((error: NodeJS.ErrnoException) => {
        if (error.code !== 'ENOENT') {
          console.error('Failed to remove old avatar file', error);
        }
      });
    }

    return updatedUser;
  }

  async findByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async create(userData: {
    email: string;
    fullName: string;
    name?: string;
    role?: UserRole;
  }) {
    return this.prisma.user.create({ data: userData });
  }

  async update(id: string, userData: Record<string, unknown>) {
    return this.prisma.user.update({ where: { id }, data: userData as any });
  }

  async remove(id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async hardDelete(id: string) {
    return this.prisma.user.delete({ where: { id } });
  }

  async getStatistics() {
    const [totalUsers, activeUsers, totalReviews] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isActive: true } }),
      this.prisma.review.count(),
    ]);

    const userRoles = await this.prisma.user.groupBy({
      by: ['role'],
      where: { isActive: true },
      _count: { role: true },
    });

    return {
      totalUsers,
      activeUsers,
      totalReviews,
      userRoles: userRoles.map((item) => ({
        role: item.role,
        count: item._count.role,
      })),
    };
  }
}
