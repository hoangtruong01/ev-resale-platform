import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  Req,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiQuery,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

interface AuthenticatedRequest extends Request {
  user?: {
    id?: string;
    sub: string;
    email: string;
    role: string;
  };
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

@ApiTags('Vehicles')
@Controller('vehicles')
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new vehicle' })
  @ApiResponse({ status: 201, description: 'Vehicle created successfully' })
  create(
    @Body() createVehicleDto: CreateVehicleDto,
    @Req() req: AuthenticatedRequest,
  ) {
    const sellerId =
      req.user?.id ??
      req.user?.sub ??
      (req.headers['x-user-id'] as string | undefined);
    return this.vehiclesService.create(createVehicleDto, sellerId);
  }

  @Get()
  @ApiOperation({ summary: 'Get all vehicles with filters' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'brand', required: false, type: String })
  @ApiQuery({ name: 'minPrice', required: false, type: Number })
  @ApiQuery({ name: 'maxPrice', required: false, type: Number })
  @ApiQuery({ name: 'year', required: false, type: Number })
  @ApiQuery({ name: 'location', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Vehicles retrieved successfully' })
  findAll(
    @Query('page') page?: number | string,
    @Query('limit') limit?: number | string,
    @Query('brand') brand?: string,
    @Query('minPrice') minPrice?: number | string,
    @Query('maxPrice') maxPrice?: number | string,
    @Query('year') year?: number | string,
    @Query('location') location?: string,
    @Query('approvalStatus') approvalStatus?: string,
  ) {
    const parseNumber = (value?: string | number | null) => {
      if (value === undefined || value === null || value === '') {
        return undefined;
      }

      const numeric = Number(value);
      return Number.isFinite(numeric) ? numeric : undefined;
    };

    const safePage = parseNumber(page) ?? 1;
    const safeLimit = parseNumber(limit) ?? 10;

    return this.vehiclesService.findAll({
      page: safePage,
      limit: safeLimit,
      brand,
      minPrice: parseNumber(minPrice),
      maxPrice: parseNumber(maxPrice),
      year: parseNumber(year),
      location,
      approvalStatus,
    });
  }

  @Get('my-vehicles')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get my vehicle listings',
    description: 'Retrieve the authenticated user vehicle listings',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'sortBy', required: false, type: String })
  @ApiQuery({
    name: 'sortOrder',
    required: false,
    enum: ['asc', 'desc'],
  })
  async getMyVehicles(
    @Req() req: AuthenticatedRequest,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('sortBy') sortBy?: string,
    @Query('sortOrder') sortOrder?: string,
  ) {
    const parseNumber = (value?: string) => {
      if (!value) {
        return undefined;
      }

      const numeric = Number(value);
      return Number.isFinite(numeric) ? numeric : undefined;
    };

    const normalizedSortOrder = sortOrder === 'asc' ? 'asc' : 'desc';

    return this.vehiclesService.findByUser(requireSellerId(req), {
      page: parseNumber(page),
      limit: parseNumber(limit),
      sortBy,
      sortOrder: normalizedSortOrder,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get vehicle by ID' })
  @ApiResponse({ status: 200, description: 'Vehicle retrieved successfully' })
  @ApiResponse({ status: 404, description: 'Vehicle not found' })
  findOne(@Param('id') id: string) {
    return this.vehiclesService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update vehicle' })
  @ApiResponse({ status: 200, description: 'Vehicle updated successfully' })
  @ApiResponse({ status: 404, description: 'Vehicle not found' })
  update(@Param('id') id: string, @Body() updateVehicleDto: UpdateVehicleDto) {
    return this.vehiclesService.update(id, updateVehicleDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete vehicle' })
  @ApiResponse({ status: 200, description: 'Vehicle deleted successfully' })
  @ApiResponse({ status: 404, description: 'Vehicle not found' })
  remove(@Param('id') id: string) {
    return this.vehiclesService.remove(id);
  }
}
