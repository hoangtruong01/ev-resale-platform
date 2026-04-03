import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsOptional,
  IsArray,
  IsEnum,
  IsDecimal,
  IsBoolean,
  Min,
  Max,
} from 'class-validator';
import { Transform } from 'class-transformer';

export enum VehicleStatus {
  AVAILABLE = 'AVAILABLE',
  SOLD = 'SOLD',
  AUCTION = 'AUCTION',
  RESERVED = 'RESERVED',
}

export class CreateVehicleDto {
  @ApiProperty({ description: 'Vehicle name', example: 'Tesla Model 3 2021' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Vehicle brand', example: 'Tesla' })
  @IsString()
  brand: string;

  @ApiProperty({ description: 'Vehicle model', example: 'Model 3' })
  @IsString()
  model: string;

  @ApiProperty({ description: 'Production year', example: 2021 })
  @IsNumber()
  @Min(2000)
  @Max(new Date().getFullYear() + 1)
  year: number;

  @ApiProperty({ description: 'Vehicle price in VND', example: 850000000 })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({
    description: 'Mileage in km',
    example: 25000,
    required: false,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  mileage?: number;

  @ApiProperty({ description: 'Vehicle condition', example: 'Excellent' })
  @IsString()
  condition: string;

  @ApiProperty({ description: 'Vehicle description', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({
    description: 'Array of image URLs',
    example: ['/images/vehicle1.jpg', '/images/vehicle2.jpg'],
    required: false,
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @ApiProperty({ description: 'Vehicle location', example: 'Hà Nội' })
  @IsString()
  location: string;

  @ApiProperty({ description: 'Vehicle color', example: 'Đỏ' })
  @IsString()
  color: string;

  @ApiProperty({ description: 'Transmission type', example: 'Tự động' })
  @IsString()
  transmission: string;

  @ApiProperty({ description: 'Number of seats', example: 5 })
  @Transform(({ value }) => {
    const parsed =
      typeof value === 'string' ? parseInt(value, 10) : Number(value);
    return Number.isFinite(parsed) ? parsed : value;
  })
  @IsNumber()
  @Min(1)
  @Max(60)
  seatCount: number;

  @ApiProperty({
    description: 'Whether the vehicle is still under warranty',
    example: true,
  })
  @Transform(({ value }) => {
    if (typeof value === 'boolean') {
      return value;
    }

    if (typeof value === 'string') {
      const normalized = value.trim().toLowerCase();
      if (normalized === 'true' || normalized === '1') return true;
      if (normalized === 'false' || normalized === '0') return false;
    }

    return Boolean(value);
  })
  @IsBoolean()
  hasWarranty: boolean;

  @ApiProperty({
    description: 'Vehicle status',
    enum: VehicleStatus,
    default: VehicleStatus.AVAILABLE,
    required: false,
  })
  @IsOptional()
  @IsEnum(VehicleStatus)
  status?: VehicleStatus;
}
