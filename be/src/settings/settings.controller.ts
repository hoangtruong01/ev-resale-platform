import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  UseGuards,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../auth/dto/auth.dto';
import { SettingsService } from './settings.service';
import { CreateSettingDto, UpdateSettingDto } from './dto';
import { AuditLogsService } from '../audit-logs/audit-logs.service';

interface RequestWithUser {
  user?: {
    sub?: string;
    role?: string;
  };
}

@ApiTags('settings')
@Controller('settings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class SettingsController {
  constructor(
    private readonly settingsService: SettingsService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create new setting' })
  @ApiResponse({ status: 201, description: 'Setting created successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires admin role' })
  async create(
    @Body() createSettingDto: CreateSettingDto,
    @Req() req: RequestWithUser,
  ) {
    const actorId = req.user?.sub;
    if (!actorId) {
      throw new UnauthorizedException('Missing authenticated admin context');
    }

    const created = await this.settingsService.create(createSettingDto);
    await this.auditLogsService.log({
      actorId,
      actorRole: req.user?.role,
      action: 'UPDATE_SYSTEM_SETTINGS',
      targetType: 'SETTING',
      targetId: created.id,
      metadata: {
        key: createSettingDto.key,
        type: createSettingDto.type ?? 'string',
      },
    });
    return created;
  }

  @Get()
  @ApiOperation({ summary: 'Get all settings' })
  @ApiResponse({ status: 200, description: 'List all settings' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  findAll() {
    return this.settingsService.findAll();
  }

  @Get(':key')
  @ApiOperation({ summary: 'Get setting by key' })
  @ApiParam({ name: 'key', description: 'Setting key' })
  @ApiResponse({ status: 200, description: 'Setting found' })
  @ApiResponse({ status: 404, description: 'Setting not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  findOne(@Param('key') key: string) {
    return this.settingsService.findOne(key);
  }

  @Put(':key')
  @ApiOperation({ summary: 'Update setting' })
  @ApiParam({ name: 'key', description: 'Setting key' })
  @ApiResponse({ status: 200, description: 'Setting updated successfully' })
  @ApiResponse({ status: 404, description: 'Setting not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires admin role' })
  async update(
    @Param('key') key: string,
    @Body() updateSettingDto: UpdateSettingDto,
    @Req() req: RequestWithUser,
  ) {
    const actorId = req.user?.sub;
    if (!actorId) {
      throw new UnauthorizedException('Missing authenticated admin context');
    }

    const updated = await this.settingsService.update(key, updateSettingDto);
    await this.auditLogsService.log({
      actorId,
      actorRole: req.user?.role,
      action: 'UPDATE_SYSTEM_SETTINGS',
      targetType: 'SETTING',
      targetId: updated.id,
      metadata: {
        key,
      },
    });

    return updated;
  }

  @Delete(':key')
  @ApiOperation({ summary: 'Delete setting' })
  @ApiParam({ name: 'key', description: 'Setting key' })
  @ApiResponse({ status: 200, description: 'Setting deleted successfully' })
  @ApiResponse({ status: 404, description: 'Setting not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires admin role' })
  async remove(@Param('key') key: string, @Req() req: RequestWithUser) {
    const actorId = req.user?.sub;
    if (!actorId) {
      throw new UnauthorizedException('Missing authenticated admin context');
    }

    const deleted = await this.settingsService.remove(key);
    await this.auditLogsService.log({
      actorId,
      actorRole: req.user?.role,
      action: 'UPDATE_SYSTEM_SETTINGS',
      targetType: 'SETTING',
      targetId: deleted.id,
      metadata: {
        key,
      },
    });
    return deleted;
  }

  @Get('value/:key')
  @ApiOperation({ summary: 'Get setting value by key' })
  @ApiParam({ name: 'key', description: 'Setting key' })
  @ApiResponse({ status: 200, description: 'Setting value found' })
  @ApiResponse({ status: 404, description: 'Setting not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getValue(@Param('key') key: string) {
    const value = await this.settingsService.getValue(key);
    return { value };
  }
}
