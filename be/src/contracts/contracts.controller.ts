import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ContractsService } from './contracts.service';
import { SignContractDto } from './dto';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
} from '@nestjs/swagger';

function resolveUserId(user: { id?: string; sub?: string }): string {
  return (user.id ?? user.sub) as string;
}

@ApiTags('Contracts')
@Controller('contracts')
export class ContractsController {
  constructor(private readonly contractsService: ContractsService) {}

  @UseGuards(JwtAuthGuard)
  @Get('admin/list')
  @ApiOperation({ summary: '[Admin] List all contracts' })
  listForAdmin(@Req() req: any, @Query('status') status?: string) {
    return this.contractsService.listContractsForAdmin(req.user.role, status);
  }

  /**
   * Get contract status by contractId (for Flutter chat polling)
   */
  @UseGuards(JwtAuthGuard)
  @Get(':contractId/status')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get contract status by contractId' })
  @ApiParam({ name: 'contractId', description: 'Contract ID' })
  getContractStatus(@Param('contractId') contractId: string, @Req() req: any) {
    const userId = resolveUserId(req.user);
    return this.contractsService.getContractStatus(contractId, userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':transactionId')
  @ApiOperation({ summary: 'Get contract by transactionId' })
  getContract(@Param('transactionId') transactionId: string, @Req() req: any) {
    return this.contractsService.getContractForUser(
      transactionId,
      resolveUserId(req.user),
      req.user.role,
    );
  }

  /**
   * Sign contract by contractId (Flutter flow)
   */
  @UseGuards(JwtAuthGuard)
  @Post(':contractId/sign')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Sign contract by contractId' })
  @ApiParam({ name: 'contractId', description: 'Contract ID' })
  signContractById(
    @Param('contractId') contractId: string,
    @Req() req: any,
    @Body(new ValidationPipe({ whitelist: true })) dto: SignContractDto,
  ) {
    const userId = resolveUserId(req.user);
    return this.contractsService.signContractById(contractId, userId, dto);
  }

  /**
   * Legacy sign by transactionId
   */
  @UseGuards(JwtAuthGuard)
  @Post(':transactionId/sign-by-transaction')
  signContract(
    @Param('transactionId') transactionId: string,
    @Req() req: any,
    @Body(new ValidationPipe({ whitelist: true })) dto: SignContractDto,
  ) {
    return this.contractsService.signContract(
      transactionId,
      resolveUserId(req.user),
      req.user.role,
      dto,
    );
  }
}
