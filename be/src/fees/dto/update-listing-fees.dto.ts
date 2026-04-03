import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class ListingFeeTierDto {
  @ApiPropertyOptional({ description: 'Existing tier identifier' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ description: 'Tier display name' })
  @IsString()
  name!: string;

  @ApiProperty({ description: 'Listing duration in days', minimum: 1 })
  @IsInt()
  @Min(1)
  duration!: number;

  @ApiProperty({ description: 'Feature list', type: [String] })
  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  features!: string[];

  @ApiProperty({ description: 'Listing price', minimum: 0 })
  @IsNumber()
  @Min(0)
  price!: number;

  @ApiProperty({ description: 'Is tier active' })
  @IsBoolean()
  enabled!: boolean;

  @ApiPropertyOptional({ description: 'Display order (ascending)' })
  @IsOptional()
  @IsInt()
  order?: number;
}

export class UpdateListingFeesDto {
  @ApiProperty({ type: [ListingFeeTierDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => ListingFeeTierDto)
  tiers!: ListingFeeTierDto[];

  @ApiPropertyOptional({ description: 'Change reason for audit log' })
  @IsOptional()
  @IsString()
  reason?: string;
}

export { ListingFeeTierDto };
