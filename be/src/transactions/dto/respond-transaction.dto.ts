import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString } from 'class-validator';

type TransactionResponseAction = 'accept' | 'reject';

export class RespondTransactionDto {
  @ApiProperty({
    enum: ['accept', 'reject'],
    description: 'Buyer decision for the transaction',
  })
  @IsString()
  @IsIn(['accept', 'reject'])
  action!: TransactionResponseAction;
}
