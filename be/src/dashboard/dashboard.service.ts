import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  BatteryStatus,
  Prisma,
  PurchaseStatus,
  VehicleStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { AddFavoriteDto } from './dto/add-favorite.dto';

const FAVORITE_TYPES = {
  VEHICLE: 'VEHICLE',
  BATTERY: 'BATTERY',
  AUCTION: 'AUCTION',
} as const;

type FavoriteType = (typeof FAVORITE_TYPES)[keyof typeof FAVORITE_TYPES];

export interface DashboardOrder {
  id: string;
  reference: string;
  status: PurchaseStatus;
  createdAt: Date;
  itemType: FavoriteType;
  itemName: string;
  amount: number;
  thumbnail?: string | null;
  sellerName?: string | null;
}

export interface DashboardFavorite {
  id: string;
  itemType: FavoriteType;
  title: string;
  price: number;
  thumbnail?: string | null;
  location?: string | null;
  sourceId: string | null;
  createdAt: Date;
}

type FavoriteSupportMode = 'model' | 'raw';

interface RawFavoriteRow {
  id: string;
  userId: string;
  itemType: FavoriteType;
  vehicleId: string | null;
  batteryId: string | null;
  auctionId: string | null;
  createdAt: Date;
  vehicleName?: string | null;
  vehiclePrice?: string | number | null;
  vehicleImages?: string[] | null;
  vehicleLocation?: string | null;
  batteryName?: string | null;
  batteryPrice?: string | number | null;
  batteryImages?: string[] | null;
  batteryLocation?: string | null;
  auctionTitle?: string | null;
  auctionPrice?: string | number | null;
  auctionVehicleId?: string | null;
  auctionVehicleImages?: string[] | null;
  auctionVehicleLocation?: string | null;
  auctionBatteryId?: string | null;
  auctionBatteryImages?: string[] | null;
  auctionBatteryLocation?: string | null;
}

export interface DashboardOverview {
  totalOrders: number;
  monthlyOrders: number;
  totalSpent: number;
  averageOrderValue: number;
  favoriteCount: number;
  activeListings: number;
  pendingOrders: number;
  recentOrders: DashboardOrder[];
}

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  private get favoriteModel() {
    const client = this.prisma as PrismaService & {
      favorite?: {
        count: (args: any) => Promise<number>;
        findMany: (args: any) => Promise<any[]>;
        findFirst: (args: any) => Promise<any | null>;
        delete: (args: any) => Promise<any>;
        create: (args: any) => Promise<any>;
      };
    };
    return client.favorite;
  }

  private favoriteSupportMode: FavoriteSupportMode | null = null;

  private mapFavoriteRecord(favorite: any): DashboardFavorite {
    const base: DashboardFavorite = {
      id: favorite.id,
      itemType: favorite.itemType,
      title: 'Sản phẩm',
      price: 0,
      thumbnail: null,
      location: null,
      sourceId:
        favorite.vehicleId || favorite.batteryId || favorite.auctionId || null,
      createdAt: favorite.createdAt,
    };

    const { vehicle, battery, auction } = favorite;

    if (favorite.itemType === FAVORITE_TYPES.VEHICLE) {
      return {
        ...base,
        title: vehicle?.name || 'Xe điện',
        price: vehicle?.price ? Number(vehicle.price) : 0,
        thumbnail: vehicle?.images?.[0] || null,
        location: vehicle?.location || null,
        sourceId: vehicle?.id || favorite.vehicleId || null,
      } satisfies DashboardFavorite;
    }

    if (favorite.itemType === FAVORITE_TYPES.BATTERY) {
      return {
        ...base,
        title: battery?.name || 'Pin xe điện',
        price: battery?.price ? Number(battery.price) : 0,
        thumbnail: battery?.images?.[0] || null,
        location: battery?.location || null,
        sourceId: battery?.id || favorite.batteryId || null,
      } satisfies DashboardFavorite;
    }

    return {
      ...base,
      itemType: FAVORITE_TYPES.AUCTION,
      title: auction?.title || 'Phiên đấu giá',
      price: auction?.currentPrice ? Number(auction.currentPrice) : 0,
      thumbnail:
        auction?.vehicle?.images?.[0] || auction?.battery?.images?.[0] || null,
      location:
        auction?.vehicle?.location || auction?.battery?.location || null,
      sourceId: auction?.id || favorite.auctionId || null,
    } satisfies DashboardFavorite;
  }

  private async ensureFavoriteSupport(): Promise<FavoriteSupportMode> {
    if (this.favoriteModel) {
      await this.ensureFavoriteSchema();
      this.favoriteSupportMode = 'model';
      return 'model';
    }

    if (this.favoriteSupportMode === 'raw') {
      return 'raw';
    }

    await this.ensureFavoriteSchema();
    this.favoriteSupportMode = 'raw';
    return 'raw';
  }

  private async ensureFavoriteSchema() {
    await this.prisma.$executeRawUnsafe(`
      DO $$
      BEGIN
        CREATE TYPE "public"."FavoriteItemType" AS ENUM ('VEHICLE', 'BATTERY', 'AUCTION');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    `);

    await this.prisma.$executeRawUnsafe(`
      CREATE TABLE IF NOT EXISTS "public"."favorites" (
        "id" TEXT PRIMARY KEY,
        "userId" TEXT NOT NULL,
        "itemType" "public"."FavoriteItemType" NOT NULL,
        "vehicleId" TEXT,
        "batteryId" TEXT,
        "auctionId" TEXT,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await this.prisma.$executeRawUnsafe(`
      CREATE INDEX IF NOT EXISTS "favorites_userId_idx" ON "public"."favorites"("userId");
    `);

    await this.prisma.$executeRawUnsafe(`
      CREATE INDEX IF NOT EXISTS "favorites_userId_itemType_idx" ON "public"."favorites"("userId", "itemType");
    `);

    await this.prisma.$executeRawUnsafe(`
      DO $$
      BEGIN
        ALTER TABLE "public"."favorites"
        ADD CONSTRAINT "favorites_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    `);

    await this.prisma.$executeRawUnsafe(`
      DO $$
      BEGIN
        ALTER TABLE "public"."favorites"
        ADD CONSTRAINT "favorites_vehicleId_fkey"
        FOREIGN KEY ("vehicleId") REFERENCES "public"."vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    `);

    await this.prisma.$executeRawUnsafe(`
      DO $$
      BEGIN
        ALTER TABLE "public"."favorites"
        ADD CONSTRAINT "favorites_batteryId_fkey"
        FOREIGN KEY ("batteryId") REFERENCES "public"."batteries"("id") ON DELETE SET NULL ON UPDATE CASCADE;
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    `);

    await this.prisma.$executeRawUnsafe(`
      DO $$
      BEGIN
        ALTER TABLE "public"."favorites"
        ADD CONSTRAINT "favorites_auctionId_fkey"
        FOREIGN KEY ("auctionId") REFERENCES "public"."auctions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    `);
  }

  private buildFavoriteSelectSql(
    whereClause: Prisma.Sql,
    limit?: number,
  ): Prisma.Sql {
    const limitClause = limit ? Prisma.sql`LIMIT ${limit}` : Prisma.sql``;
    return Prisma.sql`
      SELECT
        f."id",
        f."userId",
        f."itemType",
        f."vehicleId",
        f."batteryId",
        f."auctionId",
        f."createdAt",
        v."name" AS "vehicleName",
        v."price" AS "vehiclePrice",
        v."images" AS "vehicleImages",
        v."location" AS "vehicleLocation",
        b."name" AS "batteryName",
        b."price" AS "batteryPrice",
        b."images" AS "batteryImages",
        b."location" AS "batteryLocation",
        a."title" AS "auctionTitle",
        a."currentPrice" AS "auctionPrice",
        a."vehicleId" AS "auctionVehicleId",
        av."images" AS "auctionVehicleImages",
        av."location" AS "auctionVehicleLocation",
        a."batteryId" AS "auctionBatteryId",
        ab."images" AS "auctionBatteryImages",
        ab."location" AS "auctionBatteryLocation"
      FROM "public"."favorites" f
      LEFT JOIN "public"."vehicles" v ON v."id" = f."vehicleId"
      LEFT JOIN "public"."batteries" b ON b."id" = f."batteryId"
      LEFT JOIN "public"."auctions" a ON a."id" = f."auctionId"
      LEFT JOIN "public"."vehicles" av ON av."id" = a."vehicleId"
      LEFT JOIN "public"."batteries" ab ON ab."id" = a."batteryId"
      WHERE ${whereClause}
      ORDER BY f."createdAt" DESC
      ${limitClause}
    `;
  }

  private mapFavoriteRow(row: RawFavoriteRow): DashboardFavorite {
    const favoriteLike = {
      id: row.id,
      itemType: row.itemType,
      vehicleId: row.vehicleId,
      batteryId: row.batteryId,
      auctionId: row.auctionId,
      createdAt: row.createdAt,
      vehicle: row.vehicleId
        ? {
            id: row.vehicleId,
            name: row.vehicleName,
            price: row.vehiclePrice ?? 0,
            images: row.vehicleImages ?? [],
            location: row.vehicleLocation ?? null,
          }
        : null,
      battery: row.batteryId
        ? {
            id: row.batteryId,
            name: row.batteryName,
            price: row.batteryPrice ?? 0,
            images: row.batteryImages ?? [],
            location: row.batteryLocation ?? null,
          }
        : null,
      auction: row.auctionId
        ? {
            id: row.auctionId,
            title: row.auctionTitle,
            currentPrice: row.auctionPrice ?? 0,
            vehicle: row.auctionVehicleId
              ? {
                  id: row.auctionVehicleId,
                  images: row.auctionVehicleImages ?? [],
                  location: row.auctionVehicleLocation ?? null,
                }
              : null,
            battery: row.auctionBatteryId
              ? {
                  id: row.auctionBatteryId,
                  images: row.auctionBatteryImages ?? [],
                  location: row.auctionBatteryLocation ?? null,
                }
              : null,
          }
        : null,
    };

    return this.mapFavoriteRecord(favoriteLike);
  }

  private async fetchFavoriteRowByIdRaw(
    favoriteId: string,
  ): Promise<DashboardFavorite | null> {
    await this.ensureFavoriteSchema();

    const rows = await this.prisma.$queryRaw<RawFavoriteRow[]>(
      this.buildFavoriteSelectSql(Prisma.sql`f."id" = ${favoriteId}`, 1),
    );

    if (!rows.length) {
      return null;
    }

    return this.mapFavoriteRow(rows[0]);
  }

  private async listFavoritesRaw(userId: string): Promise<DashboardFavorite[]> {
    await this.ensureFavoriteSchema();

    const rows = await this.prisma.$queryRaw<RawFavoriteRow[]>(
      this.buildFavoriteSelectSql(Prisma.sql`f."userId" = ${userId}`),
    );

    return rows.map((row) => this.mapFavoriteRow(row));
  }

  private async countFavoritesRaw(userId: string): Promise<number> {
    await this.ensureFavoriteSchema();

    const result = await this.prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(*)::bigint AS "count"
      FROM "public"."favorites" f
      WHERE f."userId" = ${userId}
    `;

    return Number(result?.[0]?.count ?? 0);
  }

  private buildFavoriteWhereClause(
    userId: string,
    payload: AddFavoriteDto,
  ): Prisma.Sql {
    if (payload.vehicleId) {
      return Prisma.sql`f."userId" = ${userId} AND f."vehicleId" = ${payload.vehicleId}`;
    }

    if (payload.batteryId) {
      return Prisma.sql`f."userId" = ${userId} AND f."batteryId" = ${payload.batteryId}`;
    }

    if (payload.auctionId) {
      return Prisma.sql`f."userId" = ${userId} AND f."auctionId" = ${payload.auctionId}`;
    }

    throw new BadRequestException('Vui lòng chọn sản phẩm hợp lệ');
  }

  private async findExistingFavoriteRaw(
    userId: string,
    payload: AddFavoriteDto,
  ): Promise<DashboardFavorite | null> {
    await this.ensureFavoriteSchema();

    const rows = await this.prisma.$queryRaw<RawFavoriteRow[]>(
      this.buildFavoriteSelectSql(
        this.buildFavoriteWhereClause(userId, payload),
        1,
      ),
    );

    if (!rows.length) {
      return null;
    }

    return this.mapFavoriteRow(rows[0]);
  }

  private async addFavoriteRaw(
    userId: string,
    payload: AddFavoriteDto,
  ): Promise<DashboardFavorite> {
    await this.ensureFavoriteSchema();

    const existing = await this.findExistingFavoriteRaw(userId, payload);
    if (existing) {
      return existing;
    }

    const favoriteId = randomUUID();
    const itemType = payload.vehicleId
      ? FAVORITE_TYPES.VEHICLE
      : payload.batteryId
        ? FAVORITE_TYPES.BATTERY
        : FAVORITE_TYPES.AUCTION;

    await this.prisma.$executeRaw(
      Prisma.sql`
        INSERT INTO "public"."favorites" ("id", "userId", "itemType", "vehicleId", "batteryId", "auctionId")
        VALUES (
          ${favoriteId},
          ${userId},
          ${itemType}::"public"."FavoriteItemType",
          ${payload.vehicleId ?? null},
          ${payload.batteryId ?? null},
          ${payload.auctionId ?? null}
        )
      `,
    );

    const favorite = await this.fetchFavoriteRowByIdRaw(favoriteId);
    if (!favorite) {
      throw new NotFoundException('Không tìm thấy mục yêu thích');
    }

    return favorite;
  }

  private async removeFavoriteRaw(userId: string, favoriteId: string) {
    await this.ensureFavoriteSchema();

    const deleted = await this.prisma.$queryRaw<{ id: string }[]>(
      Prisma.sql`
        DELETE FROM "public"."favorites"
        WHERE "id" = ${favoriteId} AND "userId" = ${userId}
        RETURNING "id"
      `,
    );

    if (!deleted.length) {
      throw new NotFoundException('Không tìm thấy mục yêu thích');
    }
  }

  async getOverview(userId: string): Promise<DashboardOverview> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const supportMode = await this.ensureFavoriteSupport();
    const favoriteModel = this.favoriteModel;

    const favoriteCountPromise =
      supportMode === 'model' && favoriteModel
        ? favoriteModel.count({ where: { userId } })
        : this.countFavoritesRaw(userId);

    const [purchases, favoriteCount, activeVehicles, activeBatteries] =
      await Promise.all([
        this.prisma.purchase.findMany({
          where: { buyerId: userId },
          include: {
            transaction: {
              include: {
                vehicle: true,
                battery: true,
                seller: {
                  select: {
                    id: true,
                    fullName: true,
                  },
                },
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        }),
        favoriteCountPromise,
        this.prisma.vehicle.count({
          where: {
            sellerId: userId,
            isActive: true,
            status: { not: VehicleStatus.SOLD },
          },
        }),
        this.prisma.battery.count({
          where: {
            sellerId: userId,
            isActive: true,
            status: { not: BatteryStatus.SOLD },
          },
        }),
      ]);

    const totalOrders = purchases.length;
    const monthlyOrders = purchases.filter(
      (purchase) => purchase.createdAt >= startOfMonth,
    ).length;

    const totalSpent = purchases.reduce((sum, purchase) => {
      const amount = purchase.transaction?.amount;
      return sum + (amount ? Number(amount) : 0);
    }, 0);

    const averageOrderValue = totalOrders
      ? Math.round(totalSpent / totalOrders)
      : 0;

    const completedStatuses: PurchaseStatus[] = [
      PurchaseStatus.DELIVERED,
      PurchaseStatus.CANCELLED,
    ];

    const pendingOrders = purchases.filter(
      (purchase) => !completedStatuses.includes(purchase.status),
    ).length;

    const recentOrders = purchases.slice(0, 5).map((purchase) => {
      const { transaction } = purchase;
      const vehicle = transaction?.vehicle;
      const battery = transaction?.battery;

      const thumbnail = vehicle?.images?.[0] || battery?.images?.[0] || null;
      const itemType = vehicle
        ? FAVORITE_TYPES.VEHICLE
        : battery
          ? FAVORITE_TYPES.BATTERY
          : FAVORITE_TYPES.AUCTION;

      const itemName =
        vehicle?.name || battery?.name || transaction?.notes || 'Sản phẩm';

      return {
        id: purchase.id,
        reference: purchase.transactionId,
        status: purchase.status,
        createdAt: purchase.createdAt,
        itemType,
        itemName,
        amount: transaction?.amount ? Number(transaction.amount) : 0,
        thumbnail,
        sellerName: transaction?.seller?.fullName || null,
      } satisfies DashboardOrder;
    });

    return {
      totalOrders,
      monthlyOrders,
      totalSpent,
      averageOrderValue,
      favoriteCount,
      activeListings: activeVehicles + activeBatteries,
      pendingOrders,
      recentOrders,
    };
  }

  async getOrders(userId: string): Promise<{ orders: DashboardOrder[] }> {
    const purchases = await this.prisma.purchase.findMany({
      where: { buyerId: userId },
      include: {
        transaction: {
          include: {
            vehicle: true,
            battery: true,
            seller: {
              select: {
                id: true,
                fullName: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const orders = purchases.map((purchase) => {
      const { transaction } = purchase;
      const vehicle = transaction?.vehicle;
      const battery = transaction?.battery;

      const itemType = vehicle
        ? FAVORITE_TYPES.VEHICLE
        : battery
          ? FAVORITE_TYPES.BATTERY
          : FAVORITE_TYPES.AUCTION;

      const itemName =
        vehicle?.name || battery?.name || transaction?.notes || 'Sản phẩm';

      return {
        id: purchase.id,
        reference: purchase.transactionId,
        status: purchase.status,
        createdAt: purchase.createdAt,
        itemType,
        itemName,
        amount: transaction?.amount ? Number(transaction.amount) : 0,
        thumbnail: vehicle?.images?.[0] || battery?.images?.[0] || null,
        sellerName: transaction?.seller?.fullName || null,
      } satisfies DashboardOrder;
    });

    return { orders };
  }

  async getFavorites(
    userId: string,
  ): Promise<{ favorites: DashboardFavorite[] }> {
    const supportMode = await this.ensureFavoriteSupport();
    const favoriteModel = this.favoriteModel;

    if (supportMode === 'model' && favoriteModel) {
      const favorites = await favoriteModel.findMany({
        where: { userId },
        include: {
          vehicle: true,
          battery: true,
          auction: {
            include: {
              vehicle: true,
              battery: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      const favoriteItems = favorites.map((favorite) =>
        this.mapFavoriteRecord(favorite),
      );

      return { favorites: favoriteItems };
    }

    const favorites = await this.listFavoritesRaw(userId);
    return { favorites };
  }

  async addFavorite(
    userId: string,
    payload: AddFavoriteDto,
  ): Promise<DashboardFavorite> {
    const { vehicleId, batteryId, auctionId } = payload;
    const provided = [vehicleId, batteryId, auctionId].filter(
      (value) => !!value,
    );

    if (!provided.length) {
      throw new BadRequestException('Vui lòng chọn sản phẩm để thêm yêu thích');
    }

    if (provided.length > 1) {
      throw new BadRequestException('Chỉ được chọn một sản phẩm mỗi lần thêm');
    }

    const supportMode = await this.ensureFavoriteSupport();
    const favoriteModel = this.favoriteModel;

    if (supportMode !== 'model' || !favoriteModel) {
      return this.addFavoriteRaw(userId, payload);
    }

    const whereClause: Record<string, string> = { userId };
    if (vehicleId) {
      whereClause.vehicleId = vehicleId;
    }
    if (batteryId) {
      whereClause.batteryId = batteryId;
    }
    if (auctionId) {
      whereClause.auctionId = auctionId;
    }

    const existing = await favoriteModel.findFirst({
      where: whereClause,
      include: {
        vehicle: true,
        battery: true,
        auction: {
          include: {
            vehicle: true,
            battery: true,
          },
        },
      },
    });

    if (existing) {
      return this.mapFavoriteRecord(existing);
    }

    const itemType = vehicleId
      ? FAVORITE_TYPES.VEHICLE
      : batteryId
        ? FAVORITE_TYPES.BATTERY
        : FAVORITE_TYPES.AUCTION;

    try {
      const created = await favoriteModel.create({
        data: {
          userId,
          itemType,
          vehicleId: vehicleId ?? null,
          batteryId: batteryId ?? null,
          auctionId: auctionId ?? null,
        },
        include: {
          vehicle: true,
          battery: true,
          auction: {
            include: {
              vehicle: true,
              battery: true,
            },
          },
        },
      });

      return this.mapFavoriteRecord(created);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2003'
      ) {
        throw new NotFoundException('Sản phẩm không tồn tại hoặc đã bị xóa');
      }

      throw error;
    }
  }

  async removeFavorite(userId: string, favoriteId: string) {
    const supportMode = await this.ensureFavoriteSupport();
    const favoriteModel = this.favoriteModel;

    if (supportMode !== 'model' || !favoriteModel) {
      await this.removeFavoriteRaw(userId, favoriteId);
      return {
        message: 'Đã xóa mục yêu thích',
      };
    }

    const favorite = await favoriteModel.findFirst({
      where: {
        id: favoriteId,
        userId,
      },
    });

    if (!favorite) {
      throw new NotFoundException('Không tìm thấy mục yêu thích');
    }

    await favoriteModel.delete({ where: { id: favoriteId } });

    return {
      message: 'Đã xóa mục yêu thích',
    };
  }
}
