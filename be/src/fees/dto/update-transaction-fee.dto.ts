import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, Min, IsOptional, IsString } from 'class-validator';

export class UpdateTransactionFeeDto {
  @ApiProperty({ description: 'Transaction fee percentage', minimum: 0 })
  @IsNumber()
  @Min(0)
  rate!: number;

  @ApiPropertyOptional({ description: 'Minimum fee amount', minimum: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  minFee?: number;

  @ApiPropertyOptional({ description: 'Maximum fee amount', minimum: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxFee?: number;

  @ApiPropertyOptional({ description: 'Change reason for audit log' })
  @IsOptional()
  @IsString()
  reason?: string;
}
