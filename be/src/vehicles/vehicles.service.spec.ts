import { UnauthorizedException } from '@nestjs/common';
import { VehiclesService } from './vehicles.service';
import { PrismaService } from '../prisma/prisma.service';
import { ContentModerationService } from '../moderation/content-moderation.service';
import { APPROVAL_STATUS } from '../common/approval-status.constant';
import { CreateVehicleDto, VehicleStatus } from './dto/create-vehicle.dto';

describe('VehiclesService', () => {
  let service: VehiclesService;
  let prisma: {
    vehicle: {
      create: jest.Mock;
    };
  };
  let moderation: {
    analyzeVehicle: jest.Mock;
  };

  const buildVehicleDto = (): CreateVehicleDto => ({
    name: 'VinFast VF 8 Plus',
    brand: 'VinFast',
    model: 'VF 8',
    year: 2024,
    price: 960000000,
    mileage: 5000,
    condition: 'Like new',
    description: 'Xe chính chủ, bảo dưỡng đầy đủ, không đâm đụng.',
    images: ['/uploads/listings/vf8.jpg'],
    location: 'Hà Nội',
    color: 'Xanh rêu',
    transmission: 'Tự động',
    seatCount: 5,
    hasWarranty: true,
    status: VehicleStatus.AVAILABLE,
  });

  beforeEach(() => {
    prisma = {
      vehicle: {
        create: jest.fn(),
      },
    };

    moderation = {
      analyzeVehicle: jest.fn(),
    };

    service = new VehiclesService(
      prisma as unknown as PrismaService,
      moderation as unknown as ContentModerationService,
    );
  });

  describe('create', () => {
    it('throws when sellerId is missing', async () => {
      const dto = buildVehicleDto();

      await expect(service.create(dto, undefined)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );

      expect(moderation.analyzeVehicle).not.toHaveBeenCalled();
      expect(prisma.vehicle.create).not.toHaveBeenCalled();
    });

    it('persists vehicle with pending approval and spam metadata', async () => {
      const dto = buildVehicleDto();

      const moderationResult = {
        score: 0.72,
        flagged: true,
        reasons: ['Giá quá thấp so với thị trường tham chiếu'],
      };

      const createdVehicle = {
        id: 'vehicle-1',
        ...dto,
        sellerId: 'seller-42',
        approvalStatus: APPROVAL_STATUS.PENDING,
      };

      moderation.analyzeVehicle.mockResolvedValue(moderationResult);
      prisma.vehicle.create.mockResolvedValue(createdVehicle);

      const result = await service.create(dto, 'seller-42');

      expect(moderation.analyzeVehicle).toHaveBeenCalledWith({
        name: dto.name,
        brand: dto.brand,
        model: dto.model,
        description: dto.description,
        price: dto.price,
      });

      expect(prisma.vehicle.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            sellerId: 'seller-42',
            color: dto.color,
            transmission: dto.transmission,
            seatCount: dto.seatCount,
            hasWarranty: dto.hasWarranty,
            approvalStatus: APPROVAL_STATUS.PENDING,
            spamScore: moderationResult.score,
            spamReasons: moderationResult.reasons,
            isSpamSuspicious: moderationResult.flagged,
            spamCheckedAt: expect.any(Date),
          }),
          include: expect.objectContaining({
            seller: expect.any(Object),
          }),
        }),
      );

      expect(result).toBe(createdVehicle);
    });

    it('omits spamReasons when moderation provides no reasons', async () => {
      const dto = buildVehicleDto();

      moderation.analyzeVehicle.mockResolvedValue({
        score: 0,
        flagged: false,
        reasons: [],
      });

      prisma.vehicle.create.mockResolvedValue({
        id: 'vehicle-2',
        ...dto,
        sellerId: 'seller-99',
      });

      await service.create(dto, 'seller-99');

      const createArgs = prisma.vehicle.create.mock.calls[0][0];
      expect(createArgs.data.spamReasons).toBeUndefined();
    });
  });
});
