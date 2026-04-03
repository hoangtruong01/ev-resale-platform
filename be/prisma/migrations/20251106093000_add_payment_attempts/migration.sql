-- CreateEnum
CREATE TYPE "public"."PaymentGateway" AS ENUM ('VNPAY');

-- CreateEnum
CREATE TYPE "public"."PaymentAttemptStatus" AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED');

-- CreateTable
CREATE TABLE "public"."payment_attempts" (
    "id" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL,
    "gateway" "public"."PaymentGateway" NOT NULL,
    "status" "public"."PaymentAttemptStatus" NOT NULL DEFAULT 'PENDING',
    "amount" DECIMAL(12,2) NOT NULL,
    "bankCode" TEXT,
    "orderInfo" TEXT,
    "txnRef" TEXT NOT NULL,
    "payUrl" TEXT,
    "ipAddress" TEXT,
    "vnpSecureHash" TEXT,
    "vnpParams" JSONB,
    "responseCode" TEXT,
    "callbackAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_attempts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "payment_attempts_txnRef_key" ON "public"."payment_attempts"("txnRef");

-- CreateIndex
CREATE INDEX "payment_attempts_transactionId_idx" ON "public"."payment_attempts"("transactionId");

-- CreateIndex
CREATE INDEX "payment_attempts_gateway_idx" ON "public"."payment_attempts"("gateway");

-- CreateIndex
CREATE INDEX "payment_attempts_status_idx" ON "public"."payment_attempts"("status");

-- AddForeignKey
ALTER TABLE "public"."payment_attempts" ADD CONSTRAINT "payment_attempts_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "public"."transactions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
