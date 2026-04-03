/*
  Warnings:

  - You are about to drop the column `batteryId` on the `auctions` table. All the data in the column will be lost.
  - You are about to drop the column `vehicleId` on the `auctions` table. All the data in the column will be lost.
  - You are about to drop the column `paymentDeadline` on the `transactions` table. All the data in the column will be lost.
  - You are about to drop the `contract_signatures` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `contracts` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `payment_methods` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `itemType` to the `auctions` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "public"."AuctionItemType" AS ENUM ('VEHICLE', 'BATTERY', 'OTHER');

-- DropForeignKey
ALTER TABLE "public"."auctions" DROP CONSTRAINT "auctions_batteryId_fkey";

-- DropForeignKey
ALTER TABLE "public"."auctions" DROP CONSTRAINT "auctions_vehicleId_fkey";

-- DropForeignKey
ALTER TABLE "public"."contract_signatures" DROP CONSTRAINT "contract_signatures_contractId_fkey";

-- DropForeignKey
ALTER TABLE "public"."contract_signatures" DROP CONSTRAINT "contract_signatures_userId_fkey";

-- DropForeignKey
ALTER TABLE "public"."contracts" DROP CONSTRAINT "contracts_buyerId_fkey";

-- DropForeignKey
ALTER TABLE "public"."contracts" DROP CONSTRAINT "contracts_sellerId_fkey";

-- DropForeignKey
ALTER TABLE "public"."contracts" DROP CONSTRAINT "contracts_transactionId_fkey";

-- DropForeignKey
ALTER TABLE "public"."payment_methods" DROP CONSTRAINT "payment_methods_userId_fkey";

-- DropIndex
DROP INDEX "public"."auctions_batteryId_key";

-- DropIndex
DROP INDEX "public"."auctions_vehicleId_key";

-- AlterTable
ALTER TABLE "public"."auctions" DROP COLUMN "batteryId",
DROP COLUMN "vehicleId",
ADD COLUMN     "buyNowPrice" DECIMAL(12,2),
ADD COLUMN     "contactEmail" TEXT,
ADD COLUMN     "contactPhone" TEXT,
ADD COLUMN     "itemBrand" TEXT,
ADD COLUMN     "itemCapacity" INTEGER,
ADD COLUMN     "itemCondition" INTEGER,
ADD COLUMN     "itemMileage" INTEGER,
ADD COLUMN     "itemModel" TEXT,
ADD COLUMN     "itemType" "public"."AuctionItemType" NOT NULL,
ADD COLUMN     "itemYear" INTEGER,
ADD COLUMN     "location" TEXT,
ADD COLUMN     "lotQuantity" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "public"."transactions" DROP COLUMN "paymentDeadline",
ADD COLUMN     "auctionId" TEXT;

-- DropTable
DROP TABLE "public"."contract_signatures";

-- DropTable
DROP TABLE "public"."contracts";

-- DropTable
DROP TABLE "public"."payment_methods";

-- DropEnum
DROP TYPE "public"."ContractPartyRole";

-- DropEnum
DROP TYPE "public"."ContractStatus";

-- DropEnum
DROP TYPE "public"."PaymentCardBrand";

-- CreateTable
CREATE TABLE "public"."auction_media" (
    "id" TEXT NOT NULL,
    "auctionId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auction_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "auction_media_auctionId_idx" ON "public"."auction_media"("auctionId");

-- CreateIndex
CREATE INDEX "transactions_auctionId_idx" ON "public"."transactions"("auctionId");

-- AddForeignKey
ALTER TABLE "public"."auction_media" ADD CONSTRAINT "auction_media_auctionId_fkey" FOREIGN KEY ("auctionId") REFERENCES "public"."auctions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."transactions" ADD CONSTRAINT "transactions_auctionId_fkey" FOREIGN KEY ("auctionId") REFERENCES "public"."auctions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
