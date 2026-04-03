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
import { ComparisonsService } from './comparisons.service';
import { CreateComparisonDto, UpdateComparisonDto } from './dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';

@ApiTags('comparisons')
@Controller('comparisons')
export class ComparisonsController {
  constructor(private readonly comparisonsService: ComparisonsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new comparison' })
  @ApiResponse({
    status: 201,
    description: 'Comparison has been successfully created',
  })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  create(@Body() createComparisonDto: CreateComparisonDto) {
    return this.comparisonsService.create(createComparisonDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all comparisons with pagination' })
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
  @ApiResponse({ status: 200, description: 'Return all comparisons' })
  findAll(
    @Query('page', new ParseIntPipe({ optional: true })) page?: number,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.comparisonsService.findAll(page || 1, limit || 10);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a comparison by ID' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiResponse({ status: 200, description: 'Return the comparison' })
  @ApiResponse({ status: 404, description: 'Comparison not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.comparisonsService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a comparison' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiResponse({ status: 200, description: 'Comparison has been updated' })
  @ApiResponse({ status: 404, description: 'Comparison not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateComparisonDto: UpdateComparisonDto,
  ) {
    return this.comparisonsService.update(id, updateComparisonDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a comparison' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiResponse({ status: 200, description: 'Comparison has been deleted' })
  @ApiResponse({ status: 404, description: 'Comparison not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.comparisonsService.remove(id);
  }

  @Post(':id/vehicles/:vehicleId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Add a vehicle to a comparison' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({ status: 200, description: 'Vehicle added to the comparison' })
  @ApiResponse({ status: 404, description: 'Comparison or vehicle not found' })
  addVehicle(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
  ) {
    return this.comparisonsService.addVehicleToComparison(id, vehicleId);
  }

  @Delete(':id/vehicles/:vehicleId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove a vehicle from a comparison' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiParam({ name: 'vehicleId', description: 'Vehicle ID' })
  @ApiResponse({
    status: 200,
    description: 'Vehicle removed from the comparison',
  })
  @ApiResponse({ status: 404, description: 'Comparison or vehicle not found' })
  removeVehicle(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
  ) {
    return this.comparisonsService.removeVehicleFromComparison(id, vehicleId);
  }

  @Post(':id/batteries/:batteryId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Add a battery to a comparison' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiParam({ name: 'batteryId', description: 'Battery ID' })
  @ApiResponse({ status: 200, description: 'Battery added to the comparison' })
  @ApiResponse({ status: 404, description: 'Comparison or battery not found' })
  addBattery(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('batteryId', ParseUUIDPipe) batteryId: string,
  ) {
    return this.comparisonsService.addBatteryToComparison(id, batteryId);
  }

  @Delete(':id/batteries/:batteryId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove a battery from a comparison' })
  @ApiParam({ name: 'id', description: 'Comparison ID' })
  @ApiParam({ name: 'batteryId', description: 'Battery ID' })
  @ApiResponse({
    status: 200,
    description: 'Battery removed from the comparison',
  })
  @ApiResponse({ status: 404, description: 'Comparison or battery not found' })
  removeBattery(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('batteryId', ParseUUIDPipe) batteryId: string,
  ) {
    return this.comparisonsService.removeBatteryFromComparison(id, batteryId);
  }
}
