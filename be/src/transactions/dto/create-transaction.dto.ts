import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  IsIn,
  Min,
} from 'class-validator';
import { TransactionStatus } from '@prisma/client';

export class CreateTransactionDto {
  @ApiProperty({ description: 'Transaction amount' })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  amount: number;

  @ApiPropertyOptional({ description: 'Transaction fee' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  fee?: number;

  @ApiPropertyOptional({ description: 'Commission amount' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  commission?: number;

  @ApiProperty({
    description: 'Transaction status',
    enum: TransactionStatus,
    default: TransactionStatus.PENDING,
  })
  @IsOptional()
  @IsString()
  @IsIn(Object.values(TransactionStatus))
  status?: TransactionStatus;

  @ApiPropertyOptional({ description: 'Payment method' })
  @IsOptional()
  @IsString()
  paymentMethod?: string;

  @ApiPropertyOptional({ description: 'Transaction notes' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ description: 'Seller ID' })
  @IsNotEmpty()
  @IsUUID()
  sellerId: string;

  @ApiPropertyOptional({
    description: 'Vehicle ID (if transaction involves a vehicle)',
  })
  @IsOptional()
  @IsUUID()
  vehicleId?: string;

  @ApiPropertyOptional({
    description: 'Battery ID (if transaction involves a battery)',
  })
  @IsOptional()
  @IsUUID()
  batteryId?: string;

  @ApiPropertyOptional({
    description: 'Chat room ID linked to this transaction',
  })
  @IsOptional()
  @IsUUID()
  roomId?: string;
}
