import { Injectable } from '@nestjs/common';
import { Prisma, TransactionStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateTransactionFeeDto } from './dto/update-transaction-fee.dto';
import { UpdateListingFeesDto } from './dto/update-listing-fees.dto';
import { UpdateCommissionTiersDto } from './dto/update-commission-tiers.dto';

type PrismaClientLike = PrismaService & {
  transactionFeeSetting: any;
  listingFeeTier: any;
  commissionTier: any;
  feeChangeLog: any;
};

@Injectable()
export class FeesService {
  constructor(private readonly prisma: PrismaService) {}

  private get db() {
    return this.prisma as unknown as PrismaClientLike;
  }

  async getTransactionFeeSetting() {
    const setting = await this.db.transactionFeeSetting.findUnique({
      where: { key: 'default' },
      include: {
        updatedBy: {
          select: { id: true, fullName: true, email: true },
        },
      },
    });

    if (setting) {
      return setting;
    }

    return this.db.transactionFeeSetting.create({
      data: {
        key: 'default',
        rate: new Prisma.Decimal(5),
        minFee: new Prisma.Decimal(10000),
        maxFee: new Prisma.Decimal(1000000),
      },
    });
  }

  async updateTransactionFeeSetting(
    adminId: string,
    dto: UpdateTransactionFeeDto,
  ) {
    const existing = await this.db.transactionFeeSetting.findUnique({
      where: { key: 'default' },
    });

    const updated = await this.db.transactionFeeSetting.upsert({
      where: { key: 'default' },
      update: {
        rate: new Prisma.Decimal(dto.rate),
        minFee:
          dto.minFee !== undefined ? new Prisma.Decimal(dto.minFee) : null,
        maxFee:
          dto.maxFee !== undefined ? new Prisma.Decimal(dto.maxFee) : null,
        updatedById: adminId,
      },
      create: {
        rate: new Prisma.Decimal(dto.rate),
        minFee:
          dto.minFee !== undefined ? new Prisma.Decimal(dto.minFee) : null,
        maxFee:
          dto.maxFee !== undefined ? new Prisma.Decimal(dto.maxFee) : null,
        updatedById: adminId,
      },
      include: {
        updatedBy: {
          select: { id: true, fullName: true, email: true },
        },
      },
    });

    const historyEntry = await this.logFeeChange({
      type: 'TRANSACTION_FEE',
      itemId: updated.id,
      itemName: 'Phí giao dịch',
      oldValue: existing
        ? {
            rate: this.toNumber(existing.rate),
            minFee: existing.minFee ? this.toNumber(existing.minFee) : null,
            maxFee: existing.maxFee ? this.toNumber(existing.maxFee) : null,
          }
        : null,
      newValue: {
        rate: dto.rate,
        minFee: dto.minFee ?? null,
        maxFee: dto.maxFee ?? null,
      },
      reason: dto.reason,
      updatedById: adminId,
    });

    return { setting: updated, historyEntry };
  }

  async getListingFeeTiers() {
    return this.db.listingFeeTier.findMany({
      orderBy: { order: 'asc' },
    });
  }

  async updateListingFeeTiers(adminId: string, dto: UpdateListingFeesDto) {
    const existing = await this.db.listingFeeTier.findMany({
      where: {
        id: { in: dto.tiers.filter((tier) => tier.id).map((tier) => tier.id!) },
      },
    });
    const existingMap = new Map(existing.map((tier) => [tier.id, tier]));

    const results = [] as Array<{ updated: any; historyEntry: any }>;

    for (const [index, tier] of dto.tiers.entries()) {
      const data = {
        name: tier.name,
        duration: tier.duration,
        features: tier.features,
        price: new Prisma.Decimal(tier.price),
        enabled: tier.enabled,
        order: tier.order ?? index + 1,
        updatedById: adminId,
      };

      const targetId = tier.id ?? undefined;
      const updated = targetId
        ? await this.db.listingFeeTier.update({
            where: { id: targetId },
            data,
          })
        : await this.db.listingFeeTier.create({
            data,
          });

      const previous = targetId
        ? ((existingMap.get(targetId) as any) ?? null)
        : null;

      const historyEntry = await this.logFeeChange({
        type: 'LISTING_FEE',
        itemId: updated.id,
        itemName: tier.name,
        oldValue: previous
          ? {
              name: previous.name,
              duration: previous.duration,
              features: previous.features,
              price: this.toNumber(previous.price),
              enabled: previous.enabled,
            }
          : null,
        newValue: {
          name: tier.name,
          duration: tier.duration,
          features: tier.features,
          price: tier.price,
          enabled: tier.enabled,
        },
        reason: dto.reason,
        updatedById: adminId,
      });

      results.push({ updated, historyEntry });
    }

    return results;
  }

  async getCommissionTiers() {
    return this.db.commissionTier.findMany({
      orderBy: { order: 'asc' },
    });
  }

  async updateCommissionTiers(adminId: string, dto: UpdateCommissionTiersDto) {
    const existing = await this.db.commissionTier.findMany({
      where: {
        id: { in: dto.tiers.filter((tier) => tier.id).map((tier) => tier.id!) },
      },
    });
    const existingMap = new Map(existing.map((tier) => [tier.id, tier]));

    const results = [] as Array<{ updated: any; historyEntry: any }>;

    for (const [index, tier] of dto.tiers.entries()) {
      const data = {
        name: tier.name,
        rate: new Prisma.Decimal(tier.rate),
        minRequirement: tier.minRequirement,
        requirementUnit: tier.requirementUnit,
        enabled: tier.enabled,
        order: tier.order ?? index + 1,
        updatedById: adminId,
      };

      const targetId = tier.id ?? undefined;
      const updated = targetId
        ? await this.db.commissionTier.update({
            where: { id: targetId },
            data,
          })
        : await this.db.commissionTier.create({
            data,
          });

      const previous = targetId
        ? ((existingMap.get(targetId) as any) ?? null)
        : null;

      const historyEntry = await this.logFeeChange({
        type: 'COMMISSION',
        itemId: updated.id,
        itemName: tier.name,
        oldValue: previous
          ? {
              name: previous.name,
              rate: this.toNumber(previous.rate),
              minRequirement: previous.minRequirement,
              requirementUnit: previous.requirementUnit,
              enabled: previous.enabled,
            }
          : null,
        newValue: {
          name: tier.name,
          rate: tier.rate,
          minRequirement: tier.minRequirement,
          requirementUnit: tier.requirementUnit,
          enabled: tier.enabled,
        },
        reason: dto.reason,
        updatedById: adminId,
      });

      results.push({ updated, historyEntry });
    }

    return results;
  }

  async getFeeHistory(type?: 'TRANSACTION_FEE' | 'LISTING_FEE' | 'COMMISSION') {
    return this.db.feeChangeLog.findMany({
      where: type ? { type } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        updatedBy: {
          select: { id: true, fullName: true, email: true },
        },
      },
    });
  }

  async getRevenueStats() {
    const now = new Date();
    const startOfMonth = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
    );

    const [feeAggregate, commissionAggregate] = await Promise.all([
      this.prisma.transaction.aggregate({
        _sum: { fee: true },
        where: {
          status: TransactionStatus.COMPLETED,
          createdAt: { gte: startOfMonth },
        },
      }),
      this.prisma.transaction.aggregate({
        _sum: { commission: true },
        where: {
          status: TransactionStatus.COMPLETED,
          createdAt: { gte: startOfMonth },
        },
      }),
    ]);

    const transactionFees = this.toNumber(feeAggregate._sum.fee);
    const commissionPaid = this.toNumber(commissionAggregate._sum.commission);

    return {
      totalRevenue: transactionFees,
      transactionFees,
      listingFees: 0,
      commissionPaid,
    };
  }

  private async logFeeChange(params: {
    type: 'TRANSACTION_FEE' | 'LISTING_FEE' | 'COMMISSION';
    itemId?: string;
    itemName?: string;
    oldValue?: Record<string, unknown> | null;
    newValue?: Record<string, unknown> | null;
    reason?: string;
    updatedById?: string;
  }) {
    return this.db.feeChangeLog.create({
      data: {
        type: params.type,
        itemId: params.itemId,
        itemName: params.itemName,
        oldValue: params.oldValue ?? null,
        newValue: params.newValue ?? null,
        reason: params.reason,
        updatedById: params.updatedById,
      },
    });
  }

  private toNumber(value?: Prisma.Decimal | number | null) {
    if (value === null || value === undefined) {
      return 0;
    }

    return value instanceof Prisma.Decimal ? Number(value.toString()) : value;
  }
}
