import {
  PriceConfidence,
  PriceEstimateResult,
} from './providers/price-ai-provider';

export type RawPriceEstimate = {
  estimatedPrice?: unknown;
  minPrice?: unknown;
  maxPrice?: unknown;
  confidence?: unknown;
  factors?: unknown;
  assumptions?: unknown;
  explanation?: unknown;
};

export function parsePriceEstimateResponse(
  response: string,
  provider: PriceEstimateResult['provider'],
  model?: string,
): PriceEstimateResult | null {
  const stripped = stripMarkdownCodeFence(response);

  try {
    const parsed = JSON.parse(extractJsonObject(stripped)) as RawPriceEstimate;
    return validateEstimatedPrice(parsed, provider, model);
  } catch {
    return recoverTruncatedPriceEstimation(stripped, provider, model);
  }
}

export function stripMarkdownCodeFence(value: string): string {
  const trimmed = value.trim();
  const fenced = /^```(?:json)?\s*([\s\S]*?)\s*```$/i.exec(trimmed);
  return fenced ? fenced[1].trim() : trimmed;
}

export function extractJsonObject(value: string): string {
  const trimmed = value.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) return trimmed;

  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) throw new Error('No JSON');

  return trimmed.slice(start, end + 1);
}

export function recoverTruncatedPriceEstimation(
  response: string,
  provider: PriceEstimateResult['provider'],
  model?: string,
): PriceEstimateResult | null {
  const estimatedPrice = extractNumericJsonField(response, 'estimatedPrice');
  const minPrice = extractNumericJsonField(response, 'minPrice');
  const maxPrice = extractNumericJsonField(response, 'maxPrice');
  const confidence =
    response.includes('"confidence":"MEDIUM"') ||
    response.includes('"confidence":"medium"')
      ? 'MEDIUM'
      : 'LOW';

  return validateEstimatedPrice(
    {
      estimatedPrice,
      minPrice,
      maxPrice,
      confidence,
      factors: [],
      explanation: `${provider} JSON bị cắt; chỉ khôi phục khi đủ 3 giá số`,
    },
    provider,
    model,
  );
}

export function extractNumericJsonField(
  response: string,
  field: string,
): number | null {
  const match = new RegExp(`"${field}"\\s*:\\s*(\\d+(?:\\.\\d+)?)`).exec(
    response,
  );
  return match ? Number(match[1]) : null;
}

export function validateEstimatedPrice(
  input: RawPriceEstimate,
  provider: PriceEstimateResult['provider'],
  model?: string,
): PriceEstimateResult | null {
  if (
    !isReasonableVndPrice(input.estimatedPrice) ||
    !isReasonableVndPrice(input.minPrice) ||
    !isReasonableVndPrice(input.maxPrice)
  ) {
    return null;
  }

  const estimatedPrice = Number(input.estimatedPrice);
  const minPrice = Number(input.minPrice);
  const maxPrice = Number(input.maxPrice);

  if (!(minPrice <= estimatedPrice && estimatedPrice <= maxPrice)) return null;
  if (!(maxPrice > minPrice)) return null;

  return {
    estimatedPrice,
    minPrice,
    maxPrice,
    confidence: normalizeConfidence(input.confidence),
    factors: toSafeStringArray(input.factors),
    explanation:
      toSafeString(input.explanation) ||
      toSafeStringArray(input.assumptions).join('; '),
    provider,
    model,
  };
}

export function isReasonableVndPrice(value: unknown): boolean {
  if (typeof value === 'string' && !/^\d+$/.test(value.trim())) return false;
  const price = Number(value);
  return Number.isInteger(price) && price > 0 && price <= 100_000_000_000;
}

function normalizeConfidence(value: unknown): PriceConfidence {
  const normalized = typeof value === 'string' ? value.toUpperCase() : '';
  return normalized === 'HIGH' || normalized === 'MEDIUM' ? normalized : 'LOW';
}

function toSafeStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === 'string')
    .map((item) => item.trim().slice(0, 120))
    .filter(Boolean)
    .slice(0, 5);
}

function toSafeString(value: unknown): string {
  return typeof value === 'string' ? value.trim().slice(0, 300) : '';
}
