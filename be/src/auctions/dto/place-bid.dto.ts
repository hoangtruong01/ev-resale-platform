import { IsNotEmpty, IsNumber, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class PlaceBidDto {
  @ApiProperty({ description: 'Bid amount in VND' })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  amount: number;
}
