import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
  ValidationPipe,
  ForbiddenException,
} from '@nestjs/common';
import { BatteriesService } from './batteries.service';
import { BatteryType } from '@prisma/client';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiQuery,
  ApiBody,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { CreateBatteryDto, UpdateBatteryDto, SearchBatteryDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
interface AuthenticatedRequest {
  headers: Record<string, unknown>;
  user?: unknown;
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const firstString = (values: unknown[]): string | undefined => {
  for (const value of values) {
    if (typeof value === 'string' && value.length > 0) {
      return value;
    }
  }
  return undefined;
};

const requireSellerId = (req: AuthenticatedRequest): string => {
  const headerValue = req.headers?.['x-user-id'];
  let headerId: string | undefined;

  if (typeof headerValue === 'string') {
    headerId = headerValue;
  } else if (Array.isArray(headerValue)) {
    headerId = firstString(headerValue);
  }

  if (isRecord(req.user)) {
    const idValue = req.user.id;
    if (typeof idValue === 'string' && idValue.length > 0) {
      return idValue;
    }

    const subValue = req.user.sub;
    if (typeof subValue === 'string' && subValue.length > 0) {
      return subValue;
    }
  }

  if (headerId && headerId.length > 0) {
    return headerId;
  }

  throw new ForbiddenException('Missing seller identity');
};

@ApiTags('Batteries')
@Controller('batteries')
export class BatteriesController {
  constructor(private readonly batteriesService: BatteriesService) {}

  @Get()
  @ApiOperation({
    summary: 'Search batteries',
    description: 'Search and filter batteries with pagination',
  })
  @ApiResponse({
    status: 200,
    description: 'Batteries retrieved successfully',
  })
  async findAll(@Query(ValidationPipe) query: SearchBatteryDto) {
    return this.batteriesService.findAll(query);
  }

  @Get('statistics')
  @ApiOperation({
    summary: 'Get battery statistics',
    description: 'Get overall battery statistics',
  })
  async getStatistics() {
    return this.batteriesService.getStatistics();
  }

  @Get('suggest-price')
  @ApiOperation({
    summary: 'Get price suggestion',
    description: 'Get AI-based price suggestion for battery',
  })
  @ApiQuery({
    name: 'type',
    enum: [
      'LITHIUM_ION',
      'LITHIUM_POLYMER',
      'NICKEL_METAL_HYDRIDE',
      'LEAD_ACID',
    ],
  })
  @ApiQuery({ name: 'capacity', type: Number })
  @ApiQuery({ name: 'condition', type: Number })
  async suggestPrice(
    @Query('type') type: string,
    @Query('capacity') capacity: number,
    @Query('condition') condition: number,
  ) {
    return {
      suggestedPrice: await this.batteriesService.suggestPrice({
        type: type as BatteryType,
        capacity: Number(capacity),
        condition: Number(condition),
      }),
    };
  }

  @Get('my-batteries')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get my battery listings',
    description: 'Get current user battery listings',
  })
  async getMyBatteries(
    @Req() req: AuthenticatedRequest,
    @Query(ValidationPipe) query: SearchBatteryDto,
  ) {
    return this.batteriesService.findByUser(requireSellerId(req), query);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get battery by ID',
    description: 'Retrieve detailed information about a specific battery',
  })
  @ApiParam({ name: 'id', description: 'Battery ID' })
  @ApiResponse({
    status: 200,
    description: 'Battery found',
  })
  @ApiResponse({
    status: 404,
    description: 'Battery not found',
  })
  async findOne(@Param('id') id: string) {
    return this.batteriesService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create new battery listing',
    description: 'Create a new battery listing for sale',
  })
  @ApiBody({ type: CreateBatteryDto })
  @ApiResponse({
    status: 201,
    description: 'Battery created successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async create(
    @Body(ValidationPipe) createBatteryDto: CreateBatteryDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.batteriesService.create(createBatteryDto, requireSellerId(req));
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update battery',
    description: 'Update an existing battery listing',
  })
  @ApiParam({ name: 'id', description: 'Battery ID' })
  @ApiBody({ type: UpdateBatteryDto })
  @ApiResponse({
    status: 200,
    description: 'Battery updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Battery not found',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Not the owner',
  })
  async update(
    @Param('id') id: string,
    @Body(ValidationPipe) updateBatteryDto: UpdateBatteryDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.batteriesService.update(
      id,
      updateBatteryDto,
      requireSellerId(req),
    );
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete battery',
    description: 'Delete a battery listing',
  })
  @ApiParam({ name: 'id', description: 'Battery ID' })
  @ApiResponse({
    status: 200,
    description: 'Battery deleted successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Battery not found',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Not the owner',
  })
  async remove(@Param('id') id: string, @Req() req: AuthenticatedRequest) {
    return this.batteriesService.remove(id, requireSellerId(req));
  }
}
