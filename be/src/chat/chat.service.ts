import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { ProposeContractDto } from './dto/propose-contract.dto';

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

    const existingRoom = await this.prisma.chatRoom.findFirst({
      where: roomFilter,
      include: this.roomInclude,
    });

    if (existingRoom) {
      return existingRoom;
    }

    try {
      return await this.prisma.chatRoom.create({
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
        error !== null &&
        typeof error === 'object' &&
        'code' in error &&
        (error as any).code === 'P2002'
      ) {
        const room = await this.prisma.chatRoom.findFirst({
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
    const rooms = await this.prisma.chatRoom.findMany({
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

    const unreadCounts = await this.prisma.chatMessage.groupBy({
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
    const room = await this.prisma.chatRoom.findUnique({
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

    return this.prisma.chatMessage.findMany({
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

    const message = await this.prisma.chatMessage.create({
      data: {
        roomId,
        senderId,
        content: content.trim(),
        metadata: (metadata as any) ?? undefined,
      },
      include: this.messageInclude,
    });

    await this.prisma.chatRoom.update({
      where: { id: roomId },
      data: { updatedAt: message.createdAt },
    });

    return message;
  }

  async markMessagesAsRead(roomId: string, userId: string) {
    await this.ensureRoomParticipant(roomId, userId);

    const result = await this.prisma.chatMessage.updateMany({
      where: {
        roomId,
        senderId: { not: userId },
        readAt: null,
      },
      data: { readAt: new Date() },
    });

    return { updated: result.count };
  }

  /**
   * Propose a digital contract for signing in a chat room.
   * Checks that both parties have KYC APPROVED, then creates a
   * Transaction + Contract and posts a system message in the chat.
   */
  async proposeContract(
    roomId: string,
    proposerId: string,
    dto: ProposeContractDto,
  ) {
    // 1. Load the room
    const room = await this.prisma.chatRoom.findUnique({
      where: { id: roomId },
      include: {
        buyer: {
          include: { profile: true },
        },
        seller: {
          include: { profile: true },
        },
        vehicle: { select: { id: true, name: true } },
        battery: { select: { id: true, name: true } },
      },
    });

    if (!room) {
      throw new NotFoundException('Không tìm thấy phòng chat.');
    }

    const isBuyer = room.buyerId === proposerId;
    const isSeller = room.sellerId === proposerId;

    if (!isBuyer && !isSeller) {
      throw new ForbiddenException(
        'Bạn không phải thành viên của phòng chat này.',
      );
    }

    // 2. Check KYC for both parties
    const buyerKyc = room.buyer?.profile?.kycStatus;
    const sellerKyc = room.seller?.profile?.kycStatus;

    if (buyerKyc !== 'APPROVED') {
      throw new BadRequestException(
        'Người mua chưa hoàn tất xác thực danh tính (eKYC). Không thể ký hợp đồng.',
      );
    }

    if (sellerKyc !== 'APPROVED') {
      throw new BadRequestException(
        'Người bán chưa hoàn tất xác thực danh tính (eKYC). Không thể ký hợp đồng.',
      );
    }

    const agreedPrice = parseFloat(dto.agreedPrice);
    if (isNaN(agreedPrice) || agreedPrice <= 0) {
      throw new BadRequestException('Giá thỏa thuận không hợp lệ.');
    }

    // 3. Create Transaction + Contract in a single db transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Create Transaction record
      const transaction = await tx.transaction.create({
        data: {
          amount: agreedPrice,
          status: 'PENDING',
          chatRoomId: roomId,
          sellerId: room.sellerId,
          vehicleId: room.vehicleId ?? undefined,
          batteryId: room.batteryId ?? undefined,
          notes: dto.notes ?? null,
        },
      });

      // Create Purchase (buyer side)
      await tx.purchase.create({
        data: {
          buyerId: room.buyerId,
          transactionId: transaction.id,
          status: 'PENDING',
        },
      });

      // Create Contract
      const contract = await tx.contract.create({
        data: {
          transactionId: transaction.id,
          buyerId: room.buyerId,
          sellerId: room.sellerId,
          status: 'PENDING',
        },
      });

      // Post a system message in the chat
      const assetName = room.vehicle?.name ?? room.battery?.name ?? 'Sản phẩm';
      const systemMessage = await tx.chatMessage.create({
        data: {
          roomId,
          senderId: proposerId,
          content: `📋 Yêu cầu ký hợp đồng: ${assetName}`,
          metadata: {
            type: 'CONTRACT',
            contractId: contract.id,
            transactionId: transaction.id,
            agreedPrice,
            assetName,
            proposedBy: proposerId,
          },
        },
      });

      await tx.chatRoom.update({
        where: { id: roomId },
        data: { updatedAt: systemMessage.createdAt },
      });

      return { transaction, contract, systemMessage };
    });

    return {
      message: 'Đã gửi yêu cầu ký hợp đồng vào chat. Cả hai bên vui lòng ký xác nhận.',
      contractId: result.contract.id,
      transactionId: result.transaction.id,
      systemMessage: result.systemMessage,
    };
  }

  private async ensureRoomExists(roomId: string) {
    const exists = await this.prisma.chatRoom.findUnique({
      where: { id: roomId },
      select: { id: true },
    });
    if (!exists) {
      throw new NotFoundException('Room not found');
    }
  }

  private async ensureRoomParticipant(roomId: string, userId: string) {
    const room = await this.prisma.chatRoom.findUnique({
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

  private buildRoomFilter(payload: CreateRoomDto) {
    return {
      buyerId: payload.buyerId,
      sellerId: payload.sellerId,
      vehicleId: payload.vehicleId ?? null,
      batteryId: payload.batteryId ?? null,
    };
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
