import { IsOptional, IsString } from 'class-validator';

export class JoinRoomDto {
  @IsString()
  roomId!: string;

  @IsOptional()
  @IsString()
  userId?: string;
}
