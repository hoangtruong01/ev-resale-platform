import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SendMessageDto {
  @IsString()
  roomId!: string;

  @IsOptional()
  @IsString()
  senderId?: string;

  @IsString()
  @IsNotEmpty()
  content!: string;

  @IsOptional()
  metadata?: Record<string, unknown>;
}
