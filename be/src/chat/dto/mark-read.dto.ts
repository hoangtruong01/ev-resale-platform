import { IsString } from 'class-validator';

export class MarkReadDto {
  @IsString()
  roomId!: string;

  @IsString()
  userId!: string;
}
