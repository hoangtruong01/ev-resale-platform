import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ContentModerationService } from './content-moderation.service';

@Module({
  imports: [PrismaModule],
  providers: [ContentModerationService],
  exports: [ContentModerationService],
})
export class ModerationModule {}
