-- CreateEnum
CREATE TYPE "public"."FavoriteItemType" AS ENUM ('VEHICLE', 'BATTERY', 'AUCTION');

-- CreateTable
CREATE TABLE "public"."favorites" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "itemType" "public"."FavoriteItemType" NOT NULL,
    "vehicleId" TEXT,
    "batteryId" TEXT,
    "auctionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "favorites_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "favorites_userId_idx" ON "public"."favorites"("userId");
CREATE INDEX "favorites_userId_itemType_idx" ON "public"."favorites"("userId", "itemType");

-- AddForeignKey
ALTER TABLE "public"."favorites" ADD CONSTRAINT "favorites_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "public"."favorites" ADD CONSTRAINT "favorites_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "public"."vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "public"."favorites" ADD CONSTRAINT "favorites_batteryId_fkey" FOREIGN KEY ("batteryId") REFERENCES "public"."batteries"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "public"."favorites" ADD CONSTRAINT "favorites_auctionId_fkey" FOREIGN KEY ("auctionId") REFERENCES "public"."auctions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
