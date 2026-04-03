import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, Transporter } from 'nodemailer';

interface AttachmentOption {
  filename?: string;
  path?: string;
  content?: string | Buffer;
  contentType?: string;
}

interface SendMailOptions {
  to: string;
  subject: string;
  text?: string;
  html?: string;
  attachments?: AttachmentOption[];
}

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter?: Transporter;
  private readonly fromAddress?: string;

  constructor(private readonly configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST');
    const port = Number(this.configService.get<string>('SMTP_PORT')) || 587;
    const secure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASSWORD');

    this.fromAddress =
      this.configService.get<string>('SMTP_FROM_EMAIL') || user || undefined;

    if (!host || !user || !pass) {
      this.logger.warn(
        'SMTP credentials are not fully configured. Email delivery is disabled.',
      );
      return;
    }

    this.transporter = createTransport({
      host,
      port,
      secure,
      auth: {
        user,
        pass,
      },
    });
  }

  async sendMail(options: SendMailOptions) {
    if (!this.transporter) {
      throw new ServiceUnavailableException(
        'Email service is not configured. Please contact the administrator.',
      );
    }

    const mailOptions = {
      from: this.fromAddress || options.to,
      ...options,
    };

    try {
      await this.transporter.sendMail(mailOptions);
    } catch (error) {
      const err = error as Record<string, any>;
      const rawMessage =
        err?.response?.toString?.() || err?.message || 'Unknown error';
      const sanitizedMessage = String(rawMessage)
        .split('\n')[0]
        .replace(/pass(word)?=\S+/gi, 'password=***')
        .trim();

      this.logger.error(
        `Failed to send email: ${sanitizedMessage}`,
        err?.stack || sanitizedMessage,
      );

      throw new ServiceUnavailableException(
        sanitizedMessage
          ? `Không thể gửi email OTP (${sanitizedMessage}). Vui lòng kiểm tra cấu hình SMTP hoặc liên hệ quản trị viên.`
          : 'Không thể gửi email OTP. Vui lòng kiểm tra cấu hình SMTP hoặc liên hệ quản trị viên.',
      );
    }
  }
}
