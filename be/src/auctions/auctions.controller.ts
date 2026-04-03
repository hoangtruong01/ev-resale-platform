import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { AuctionsService } from './auctions.service';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiBody,
  ApiResponse,
  ApiQuery,
} from '@nestjs/swagger';
import { CreateAuctionDto, SearchAuctionDto, PlaceBidDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Request } from 'express';

interface AuthenticatedRequest extends Request {
  user: {
    sub: string;
    email: string;
    role: string;
  };
}

@ApiTags('Auctions')
@Controller('auctions')
export class AuctionsController {
  constructor(private readonly auctionsService: AuctionsService) {}

  @Get()
  @ApiOperation({
    summary: 'Search auctions',
    description: 'Search and filter auctions with pagination',
  })
  @ApiResponse({
    status: 200,
    description: 'Auctions retrieved successfully',
  })
  async findAll(@Query(ValidationPipe) query: SearchAuctionDto) {
    return this.auctionsService.findAll(query);
  }

  @Get('statistics')
  @ApiOperation({
    summary: 'Get auction statistics',
    description: 'Get overall auction statistics',
  })
  async getStatistics() {
    return this.auctionsService.getStatistics();
  }

  @Get('my-auctions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get my auctions',
    description: 'Get current user auction listings',
  })
  async getMyAuctions(
    @Req() req: AuthenticatedRequest,
    @Query(ValidationPipe) query: SearchAuctionDto,
  ) {
    return this.auctionsService.getMyAuctions(req.user.sub, query);
  }

  @Get('my-bids')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get my bids',
    description: 'Get current user bid history',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getMyBids(
    @Req() req: AuthenticatedRequest,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.auctionsService.getMyBids(req.user.sub, page, limit);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get auction by ID',
    description: 'Retrieve detailed information about a specific auction',
  })
  @ApiParam({ name: 'id', description: 'Auction ID' })
  @ApiResponse({
    status: 200,
    description: 'Auction found',
  })
  @ApiResponse({
    status: 404,
    description: 'Auction not found',
  })
  async findOne(@Param('id') id: string) {
    return this.auctionsService.findOne(id);
  }

  @Get(':id/bids')
  @ApiOperation({
    summary: 'Get all bids for auction',
    description: 'Get paginated list of bids for a specific auction',
  })
  @ApiParam({ name: 'id', description: 'Auction ID' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getBids(
    @Param('id') auctionId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.auctionsService.getBidsForAuction(auctionId, page, limit);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create new auction',
    description: 'Create a new auction for a vehicle or battery',
  })
  @ApiBody({ type: CreateAuctionDto })
  @ApiResponse({
    status: 201,
    description: 'Auction created successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Bad request - Invalid data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async create(
    @Body(ValidationPipe) createAuctionDto: CreateAuctionDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.auctionsService.create(createAuctionDto, req.user.sub);
  }

  @Post(':id/bid')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Place a bid on auction',
    description: 'Place a new bid on an active auction',
  })
  @ApiParam({ name: 'id', description: 'Auction ID' })
  @ApiBody({ type: PlaceBidDto })
  @ApiResponse({
    status: 201,
    description: 'Bid placed successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Bad request - Invalid bid amount or auction not active',
  })
  @ApiResponse({
    status: 404,
    description: 'Auction not found',
  })
  async placeBid(
    @Param('id') auctionId: string,
    @Body(ValidationPipe) placeBidDto: PlaceBidDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.auctionsService.placeBid(auctionId, placeBidDto, req.user.sub);
  }

  @Put(':id/end')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'End auction',
    description: 'End an active auction and process the winner',
  })
  @ApiParam({ name: 'id', description: 'Auction ID' })
  @ApiResponse({
    status: 200,
    description: 'Auction ended successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Bad request - Auction cannot be ended',
  })
  @ApiResponse({
    status: 404,
    description: 'Auction not found',
  })
  async endAuction(
    @Param('id') auctionId: string,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.auctionsService.endAuction(auctionId, req.user.sub);
  }
}
