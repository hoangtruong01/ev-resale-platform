-- CreateEnum
CREATE TYPE "public"."AccessoryCategory" AS ENUM ('CHARGER', 'TIRE', 'INTERIOR', 'EXTERIOR', 'ELECTRONICS', 'SAFETY', 'MAINTENANCE', 'OTHER');

-- CreateEnum
CREATE TYPE "public"."AccessoryStatus" AS ENUM ('AVAILABLE', 'SOLD', 'RESERVED');

-- CreateTable
CREATE TABLE "public"."accessories" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "public"."AccessoryCategory" NOT NULL,
    "brand" TEXT,
    "compatibleModel" TEXT,
    "condition" TEXT NOT NULL,
    "price" DECIMAL(12,2) NOT NULL,
    "description" TEXT,
    "images" TEXT[],
    "location" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "status" "public"."AccessoryStatus" NOT NULL DEFAULT 'AVAILABLE',
    "isSpamSuspicious" BOOLEAN NOT NULL DEFAULT false,
    "spamScore" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "spamReasons" JSONB,
    "spamCheckedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "approvalStatus" "public"."ApprovalStatus" NOT NULL DEFAULT 'PENDING',
    "approvalNotes" TEXT,
    "approvedAt" TIMESTAMP(3),
    "approvedById" TEXT,
    "sellerId" TEXT NOT NULL,

    CONSTRAINT "accessories_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "public"."accessories" ADD CONSTRAINT "accessories_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "public"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."accessories" ADD CONSTRAINT "accessories_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
