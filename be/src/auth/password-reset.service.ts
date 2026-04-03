import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { randomBytes, randomInt } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { Prisma } from '@prisma/client';

export interface RequestPasswordResetResult {
  resetId?: string;
}

export interface VerifyOtpResult {
  resetToken: string;
}

@Injectable()
export class PasswordResetService {
  private readonly logger = new Logger(PasswordResetService.name);
  private readonly otpTtlMinutes: number;
  private readonly tokenTtlMinutes: number;
  private readonly maxOtpAttempts: number;
  private readonly resendIntervalSeconds: number;
  private readonly maxResendAttempts: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
    private readonly configService: ConfigService,
  ) {
    this.otpTtlMinutes = Number(
      this.configService.get('PASSWORD_RESET_OTP_TTL_MINUTES') ?? 10,
    );
    this.tokenTtlMinutes = Number(
      this.configService.get('PASSWORD_RESET_TOKEN_TTL_MINUTES') ?? 30,
    );
    this.maxOtpAttempts = Number(
      this.configService.get('PASSWORD_RESET_MAX_ATTEMPTS') ?? 5,
    );
    this.resendIntervalSeconds = Number(
      this.configService.get('PASSWORD_RESET_RESEND_INTERVAL_SECONDS') ?? 60,
    );
    this.maxResendAttempts = Number(
      this.configService.get('PASSWORD_RESET_MAX_RESENDS') ?? 3,
    );
  }

  async request(email: string): Promise<RequestPasswordResetResult> {
    try {
      const normalizedEmail = email.trim().toLowerCase();
      const user = await this.prisma.user.findUnique({
        where: { email: normalizedEmail },
      });

      if (!user || !user.password) {
        // Return generic message to avoid email enumeration
        return {};
      }

      const prisma = this.prisma as any;

      await prisma.passwordReset.deleteMany({
        where: {
          userId: user.id,
          completedAt: null,
        },
      });

      const otp = this.generateOtp();
      const otpHash = await bcrypt.hash(otp, 10);
      const otpExpiresAt = new Date(
        Date.now() + this.otpTtlMinutes * 60 * 1000,
      );

      const resetRequest = await prisma.passwordReset.create({
        data: {
          userId: user.id,
          email: normalizedEmail,
          otpHash,
          otpExpiresAt,
          maxAttempts: this.maxOtpAttempts,
          lastSentAt: new Date(),
        },
      });

      try {
        await this.sendOtpEmail(
          user.fullName ?? user.email,
          normalizedEmail,
          otp,
        );
      } catch (error) {
        const err = error as Error;
        this.logger.error(
          `Failed to send OTP email: ${err.message}`,
          err.stack,
        );

        await prisma.passwordReset
          .delete({ where: { id: resetRequest.id } })
          .catch(() => undefined);

        if (error instanceof ServiceUnavailableException) {
          throw error;
        }

        throw new ServiceUnavailableException(
          'Không thể gửi email OTP. Vui lòng thử lại sau.',
        );
      }

      return { resetId: resetRequest.id };
    } catch (error) {
      return this.handleServiceError(error);
    }
  }

  async verify(resetId: string, otp: string): Promise<VerifyOtpResult> {
    try {
      const prisma = this.prisma as any;

      const record = await prisma.passwordReset.findUnique({
        where: { id: resetId },
      });

      if (!record || record.completedAt) {
        throw new BadRequestException('Yêu cầu không hợp lệ hoặc đã hết hạn.');
      }

      if (record.otpExpiresAt < new Date()) {
        throw new BadRequestException('Mã OTP đã hết hạn. Vui lòng gửi lại.');
      }

      if (record.attempts >= record.maxAttempts) {
        throw new BadRequestException(
          'Bạn đã nhập sai OTP quá số lần cho phép. Vui lòng tạo yêu cầu mới.',
        );
      }

      const sanitizedOtp = otp.trim();

      if (!sanitizedOtp) {
        throw new BadRequestException('Vui lòng nhập mã OTP.');
      }

      const isValid = await bcrypt.compare(sanitizedOtp, record.otpHash);

      if (!isValid) {
        await prisma.passwordReset.update({
          where: { id: resetId },
          data: {
            attempts: { increment: 1 },
          },
        });

        throw new BadRequestException(
          'Mã OTP không chính xác. Vui lòng thử lại.',
        );
      }

      const resetToken = this.generateResetToken();
      const resetTokenHash = await bcrypt.hash(resetToken, 10);
      const resetTokenExpiresAt = new Date(
        Date.now() + this.tokenTtlMinutes * 60 * 1000,
      );

      await prisma.passwordReset.update({
        where: { id: resetId },
        data: {
          isVerified: true,
          attempts: 0,
          resetTokenHash,
          resetTokenExpiresAt,
        },
      });

      return { resetToken };
    } catch (error) {
      return this.handleServiceError(error);
    }
  }

  async resend(resetId: string) {
    try {
      const prisma = this.prisma as any;

      const record = await prisma.passwordReset.findUnique({
        where: { id: resetId },
        include: {
          user: true,
        },
      });

      if (!record || record.completedAt) {
        throw new BadRequestException(
          'Yêu cầu không tồn tại hoặc đã hoàn tất.',
        );
      }

      if (record.user?.password === null) {
        throw new NotFoundException('Không tìm thấy người dùng hợp lệ.');
      }

      if (record.isVerified) {
        throw new BadRequestException(
          'Mã OTP đã được xác thực. Vui lòng tiếp tục đặt lại mật khẩu.',
        );
      }

      if (record.resendCount >= this.maxResendAttempts) {
        throw new BadRequestException(
          'Bạn đã yêu cầu gửi lại OTP quá số lần cho phép. Vui lòng tạo yêu cầu mới.',
        );
      }

      const nextAllowedSentAt =
        record.lastSentAt.getTime() + this.resendIntervalSeconds * 1000;

      if (nextAllowedSentAt > Date.now()) {
        throw new BadRequestException(
          'Vui lòng chờ thêm ít phút trước khi yêu cầu gửi lại OTP.',
        );
      }

      const otp = this.generateOtp();
      const otpHash = await bcrypt.hash(otp, 10);
      const otpExpiresAt = new Date(
        Date.now() + this.otpTtlMinutes * 60 * 1000,
      );

      await prisma.passwordReset.update({
        where: { id: resetId },
        data: {
          otpHash,
          otpExpiresAt,
          attempts: 0,
          resendCount: { increment: 1 },
          lastSentAt: new Date(),
        },
      });

      await this.sendOtpEmail(
        record.user.fullName ?? record.user.email,
        record.email,
        otp,
      );
    } catch (error) {
      this.handleServiceError(error);
    }
  }

  async resetPassword(
    resetId: string,
    resetToken: string,
    password: string,
    confirmPassword: string,
  ) {
    try {
      if (password !== confirmPassword) {
        throw new BadRequestException('Mật khẩu xác nhận không khớp.');
      }

      const prisma = this.prisma as any;

      const record = await prisma.passwordReset.findUnique({
        where: { id: resetId },
        include: {
          user: true,
        },
      });

      if (!record || record.completedAt) {
        throw new BadRequestException('Phiên đặt lại mật khẩu không hợp lệ.');
      }

      if (!record.isVerified || !record.resetTokenHash) {
        throw new BadRequestException('Mã OTP chưa được xác thực.');
      }

      if (!record.user || !record.user.password) {
        throw new NotFoundException('Không tìm thấy người dùng hợp lệ.');
      }

      if (
        record.resetTokenExpiresAt &&
        record.resetTokenExpiresAt.getTime() < Date.now()
      ) {
        throw new BadRequestException(
          'Phiên đặt lại mật khẩu đã hết hạn. Vui lòng tạo yêu cầu mới.',
        );
      }

      const sanitizedToken = resetToken.trim();

      if (!sanitizedToken) {
        throw new BadRequestException('Phiên đặt lại mật khẩu không hợp lệ.');
      }

      const isTokenValid = await bcrypt.compare(
        sanitizedToken,
        record.resetTokenHash,
      );

      if (!isTokenValid) {
        throw new BadRequestException('Phiên đặt lại mật khẩu không hợp lệ.');
      }

      const hashedPassword = await bcrypt.hash(password, 10);

      await this.prisma.$transaction([
        this.prisma.user.update({
          where: { id: record.userId },
          data: {
            password: hashedPassword,
          },
        }),
        prisma.passwordReset.update({
          where: { id: resetId },
          data: {
            completedAt: new Date(),
            resetTokenHash: null,
          },
        }),
      ]);
    } catch (error) {
      this.handleServiceError(error);
    }
  }

  private generateOtp(): string {
    return randomInt(100000, 999999).toString();
  }

  private generateResetToken(): string {
    return randomBytes(32).toString('hex');
  }

  private async sendOtpEmail(name: string, to: string, otp: string) {
    const subject = 'Mã OTP khôi phục mật khẩu EVN Market';
    const html = `
      <p>Xin chào ${name || 'bạn'},</p>
      <p>Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản EVN Market.</p>
      <p>Mã OTP của bạn là:</p>
      <h2 style="letter-spacing: 8px;">${otp}</h2>
      <p>Mã có hiệu lực trong ${this.otpTtlMinutes} phút. Không chia sẻ mã này với bất kỳ ai.</p>
      <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
      <p>Trân trọng,<br />Đội ngũ EVN Market</p>
    `;

    const text = `Xin chào ${name || 'bạn'},

  Mã OTP đặt lại mật khẩu EVN Market của bạn là: ${otp}.
  Mã có hiệu lực trong ${this.otpTtlMinutes} phút.
  Nếu bạn không yêu cầu, vui lòng bỏ qua email này.`;

    await this.mailService.sendMail({
      to,
      subject,
      html,
      text,
    });
  }

  private handleServiceError(error: unknown): never {
    if (
      error instanceof BadRequestException ||
      error instanceof NotFoundException ||
      error instanceof ServiceUnavailableException
    ) {
      throw error;
    }

    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      (error.code === 'P2021' ||
        error.code === 'P2010' ||
        error.code === 'P2018')
    ) {
      this.logger.error(
        `Password reset storage unavailable: ${error.code}`,
        error.stack,
      );

      throw new ServiceUnavailableException(
        'Chức năng khôi phục mật khẩu đang được bảo trì. Vui lòng thử lại sau.',
      );
    }

    const err = error as Error;
    this.logger.error(
      `Unexpected password reset failure: ${err?.message ?? 'Unknown error'}`,
      err?.stack,
    );

    throw new ServiceUnavailableException(
      'Không thể xử lý yêu cầu khôi phục mật khẩu. Vui lòng thử lại sau.',
    );
  }
}
