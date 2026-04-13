import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminAnalyticsService } from './admin-analytics.service';
import { UsersModule } from '../users/users.module';
import { BatteriesModule } from '../batteries/batteries.module';
import { AuctionsModule } from '../auctions/auctions.module';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { AccessoriesModule } from '../accessories/accessories.module';
import { TransactionsModule } from '../transactions/transactions.module';
import { SupportTicketsModule } from '../support-tickets/support-tickets.module';

@Module({
  imports: [
    UsersModule,
    BatteriesModule,
    AuctionsModule,
    VehiclesModule,
    AccessoriesModule,
    TransactionsModule,
    SupportTicketsModule,
  ],
  controllers: [AdminController],
  providers: [AdminAnalyticsService],
})
export class AdminModule {}
