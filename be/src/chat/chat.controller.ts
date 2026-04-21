import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
  ValidationPipe,
  BadRequestException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatService } from './chat.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { ProposeContractDto } from './dto/propose-contract.dto';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiBody,
} from '@nestjs/swagger';

@ApiTags('Chat')
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('rooms')
  @ApiOperation({ summary: 'Get or create a chat room' })
  createRoom(@Body() dto: CreateRoomDto) {
    return this.chatService.getOrCreateRoom(dto);
  }

  @Get('rooms')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'List chat rooms for a user' })
  async listRooms(@Req() req: any) {
    const userId = req.user?.id ?? req.user?.sub;
    if (!userId) {
      throw new BadRequestException('User identity is required.');
    }
    return this.chatService.findRoomsForUser(userId);
  }

  @Get('rooms/:roomId')
  @ApiOperation({ summary: 'Get room details' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  getRoom(@Param('roomId') roomId: string) {
    return this.chatService.getRoom(roomId);
  }

  @Get('rooms/:roomId/messages')
  @ApiOperation({ summary: 'Get messages in a room' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  getRoomMessages(
    @Param('roomId') roomId: string,
    @Query('limit') limit?: string,
  ) {
    const parsedLimit = Number(limit);
    const safeLimit = Number.isFinite(parsedLimit) ? parsedLimit : undefined;
    return this.chatService.getRoomMessages(roomId, safeLimit);
  }

  @Post('rooms/:roomId/messages')
  @ApiOperation({ summary: 'Send a message in a room' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  createMessage(
    @Param('roomId') roomId: string,
    @Body() dto: Omit<SendMessageDto, 'roomId'>,
  ) {
    return this.chatService.createMessage({ ...dto, roomId });
  }

  /**
   * Propose a contract from within the chat room.
   * Requires both buyer and seller to have KYC APPROVED.
   * Creates a Transaction + Contract and broadcasts a system message.
   */
  @Post('rooms/:roomId/propose-contract')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Propose a digital contract for both parties to sign',
    description:
      'Verifies KYC of both buyer and seller, then creates a contract and ' +
      'sends a system chat message with the signing request.',
  })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  @ApiBody({ type: ProposeContractDto })
  async proposeContract(
    @Param('roomId') roomId: string,
    @Req() req: any,
    @Body(new ValidationPipe({ whitelist: true })) dto: ProposeContractDto,
  ) {
    const proposerId = req.user?.id ?? req.user?.sub;
    return this.chatService.proposeContract(roomId, proposerId, dto);
  }
}
