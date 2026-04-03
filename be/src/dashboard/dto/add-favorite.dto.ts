import { IsOptional, IsUUID } from 'class-validator';

export class AddFavoriteDto {
  @IsOptional()
  @IsUUID('4', { message: 'vehicleId phải là UUID hợp lệ' })
  vehicleId?: string;

  @IsOptional()
  @IsUUID('4', { message: 'batteryId phải là UUID hợp lệ' })
  batteryId?: string;

  @IsOptional()
  @IsUUID('4', { message: 'auctionId phải là UUID hợp lệ' })
  auctionId?: string;
}
