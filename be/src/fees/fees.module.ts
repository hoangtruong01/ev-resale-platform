import { Module } from '@nestjs/common';
import { FeesService } from './fees.service';
import { AdminFeesController } from './admin-fees.controller';

@Module({
  controllers: [AdminFeesController],
  providers: [FeesService],
})
export class FeesModule {}
