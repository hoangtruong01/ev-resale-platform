import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Req,
  ValidationPipe,
  Query,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
  ApiParam,
  ApiBody,
  ApiQuery,
  ApiConsumes,
} from '@nestjs/swagger';
import { UpdateProfileDto, CreateReviewDto } from './dto';
import { GetAllUsersDto } from './dto/get-all-users.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import type { Request } from 'express';

interface AuthenticatedUser {
  sub?: string;
  id?: string;
  email?: string;
  role?: string;
}

interface AuthenticatedRequest extends Request {
  user?: AuthenticatedUser;
}

interface AvatarUploadFile {
  filename: string;
  mimetype: string;
}

@ApiTags('Users')
@Controller(['users', 'api/users'])
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get all users',
    description:
      'Retrieve a paginated list of all users with optional search and filtering',
  })
  @ApiResponse({
    status: 200,
    description: 'Users retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        data: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'number' },
              email: { type: 'string' },
              fullName: { type: 'string' },
              phone: { type: 'string' },
              role: { type: 'string' },
              isActive: { type: 'boolean' },
              createdAt: { type: 'string', format: 'date-time' },
              updatedAt: { type: 'string', format: 'date-time' },
            },
          },
        },
        meta: {
          type: 'object',
          properties: {
            total: { type: 'number' },
            page: { type: 'number' },
            lastPage: { type: 'number' },
          },
        },
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getAllUsers(@Query(ValidationPipe) query: GetAllUsersDto) {
    return this.usersService.findAll(query);
  }

  private extractUserId(req: AuthenticatedRequest): string {
    const user = req.user;
    const userId = user?.id ?? user?.sub;
    if (!userId) {
      throw new UnauthorizedException('User is not authenticated');
    }
    return userId;
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get current user profile',
    description: 'Get detailed profile information for the authenticated user',
  })
  @ApiResponse({
    status: 200,
    description: 'Profile retrieved successfully',
  })
  async getProfile(@Req() req: AuthenticatedRequest) {
    const userId = this.extractUserId(req);
    return this.usersService.getProfile(userId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update user profile',
    description: 'Update profile information for the authenticated user',
  })
  @ApiBody({ type: UpdateProfileDto })
  @ApiResponse({
    status: 200,
    description: 'Profile updated successfully',
  })
  async updateProfile(
    @Req() req: AuthenticatedRequest,
    @Body(ValidationPipe) updateProfileDto: UpdateProfileDto,
  ) {
    const userId = this.extractUserId(req);
    return this.usersService.updateProfile(userId, updateProfileDto);
  }

  @Patch('profile/avatar')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: diskStorage({
        destination: (_req, _file, callback) => {
          const uploadPath = join(process.cwd(), 'uploads', 'avatars');
          if (!existsSync(uploadPath)) {
            mkdirSync(uploadPath, { recursive: true });
          }
          callback(null, uploadPath);
        },
        filename: (_req, file, callback) => {
          const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1_000_000)}`;
          callback(null, `${uniqueSuffix}${extname(file.originalname)}`);
        },
      }),
      limits: {
        fileSize: 5 * 1024 * 1024,
      },
      fileFilter: (_req, file, callback) => {
        if (!file.mimetype.startsWith('image/')) {
          return callback(
            new BadRequestException('Only image files are allowed') as any,
            false,
          );
        }
        callback(null, true);
      },
    }),
  )
  @ApiOperation({
    summary: 'Update user avatar',
    description:
      'Upload and update the avatar image for the authenticated user',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        avatar: {
          type: 'string',
          format: 'binary',
          description: 'Avatar image file',
        },
      },
      required: ['avatar'],
    },
  })
  async updateAvatar(
    @Req() req: AuthenticatedRequest,
    @UploadedFile() file?: AvatarUploadFile,
  ) {
    if (!file) {
      throw new BadRequestException('Avatar file is required');
    }

    const userId = this.extractUserId(req);
    const avatarUrl = `/uploads/avatars/${file.filename}`;
    const user = await this.usersService.updateAvatar(userId, avatarUrl);

    return {
      message: 'Avatar updated successfully',
      avatar: user.avatar,
      user,
    };
  }

  @Get('transactions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get user transactions',
    description: 'Get transaction history for the authenticated user',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: ['sales', 'purchases', 'all'],
  })
  async getTransactions(
    @Req() req: AuthenticatedRequest,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('type') type?: 'sales' | 'purchases' | 'all',
  ) {
    const userId = this.extractUserId(req);
    return this.usersService.getTransactions(userId, { page, limit, type });
  }

  @Get('reviews')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get user reviews',
    description: 'Get reviews for the authenticated user',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getReviews(
    @Req() req: AuthenticatedRequest,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    const userId = this.extractUserId(req);
    return this.usersService.getReviews(userId, page, limit);
  }

  @Post('reviews')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create a review',
    description: 'Create a review for a user after a transaction',
  })
  @ApiBody({ type: CreateReviewDto })
  @ApiResponse({
    status: 201,
    description: 'Review created successfully',
  })
  async createReview(
    @Req() req: AuthenticatedRequest,
    @Body(ValidationPipe) createReviewDto: CreateReviewDto,
  ) {
    const userId = this.extractUserId(req);
    return this.usersService.createReview(userId, createReviewDto);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get user by ID',
    description: 'Get public profile information for a specific user',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({
    status: 200,
    description: 'User found',
  })
  @ApiResponse({
    status: 404,
    description: 'User not found',
  })
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Get(':id/reviews')
  @ApiOperation({
    summary: 'Get reviews for a specific user',
    description: 'Get paginated reviews for a specific user',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getUserReviews(
    @Param('id') userId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.usersService.getReviews(userId, page, limit);
  }

  @Get(':id/listings')
  @ApiOperation({
    summary: 'Get user listings',
    description:
      'Get active listings (batteries and vehicles) for a specific user',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: ['batteries', 'vehicles', 'all'],
  })
  async getUserListings(
    @Param('id') userId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('type') type?: 'batteries' | 'vehicles' | 'all',
  ) {
    return this.usersService.getUserListings(userId, { page, limit, type });
  }

  // Admin endpoints would be in a separate admin controller, but for now adding basic ones here
  @Get()
  @ApiOperation({
    summary: 'Get all users (Admin)',
    description: 'Get paginated list of all users - Admin only',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  async findAll(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
  ) {
    return this.usersService.findAll({ page, limit, search });
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Update user (Admin)',
    description: 'Update user information - Admin only',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  async update(@Param('id') id: string, @Body() updateUserData: any) {
    return this.usersService.update(id, updateUserData);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Deactivate user (Admin)',
    description: 'Deactivate a user account - Admin only',
  })
  @ApiParam({ name: 'id', description: 'User ID' })
  async remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
