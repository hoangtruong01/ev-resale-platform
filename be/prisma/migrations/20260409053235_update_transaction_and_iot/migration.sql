-- CreateEnum
CREATE TYPE "public"."PaymentType" AS ENUM ('DEPOSIT', 'BALANCE', 'FULL');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "public"."TransactionStatus" ADD VALUE 'AWAITING_DEPOSIT';
ALTER TYPE "public"."TransactionStatus" ADD VALUE 'DEPOSIT_PAID';
ALTER TYPE "public"."TransactionStatus" ADD VALUE 'AWAITING_CONTRACT';
ALTER TYPE "public"."TransactionStatus" ADD VALUE 'CONTRACT_SIGNED';
ALTER TYPE "public"."TransactionStatus" ADD VALUE 'AWAITING_BALANCE';

-- AlterTable
ALTER TABLE "public"."batteries" ADD COLUMN     "current" DECIMAL(8,2),
ADD COLUMN     "soc" INTEGER,
ADD COLUMN     "soh" INTEGER,
ADD COLUMN     "temperature" DECIMAL(5,2);

-- AlterTable
ALTER TABLE "public"."payment_attempts" ADD COLUMN     "paymentType" "public"."PaymentType" NOT NULL DEFAULT 'FULL';

-- AlterTable
ALTER TABLE "public"."transactions" ADD COLUMN     "balanceAmount" DECIMAL(12,2),
ADD COLUMN     "depositAmount" DECIMAL(12,2);
