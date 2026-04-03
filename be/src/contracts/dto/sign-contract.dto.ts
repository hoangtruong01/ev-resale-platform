import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SignContractDto {
  @IsString()
  @IsNotEmpty()
  signatureData!: string;

  @IsString()
  @IsOptional()
  signingDevice?: string;
}
