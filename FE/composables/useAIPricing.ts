type AIPricingKind = "vehicle" | "battery" | "accessory";

export interface AIPricingResponse {
  suggestedPrice: number | null;
  message?: string;
  priceRange?: {
    min?: number;
    max?: number;
  } | null;
  confidence?: number | string | null;
  comparableCount?: number | null;
}

export interface VehiclePricePayload {
  brand: string;
  model: string;
  year: number;
  mileage: number;
  condition: string;
}

export interface BatteryPricePayload {
  type: string;
  capacity: number;
  condition: number;
}

export interface AccessoryPricePayload {
  category: string;
  brand?: string;
  compatibleModel?: string;
  condition: string;
}

const ENDPOINTS: Record<AIPricingKind, string> = {
  vehicle: "/ai/vehicles/suggest-price",
  battery: "/ai/batteries/suggest-price",
  accessory: "/ai/accessories/suggest-price",
};

const safeMessage = (error: unknown) => {
  const status = (error as { status?: number })?.status;

  if (status === 401) {
    return "Vui lòng đăng nhập lại để dùng gợi ý giá AI.";
  }

  if (status === 503) {
    return "Dịch vụ gợi ý giá AI đang tạm thời không khả dụng.";
  }

  if (status === 500) {
    return "Chưa thể gợi ý giá lúc này. Vui lòng thử lại sau.";
  }

  return error instanceof Error && error.message
    ? error.message
    : "Không thể lấy gợi ý giá AI. Vui lòng thử lại sau.";
};

export const useAIPricing = () => {
  const { post } = useApi();

  const suggestPrice = async <TPayload>(
    kind: AIPricingKind,
    payload: TPayload,
  ) => {
    try {
      const data = await post<AIPricingResponse>(ENDPOINTS[kind], payload);
      return { data, error: null as string | null };
    } catch (error) {
      return { data: null, error: safeMessage(error) };
    }
  };

  return {
    suggestVehiclePrice: (payload: VehiclePricePayload) =>
      suggestPrice("vehicle", payload),
    suggestBatteryPrice: (payload: BatteryPricePayload) =>
      suggestPrice("battery", payload),
    suggestAccessoryPrice: (payload: AccessoryPricePayload) =>
      suggestPrice("accessory", payload),
  };
};
