export type PriceConfidence = 'LOW' | 'MEDIUM' | 'HIGH';

export type PriceComparable = {
  price: number;
  score: number;
  reasons: string[];
};

export type PriceItemType = 'vehicle' | 'battery' | 'accessory';

export type PriceEstimateInput = {
  itemType: PriceItemType;
  payload: Record<string, unknown>;
  comparables: PriceComparable[];
};

export type PriceEstimateResult = {
  estimatedPrice: number;
  minPrice: number;
  maxPrice: number;
  confidence: PriceConfidence;
  factors: string[];
  explanation: string;
  provider: 'gemini' | 'groq' | 'heuristic';
  model?: string;
};

export interface PriceAIProvider {
  name: 'gemini' | 'groq';
  estimatePrice(input: PriceEstimateInput): Promise<PriceEstimateResult | null>;
}
