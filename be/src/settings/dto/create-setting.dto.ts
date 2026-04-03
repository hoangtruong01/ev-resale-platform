import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsEnum, IsOptional } from 'class-validator';

export enum SettingType {
  STRING = 'string',
  NUMBER = 'number',
  BOOLEAN = 'boolean',
  JSON = 'json',
}

export class CreateSettingDto {
  @ApiProperty({ description: 'Setting key (unique identifier)' })
  @IsNotEmpty()
  @IsString()
  key: string;

  @ApiProperty({ description: 'Setting value' })
  @IsNotEmpty()
  @IsString()
  value: string;

  @ApiPropertyOptional({
    description: 'Setting type',
    enum: SettingType,
    default: SettingType.STRING,
  })
  @IsOptional()
  @IsEnum(SettingType)
  type?: SettingType;
}
