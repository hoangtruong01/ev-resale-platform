import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { AccessoryCategory, BatteryType } from '@prisma/client';

export class AiVehiclePriceSuggestionDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  brand!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  model!: string;

  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(2000)
  @Max(new Date().getFullYear() + 1)
  year!: number;

  @Transform(({ value }) => Number(value))
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(2000000)
  mileage?: number;

  @IsString()
  @IsOptional()
  @MaxLength(40)
  condition?: string;

  @IsString()
  @IsOptional()
  @MaxLength(80)
  location?: string;
}

export class AiBatteryPriceSuggestionDto {
  @IsEnum(BatteryType)
  type!: BatteryType;

  @Transform(({ value }) => Number(value))
  @IsNumber()
  @Min(0.1)
  @Max(1000)
  capacity!: number;

  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(0)
  @Max(100)
  condition!: number;

  @Transform(({ value }) => Number(value))
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  soh?: number;

  @IsString()
  @IsOptional()
  @MaxLength(80)
  location?: string;
}

export class AiAccessoryPriceSuggestionDto {
  @IsEnum(AccessoryCategory)
  category!: AccessoryCategory;

  @IsString()
  @IsOptional()
  @MaxLength(80)
  brand?: string;

  @IsString()
  @IsOptional()
  @MaxLength(120)
  compatibleModel?: string;

  @IsString()
  @IsOptional()
  @MaxLength(40)
  condition?: string;

  @IsString()
  @IsOptional()
  @MaxLength(80)
  location?: string;
}
