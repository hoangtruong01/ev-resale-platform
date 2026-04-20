import {
  Body,
  Controller,
  Get,
  Put,
  Query,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Request } from 'express';
import { FeesService } from './fees.service';
import {
  UpdateTransactionFeeDto,
  UpdateListingFeesDto,
  UpdateCommissionTiersDto,
} from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../auth/dto/auth.dto';
import { AuditLogsService } from '../audit-logs/audit-logs.service';

const FEE_CHANGE_TYPE_VALUES = [
  'TRANSACTION_FEE',
  'LISTING_FEE',
  'COMMISSION',
] as const;

type FeeChangeTypeParam = (typeof FEE_CHANGE_TYPE_VALUES)[number];

interface AdminRequest extends Request {
  user?: {
    sub: string;
    role: string;
    email: string;
  };
}

@ApiTags('Admin Fees')
@ApiBearerAuth('JWT-auth')
@Controller('admin/fees')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminFeesController {
  constructor(
    private readonly feesService: FeesService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  @Get('transaction')
  @ApiOperation({ summary: 'Get transaction fee configuration' })
  async getTransactionFeeSetting() {
    return this.feesService.getTransactionFeeSetting();
  }

  @Put('transaction')
  @ApiOperation({ summary: 'Update transaction fee configuration' })
  @ApiResponse({
    status: 200,
    description: 'Transaction fee updated successfully',
  })
  async updateTransactionFeeSetting(
    @Req() req: AdminRequest,
    @Body() body: UpdateTransactionFeeDto,
  ) {
    const adminId = req.user?.sub;

    if (!adminId) {
      throw new UnauthorizedException('Missing authenticated admin context');
    }

    const result = await this.feesService.updateTransactionFeeSetting(
      adminId,
      body,
    );

    await this.auditLogsService.log({
      actorId: adminId,
      actorRole: req.user?.role,
      action: 'UPDATE_FEES',
      targetType: 'TRANSACTION_FEE',
      targetId: result.setting.id,
    });

    return result;
  }

  @Get('listing')
  @ApiOperation({ summary: 'Get listing fee tiers' })
  async getListingFeeTiers() {
    return this.feesService.getListingFeeTiers();
  }

  @Put('listing')
  @ApiOperation({ summary: 'Update listing fee tiers' })
  async updateListingFeeTiers(
    @Req() req: AdminRequest,
    @Body() body: UpdateListingFeesDto,
  ) {
    const adminId = req.user?.sub;

    if (!adminId) {
      throw new UnauthorizedException('Missing authenticated admin context');
    }

    const result = await this.feesService.updateListingFeeTiers(adminId, body);

    await this.auditLogsService.log({
      actorId: adminId,
      actorRole: req.user?.role,
      action: 'UPDATE_FEES',
      targetType: 'LISTING_FEE',
      metadata: {
        tierCount: body.tiers.length,
      },
    });

    return result;
  }

  @Get('commissions')
  @ApiOperation({ summary: 'Get commission tiers' })
  async getCommissionTiers() {
    return this.feesService.getCommissionTiers();
  }

  @Put('commissions')
  @ApiOperation({ summary: 'Update commission tiers' })
  async updateCommissionTiers(
    @Req() req: AdminRequest,
    @Body() body: UpdateCommissionTiersDto,
  ) {
    const adminId = req.user?.sub;

    if (!adminId) {
      throw new UnauthorizedException('Missing authenticated admin context');
    }

    const result = await this.feesService.updateCommissionTiers(adminId, body);

    await this.auditLogsService.log({
      actorId: adminId,
      actorRole: req.user?.role,
      action: 'UPDATE_FEES',
      targetType: 'COMMISSION',
      metadata: {
        tierCount: body.tiers.length,
      },
    });

    return result;
  }

  @Get('history')
  @ApiOperation({ summary: 'Get fee & commission change history' })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: FEE_CHANGE_TYPE_VALUES,
    description: 'Filter history by change type',
  })
  async getHistory(@Query('type') type?: FeeChangeTypeParam) {
    return this.feesService.getFeeHistory(type);
  }

  @Get('revenue')
  @ApiOperation({ summary: 'Get revenue statistics from fees' })
  async getRevenueStats() {
    return this.feesService.getRevenueStats();
  }
}
