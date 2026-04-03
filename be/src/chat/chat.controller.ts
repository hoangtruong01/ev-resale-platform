import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  BadRequestException,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('rooms')
  createRoom(@Body() dto: CreateRoomDto) {
    return this.chatService.getOrCreateRoom(dto);
  }

  @Get('rooms')
  async listRooms(@Query('userId') userId?: string) {
    if (!userId) {
      throw new BadRequestException('Query parameter "userId" is required.');
    }

    return this.chatService.findRoomsForUser(userId);
  }

  @Get('rooms/:roomId')
  getRoom(@Param('roomId') roomId: string) {
    return this.chatService.getRoom(roomId);
  }

  @Get('rooms/:roomId/messages')
  getRoomMessages(
    @Param('roomId') roomId: string,
    @Query('limit') limit?: string,
  ) {
    const parsedLimit = Number(limit);
    const safeLimit = Number.isFinite(parsedLimit) ? parsedLimit : undefined;
    return this.chatService.getRoomMessages(roomId, safeLimit);
  }

  @Post('rooms/:roomId/messages')
  createMessage(
    @Param('roomId') roomId: string,
    @Body() dto: Omit<SendMessageDto, 'roomId'>,
  ) {
    return this.chatService.createMessage({ ...dto, roomId });
  }
}
