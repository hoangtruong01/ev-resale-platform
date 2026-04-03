-- CreateEnum
CREATE TYPE "public"."ContractStatus" AS ENUM ('PENDING', 'BUYER_SIGNED', 'SELLER_SIGNED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "public"."ContractPartyRole" AS ENUM ('BUYER', 'SELLER');

-- DropIndex
DROP INDEX "public"."transaction_disputes_status_idx";

-- AlterTable
ALTER TABLE "public"."commission_tiers" ADD CONSTRAINT "commission_tiers_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "public"."fee_change_logs" ADD CONSTRAINT "fee_change_logs_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "public"."listing_fee_tiers" ADD CONSTRAINT "listing_fee_tiers_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "public"."password_resets" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "public"."transaction_fee_settings" ADD CONSTRAINT "transaction_fee_settings_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "public"."transactions" ADD COLUMN     "paymentDeadline" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "public"."contracts" (
    "id" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL,
    "buyerId" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "templatePath" TEXT,
    "finalPdfPath" TEXT,
    "status" "public"."ContractStatus" NOT NULL DEFAULT 'PENDING',
    "buyerSignedAt" TIMESTAMP(3),
    "sellerSignedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "requestEmailSentAt" TIMESTAMP(3),
    "finalEmailSentAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "contracts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."contract_signatures" (
    "id" TEXT NOT NULL,
    "contractId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" "public"."ContractPartyRole" NOT NULL,
    "signaturePath" TEXT NOT NULL,
    "signedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "contract_signatures_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "contracts_transactionId_key" ON "public"."contracts"("transactionId");

-- CreateIndex
CREATE UNIQUE INDEX "contract_signatures_contractId_role_key" ON "public"."contract_signatures"("contractId", "role");

-- AddForeignKey
ALTER TABLE "public"."contracts" ADD CONSTRAINT "contracts_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "public"."transactions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."contracts" ADD CONSTRAINT "contracts_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "public"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."contracts" ADD CONSTRAINT "contracts_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "public"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."contract_signatures" ADD CONSTRAINT "contract_signatures_contractId_fkey" FOREIGN KEY ("contractId") REFERENCES "public"."contracts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."contract_signatures" ADD CONSTRAINT "contract_signatures_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
