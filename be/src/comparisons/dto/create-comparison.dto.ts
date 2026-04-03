import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsString,
  IsUUID,
  IsArray,
  IsOptional,
} from 'class-validator';

export class CreateComparisonDto {
  @ApiProperty({ description: 'Comparison name' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiPropertyOptional({ description: 'List of vehicle IDs to compare' })
  @IsOptional()
  @IsArray()
  @IsUUID(undefined, { each: true })
  vehicleIds?: string[];

  @ApiPropertyOptional({ description: 'List of battery IDs to compare' })
  @IsOptional()
  @IsArray()
  @IsUUID(undefined, { each: true })
  batteryIds?: string[];
}
