import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminAnalyticsService } from './admin-analytics.service';
import { UsersModule } from '../users/users.module';
import { BatteriesModule } from '../batteries/batteries.module';
import { AuctionsModule } from '../auctions/auctions.module';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { TransactionsModule } from '../transactions/transactions.module';

@Module({
  imports: [
    UsersModule,
    BatteriesModule,
    AuctionsModule,
    VehiclesModule,
    TransactionsModule,
  ],
  controllers: [AdminController],
  providers: [AdminAnalyticsService],
})
export class AdminModule {}
