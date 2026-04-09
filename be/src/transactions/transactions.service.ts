import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateTransactionDto,
  UpdateTransactionDto,
  RespondTransactionDto,
} from './dto';
import { Prisma, TransactionStatus, PurchaseStatus } from '@prisma/client';
import { ChatService } from '../chat/chat.service';
import { ChatGateway } from '../chat/chat.gateway';

type DisputeStatus = 'OPEN' | 'IN_REVIEW' | 'RESOLVED';
type DisputeResolution = 'BUYER' | 'SELLER' | 'PARTIAL';
type AdminTransactionStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'cancelled'
  | 'disputed';

interface AdminTransactionDispute {
  id: string;
  reporter: {
    id: string;
    name: string;
    role: 'buyer' | 'seller';
    email?: string | null;
    phone?: string | null;
  };
  reason: string;
  description?: string | null;
  evidence?: string[] | null;
  status: 'open' | 'in_review' | 'resolved';
  createdAt: string;
  resolvedAt?: string | null;
  resolvedBy?: {
    id: string;
    name: string;
    email?: string | null;
  } | null;
  resolutionOutcome?: 'buyer' | 'seller' | 'partial' | null;
  resolutionNotes?: string | null;
}

interface AdminTransactionItem {
  id: string;
  type: 'sale' | 'auction';
  product: {
    name: string;
    category: string;
    image?: string | null;
  };
  seller: {
    id: string;
    name: string;
    email: string;
    phone?: string | null;
    address?: string | null;
    avatar?: string | null;
  };
  buyer: {
    id: string;
    name: string;
    email: string;
    phone?: string | null;
    address?: string | null;
    avatar?: string | null;
  } | null;
  amount: number;
  fee: number;
  feePercent: number;
  status: AdminTransactionStatus;
  hasDispute: boolean;
  dispute?: AdminTransactionDispute | null;
  createdAt: string;
  updatedAt: string;
}

type TransactionWithRelations = Prisma.TransactionGetPayload<{
  include: {
    seller: {
      select: {
        id: true;
        fullName: true;
        email: true;
        phone: true;
        address: true;
        avatar: true;
      };
    };
    vehicle: true;
    battery: true;
    purchase: {
      include: {
        buyer: {
          select: {
            id: true;
            fullName: true;
            email: true;
            phone: true;
            address: true;
            avatar: true;
            profile: {
              select: {
                location: true;
                ward: true;
                district: true;
                city: true;
              };
            };
          };
        };
      };
    };
    chatRoom: {
      include: {
        buyer: {
          select: {
            id: true;
            fullName: true;
            email: true;
            phone: true;
            address: true;
            avatar: true;
            profile: {
              select: {
                location: true;
                ward: true;
                district: true;
                city: true;
              };
            };
          };
        };
        seller: {
          select: {
            id: true;
            fullName: true;
            email: true;
          };
        };
      };
    };
    dispute: {
      include: {
        reporter: {
          select: {
            id: true;
            fullName: true;
            email: true;
            phone: true;
            address: true;
            avatar: true;
          };
        };
        resolvedBy: {
          select: {
            id: true;
            fullName: true;
            email: true;
          };
        };
      };
    };
  };
}>;

@Injectable()
export class TransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  private readonly transactionInclude = {
    seller: {
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        address: true,
        avatar: true,
      },
    },
    vehicle: true,
    battery: true,
    purchase: {
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            address: true,
            avatar: true,
            profile: {
              select: {
                location: true,
                ward: true,
                district: true,
                city: true,
              },
            },
          },
        },
      },
    },
    chatRoom: {
      include: {
        buyer: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            address: true,
            avatar: true,
            profile: {
              select: {
                location: true,
                ward: true,
                district: true,
                city: true,
              },
            },
          },
        },
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
          },
        },
      },
    },
    dispute: {
      include: {
        reporter: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phone: true,
            address: true,
            avatar: true,
          },
        },
        resolvedBy: {
          select: {
            id: true,
            fullName: true,
            email: true,
          },
        },
      },
    },
  } as const;

  async create(createTransactionDto: CreateTransactionDto) {
    const {
      vehicleId,
      batteryId,
      sellerId,
      roomId,
      amount,
      fee,
      commission,
      status,
      paymentMethod,
      notes,
    } = createTransactionDto;

    let resolvedVehicleId = vehicleId ?? null;
    let resolvedBatteryId = batteryId ?? null;

    let chatRoom: {
      id: string;
      buyerId: string;
      sellerId: string;
      vehicleId: string | null;
      batteryId: string | null;
    } | null = null;

    if (roomId) {
      chatRoom = await this.prisma.chatRoom.findUnique({
        where: { id: roomId },
        select: {
          id: true,
          buyerId: true,
          sellerId: true,
          vehicleId: true,
          batteryId: true,
        },
      });

      if (!chatRoom) {
        throw new NotFoundException('Không tìm thấy phòng chat');
      }

      if (chatRoom.sellerId !== sellerId) {
        throw new BadRequestException('Phòng chat không thuộc người bán');
      }

      if (!resolvedVehicleId && chatRoom.vehicleId) {
        resolvedVehicleId = chatRoom.vehicleId;
      }

      if (!resolvedBatteryId && chatRoom.batteryId) {
        resolvedBatteryId = chatRoom.batteryId;
      }

      if (
        resolvedVehicleId &&
        chatRoom.vehicleId &&
        chatRoom.vehicleId !== resolvedVehicleId
      ) {
        throw new BadRequestException('Phòng chat không liên quan tới xe này');
      }

      if (
        resolvedBatteryId &&
        chatRoom.batteryId &&
        chatRoom.batteryId !== resolvedBatteryId
      ) {
        throw new BadRequestException('Phòng chat không liên quan tới pin này');
      }

      const pendingTransaction = await this.prisma.transaction.findFirst({
        where: {
          chatRoomId: roomId,
          status: TransactionStatus.PENDING,
          buyerRespondedAt: null,
        },
        select: {
          id: true,
        },
      });

      if (pendingTransaction) {
        throw new BadRequestException(
          'Đơn giao dịch hiện tại vẫn đang chờ phản hồi của người mua.',
        );
      }

      const rejectedCount = await this.prisma.transaction.count({
        where: {
          chatRoomId: roomId,
          status: TransactionStatus.CANCELLED,
        },
      });

      if (rejectedCount >= 3) {
        throw new BadRequestException(
          'Bạn đã đạt giới hạn 3 lần tạo lại giao dịch sau khi bị từ chối.',
        );
      }
    }

    if (
      (resolvedVehicleId && resolvedBatteryId) ||
      (!resolvedVehicleId && !resolvedBatteryId)
    ) {
      throw new BadRequestException(
        'Một giao dịch cần có duy nhất một xe hoặc một pin',
      );
    }

    if (resolvedVehicleId) {
      const vehicle = await this.prisma.vehicle.findUnique({
        where: { id: resolvedVehicleId },
      });

      if (!vehicle) {
        throw new NotFoundException('Không tìm thấy xe');
      }

      if (vehicle.sellerId !== sellerId) {
        throw new BadRequestException('Xe này không thuộc về người bán');
      }
    }

    if (resolvedBatteryId) {
      const battery = await this.prisma.battery.findUnique({
        where: { id: resolvedBatteryId },
      });

      if (!battery) {
        throw new NotFoundException('Không tìm thấy pin');
      }

      if (battery.sellerId !== sellerId) {
        throw new BadRequestException('Pin này không thuộc về người bán');
      }
    }

    const resolvedFeeValue =
      fee ?? (await this.calculatePlatformFee(Number(amount)));

    const transaction = await this.prisma.transaction.create({
      data: {
        sellerId,
        amount,
        fee: resolvedFeeValue ?? null,
        commission: commission ?? null,
        status: status ?? TransactionStatus.PENDING,
        paymentMethod: paymentMethod ?? null,
        notes: notes ?? null,
        vehicleId: resolvedVehicleId,
        batteryId: resolvedBatteryId,
        chatRoomId: roomId ?? null,
        buyerAccepted: null,
        buyerRespondedAt: null,
      },
      include: this.transactionInclude,
    });

    if (roomId && chatRoom) {
      const message = await this.chatService.createMessage({
        roomId,
        senderId: sellerId,
        content: 'Người bán đã tạo đơn giao dịch.',
        metadata: {
          kind: 'transaction-offer',
          transactionId: transaction.id,
          amount: this.toPlainNumber(transaction.amount),
          fee: this.toPlainNumber(transaction.fee),
          commission: this.toPlainNumber(transaction.commission),
          sellerId,
          buyerId: chatRoom.buyerId,
          status: 'pending',
        },
      });

      this.emitChatMessage(roomId, message);
    }

    return transaction;
  }

  async findAll(
    page = 1,
    limit = 10,
    status?: TransactionStatus,
    sellerId?: string,
  ) {
    const skip = (page - 1) * limit;

    // Build filter conditions
    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (sellerId) {
      where.sellerId = sellerId;
    }

    // Get total count for pagination
    const totalCount = await this.prisma.transaction.count({ where });

    // Get transactions with pagination
    const transactions = await this.prisma.transaction.findMany({
      skip,
      take: limit,
      where,
      include: this.transactionInclude,
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      data: transactions,
      meta: {
        totalCount,
        page,
        limit,
        pageCount: Math.ceil(totalCount / limit),
      },
    };
  }

  async getAdminTransactions(params: {
    page?: number;
    limit?: number;
    status?: AdminTransactionStatus | 'all';
    type?: 'sale' | 'auction' | 'all';
    search?: string;
  }) {
    const page = Math.max(params.page ?? 1, 1);
    const limit = Math.max(Math.min(params.limit ?? 10, 100), 1);
    const skip = (page - 1) * limit;

    const sharedConditions: Prisma.TransactionWhereInput[] = [];

    if (params.search) {
      const search = params.search.trim();
      if (search.length) {
        sharedConditions.push({
          OR: [
            { id: { contains: search, mode: 'insensitive' } },
            {
              vehicle: {
                is: {
                  name: { contains: search, mode: 'insensitive' },
                },
              },
            },
            {
              battery: {
                is: {
                  name: { contains: search, mode: 'insensitive' },
                },
              },
            },
            {
              seller: {
                is: {
                  fullName: { contains: search, mode: 'insensitive' },
                },
              },
            },
            {
              purchase: {
                is: {
                  buyer: {
                    is: {
                      fullName: { contains: search, mode: 'insensitive' },
                    },
                  },
                },
              },
            },
            {
              chatRoom: {
                is: {
                  buyer: {
                    is: {
                      fullName: { contains: search, mode: 'insensitive' },
                    },
                  },
                },
              },
            },
          ],
        });
      }
    }

    if (params.type && params.type !== 'all') {
      if (params.type === 'auction') {
        sharedConditions.push({
          OR: [
            { vehicle: { is: { status: 'AUCTION' } } },
            { battery: { is: { status: 'AUCTION' } } },
          ],
        });
      } else {
        sharedConditions.push({
          OR: [
            { vehicle: { is: null } },
            { vehicle: { is: { status: { not: 'AUCTION' } } } },
            { battery: { is: null } },
            { battery: { is: { status: { not: 'AUCTION' } } } },
          ],
        });
      }
    }

    const listConditions = [...sharedConditions];

    if (params.status && params.status !== 'all') {
      switch (params.status) {
        case 'completed':
          listConditions.push({ status: TransactionStatus.COMPLETED });
          break;
        case 'cancelled':
          listConditions.push({
            status: {
              in: [TransactionStatus.CANCELLED, TransactionStatus.REFUNDED],
            },
          });
          break;
        case 'disputed':
          listConditions.push({
            dispute: {
              is: {
                status: 'OPEN',
              },
            },
          } as unknown as Prisma.TransactionWhereInput);
          break;
        case 'processing':
          listConditions.push({
            status: TransactionStatus.PENDING,
            buyerRespondedAt: { not: null },
          });
          break;
        case 'pending':
        default:
          listConditions.push({
            status: TransactionStatus.PENDING,
            buyerRespondedAt: null,
          });
          break;
      }
    }

    const listWhere = this.buildWhere(listConditions);
    const sharedWhere = this.buildWhere(sharedConditions);

    const [
      totalCount,
      transactions,
      totalForStats,
      completedCount,
      pendingCount,
      disputeCount,
      revenueAggregate,
    ] = await this.prisma.$transaction([
      this.prisma.transaction.count({ where: listWhere }),
      this.prisma.transaction.findMany({
        where: listWhere,
        include: this.transactionInclude,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.transaction.count({ where: sharedWhere }),
      this.prisma.transaction.count({
        where: this.extendConditions(sharedConditions, {
          status: TransactionStatus.COMPLETED,
        }),
      }),
      this.prisma.transaction.count({
        where: this.extendConditions(sharedConditions, {
          status: TransactionStatus.PENDING,
        }),
      }),
      this.prisma.transaction.count({
        where: this.extendConditions(sharedConditions, {
          dispute: {
            is: {
              status: 'OPEN',
            },
          },
        } as unknown as Prisma.TransactionWhereInput),
      }),
      this.prisma.transaction.aggregate({
        _sum: { fee: true },
        where: this.extendConditions(sharedConditions, {
          status: TransactionStatus.COMPLETED,
        }),
      }),
    ]);

    const items = transactions.map((transaction) =>
      this.mapTransactionToAdminItem(transaction as TransactionWithRelations),
    );

    const pageCount = Math.max(Math.ceil(totalCount / limit), 1);
    const totalRevenue =
      this.toPlainNumber(revenueAggregate._sum?.fee ?? 0) ?? 0;

    return {
      data: items,
      meta: {
        page,
        limit,
        pageCount,
        totalCount,
      },
      stats: {
        total: totalForStats,
        completed: completedCount,
        pending: pendingCount,
        disputes: disputeCount,
        totalRevenue,
      },
    };
  }

  async getAdminTransactionById(id: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: this.transactionInclude,
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    return this.mapTransactionToAdminItem(
      transaction as TransactionWithRelations,
    );
  }

  async markTransactionProcessing(id: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: this.transactionInclude,
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    if (transaction.status !== TransactionStatus.PENDING) {
      throw new BadRequestException('Chỉ có thể xử lý giao dịch đang chờ.');
    }

    if (transaction.buyerRespondedAt) {
      return this.mapTransactionToAdminItem(
        transaction as TransactionWithRelations,
      );
    }

    const updated = await this.prisma.transaction.update({
      where: { id },
      data: {
        buyerRespondedAt: new Date(),
        buyerAccepted:
          transaction.buyerAccepted === null ? true : transaction.buyerAccepted,
      },
      include: this.transactionInclude,
    });

    return this.mapTransactionToAdminItem(updated as TransactionWithRelations);
  }

  async resolveTransactionDispute(
    id: string,
    resolution: 'buyer' | 'seller' | 'partial',
    adminId: string,
    notes?: string,
  ) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: this.transactionInclude,
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    const currentDispute = transaction.dispute as
      | ({ status?: DisputeStatus } & Record<string, unknown>)
      | null
      | undefined;

    if (!currentDispute) {
      throw new BadRequestException('Giao dịch không có khiếu nại.');
    }

    if (currentDispute.status === 'RESOLVED') {
      throw new BadRequestException('Khiếu nại đã được giải quyết.');
    }

    const resolutionValue = resolution.toUpperCase() as DisputeResolution;

    const newTransactionStatus =
      resolutionValue === 'BUYER'
        ? TransactionStatus.CANCELLED
        : resolutionValue === 'SELLER'
          ? TransactionStatus.COMPLETED
          : TransactionStatus.REFUNDED;

    const [, updatedTransaction] = await this.prisma.$transaction([
      (this.prisma as any).transactionDispute.update({
        where: { transactionId: id },
        data: {
          status: 'RESOLVED',
          resolutionOutcome: resolutionValue,
          resolutionNotes: notes ?? null,
          resolvedById: adminId,
          resolvedAt: new Date(),
        },
      }),
      this.prisma.transaction.update({
        where: { id },
        data: {
          status: newTransactionStatus,
        },
        include: this.transactionInclude,
      }),
    ]);

    return this.mapTransactionToAdminItem(
      updatedTransaction as TransactionWithRelations,
    );
  }

  async findOne(id: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: this.transactionInclude,
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    return transaction;
  }

  async update(id: string, updateTransactionDto: UpdateTransactionDto) {
    // Check if the transaction exists
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    const {
      amount: dtoAmount,
      fee: dtoFee,
      commission: dtoCommission,
      ...rest
    } = updateTransactionDto;

    const amountUpdate =
      dtoAmount !== undefined ? Number(dtoAmount) : undefined;

    let feeUpdate = dtoFee as number | null | undefined;

    if (feeUpdate === undefined && amountUpdate !== undefined) {
      feeUpdate = await this.calculatePlatformFee(amountUpdate);
    }

    return this.prisma.transaction.update({
      where: { id },
      data: {
        ...rest,
        amount: amountUpdate !== undefined ? amountUpdate : undefined,
        fee: feeUpdate !== undefined ? feeUpdate : undefined,
        commission: dtoCommission !== undefined ? dtoCommission : undefined,
      },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        vehicle: true,
        battery: true,
        purchase: true,
      },
    });
  }

  async remove(id: string) {
    // Check if the transaction exists
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    // Check if there's an associated purchase
    if (transaction.id) {
      const purchase = await this.prisma.purchase.findUnique({
        where: { transactionId: id },
      });

      if (purchase) {
        // Delete the purchase first
        await this.prisma.purchase.delete({
          where: { id: purchase.id },
        });
      }
    }

    // Now delete the transaction
    await this.prisma.transaction.delete({
      where: { id },
    });

    return { message: 'Giao dịch đã được xóa thành công' };
  }

  // Additional methods

  async findByVehicle(vehicleId: string) {
    return this.prisma.transaction.findMany({
      where: { vehicleId },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        purchase: true,
      },
    });
  }

  async findByBattery(batteryId: string) {
    return this.prisma.transaction.findMany({
      where: { batteryId },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        purchase: true,
      },
    });
  }

  async findBySeller(sellerId: string, page = 1, limit = 10) {
    return this.findAll(page, limit, undefined, sellerId);
  }

  async updateStatus(id: string, status: TransactionStatus) {
    // Check if the transaction exists
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    return this.prisma.transaction.update({
      where: { id },
      data: { status },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
            avatar: true,
          },
        },
        vehicle: true,
        battery: true,
        purchase: true,
      },
    });
  }

  async respondToChatTransaction(
    id: string,
    action: RespondTransactionDto['action'],
    userId: string,
  ) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: {
        chatRoom: {
          select: {
            id: true,
            buyerId: true,
            sellerId: true,
          },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    if (!transaction.chatRoom) {
      throw new BadRequestException(
        'Giao dịch này không được tạo từ cuộc trò chuyện',
      );
    }

    if (transaction.chatRoom.buyerId !== userId) {
      throw new ForbiddenException('Bạn không có quyền xử lý giao dịch này');
    }

    if (transaction.buyerRespondedAt) {
      throw new BadRequestException('Bạn đã phản hồi giao dịch này');
    }

    const buyerAccepted = action === 'accept';
    const nextStatus = buyerAccepted
      ? TransactionStatus.AWAITING_DEPOSIT
      : TransactionStatus.CANCELLED;

    let depositAmount: number | undefined;
    let balanceAmount: number | undefined;

    if (buyerAccepted) {
      const total = this.calculateTotalAmount(transaction);
      depositAmount = Math.round(total / 2);
      balanceAmount = total - depositAmount;
    }

    const updatedTransaction = await this.prisma.transaction.update({
      where: { id },
      data: {
        buyerAccepted,
        buyerRespondedAt: new Date(),
        status: nextStatus,
        depositAmount,
        balanceAmount,
      },
      include: this.transactionInclude,
    });

    const message = await this.chatService.createMessage({
      roomId: transaction.chatRoom.id,
      senderId: userId,
      content: buyerAccepted
        ? 'Người mua đã xác nhận đơn giao dịch.'
        : 'Người mua đã từ chối đơn giao dịch.',
      metadata: {
        kind: 'transaction-response',
        transactionId: updatedTransaction.id,
        action,
        buyerAccepted,
        status: buyerAccepted ? 'accepted' : 'rejected',
        amount: this.toPlainNumber(updatedTransaction.amount),
        sellerId: transaction.chatRoom.sellerId,
        buyerId: userId,
      },
    });

    this.emitChatMessage(transaction.chatRoom.id, message);

    return updatedTransaction;
  }

  private toPlainNumber(
    value: Prisma.Decimal | number | null | undefined,
  ): number | null {
    if (value === null || value === undefined) {
      return null;
    }

    if (typeof value === 'number') {
      return value;
    }

    const candidate = value as Prisma.Decimal & { toNumber?: () => number };
    if (typeof candidate.toNumber === 'function') {
      return candidate.toNumber();
    }

    return Number(value);
  }

  private async calculatePlatformFee(amount: number): Promise<number | null> {
    const normalizedAmount = Number(amount);

    if (!Number.isFinite(normalizedAmount) || normalizedAmount <= 0) {
      return null;
    }

    const prismaClient = this.prisma as unknown as {
      transactionFeeSetting?: {
        findUnique: (args: { where: { key: string } }) => Promise<any>;
      };
    };

    if (!prismaClient.transactionFeeSetting) {
      return null;
    }

    const setting = await prismaClient.transactionFeeSetting.findUnique({
      where: { key: 'default' },
    });

    if (!setting) {
      return null;
    }

    const rate = this.toPlainNumber(setting.rate) ?? 0;
    if (rate <= 0) {
      return null;
    }

    const minFee = this.toPlainNumber(setting.minFee) ?? null;
    const maxFee = this.toPlainNumber(setting.maxFee) ?? null;

    let fee = (normalizedAmount * rate) / 100;

    if (minFee !== null && minFee > 0) {
      fee = Math.max(fee, minFee);
    }

    if (maxFee !== null && maxFee > 0) {
      fee = Math.min(fee, maxFee);
    }

    return Number(fee.toFixed(2));
  }

  private buildWhere(
    conditions: Prisma.TransactionWhereInput[],
  ): Prisma.TransactionWhereInput {
    return conditions.length ? { AND: conditions } : {};
  }

  private extendConditions(
    base: Prisma.TransactionWhereInput[],
    extra: Prisma.TransactionWhereInput | Prisma.TransactionWhereInput[],
  ): Prisma.TransactionWhereInput {
    const extras = Array.isArray(extra) ? extra : [extra];
    return this.buildWhere([...base, ...extras]);
  }

  private mapTransactionToAdminItem(
    transaction: TransactionWithRelations,
  ): AdminTransactionItem {
    const amount = this.toPlainNumber(transaction.amount) ?? 0;
    const fee = this.toPlainNumber(transaction.fee) ?? 0;
    const feePercent = amount > 0 && fee > 0 ? (fee / amount) * 100 : 0;

    const sellerName = transaction.seller.fullName || transaction.seller.email;

    const buyerEntity =
      transaction.purchase?.buyer ?? transaction.chatRoom?.buyer ?? null;
    const buyerName = buyerEntity?.fullName || buyerEntity?.email || '';
    const buyerProfile = (buyerEntity as any)?.profile as
      | {
          location?: string | null;
          ward?: string | null;
          district?: string | null;
          city?: string | null;
        }
      | null
      | undefined;
    const buyerAddress =
      buyerEntity?.address ?? this.composeAddressFromProfile(buyerProfile);

    const dispute = this.mapDispute(transaction);

    return {
      id: transaction.id,
      type:
        transaction.vehicle?.status === 'AUCTION' ||
        transaction.battery?.status === 'AUCTION'
          ? 'auction'
          : 'sale',
      product: {
        name:
          transaction.vehicle?.name ?? transaction.battery?.name ?? 'Giao dịch',
        category: this.getProductCategory(transaction),
        image: this.getProductImage(transaction),
      },
      seller: {
        id: transaction.seller.id,
        name: sellerName,
        email: transaction.seller.email,
        phone: transaction.seller.phone ?? null,
        address: transaction.seller.address ?? null,
        avatar: transaction.seller.avatar ?? null,
      },
      buyer: buyerEntity
        ? {
            id: buyerEntity.id,
            name: buyerName,
            email: buyerEntity.email,
            phone: buyerEntity.phone ?? null,
            address: buyerAddress ?? null,
            avatar: buyerEntity.avatar ?? null,
          }
        : null,
      amount,
      fee,
      feePercent: Number(feePercent.toFixed(2)),
      status: this.resolveAdminStatus(transaction),
      hasDispute: dispute ? dispute.status === 'open' : false,
      dispute,
      createdAt: transaction.createdAt.toISOString(),
      updatedAt: transaction.updatedAt.toISOString(),
    };
  }

  private resolveAdminStatus(
    transaction: TransactionWithRelations,
  ): AdminTransactionStatus {
    const dispute = transaction.dispute as
      | ({
          status?: DisputeStatus;
        } & Record<string, unknown>)
      | null
      | undefined;

    const purchaseStatus = transaction.purchase?.status;

    if (dispute && dispute.status === 'OPEN') {
      return 'disputed';
    }

    if (transaction.status === TransactionStatus.COMPLETED) {
      return 'completed';
    }

    if (
      transaction.status === TransactionStatus.CANCELLED ||
      transaction.status === TransactionStatus.REFUNDED
    ) {
      return 'cancelled';
    }

    if (
      transaction.status === TransactionStatus.PENDING &&
      (transaction.buyerRespondedAt ||
        (purchaseStatus && purchaseStatus !== PurchaseStatus.PENDING))
    ) {
      return 'processing';
    }

    return 'pending';
  }

  private composeAddressFromProfile(
    profile?: {
      location?: string | null;
      ward?: string | null;
      district?: string | null;
      city?: string | null;
    } | null,
  ): string | null {
    if (!profile) {
      return null;
    }

    if (profile.location) {
      return profile.location;
    }

    const parts = [profile.ward, profile.district, profile.city].filter(
      (part): part is string => Boolean(part && part.trim().length),
    );

    return parts.length ? parts.join(', ') : null;
  }

  private mapDispute(
    transaction: TransactionWithRelations,
  ): AdminTransactionDispute | null {
    const dispute = transaction.dispute as
      | ({
          status?: DisputeStatus;
          reporterRole?: 'BUYER' | 'SELLER';
          evidence?: unknown;
          resolutionOutcome?: DisputeResolution | null;
          resolutionNotes?: string | null;
        } & {
          id: string;
          reason: string;
          description?: string | null;
          createdAt: Date;
          resolvedAt?: Date | null;
          reporter: {
            id: string;
            fullName: string;
            email: string;
            phone?: string | null;
            address?: string | null;
            avatar?: string | null;
          };
          resolvedBy?: {
            id: string;
            fullName: string;
            email: string;
          } | null;
        })
      | null
      | undefined;

    if (!dispute) {
      return null;
    }

    const evidenceArray = Array.isArray(dispute.evidence)
      ? (dispute.evidence as string[])
      : null;

    return {
      id: dispute.id,
      reporter: {
        id: dispute.reporter.id,
        name: dispute.reporter.fullName,
        role: dispute.reporterRole === 'SELLER' ? 'seller' : 'buyer',
        email: dispute.reporter.email,
        phone: dispute.reporter.phone ?? null,
      },
      reason: dispute.reason,
      description: dispute.description ?? null,
      evidence: evidenceArray,
      status: this.mapDisputeStatus(dispute.status ?? 'OPEN'),
      createdAt: dispute.createdAt.toISOString(),
      resolvedAt: dispute.resolvedAt?.toISOString() ?? null,
      resolvedBy: dispute.resolvedBy
        ? {
            id: dispute.resolvedBy.id,
            name: dispute.resolvedBy.fullName,
            email: dispute.resolvedBy.email,
          }
        : null,
      resolutionOutcome: dispute.resolutionOutcome
        ? this.mapDisputeResolution(dispute.resolutionOutcome)
        : null,
      resolutionNotes: dispute.resolutionNotes ?? null,
    };
  }

  private mapDisputeStatus(
    status: DisputeStatus,
  ): 'open' | 'in_review' | 'resolved' {
    switch (status) {
      case 'RESOLVED':
        return 'resolved';
      case 'IN_REVIEW':
        return 'in_review';
      case 'OPEN':
      default:
        return 'open';
    }
  }

  private mapDisputeResolution(
    resolution: DisputeResolution,
  ): 'buyer' | 'seller' | 'partial' {
    switch (resolution) {
      case 'SELLER':
        return 'seller';
      case 'PARTIAL':
        return 'partial';
      case 'BUYER':
      default:
        return 'buyer';
    }
  }

  private getProductCategory(transaction: TransactionWithRelations): string {
    if (transaction.vehicle) {
      return transaction.vehicle.brand
        ? `${transaction.vehicle.brand} ${transaction.vehicle.model}`.trim()
        : 'Xe điện';
    }

    if (transaction.battery) {
      return `Pin ${transaction.battery.type}`;
    }

    return 'Sản phẩm';
  }

  private getProductImage(
    transaction: TransactionWithRelations,
  ): string | null {
    const vehicleImage = transaction.vehicle?.images?.[0];
    if (vehicleImage) {
      return vehicleImage;
    }

    const batteryImage = transaction.battery?.images?.[0];
    if (batteryImage) {
      return batteryImage;
    }

    return null;
  }

  private emitChatMessage(roomId: string, payload: unknown) {
    const server = this.chatGateway?.server;
    if (!server) {
      return;
    }
    server.to(roomId).emit('chat:message', payload);
  }

  private calculateTotalAmount(transaction: {
    amount: Prisma.Decimal | number;
    fee?: Prisma.Decimal | number | null;
    commission?: Prisma.Decimal | number | null;
  }): number {
    const values = [
      transaction.amount,
      transaction.fee,
      transaction.commission,
    ];
    return values.reduce<number>((sum, value) => {
      const numeric = this.toPlainNumber(value);
      return sum + (numeric ?? 0);
    }, 0);
  }
}
