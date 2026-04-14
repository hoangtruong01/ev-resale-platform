import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { StatsService } from './stats.service';

@ApiTags('Stats')
@Controller('stats')
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get('overview')
  @ApiOperation({
    summary: 'Get public overview statistics',
    description: 'Counts of listings, users, and completed transactions',
  })
  async getOverview() {
    return this.statsService.getOverview();
  }
}
