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
import { BidsService } from './bids.service';
import { CreateBidDto, UpdateBidDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';

@ApiTags('bids')
@Controller('bids')
export class BidsController {
  constructor(private readonly bidsService: BidsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new bid' })
  @ApiResponse({
    status: 201,
    description: 'Bid has been successfully created',
  })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  create(@Body() createBidDto: CreateBidDto) {
    return this.bidsService.create(createBidDto);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all bids with pagination' })
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
  @ApiResponse({ status: 200, description: 'Return all bids' })
  findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.bidsService.findAll(page || 1, limit || 10);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get a bid by ID' })
  @ApiParam({ name: 'id', description: 'Bid ID' })
  @ApiResponse({ status: 200, description: 'Return the bid' })
  @ApiResponse({ status: 404, description: 'Bid not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.bidsService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a bid (Admin only)' })
  @ApiParam({ name: 'id', description: 'Bid ID' })
  @ApiResponse({ status: 200, description: 'Bid has been updated' })
  @ApiResponse({ status: 404, description: 'Bid not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateBidDto: UpdateBidDto,
  ) {
    return this.bidsService.update(id, updateBidDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a bid (Admin only)' })
  @ApiParam({ name: 'id', description: 'Bid ID' })
  @ApiResponse({ status: 200, description: 'Bid has been deleted' })
  @ApiResponse({ status: 404, description: 'Bid not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.bidsService.remove(id);
  }

  @Get('auction/:auctionId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get bids by auction ID' })
  @ApiParam({ name: 'auctionId', description: 'Auction ID' })
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
  @ApiResponse({ status: 200, description: 'Return bids for the auction' })
  findByAuction(
    @Param('auctionId', ParseUUIDPipe) auctionId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.bidsService.findByAuction(auctionId, page || 1, limit || 10);
  }

  @Get('bidder/:bidderId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get bids by bidder ID' })
  @ApiParam({ name: 'bidderId', description: 'Bidder ID' })
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
  @ApiResponse({ status: 200, description: 'Return bids for the bidder' })
  findByBidder(
    @Param('bidderId', ParseUUIDPipe) bidderId: string,
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.bidsService.findByBidder(bidderId, page || 1, limit || 10);
  }

  @Get('auction/:auctionId/highest')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get highest bid for an auction' })
  @ApiParam({ name: 'auctionId', description: 'Auction ID' })
  @ApiResponse({
    status: 200,
    description: 'Return highest bid for the auction',
  })
  @ApiResponse({ status: 404, description: 'No bids found for this auction' })
  getHighestBid(@Param('auctionId', ParseUUIDPipe) auctionId: string) {
    return this.bidsService.getHighestBidForAuction(auctionId);
  }
}
