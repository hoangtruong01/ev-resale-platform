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
import { AccessoryCategory, AccessoryStatus } from '@prisma/client';

export class SearchAccessoryDto {
  @ApiPropertyOptional({ description: 'Search term for accessory name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    description: 'Accessory category filter',
    enum: AccessoryCategory,
  })
  @IsOptional()
  @IsEnum(AccessoryCategory)
  category?: AccessoryCategory;

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

  @ApiPropertyOptional({
    description: 'Accessory status filter',
    enum: AccessoryStatus,
  })
  @IsOptional()
  @IsEnum(AccessoryStatus)
  status?: AccessoryStatus;

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
    enum: ['createdAt', 'price'],
  })
  @IsOptional()
  @IsString()
  sortBy?: string = 'createdAt';

  @ApiPropertyOptional({ description: 'Sort order', enum: ['asc', 'desc'] })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc' = 'desc';
}
