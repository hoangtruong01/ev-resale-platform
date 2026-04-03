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
} from '@nestjs/common';
import { PurchasesService } from './purchases.service';
import { CreatePurchaseDto, UpdatePurchaseDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { PurchaseStatus, UserRole } from '@prisma/client';
import { Roles } from '../auth/roles.decorator';

@ApiTags('purchases')
@Controller('purchases')
export class PurchasesController {
  constructor(private readonly purchasesService: PurchasesService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new purchase' })
  @ApiResponse({
    status: 201,
    description: 'Purchase has been successfully created',
  })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  create(@Body() createPurchaseDto: CreatePurchaseDto) {
    return this.purchasesService.create(createPurchaseDto);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all purchases with pagination' })
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
    enum: PurchaseStatus,
    description: 'Filter by status',
  })
  @ApiResponse({ status: 200, description: 'Return all purchases' })
  findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
    @Query('status') status?: PurchaseStatus,
  ) {
    return this.purchasesService.findAll(page || 1, limit || 10, status);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get a purchase by ID' })
  @ApiParam({ name: 'id', description: 'Purchase ID' })
  @ApiResponse({ status: 200, description: 'Return the purchase' })
  @ApiResponse({ status: 404, description: 'Purchase not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.purchasesService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a purchase' })
  @ApiParam({ name: 'id', description: 'Purchase ID' })
  @ApiResponse({ status: 200, description: 'Purchase has been updated' })
  @ApiResponse({ status: 404, description: 'Purchase not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updatePurchaseDto: UpdatePurchaseDto,
  ) {
    return this.purchasesService.update(id, updatePurchaseDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a purchase' })
  @ApiParam({ name: 'id', description: 'Purchase ID' })
  @ApiResponse({ status: 200, description: 'Purchase has been deleted' })
  @ApiResponse({ status: 404, description: 'Purchase not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.purchasesService.remove(id);
  }

  @Get('buyer/:buyerId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get purchases by buyer ID' })
  @ApiParam({ name: 'buyerId', description: 'Buyer ID' })
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
  @ApiResponse({ status: 200, description: 'Return purchases for the buyer' })
  findByBuyer(
    @Param('buyerId', ParseUUIDPipe) buyerId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.purchasesService.findByBuyer(buyerId, page || 1, limit || 10);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update purchase status' })
  @ApiParam({ name: 'id', description: 'Purchase ID' })
  @ApiResponse({ status: 200, description: 'Purchase status has been updated' })
  @ApiResponse({ status: 404, description: 'Purchase not found' })
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: PurchaseStatus,
  ) {
    return this.purchasesService.updateStatus(id, status);
  }

  @Get('transaction/:transactionId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get purchase by transaction ID' })
  @ApiParam({ name: 'transactionId', description: 'Transaction ID' })
  @ApiResponse({
    status: 200,
    description: 'Return purchase for the transaction',
  })
  @ApiResponse({
    status: 404,
    description: 'Purchase not found for this transaction',
  })
  findByTransaction(
    @Param('transactionId', ParseUUIDPipe) transactionId: string,
  ) {
    return this.purchasesService.findByTransaction(transactionId);
  }
}
