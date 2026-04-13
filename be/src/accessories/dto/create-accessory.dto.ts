import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsOptional,
  IsEnum,
  IsArray,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AccessoryCategory } from '@prisma/client';

export class CreateAccessoryDto {
  @ApiProperty({ description: 'Accessory name' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Accessory category', enum: AccessoryCategory })
  @IsEnum(AccessoryCategory)
  category: AccessoryCategory;

  @ApiPropertyOptional({ description: 'Accessory brand' })
  @IsOptional()
  @IsString()
  brand?: string;

  @ApiPropertyOptional({ description: 'Compatible vehicle model' })
  @IsOptional()
  @IsString()
  compatibleModel?: string;

  @ApiProperty({ description: 'Accessory condition' })
  @IsNotEmpty()
  @IsString()
  condition: string;

  @ApiProperty({ description: 'Accessory price in VND' })
  @IsNumber()
  @Min(0)
  @Max(999999999999.99)
  price: number;

  @ApiPropertyOptional({ description: 'Accessory description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Accessory location' })
  @IsNotEmpty()
  @IsString()
  location: string;

  @ApiPropertyOptional({ description: 'Array of image URLs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];
}
