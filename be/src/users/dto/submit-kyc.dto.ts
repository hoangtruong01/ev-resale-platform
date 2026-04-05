import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum IdType {
  CMND = 'CMND',
  CCCD = 'CCCD',
  PASSPORT = 'PASSPORT',
  OTHER = 'OTHER',
}

export class SubmitKycDto {
  @ApiProperty({ description: 'ID number (Số CMND/CCCD/Hộ chiếu)' })
  @IsString()
  idNumber: string;

  @ApiProperty({ enum: IdType, description: 'ID document type' })
  @IsEnum(IdType)
  idType: IdType;

  @ApiPropertyOptional({ description: 'Full name exactly as on ID card' })
  @IsOptional()
  @IsString()
  fullNameOnId?: string;

  @ApiPropertyOptional({ description: 'Date of issue (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  idIssueDate?: string;

  @ApiPropertyOptional({ description: 'Place of issue' })
  @IsOptional()
  @IsString()
  idIssuePlace?: string;
}

export class ReviewKycDto {
  @ApiProperty({ enum: ['APPROVED', 'REJECTED'], description: 'KYC decision' })
  @IsEnum(['APPROVED', 'REJECTED'])
  decision: 'APPROVED' | 'REJECTED';

  @ApiPropertyOptional({ description: 'Admin notes / rejection reason' })
  @IsOptional()
  @IsString()
  notes?: string;
}
