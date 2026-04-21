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
import { ForbiddenException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
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

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
  ) {}

  handleConnection(client: Socket) {
    const userId = this.extractUserIdFromJwt(client);

    if (!userId) {
      client.disconnect(true);
      return;
    }

    const data = client.data as { userId?: string };
    data.userId = userId;

    const set = this.connections.get(userId) ?? new Set<string>();
    set.add(client.id);
    this.connections.set(userId, set);

    this.logger.debug(`Client ${client.id} connected for user ${userId}`);
  }

  handleDisconnect(client: Socket) {
    const userId = this.readSocketUserId(client);

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
      const authUserId = this.requireSocketUserId(client);
      await client.join(payload.roomId);
      await this.chatService.markMessagesAsRead(payload.roomId, authUserId);
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
      return this.handleError(client, error as Error);
    }
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SendMessageDto,
  ) {
    try {
      const authUserId = this.requireSocketUserId(client);
      if (payload.senderId && payload.senderId !== authUserId) {
        throw new ForbiddenException('Sender identity mismatch');
      }

      const message = await this.chatService.createMessage({
        ...payload,
        senderId: authUserId,
      });
      this.server.to(payload.roomId).emit('chat:message', message);
      return { status: 'ok', message };
    } catch (error: unknown) {
      return this.handleError(client, error as Error);
    }
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: MarkReadDto,
  ) {
    try {
      const authUserId = this.requireSocketUserId(client);
      if (payload.userId && payload.userId !== authUserId) {
        throw new ForbiddenException('Reader identity mismatch');
      }

      const result = await this.chatService.markMessagesAsRead(
        payload.roomId,
        authUserId,
      );
      client.emit('chat:read', { roomId: payload.roomId, ...result });
      return { status: 'ok', ...result };
    } catch (error: unknown) {
      return this.handleError(client, error as Error);
    }
  }

  private extractUserIdFromJwt(client: Socket): string | null {
    const authAny = client.handshake.auth as
      | Record<string, unknown>
      | undefined;
    const rawHeader = client.handshake.headers.authorization;
    const headerToken =
      typeof rawHeader === 'string' && rawHeader.startsWith('Bearer ')
        ? rawHeader.replace('Bearer ', '').trim()
        : null;
    const authToken =
      typeof authAny?.token === 'string' ? authAny.token.trim() : null;
    const token = authToken || headerToken;

    if (!token) {
      return null;
    }

    try {
      const decoded = this.jwtService.verify<{ sub?: string }>(token);
      if (decoded.sub && decoded.sub.trim()) {
        return decoded.sub;
      }
    } catch {
      return null;
    }

    return null;
  }

  private requireSocketUserId(client: Socket): string {
    const userId = this.readSocketUserId(client);
    if (!userId) {
      throw new ForbiddenException('Unauthorized socket session');
    }

    return userId;
  }

  private readSocketUserId(client: Socket): string | undefined {
    const data = client.data as { userId?: string };
    return data.userId;
  }

  private handleError(client: Socket, error: Error): never {
    const message = error.message ?? 'Unexpected error';
    client.emit('chat:error', { message });
    throw new WsException(message);
  }
}
