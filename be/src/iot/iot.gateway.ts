import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ForbiddenException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: 'iot',
})
export class IotGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private logger: Logger = new Logger('IotGateway');

  constructor(private readonly jwtService: JwtService) {}

  handleConnection(client: Socket) {
    const userId = this.extractUserIdFromJwt(client);
    if (!userId) {
      this.logger.warn(`Unauthorized IoT socket rejected: ${client.id}`);
      client.disconnect(true);
      return;
    }

    const data = client.data as { userId?: string };
    data.userId = userId;
    this.logger.log(`Client connected to IoT: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected from IoT: ${client.id}`);
  }

  @SubscribeMessage('subscribeBattery')
  async handleSubscribeBattery(client: Socket, batteryId: string) {
    this.requireSocketUserId(client);
    const room = `battery:${batteryId}`;
    await client.join(room);
    this.logger.log(`Client ${client.id} joined room ${room}`);
    return { event: 'subscribed', data: room };
  }

  @SubscribeMessage('unsubscribeBattery')
  async handleUnsubscribeBattery(client: Socket, batteryId: string) {
    this.requireSocketUserId(client);
    const room = `battery:${batteryId}`;
    await client.leave(room);
    this.logger.log(`Client ${client.id} left room ${room}`);
    return { event: 'unsubscribed', data: room };
  }

  broadcastTelemetry(batteryId: string, data: any) {
    const room = `battery:${batteryId}`;
    this.server.to(room).emit('battery:telemetry', data);
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
}
