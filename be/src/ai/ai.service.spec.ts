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
  confidence: 'MEDIUM',
  factors: ['brand/model input', 'condition input'],
  explanation: 'limited market data',
});

const mockGeminiFetch = (texts: string[]) => {
  const queue = [...texts];
  const fetchMock = jest.fn<typeof fetch>().mockImplementation(async () => {
    const text = queue.shift() ?? texts[texts.length - 1] ?? '';
    return {
      ok: true,
      status: 200,
      json: async () => ({
        candidates: [{ finishReason: 'STOP', content: { parts: [{ text }] } }],
        usageMetadata: { totalTokenCount: 10 },
      }),
    } as Response;
  });
  global.fetch = fetchMock;
  return fetchMock;
};

const mockStatusFetch = (statuses: number[]) => {
  const queue = [...statuses];
  const fetchMock = jest.fn<typeof fetch>().mockImplementation(async () => {
    const status = queue.shift() ?? statuses[statuses.length - 1] ?? 500;
    return {
      ok: status >= 200 && status < 300,
      status,
      json: async () => ({}),
    } as Response;
  });
  global.fetch = fetchMock;
  return fetchMock;
};

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
        nested: { refresh_token: 'refresh-token-value', publicInfo: 'VF8' },
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
    const fetchMock = mockGeminiFetch([geminiEstimate]);

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
    expect(result.factors).toContain('provider: gemini');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('Gemini markdown JSON is parsed', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'm1'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    mockGeminiFetch([`\`\`\`json\n${geminiEstimate}\n\`\`\``]);

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result.suggestedPrice).toBe(650000000);
  });

  it('Gemini truncated only estimatedPrice is rejected and falls to heuristic without guessing 98', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'm1'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    mockGeminiFetch(['{"estimatedPrice":98']);

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result.suggestedPrice).not.toBe(98);
    expect(result.factors).toContain('heuristic_estimation_fallback');
  });

  it('Gemini 429 moves to next model/provider', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'm1'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    const fetchMock = mockStatusFetch([429, 429, 429, 429, 429]);

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(fetchMock).toHaveBeenCalled();
    expect(result.factors).toContain('heuristic_estimation_fallback');
  });

  it('Gemini all fail then Groq valid JSON is used', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'm1'
          : key === 'GROQ_API_KEY'
            ? 'groq-key'
            : key === 'GROQ_PRICE_MODELS'
              ? 'g1'
              : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    const fetchMock = jest
      .fn<typeof fetch>()
      .mockImplementation(async (url) => {
        if (String(url).includes('googleapis')) {
          return { ok: false, status: 429, json: async () => ({}) } as Response;
        }
        return {
          ok: true,
          status: 200,
          json: async () => ({
            choices: [
              { finish_reason: 'stop', message: { content: geminiEstimate } },
            ],
          }),
        } as Response;
      });
    global.fetch = fetchMock;

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result.suggestedPrice).toBe(650000000);
    expect(result.factors).toContain('provider: groq');
  });

  it('Groq 400 response_format retries without response_format', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GROQ_API_KEY'
        ? 'groq-key'
        : key === 'GROQ_PRICE_MODELS'
          ? 'g1'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    const fetchMock = jest
      .fn<typeof fetch>()
      .mockResolvedValueOnce({
        ok: false,
        status: 400,
        json: async () => ({}),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          choices: [{ message: { content: geminiEstimate } }],
        }),
      } as Response);
    global.fetch = fetchMock;

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(result.factors).toContain('provider: groq');
  });

  it('Groq fail then heuristic is used', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GROQ_API_KEY'
        ? 'groq-key'
        : key === 'GROQ_PRICE_MODELS'
          ? 'g1'
          : undefined,
    );
    prisma.vehicle.findMany.mockResolvedValue([]);
    mockStatusFetch([500, 500]);

    const result = await service.suggestVehiclePrice({
      brand: 'VinFast',
      model: 'VF8',
      year: 2024,
      mileage: 10000,
      condition: 'good',
    });

    expect(result.suggestedPrice).not.toBeNull();
    expect(result.priceRange.min).not.toBeNull();
    expect(result.priceRange.max).not.toBeNull();
    expect(result.factors).toContain('heuristic_estimation_fallback');
  });

  it('battery no comparable with missing providers uses heuristic fallback', async () => {
    config.get.mockReturnValue(undefined);
    prisma.battery.findMany.mockResolvedValue([]);

    const result = await service.suggestBatteryPrice({
      type: BatteryType.LITHIUM_ION,
      capacity: 60,
      condition: 85,
      soh: 90,
    });

    expect(result.suggestedPrice).not.toBeNull();
    expect(result.factors).toContain('heuristic_estimation_fallback');
  });

  it('accessory no comparable uses Gemini fallback and never high confidence', async () => {
    config.get.mockImplementation((key: string) =>
      key === 'GEMINI_API_KEY'
        ? 'test-key'
        : key === 'GEMINI_MODEL'
          ? 'gemini-test'
          : undefined,
    );
    prisma.accessory.findMany.mockResolvedValue([]);
    mockGeminiFetch([
      JSON.stringify({
        estimatedPrice: 2000000,
        minPrice: 1500000,
        maxPrice: 2500000,
        confidence: 'HIGH',
        factors: ['category input'],
        explanation: 'limited data',
      }),
    ]);

    const result = await service.suggestAccessoryPrice({
      category: AccessoryCategory.CHARGER,
      brand: 'VinFast',
      compatibleModel: 'VF8',
      condition: 'good',
    });

    expect(result.suggestedPrice).toBe(2000000);
    expect(result.confidence).toBe('high');
    expect(result.factors).toContain('provider: gemini');
  });

  it('vehicle with three comparables keeps deterministic flow and does not call providers/heuristic', async () => {
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
    const fetchMock = jest.fn<typeof fetch>();
    global.fetch = fetchMock;

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
    expect(fetchMock).not.toHaveBeenCalled();
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
