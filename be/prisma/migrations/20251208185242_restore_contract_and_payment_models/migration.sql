-- CreateEnum
CREATE TYPE "public"."ContractStatus" AS ENUM ('PENDING', 'BUYER_SIGNED', 'SELLER_SIGNED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "public"."ContractPartyRole" AS ENUM ('BUYER', 'SELLER');

-- CreateEnum
CREATE TYPE "public"."PaymentCardBrand" AS ENUM ('VISA', 'MASTERCARD', 'JCB', 'AMEX', 'OTHER');

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

-- CreateTable
CREATE TABLE "public"."payment_methods" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "brand" "public"."PaymentCardBrand" NOT NULL DEFAULT 'VISA',
    "cardholderName" TEXT NOT NULL,
    "encryptedCardNumber" TEXT NOT NULL,
    "encryptionIv" TEXT NOT NULL,
    "encryptionAuthTag" TEXT NOT NULL,
    "cardLast4" TEXT NOT NULL,
    "expiryMonth" INTEGER NOT NULL,
    "expiryYear" INTEGER NOT NULL,
    "billingAddress" TEXT,
    "isDefault" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "contracts_transactionId_key" ON "public"."contracts"("transactionId");

-- CreateIndex
CREATE UNIQUE INDEX "contract_signatures_contractId_role_key" ON "public"."contract_signatures"("contractId", "role");

-- CreateIndex
CREATE INDEX "payment_methods_userId_idx" ON "public"."payment_methods"("userId");

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

-- AddForeignKey
ALTER TABLE "public"."payment_methods" ADD CONSTRAINT "payment_methods_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
