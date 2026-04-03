-- AlterTable
ALTER TABLE "transactions"
    ADD COLUMN "chatRoomId" TEXT,
    ADD COLUMN "buyerAccepted" BOOLEAN,
    ADD COLUMN "buyerRespondedAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "transactions_chatRoomId_idx" ON "transactions"("chatRoomId");

-- AddForeignKey
ALTER TABLE "transactions"
    ADD CONSTRAINT "transactions_chatRoomId_fkey"
    FOREIGN KEY ("chatRoomId")
    REFERENCES "chat_rooms"("id")
    ON DELETE SET NULL
    ON UPDATE CASCADE;
