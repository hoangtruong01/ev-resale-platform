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
  UploadedFiles,
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
import { SubmitKycDto, ReviewKycDto } from './dto/submit-kyc.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '@prisma/client';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
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

interface UploadedMulterFile {
  filename: string;
  mimetype: string;
}

const kycStorage = diskStorage({
  destination: (_req, _file, callback) => {
    const uploadPath = join(process.cwd(), 'uploads', 'kyc');
    if (!existsSync(uploadPath)) {
      mkdirSync(uploadPath, { recursive: true });
    }
    callback(null, uploadPath);
  },
  filename: (_req, file, callback) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1_000_000)}`;
    callback(null, `${uniqueSuffix}${extname(file.originalname)}`);
  },
});

const imageFilter = (_req: any, file: any, callback: any) => {
  if (!file.mimetype.startsWith('image/')) {
    return callback(
      new BadRequestException('Chỉ chấp nhận file ảnh.') as any,
      false,
    );
  }
  callback(null, true);
};

@ApiTags('Users')
@Controller(['users', 'api/users'])
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get all users' })
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
  @ApiOperation({ summary: 'Get current user profile' })
  async getProfile(@Req() req: AuthenticatedRequest) {
    const userId = this.extractUserId(req);
    return this.usersService.getProfile(userId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update user profile' })
  @ApiBody({ type: UpdateProfileDto })
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
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: imageFilter,
    }),
  )
  @ApiOperation({ summary: 'Update user avatar' })
  @ApiConsumes('multipart/form-data')
  async updateAvatar(
    @Req() req: AuthenticatedRequest,
    @UploadedFile() file?: UploadedMulterFile,
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

  // ─── eKYC Endpoints ────────────────────────────────────────────────────────

  /**
   * Get own KYC status
   */
  @Get('kyc/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Get own KYC verification status',
    description:
      'Returns the KYC status and submitted document info for the authenticated user.',
  })
  async getKycStatus(@Req() req: AuthenticatedRequest) {
    const userId = this.extractUserId(req);
    return this.usersService.getKycStatus(userId);
  }

  /**
   * Submit KYC with images (multipart)
   * Fields: idFrontImage (required), idBackImage (optional), faceImage (optional)
   * Body JSON fields: idNumber, idType, fullNameOnId, idIssueDate, idIssuePlace
   */
  @Post('kyc/submit')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @UseInterceptors(
    FilesInterceptor('images', 3, {
      storage: kycStorage,
      limits: { fileSize: 10 * 1024 * 1024 },
      fileFilter: imageFilter,
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Submit KYC identity verification documents',
    description:
      'Upload CMND/CCCD front image (required), back image, and selfie. ' +
      'Also provide idNumber, idType in the multipart body.',
  })
  async submitKyc(
    @Req() req: AuthenticatedRequest,
    @Body(new ValidationPipe({ whitelist: true })) dto: SubmitKycDto,
    @UploadedFiles() files: UploadedMulterFile[],
  ) {
    const userId = this.extractUserId(req);
    const uploaded = files ?? [];

    const getUrl = (index: number) =>
      uploaded[index] ? `/uploads/kyc/${uploaded[index].filename}` : undefined;

    return this.usersService.submitKyc(userId, dto, {
      idFrontImage: getUrl(0),
      idBackImage: getUrl(1),
      faceImage: getUrl(2),
    });
  }

  /**
   * Admin: list pending KYC requests
   */
  @Get('kyc/pending')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] List pending KYC requests' })
  async listPendingKyc(@Req() req: AuthenticatedRequest) {
    const user = req.user as any;
    return this.usersService.listPendingKyc(user.role);
  }

  /**
   * Admin: approve or reject a user's KYC
   */
  @Post('kyc/:userId/review')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: '[Admin] Approve or reject KYC for a user' })
  @ApiParam({ name: 'userId', description: 'Target user ID' })
  @ApiBody({ type: ReviewKycDto })
  async reviewKyc(
    @Req() req: AuthenticatedRequest,
    @Param('userId') targetUserId: string,
    @Body(new ValidationPipe({ whitelist: true })) dto: ReviewKycDto,
  ) {
    const user = req.user as any;
    return this.usersService.reviewKyc(
      user.id ?? user.sub,
      user.role,
      targetUserId,
      dto,
    );
  }

  // ─── Existing endpoints ────────────────────────────────────────────────────

  @Get('transactions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get user transactions' })
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
  @ApiOperation({ summary: 'Get user reviews' })
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
  @ApiOperation({ summary: 'Create a review' })
  @ApiBody({ type: CreateReviewDto })
  async createReview(
    @Req() req: AuthenticatedRequest,
    @Body(ValidationPipe) createReviewDto: CreateReviewDto,
  ) {
    const userId = this.extractUserId(req);
    return this.usersService.createReview(userId, createReviewDto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'id', description: 'User ID' })
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Get(':id/reviews')
  @ApiOperation({ summary: 'Get reviews for a specific user' })
  @ApiParam({ name: 'id', description: 'User ID' })
  async getUserReviews(
    @Param('id') userId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.usersService.getReviews(userId, page, limit);
  }

  @Get(':id/listings')
  @ApiOperation({ summary: 'Get user listings' })
  @ApiParam({ name: 'id', description: 'User ID' })
  async getUserListings(
    @Param('id') userId: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('type') type?: 'batteries' | 'vehicles' | 'all',
  ) {
    return this.usersService.getUserListings(userId, { page, limit, type });
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update user (Admin)' })
  @ApiParam({ name: 'id', description: 'User ID' })
  async update(@Param('id') id: string, @Body() updateUserData: any) {
    return this.usersService.update(id, updateUserData);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate user (Admin)' })
  @ApiParam({ name: 'id', description: 'User ID' })
  async remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
