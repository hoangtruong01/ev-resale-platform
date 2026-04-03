import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Query,
  ParseUUIDPipe,
  ParseIntPipe,
  Req,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import {
  CreateTransactionDto,
  UpdateTransactionDto,
  RespondTransactionDto,
} from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { TransactionStatus, UserRole } from '@prisma/client';
import { Roles } from 'auth/roles.decorator';
import type { Request } from 'express';

@ApiTags('transactions')
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new transaction' })
  @ApiResponse({
    status: 201,
    description: 'Transaction has been successfully created',
  })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  create(
    @Body() createTransactionDto: CreateTransactionDto,
    @Req() req: Request,
  ) {
    const userId = this.resolveUserId(req);

    if (
      createTransactionDto.sellerId &&
      createTransactionDto.sellerId !== userId
    ) {
      throw new ForbiddenException('Người bán không hợp lệ cho giao dịch này');
    }

    return this.transactionsService.create({
      ...createTransactionDto,
      sellerId: userId,
    });
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all transactions with pagination' })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: TransactionStatus,
    description: 'Filter by status',
  })
  @ApiResponse({ status: 200, description: 'Return all transactions' })
  findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
    @Query('status') status?: TransactionStatus,
  ) {
    return this.transactionsService.findAll(page || 1, limit || 10, status);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get a transaction by ID' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  @ApiResponse({ status: 200, description: 'Return the transaction' })
  @ApiResponse({ status: 404, description: 'Transaction not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.transactionsService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a transaction' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  @ApiResponse({ status: 200, description: 'Transaction has been updated' })
  @ApiResponse({ status: 404, description: 'Transaction not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateTransactionDto: UpdateTransactionDto,
  ) {
    return this.transactionsService.update(id, updateTransactionDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a transaction' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  @ApiResponse({ status: 200, description: 'Transaction has been deleted' })
  @ApiResponse({ status: 404, description: 'Transaction not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.transactionsService.remove(id);
  }

  @Get('vehicle/:vehicleId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get transactions by vehicle ID' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Return transactions related to the vehicle',
  })
  findByVehicle(@Param('vehicleId', ParseUUIDPipe) vehicleId: string) {
    return this.transactionsService.findByVehicle(vehicleId);
  }

  @Get('battery/:batteryId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get transactions by battery ID' })
  @ApiParam({ name: 'batteryId', description: 'Battery ID' })
  @ApiResponse({
    status: 200,
    description: 'Return transactions related to the battery',
  })
  findByBattery(@Param('batteryId', ParseUUIDPipe) batteryId: string) {
    return this.transactionsService.findByBattery(batteryId);
  }

  @Get('seller/:sellerId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get transactions by seller ID' })
  @ApiParam({ name: 'sellerId', description: 'Seller ID' })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page',
  })
  @ApiResponse({
    status: 200,
    description: 'Return transactions for the seller',
  })
  findBySeller(
    @Param('sellerId', ParseUUIDPipe) sellerId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.transactionsService.findBySeller(
      sellerId,
      page || 1,
      limit || 10,
    );
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update transaction status' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  @ApiResponse({
    status: 200,
    description: 'Transaction status has been updated',
  })
  @ApiResponse({ status: 404, description: 'Transaction not found' })
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: TransactionStatus,
  ) {
    return this.transactionsService.updateStatus(id, status);
  }

  @Post(':id/respond')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Buyer responds to a chat transaction offer' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  @ApiResponse({ status: 200, description: 'Quyết định đã được ghi nhận' })
  respond(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() respondDto: RespondTransactionDto,
    @Req() req: Request,
  ) {
    const userId = this.resolveUserId(req);
    return this.transactionsService.respondToChatTransaction(
      id,
      respondDto.action,
      userId,
    );
  }

  private resolveUserId(req: Request) {
    const user = req.user as { sub?: string; id?: string } | undefined;
    const userId = user?.sub ?? user?.id;
    if (!userId) {
      throw new UnauthorizedException('Không tìm thấy thông tin người dùng');
    }
    return userId;
  }
}
