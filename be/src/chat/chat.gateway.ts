import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { JoinRoomDto } from './dto/join-room.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { MarkReadDto } from './dto/mark-read.dto';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ChatGateway.name);
  private readonly connections = new Map<string, Set<string>>();

  constructor(private readonly chatService: ChatService) {}

  handleConnection(client: Socket) {
    const userId = this.extractUserId(client);

    if (!userId) {
      client.disconnect(true);
      return;
    }

    const set = this.connections.get(userId) ?? new Set<string>();
    set.add(client.id);
    this.connections.set(userId, set);

    this.logger.debug(`Client ${client.id} connected for user ${userId}`);
  }

  handleDisconnect(client: Socket) {
    const userId = this.extractUserId(client);

    if (!userId) {
      return;
    }

    const set = this.connections.get(userId);
    if (set) {
      set.delete(client.id);
      if (!set.size) {
        this.connections.delete(userId);
      }
    }

    this.logger.debug(`Client ${client.id} disconnected for user ${userId}`);
  }

  @SubscribeMessage('joinRoom')
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: JoinRoomDto,
  ) {
    try {
      client.join(payload.roomId);
      await this.chatService.markMessagesAsRead(payload.roomId, payload.userId);
      const history = await this.chatService.getRoomMessages(
        payload.roomId,
        100,
      );
      client.emit('chat:history', {
        roomId: payload.roomId,
        messages: history,
      });
      return { status: 'ok' };
    } catch (error: unknown) {
      this.handleError(client, error as Error);
    }
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SendMessageDto,
  ) {
    try {
      const message = await this.chatService.createMessage(payload);
      this.server.to(payload.roomId).emit('chat:message', message);
      return { status: 'ok', message };
    } catch (error: unknown) {
      this.handleError(client, error as Error);
    }
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: MarkReadDto,
  ) {
    try {
      const result = await this.chatService.markMessagesAsRead(
        payload.roomId,
        payload.userId,
      );
      client.emit('chat:read', { roomId: payload.roomId, ...result });
      return { status: 'ok', ...result };
    } catch (error: unknown) {
      this.handleError(client, error as Error);
    }
  }

  private extractUserId(client: Socket): string | null {
    const authAny = client.handshake.auth as
      | Record<string, unknown>
      | undefined;
    const queryAny = client.handshake.query as
      | Record<string, unknown>
      | undefined;

    const direct = authAny?.userId ?? queryAny?.userId;

    if (typeof direct === 'string' && direct.trim()) {
      return direct;
    }

    return null;
  }

  private handleError(client: Socket, error: Error) {
    const message = error.message ?? 'Unexpected error';
    client.emit('chat:error', { message });
    throw new WsException(message);
  }
}
