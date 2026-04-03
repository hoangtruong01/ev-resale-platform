import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePurchaseDto, UpdatePurchaseDto } from './dto';
import { PurchaseStatus, TransactionStatus } from '@prisma/client';

@Injectable()
export class PurchasesService {
  constructor(private prisma: PrismaService) {}

  async create(createPurchaseDto: CreatePurchaseDto) {
    const { transactionId, buyerId } = createPurchaseDto;

    // Check if the transaction exists
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    // Check if a purchase already exists for this transaction
    const existingPurchase = await this.prisma.purchase.findUnique({
      where: { transactionId },
    });

    if (existingPurchase) {
      throw new BadRequestException(
        'Đã tồn tại đơn mua hàng cho giao dịch này',
      );
    }

    // Check if the buyer exists
    const buyer = await this.prisma.user.findUnique({
      where: { id: buyerId },
    });

    if (!buyer) {
      throw new NotFoundException('Không tìm thấy người mua');
    }

    // Create the purchase
    const purchase = await this.prisma.purchase.create({
      data: {
        ...createPurchaseDto,
        status: createPurchaseDto.status || PurchaseStatus.PENDING,
      },
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        transaction: {
          include: {
            vehicle: true,
            battery: true,
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

    // Update transaction status to COMPLETED if not already
    if (transaction.status !== TransactionStatus.COMPLETED) {
      await this.prisma.transaction.update({
        where: { id: transactionId },
        data: { status: TransactionStatus.COMPLETED },
      });
    }

    return purchase;
  }

  async findAll(
    page = 1,
    limit = 10,
    status?: PurchaseStatus,
    buyerId?: string,
  ) {
    const skip = (page - 1) * limit;

    // Build filter conditions
    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (buyerId) {
      where.buyerId = buyerId;
    }

    // Get total count for pagination
    const totalCount = await this.prisma.purchase.count({ where });

    // Get purchases with pagination
    const purchases = await this.prisma.purchase.findMany({
      skip,
      take: limit,
      where,
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        transaction: {
          include: {
            vehicle: true,
            battery: true,
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
      data: purchases,
      meta: {
        totalCount,
        page,
        limit,
        pageCount: Math.ceil(totalCount / limit),
      },
    };
  }

  async findOne(id: string) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { id },
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        transaction: {
          include: {
            vehicle: true,
            battery: true,
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

    if (!purchase) {
      throw new NotFoundException('Không tìm thấy đơn mua hàng');
    }

    return purchase;
  }

  async update(id: string, updatePurchaseDto: UpdatePurchaseDto) {
    // Check if the purchase exists
    const purchase = await this.prisma.purchase.findUnique({
      where: { id },
    });

    if (!purchase) {
      throw new NotFoundException('Không tìm thấy đơn mua hàng');
    }

    return this.prisma.purchase.update({
      where: { id },
      data: updatePurchaseDto,
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        transaction: {
          include: {
            vehicle: true,
            battery: true,
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
  }

  async remove(id: string) {
    // Check if the purchase exists
    const purchase = await this.prisma.purchase.findUnique({
      where: { id },
    });

    if (!purchase) {
      throw new NotFoundException('Không tìm thấy đơn mua hàng');
    }

    await this.prisma.purchase.delete({
      where: { id },
    });

    return { message: 'Đơn mua hàng đã được xóa thành công' };
  }

  // Additional methods

  async findByBuyer(buyerId: string, page = 1, limit = 10) {
    return this.findAll(page, limit, undefined, buyerId);
  }

  async updateStatus(id: string, status: PurchaseStatus) {
    // Check if the purchase exists
    const purchase = await this.prisma.purchase.findUnique({
      where: { id },
    });

    if (!purchase) {
      throw new NotFoundException('Không tìm thấy đơn mua hàng');
    }

    // If status is changing to DELIVERED, update delivery date
    const updateData: any = { status };
    if (
      status === PurchaseStatus.DELIVERED &&
      purchase.status !== PurchaseStatus.DELIVERED
    ) {
      updateData.deliveryDate = new Date();
    }

    return this.prisma.purchase.update({
      where: { id },
      data: updateData,
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        transaction: {
          include: {
            vehicle: true,
            battery: true,
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
  }

  async findByTransaction(transactionId: string) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { transactionId },
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        transaction: {
          include: {
            vehicle: true,
            battery: true,
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

    if (!purchase) {
      throw new NotFoundException(
        'Không tìm thấy đơn mua hàng cho giao dịch này',
      );
    }

    return purchase;
  }
}
