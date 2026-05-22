import { validateEstimatedPrice } from './price-estimate.validator';
import {
  PriceEstimateInput,
  PriceEstimateResult,
} from './providers/price-ai-provider';

export function estimatePriceWithHeuristic(
  input: PriceEstimateInput,
): PriceEstimateResult | null {
  const comparables = input.comparables
    .filter((item) => Number.isFinite(item.price) && item.price > 0)
    .sort((a, b) => a.price - b.price)
    .slice(0, 2);

  if (comparables.length === 0 && !hasMinimumStructuredInput(input)) {
    return null;
  }

  const baseline = comparables.length
    ? weightedAverage(comparables)
    : baselineFromStructuredInput(input);

  if (!Number.isFinite(baseline) || baseline <= 0) return null;

  const adjusted = applyStructuredAdjustments(baseline, input);
  const estimatedPrice = roundVnd(adjusted);
  const minPrice = roundVnd(estimatedPrice * 0.72);
  const maxPrice = roundVnd(estimatedPrice * 1.28);

  return validateEstimatedPrice(
    {
      estimatedPrice,
      minPrice,
      maxPrice,
      confidence: 'LOW',
      factors: ['heuristic_estimation_fallback'],
      explanation:
        'Ước lượng deterministic fallback sau khi Gemini và Groq không trả kết quả hợp lệ.',
    },
    'heuristic',
  );
}

function hasMinimumStructuredInput(input: PriceEstimateInput): boolean {
  const payload = input.payload;
  if (input.itemType === 'vehicle') {
    return Boolean(payload.brand && payload.model && payload.year);
  }
  if (input.itemType === 'battery') {
    return Boolean(payload.type && payload.capacity && payload.condition);
  }
  return Boolean(payload.category && payload.condition);
}

function baselineFromStructuredInput(input: PriceEstimateInput): number {
  const payload = input.payload;
  if (input.itemType === 'vehicle') {
    const year = Number(payload.year);
    const age = Number.isFinite(year)
      ? Math.max(0, new Date().getFullYear() - year)
      : 5;
    return Math.max(80_000_000, 700_000_000 * Math.pow(0.88, age));
  }
  if (input.itemType === 'battery') {
    return (
      Number(payload.capacity) * 5_000_000 * (Number(payload.condition) / 100)
    );
  }
  return 2_000_000;
}

function applyStructuredAdjustments(
  baseline: number,
  input: PriceEstimateInput,
): number {
  const payload = input.payload;
  let value = baseline;

  if (input.itemType === 'vehicle') {
    const mileage = Number(payload.mileage);
    if (Number.isFinite(mileage)) {
      value *= Math.max(0.72, Math.min(1.08, 1 - mileage / 500_000));
    }
    value *= conditionMultiplier(payload.condition);
  }

  if (input.itemType === 'battery') {
    const soh = Number(payload.soh ?? payload.condition);
    if (Number.isFinite(soh)) value *= Math.max(0.65, Math.min(1.1, soh / 90));
  }

  if (input.itemType === 'accessory') {
    value *= conditionMultiplier(payload.condition);
  }

  return value;
}

function conditionMultiplier(condition: unknown): number {
  const normalized = String(condition ?? '').toLowerCase();
  if (normalized.includes('excellent') || normalized.includes('xuất sắc'))
    return 1.05;
  if (normalized.includes('good') || normalized.includes('tốt')) return 1;
  if (normalized.includes('fair') || normalized.includes('khá')) return 0.85;
  if (normalized.includes('poor') || normalized.includes('kém')) return 0.65;
  return 0.9;
}

function weightedAverage(
  items: Array<{ price: number; score: number }>,
): number {
  const totalWeight = items.reduce((sum, item) => sum + item.score, 0);
  if (totalWeight <= 0) {
    return items.reduce((sum, item) => sum + item.price, 0) / items.length;
  }
  return (
    items.reduce((sum, item) => sum + item.price * item.score, 0) / totalWeight
  );
}

function roundVnd(value: number): number {
  return Math.round(value / 100000) * 100000;
}
