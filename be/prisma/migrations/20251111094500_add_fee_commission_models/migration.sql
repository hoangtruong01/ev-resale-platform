-- CreateEnum
CREATE TYPE "public"."FeeChangeType" AS ENUM ('TRANSACTION_FEE', 'LISTING_FEE', 'COMMISSION');

-- CreateTable
CREATE TABLE "public"."transaction_fee_settings" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL DEFAULT 'default',
    "rate" DECIMAL(5,2) NOT NULL,
    "minFee" DECIMAL(12,2),
    "maxFee" DECIMAL(12,2),
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "public"."listing_fee_tiers" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "duration" INTEGER NOT NULL,
    "features" TEXT[] NOT NULL,
    "price" DECIMAL(12,2) NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "order" INTEGER NOT NULL DEFAULT 0,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "public"."commission_tiers" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "rate" DECIMAL(5,2) NOT NULL,
    "minRequirement" INTEGER NOT NULL DEFAULT 0,
    "requirementUnit" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "order" INTEGER NOT NULL DEFAULT 0,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "public"."fee_change_logs" (
    "id" TEXT NOT NULL,
    "type" "public"."FeeChangeType" NOT NULL,
    "itemId" TEXT,
    "itemName" TEXT,
    "oldValue" JSONB,
    "newValue" JSONB,
    "reason" TEXT,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "transaction_fee_settings_key_key" ON "public"."transaction_fee_settings"("key");

-- CreateIndex
CREATE INDEX "listing_fee_tiers_enabled_idx" ON "public"."listing_fee_tiers"("enabled");

-- CreateIndex
CREATE INDEX "listing_fee_tiers_order_idx" ON "public"."listing_fee_tiers"("order");

-- CreateIndex
CREATE INDEX "commission_tiers_enabled_idx" ON "public"."commission_tiers"("enabled");

-- CreateIndex
CREATE INDEX "commission_tiers_order_idx" ON "public"."commission_tiers"("order");

-- CreateIndex
CREATE INDEX "fee_change_logs_type_idx" ON "public"."fee_change_logs"("type");

-- CreateIndex
CREATE INDEX "fee_change_logs_createdAt_idx" ON "public"."fee_change_logs"("createdAt");

-- AddForeignKey
ALTER TABLE "public"."transaction_fee_settings" ADD CONSTRAINT "transaction_fee_settings_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."listing_fee_tiers" ADD CONSTRAINT "listing_fee_tiers_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."commission_tiers" ADD CONSTRAINT "commission_tiers_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."fee_change_logs" ADD CONSTRAINT "fee_change_logs_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
