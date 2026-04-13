import { Injectable, Logger } from '@nestjs/common';
import {
  BatteryType,
  AuctionItemType,
  AccessoryCategory,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface ModerationResult {
  score: number;
  flagged: boolean;
  reasons: string[];
  baseline?: number | null;
}

interface TextualContent {
  title: string;
  description?: string | null;
  price?: number | null;
  baseline?: number | null;
  context: 'vehicle' | 'battery' | 'auction' | 'accessory';
}

interface VehicleModerationInput {
  name: string;
  brand?: string | null;
  model?: string | null;
  description?: string | null;
  price: number;
}

interface BatteryModerationInput {
  name: string;
  type: BatteryType;
  capacity: number;
  description?: string | null;
  price: number;
}

interface AuctionModerationInput {
  title: string;
  description?: string | null;
  startingPrice: number;
  itemType: 'VEHICLE' | 'BATTERY' | 'OTHER';
  itemBrand?: string | null;
  itemModel?: string | null;
  itemCapacity?: number | null;
}

interface AccessoryModerationInput {
  name: string;
  category: AccessoryCategory;
  description?: string | null;
  price: number;
}

@Injectable()
export class ContentModerationService {
  private readonly logger = new Logger(ContentModerationService.name);
  private readonly spamThreshold = 0.6;
  private readonly criticalLowPriceReason =
    'Giá quá thấp so với thị trường tham chiếu';

  private readonly persuasiveKeywords = [
    'siêu rẻ',
    'giá sốc',
    'giá shock',
    'giảm giá sốc',
    'cực rẻ',
    'siêu sốc',
    'khuyến mãi khủng',
    'free ship',
    'bao ship',
    'bảo hành trọn đời',
    'cam kết 100%',
    'bán gấp',
  ];

  private readonly urgencyKeywords = [
    'liên hệ ngay',
    'gọi ngay',
    'nhanh tay',
    'duy nhất hôm nay',
    'chỉ hôm nay',
    'số lượng có hạn',
  ];

  constructor(private readonly prisma: PrismaService) {}

  async analyzeVehicle(
    input: VehicleModerationInput,
  ): Promise<ModerationResult> {
    const baseline = await this.getVehicleBaseline(input.brand, input.model);

    return this.evaluateContent({
      title: [input.brand, input.model, input.name].filter(Boolean).join(' '),
      description: input.description,
      price: input.price,
      baseline,
      context: 'vehicle',
    });
  }

  async analyzeBattery(
    input: BatteryModerationInput,
  ): Promise<ModerationResult> {
    const baseline = await this.getBatteryBaseline(input.type, input.capacity);

    return this.evaluateContent({
      title: input.name,
      description: input.description,
      price: input.price,
      baseline,
      context: 'battery',
    });
  }

  async analyzeAuction(
    input: AuctionModerationInput,
  ): Promise<ModerationResult> {
    let baseline: number | null = null;

    if (input.itemType === AuctionItemType.VEHICLE) {
      baseline = await this.getVehicleBaseline(
        input.itemBrand,
        input.itemModel,
      );
    } else if (input.itemType === AuctionItemType.BATTERY) {
      const batteryType = this.resolveBatteryTypeFromAuction(
        input.itemBrand,
        input.itemModel,
      );
      baseline = await this.getBatteryBaseline(
        batteryType ?? BatteryType.LITHIUM_ION,
        input.itemCapacity ?? undefined,
      );
    }

    if (!baseline) {
      baseline = await this.getAuctionBaseline(
        input.itemType === AuctionItemType.VEHICLE,
        input.itemType === AuctionItemType.BATTERY,
      );
    }

    return this.evaluateContent({
      title: input.title,
      description: input.description,
      price: input.startingPrice,
      baseline,
      context: 'auction',
    });
  }

  async analyzeAccessory(
    input: AccessoryModerationInput,
  ): Promise<ModerationResult> {
    const baseline = await this.getAccessoryBaseline(input.category);

    return this.evaluateContent({
      title: input.name,
      description: input.description,
      price: input.price,
      baseline,
      context: 'accessory',
    });
  }

  private resolveBatteryTypeFromAuction(
    brand?: string | null,
    model?: string | null,
  ): BatteryType | null {
    const candidates = [model, brand]
      .map(
        (value) =>
          value
            ?.trim()
            .toUpperCase()
            .replace(/[-\s]+/g, '_') || null,
      )
      .filter((value): value is string => Boolean(value));

    for (const candidate of candidates) {
      if ((Object.values(BatteryType) as string[]).includes(candidate)) {
        return candidate as BatteryType;
      }
    }

    return null;
  }

  private async getVehicleBaseline(
    brand?: string | null,
    model?: string | null,
  ): Promise<number | null> {
    try {
      const [specific, general] = await Promise.all([
        this.prisma.vehicle.aggregate({
          where: {
            isActive: true,
            ...(brand
              ? {
                  brand: {
                    equals: brand,
                    mode: 'insensitive',
                  },
                }
              : {}),
            ...(model
              ? {
                  model: {
                    equals: model,
                    mode: 'insensitive',
                  },
                }
              : {}),
          },
          _avg: { price: true },
        }),
        this.prisma.vehicle.aggregate({
          where: { isActive: true },
          _avg: { price: true },
        }),
      ]);

      const specificAverage = Number(specific._avg.price ?? 0);
      if (specificAverage > 0) {
        return specificAverage;
      }

      const generalAverage = Number(general._avg.price ?? 0);
      return generalAverage > 0 ? generalAverage : null;
    } catch (error) {
      this.logger.warn(`Unable to compute vehicle baseline: ${error}`);
      return null;
    }
  }

  private async getBatteryBaseline(
    type: BatteryType,
    capacity?: number,
  ): Promise<number | null> {
    try {
      const capacityRange = capacity
        ? {
            gte: capacity * 0.8,
            lte: capacity * 1.2,
          }
        : undefined;

      const [specific, general] = await Promise.all([
        this.prisma.battery.aggregate({
          where: {
            isActive: true,
            type,
            ...(capacityRange ? { capacity: capacityRange } : {}),
          },
          _avg: { price: true },
        }),
        this.prisma.battery.aggregate({
          where: { isActive: true },
          _avg: { price: true },
        }),
      ]);

      const specificAverage = Number(specific._avg.price ?? 0);
      if (specificAverage > 0) {
        return specificAverage;
      }

      const generalAverage = Number(general._avg.price ?? 0);
      return generalAverage > 0 ? generalAverage : null;
    } catch (error) {
      this.logger.warn(`Unable to compute battery baseline: ${error}`);
      return null;
    }
  }

  private async getAuctionBaseline(
    hasVehicle: boolean,
    hasBattery: boolean,
  ): Promise<number | null> {
    try {
      const [vehicleStats, batteryStats] = await Promise.all([
        hasVehicle
          ? this.prisma.auction.aggregate({
              where: {
                itemType: AuctionItemType.VEHICLE,
                status: { in: ['ACTIVE', 'PENDING'] },
              },
              _avg: { startingPrice: true },
            })
          : null,
        hasBattery
          ? this.prisma.auction.aggregate({
              where: {
                itemType: AuctionItemType.BATTERY,
                status: { in: ['ACTIVE', 'PENDING'] },
              },
              _avg: { startingPrice: true },
            })
          : null,
      ]);

      const vehicleAverage = Number(vehicleStats?._avg?.startingPrice ?? 0);
      if (hasVehicle && vehicleAverage > 0) {
        return vehicleAverage;
      }

      const batteryAverage = Number(batteryStats?._avg?.startingPrice ?? 0);
      if (hasBattery && batteryAverage > 0) {
        return batteryAverage;
      }

      const general = await this.prisma.auction.aggregate({
        where: { status: { in: ['ACTIVE', 'PENDING'] } },
        _avg: { startingPrice: true },
      });

      const generalAverage = Number(general._avg?.startingPrice ?? 0);
      return generalAverage > 0 ? generalAverage : null;
    } catch (error) {
      this.logger.warn(`Unable to compute auction baseline: ${error}`);
      return null;
    }
  }

  private async getAccessoryBaseline(
    category: AccessoryCategory,
  ): Promise<number | null> {
    try {
      const [specific, general] = await Promise.all([
        this.prisma.accessory.aggregate({
          where: {
            isActive: true,
            category,
          },
          _avg: { price: true },
        }),
        this.prisma.accessory.aggregate({
          where: { isActive: true },
          _avg: { price: true },
        }),
      ]);

      const specificAverage = Number(specific._avg.price ?? 0);
      if (specificAverage > 0) {
        return specificAverage;
      }

      const generalAverage = Number(general._avg.price ?? 0);
      return generalAverage > 0 ? generalAverage : null;
    } catch (error) {
      this.logger.warn(`Unable to compute accessory baseline: ${error}`);
      return null;
    }
  }

  private evaluateContent(content: TextualContent): ModerationResult {
    const combinedText = [content.title, content.description]
      .filter(Boolean)
      .join(' ')
      .trim();

    const normalized = combinedText.toLowerCase();
    const reasons = new Set<string>();
    let score = 0;

    if (combinedText.length === 0) {
      reasons.add('Thiếu nội dung mô tả sản phẩm');
      score += 0.25;
    }

    const persuasiveHits = this.persuasiveKeywords.filter((keyword) =>
      normalized.includes(keyword),
    );
    if (persuasiveHits.length) {
      reasons.add('Từ ngữ lôi kéo/ưu đãi bất thường');
      score += Math.min(0.3, 0.15 + persuasiveHits.length * 0.05);
    }

    const urgencyHits = this.urgencyKeywords.filter((keyword) =>
      normalized.includes(keyword),
    );
    if (urgencyHits.length) {
      reasons.add('Từ ngữ thúc giục hành động bất thường');
      score += Math.min(0.2, 0.1 + urgencyHits.length * 0.04);
    }

    if (/(?:!){3,}/.test(combinedText)) {
      reasons.add('Sử dụng nhiều dấu chấm than');
      score += 0.15;
    }

    const uppercaseWords = combinedText.match(
      /\b[0-9A-ZĐÁÀẢÃẠĂÂÊẾỀỂỄỆÔƠÚÙỦŨỤƯÝỲỶỸỴ]{4,}\b/g,
    );
    if (uppercaseWords && uppercaseWords.length >= 3) {
      reasons.add('Sử dụng nhiều chữ in hoa');
      score += 0.12;
    }

    if (!content.description || content.description.trim().length < 40) {
      reasons.add('Mô tả quá ngắn, thiếu thông tin chi tiết');
      score += 0.1;
    }

    const price = content.price ?? null;
    const baseline = content.baseline ?? null;

    if (price && price > 0) {
      if (baseline && baseline > 0) {
        const ratio = price / baseline;

        if (ratio < 0.35) {
          reasons.add(this.criticalLowPriceReason);
          score += 0.45;
        } else if (ratio < 0.55) {
          reasons.add('Giá thấp hơn đáng kể so với mức trung bình');
          score += 0.28;
        } else if (ratio > 2.5) {
          reasons.add('Giá cao bất thường so với thị trường');
          score += 0.22;
        }
      } else {
        if (content.context === 'vehicle' && price < 50000000) {
          reasons.add('Giá rao không phù hợp với loại phương tiện');
          score += 0.32;
        }

        if (content.context === 'battery' && price < 300000) {
          reasons.add('Giá rao pin quá thấp so với thực tế');
          score += 0.28;
        }

        if (content.context === 'auction' && price < 1000000) {
          reasons.add('Giá khởi điểm quá thấp so với kỳ vọng');
          score += 0.25;
        }

        if (content.context === 'accessory' && price < 50000) {
          reasons.add('Giá phụ kiện quá thấp so với thực tế');
          score += 0.2;
        }
      }
    }

    const cappedScore = Math.min(1, Number(score.toFixed(2)));
    const criticalFlag = reasons.has(this.criticalLowPriceReason);
    const flagged = cappedScore >= this.spamThreshold || criticalFlag;

    return {
      score: cappedScore,
      flagged,
      reasons: Array.from(reasons),
      baseline,
    };
  }
}
