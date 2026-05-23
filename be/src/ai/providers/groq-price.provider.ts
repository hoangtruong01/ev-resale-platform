import { ConfigService } from '@nestjs/config';
import { parsePriceEstimateResponse } from '../price-estimate.validator';
import {
  PriceAIProvider,
  PriceEstimateInput,
  PriceEstimateResult,
} from './price-ai-provider';

type GroqResponse = {
  choices?: Array<{
    finish_reason?: string;
    message?: { content?: string };
  }>;
  usage?: unknown;
};

export class GroqPriceProvider implements PriceAIProvider {
  readonly name = 'groq' as const;

  constructor(private readonly configService: ConfigService) {}

  async estimatePrice(
    input: PriceEstimateInput,
  ): Promise<PriceEstimateResult | null> {
    const apiKey = this.configService.get<string>('GROQ_API_KEY');
    if (!apiKey) return null;

    const prompt = this.buildPrompt(input);
    for (const model of this.models()) {
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
        const response = await this.callGroq(model, apiKey, prompt, true);
        const parsed = parsePriceEstimateResponse(response.text, 'groq', model);
        console.log('[AI_ESTIMATION]', {
          provider: 'groq',
          model,
          status: 'ok',
          finishReason: response.finishReason,
          usage: response.usage,
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
          provider: 'groq',
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

  private async callGroq(
    model: string,
    apiKey: string,
    prompt: string,
    useResponseFormat: boolean,
  ): Promise<{ text: string; finishReason?: string; usage?: unknown }> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs());

    try {
      let response = await this.request(
        model,
        apiKey,
        prompt,
        useResponseFormat,
        controller.signal,
      );
      if (response.status === 400 && useResponseFormat) {
        response = await this.request(
          model,
          apiKey,
          prompt,
          false,
          controller.signal,
        );
      }
      if (!response.ok)
        throw new Error(`Groq request failed: ${response.status}`);

      const data = (await response.json()) as GroqResponse;
      const choice = data.choices?.[0];
      return {
        text: choice?.message?.content ?? '',
        finishReason: choice?.finish_reason,
        usage: data.usage,
      };
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Groq request failed: timeout');
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }

  private request(
    model: string,
    apiKey: string,
    prompt: string,
    useResponseFormat: boolean,
    signal: AbortSignal,
  ) {
    return fetch(`${this.baseUrl()}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      signal,
      body: JSON.stringify({
        model,
        messages: [
          {
            role: 'system',
            content: 'You are a strict JSON-only price estimation engine.',
          },
          { role: 'user', content: prompt },
        ],
        temperature: 0,
        ...(useResponseFormat
          ? { response_format: { type: 'json_object' } }
          : {}),
      }),
    });
  }

  private buildPrompt(input: PriceEstimateInput): string {
    const comparableSummary = input.comparables.slice(0, 3).map((item) => ({
      price: item.price,
      score: item.score,
      reasons: item.reasons,
    }));

    return `Return ONLY valid JSON. No markdown. No explanation outside JSON.
Must include estimatedPrice, minPrice, maxPrice.
Prices must be integer VND. Never infer missing fields. Never append zeroes.
Schema: {"estimatedPrice":integer,"minPrice":integer,"maxPrice":integer,"confidence":"LOW"|"MEDIUM"|"HIGH","factors":string[],"explanation":string}
INPUT_JSON:
${JSON.stringify(input.payload)}
COMPARABLE_SUMMARY:
${JSON.stringify(comparableSummary)}`;
  }

  private baseUrl(): string {
    return (
      this.configService.get<string>('GROQ_BASE_URL') ??
      'https://api.groq.com/openai/v1'
    ).replace(/\/$/, '');
  }

  private models(): string[] {
    return (
      this.configService.get<string>('GROQ_PRICE_MODELS') ??
      'llama-3.3-70b-versatile,llama-3.1-8b-instant'
    )
      .split(',')
      .map((model) => model.trim())
      .filter(Boolean);
  }

  private timeoutMs(): number {
    return Number(this.configService.get<string>('GROQ_TIMEOUT_MS') ?? 15000);
  }

  private isTransient(message: string): boolean {
    return /429|timeout|unavailable|500|502|503|504|404|not found/i.test(
      message,
    );
  }
}
