import { Injectable } from '@nestjs/common';
import {
  Prisma,
  TransactionStatus,
  BatteryType,
  AuctionStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type AdminAnalyticsPeriod = '7d' | '30d' | '3m' | '6m' | '1y';

type ChartUnit = 'day' | 'week' | 'month';

interface MetricsSummary {
  totalRevenue: number;
  revenueTrend: number;
  totalTransactions: number;
  transactionsTrend: number;
  activeUsers: number;
  usersTrend: number;
  totalPosts: number;
  postsTrend: number;
}

interface RevenueChartSummary {
  labels: string[];
  revenue: number[];
  profit: number[];
}

interface TransactionStatsSummary {
  successful: number;
  pending: number;
  cancelled: number;
}

interface CategoryPerformanceItem {
  name: string;
  posts: number;
  revenue: number;
  percentage: number;
}

interface TopUserItem {
  id: string;
  name: string;
  avatar?: string | null;
  transactions: number;
  revenue: number;
}

interface ActivityItem {
  id: string;
  type: 'transaction' | 'user' | 'post' | 'system';
  title: string;
  value?: string | null;
  createdAt: string;
}

interface MarketTrendItem {
  category: string;
  direction: 'up' | 'down';
  change: number;
  avgPrice: number;
  volume: number;
}

interface SystemHealthSummary {
  uptime: number;
  avgLoad: number;
  errorsPerHour: number;
  avgResponseTime: number;
}

export interface AdminAnalyticsResponse {
  metrics: MetricsSummary;
  revenueChart: RevenueChartSummary;
  transactionStats: TransactionStatsSummary;
  categoryPerformance: CategoryPerformanceItem[];
  topUsers: TopUserItem[];
  recentActivities: ActivityItem[];
  marketTrends: MarketTrendItem[];
  systemHealth: SystemHealthSummary;
  generatedAt: string;
}

type TransactionGroupRow = {
  status: TransactionStatus;
  _count: {
    _all: number;
  };
};

@Injectable()
export class AdminAnalyticsService {
  private readonly periodConfig: Record<
    AdminAnalyticsPeriod,
    { days?: number; months?: number; bucket: ChartUnit }
  > = {
    '7d': { days: 7, bucket: 'day' },
    '30d': { days: 30, bucket: 'day' },
    '3m': { months: 3, bucket: 'week' },
    '6m': { months: 6, bucket: 'month' },
    '1y': { months: 12, bucket: 'month' },
  };

  constructor(private readonly prisma: PrismaService) {}

  async getAnalytics(
    period: AdminAnalyticsPeriod = '30d',
  ): Promise<AdminAnalyticsResponse> {
    const {
      startDate,
      endDate,
      previousStartDate,
      previousEndDate,
      bucketUnit,
    } = this.resolvePeriod(period);

    const transactionDateFilter = {
      createdAt: { gte: startDate, lt: endDate },
    };

    const previousTransactionDateFilter = {
      createdAt: { gte: previousStartDate, lt: previousEndDate },
    };

    const [
      currentRevenueAggregate,
      previousRevenueAggregate,
      currentTransactionCount,
      previousTransactionCount,
      statusCountsRaw,
      activeUsersCurrentResult,
      activeUsersPreviousResult,
      currentBatteryCount,
      previousBatteryCount,
      currentVehicleCount,
      previousVehicleCount,
      batteryPostRows,
      batteryRevenueRows,
      batteryRevenuePreviousRows,
      topUsersRows,
      revenueChartRows,
      avgResponseTimeRows,
      recentTransactions,
      recentUsers,
      recentBatteries,
      recentVehicles,
      recentDisputes,
      disputeCountLast24h,
      activeAuctionsCount,
    ] = await Promise.all([
      this.prisma.transaction.aggregate({
        _sum: { amount: true, fee: true, commission: true },
        where: {
          status: TransactionStatus.COMPLETED,
          createdAt: { gte: startDate, lt: endDate },
        },
      }),
      this.prisma.transaction.aggregate({
        _sum: { amount: true, fee: true, commission: true },
        where: {
          status: TransactionStatus.COMPLETED,
          createdAt: { gte: previousStartDate, lt: previousEndDate },
        },
      }),
      this.prisma.transaction.count({ where: transactionDateFilter }),
      this.prisma.transaction.count({ where: previousTransactionDateFilter }),
      this.prisma.transaction.groupBy({
        by: ['status'],
        _count: { _all: true },
        where: transactionDateFilter,
      }),
      this.prisma.$queryRaw<{ count: bigint }[]>(
        Prisma.sql`
          SELECT COUNT(*)::bigint AS count
          FROM (
            SELECT DISTINCT t."sellerId" AS "userId"
            FROM "transactions" t
            WHERE t."sellerId" IS NOT NULL
              AND t."createdAt" >= ${startDate}
              AND t."createdAt" < ${endDate}
            UNION
            SELECT DISTINCT p."buyerId" AS "userId"
            FROM "purchases" p
            INNER JOIN "transactions" t ON t."id" = p."transactionId"
            WHERE p."buyerId" IS NOT NULL
              AND t."createdAt" >= ${startDate}
              AND t."createdAt" < ${endDate}
          ) active_users
        `,
      ),
      this.prisma.$queryRaw<{ count: bigint }[]>(
        Prisma.sql`
          SELECT COUNT(*)::bigint AS count
          FROM (
            SELECT DISTINCT t."sellerId" AS "userId"
            FROM "transactions" t
            WHERE t."sellerId" IS NOT NULL
              AND t."createdAt" >= ${previousStartDate}
              AND t."createdAt" < ${previousEndDate}
            UNION
            SELECT DISTINCT p."buyerId" AS "userId"
            FROM "purchases" p
            INNER JOIN "transactions" t ON t."id" = p."transactionId"
            WHERE p."buyerId" IS NOT NULL
              AND t."createdAt" >= ${previousStartDate}
              AND t."createdAt" < ${previousEndDate}
          ) active_users
        `,
      ),
      this.prisma.battery.count({
        where: { createdAt: { gte: startDate, lt: endDate } },
      }),
      this.prisma.battery.count({
        where: { createdAt: { gte: previousStartDate, lt: previousEndDate } },
      }),
      this.prisma.vehicle.count({
        where: { createdAt: { gte: startDate, lt: endDate } },
      }),
      this.prisma.vehicle.count({
        where: { createdAt: { gte: previousStartDate, lt: previousEndDate } },
      }),
      this.prisma.$queryRaw<
        {
          type: BatteryType;
          posts: number;
        }[]
      >(
        Prisma.sql`
					SELECT "type", COUNT(*)::int AS posts
					FROM "batteries"
					WHERE "createdAt" >= ${startDate}
						AND "createdAt" < ${endDate}
					GROUP BY "type"
				`,
      ),
      this.prisma.$queryRaw<
        {
          type: BatteryType;
          revenue: Prisma.Decimal | string;
          volume: number;
        }[]
      >(
        Prisma.sql`
					SELECT b."type",
						SUM(t."amount")::numeric AS revenue,
						COUNT(*)::int AS volume
					FROM "transactions" t
					INNER JOIN "batteries" b ON b."id" = t."batteryId"
					WHERE t."status" = 'COMPLETED'
						AND t."createdAt" >= ${startDate}
						AND t."createdAt" < ${endDate}
					GROUP BY b."type"
				`,
      ),
      this.prisma.$queryRaw<
        {
          type: BatteryType;
          revenue: Prisma.Decimal | string;
          volume: number;
        }[]
      >(
        Prisma.sql`
					SELECT b."type",
						SUM(t."amount")::numeric AS revenue,
						COUNT(*)::int AS volume
					FROM "transactions" t
					INNER JOIN "batteries" b ON b."id" = t."batteryId"
					WHERE t."status" = 'COMPLETED'
						AND t."createdAt" >= ${previousStartDate}
						AND t."createdAt" < ${previousEndDate}
					GROUP BY b."type"
				`,
      ),
      this.prisma.$queryRaw<
        {
          id: string;
          fullName: string | null;
          name: string | null;
          avatar: string | null;
          revenue: Prisma.Decimal | string;
          transactions: number;
        }[]
      >(
        Prisma.sql`
					SELECT u."id",
						u."fullName",
						u."name",
						u."avatar",
						SUM(t."amount")::numeric AS revenue,
						COUNT(*)::int AS transactions
					FROM "transactions" t
					INNER JOIN "users" u ON u."id" = t."sellerId"
					WHERE t."status" = 'COMPLETED'
						AND t."createdAt" >= ${startDate}
						AND t."createdAt" < ${endDate}
					GROUP BY u."id", u."fullName", u."name", u."avatar"
					ORDER BY revenue DESC
					LIMIT 5
				`,
      ),
      this.prisma.$queryRaw<
        {
          bucket: Date;
          revenue: Prisma.Decimal | string;
          profit: Prisma.Decimal | string;
        }[]
      >(
        Prisma.sql`
					SELECT date_trunc(${Prisma.raw(`'${bucketUnit}'`)}, t."createdAt") AS bucket,
						SUM(t."amount")::numeric AS revenue,
						SUM(COALESCE(t."fee", 0) + COALESCE(t."commission", 0))::numeric AS profit
					FROM "transactions" t
					WHERE t."status" = 'COMPLETED'
						AND t."createdAt" >= ${startDate}
						AND t."createdAt" < ${endDate}
					GROUP BY bucket
					ORDER BY bucket
				`,
      ),
      this.prisma.$queryRaw<
        { avg_ms: Prisma.Decimal | string | number | null }[]
      >(
        Prisma.sql`
					SELECT AVG(EXTRACT(EPOCH FROM (t."updatedAt" - t."createdAt")) * 1000)::numeric AS avg_ms
					FROM "transactions" t
					WHERE t."status" = 'COMPLETED'
						AND t."createdAt" >= ${startDate}
						AND t."createdAt" < ${endDate}
				`,
      ),
      this.prisma.transaction.findMany({
        where: transactionDateFilter,
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: {
          id: true,
          amount: true,
          status: true,
          createdAt: true,
        },
      }),
      this.prisma.user.findMany({
        where: { createdAt: { gte: startDate, lt: endDate } },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: {
          id: true,
          fullName: true,
          email: true,
          createdAt: true,
        },
      }),
      this.prisma.battery.findMany({
        where: { createdAt: { gte: startDate, lt: endDate } },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: {
          id: true,
          name: true,
          createdAt: true,
        },
      }),
      this.prisma.vehicle.findMany({
        where: { createdAt: { gte: startDate, lt: endDate } },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: {
          id: true,
          name: true,
          createdAt: true,
        },
      }),
      this.prisma.transactionDispute.findMany({
        where: { createdAt: { gte: startDate, lt: endDate } },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: {
          id: true,
          status: true,
          createdAt: true,
        },
      }),
      this.prisma.transactionDispute.count({
        where: { createdAt: { gte: this.minusHours(endDate, 24) } },
      }),
      this.prisma.auction.count({
        where: { status: AuctionStatus.ACTIVE },
      }),
    ]);

    const totalRevenue = this.toNumber(currentRevenueAggregate._sum?.amount);
    const previousRevenue = this.toNumber(
      previousRevenueAggregate._sum?.amount,
    );
    const totalTransactions = currentTransactionCount;
    const previousTransactions = previousTransactionCount;
    const activeUsers = this.toNumber(activeUsersCurrentResult[0]?.count ?? 0);
    const previousActiveUsers = this.toNumber(
      activeUsersPreviousResult[0]?.count ?? 0,
    );
    const totalPosts = currentBatteryCount + currentVehicleCount;
    const previousTotalPosts = previousBatteryCount + previousVehicleCount;

    const metrics: MetricsSummary = {
      totalRevenue,
      revenueTrend: this.calculateTrend(totalRevenue, previousRevenue),
      totalTransactions,
      transactionsTrend: this.calculateTrend(
        totalTransactions,
        previousTransactions,
      ),
      activeUsers,
      usersTrend: this.calculateTrend(activeUsers, previousActiveUsers),
      totalPosts,
      postsTrend: this.calculateTrend(totalPosts, previousTotalPosts),
    };

    const transactionStats = this.buildTransactionStats(
      statusCountsRaw as TransactionGroupRow[],
      totalTransactions,
    );
    const revenueChart = this.buildRevenueChart(revenueChartRows, bucketUnit);
    const categoryPerformance = this.buildCategoryPerformance(
      batteryPostRows,
      batteryRevenueRows,
      totalRevenue,
    );
    const marketTrends = this.buildMarketTrends(
      batteryRevenueRows,
      batteryRevenuePreviousRows,
    );
    const topUsers = topUsersRows.map((user) => ({
      id: user.id,
      name: user.fullName || user.name || 'Unknown seller',
      avatar: user.avatar,
      transactions: user.transactions,
      revenue: Math.round(this.toNumber(user.revenue)),
    }));
    const recentActivities = this.buildRecentActivities({
      recentTransactions,
      recentUsers,
      recentBatteries,
      recentVehicles,
      recentDisputes,
    });

    const avgResponseTime = Math.round(
      this.toNumber(avgResponseTimeRows[0]?.avg_ms ?? 0),
    );
    const errorsPerHour = Math.max(0, Math.round(disputeCountLast24h / 24));
    const uptime = Number(Math.max(92, 99.5 - errorsPerHour * 0.2).toFixed(1));
    const avgLoad = Math.min(100, Math.max(30, 40 + activeAuctionsCount));
    const systemHealth: SystemHealthSummary = {
      uptime,
      avgLoad,
      errorsPerHour,
      avgResponseTime,
    };

    return {
      metrics,
      revenueChart,
      transactionStats,
      categoryPerformance,
      topUsers,
      recentActivities,
      marketTrends,
      systemHealth,
      generatedAt: endDate.toISOString(),
    };
  }

  async exportAnalytics(
    period: AdminAnalyticsPeriod = '30d',
  ): Promise<{ filename: string; content: string }> {
    const analytics = await this.getAnalytics(period);

    const lines: string[] = [];

    lines.push('Overview');
    lines.push('Metric,Value');
    lines.push(
      `Total revenue,${this.escapeCsv(this.formatCurrency(analytics.metrics.totalRevenue))}`,
    );
    lines.push(
      `Revenue change,${this.escapeCsv(`${analytics.metrics.revenueTrend}%`)}`,
    );
    lines.push(`Total transactions,${analytics.metrics.totalTransactions}`);
    lines.push(
      `Transaction change,${this.escapeCsv(`${analytics.metrics.transactionsTrend}%`)}`,
    );
    lines.push(`Active users,${analytics.metrics.activeUsers}`);
    lines.push(
      `User change,${this.escapeCsv(`${analytics.metrics.usersTrend}%`)}`,
    );
    lines.push(`New listings,${analytics.metrics.totalPosts}`);
    lines.push(
      `Listing change,${this.escapeCsv(`${analytics.metrics.postsTrend}%`)}`,
    );

    lines.push('');
    lines.push('Transaction breakdown');
    lines.push('Status,Percent (%)');
    lines.push(`Completed,${analytics.transactionStats.successful}`);
    lines.push(`Pending,${analytics.transactionStats.pending}`);
    lines.push(`Cancelled,${analytics.transactionStats.cancelled}`);

    lines.push('');
    lines.push('Revenue timeline');
    lines.push('Period,Revenue,Profit');
    analytics.revenueChart.labels.forEach((label, index) => {
      const revenue = analytics.revenueChart.revenue[index] ?? 0;
      const profit = analytics.revenueChart.profit[index] ?? 0;
      lines.push(
        `${this.escapeCsv(label)},${this.escapeCsv(this.formatCurrency(revenue))},${this.escapeCsv(this.formatCurrency(profit))}`,
      );
    });

    lines.push('');
    lines.push('Top sellers');
    lines.push('Name,Revenue,Transactions');
    analytics.topUsers.forEach((user) => {
      lines.push(
        `${this.escapeCsv(user.name)},${this.escapeCsv(this.formatCurrency(user.revenue))},${user.transactions}`,
      );
    });

    lines.push('');
    lines.push('Category performance');
    lines.push('Category,Listings,Revenue,Share (%)');
    analytics.categoryPerformance.forEach((category) => {
      lines.push(
        `${this.escapeCsv(category.name)},${category.posts},${this.escapeCsv(this.formatCurrency(category.revenue))},${category.percentage}`,
      );
    });

    lines.push('');
    lines.push('Market trends');
    lines.push('Category,Direction,Change (%),Average price,Volume');
    analytics.marketTrends.forEach((trend) => {
      lines.push(
        `${this.escapeCsv(trend.category)},${trend.direction === 'up' ? 'Up' : 'Down'},${trend.change},${this.escapeCsv(this.formatCurrency(trend.avgPrice))},${trend.volume}`,
      );
    });

    lines.push('');
    lines.push('Recent activities');
    lines.push('Type,Details,Value,Timestamp');
    analytics.recentActivities.forEach((activity) => {
      lines.push(
        `${activity.type},${this.escapeCsv(activity.title)},${this.escapeCsv(activity.value ?? '')},${activity.createdAt}`,
      );
    });

    const today = new Date();
    const filename = `analytics-report-${period}-${this.formatDateForFilename(today)}.csv`;
    const content = `\ufeff${lines.join('\n')}`;

    return { filename, content };
  }

  private resolvePeriod(period: AdminAnalyticsPeriod) {
    const config = this.periodConfig[period] ?? this.periodConfig['30d'];
    const endDate = new Date();
    const startDate = this.subtractPeriod(new Date(endDate), config);
    startDate.setUTCHours(0, 0, 0, 0);

    const previousEndDate = new Date(startDate);
    const previousStartDate = this.subtractPeriod(
      new Date(previousEndDate),
      config,
    );
    previousStartDate.setUTCHours(0, 0, 0, 0);

    return {
      startDate,
      endDate,
      previousStartDate,
      previousEndDate,
      bucketUnit: config.bucket,
    };
  }

  private subtractPeriod(
    date: Date,
    config: { days?: number; months?: number },
  ): Date {
    const result = new Date(date);
    if (config.days) {
      result.setUTCDate(result.getUTCDate() - config.days);
    }
    if (config.months) {
      result.setUTCMonth(result.getUTCMonth() - config.months);
    }
    return result;
  }

  private buildTransactionStats(
    rows: TransactionGroupRow[],
    totalTransactions: number,
  ): TransactionStatsSummary {
    if (!rows.length || totalTransactions === 0) {
      return { successful: 0, pending: 0, cancelled: 0 };
    }

    const denominator = rows.reduce((sum, row) => sum + row._count._all, 0);

    let successful = 0;
    let pending = 0;
    let cancelled = 0;

    rows.forEach((row) => {
      const share = Math.round((row._count._all / denominator) * 100);
      switch (row.status) {
        case TransactionStatus.COMPLETED:
          successful += share;
          break;
        case TransactionStatus.PENDING:
          pending += share;
          break;
        case TransactionStatus.CANCELLED:
        case TransactionStatus.REFUNDED:
          cancelled += share;
          break;
        default:
          pending += share;
      }
    });

    const totalPercent = successful + pending + cancelled;
    if (totalPercent > 100) {
      const excess = totalPercent - 100;
      pending = Math.max(0, pending - excess);
    }

    return {
      successful: Math.min(100, successful),
      pending: Math.min(100, pending),
      cancelled: Math.min(100, cancelled),
    };
  }

  private buildRevenueChart(
    rows: {
      bucket: Date;
      revenue: Prisma.Decimal | string;
      profit: Prisma.Decimal | string;
    }[],
    unit: ChartUnit,
  ): RevenueChartSummary {
    if (!rows.length) {
      return { labels: [], revenue: [], profit: [] };
    }

    const sorted = [...rows].sort(
      (a, b) => new Date(a.bucket).getTime() - new Date(b.bucket).getTime(),
    );

    const labels = sorted.map((row) =>
      this.formatChartLabel(new Date(row.bucket), unit),
    );
    const revenue = sorted.map((row) => Math.round(this.toNumber(row.revenue)));
    const profit = sorted.map((row) => Math.round(this.toNumber(row.profit)));

    return { labels, revenue, profit };
  }

  private buildCategoryPerformance(
    posts: { type: BatteryType; posts: number }[],
    revenueRows: {
      type: BatteryType;
      revenue: Prisma.Decimal | string;
      volume: number;
    }[],
    totalRevenue: number,
  ): CategoryPerformanceItem[] {
    const map = new Map<
      BatteryType,
      { posts: number; revenue: number; volume: number }
    >();

    posts.forEach((row) => {
      map.set(row.type, { posts: row.posts, revenue: 0, volume: 0 });
    });

    revenueRows.forEach((row) => {
      const existing = map.get(row.type) ?? { posts: 0, revenue: 0, volume: 0 };
      existing.revenue = this.toNumber(row.revenue);
      existing.volume = row.volume;
      map.set(row.type, existing);
    });

    const overallRevenue =
      totalRevenue > 0
        ? totalRevenue
        : Array.from(map.values()).reduce((sum, item) => sum + item.revenue, 0);

    return Array.from(map.entries())
      .map(([type, value]) => {
        const percentage = overallRevenue
          ? Math.min(100, Math.round((value.revenue / overallRevenue) * 100))
          : 0;
        return {
          name: this.formatCategoryLabel(type),
          posts: value.posts,
          revenue: Math.round(value.revenue),
          percentage,
        };
      })
      .sort((a, b) => b.revenue - a.revenue);
  }

  private buildMarketTrends(
    current: {
      type: BatteryType;
      revenue: Prisma.Decimal | string;
      volume: number;
    }[],
    previous: {
      type: BatteryType;
      revenue: Prisma.Decimal | string;
      volume: number;
    }[],
  ): MarketTrendItem[] {
    const previousMap = new Map<
      BatteryType,
      { revenue: number; volume: number }
    >();

    previous.forEach((row) => {
      previousMap.set(row.type, {
        revenue: this.toNumber(row.revenue),
        volume: row.volume,
      });
    });

    return current
      .map((row) => {
        const currentRevenue = this.toNumber(row.revenue);
        const previousEntry = previousMap.get(row.type) ?? {
          revenue: 0,
          volume: 0,
        };
        const change = this.calculateTrend(
          currentRevenue,
          previousEntry.revenue,
        );
        const direction: 'up' | 'down' = change >= 0 ? 'up' : 'down';
        const volume = row.volume;
        const avgPrice = volume ? Math.round(currentRevenue / volume) : 0;

        return {
          category: this.formatCategoryLabel(row.type),
          direction,
          change: Math.abs(change),
          avgPrice,
          volume,
        };
      })
      .sort((a, b) => b.volume - a.volume);
  }

  private buildRecentActivities(params: {
    recentTransactions: {
      id: string;
      amount: Prisma.Decimal;
      status: TransactionStatus;
      createdAt: Date;
    }[];
    recentUsers: {
      id: string;
      fullName: string | null;
      email: string;
      createdAt: Date;
    }[];
    recentBatteries: {
      id: string;
      name: string | null;
      createdAt: Date;
    }[];
    recentVehicles: {
      id: string;
      name: string | null;
      createdAt: Date;
    }[];
    recentDisputes: {
      id: string;
      status: string;
      createdAt: Date;
    }[];
  }): ActivityItem[] {
    const activities: ActivityItem[] = [];

    params.recentTransactions.forEach((tx) => {
      activities.push({
        id: `transaction-${tx.id}`,
        type: 'transaction',
        title: `Transaction ${this.formatTransactionStatus(tx.status)}`,
        value: this.formatCurrency(this.toNumber(tx.amount)),
        createdAt: tx.createdAt.toISOString(),
      });
    });

    params.recentUsers.forEach((user) => {
      activities.push({
        id: `user-${user.id}`,
        type: 'user',
        title: `New user: ${user.fullName || user.email}`,
        createdAt: user.createdAt.toISOString(),
      });
    });

    params.recentBatteries.forEach((battery) => {
      activities.push({
        id: `battery-${battery.id}`,
        type: 'post',
        title: `Battery listing: ${battery.name || 'Unnamed battery'}`,
        createdAt: battery.createdAt.toISOString(),
      });
    });

    params.recentVehicles.forEach((vehicle) => {
      activities.push({
        id: `vehicle-${vehicle.id}`,
        type: 'post',
        title: `Vehicle listing: ${vehicle.name || 'Unnamed vehicle'}`,
        createdAt: vehicle.createdAt.toISOString(),
      });
    });

    params.recentDisputes.forEach((dispute) => {
      activities.push({
        id: `dispute-${dispute.id}`,
        type: 'system',
        title: `Dispute updated (${dispute.status})`,
        createdAt: dispute.createdAt.toISOString(),
      });
    });

    return activities
      .sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
      )
      .slice(0, 20);
  }

  private calculateTrend(current: number, previous: number): number {
    if (previous === 0) {
      return current === 0 ? 0 : 100;
    }
    return Math.round(((current - previous) / previous) * 100);
  }

  private formatChartLabel(date: Date, unit: ChartUnit): string {
    const options: Intl.DateTimeFormatOptions = (() => {
      if (unit === 'day') {
        return { month: 'short', day: 'numeric' };
      }
      if (unit === 'week') {
        return { month: 'short', day: 'numeric' };
      }
      return { month: 'short', year: 'numeric' };
    })();

    return new Intl.DateTimeFormat('en-US', options).format(date);
  }

  private formatCategoryLabel(type: BatteryType): string {
    return type
      .toLowerCase()
      .split('_')
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(' ');
  }

  private formatTransactionStatus(status: TransactionStatus): string {
    switch (status) {
      case TransactionStatus.COMPLETED:
        return 'completed';
      case TransactionStatus.PENDING:
        return 'pending';
      case TransactionStatus.CANCELLED:
        return 'cancelled';
      case TransactionStatus.REFUNDED:
        return 'refunded';
      default:
        return 'updated';
    }
  }

  private escapeCsv(value: string | number | null | undefined): string {
    if (value === null || value === undefined) {
      return '';
    }
    const normalized = String(value);
    if (/[",\n]/.test(normalized)) {
      return `"${normalized.replace(/"/g, '""')}"`;
    }
    return normalized;
  }

  private formatCurrency(value: number): string {
    const formatted = Math.round(value).toLocaleString('en-US');
    return `${formatted} VND`;
  }

  private formatDateForFilename(date: Date): string {
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');
    return `${year}${month}${day}`;
  }

  private toNumber(
    value: Prisma.Decimal | string | number | bigint | null | undefined,
  ): number {
    if (value === null || value === undefined) {
      return 0;
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'bigint') {
      return Number(value);
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      return Number.isNaN(parsed) ? 0 : parsed;
    }
    return Number(value.toString());
  }

  private minusHours(date: Date, hours: number): Date {
    const result = new Date(date);
    result.setTime(result.getTime() - hours * 60 * 60 * 1000);
    return result;
  }
}
