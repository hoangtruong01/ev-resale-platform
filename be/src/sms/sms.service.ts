import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface SmsSendResult {
  skipped?: boolean;
  provider?: string;
  messageId?: string;
}

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly provider?: string;
  private readonly apiUrl?: string;
  private readonly apiKey?: string;
  private readonly senderId?: string;

  constructor(private readonly configService: ConfigService) {
    this.provider = this.configService.get<string>('SMS_PROVIDER');
    this.apiUrl = this.configService.get<string>('SMS_API_URL');
    this.apiKey = this.configService.get<string>('SMS_API_KEY');
    this.senderId = this.configService.get<string>('SMS_SENDER_ID');

    if (!this.provider || !this.apiUrl || !this.apiKey) {
      this.logger.warn(
        'SMS is not fully configured. SMS delivery is disabled.',
      );
    }
  }

  async sendSms(to: string, message: string): Promise<SmsSendResult> {
    if (!this.provider || !this.apiUrl || !this.apiKey) {
      return { skipped: true };
    }

    try {
      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          to,
          message,
          senderId: this.senderId,
          provider: this.provider,
        }),
      });

      if (!response.ok) {
        const body = await response.text();
        this.logger.warn(`SMS failed: ${response.status} ${body}`);
        return { provider: this.provider };
      }

      const payload = (await response.json().catch(() => ({}))) as {
        messageId?: string;
      };

      return {
        provider: this.provider,
        messageId: payload.messageId,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.warn(`SMS failed: ${message}`);
      return { provider: this.provider };
    }
  }
}
