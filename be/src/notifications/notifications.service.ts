import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificationDto, UpdateNotificationDto } from './dto';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async create(createNotificationDto: CreateNotificationDto) {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: createNotificationDto.userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    // Create notification
    return this.prisma.notification.create({
      data: {
        title: createNotificationDto.title,
        message: createNotificationDto.message,
        type: createNotificationDto.type,
        userId: createNotificationDto.userId,
        metadata: createNotificationDto.metadata || {},
      },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
      },
    });
  }

  async findAll(
    page = 1,
    limit = 10,
    userId?: string,
    isRead?: boolean,
    type?: NotificationType,
  ) {
    const skip = (page - 1) * limit;

    // Build filter conditions
    const where: any = {};

    if (userId) {
      where.userId = userId;
    }

    if (isRead !== undefined) {
      where.isRead = isRead;
    }

    if (type) {
      where.type = type;
    }

    // Get total count for pagination
    const totalCount = await this.prisma.notification.count({ where });

    // Get notifications with pagination
    const notifications = await this.prisma.notification.findMany({
      skip,
      take: limit,
      where,
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      data: notifications,
      meta: {
        totalCount,
        page,
        limit,
        pageCount: Math.ceil(totalCount / limit),
        unreadCount:
          isRead === false
            ? totalCount
            : await this.prisma.notification.count({
                where: {
                  ...where,
                  isRead: false,
                },
              }),
      },
    };
  }

  async findOne(id: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
      },
    });

    if (!notification) {
      throw new NotFoundException('Không tìm thấy thông báo');
    }

    return notification;
  }

  async update(id: string, updateNotificationDto: UpdateNotificationDto) {
    // Check if notification exists
    const notification = await this.prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundException('Không tìm thấy thông báo');
    }

    return this.prisma.notification.update({
      where: { id },
      data: updateNotificationDto,
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
      },
    });
  }

  async remove(id: string) {
    // Check if notification exists
    const notification = await this.prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundException('Không tìm thấy thông báo');
    }

    await this.prisma.notification.delete({
      where: { id },
    });

    return { message: 'Thông báo đã được xóa thành công' };
  }

  // Additional methods

  async findByUser(userId: string, page = 1, limit = 10, isRead?: boolean) {
    // Verify that user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    return this.findAll(page, limit, userId, isRead);
  }

  async markAsRead(id: string) {
    // Check if notification exists
    const notification = await this.prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      throw new NotFoundException('Không tìm thấy thông báo');
    }

    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllAsRead(userId: string) {
    // Verify that user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    await this.prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
      },
      data: { isRead: true },
    });

    return {
      message: 'Tất cả thông báo đã được đánh dấu là đã đọc',
      success: true,
    };
  }

  async getUnreadCount(userId: string) {
    // Verify that user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    const count = await this.prisma.notification.count({
      where: {
        userId,
        isRead: false,
      },
    });

    return { count };
  }

  async deleteAllForUser(userId: string) {
    // Verify that user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Không tìm thấy người dùng');
    }

    await this.prisma.notification.deleteMany({
      where: { userId },
    });

    return {
      message: 'Tất cả thông báo đã được xóa',
      success: true,
    };
  }
}
