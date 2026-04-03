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

@Controller('contracts')
export class ContractsController {
  constructor(private readonly contractsService: ContractsService) {}

  @UseGuards(JwtAuthGuard)
  @Get('admin/list')
  listForAdmin(@Req() req: any, @Query('status') status?: string) {
    return this.contractsService.listContractsForAdmin(req.user.role, status);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':transactionId')
  getContract(@Param('transactionId') transactionId: string, @Req() req: any) {
    return this.contractsService.getContractForUser(
      transactionId,
      req.user.id,
      req.user.role,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Post(':transactionId/sign')
  signContract(
    @Param('transactionId') transactionId: string,
    @Req() req: any,
    @Body(new ValidationPipe({ whitelist: true })) dto: SignContractDto,
  ) {
    return this.contractsService.signContract(
      transactionId,
      req.user.id,
      req.user.role,
      dto,
    );
  }
}
