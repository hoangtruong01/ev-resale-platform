import {
  Controller,
  ForbiddenException,
  Get,
  Put,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  ValidationPipe,
  Req,
  UnauthorizedException,
  Res,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
  ApiParam,
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import type { Response, Request } from 'express';
import { UsersService } from '../users/users.service';
import { BatteriesService } from '../batteries/batteries.service';
import { AccessoriesService } from '../accessories/accessories.service';
import { AuctionsService } from '../auctions/auctions.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { TransactionsService } from '../transactions/transactions.service';
import { SupportTicketsService } from '../support-tickets/support-tickets.service';
import { ResolveTransactionDisputeDto } from '../transactions/dto';
import { SupportTicketStatus } from '@prisma/client';
import { UserRole } from '@prisma/client';
import {
  AdminAnalyticsService,
  AdminAnalyticsPeriod,
  AdminAnalyticsResponse,
} from './admin-analytics.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { Permissions } from '../auth/permissions.decorator';
import { PermissionsGuard } from '../auth/permissions.guard';
import {
  MODERATOR_PERMISSIONS,
  normalizePermissions,
} from '../auth/permissions';
import { UpdateSupportTicketStatusDto } from '../support-tickets/dto';
import { SettingsService } from '../settings/settings.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';

interface AdminRequest extends Request {
  user?: {
    sub: string;
    email: string;
    role: string;
    moderatorPermissions?: string[];
  };
}

@ApiTags('Admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth('JWT-auth')
export class AdminController {
  constructor(
    private readonly usersService: UsersService,
    private readonly batteriesService: BatteriesService,
    private readonly accessoriesService: AccessoriesService,
    private readonly auctionsService: AuctionsService,
    private readonly vehiclesService: VehiclesService,
    private readonly transactionsService: TransactionsService,
    private readonly analyticsService: AdminAnalyticsService,
    private readonly supportTicketsService: SupportTicketsService,
    private readonly settingsService: SettingsService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  // Dashboard Statistics
  @Get('dashboard')
  @ApiOperation({
    summary: 'Get admin dashboard statistics',
    description: 'Get overall platform statistics for admin dashboard',
  })
  async getDashboardStats() {
    const [userStats, batteryStats, auctionStats] = await Promise.all([
      this.usersService.getStatistics(),
      this.batteriesService.getStatistics(),
      this.auctionsService.getStatistics(),
    ]);

    return {
      users: userStats,
      batteries: batteryStats,
      auctions: auctionStats,
    };
  }

  @Get('support-tickets')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('HANDLE_SUPPORT_TICKETS')
  @ApiOperation({
    summary: 'Get support tickets (Admin)',
    description: 'Get paginated list of support tickets with filters',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, enum: SupportTicketStatus })
  @ApiQuery({ name: 'search', required: false, type: String })
  async listSupportTickets(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: SupportTicketStatus,
    @Query('search') search?: string,
  ) {
    const toNumber = (value?: string) => {
      if (!value) return undefined;
      const numeric = Number(value);
      return Number.isFinite(numeric) ? numeric : undefined;
    };

    return this.supportTicketsService.findAll({
      page: toNumber(page),
      limit: toNumber(limit),
      status,
      search,
    });
  }

  @Patch('support-tickets/:id')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('HANDLE_SUPPORT_TICKETS')
  @ApiOperation({
    summary: 'Update support ticket status (Admin)',
    description: 'Update the status of a support ticket',
  })
  @ApiParam({ name: 'id', description: 'Support ticket ID' })
  @ApiBody({ type: UpdateSupportTicketStatusDto })
  async updateSupportTicketStatus(
    @Param('id') id: string,
    @Body(ValidationPipe) payload: UpdateSupportTicketStatusDto,
    @Req() req: AdminRequest,
  ) {
    const actorId = req.user?.sub;
    const result = await this.supportTicketsService.updateStatus(
      id,
      payload.status,
    );

    if (actorId) {
      await this.auditLogsService.log({
        actorId,
        actorRole: req.user?.role,
        action: 'HANDLE_SUPPORT_TICKET',
        targetType: 'SUPPORT_TICKET',
        targetId: id,
        metadata: {
          status: payload.status,
        },
      });
    }

    return result;
  }

  @Get('moderators/:id/permissions')
  @ApiOperation({ summary: 'Get moderator permissions' })
  async getModeratorPermissions(@Param('id') id: string) {
    const user = await this.usersService.getModeratorPermissionProfile(id);
    if (user.role !== UserRole.MODERATOR) {
      throw new ForbiddenException('Người dùng không phải moderator.');
    }

    return {
      moderator: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
      availablePermissions: MODERATOR_PERMISSIONS,
      permissions: user.moderatorPermissions,
    };
  }

  @Put('moderators/:id/permissions')
  @ApiOperation({ summary: 'Update moderator permissions' })
  async updateModeratorPermissions(
    @Param('id') id: string,
    @Body() body: { permissions?: string[] },
    @Req() req: AdminRequest,
  ) {
    const actorId = req.user?.sub;
    if (!actorId) {
      throw new UnauthorizedException('Thiếu thông tin quản trị viên');
    }

    const normalized = normalizePermissions(body.permissions);
    const updated = await this.usersService.updateModeratorPermissions(
      id,
      normalized,
    );

    await this.auditLogsService.log({
      actorId,
      actorRole: req.user?.role,
      action: 'UPDATE_MODERATOR_PERMISSIONS',
      targetType: 'USER',
      targetId: id,
      metadata: {
        permissions: normalized,
      },
    });

    return {
      moderator: {
        id: updated.id,
        email: updated.email,
        fullName: updated.fullName,
        role: updated.role,
      },
      availablePermissions: MODERATOR_PERMISSIONS,
      permissions: updated.moderatorPermissions,
    };
  }

  @Get('analytics')
  @ApiOperation({ summary: 'Thống kê và báo cáo tổng quan' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['7d', '30d', '3m', '6m', '1y'],
  })
  async getAdminAnalytics(
    @Query('period') period?: string,
  ): Promise<AdminAnalyticsResponse> {
    const normalized = this.normalizeAnalyticsPeriod(period);
    return this.analyticsService.getAnalytics(normalized);
  }

  @Get('analytics/export')
  @ApiOperation({ summary: 'Xuất báo cáo thống kê (CSV)' })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['7d', '30d', '3m', '6m', '1y'],
  })
  async exportAdminAnalytics(
    @Query('period') period: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const normalized = this.normalizeAnalyticsPeriod(period);
    const { filename, content } =
      await this.analyticsService.exportAnalytics(normalized);

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    return content;
  }

  // User Management
  @Get('users')
  @ApiOperation({
    summary: 'Get all users (Admin)',
    description: 'Get paginated list of all users with admin filters',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({
    name: 'role',
    required: false,
    enum: ['USER', 'ADMIN', 'MODERATOR'],
  })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  async getUsers(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
    @Query('role') role?: string,
    @Query('isActive') isActive?: boolean,
  ) {
    const result = await this.usersService.findAll({
      page,
      limit,
      search,
      role,
      isActive,
    });

    // Transform data for frontend
    const users = result.data.map((user) => ({
      id: user.id,
      name: user.fullName || user.name,
      email: user.email,
      phone: user.phone || '',
      avatar: user.avatar || '',
      role: user.role,
      status: user.isActive ? 'active' : 'blocked',
      createdAt: user.createdAt,
      lastActive: user.updatedAt,
      address: user.address || '',
      postCount: (user._count?.batteries || 0) + (user._count?.vehicles || 0),
      transactionCount: user._count?.auctions || 0,
      averageRating: user.rating || 0,
    }));

    return {
      users,
      pagination: result.pagination,
    };
  }

  @Get('users/all')
  @ApiOperation({
    summary: 'Get all users (Simple)',
    description: 'Get all users without pagination for admin',
  })
  async getAllUsers() {
    const result = await this.usersService.findAll({ page: 1, limit: 1000 });

    // Transform data for frontend
    const users = result.data.map((user) => ({
      id: user.id,
      name: user.fullName || user.name,
      email: user.email,
      phone: user.phone || '',
      avatar: user.avatar || '',
      role: user.role,
      status: user.isActive ? 'active' : 'blocked',
      createdAt: user.createdAt,
      lastActive: user.updatedAt,
      address: user.address || '',
      postCount: (user._count?.batteries || 0) + (user._count?.vehicles || 0),
      transactionCount: user._count?.auctions || 0,
      averageRating: user.rating || 0,
    }));

    return users;
  }

  @Put('users/:id/approve')
  @ApiOperation({
    summary: 'Approve user',
    description: 'Approve a pending user account',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  async approveUser(@Param('id') id: string) {
    return this.usersService.update(id, { isActive: true });
  }

  @Put('users/:id/block')
  @ApiOperation({
    summary: 'Block user',
    description: 'Block a user account',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  async blockUser(@Param('id') id: string) {
    return this.usersService.update(id, { isActive: false });
  }

  @Put('users/:id/unblock')
  @ApiOperation({
    summary: 'Unblock user',
    description: 'Unblock a user account',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  async unblockUser(@Param('id') id: string) {
    return this.usersService.update(id, { isActive: true });
  }

  @Put('users/:id/activate')
  @ApiOperation({
    summary: 'Activate/Deactivate user',
    description: 'Toggle user active status',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        isActive: { type: 'boolean' },
      },
    },
  })
  async toggleUserStatus(
    @Param('id') id: string,
    @Body() body: { isActive: boolean },
  ) {
    return this.usersService.update(id, { isActive: body.isActive });
  }

  @Put('users/:id/role')
  @ApiOperation({
    summary: 'Update user role',
    description: 'Change user role (USER, ADMIN, MODERATOR)',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        role: { type: 'string', enum: ['USER', 'ADMIN', 'MODERATOR'] },
      },
    },
  })
  async updateUserRole(
    @Param('id') id: string,
    @Body() body: { role: 'USER' | 'ADMIN' | 'MODERATOR' },
    @Req() req: AdminRequest,
  ) {
    const actorId = req.user?.sub;
    if (!actorId) {
      throw new UnauthorizedException('Thiếu thông tin quản trị viên');
    }

    const before = await this.usersService.getModeratorPermissionProfile(id);
    const updated = await this.usersService.update(id, { role: body.role });

    await this.auditLogsService.log({
      actorId,
      actorRole: req.user?.role,
      action: 'UPDATE_USER_ROLE',
      targetType: 'USER',
      targetId: id,
      metadata: {
        fromRole: before.role,
        toRole: body.role,
      },
    });

    return updated;
  }

  @Delete('users/:id')
  @ApiOperation({
    summary: 'Delete user',
    description: 'Permanently delete a user account',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  async deleteUser(@Param('id') id: string) {
    return this.usersService.remove(id);
  }

  // Battery Listing Management
  @Get('batteries')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Get all battery listings (Admin)',
    description: 'Get all battery listings with admin filters',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['AVAILABLE', 'SOLD', 'AUCTION', 'RESERVED'],
  })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  async getBatteries(@Query(ValidationPipe) query: any) {
    return this.batteriesService.findAll(query, { includeAllStatuses: true });
  }

  @Put('batteries/:id/approve')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Approve battery listing',
    description: 'Approve a battery listing for public display',
  })
  @ApiParam({ name: 'id', description: 'Battery ID' })
  async approveBattery(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { notes?: string } = {},
  ) {
    return this.batteriesService.approve(id, req.user?.sub, body.notes);
  }

  @Put('batteries/:id/reject')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Reject battery listing',
    description: 'Reject a battery listing and hide from public',
  })
  @ApiParam({ name: 'id', description: 'Battery ID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        reason: { type: 'string' },
      },
    },
  })
  async rejectBattery(
    @Param('id') id: string,
    @Body() body: { reason: string },
    @Req() req: AdminRequest,
  ) {
    return this.batteriesService.reject(id, req.user?.sub, body.reason);
  }

  @Put('batteries/:id/spam')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MARK_SPAM')
  @ApiOperation({
    summary: 'Mark battery listing as spam',
    description: 'Flag a battery listing as spam and hide it',
  })
  async markBatterySpam(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { reason?: string } = {},
  ) {
    return this.batteriesService.markSpam(id, req.user?.sub, body.reason);
  }

  @Put('batteries/:id/verify')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({ summary: 'Verify battery listing' })
  async verifyBattery(@Param('id') id: string, @Req() req: AdminRequest) {
    return this.batteriesService.verify(id, req.user?.sub);
  }

  @Put('batteries/:id/unverify')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({ summary: 'Remove verification from battery listing' })
  async unverifyBattery(@Param('id') id: string, @Req() req: AdminRequest) {
    return this.batteriesService.unverify(id, req.user?.sub);
  }

  @Get('accessories')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Get all accessory listings (Admin)',
    description: 'Get all accessory listings with admin filters',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'category', required: false, type: String })
  @ApiQuery({ name: 'location', required: false, type: String })
  @ApiQuery({ name: 'approvalStatus', required: false, type: String })
  async getAccessories(@Query(ValidationPipe) query: any) {
    return this.accessoriesService.findAll(query, { includeAllStatuses: true });
  }

  @Put('accessories/:id/approve')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Approve accessory listing',
    description: 'Approve an accessory listing for public display',
  })
  async approveAccessory(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { notes?: string } = {},
  ) {
    return this.accessoriesService.approve(id, req.user?.sub, body.notes);
  }

  @Put('accessories/:id/reject')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Reject accessory listing',
    description: 'Reject an accessory listing and hide from public',
  })
  async rejectAccessory(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { reason?: string } = {},
  ) {
    return this.accessoriesService.reject(id, req.user?.sub, body.reason);
  }

  @Put('accessories/:id/spam')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MARK_SPAM')
  @ApiOperation({
    summary: 'Mark accessory listing as spam',
    description: 'Flag an accessory listing as spam and hide it',
  })
  async markAccessorySpam(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { reason?: string } = {},
  ) {
    return this.accessoriesService.markSpam(id, req.user?.sub, body.reason);
  }

  @Put('accessories/:id/verify')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({ summary: 'Verify accessory listing' })
  async verifyAccessory(@Param('id') id: string, @Req() req: AdminRequest) {
    return this.accessoriesService.verify(id, req.user?.sub);
  }

  @Put('accessories/:id/unverify')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({ summary: 'Remove verification from accessory listing' })
  async unverifyAccessory(@Param('id') id: string, @Req() req: AdminRequest) {
    return this.accessoriesService.unverify(id, req.user?.sub);
  }

  @Get('vehicles')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Get all vehicle listings (Admin)',
    description: 'Get all vehicle listings with admin filters',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'brand', required: false, type: String })
  @ApiQuery({ name: 'minPrice', required: false, type: Number })
  @ApiQuery({ name: 'maxPrice', required: false, type: Number })
  @ApiQuery({ name: 'year', required: false, type: Number })
  @ApiQuery({ name: 'location', required: false, type: String })
  @ApiQuery({ name: 'approvalStatus', required: false, type: String })
  async getVehicles(@Query() query: any) {
    const page = query.page ? Number(query.page) : 1;
    const limit = query.limit ? Number(query.limit) : 10;

    return this.vehiclesService.findAll(
      {
        page,
        limit,
        brand: query.brand,
        minPrice:
          query.minPrice !== undefined ? Number(query.minPrice) : undefined,
        maxPrice:
          query.maxPrice !== undefined ? Number(query.maxPrice) : undefined,
        year: query.year !== undefined ? Number(query.year) : undefined,
        location: query.location,
        approvalStatus: query.approvalStatus,
      },
      { includeAllStatuses: true },
    );
  }

  @Get('listings')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Get combined listings',
    description:
      'Retrieve both vehicle and battery listings for moderation workflows',
  })
  async getCombinedListings(@Query() query: any) {
    const page = query.page ? Math.max(Number(query.page), 1) : 1;
    const limit = query.limit ? Math.max(Number(query.limit), 1) : 20;
    const approvalStatus = query.approvalStatus as string | undefined;
    const fetchLimit = limit * page;

    const [vehicles, batteries, accessories] = await Promise.all([
      this.vehiclesService.findAll(
        {
          page: 1,
          limit: fetchLimit,
          brand: query.brand,
          minPrice:
            query.minPrice !== undefined ? Number(query.minPrice) : undefined,
          maxPrice:
            query.maxPrice !== undefined ? Number(query.maxPrice) : undefined,
          year: query.year !== undefined ? Number(query.year) : undefined,
          location: query.location,
          approvalStatus,
        },
        { includeAllStatuses: true },
      ),
      this.batteriesService.findAll(
        {
          search: query.search,
          status: query.status,
          location: query.location,
          page: 1,
          limit: fetchLimit,
          approvalStatus,
        },
        { includeAllStatuses: true },
      ),
      this.accessoriesService.findAll(
        {
          search: query.search,
          status: query.status,
          location: query.location,
          page: 1,
          limit: fetchLimit,
          approvalStatus,
        },
        { includeAllStatuses: true },
      ),
    ]);

    const mapped = [
      ...vehicles.data.map((vehicle: any) => ({
        id: vehicle.id,
        type: 'vehicle' as const,
        title: vehicle.name,
        description: vehicle.description,
        price: Number(vehicle.price ?? 0),
        approvalStatus: vehicle.approvalStatus ?? 'PENDING',
        status: vehicle.status,
        location: vehicle.location,
        createdAt: vehicle.createdAt,
        seller: vehicle.seller,
        images: vehicle.images ?? [],
        isVerified: vehicle.isVerified ?? false,
        spamScore: vehicle.spamScore ?? 0,
        spamReasons: vehicle.spamReasons ?? [],
        isSpamSuspicious: vehicle.isSpamSuspicious ?? false,
      })),
      ...batteries.data.map((battery: any) => ({
        id: battery.id,
        type: 'battery' as const,
        title: battery.name,
        description: battery.description,
        price: Number(battery.price ?? 0),
        approvalStatus: battery.approvalStatus ?? 'PENDING',
        status: battery.status,
        location: battery.location,
        createdAt: battery.createdAt,
        seller: battery.seller,
        images: battery.images ?? [],
        isVerified: battery.isVerified ?? false,
        spamScore: battery.spamScore ?? 0,
        spamReasons: battery.spamReasons ?? [],
        isSpamSuspicious: battery.isSpamSuspicious ?? false,
      })),
      ...accessories.data.map((accessory: any) => ({
        id: accessory.id,
        type: 'accessory' as const,
        title: accessory.name,
        description: accessory.description,
        price: Number(accessory.price ?? 0),
        category: accessory.category,
        approvalStatus: accessory.approvalStatus ?? 'PENDING',
        status: accessory.status,
        location: accessory.location,
        createdAt: accessory.createdAt,
        seller: accessory.seller,
        images: accessory.images ?? [],
        isVerified: accessory.isVerified ?? false,
        spamScore: accessory.spamScore ?? 0,
        spamReasons: accessory.spamReasons ?? [],
        isSpamSuspicious: accessory.isSpamSuspicious ?? false,
      })),
    ].sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );

    const start = (page - 1) * limit;
    const paginated = mapped.slice(start, start + limit);

    const counts = mapped.reduce(
      (acc, item) => {
        const key = (item.approvalStatus || 'PENDING').toLowerCase();
        acc[key] = (acc[key] || 0) + 1;
        return acc;
      },
      { pending: 0, approved: 0, rejected: 0 } as Record<string, number>,
    );

    return {
      data: paginated,
      pagination: {
        total: mapped.length,
        page,
        limit,
        totalPages: Math.ceil(mapped.length / limit) || 1,
      },
      counts,
    };
  }

  @Put('vehicles/:id/approve')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Approve vehicle listing',
    description: 'Approve a vehicle listing for public display',
  })
  async approveVehicle(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { notes?: string } = {},
  ) {
    return this.vehiclesService.approve(id, req.user?.sub, body.notes);
  }

  @Put('vehicles/:id/reject')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Reject vehicle listing',
    description: 'Reject a vehicle listing and hide from public',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        reason: { type: 'string' },
      },
    },
  })
  async rejectVehicle(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { reason: string },
  ) {
    return this.vehiclesService.reject(id, req.user?.sub, body.reason);
  }

  @Put('vehicles/:id/spam')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MARK_SPAM')
  @ApiOperation({ summary: 'Mark vehicle listing as spam' })
  async markVehicleSpam(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { reason?: string } = {},
  ) {
    return this.vehiclesService.markSpam(id, req.user?.sub, body.reason);
  }

  @Put('vehicles/:id/verify')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({ summary: 'Verify vehicle listing' })
  async verifyVehicle(@Param('id') id: string, @Req() req: AdminRequest) {
    return this.vehiclesService.verify(id, req.user?.sub);
  }

  @Put('vehicles/:id/unverify')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({ summary: 'Remove verification from vehicle listing' })
  async unverifyVehicle(@Param('id') id: string, @Req() req: AdminRequest) {
    return this.vehiclesService.unverify(id, req.user?.sub);
  }

  // Auction Management
  @Get('auctions')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Get all auctions (Admin)',
    description: 'Get all auctions with admin filters',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['PENDING', 'ACTIVE', 'ENDED', 'CANCELLED'],
  })
  async getAuctions(@Query(ValidationPipe) query: any) {
    return this.auctionsService.findAll(query, { includeAllStatuses: true });
  }

  @Put('auctions/:id/approve')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Approve auction',
    description: 'Approve an auction for activation',
  })
  async approveAuction(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { notes?: string } = {},
  ) {
    return this.auctionsService.approve(id, req.user?.sub, body.notes);
  }

  @Put('auctions/:id/reject')
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  @ApiOperation({
    summary: 'Reject auction',
    description: 'Reject an auction and release associated items',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        reason: { type: 'string' },
      },
    },
  })
  async rejectAuction(
    @Param('id') id: string,
    @Req() req: AdminRequest,
    @Body() body: { reason: string },
  ) {
    return this.auctionsService.reject(id, req.user?.sub, body.reason);
  }

  @Put('auctions/:id/end')
  @ApiOperation({
    summary: 'Force end auction',
    description: 'Manually end an active auction',
  })
  @ApiParam({ name: 'id', description: 'Auction ID' })
  async forceEndAuction(@Param('id') id: string) {
    return this.auctionsService.endAuction(id, undefined, true);
  }

  // Review Management
  @Get('reviews')
  @ApiOperation({
    summary: 'Get all reviews (Admin)',
    description: 'Get all reviews for moderation',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'rating', required: false, type: Number })
  async getReviews(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('rating') rating?: number,
  ) {
    // This would be implemented in a ReviewsService
    return {
      data: [],
      pagination: {
        total: 0,
        page: page || 1,
        limit: limit || 10,
        totalPages: 0,
      },
    };
  }

  @Put('reviews/:id/hide')
  @ApiOperation({
    summary: 'Hide review',
    description: 'Hide inappropriate review from public display',
  })
  @ApiParam({ name: 'id', description: 'Review ID' })
  async hideReview(@Param('id') id: string) {
    return { message: 'Review hidden', id };
  }

  // Platform Settings
  @Get('settings')
  @ApiOperation({
    summary: 'Get platform settings',
    description: 'Get all platform configuration settings',
  })
  async getSettings() {
    return this.settingsService.findAll();
  }

  @Put('settings')
  @ApiOperation({
    summary: 'Update platform settings',
    description: 'Update platform configuration settings',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        commissionRate: { type: 'number' },
        maxAuctionDuration: { type: 'number' },
        minBidIncrement: { type: 'number' },
        autoEndAuctions: { type: 'boolean' },
      },
    },
  })
  async updateSettings(
    @Body() settings: Record<string, unknown>,
    @Req() req: AdminRequest,
  ) {
    const actorId = req.user?.sub;
    if (!actorId) {
      throw new UnauthorizedException('Thiếu thông tin quản trị viên');
    }

    const entries = Object.entries(settings ?? {});
    const inferSettingType = (
      value: unknown,
    ): 'string' | 'number' | 'boolean' | 'json' => {
      if (typeof value === 'string') {
        return 'string';
      }
      if (typeof value === 'number') {
        return 'number';
      }
      if (typeof value === 'boolean') {
        return 'boolean';
      }
      return 'json';
    };

    const updated = await Promise.all(
      entries.map(async ([key, value]) => {
        const serializedValue =
          typeof value === 'string' ? value : JSON.stringify(value);
        try {
          return await this.settingsService.update(key, {
            value: serializedValue,
          });
        } catch {
          return this.settingsService.create({
            key,
            value: serializedValue,
            type: inferSettingType(value),
          });
        }
      }),
    );

    await this.auditLogsService.log({
      actorId,
      actorRole: req.user?.role,
      action: 'UPDATE_SYSTEM_SETTINGS',
      targetType: 'SETTINGS',
      metadata: {
        keys: entries.map(([key]) => key),
      },
    });

    return {
      message: 'Settings updated',
      count: updated.length,
      settings: updated,
    };
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Danh sách giao dịch cho admin' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: [
      'all',
      'pending',
      'processing',
      'completed',
      'cancelled',
      'disputed',
    ],
  })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: ['all', 'sale', 'auction'],
  })
  @ApiQuery({ name: 'search', required: false, type: String })
  async getAdminTransactions(@Query() query: any): Promise<unknown> {
    const page = query.page ? Number(query.page) : undefined;
    const limit = query.limit ? Number(query.limit) : undefined;
    const status = query.status as
      | 'all'
      | 'pending'
      | 'processing'
      | 'completed'
      | 'cancelled'
      | 'disputed'
      | undefined;
    const type = query.type as 'all' | 'sale' | 'auction' | undefined;
    const search = query.search as string | undefined;

    return this.transactionsService.getAdminTransactions({
      page,
      limit,
      status,
      type,
      search,
    });
  }

  @Get('transactions/:id')
  @ApiOperation({ summary: 'Chi tiết giao dịch admin' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  async getAdminTransaction(@Param('id') id: string): Promise<unknown> {
    return this.transactionsService.getAdminTransactionById(id);
  }

  @Post('transactions/:id/process')
  @ApiOperation({ summary: 'Đánh dấu giao dịch đang xử lý' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  async processTransaction(@Param('id') id: string): Promise<unknown> {
    return this.transactionsService.markTransactionProcessing(id);
  }

  @Post('transactions/:id/resolve-dispute')
  @ApiOperation({ summary: 'Giải quyết khiếu nại giao dịch' })
  @ApiParam({ name: 'id', description: 'Transaction ID' })
  async resolveTransactionDispute(
    @Param('id') id: string,
    @Body() body: ResolveTransactionDisputeDto,
    @Req() req: AdminRequest,
  ): Promise<unknown> {
    const adminId = req.user?.sub;
    if (!adminId) {
      throw new UnauthorizedException('Thiếu thông tin quản trị viên');
    }

    const result = await this.transactionsService.resolveTransactionDispute(
      id,
      body.resolution,
      adminId,
      body.notes,
    );

    await this.auditLogsService.log({
      actorId: adminId,
      actorRole: req.user?.role,
      action: 'RESOLVE_TRANSACTION_DISPUTE',
      targetType: 'TRANSACTION',
      targetId: id,
      metadata: {
        resolution: body.resolution,
      },
    });

    return result;
  }

  private normalizeAnalyticsPeriod(value?: string): AdminAnalyticsPeriod {
    const allowed: AdminAnalyticsPeriod[] = ['7d', '30d', '3m', '6m', '1y'];
    if (!value) {
      return '30d';
    }

    return allowed.includes(value as AdminAnalyticsPeriod)
      ? (value as AdminAnalyticsPeriod)
      : '30d';
  }
}
