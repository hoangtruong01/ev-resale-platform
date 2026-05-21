import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { ServiceUnavailableException } from '@nestjs/common';
import { GUARDS_METADATA } from '@nestjs/common/constants';
import { ConfigService } from '@nestjs/config';
import { AccessoryCategory, BatteryType } from '@prisma/client';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

type MockConfig = {
  get: jest.MockedFunction<(key: string) => string | undefined>;
};

type MockPrisma = {
  vehicle: { findMany: jest.MockedFunction<() => Promise<unknown[]>> };
  battery: { findMany: jest.MockedFunction<() => Promise<unknown[]>> };
  accessory: { findMany: jest.MockedFunction<() => Promise<unknown[]>> };
};

type CallGemini = (
  model: string,
  apiKey: string,
  prompt: string,
) => Promise<string>;

type AiServicePrivate = {
  callGemini: jest.MockedFunction<CallGemini>;
};

const geminiEstimate = JSON.stringify({
  estimatedPrice: 650000000,
  minPrice: 580000000,
  maxPrice: 720000000,
  confidence: 'medium',
  factors: ['brand/model input', 'condition input'],
  assumptions: ['limited market data'],
});

describe('AiService', () => {
  let service: AiService;
  let config: MockConfig;
  let prisma: MockPrisma;

  beforeEach(() => {
    config = { get: jest.fn<(key: string) => string | undefined>() };
    prisma = {
      vehicle: { findMany: jest.fn<() => Promise<unknown[]>>() },
      battery: { findMany: jest.fn<() => Promise<unknown[]>>() },
      accessory: { findMany: jest.fn<() => Promise<unknown[]>>() },
    };
    service = new AiService(
      config as unknown as ConfigService,
      prisma as unknown as PrismaService,
    );
    jest.restoreAllMocks();
  });

  it('redacts sensitive context keys before provider call', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY' ? 'test-key' : undefined,
    );
    const callGemini = jest.fn<CallGemini>().mockResolvedValue('Xin chào');
    (service as unknown as AiServicePrivate).callGemini = callGemini;

    await service.chat({
      message: 'Tư vấn xe điện',
      context: {
        accessToken: 'access-token-value',
        Authorization: 'Bearer secret-token',
        cookie: 'sid=secret',
        email: 'user@example.com',
        phone: '0900000000',
        nested: {
          refresh_token: 'refresh-token-value',
          publicInfo: 'VF8',
        },
      },
    });

    const prompt = callGemini.mock.calls[0][2];
    expect(prompt).toContain('[REDACTED]');
    expect(prompt).toContain('VF8');
    expect(prompt).not.toContain('access-token-value');
    expect(prompt).not.toContain('refresh-token-value');
    expect(prompt).not.toContain('Bearer secret-token');
    expect(prompt).not.toContain('user@example.com');
    expect(prompt).not.toContain('0900000000');
  });

  it('returns generic service unavailable when provider fails', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY' ? 'test-key' : undefined,
    );
    (service as unknown as AiServicePrivate).callGemini = jest
      .fn<CallGemini>()
      .mockRejectedValue(
        new Error('Gemini request failed: 503 provider secret'),
      );

    await expect(service.chat({ message: 'Tư vấn xe điện' })).rejects.toThrow(
      ServiceUnavailableException,
    );
  });

  it('vehicle no comparable uses Gemini AI_ESTIMATION fallback', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'gemini-test'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    const callGemini = jest.fn<CallGemini>().mockResolvedValue(geminiEstimate);
    (service as unknown as AiServicePrivate).callGemini = callGemini;

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result).toMatchObject({
      itemType: 'vehicle',
      suggestedPrice: 650000000,
      priceRange: { min: 580000000, max: 720000000 },
      confidence: 'medium',
      comparableCount: 0,
    });
    expect(result.factors).toContain('ai_estimation_fallback');
    expect(result.factors).toContain('provider: gemini');
    expect(result.factors).toContain('low_comparable_data');
    expect(callGemini).toHaveBeenCalledTimes(1);
    expect(callGemini.mock.calls[0][2]).toContain('OUTPUT:');
  });

  it('vehicle no comparable with invalid Gemini JSON safely falls back to null', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'gemini-test'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    const callGemini = jest.fn<CallGemini>().mockResolvedValue('not-json');
    (service as unknown as AiServicePrivate).callGemini = callGemini;

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result).toMatchObject({
      itemType: 'vehicle',
      suggestedPrice: null,
      priceRange: { min: null, max: null },
      confidence: 'low',
      comparableCount: 0,
    });
    expect(result.factors).toContain('no_comparable_data');
    expect(callGemini).toHaveBeenCalledTimes(1);
  });

  it('battery no comparable with missing Gemini key safely falls back to null', async () => {
    config.get.mockReturnValue(undefined);
    prisma.battery.findMany.mockResolvedValue([]);
    const callGemini = jest.fn<CallGemini>();
    (service as unknown as AiServicePrivate).callGemini = callGemini;

    const result = await service.suggestBatteryPrice({
      type: BatteryType.LITHIUM_ION,
      capacity: 60,
      condition: 85,
      soh: 90,
    });

    expect(result).toMatchObject({
      itemType: 'battery',
      suggestedPrice: null,
      priceRange: { min: null, max: null },
      confidence: 'low',
      comparableCount: 0,
    });
    expect(result.factors).toContain('no_comparable_data');
    expect(callGemini).not.toHaveBeenCalled();
  });

  it('accessory no comparable uses Gemini AI_ESTIMATION fallback and never high confidence', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'gemini-test'
          : undefined,
    );
    prisma.accessory.findMany.mockResolvedValue([]);
    const callGemini = jest.fn<CallGemini>().mockResolvedValue(
      JSON.stringify({
        estimatedPrice: 2000000,
        minPrice: 1500000,
        maxPrice: 2500000,
        confidence: 'high',
        factors: ['category input'],
        assumptions: ['limited data'],
      }),
    );
    (service as unknown as AiServicePrivate).callGemini = callGemini;

    const result = await service.suggestAccessoryPrice({
      category: AccessoryCategory.CHARGER,
      brand: 'VinFast',
      compatibleModel: 'VF8',
      condition: 'good',
    });

    expect(result).toMatchObject({
      itemType: 'accessory',
      suggestedPrice: 2000000,
      confidence: 'low',
      comparableCount: 0,
    });
    expect(result.confidence).not.toBe('high');
    expect(result.factors).toContain('ai_estimation_fallback');
  });

  it('vehicle with three comparables keeps deterministic flow and does not call Gemini', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'gemini-test'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([
      {
        price: 600000000,
        year: 2024,
        mileage: 10000,
        condition: 'good',
        location: 'HCM',
      },
      {
        price: 620000000,
        year: 2024,
        mileage: 12000,
        condition: 'good',
        location: 'HN',
      },
      {
        price: 640000000,
        year: 2023,
        mileage: 15000,
        condition: 'good',
        location: 'DN',
      },
    ]);
    const callGemini = jest.fn<CallGemini>();
    (service as unknown as AiServicePrivate).callGemini = callGemini;

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result.suggestedPrice).not.toBeNull();
    expect(result.comparableCount).toBe(3);
    expect(result.factors).toContain('market_data_available');
    expect(result.factors).not.toContain('ai_estimation_fallback');
    expect(callGemini).not.toHaveBeenCalled();
  });
});

describe('AiController guards', () => {
  const guardedMethods = [
    'suggestVehiclePrice',
    'suggestBatteryPrice',
    'suggestAccessoryPrice',
  ] as const;

  it.each(guardedMethods)('%s uses JwtAuthGuard', (methodName) => {
    const guards = Reflect.getMetadata(
      GUARDS_METADATA,
      AiController.prototype[methodName],
    ) as unknown[] | undefined;

    expect(guards).toContain(JwtAuthGuard);
  });
});
