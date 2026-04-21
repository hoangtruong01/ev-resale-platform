import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { IotGateway } from './iot.gateway';
import { PlcSimulatorService } from './plc-simulator.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET,
    }),
  ],
  providers: [IotGateway, PlcSimulatorService],
  exports: [IotGateway],
})
export class IotModule {}
