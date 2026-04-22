/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return */

import {
  Controller,
  Post,
  Body,
  Get,
  Req,
  Res,
  UseGuards,
  BadRequestException,
  Put,
  Delete,
  Param,
  ValidationPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import type { Response } from 'express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBody,
  ApiConsumes,
  ApiOkResponse,
  ApiUnauthorizedResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthService } from './auth.service';
import { OAuth2Client } from 'google-auth-library';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { UserRole } from '@prisma/client';
import {
  LoginDto,
  RegisterDto,
  CompleteProfileDto,
  UpdateAuthDto,
} from './dto/auth.dto';
import {
  ForgotPasswordRequestDto,
  ResetPasswordDto,
  ResendOtpDto,
  VerifyOtpDto,
} from './dto/password-reset.dto';
import { PasswordResetService } from './password-reset.service';

class AuthResponseDto {
  user: {
    id: string;
    email: string;
    fullName: string;
    name: string;
    avatar: string;
    isProfileComplete: boolean;
    role: string;
    moderatorPermissions?: string[];
  };
  access_token: string;
  refresh_token: string;
  requiresProfileCompletion: boolean;
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private passwordResetService: PasswordResetService,
  ) {}
  private googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

  @Post('login')
  @ApiOperation({
    summary: 'User login',
    description: 'Authenticate user and return JWT token',
  })
  @ApiConsumes('application/json')
  @ApiBody({ type: LoginDto })
  @ApiOkResponse({
    description: 'Login successful',
    type: AuthResponseDto,
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid credentials',
  })
  async login(
    @Body(new ValidationPipe({ transform: true })) loginDto: LoginDto,
  ) {
    return await this.authService.localLogin(loginDto);
  }

  @Post('refresh')
  @ApiOperation({
    summary: 'Refresh access token',
    description: 'Issue a new token pair using a valid refresh token',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        refresh_token: { type: 'string' },
      },
      required: ['refresh_token'],
    },
  })
  async refresh(@Body('refresh_token') refreshToken: string) {
    if (!refreshToken) {
      throw new BadRequestException('Missing refresh_token');
    }
    return this.authService.refreshAccessToken(refreshToken);
  }

  @Post('register')
  @ApiOperation({
    summary: 'User registration',
    description: 'Register a new user account',
  })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({
    status: 201,
    description: 'Registration successful',
    type: AuthResponseDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Email already exists',
  })
  async register(@Body() registerDto: RegisterDto) {
    return await this.authService.register(registerDto);
  }

  @Post('password/forgot')
  @ApiOperation({
    summary: 'Request password reset',
    description: 'Send OTP to user email for password reset',
  })
  async forgotPassword(
    @Body(new ValidationPipe({ whitelist: true }))
    payload: ForgotPasswordRequestDto,
  ) {
    const result = await this.passwordResetService.request(payload.email);
    return {
      success: true,
      message:
        'Nếu email tồn tại trong hệ thống, mã OTP đã được gửi đến hộp thư của bạn.',
      data: result,
    };
  }

  @Post('password/resend')
  @ApiOperation({
    summary: 'Resend password reset OTP',
  })
  async resendOtp(
    @Body(new ValidationPipe({ whitelist: true })) payload: ResendOtpDto,
  ) {
    await this.passwordResetService.resend(payload.resetId);
    return {
      success: true,
      message: 'Mã OTP mới đã được gửi đến email của bạn.',
    };
  }

  @Post('password/verify')
  @ApiOperation({
    summary: 'Verify password reset OTP',
  })
  async verifyOtp(
    @Body(new ValidationPipe({ whitelist: true })) payload: VerifyOtpDto,
  ) {
    const result = await this.passwordResetService.verify(
      payload.resetId,
      payload.otp,
    );
    return {
      success: true,
      message: 'Xác thực OTP thành công.',
      data: result,
    };
  }

  @Post('password/reset')
  @ApiOperation({
    summary: 'Reset password with verified OTP',
  })
  async resetPassword(
    @Body(new ValidationPipe({ whitelist: true })) payload: ResetPasswordDto,
  ) {
    await this.passwordResetService.resetPassword(
      payload.resetId,
      payload.resetToken,
      payload.password,
      payload.confirmPassword,
    );

    return {
      success: true,
      message: 'Mật khẩu của bạn đã được cập nhật thành công.',
    };
  }

  @Post('google/verify')
  @ApiOperation({
    summary: 'Verify Google ID token',
    description: 'Verify Google One Tap/Sign-In credential and return JWT',
  })
  async verifyGoogle(@Body('credential') credential: string) {
    if (!credential) {
      throw new BadRequestException('Missing credential');
    }
    const ticket = await this.googleClient.verifyIdToken({
      idToken: credential,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload || !payload.sub || !payload.email) {
      throw new BadRequestException('Invalid Google token');
    }

    const user = await this.authService.validateGoogleUser({
      googleId: payload.sub,
      email: payload.email,
      firstName: payload.given_name ?? '',
      lastName: payload.family_name ?? '',
      picture: payload.picture ?? '',
      accessToken: credential,
    });
    const result = this.authService.login(user);
    return result;
  }

  @Get('google')
  @ApiOperation({
    summary: 'Google OAuth login',
    description: 'Initiate Google OAuth authentication flow',
  })
  @UseGuards(AuthGuard('google'))
  async googleAuth() {
    // Initiates Google OAuth flow
  }

  @Get('google/callback')
  @ApiOperation({
    summary: 'Google OAuth callback',
    description: 'Handle Google OAuth callback and redirect to frontend',
  })
  @UseGuards(AuthGuard('google'))
  googleAuthRedirect(@Req() req, @Res() res: Response) {
    const { access_token, user } = this.authService.login(req.user);

    // Redirect to frontend with token
    const frontendUrl = process.env.CORS_ORIGIN || 'http://localhost:3001';
    res.redirect(
      `${frontendUrl}/auth/callback?token=${access_token}&user=${encodeURIComponent(JSON.stringify(user))}`,
    );
  }

  @Get('facebook')
  @ApiOperation({
    summary: 'Facebook OAuth login',
    description: 'Initiate Facebook OAuth authentication flow',
  })
  @UseGuards(AuthGuard('facebook'))
  async facebookAuth() {
    // Initiates Facebook OAuth flow
  }

  @Get('facebook/callback')
  @ApiOperation({
    summary: 'Facebook OAuth callback',
    description: 'Handle Facebook OAuth callback and redirect to frontend',
  })
  @UseGuards(AuthGuard('facebook'))
  facebookAuthRedirect(@Req() req, @Res() res: Response) {
    const { access_token, user } = this.authService.login(req.user);

    // Redirect to frontend with token
    const frontendUrl = process.env.CORS_ORIGIN || 'http://localhost:3001';
    res.redirect(
      `${frontendUrl}/auth/callback?token=${access_token}&user=${encodeURIComponent(JSON.stringify(user))}`,
    );
  }

  @Put('complete-profile')
  @ApiOperation({
    summary: 'Complete user profile',
    description: 'Complete user profile with additional information',
  })
  @ApiBody({ type: CompleteProfileDto })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  async completeProfile(@Body() profileData: CompleteProfileDto, @Req() req) {
    const authReq = req as { user?: { id?: string } };
    const userId = authReq.user?.id;
    if (!userId) {
      throw new BadRequestException('Missing authenticated user id');
    }

    return this.authService.completeProfile(userId, profileData);
  }

  @Get('profile')
  @ApiOperation({
    summary: 'Get user profile',
    description: 'Get authenticated user profile information',
  })
  @UseGuards(JwtAuthGuard)
  getProfile(@Req() req) {
    return req.user;
  }
  @Delete('users/:id')
  @ApiOperation({
    summary: 'Delete user',
    description: 'Delete user by ID',
  })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiParam({ name: 'id', description: 'User ID' })
  async deleteUser(@Param('id') id: string) {
    return this.authService.remove(id);
  }

  @Get('users')
  @ApiOperation({
    summary: 'Get all users',
    description: 'Get a list of all users',
  })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiResponse({
    status: 200,
    description: 'List of all users',
    type: [Object],
  })
  async getAllUsers() {
    return this.authService.findAll();
  }

  @Put('users/:id')
  @ApiOperation({
    summary: 'Update user',
    description: 'Update user information',
  })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiBody({ type: UpdateAuthDto })
  @ApiResponse({
    status: 200,
    description: 'User updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'User not found',
  })
  async updateUser(
    @Param('id') id: string,
    @Body() updateAuthDto: UpdateAuthDto,
  ) {
    return this.authService.update(id, updateAuthDto);
  }
}
