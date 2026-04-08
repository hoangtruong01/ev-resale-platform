import { Module } from '@nestjs/common';
import { AuctionsController } from './auctions.controller';
import { AuctionsService } from './auctions.service';
import { ModerationModule } from '../moderation/moderation.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuctionsScheduler } from './auctions.scheduler';
import { MailModule } from '../mail/mail.module';
import { SmsModule } from '../sms/sms.module';

@Module({
  imports: [ModerationModule, NotificationsModule, MailModule, SmsModule],
  controllers: [AuctionsController],
  providers: [AuctionsService, AuctionsScheduler],
  exports: [AuctionsService],
})
export class AuctionsModule {}
