import { IsOptional, IsString, IsUUID, MaxLength, IsEnum } from 'class-validator';
import { PaymentType } from '@prisma/client';

export class CreateVnpayPaymentDto {
  @IsUUID()
  @IsString()
  transactionId!: string;

  @IsOptional()
  @IsEnum(PaymentType)
  paymentType?: PaymentType = PaymentType.FULL;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  bankCode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  orderInfo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  returnUrl?: string;
}
