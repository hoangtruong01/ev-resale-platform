import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

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

  handleConnection(client: Socket) {
    this.logger.log(`Client connected to IoT: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected from IoT: ${client.id}`);
  }

  @SubscribeMessage('subscribeBattery')
  handleSubscribeBattery(client: Socket, batteryId: string) {
    const room = `battery:${batteryId}`;
    client.join(room);
    this.logger.log(`Client ${client.id} joined room ${room}`);
    return { event: 'subscribed', data: room };
  }

  @SubscribeMessage('unsubscribeBattery')
  handleUnsubscribeBattery(client: Socket, batteryId: string) {
    const room = `battery:${batteryId}`;
    client.leave(room);
    this.logger.log(`Client ${client.id} left room ${room}`);
    return { event: 'unsubscribed', data: room };
  }

  broadcastTelemetry(batteryId: string, data: any) {
    const room = `battery:${batteryId}`;
    this.server.to(room).emit('battery:telemetry', data);
  }
}
