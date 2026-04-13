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
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiQuery,
  ApiBody,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AccessoriesService } from './accessories.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  CreateAccessoryDto,
  UpdateAccessoryDto,
  SearchAccessoryDto,
} from './dto';

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

@ApiTags('Accessories')
@Controller('accessories')
export class AccessoriesController {
  constructor(private readonly accessoriesService: AccessoriesService) {}

  @Get()
  @ApiOperation({
    summary: 'Search accessories',
    description: 'Search and filter accessories with pagination',
  })
  @ApiResponse({
    status: 200,
    description: 'Accessories retrieved successfully',
  })
  async findAll(@Query(ValidationPipe) query: SearchAccessoryDto) {
    return this.accessoriesService.findAll(query);
  }

  @Get('my-accessories')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get my accessory listings',
    description: 'Get current user accessory listings',
  })
  async getMyAccessories(
    @Req() req: AuthenticatedRequest,
    @Query(ValidationPipe) query: SearchAccessoryDto,
  ) {
    return this.accessoriesService.findByUser(requireSellerId(req), query);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get accessory by ID',
    description: 'Retrieve detailed information about a specific accessory',
  })
  @ApiParam({ name: 'id', description: 'Accessory ID' })
  @ApiResponse({ status: 200, description: 'Accessory found' })
  @ApiResponse({ status: 404, description: 'Accessory not found' })
  async findOne(@Param('id') id: string) {
    return this.accessoriesService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create new accessory listing',
    description: 'Create a new accessory listing for sale',
  })
  @ApiBody({ type: CreateAccessoryDto })
  @ApiResponse({ status: 201, description: 'Accessory created successfully' })
  async create(
    @Body(ValidationPipe) createAccessoryDto: CreateAccessoryDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.accessoriesService.create(
      createAccessoryDto,
      requireSellerId(req),
    );
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update accessory',
    description: 'Update an existing accessory listing',
  })
  @ApiParam({ name: 'id', description: 'Accessory ID' })
  @ApiBody({ type: UpdateAccessoryDto })
  @ApiResponse({ status: 200, description: 'Accessory updated successfully' })
  @ApiResponse({ status: 404, description: 'Accessory not found' })
  @ApiResponse({ status: 403, description: 'Forbidden - Not the owner' })
  async update(
    @Param('id') id: string,
    @Body(ValidationPipe) updateAccessoryDto: UpdateAccessoryDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.accessoriesService.update(
      id,
      updateAccessoryDto,
      requireSellerId(req),
    );
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete accessory',
    description: 'Delete an accessory listing',
  })
  @ApiParam({ name: 'id', description: 'Accessory ID' })
  @ApiResponse({ status: 200, description: 'Accessory deleted successfully' })
  @ApiResponse({ status: 404, description: 'Accessory not found' })
  @ApiResponse({ status: 403, description: 'Forbidden - Not the owner' })
  async remove(@Param('id') id: string, @Req() req: AuthenticatedRequest) {
    return this.accessoriesService.remove(id, requireSellerId(req));
  }
}
