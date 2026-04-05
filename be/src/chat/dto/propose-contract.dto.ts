import { IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ProposeContractDto {
  @ApiProperty({ description: 'The negotiated price for the deal', example: '50000000' })
  @IsString()
  agreedPrice: string;

  @ApiPropertyOptional({ description: 'Optional notes about the deal' })
  @IsOptional()
  @IsString()
  notes?: string;
}
