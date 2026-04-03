import {
  IsOptional,
  IsString,
  IsNumber,
  IsEnum,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BatteryType, BatteryStatus } from '@prisma/client';

export class SearchBatteryDto {
  @ApiPropertyOptional({ description: 'Search term for battery name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    description: 'Battery type filter',
    enum: BatteryType,
  })
  @IsOptional()
  @IsEnum(BatteryType)
  type?: BatteryType;

  @ApiPropertyOptional({ description: 'Minimum capacity in kWh' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minCapacity?: number;

  @ApiPropertyOptional({ description: 'Maximum capacity in kWh' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  maxCapacity?: number;

  @ApiPropertyOptional({ description: 'Minimum price in VND' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional({ description: 'Maximum price in VND' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  maxPrice?: number;

  @ApiPropertyOptional({ description: 'Minimum condition percentage' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(100)
  minCondition?: number;

  @ApiPropertyOptional({ description: 'Maximum condition percentage' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(100)
  maxCondition?: number;

  @ApiPropertyOptional({
    description: 'Battery status filter',
    enum: BatteryStatus,
  })
  @IsOptional()
  @IsEnum(BatteryStatus)
  status?: BatteryStatus;

  @ApiPropertyOptional({
    description: 'Approval status filter',
    enum: ['PENDING', 'APPROVED', 'REJECTED'],
  })
  @IsOptional()
  @IsString()
  approvalStatus?: string;

  @ApiPropertyOptional({ description: 'Location filter' })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Items per page', default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number = 10;

  @ApiPropertyOptional({
    description: 'Sort field',
    enum: ['createdAt', 'price', 'capacity', 'condition'],
  })
  @IsOptional()
  @IsString()
  sortBy?: string = 'createdAt';

  @ApiPropertyOptional({ description: 'Sort order', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc' = 'desc';
}
