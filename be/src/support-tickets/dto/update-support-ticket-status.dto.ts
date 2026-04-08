import { IsEnum } from 'class-validator';
import { SupportTicketStatus } from '@prisma/client';

export class UpdateSupportTicketStatusDto {
  @IsEnum(SupportTicketStatus)
  status: SupportTicketStatus;
}
