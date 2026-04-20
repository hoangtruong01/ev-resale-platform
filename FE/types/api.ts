// Types for API responses
export interface ApiResponse<T = any> {
  data: T;
  message?: string;
  success: boolean;
}

// Types for pagination
export interface PaginationParams {
  page?: number;
  limit?: number;
  search?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: PaginationMeta;
}

// Types for authentication
export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  name: string;
  phone?: string;
}

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  role: string;
  moderatorPermissions?: string[];
  createdAt: string;
  updatedAt: string;
}

// Types for batteries
export interface Battery {
  id: string;
  model: string;
  capacity: number;
  voltage: number;
  condition: string;
  price: number | string;
  description?: string;
  images?: string[];
  sellerId: string;
  seller: User;
  createdAt: string;
  updatedAt: string;
}

// Types for vehicles
export interface Vehicle {
  id: string;
  name: string;
  brand: string;
  model: string;
  year: number;
  price: number | string;
  mileage?: number | null;
  condition?: string | null;
  description?: string | null;
  images?: string[];
  location?: string | null;
  sellerId: string;
  seller: User;
  createdAt: string;
  updatedAt: string;
  status?: string;
  approvalStatus?: string;
}

export type AccessoryCategory =
  | "CHARGER"
  | "TIRE"
  | "INTERIOR"
  | "EXTERIOR"
  | "ELECTRONICS"
  | "SAFETY"
  | "MAINTENANCE"
  | "OTHER";

export interface Accessory {
  id: string;
  name: string;
  category: AccessoryCategory;
  brand?: string | null;
  compatibleModel?: string | null;
  condition: string;
  price: number | string;
  description?: string | null;
  images?: string[];
  location?: string | null;
  sellerId: string;
  seller?: User;
  status?: string;
  approvalStatus?: string;
  createdAt?: string;
  updatedAt?: string;
}

// Types for auctions
export type AuctionStatus = "PENDING" | "ACTIVE" | "ENDED" | "CANCELLED";
export type ApprovalStatus = "PENDING" | "APPROVED" | "REJECTED";

export interface AuctionSeller {
  id: string;
  fullName: string;
  email: string;
  phone?: string | null;
  avatar?: string | null;
  createdAt?: string;
  rating?: number | null;
  averageRating?: number | null;
  reviewScore?: number | null;
  reviewCount?: number | null;
  reviewsCount?: number | null;
  totalReviews?: number | null;
  soldItems?: number | null;
  soldAuctions?: number | null;
  completedTransactions?: number | null;
  location?: string | null;
}

export interface AuctionBidder {
  id: string;
  fullName: string;
  avatar?: string | null;
}

export interface AuctionBid {
  id: string;
  amount: number | string;
  bidderId: string;
  bidder: AuctionBidder;
  auctionId: string;
  createdAt: string;
}

export type AuctionItemType = "VEHICLE" | "BATTERY";

export interface AuctionMedia {
  id: string;
  url: string;
  sortOrder: number;
}

export interface AuctionSummary {
  id: string;
  title: string;
  description?: string | null;
  itemType: AuctionItemType;
  lotQuantity: number;
  itemBrand?: string | null;
  itemModel?: string | null;
  itemYear?: number | null;
  itemMileage?: number | null;
  itemCapacity?: number | null;
  itemCondition?: number | null;
  location?: string | null;
  contactPhone?: string | null;
  contactEmail?: string | null;
  buyNowPrice?: number | string | null;
  startingPrice: number | string;
  currentPrice: number | string;
  bidStep: number | string;
  startTime: string;
  endTime: string;
  status: AuctionStatus;
  approvalStatus: ApprovalStatus;
  sellerId: string;
  seller: AuctionSeller;
  media?: AuctionMedia[];
  bids?: AuctionBid[];
  _count?: {
    bids: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AuctionDetail extends AuctionSummary {
  bids: AuctionBid[];
}

export interface Bid {
  id: string;
  amount: number | string;
  bidderId: string;
  bidder: User;
  auctionId: string;
  createdAt: string;
}
