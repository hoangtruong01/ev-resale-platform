import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, Min } from 'class-validator';

export class UpdateBidDto {
  @ApiPropertyOptional({ description: 'Bid amount' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  amount?: number;
}
