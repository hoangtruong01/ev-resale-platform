import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import {
  GoogleUser,
  FacebookUser,
  RegisterDto,
  LoginDto,
  CompleteProfileDto,
  UpdateAuthDto,
} from './dto/auth.dto';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  // Local Registration
  async register(registerDto: RegisterDto) {
    const { email, password, fullName, phone } = registerDto;

    const normalizedEmail = email.trim().toLowerCase();
    const normalizedPhone = phone ? phone.trim() : undefined;

    // Prefer explicit messaging so users know which field is duplicated
    const existingByEmail = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });

    if (existingByEmail) {
      throw new BadRequestException(
        'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.',
      );
    }

    if (normalizedPhone) {
      const existingByPhone = await this.prisma.user.findUnique({
        where: { phone: normalizedPhone },
        select: { id: true },
      });

      if (existingByPhone) {
        throw new BadRequestException(
          'Số điện thoại này đã được đăng ký. Vui lòng dùng số khác.',
        );
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = await this.prisma.user.create({
      data: {
        email: normalizedEmail,
        password: hashedPassword,
        fullName,
        phone: normalizedPhone,
        provider: 'local',
        isProfileComplete: false,
      },
    });

    return this.generateAuthResponse(user);
  }

  // Local Login
  async localLogin(loginDto: LoginDto) {
    const { email, password } = loginDto;

    // Find user by email
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { profile: true },
    });

    if (!user || !user.password) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Tài khoản của bạn đã bị khóa');
    }

    return this.generateAuthResponse(user);
  }

  // Complete Profile
  async completeProfile(userId: string, profileData: CompleteProfileDto) {
    // Update user info
    const updateUserData: any = {};
    if (profileData.dateOfBirth)
      updateUserData.dateOfBirth = profileData.dateOfBirth;
    if (profileData.gender) updateUserData.gender = profileData.gender;
    if (profileData.occupation)
      updateUserData.occupation = profileData.occupation;
    if (profileData.bio) updateUserData.bio = profileData.bio;
    if (profileData.address) updateUserData.address = profileData.address;
    if (profileData.phone) updateUserData.phone = profileData.phone;

    // Mark profile as complete
    updateUserData.isProfileComplete = true;
    updateUserData.profileCompletedAt = new Date();

    // Update user
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: updateUserData,
    });

    // Create or update profile
    await this.prisma.profile.upsert({
      where: { userId },
      create: {
        userId,
        location: profileData.location,
        district: profileData.district,
        city: profileData.city,
        emergencyContactName: profileData.emergencyContactName,
        emergencyContactPhone: profileData.emergencyContactPhone,
        idNumber: profileData.idNumber,
        idType: profileData.idType as any,
      },
      update: {
        location: profileData.location,
        district: profileData.district,
        city: profileData.city,
        emergencyContactName: profileData.emergencyContactName,
        emergencyContactPhone: profileData.emergencyContactPhone,
        idNumber: profileData.idNumber,
        idType: profileData.idType as any,
      },
    });

    return { success: true, message: 'Hoàn thành hồ sơ thành công!' };
  }

  // Generate auth response with token
  private generateAuthResponse(user: any) {
    const payload = {
      email: user.email,
      sub: user.id,
      name: user.fullName,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        name: user.name,
        avatar: user.avatar,
        isProfileComplete: user.isProfileComplete,
        role: user.role,
        phone: user.phone,
        address: user.address,
        profile: user.profile ?? null,
      },
      requiresProfileCompletion: !user.isProfileComplete,
    };
  }

  async validateGoogleUser(googleUser: GoogleUser) {
    const { googleId, email, firstName, lastName, picture } = googleUser;

    // Tìm user theo Google ID hoặc email
    let user = await this.prisma.user.findFirst({
      where: {
        OR: [{ googleId: googleId }, { email: email }],
      },
    });

    if (user) {
      // Cập nhật Google ID nếu user đã tồn tại nhưng chưa có Google ID
      if (!user.googleId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            googleId: googleId,
            avatar: picture,
            name: `${firstName} ${lastName}`,
            provider: 'google',
          },
        });
      }
    } else {
      // Tạo user mới với profile chưa hoàn thành
      user = await this.prisma.user.create({
        data: {
          googleId: googleId,
          email: email,
          fullName: `${firstName} ${lastName}`,
          name: `${firstName} ${lastName}`,
          avatar: picture,
          provider: 'google',
          isProfileComplete: false, // Yêu cầu hoàn thành profile
        },
      });
    }

    return user;
  }

  async validateFacebookUser(facebookUser: FacebookUser) {
    const { facebookId, email, firstName, lastName, picture } = facebookUser;

    // Tìm user theo Facebook ID hoặc email
    let user = await this.prisma.user.findFirst({
      where: {
        OR: [{ facebookId: facebookId }, { email: email }],
      },
    });

    if (user) {
      // Cập nhật Facebook ID nếu user đã tồn tại nhưng chưa có Facebook ID
      if (!user.facebookId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            facebookId: facebookId,
            avatar: picture,
            name: `${firstName} ${lastName}`,
            provider: 'facebook',
          },
        });
      }
    } else {
      // Tạo user mới với profile chưa hoàn thành
      user = await this.prisma.user.create({
        data: {
          facebookId: facebookId,
          email: email,
          fullName: `${firstName} ${lastName}`,
          name: `${firstName} ${lastName}`,
          avatar: picture,
          provider: 'facebook',
          isProfileComplete: false, // Yêu cầu hoàn thành profile
        },
      });
    }

    return user;
  }

  async login(user: any) {
    return this.generateAuthResponse(user);
  }

  async validateToken(payload: any) {
    const user = await this.prisma.user.findFirst({
      where: { id: payload.sub, isActive: true },
      select: {
        id: true,
        email: true,
        fullName: true,
        name: true,
        avatar: true,
        role: true,
        isProfileComplete: true,
        phone: true,
        address: true,
        profile: true,
      },
    });

    if (!user) {
      return null;
    }

    return {
      ...user,
      sub: user.id,
    };
  }

  async remove(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('Người dùng không tồn tại');
    }

    await this.prisma.profile.deleteMany({
      where: { userId: id },
    });

    await this.prisma.user.delete({
      where: { id },
    });

    return { success: true, message: 'Người dùng đã được xóa thành công' };
  }

  async deleteProfile(id: string) {
    return this.remove(id);
  }

  async findAll() {
    const userSelect = {
      id: true,
      email: true,
      password: true,
      fullName: true,
      name: true,
      avatar: true,
      isProfileComplete: true,
      role: true,
      createdAt: true,
      updatedAt: true,
      provider: true,
      phone: true,
      gender: true,
      dateOfBirth: true,
      occupation: true,
      address: true,
      isActive: true,
      profileCompletedAt: true,
      profile: {
        select: {
          location: true,
          district: true,
          city: true,
          emergencyContactName: true,
          emergencyContactPhone: true,
          idNumber: true,
          idType: true,
        },
      },
    };

    return this.prisma.user.findMany({ select: userSelect });
  }

  async update(id: string, updateAuthDto: UpdateAuthDto) {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('Người dùng không tồn tại');
    }

    // Handle password update separately with hashing
    const data: any = { ...updateAuthDto };
    if (updateAuthDto.password) {
      data.password = await bcrypt.hash(updateAuthDto.password, 10);
    }

    // Update user
    const updatedUser = await this.prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        email: true,
        fullName: true,
        name: true,
        avatar: true,
        isProfileComplete: true,
        role: true,
        createdAt: true,
        updatedAt: true,
        provider: true,
        phone: true,
        gender: true,
        dateOfBirth: true,
        occupation: true,
        address: true,
        isActive: true,
        profileCompletedAt: true,
      },
    });

    return updatedUser;
  }
}
