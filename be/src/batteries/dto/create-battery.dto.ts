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
import { BatteryType } from '@prisma/client';

export class CreateBatteryDto {
  @ApiProperty({ description: 'Battery name' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ description: 'Battery type', enum: BatteryType })
  @IsEnum(BatteryType)
  type: BatteryType;

  @ApiProperty({ description: 'Battery capacity in kWh' })
  @IsNumber()
  @Min(0)
  @Max(999999.99)
  capacity: number;

  @ApiPropertyOptional({ description: 'Battery voltage in V' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(999999.99)
  voltage?: number;

  @ApiProperty({ description: 'Battery condition percentage (0-100)' })
  @IsNumber()
  @Min(0)
  @Max(100)
  condition: number;

  @ApiProperty({ description: 'Battery price in VND' })
  @IsNumber()
  @Min(0)
  @Max(999999999999.99)
  price: number;

  @ApiPropertyOptional({ description: 'Battery description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Battery location' })
  @IsNotEmpty()
  @IsString()
  location: string;

  @ApiPropertyOptional({ description: 'Array of image URLs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];
}
