import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsUUID, Min } from 'class-validator';

export class CreateBidDto {
  @ApiProperty({ description: 'Bid amount' })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  amount: number;

  @ApiProperty({ description: 'Bidder ID' })
  @IsNotEmpty()
  @IsUUID()
  bidderId: string;

  @ApiProperty({ description: 'Auction ID' })
  @IsNotEmpty()
  @IsUUID()
  auctionId: string;
}
