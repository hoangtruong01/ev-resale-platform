import { Body, Controller, Post, Req, ValidationPipe } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SupportTicketsService } from './support-tickets.service';
import { CreateSupportTicketDto } from './dto';

interface RequestWithUser {
  user?: {
    id?: string;
    sub?: string;
  };
}

@ApiTags('SupportTickets')
@Controller('support-tickets')
export class SupportTicketsController {
  constructor(private readonly supportTicketsService: SupportTicketsService) {}

  @Post()
  @ApiOperation({
    summary: 'Create support ticket',
    description: 'Create a support ticket request from a user or guest',
  })
  @ApiResponse({ status: 201, description: 'Support ticket created' })
  async create(
    @Body(ValidationPipe) payload: CreateSupportTicketDto,
    @Req() req: RequestWithUser,
  ) {
    const userId = req.user?.id ?? req.user?.sub;
    return this.supportTicketsService.create({
      ...payload,
      userId: payload.userId ?? userId,
    });
  }
}
