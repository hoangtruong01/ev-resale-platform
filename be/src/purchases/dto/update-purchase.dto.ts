import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsIn, IsDate } from 'class-validator';
import { PurchaseStatus } from '@prisma/client';
import { Type } from 'class-transformer';

export class UpdatePurchaseDto {
  @ApiPropertyOptional({
    description: 'Purchase status',
    enum: PurchaseStatus,
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
}
