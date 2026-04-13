import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { BatteriesModule } from './batteries/batteries.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { AuctionsModule } from './auctions/auctions.module';
import { AccessoriesModule } from './accessories/accessories.module';
import { AdminModule } from './admin/admin.module';
import { SettingsModule } from './settings/settings.module';
import { TransactionsModule } from './transactions/transactions.module';
import { PurchasesModule } from './purchases/purchases.module';
import { BidsModule } from './bids/bids.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ComparisonsModule } from './comparisons/comparisons.module';
import { PrismaModule } from './prisma/prisma.module';
import { ChatModule } from './chat/chat.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { PaymentsModule } from './payments/payments.module';
import { FeesModule } from './fees/fees.module';
import { SupportTicketsModule } from './support-tickets/support-tickets.module';
import { IotModule } from './iot/iot.module';
import { UploadsModule } from './uploads/uploads.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    BatteriesModule,
    VehiclesModule,
    AccessoriesModule,
    AuctionsModule,
    AdminModule,
    SettingsModule,
    TransactionsModule,
    PurchasesModule,
    BidsModule,
    NotificationsModule,
    ComparisonsModule,
    ChatModule,
    DashboardModule,
    PaymentsModule,
    FeesModule,
    SupportTicketsModule,
    IotModule,
    UploadsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
