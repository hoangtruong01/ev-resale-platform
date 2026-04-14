import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { APPROVAL_STATUS } from '../common/approval-status.constant';
import { TransactionStatus } from '@prisma/client';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview() {
    const [totalUsers, batteriesListed, vehiclesListed, totalTransactions] =
      await Promise.all([
        this.prisma.user.count({ where: { isActive: true } }),
        this.prisma.battery.count({
          where: {
            isActive: true,
            approvalStatus: APPROVAL_STATUS.APPROVED,
          },
        }),
        this.prisma.vehicle.count({
          where: {
            isActive: true,
            approvalStatus: APPROVAL_STATUS.APPROVED,
          },
        }),
        this.prisma.transaction.count({
          where: { status: TransactionStatus.COMPLETED },
        }),
      ]);

    return {
      totalUsers,
      totalTransactions,
      batteriesListed,
      vehiclesListed,
    };
  }
}
