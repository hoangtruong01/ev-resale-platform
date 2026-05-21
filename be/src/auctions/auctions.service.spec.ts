import { AuctionStatus } from '@prisma/client';
import { AuctionsService } from './auctions.service';
import { PrismaService } from '../prisma/prisma.service';
import { ContentModerationService } from '../moderation/content-moderation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { MailService } from '../mail/mail.service';
import { SmsService } from '../sms/sms.service';
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
  let mailService: jest.Mock;
  let smsService: jest.Mock;

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

    mailService = jest.fn();
    smsService = jest.fn();

    service = new AuctionsService(
      prisma as unknown as PrismaService,
      moderation as unknown as ContentModerationService,
      notifications as unknown as NotificationsService,
      mailService as unknown as MailService,
      smsService as unknown as SmsService,
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

      prisma.$transaction.mockImplementation(async (handler: unknown) =>
        (handler as (tx: unknown) => Promise<typeof updatedAuction>)({
          auction: { update: auctionUpdate },
          vehicle: { update: vehicleUpdate },
          battery: { update: batteryUpdate },
        }),
      );

      const result = await service.approve('auction-001', 'admin-1', 'OK');

      expect(prisma.auction.findUnique).toHaveBeenCalledWith({
        where: { id: 'auction-001' },
      });

      const [updateArgs] = auctionUpdate.mock.calls[0] as unknown as [
        {
          where: { id: string };
          data: {
            approvalStatus: string;
            approvedById: string;
            approvalNotes: string;
            status: AuctionStatus;
          };
          include: object;
        },
      ];
      expect(updateArgs.where).toEqual({ id: 'auction-001' });
      expect(updateArgs.data).toMatchObject({
        approvalStatus: APPROVAL_STATUS.APPROVED,
        approvedById: 'admin-1',
        approvalNotes: 'OK',
        status: AuctionStatus.ACTIVE,
      });
      expect(updateArgs.include).toBeDefined();

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

      prisma.$transaction.mockImplementation(async (handler: unknown) =>
        (handler as (tx: unknown) => Promise<typeof updatedAuction>)({
          auction: { update: auctionUpdate },
          vehicle: { update: vehicleUpdate },
          battery: { update: jest.fn() },
        }),
      );

      const result = await service.approve('auction-002', 'admin-2');

      const [updateArgs] = auctionUpdate.mock.calls[0] as unknown as [
        {
          where: { id: string };
          data: { status: AuctionStatus };
          include: object;
        },
      ];
      expect(updateArgs.where).toEqual({ id: 'auction-002' });
      expect(updateArgs.data).toMatchObject({
        status: AuctionStatus.PENDING,
      });
      expect(updateArgs.include).toBeDefined();

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

      const [findManyArgs] = prisma.auction.findMany.mock
        .calls[0] as unknown as [
        {
          where: {
            status: AuctionStatus;
            approvalStatus: string;
            startTime: { lte: Date };
          };
          select: { id: boolean };
        },
      ];
      expect(findManyArgs.where.status).toBe(AuctionStatus.PENDING);
      expect(findManyArgs.where.approvalStatus).toBe(APPROVAL_STATUS.APPROVED);
      expect(findManyArgs.where.startTime.lte).toBeInstanceOf(Date);
      expect(findManyArgs.select).toEqual({ id: true });

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
