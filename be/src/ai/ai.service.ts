import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiChatHistoryItemDto, AiChatRequestDto } from './dto/ai-chat.dto';
import {
  AiAccessoryPriceSuggestionDto,
  AiBatteryPriceSuggestionDto,
  AiVehiclePriceSuggestionDto,
} from './dto/ai-price-suggestion.dto';
import { PrismaService } from '../prisma/prisma.service';
import { estimatePriceWithHeuristic } from './heuristic-price-estimator';
import { GeminiPriceProvider } from './providers/gemini-price.provider';
import { GroqPriceProvider } from './providers/groq-price.provider';
import {
  PriceEstimateInput,
  PriceEstimateResult,
} from './providers/price-ai-provider';

const MAX_HISTORY_ITEMS = 5;
const MAX_CONTEXT_CHARS = 1500;
const MAX_CONTEXT_KEYS = 20;
const MAX_CONTEXT_DEPTH = 3;
const MAX_CONTEXT_ARRAY_ITEMS = 10;
const MAX_CONTEXT_STRING_CHARS = 300;
const GEMINI_TIMEOUT_MS = 10000;
const MAX_RESPONSE_WORDS = 500;
const MIN_COMPARABLES = 3;
const MAX_COMPARABLES = 30;
const SENSITIVE_CONTEXT_KEYS = new Set([
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'cookie',
  'password',
  'secret',
  'apikey',
  'key',
  'email',
  'phone',
  'jwt',
]);

type Comparable = {
  price: number;
  score: number;
  reasons: string[];
};

type PriceItemType = 'vehicle' | 'battery' | 'accessory';

type PriceFallback = PriceEstimateResult;

@Injectable()
export class AiService {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async chat(payload: AiChatRequestDto) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');

    if (!apiKey) {
      throw new ServiceUnavailableException(
        'AI chat chưa được cấu hình. Vui lòng thử lại sau.',
      );
    }

    const prompt = this.buildPrompt(payload);
    const models = this.getCandidateModels();

    for (const model of models) {
      try {
        const response = await this.callGemini(model, apiKey, prompt);
        if (response.trim()) {
          return {
            response: response.trim(),
            timestamp: new Date().toISOString(),
            model,
          };
        }
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        if (
          errorMsg.includes('API_KEY_INVALID') ||
          errorMsg.includes('API Key not found') ||
          errorMsg.includes('400')
        ) {
          throw new ServiceUnavailableException(
            'Khóa API Gemini không hợp lệ hoặc đã hết hạn. Vui lòng cấu hình GEMINI_API_KEY chính xác trong file .env của backend.',
          );
        }
        if (this.shouldRetryWithFallback(error)) {
          continue;
        }
        break;
      }
    }

    throw new ServiceUnavailableException(
      'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.',
    );
  }

  async suggestVehiclePrice(payload: AiVehiclePriceSuggestionDto) {
    const normalizedBrand = payload.brand.trim();
    const normalizedModel = payload.model.trim();
    const conditionScore = this.scoreTextCondition(payload.condition);
    const targetAge = new Date().getFullYear() - payload.year;

    const records = await this.prisma.vehicle.findMany({
      where: {
        brand: { contains: normalizedBrand, mode: 'insensitive' },
        model: { contains: normalizedModel, mode: 'insensitive' },
        year: { gte: payload.year - 2, lte: payload.year + 2 },
        isActive: true,
        status: { in: ['AVAILABLE', 'SOLD'] },
      },
      take: MAX_COMPARABLES,
      orderBy: { createdAt: 'desc' },
      select: {
        price: true,
        year: true,
        mileage: true,
        condition: true,
        location: true,
      },
    });

    const comparables = records.map((item) => {
      const mileageScore =
        payload.mileage !== undefined && item.mileage !== null
          ? Math.max(
              0.55,
              1 - Math.abs(item.mileage - payload.mileage) / 200000,
            )
          : 0.8;
      const ageScore = Math.max(
        0.55,
        1 - Math.abs(new Date().getFullYear() - item.year - targetAge) * 0.08,
      );
      const conditionMatch = this.scoreTextCondition(item.condition);
      const conditionRatio = this.safeRatio(conditionScore, conditionMatch);
      return {
        price: Math.round(Number(item.price) * conditionRatio),
        score: Math.min(1, mileageScore * 0.35 + ageScore * 0.35 + 0.3),
        reasons: [`${item.year}`, item.condition, item.location ?? 'unknown'],
      };
    });

    const fallback =
      comparables.length < MIN_COMPARABLES
        ? await this.estimatePriceFallback({
            itemType: 'vehicle',
            payload,
            comparables,
          })
        : null;

    return this.buildSuggestionResponse({
      itemType: 'vehicle',
      comparables,
      targetCompleteness: this.inputCompleteness([
        payload.brand,
        payload.model,
        payload.year,
        payload.mileage,
        payload.condition,
      ]),
      fallback,
      factors: [
        `brand/model: ${normalizedBrand} ${normalizedModel}`,
        `year: ${payload.year}`,
        `mileage: ${payload.mileage ?? 'unknown'}`,
        `conditionScore: ${conditionScore}`,
      ],
    });
  }

  async suggestBatteryPrice(payload: AiBatteryPriceSuggestionDto) {
    const condition = payload.soh ?? payload.condition;
    const records = await this.prisma.battery.findMany({
      where: {
        type: payload.type,
        capacity: { gte: payload.capacity * 0.8, lte: payload.capacity * 1.2 },
        condition: {
          gte: Math.max(0, condition - 15),
          lte: Math.min(100, condition + 15),
        },
        isActive: true,
        status: { in: ['AVAILABLE', 'SOLD'] },
      },
      take: MAX_COMPARABLES,
      orderBy: { createdAt: 'desc' },
      select: {
        price: true,
        capacity: true,
        condition: true,
        soh: true,
        location: true,
      },
    });

    const comparables = records.map((item) => {
      const sourceCondition = item.soh ?? item.condition;
      const capacityRatio = this.safeRatio(
        payload.capacity,
        Number(item.capacity),
      );
      const conditionRatio = this.safeRatio(condition, sourceCondition);
      const capacityScore = Math.max(0.55, 1 - Math.abs(1 - capacityRatio));
      const conditionScore = Math.max(
        0.55,
        1 - Math.abs(condition - sourceCondition) / 100,
      );
      return {
        price: Math.round(Number(item.price) * capacityRatio * conditionRatio),
        score: Math.min(1, capacityScore * 0.5 + conditionScore * 0.5),
        reasons: [
          `capacity: ${Number(item.capacity)}kWh`,
          `condition/SOH: ${sourceCondition}`,
          item.location ?? 'unknown',
        ],
      };
    });

    const fallback =
      comparables.length < MIN_COMPARABLES
        ? await this.estimatePriceFallback({
            itemType: 'battery',
            payload,
            comparables,
          })
        : null;

    return this.buildSuggestionResponse({
      itemType: 'battery',
      comparables,
      targetCompleteness: this.inputCompleteness([
        payload.type,
        payload.capacity,
        payload.condition,
        payload.soh,
      ]),
      fallback,
      factors: [
        `type: ${payload.type}`,
        `capacity: ${payload.capacity}kWh`,
        `condition: ${payload.condition}`,
        `soh: ${payload.soh ?? 'not_provided'}`,
      ],
    });
  }

  async suggestAccessoryPrice(payload: AiAccessoryPriceSuggestionDto) {
    const records = await this.prisma.accessory.findMany({
      where: {
        category: payload.category,
        ...(payload.brand
          ? { brand: { contains: payload.brand.trim(), mode: 'insensitive' } }
          : {}),
        ...(payload.compatibleModel
          ? {
              compatibleModel: {
                contains: payload.compatibleModel.trim(),
                mode: 'insensitive',
              },
            }
          : {}),
        isActive: true,
        status: { in: ['AVAILABLE', 'SOLD'] },
      },
      take: MAX_COMPARABLES,
      orderBy: { createdAt: 'desc' },
      select: {
        price: true,
        brand: true,
        compatibleModel: true,
        condition: true,
        location: true,
      },
    });

    const targetCondition = this.scoreTextCondition(payload.condition);
    const comparables = records.map((item) => {
      const sourceCondition = this.scoreTextCondition(item.condition);
      const conditionRatio = this.safeRatio(targetCondition, sourceCondition);
      const brandScore = payload.brand && item.brand ? 1 : 0.75;
      const modelScore =
        payload.compatibleModel && item.compatibleModel ? 1 : 0.75;
      return {
        price: Math.round(Number(item.price) * conditionRatio),
        score: Math.min(1, brandScore * 0.25 + modelScore * 0.25 + 0.5),
        reasons: [
          item.brand ?? 'unknown brand',
          item.compatibleModel ?? 'unknown model',
          item.condition,
        ],
      };
    });

    const fallback =
      comparables.length < MIN_COMPARABLES
        ? await this.estimatePriceFallback({
            itemType: 'accessory',
            payload,
            comparables,
          })
        : null;

    return this.buildSuggestionResponse({
      itemType: 'accessory',
      comparables,
      targetCompleteness: this.inputCompleteness([
        payload.category,
        payload.brand,
        payload.compatibleModel,
        payload.condition,
      ]),
      fallback,
      factors: [
        `category: ${payload.category}`,
        `brand: ${payload.brand ?? 'unknown'}`,
        `compatibleModel: ${payload.compatibleModel ?? 'unknown'}`,
        `conditionScore: ${targetCondition}`,
      ],
    });
  }

  private buildSuggestionResponse(input: {
    itemType: PriceItemType;
    comparables: Comparable[];
    targetCompleteness: number;
    fallback: PriceFallback | null;
    factors: string[];
  }) {
    const sorted = input.comparables
      .filter((item) => Number.isFinite(item.price) && item.price > 0)
      .sort((a, b) => a.price - b.price);
    const trimmed = this.trimOutliers(sorted);
    const source = trimmed.length ? trimmed : sorted;
    const comparableCount = source.length;

    if (comparableCount === 0 && input.fallback === null) {
      return {
        itemType: input.itemType,
        currency: 'VND',
        suggestedPrice: null,
        priceRange: { min: null, max: null },
        confidence: 'low',
        comparableCount,
        factors: [...input.factors, 'no_comparable_data'],
        message: 'Chưa đủ dữ liệu so sánh để gợi ý giá đáng tin cậy.',
      };
    }

    const fallback = input.fallback;
    const usesAiFallback =
      comparableCount < MIN_COMPARABLES && fallback !== null;
    const weightedPrice = comparableCount
      ? usesAiFallback
        ? fallback.estimatedPrice
        : this.weightedAverage(source)
      : (fallback?.estimatedPrice ?? 0);
    const confidenceScore = this.confidenceScore(
      comparableCount,
      source,
      input.targetCompleteness,
    );
    const confidence = usesAiFallback
      ? fallback.confidence.toLowerCase()
      : confidenceScore >= 0.75
        ? 'high'
        : confidenceScore >= 0.45
          ? 'medium'
          : 'low';
    const spread =
      confidence === 'high' ? 0.08 : confidence === 'medium' ? 0.15 : 0.28;
    const suggestedPrice = this.roundVnd(weightedPrice);

    return {
      itemType: input.itemType,
      currency: 'VND',
      suggestedPrice,
      priceRange: usesAiFallback
        ? {
            min: this.roundVnd(fallback.minPrice),
            max: this.roundVnd(fallback.maxPrice),
          }
        : {
            min: this.roundVnd(suggestedPrice * (1 - spread)),
            max: this.roundVnd(suggestedPrice * (1 + spread)),
          },
      confidence,
      comparableCount,
      factors: [
        ...input.factors,
        ...(usesAiFallback
          ? [
              'ai_estimation_fallback',
              `provider: ${fallback.provider}`,
              ...(fallback.model ? [`model: ${fallback.model}`] : []),
              ...fallback.factors,
              ...(fallback.explanation
                ? [`explanation: ${fallback.explanation}`]
                : []),
            ]
          : []),
        `marketComparables: ${comparableCount}`,
        comparableCount < MIN_COMPARABLES
          ? 'low_comparable_data'
          : 'market_data_available',
      ],
      message: usesAiFallback
        ? 'Dữ liệu thị trường nội bộ còn ít; giá được AI ước lượng dựa trên thông tin nhập và chỉ dùng để tham khảo.'
        : comparableCount < MIN_COMPARABLES
          ? 'Dữ liệu so sánh còn ít; nên dùng như khoảng tham khảo.'
          : 'Giá được tính bằng engine deterministic từ dữ liệu thị trường nội bộ.',
    };
  }

  private async estimatePriceFallback(input: {
    itemType: PriceItemType;
    payload: object;
    comparables: Comparable[];
  }): Promise<PriceFallback | null> {
    const providerInput: PriceEstimateInput = {
      itemType: input.itemType,
      payload: input.payload as Record<string, unknown>,
      comparables: input.comparables,
    };

    const gemini = new GeminiPriceProvider(this.configService);
    const geminiResult = await gemini.estimatePrice(providerInput);
    if (geminiResult) return geminiResult;

    const groq = new GroqPriceProvider(this.configService);
    const groqResult = await groq.estimatePrice(providerInput);
    if (groqResult) return groqResult;

    return estimatePriceWithHeuristic(providerInput);
  }

  private trimOutliers(items: Comparable[]) {
    if (items.length < 5) return items;
    const trim = Math.floor(items.length * 0.1);
    return items.slice(trim, items.length - trim);
  }

  private weightedAverage(items: Comparable[]) {
    const totalWeight = items.reduce((sum, item) => sum + item.score, 0);
    if (totalWeight <= 0) {
      return items.reduce((sum, item) => sum + item.price, 0) / items.length;
    }
    return (
      items.reduce((sum, item) => sum + item.price * item.score, 0) /
      totalWeight
    );
  }

  private confidenceScore(
    count: number,
    items: Comparable[],
    completeness: number,
  ) {
    const sampleScore = Math.min(1, count / 10);
    const matchScore = items.length
      ? items.reduce((sum, item) => sum + item.score, 0) / items.length
      : 0.15;
    return sampleScore * 0.45 + matchScore * 0.35 + completeness * 0.2;
  }

  private inputCompleteness(values: unknown[]) {
    return (
      values.filter(
        (value) => value !== undefined && value !== null && value !== '',
      ).length / values.length
    );
  }

  private scoreTextCondition(condition?: string | null) {
    const normalized = (condition ?? '').toLowerCase();
    if (normalized.includes('excellent') || normalized.includes('xuất sắc'))
      return 100;
    if (normalized.includes('good') || normalized.includes('tốt')) return 85;
    if (normalized.includes('fair') || normalized.includes('khá')) return 70;
    if (normalized.includes('poor') || normalized.includes('kém')) return 50;
    return 75;
  }

  private safeRatio(target: number, source: number) {
    if (!Number.isFinite(target) || !Number.isFinite(source) || source <= 0)
      return 1;
    return Math.min(1.35, Math.max(0.65, target / source));
  }

  private roundVnd(value: number) {
    return Math.round(value / 100000) * 100000;
  }

  private buildPrompt(payload: AiChatRequestDto): string {
    const history = this.capHistory(payload.history ?? []);
    const context = this.stringifyContext(payload.context);

    const historyText = history
      .map((item) => {
        const role = item.role === 'user' ? 'NGƯỜI DÙNG' : 'AI';
        return `${role}: ${item.content}`;
      })
      .join('\n');

    return `${this.systemPrompt()}\n\nCONTEXT ỨNG DỤNG (nếu có, chỉ dùng trong phạm vi được cung cấp):\n${context || 'Không có'}\n\nLỊCH SỬ GẦN ĐÂY:\n${historyText || 'Không có'}\n\nNGƯỜI DÙNG: ${payload.message}\nAI:`;
  }

  private capHistory(history: AiChatHistoryItemDto[]): AiChatHistoryItemDto[] {
    return history
      .slice(-MAX_HISTORY_ITEMS)
      .map((item) => ({ ...item, content: item.content.slice(0, 1000) }));
  }

  private stringifyContext(context?: Record<string, unknown>): string {
    if (!context) {
      return '';
    }

    const sanitized = this.sanitizeContextValue(context, 0);
    return JSON.stringify(sanitized).slice(0, MAX_CONTEXT_CHARS);
  }

  private sanitizeContextValue(value: unknown, depth: number): unknown {
    if (
      value === null ||
      typeof value === 'number' ||
      typeof value === 'boolean'
    ) {
      return value;
    }

    if (typeof value === 'string') {
      return value.slice(0, MAX_CONTEXT_STRING_CHARS);
    }

    if (depth >= MAX_CONTEXT_DEPTH) {
      return '[trimmed]';
    }

    if (Array.isArray(value)) {
      return value
        .slice(0, MAX_CONTEXT_ARRAY_ITEMS)
        .map((item) => this.sanitizeContextValue(item, depth + 1));
    }

    if (typeof value === 'object' && this.isPlainObject(value)) {
      return Object.fromEntries(
        Object.entries(value)
          .slice(0, MAX_CONTEXT_KEYS)
          .map(([key, item]) => {
            const sanitizedKey = key.slice(0, 60);
            if (this.isSensitiveContextKey(sanitizedKey)) {
              return [sanitizedKey, '[REDACTED]'];
            }
            return [sanitizedKey, this.sanitizeContextValue(item, depth + 1)];
          }),
      );
    }

    throw new BadRequestException('Context không hợp lệ.');
  }

  private isSensitiveContextKey(key: string): boolean {
    return SENSITIVE_CONTEXT_KEYS.has(
      key.toLowerCase().replace(/[^a-z0-9]/g, ''),
    );
  }

  private isPlainObject(value: object): value is Record<string, unknown> {
    return (
      value.constructor === Object || Object.getPrototypeOf(value) === null
    );
  }

  private getCandidateModels(): string[] {
    const configured = this.configService.get<string>('GEMINI_MODEL');
    return [
      configured,
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-pro-latest',
      'gemini-flash-latest',
    ].filter((model): model is string => Boolean(model));
  }

  private async callGemini(
    model: string,
    apiKey: string,
    prompt: string,
  ): Promise<string> {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

    const buildBody = (retryPrompt = prompt) =>
      JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: retryPrompt }] }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 512,
        },
      });

    const requestGemini = (body: string) =>
      fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body,
      });

    let response: Response;
    try {
      response = await requestGemini(buildBody());
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Gemini request failed: timeout');
      }
      throw new Error('Gemini request failed: unavailable');
    } finally {
      clearTimeout(timeout);
    }

    if (!response.ok) {
      throw new Error(`Gemini request failed: ${response.status}`);
    }

    const data = (await response.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };

    const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    if (text.trim()) return text;

    const retryResponse = await requestGemini(buildBody(prompt));
    if (!retryResponse.ok) {
      throw new Error(`Gemini request failed: ${retryResponse.status}`);
    }

    const retryData = (await retryResponse.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };

    return retryData.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  }

  private shouldRetryWithFallback(error: unknown): boolean {
    const message = error instanceof Error ? error.message.toLowerCase() : '';
    return (
      message.includes('404') ||
      message.includes('not found') ||
      message.includes('timeout') ||
      message.includes('unavailable') ||
      message.includes('429') ||
      message.includes('500') ||
      message.includes('502') ||
      message.includes('503') ||
      message.includes('504')
    );
  }

  private systemPrompt(): string {
    return `Bạn là trợ lý AI của EV Resale Platform tại Việt Nam.

PHẠM VI:
- Hỗ trợ hỏi đáp về xe điện, pin EV, phụ kiện EV, mua bán trên nền tảng và hướng dẫn dùng app.
- Trả lời ngắn gọn, rõ ràng, thực tế, tối đa ${MAX_RESPONSE_WORDS} từ.
- Nếu thiếu dữ liệu, nói rõ là chưa đủ thông tin.
- Với listing/sản phẩm cụ thể, chỉ giải thích dựa trên context backend cung cấp.

KHÔNG ĐƯỢC:
- Không trả lời chủ đề ngoài EV marketplace.
- Không bịa thông số kỹ thuật, giá, bảo hành hoặc tình trạng sản phẩm.
- Không đưa cam kết pháp lý, tài chính hoặc kỹ thuật tuyệt đối.
- Không tự tính giá; nếu người dùng hỏi định giá, hướng dẫn dùng tính năng AI Price Suggestion.
- Không tự thực hiện giao dịch, đặt cọc, thanh toán hoặc thay đổi dữ liệu.
- Không yêu cầu hoặc tiết lộ secrets, token, mật khẩu, cookie, private key.

AN TOÀN:
- Luôn khuyến nghị kiểm tra thực tế xe/pin/phụ kiện và giấy tờ trước khi mua.
- Không lưu hoặc giả định có AI memory dài hạn.`;
  }
}
