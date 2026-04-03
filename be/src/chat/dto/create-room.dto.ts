import { IsOptional, IsString } from 'class-validator';

export class CreateRoomDto {
  @IsString()
  buyerId!: string;

  @IsString()
  sellerId!: string;

  @IsOptional()
  @IsString()
  vehicleId?: string;

  @IsOptional()
  @IsString()
  batteryId?: string;
}
