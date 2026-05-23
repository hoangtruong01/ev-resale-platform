import { ConfigService } from '@nestjs/config';
import { parsePriceEstimateResponse } from '../price-estimate.validator';
import {
  PriceAIProvider,
  PriceEstimateInput,
  PriceEstimateResult,
} from './price-ai-provider';

const MIN_COMPARABLES = 3;

type GeminiResponse = {
  candidates?: Array<{
    finishReason?: string;
    content?: { parts?: Array<{ text?: string }> };
  }>;
  usageMetadata?: unknown;
};

export class GeminiPriceProvider implements PriceAIProvider {
  readonly name = 'gemini' as const;

  constructor(private readonly configService: ConfigService) {}

  async estimatePrice(
    input: PriceEstimateInput,
  ): Promise<PriceEstimateResult | null> {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      console.warn('[AI_ESTIMATION] missing GEMINI_API_KEY');
      return null;
    }

    const prompt = this.buildPrompt(input);
    for (const model of this.getModels()) {
      const result = await this.tryModel(model, apiKey, prompt, input);
      if (result) return result;
    }

    return null;
  }

  private async tryModel(
    model: string,
    apiKey: string,
    prompt: string,
    input: PriceEstimateInput,
  ): Promise<PriceEstimateResult | null> {
    for (let attempt = 0; attempt < 2; attempt += 1) {
      try {
        const response = await this.callGemini(model, apiKey, prompt);
        const parsed = parsePriceEstimateResponse(
          response.text,
          'gemini',
          model,
        );
        console.log('[AI_ESTIMATION]', {
          provider: 'gemini',
          model,
          status: 'ok',
          finishReason: response.finishReason,
          usageMetadata: response.usageMetadata,
          rawLength: response.text.length,
          parsed: parsed !== null,
          itemType: input.itemType,
          comparableCount: input.comparables.length,
        });
        if (parsed) return parsed;
        return null;
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.warn('[AI_ESTIMATION]', {
          provider: 'gemini',
          model,
          status: 'error',
          error: message,
          attempt,
        });
        if (!this.isTransient(message)) return null;
      }
    }
    return null;
  }

  private buildPrompt(input: PriceEstimateInput): string {
    const comparableSummary = input.comparables.slice(0, 3).map((item) => ({
      price: item.price,
      score: item.score,
      reasons: item.reasons,
    }));

    return `Bạn là bộ ước lượng giá tham khảo cho EV Resale Platform tại Việt Nam.
Return ONLY valid JSON. No markdown. No explanation outside JSON.
Must include estimatedPrice, minPrice, maxPrice.
Prices must be integer VND. Do not use strings, separators, or currency suffixes.
Use only INPUT_JSON and COMPARABLE_SUMMARY. Do not infer missing prices from malformed JSON.
estimatedPrice > 0, minPrice > 0, maxPrice > 0, minPrice <= estimatedPrice <= maxPrice, maxPrice > minPrice.
confidence must be one of LOW, MEDIUM, HIGH. Use LOW or MEDIUM when internal comparable data is fewer than ${MIN_COMPARABLES}.
Schema: {"estimatedPrice":integer,"minPrice":integer,"maxPrice":integer,"confidence":"LOW"|"MEDIUM"|"HIGH","factors":string[],"explanation":string}
INPUT_JSON:
${JSON.stringify(input.payload)}
COMPARABLE_SUMMARY:
${JSON.stringify(comparableSummary)}`;
  }

  private async callGemini(
    model: string,
    apiKey: string,
    prompt: string,
  ): Promise<{ text: string; finishReason?: string; usageMetadata?: unknown }> {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs());

    const request = (useSchema: boolean) =>
      fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: this.body(prompt, useSchema),
      });

    try {
      let response = await request(true);
      if (response.status === 400) response = await request(false);
      if (!response.ok)
        throw new Error(`Gemini request failed: ${response.status}`);

      const data = (await response.json()) as GeminiResponse;
      const candidate = data.candidates?.[0];
      return {
        text: candidate?.content?.parts?.[0]?.text ?? '',
        finishReason: candidate?.finishReason,
        usageMetadata: data.usageMetadata,
      };
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Gemini request failed: timeout');
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }

  private body(prompt: string, useSchema: boolean): string {
    return JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: this.maxOutputTokens(),
        ...(useSchema
          ? {
              responseMimeType: 'application/json',
              responseSchema: {
                type: 'OBJECT',
                properties: {
                  estimatedPrice: { type: 'INTEGER' },
                  minPrice: { type: 'INTEGER' },
                  maxPrice: { type: 'INTEGER' },
                  confidence: {
                    type: 'STRING',
                    enum: ['LOW', 'MEDIUM', 'HIGH'],
                  },
                  factors: { type: 'ARRAY', items: { type: 'STRING' } },
                  explanation: { type: 'STRING' },
                },
                required: [
                  'estimatedPrice',
                  'minPrice',
                  'maxPrice',
                  'confidence',
                  'factors',
                  'explanation',
                ],
              },
            }
          : {}),
      },
    });
  }

  private getModels(): string[] {
    const configured = this.configService.get<string>('GEMINI_MODEL');
    return [
      configured,
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-pro-latest',
      'gemini-flash-latest',
    ].filter((model): model is string => Boolean(model));
  }

  private maxOutputTokens(): number {
    return Number(
      this.configService.get<string>('GEMINI_MAX_OUTPUT_TOKENS') ?? 1024,
    );
  }

  private timeoutMs(): number {
    return Number(this.configService.get<string>('GEMINI_TIMEOUT_MS') ?? 15000);
  }

  private isTransient(message: string): boolean {
    return /429|timeout|unavailable|500|502|503|504|404|not found/i.test(
      message,
    );
  }
}
