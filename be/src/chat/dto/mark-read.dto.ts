import { IsOptional, IsString } from 'class-validator';

export class MarkReadDto {
  @IsString()
  roomId!: string;

  @IsOptional()
  @IsString()
  userId?: string;
}
