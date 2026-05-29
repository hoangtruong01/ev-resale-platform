import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { IotGateway } from './iot.gateway';
import { PlcSimulatorService } from './plc-simulator.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret:
          configService.get<string>('JWT_SECRET') ||
          'evn-market-dev-jwt-secret',
      }),
    }),
  ],
  providers: [IotGateway, PlcSimulatorService],
  exports: [IotGateway],
})
export class IotModule {}
