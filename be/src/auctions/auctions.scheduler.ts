import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuctionsService } from './auctions.service';

@Injectable()
export class AuctionsScheduler {
  private readonly logger = new Logger(AuctionsScheduler.name);

  constructor(private readonly auctionsService: AuctionsService) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async activatePendingAuctions() {
    const activated = await this.auctionsService.activateScheduledAuctions();

    if (activated > 0) {
      this.logger.log(`Scheduler activated ${activated} auction(s).`);
    }
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async concludeExpiredAuctions() {
    const ended = await this.auctionsService.endExpiredAuctions();

    if (ended > 0) {
      this.logger.log(`Scheduler closed ${ended} auction(s).`);
    }
  }
}
