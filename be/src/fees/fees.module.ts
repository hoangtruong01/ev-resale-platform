import { Module } from '@nestjs/common';
import { FeesService } from './fees.service';
import { AdminFeesController } from './admin-fees.controller';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';

@Module({
  imports: [AuditLogsModule],
  controllers: [AdminFeesController],
  providers: [FeesService],
})
export class FeesModule {}
