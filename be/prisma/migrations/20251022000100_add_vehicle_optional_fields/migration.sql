-- AlterTable
ALTER TABLE "vehicles"
  ADD COLUMN "color" TEXT,
  ADD COLUMN "transmission" TEXT,
  ADD COLUMN "seatCount" INTEGER,
  ADD COLUMN "hasWarranty" BOOLEAN DEFAULT false;
