import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateVnpayPaymentDto {
  @IsUUID()
  @IsString()
  transactionId!: string;

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
