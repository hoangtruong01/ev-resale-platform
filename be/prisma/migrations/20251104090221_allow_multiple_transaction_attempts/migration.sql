-- DropIndex
DROP INDEX "public"."transactions_batteryId_key";

-- DropIndex
DROP INDEX "public"."transactions_vehicleId_key";

-- CreateIndex
CREATE INDEX "transactions_vehicleId_idx" ON "transactions"("vehicleId");

-- CreateIndex
CREATE INDEX "transactions_batteryId_idx" ON "transactions"("batteryId");
