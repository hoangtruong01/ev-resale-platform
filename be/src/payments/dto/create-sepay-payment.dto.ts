import {
  IsOptional,
  IsString,
  IsUUID,
  IsEnum,
} from 'class-validator';
import { PaymentType } from '@prisma/client';

export class CreateSepayPaymentDto {
  @IsUUID()
  @IsString()
  transactionId!: string;

  @IsOptional()
  @IsEnum(PaymentType)
  paymentType?: PaymentType = PaymentType.FULL;
}
