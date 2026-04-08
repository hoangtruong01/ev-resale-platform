import { Module } from '@nestjs/common';
import { BidsService } from './bids.service';
import { BidsController } from './bids.controller';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { MailModule } from '../mail/mail.module';
import { SmsModule } from '../sms/sms.module';

@Module({
  imports: [NotificationsModule, MailModule, SmsModule],
  controllers: [BidsController],
  providers: [BidsService, PrismaService],
  exports: [BidsService],
})
export class BidsModule {}
