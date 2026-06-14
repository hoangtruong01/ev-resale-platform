import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { ProposeContractDto } from './dto/propose-contract.dto';

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async getOrCreateRoom(payload: CreateRoomDto) {
    const buyerId = payload.buyerId?.trim();
    const sellerId = payload.sellerId?.trim();

    if (!buyerId || !sellerId) {
      throw new BadRequestException('Buyer and seller are required.');
    }

    if (buyerId === sellerId) {
      throw new BadRequestException(
        'Buyer and seller must be different users.',
      );
    }

    const asset = await this.resolveRoomAsset({
      ...payload,
      buyerId,
      sellerId,
    });

    const normalizedPayload: CreateRoomDto = {
      buyerId,
      sellerId,
      vehicleId: asset.type === 'vehicle' ? asset.id : undefined,
      batteryId: asset.type === 'battery' ? asset.id : undefined,
      accessoryId: asset.type === 'accessory' ? asset.id : undefined,
    };
    const roomFilter = this.buildRoomFilter(normalizedPayload);

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
          buyerId,
          sellerId,
          vehicleId: normalizedPayload.vehicleId ?? null,
          batteryId: normalizedPayload.batteryId ?? null,
          accessoryId: normalizedPayload.accessoryId ?? null,
        },
        include: this.roomInclude,
      });
    } catch (error: unknown) {
      if (this.isPrismaError(error, 'P2002')) {
        const room = await this.prisma.chatRoom.findFirst({
          where: roomFilter,
          include: this.roomInclude,
        });

        if (room) {
          return room;
        }
      }

      if (this.isPrismaError(error, 'P2003')) {
        throw new BadRequestException(
          'Invalid chat room participant or product reference.',
        );
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

  async getRoom(roomId: string, userId: string) {
    await this.ensureRoomParticipant(roomId, userId);

    const room = await this.prisma.chatRoom.findUnique({
      where: { id: roomId },
      include: this.roomInclude,
    });

    if (!room) {
      throw new NotFoundException('Room not found');
    }

    return room;
  }

  async getRoomMessages(
    roomId: string,
    userIdOrLimit?: string | number,
    limit = 50,
  ) {
    if (typeof userIdOrLimit === 'string') {
      await this.ensureRoomParticipant(roomId, userIdOrLimit);
    } else {
      await this.ensureRoomExists(roomId);
      limit = userIdOrLimit ?? limit;
    }

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

    if (!senderId?.trim()) {
      throw new BadRequestException('Sender is required.');
    }

    await this.ensureRoomParticipant(roomId, senderId);

    const message = await this.prisma.chatMessage.create({
      data: {
        roomId,
        senderId,
        content: content.trim(),
        metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
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
        accessory: { select: { id: true, name: true } },
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
          accessoryId: room.accessoryId ?? undefined,
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
      const assetName =
        room.vehicle?.name ?? room.battery?.name ?? room.accessory?.name ?? 'San pham';
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
      message:
        'Đã gửi yêu cầu ký hợp đồng vào chat. Cả hai bên vui lòng ký xác nhận.',
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
      throw new ForbiddenException('User is not a participant of this room.');
    }
  }

  private isPrismaError(error: unknown, code: string) {
    return (
      error !== null &&
      typeof error === 'object' &&
      'code' in error &&
      (error as { code?: unknown }).code === code
    );
  }

  private async resolveRoomAsset(payload: CreateRoomDto): Promise<{
    type: 'vehicle' | 'battery' | 'accessory';
    id: string;
  }> {
    await Promise.all([
      this.ensureUserExists(payload.buyerId, 'Buyer'),
      this.ensureUserExists(payload.sellerId, 'Seller'),
    ]);

    const selected = [
      payload.vehicleId ? { type: 'vehicle' as const, id: payload.vehicleId } : null,
      payload.batteryId ? { type: 'battery' as const, id: payload.batteryId } : null,
      payload.accessoryId ? { type: 'accessory' as const, id: payload.accessoryId } : null,
    ].filter(Boolean) as Array<{
      type: 'vehicle' | 'battery' | 'accessory';
      id: string;
    }>;

    if (selected.length !== 1) {
      throw new BadRequestException(
        'Exactly one product must be linked to a chat room.',
      );
    }

    const asset = selected[0];
    const record = await this.findAssetOwner(asset.type, asset.id);

    if (!record) {
      throw new NotFoundException('Product not found.');
    }

    if (record.sellerId !== payload.sellerId) {
      throw new BadRequestException(
        'Seller does not match the selected product owner.',
      );
    }

    return asset;
  }

  private async ensureUserExists(userId: string, label: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!user) {
      throw new NotFoundException(`${label} not found.`);
    }
  }

  private findAssetOwner(
    type: 'vehicle' | 'battery' | 'accessory',
    id: string,
  ): Promise<{ sellerId: string } | null> {
    const select = { sellerId: true };
    if (type === 'vehicle') {
      return this.prisma.vehicle.findUnique({ where: { id }, select });
    }
    if (type === 'battery') {
      return this.prisma.battery.findUnique({ where: { id }, select });
    }
    return this.prisma.accessory.findUnique({ where: { id }, select });
  }
  private buildRoomFilter(payload: CreateRoomDto) {
    return {
      buyerId: payload.buyerId,
      sellerId: payload.sellerId,
      vehicleId: payload.vehicleId ?? null,
      batteryId: payload.batteryId ?? null,
      accessoryId: payload.accessoryId ?? null,
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
      select: {
        id: true,
        name: true,
        brand: true,
        model: true,
        price: true,
        status: true,
        images: true,
      },
    },
    battery: {
      select: {
        id: true,
        name: true,
        type: true,
        capacity: true,
        price: true,
        status: true,
        images: true,
      },
    },
    accessory: {
      select: {
        id: true,
        name: true,
        category: true,
        brand: true,
        price: true,
        status: true,
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
