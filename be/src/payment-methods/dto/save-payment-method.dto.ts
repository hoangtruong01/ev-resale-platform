import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

const CURRENT_YEAR = new Date().getFullYear();

export class SavePaymentMethodDto {
  @ApiProperty({ description: 'Tên chủ thẻ', example: 'Nguyen Van A' })
  @IsString()
  @MinLength(3)
  @MaxLength(80)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  cardholderName!: string;

  @ApiProperty({
    description:
      'Số thẻ Visa (chỉ ký tự số, cho phép nhập cách nhau bằng khoảng trắng)',
    example: '4111 1111 1111 1111',
  })
  @IsString()
  @Matches(/^[0-9\s-]{13,19}$/u, {
    message: 'Số thẻ Visa chỉ được chứa 13-19 chữ số',
  })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  cardNumber!: string;

  @ApiProperty({
    description: 'Tháng hết hạn',
    example: 12,
    minimum: 1,
    maximum: 12,
  })
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(12)
  expiryMonth!: number;

  @ApiProperty({
    description: 'Năm hết hạn (YYYY)',
    example: CURRENT_YEAR + 3,
  })
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(CURRENT_YEAR)
  @Max(CURRENT_YEAR + 20)
  expiryYear!: number;

  @ApiPropertyOptional({ description: 'Địa chỉ thanh toán', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  billingAddress?: string;
}
