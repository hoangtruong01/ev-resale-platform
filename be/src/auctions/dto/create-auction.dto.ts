import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsDateString,
  Min,
  Max,
  IsInt,
  MinLength,
  MaxLength,
  IsEnum,
  IsArray,
  ArrayNotEmpty,
  ArrayMaxSize,
  IsEmail,
  ValidateIf,
  IsIn,
  IsString,
  Matches,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ALLOWED_AUCTION_ITEM_TYPES,
  MAX_AUCTION_PRICE,
} from '../auction.constants';
import type { AllowedAuctionItemType } from '../auction.constants';

export class CreateAuctionDto {
  @ApiProperty({ description: 'Auction title' })
  @IsNotEmpty()
  @IsString()
  title: string;

  @ApiPropertyOptional({ description: 'Auction description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Starting price in VND' })
  @IsNumber()
  @Min(0)
  @Max(MAX_AUCTION_PRICE)
  startingPrice: number;

  @ApiProperty({ description: 'Bid step amount in VND' })
  @IsNumber()
  @Min(1000)
  @Max(MAX_AUCTION_PRICE)
  bidStep: number;

  @ApiPropertyOptional({ description: 'Buy now price in VND' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(MAX_AUCTION_PRICE)
  buyNowPrice?: number;

  @ApiProperty({ description: 'Auction start time' })
  @IsDateString()
  startTime: string;

  @ApiProperty({ description: 'Auction end time' })
  @IsDateString()
  endTime: string;

  @ApiProperty({
    enum: ALLOWED_AUCTION_ITEM_TYPES,
    description: 'Type of auctioned item',
  })
  @IsIn(ALLOWED_AUCTION_ITEM_TYPES)
  itemType: AllowedAuctionItemType;

  @ApiProperty({ description: 'Quantity available in this lot', default: 1 })
  @IsInt()
  @Min(1)
  lotQuantity: number;

  @ApiPropertyOptional({ description: 'Brand of the item' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  itemBrand?: string;

  @ApiPropertyOptional({ description: 'Model of the item' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  itemModel?: string;

  @ApiPropertyOptional({ description: 'Manufacturing year' })
  @IsOptional()
  @IsInt()
  itemYear?: number;

  @ApiPropertyOptional({ description: 'Mileage in km (vehicles)', minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  itemMileage?: number;

  @ApiPropertyOptional({
    description: 'Battery capacity in Ah (batteries)',
    minimum: 0,
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  itemCapacity?: number;

  @ApiPropertyOptional({
    description: 'Remaining condition percentage (0-100)',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  itemCondition?: number;

  @ApiProperty({ description: 'Location string' })
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  location: string;

  @ApiProperty({ description: 'Contact phone number' })
  @IsString()
  @MinLength(6)
  @MaxLength(20)
  contactPhone: string;

  @ApiPropertyOptional({ description: 'Contact email' })
  @IsOptional()
  @IsEmail()
  contactEmail?: string;

  @ApiPropertyOptional({ description: 'Image URLs for the auction' })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateIf((_, value) => Array.isArray(value))
  @IsString({ each: true })
  @Matches(/^(https?:\/\/[^\s]+|\/[^\s]+)$/i, {
    each: true,
    message:
      'Mỗi đường dẫn hình ảnh phải là URL hợp lệ hoặc đường dẫn tuyệt đối bắt đầu bằng /.',
  })
  imageUrls?: string[];
}
