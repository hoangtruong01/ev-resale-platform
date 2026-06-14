ALTER TABLE "chat_rooms" ADD COLUMN IF NOT EXISTS "accessoryId" TEXT;
ALTER TABLE "transactions" ADD COLUMN IF NOT EXISTS "accessoryId" TEXT;

ALTER TABLE "chat_rooms" DROP CONSTRAINT IF EXISTS "chat_rooms_accessoryId_fkey";
ALTER TABLE "transactions" DROP CONSTRAINT IF EXISTS "transactions_accessoryId_fkey";

ALTER TABLE "chat_rooms" ADD CONSTRAINT "chat_rooms_accessoryId_fkey"
  FOREIGN KEY ("accessoryId") REFERENCES "accessories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "transactions" ADD CONSTRAINT "transactions_accessoryId_fkey"
  FOREIGN KEY ("accessoryId") REFERENCES "accessories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

DROP INDEX IF EXISTS "chat_rooms_buyerId_sellerId_vehicleId_batteryId_key";
CREATE UNIQUE INDEX IF NOT EXISTS "chat_rooms_buyerId_sellerId_vehicleId_batteryId_accessoryId_key"
  ON "chat_rooms"("buyerId", "sellerId", "vehicleId", "batteryId", "accessoryId");

CREATE INDEX IF NOT EXISTS "transactions_accessoryId_idx" ON "transactions"("accessoryId");