import type {
  AuctionSummary,
  AuctionDetail,
  AuctionBid,
  PaginatedResponse,
  PaginationMeta,
} from "~/types/api";

export interface AuctionListParams {
  search?: string;
  status?: string;
  itemType?: "vehicle" | "battery";
  approvalStatus?: string;
  minPrice?: number;
  maxPrice?: number;
  page?: number;
  limit?: number;
  sortBy?: "createdAt" | "startTime" | "endTime" | "currentPrice";
  sortOrder?: "asc" | "desc";
}

export interface CreateAuctionPayload {
  title: string;
  description?: string;
  startingPrice: number;
  bidStep: number;
  buyNowPrice?: number;
  startTime: string;
  endTime: string;
  itemType: "VEHICLE" | "BATTERY";
  lotQuantity: number;
  itemBrand?: string;
  itemModel?: string;
  itemYear?: number;
  itemMileage?: number;
  itemCapacity?: number;
  itemCondition?: number;
  location: string;
  contactPhone: string;
  contactEmail?: string;
  imageUrls?: string[];
}

export interface AuctionBidsResponse {
  data: AuctionBid[];
  pagination: PaginationMeta;
}

export const useAuctions = () => {
  const { get, post } = useApi();

  const toQueryString = (params?: Record<string, any>) => {
    if (!params) return "";
    const entries = Object.entries(params).filter(
      ([, value]) => value !== undefined && value !== null && value !== ""
    );
    if (entries.length === 0) {
      return "";
    }

    const qs = new URLSearchParams();
    for (const [key, value] of entries) {
      qs.append(key, String(value));
    }
    return `?${qs.toString()}`;
  };

  const list = (params?: AuctionListParams) => {
    const query = toQueryString(params as Record<string, any>);
    return get<PaginatedResponse<AuctionSummary>>(`/auctions${query}`);
  };

  const getById = (id: string) => get<AuctionDetail>(`/auctions/${id}`);

  const getBids = (auctionId: string, page = 1, limit = 10) => {
    const query = toQueryString({ page, limit });
    return get<AuctionBidsResponse>(`/auctions/${auctionId}/bids${query}`);
  };

  const create = (payload: CreateAuctionPayload) =>
    post<AuctionDetail>("/auctions", payload);

  const placeBid = (auctionId: string, amount: number) =>
    post<AuctionBid>(`/auctions/${auctionId}/bid`, { amount });

  const getMyAuctions = (params?: AuctionListParams) => {
    const query = toQueryString(params as Record<string, any>);
    return get<PaginatedResponse<AuctionSummary>>(
      `/auctions/my-auctions${query}`
    );
  };

  const getMyBids = (page = 1, limit = 10) => {
    const query = toQueryString({ page, limit });
    return get<AuctionBidsResponse>(`/auctions/my-bids${query}`);
  };

  return {
    list,
    getById,
    getBids,
    create,
    placeBid,
    getMyAuctions,
    getMyBids,
  };
};
