import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class ResolveTransactionDisputeDto {
  @IsIn(['buyer', 'seller', 'partial', 'BUYER', 'SELLER', 'PARTIAL'])
  resolution!: 'buyer' | 'seller' | 'partial';

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

