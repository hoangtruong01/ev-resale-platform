import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma, User, UserRole } from '@prisma/client';
import { UpdateProfileDto, CreateReviewDto } from './dto';
import { unlink } from 'fs/promises';
import { join } from 'path';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  private get favoriteModel() {
    const client = this.prisma as PrismaService & {
      favorite?: {
        count: (args: any) => Promise<number>;
      };
    };
    return client.favorite;
  }

  async findAll(query?: { page?: number; limit?: number; search?: string }) {
    const { page = 1, limit = 10, search } = query || {};

    const where: any = { isActive: true };

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

    const userUpdateData: Prisma.UserUpdateInput = {};

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

    const profileUpdatePayload: Prisma.ProfileUpdateInput = {};
    const profileCreatePayload: Prisma.ProfileUncheckedCreateInput = {
      userId,
    };

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
          update: profileUpdatePayload,
          create: profileCreatePayload,
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

  async getTransactions(
    userId: string,
    query: {
      page?: number;
      limit?: number;
      type?: 'sales' | 'purchases' | 'all';
    },
  ) {
    const { page = 1, limit = 10, type = 'all' } = query;
    const skip = (page - 1) * limit;

    const transactions = [];
    const total = 0;

    // Note: This will need to be updated once Transaction model is properly generated
    // For now, returning empty result to avoid compilation errors
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

    // Check if reviewer is not reviewing themselves
    if (reviewerId === userId) {
      throw new BadRequestException('You cannot review yourself');
    }

    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Create the review
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

    // Update user's average rating
    await this.updateUserRating(userId);

    return review;
  }

  private async updateUserRating(userId: string) {
    const reviews = await this.prisma.review.findMany({
      where: { userId },
      select: { rating: true },
    });

    if (reviews.length > 0) {
      const averageRating =
        reviews.reduce((sum, review) => sum + review.rating, 0) /
        reviews.length;

      await this.prisma.user.update({
        where: { id: userId },
        data: {
          // rating: averageRating, // This will need to be uncommented when rating field is added to User model
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
          where: {
            sellerId: userId,
            isActive: true,
            status: 'AVAILABLE',
          },
          skip: type === 'batteries' ? skip : 0,
          take: type === 'batteries' ? limit : limit / 2,
          include: {
            _count: {
              select: {
                reviews: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.battery.count({
          where: {
            sellerId: userId,
            isActive: true,
            status: 'AVAILABLE',
          },
        }),
      ]);
    }

    if (type === 'vehicles' || type === 'all') {
      [vehicles, totalVehicles] = await Promise.all([
        this.prisma.vehicle.findMany({
          where: {
            sellerId: userId,
            isActive: true,
            status: 'AVAILABLE',
          },
          skip: type === 'vehicles' ? skip : 0,
          take: type === 'vehicles' ? limit : limit / 2,
          include: {
            _count: {
              select: {
                reviews: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.vehicle.count({
          where: {
            sellerId: userId,
            isActive: true,
            status: 'AVAILABLE',
          },
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
      data: {
        avatar: avatarUrl,
      },
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
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  async create(userData: {
    email: string;
    fullName: string;
    name?: string;
    role?: UserRole;
  }) {
    return this.prisma.user.create({
      data: userData,
    });
  }

  async update(id: string, userData: Partial<User>) {
    return this.prisma.user.update({
      where: { id },
      data: userData,
    });
  }

  async remove(id: string) {
    // Soft delete - just deactivate
    return this.prisma.user.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async hardDelete(id: string) {
    // Hard delete - permanently remove from database
    return this.prisma.user.delete({
      where: { id },
    });
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
