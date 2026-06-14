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
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
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

interface AuthenticatedRequest extends Request {
  user?: {
    id?: string;
    sub: string;
    email: string;
    role: string;
  };
}

function resolveUserId(user?: {
  id?: string;
  sub?: string;
}): string | undefined {
  return user?.id ?? user?.sub;
}

@ApiTags('Chat')
@Controller('chat')
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  @Post('rooms')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get or create a chat room' })
  createRoom(@Req() req: AuthenticatedRequest, @Body(new ValidationPipe({ whitelist: true })) dto: CreateRoomDto) {
    const buyerId = resolveUserId(req.user);
    if (!buyerId) {
      throw new BadRequestException('User identity is required.');
    }
    return this.chatService.getOrCreateRoom({ ...dto, buyerId });
  }

  @Get('rooms')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'List chat rooms for a user' })
  async listRooms(@Req() req: AuthenticatedRequest) {
    const userId = resolveUserId(req.user);
    if (!userId) {
      throw new BadRequestException('User identity is required.');
    }
    return this.chatService.findRoomsForUser(userId);
  }

  @Get('rooms/:roomId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get room details' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  getRoom(@Param('roomId') roomId: string, @Req() req: AuthenticatedRequest) {
    const userId = resolveUserId(req.user);
    if (!userId) {
      throw new BadRequestException('User identity is required.');
    }
    return this.chatService.getRoom(roomId, userId);
  }

  @Get('rooms/:roomId/messages')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get messages in a room' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  getRoomMessages(
    @Param('roomId') roomId: string,
    @Req() req: AuthenticatedRequest,
    @Query('limit') limit?: string,
  ) {
    const userId = resolveUserId(req.user);
    if (!userId) {
      throw new BadRequestException('User identity is required.');
    }
    const parsedLimit = Number(limit);
    const safeLimit = Number.isFinite(parsedLimit) ? parsedLimit : undefined;
    return this.chatService.getRoomMessages(roomId, userId, safeLimit);
  }

  @Post('rooms/:roomId/messages')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Send a message in a room' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  createMessage(
    @Param('roomId') roomId: string,
    @Req() req: AuthenticatedRequest,
    @Body() dto: Omit<SendMessageDto, 'roomId'>,
  ) {
    const senderId = resolveUserId(req.user);
    if (!senderId) {
      throw new BadRequestException('User identity is required.');
    }
    return this.chatService.createMessage({ ...dto, roomId, senderId });
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
    @Req() req: AuthenticatedRequest,
    @Body(new ValidationPipe({ whitelist: true })) dto: ProposeContractDto,
  ) {
    const proposerId = resolveUserId(req.user);
    if (!proposerId) {
      throw new BadRequestException('User identity is required.');
    }
    const result = await this.chatService.proposeContract(roomId, proposerId, dto);
    this.chatGateway.broadcastMessage(roomId, result.systemMessage);
    return result;
  }
}
