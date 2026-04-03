import { Module } from '@nestjs/common';
import { BidsService } from './bids.service';
import { BidsController } from './bids.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [BidsController],
  providers: [BidsService, PrismaService],
  exports: [BidsService],
})
export class BidsModule {}
