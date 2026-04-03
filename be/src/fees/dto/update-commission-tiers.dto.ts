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

class CommissionTierDto {
  @ApiPropertyOptional({ description: 'Existing tier identifier' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ description: 'Tier display name' })
  @IsString()
  name!: string;

  @ApiProperty({ description: 'Commission rate percent', minimum: 0 })
  @IsNumber()
  @Min(0)
  rate!: number;

  @ApiProperty({ description: 'Minimum requirement threshold', minimum: 0 })
  @IsInt()
  @Min(0)
  minRequirement!: number;

  @ApiProperty({ description: 'Requirement unit label' })
  @IsString()
  requirementUnit!: string;

  @ApiProperty({ description: 'Is tier active' })
  @IsBoolean()
  enabled!: boolean;

  @ApiPropertyOptional({ description: 'Display order (ascending)' })
  @IsOptional()
  @IsInt()
  order?: number;
}

export class UpdateCommissionTiersDto {
  @ApiProperty({ type: [CommissionTierDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => CommissionTierDto)
  tiers!: CommissionTierDto[];

  @ApiPropertyOptional({ description: 'Change reason for audit log' })
  @IsOptional()
  @IsString()
  reason?: string;
}

export { CommissionTierDto };
