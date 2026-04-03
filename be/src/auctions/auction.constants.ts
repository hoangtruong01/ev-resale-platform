import { AuctionItemType } from '@prisma/client';

export const ALLOWED_AUCTION_ITEM_TYPES = [
  AuctionItemType.VEHICLE,
  AuctionItemType.BATTERY,
] as const;

export type AllowedAuctionItemType =
  (typeof ALLOWED_AUCTION_ITEM_TYPES)[number];

export const MAX_AUCTION_PRICE = 9_999_999_999;
