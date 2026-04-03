import { AuctionStatus, VehicleStatus } from '@prisma/client';
import { AuctionsService } from './auctions.service';
import { PrismaService } from '../prisma/prisma.service';
import { ContentModerationService } from '../moderation/content-moderation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { APPROVAL_STATUS } from '../common/approval-status.constant';

describe('AuctionsService', () => {
  let service: AuctionsService;
  let prisma: {
    auction: {
      findUnique: jest.Mock;
      findMany: jest.Mock;
      updateMany: jest.Mock;
    };
    vehicle: {
      update: jest.Mock;
    };
    battery: {
      update: jest.Mock;
    };
    $transaction: jest.Mock;
  };
  let moderation: { analyzeAuction: jest.Mock };
  let notifications: { create: jest.Mock };

  beforeEach(() => {
    prisma = {
      auction: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        updateMany: jest.fn(),
      },
      vehicle: {
        update: jest.fn(),
      },
      battery: {
        update: jest.fn(),
      },
      $transaction: jest.fn(),
    };

    moderation = {
      analyzeAuction: jest.fn(),
    };

    notifications = {
      create: jest.fn(),
    };

    service = new AuctionsService(
      prisma as unknown as PrismaService,
      moderation as unknown as ContentModerationService,
      notifications as unknown as NotificationsService,
    );
  });

  describe('approve', () => {
    it('activates auction immediately when start time has passed', async () => {
      const startTime = new Date(Date.now() - 60_000);
      const auctionRecord = {
        id: 'auction-001',
        startTime,
        vehicleId: 'vehicle-777',
        batteryId: null,
      };

      const updatedAuction = {
        ...auctionRecord,
        status: AuctionStatus.ACTIVE,
        approvalStatus: APPROVAL_STATUS.APPROVED,
      };

      prisma.auction.findUnique.mockResolvedValue(auctionRecord);

      const auctionUpdate = jest.fn().mockResolvedValue(updatedAuction);
      const vehicleUpdate = jest.fn().mockResolvedValue(undefined);
      const batteryUpdate = jest.fn();

      prisma.$transaction.mockImplementation(async (handler) =>
        handler({
          auction: { update: auctionUpdate },
          vehicle: { update: vehicleUpdate },
          battery: { update: batteryUpdate },
        }),
      );

      const result = await service.approve('auction-001', 'admin-1', 'OK');

      expect(prisma.auction.findUnique).toHaveBeenCalledWith({
        where: { id: 'auction-001' },
        include: {
          vehicle: { select: { id: true } },
          battery: { select: { id: true } },
        },
      });

      expect(auctionUpdate).toHaveBeenCalledWith({
        where: { id: 'auction-001' },
        data: expect.objectContaining({
          approvalStatus: APPROVAL_STATUS.APPROVED,
          approvedById: 'admin-1',
          approvalNotes: 'OK',
          status: AuctionStatus.ACTIVE,
        }),
        include: expect.any(Object),
      });

      expect(vehicleUpdate).toHaveBeenCalledWith({
        where: { id: 'vehicle-777' },
        data: { status: VehicleStatus.AUCTION },
      });

      expect(batteryUpdate).not.toHaveBeenCalled();
      expect(result).toBe(updatedAuction);
    });

    it('keeps auction pending when start time is in the future', async () => {
      const startTime = new Date(Date.now() + 10 * 60_000);
      const auctionRecord = {
        id: 'auction-002',
        startTime,
        vehicleId: 'vehicle-888',
        batteryId: null,
      };

      const updatedAuction = {
        ...auctionRecord,
        status: AuctionStatus.PENDING,
        approvalStatus: APPROVAL_STATUS.APPROVED,
      };

      prisma.auction.findUnique.mockResolvedValue(auctionRecord);

      const auctionUpdate = jest.fn().mockResolvedValue(updatedAuction);
      const vehicleUpdate = jest.fn();

      prisma.$transaction.mockImplementation(async (handler) =>
        handler({
          auction: { update: auctionUpdate },
          vehicle: { update: vehicleUpdate },
          battery: { update: jest.fn() },
        }),
      );

      const result = await service.approve('auction-002', 'admin-2');

      expect(auctionUpdate).toHaveBeenCalledWith({
        where: { id: 'auction-002' },
        data: expect.objectContaining({
          status: AuctionStatus.PENDING,
        }),
        include: expect.any(Object),
      });

      expect(vehicleUpdate).toHaveBeenCalledWith({
        where: { id: 'vehicle-888' },
        data: { status: VehicleStatus.AUCTION },
      });

      expect(result).toBe(updatedAuction);
    });
  });

  describe('activateScheduledAuctions', () => {
    it('activates approved auctions whose start time has arrived', async () => {
      prisma.auction.findMany.mockResolvedValue([
        { id: 'auction-a' },
        { id: 'auction-b' },
      ]);
      prisma.auction.updateMany.mockResolvedValue({ count: 2 });

      const activated = await service.activateScheduledAuctions();

      expect(prisma.auction.findMany).toHaveBeenCalledWith({
        where: {
          status: AuctionStatus.PENDING,
          approvalStatus: APPROVAL_STATUS.APPROVED,
          startTime: { lte: expect.any(Date) },
        },
        select: { id: true },
      });

      expect(prisma.auction.updateMany).toHaveBeenCalledWith({
        where: { id: { in: ['auction-a', 'auction-b'] } },
        data: { status: AuctionStatus.ACTIVE },
      });

      expect(activated).toBe(2);
    });

    it('returns zero when no auctions need activation', async () => {
      prisma.auction.findMany.mockResolvedValue([]);

      const activated = await service.activateScheduledAuctions();

      expect(prisma.auction.updateMany).not.toHaveBeenCalled();
      expect(activated).toBe(0);
    });
  });
});
