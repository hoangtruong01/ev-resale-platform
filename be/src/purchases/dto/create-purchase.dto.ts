import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  IsIn,
  IsDate,
} from 'class-validator';
import { PurchaseStatus } from '@prisma/client';
import { Type } from 'class-transformer';

export class CreatePurchaseDto {
  @ApiProperty({
    description: 'Purchase status',
    enum: PurchaseStatus,
    default: PurchaseStatus.PENDING,
  })
  @IsOptional()
  @IsString()
  @IsIn(Object.values(PurchaseStatus))
  status?: PurchaseStatus;

  @ApiPropertyOptional({ description: 'Expected delivery date' })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  deliveryDate?: Date;

  @ApiPropertyOptional({
    description: 'Purchase notes or additional information',
  })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ description: 'Buyer ID' })
  @IsNotEmpty()
  @IsUUID()
  buyerId: string;

  @ApiProperty({ description: 'Transaction ID' })
  @IsNotEmpty()
  @IsUUID()
  transactionId: string;
}
