import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsUUID, IsArray, IsOptional } from 'class-validator';

export class UpdateComparisonDto {
  @ApiPropertyOptional({ description: 'Comparison name' })
  @IsOptional()
  @IsString()
  name?: string;

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
