import { Module } from '@nestjs/common';
import { BatteriesController } from './batteries.controller';
import { BatteriesService } from './batteries.service';
import { ModerationModule } from '../moderation/moderation.module';

@Module({
  imports: [ModerationModule],
  controllers: [BatteriesController],
  providers: [BatteriesService],
  exports: [BatteriesService],
})
export class BatteriesModule {}
