import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async getOrCreateRoom(payload: CreateRoomDto) {
    if (payload.buyerId === payload.sellerId) {
      throw new BadRequestException(
        'Buyer and seller must be different users.',
      );
    }

    const roomFilter = this.buildRoomFilter(payload);

    const existingRoom = await this.chatRoom.findFirst({
      where: roomFilter,
      include: this.roomInclude,
    });

    if (existingRoom) {
      return existingRoom;
    }

    try {
      return await this.chatRoom.create({
        data: {
          buyerId: payload.buyerId,
          sellerId: payload.sellerId,
          vehicleId: payload.vehicleId ?? null,
          batteryId: payload.batteryId ?? null,
        },
        include: this.roomInclude,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const room = await this.chatRoom.findFirst({
          where: roomFilter,
          include: this.roomInclude,
        });

        if (room) {
          return room;
        }
      }

      throw error;
    }
  }

  async findRoomsForUser(userId: string) {
    const rooms = await this.chatRoom.findMany({
      where: {
        OR: [{ buyerId: userId }, { sellerId: userId }],
      },
      orderBy: { updatedAt: 'desc' },
      include: {
        ...this.roomInclude,
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          include: this.messageInclude,
        },
      },
    });

    if (!rooms.length) {
      return [];
    }

    const unreadCounts = await this.chatMessage.groupBy({
      by: ['roomId'],
      where: {
        roomId: { in: rooms.map((room) => room.id) },
        senderId: { not: userId },
        readAt: null,
      },
      _count: { _all: true },
    });

    const unreadMap = new Map<string, number>();
    for (const entry of unreadCounts) {
      unreadMap.set(entry.roomId, entry._count._all);
    }

    return rooms.map((room) => ({
      ...room,
      unreadCount: unreadMap.get(room.id) ?? 0,
    }));
  }

  async getRoom(roomId: string) {
    const room = await this.chatRoom.findUnique({
      where: { id: roomId },
      include: this.roomInclude,
    });

    if (!room) {
      throw new NotFoundException('Room not found');
    }

    return room;
  }

  async getRoomMessages(roomId: string, limit = 50) {
    await this.ensureRoomExists(roomId);

    const baseLimit = Number.isFinite(limit) ? limit : 50;
    const clampedLimit = Math.min(Math.max(baseLimit, 1), 200);

    return this.chatMessage.findMany({
      where: { roomId },
      orderBy: { createdAt: 'asc' },
      take: clampedLimit,
      include: this.messageInclude,
    });
  }

  async createMessage(payload: SendMessageDto) {
    const { roomId, senderId, content, metadata } = payload;

    if (!content?.trim()) {
      throw new BadRequestException('Message content is required.');
    }

    await this.ensureRoomParticipant(roomId, senderId);

    const message = await this.chatMessage.create({
      data: {
        roomId,
        senderId,
        content: content.trim(),
        metadata: metadata ?? undefined,
      },
      include: this.messageInclude,
    });

    await this.chatRoom.update({
      where: { id: roomId },
      data: { updatedAt: message.createdAt },
    });

    return message;
  }

  async markMessagesAsRead(roomId: string, userId: string) {
    await this.ensureRoomParticipant(roomId, userId);

    const result = await this.chatMessage.updateMany({
      where: {
        roomId,
        senderId: { not: userId },
        readAt: null,
      },
      data: { readAt: new Date() },
    });

    return { updated: result.count };
  }

  private async ensureRoomExists(roomId: string) {
    const exists = await this.chatRoom.findUnique({
      where: { id: roomId },
      select: { id: true },
    });
    if (!exists) {
      throw new NotFoundException('Room not found');
    }
  }

  private async ensureRoomParticipant(roomId: string, userId: string) {
    const room = await this.chatRoom.findUnique({
      where: { id: roomId },
      select: { buyerId: true, sellerId: true },
    });

    if (!room) {
      throw new NotFoundException('Room not found');
    }

    if (room.buyerId !== userId && room.sellerId !== userId) {
      throw new BadRequestException('User is not a participant of this room.');
    }
  }

  private buildRoomFilter(payload: CreateRoomDto): Prisma.ChatRoomWhereInput {
    return {
      buyerId: payload.buyerId,
      sellerId: payload.sellerId,
      vehicleId: payload.vehicleId ?? null,
      batteryId: payload.batteryId ?? null,
    };
  }

  private get chatRoom() {
    return (this.prisma as any).chatRoom;
  }

  private get chatMessage() {
    return (this.prisma as any).chatMessage;
  }

  private readonly roomInclude = {
    buyer: {
      select: { id: true, fullName: true, avatar: true },
    },
    seller: {
      select: { id: true, fullName: true, avatar: true },
    },
    vehicle: {
      select: { id: true, name: true, brand: true, model: true, images: true },
    },
    battery: {
      select: {
        id: true,
        name: true,
        type: true,
        capacity: true,
        images: true,
      },
    },
  } as const;

  private readonly messageInclude = {
    sender: {
      select: { id: true, fullName: true, avatar: true },
    },
  } as const;
}
