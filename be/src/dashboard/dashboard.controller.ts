import {
  Controller,
  Get,
  Delete,
  Post,
  Body,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  DashboardService,
  DashboardOverview,
  DashboardFavorite,
  DashboardOrder,
} from './dashboard.service';
import { AddFavoriteDto } from './dto/add-favorite.dto';

interface AuthenticatedUser {
  id?: string;
  sub?: string;
}

interface AuthenticatedRequest extends Request {
  user?: AuthenticatedUser;
}

@ApiTags('Dashboard')
@Controller('dashboard')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  private extractUserId(request: AuthenticatedRequest): string {
    const userId = request.user?.id ?? request.user?.sub;

    if (!userId) {
      throw new Error('Không xác định được người dùng');
    }

    return userId;
  }

  @Get('overview')
  @ApiOperation({
    summary: 'Tổng quan dashboard',
    description: 'Lấy tổng quan các chỉ số hoạt động của người dùng',
  })
  async getOverview(
    @Req() request: AuthenticatedRequest,
  ): Promise<DashboardOverview> {
    const userId = this.extractUserId(request);
    return this.dashboardService.getOverview(userId);
  }

  @Get('orders')
  @ApiOperation({
    summary: 'Danh sách đơn hàng',
    description: 'Lấy danh sách đơn hàng của người dùng theo thời gian',
  })
  async getOrders(
    @Req() request: AuthenticatedRequest,
  ): Promise<{ orders: DashboardOrder[] }> {
    const userId = this.extractUserId(request);
    return this.dashboardService.getOrders(userId);
  }

  @Get('favorites')
  @ApiOperation({
    summary: 'Danh sách yêu thích',
    description: 'Lấy danh sách sản phẩm yêu thích của người dùng',
  })
  async getFavorites(
    @Req() request: AuthenticatedRequest,
  ): Promise<{ favorites: DashboardFavorite[] }> {
    const userId = this.extractUserId(request);
    return this.dashboardService.getFavorites(userId);
  }

  @Post('favorites')
  @ApiOperation({
    summary: 'Thêm sản phẩm yêu thích',
    description: 'Thêm một sản phẩm vào danh sách yêu thích của người dùng',
  })
  async addFavorite(
    @Req() request: AuthenticatedRequest,
    @Body() payload: AddFavoriteDto,
  ): Promise<{ favorite: DashboardFavorite }> {
    const userId = this.extractUserId(request);
    const favorite = await this.dashboardService.addFavorite(userId, payload);
    return { favorite };
  }

  @Delete('favorites/:id')
  @ApiOperation({
    summary: 'Xóa mục yêu thích',
    description: 'Xóa một mục khỏi danh sách yêu thích của người dùng',
  })
  @ApiParam({ name: 'id', description: 'ID của mục yêu thích' })
  async removeFavorite(
    @Req() request: AuthenticatedRequest,
    @Param('id') favoriteId: string,
  ) {
    const userId = this.extractUserId(request);
    return this.dashboardService.removeFavorite(userId, favoriteId);
  }
}
