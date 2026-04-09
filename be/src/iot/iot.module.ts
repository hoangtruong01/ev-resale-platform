import { Module } from '@nestjs/common';
import { IotGateway } from './iot.gateway';
import { PlcSimulatorService } from './plc-simulator.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [IotGateway, PlcSimulatorService],
  exports: [IotGateway],
})
export class IotModule {}
