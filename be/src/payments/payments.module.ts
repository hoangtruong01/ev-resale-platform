import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ChatModule } from '../chat/chat.module';
import { ContractsModule } from '../contracts/contracts.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';

@Module({
  imports: [ConfigModule, ChatModule, ContractsModule],
  controllers: [PaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
