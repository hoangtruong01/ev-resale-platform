import { Module } from '@nestjs/common';
import { ComparisonsService } from './comparisons.service';
import { ComparisonsController } from './comparisons.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [ComparisonsController],
  providers: [ComparisonsService, PrismaService],
  exports: [ComparisonsService],
})
export class ComparisonsModule {}
