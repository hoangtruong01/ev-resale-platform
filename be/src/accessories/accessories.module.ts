import { Module } from '@nestjs/common';
import { AccessoriesController } from './accessories.controller';
import { AccessoriesService } from './accessories.service';
import { ModerationModule } from '../moderation/moderation.module';

@Module({
  imports: [ModerationModule],
  controllers: [AccessoriesController],
  providers: [AccessoriesService],
  exports: [AccessoriesService],
})
export class AccessoriesModule {}
