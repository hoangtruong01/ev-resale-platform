import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaymentCardBrand } from '@prisma/client';
import { createCipheriv, randomBytes, type CipherKey } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { SavePaymentMethodDto } from './dto/save-payment-method.dto';

export interface MaskedPaymentMethod {
  id: string;
  brand: PaymentCardBrand;
  cardholderName: string;
  last4: string;
  expiryMonth: number;
  expiryYear: number;
  billingAddress?: string | null;
  isDefault: boolean;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class PaymentMethodsService {
  private readonly logger = new Logger(PaymentMethodsService.name);
  private encryptionKey?: CipherKey;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async listUserMethods(userId: string): Promise<MaskedPaymentMethod[]> {
    const methods = await this.prisma.paymentMethod.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return methods.map((method) => this.presentMethod(method));
  }

  async getDefaultMethod(userId: string): Promise<MaskedPaymentMethod | null> {
    const method = await this.prisma.paymentMethod.findFirst({
      where: { userId },
      orderBy: { isDefault: 'desc', updatedAt: 'desc' },
    });

    return method ? this.presentMethod(method) : null;
  }

  async savePaymentMethod(
    userId: string,
    dto: SavePaymentMethodDto,
  ): Promise<MaskedPaymentMethod> {
    const sanitizedNumber = this.sanitizeCardNumber(dto.cardNumber);
    this.validateVisaNumber(sanitizedNumber);
    this.ensureNotExpired(dto.expiryMonth, dto.expiryYear);

    const encryptionPayload = this.encryptCardNumber(sanitizedNumber);
    const last4 = sanitizedNumber.slice(-4);
    const normalizedName = dto.cardholderName.trim();
    if (!normalizedName) {
      throw new BadRequestException('Tên chủ thẻ không hợp lệ.');
    }

    const billingAddress = dto.billingAddress?.trim() || null;

    const existingDefault = await this.prisma.paymentMethod.findFirst({
      where: { userId, isDefault: true },
    });

    const baseData = {
      brand: PaymentCardBrand.VISA,
      cardholderName: normalizedName,
      encryptedCardNumber: encryptionPayload.ciphertext,
      encryptionIv: encryptionPayload.iv,
      encryptionAuthTag: encryptionPayload.authTag,
      cardLast4: last4,
      expiryMonth: dto.expiryMonth,
      expiryYear: dto.expiryYear,
      billingAddress,
    };

    let saved;

    if (existingDefault) {
      saved = await this.prisma.paymentMethod.update({
        where: { id: existingDefault.id },
        data: baseData,
      });
    } else {
      saved = await this.prisma.paymentMethod.create({
        data: {
          userId,
          isDefault: true,
          ...baseData,
        },
      });
    }

    return this.presentMethod(saved);
  }

  private presentMethod(method: any): MaskedPaymentMethod {
    return {
      id: method.id,
      brand: method.brand,
      cardholderName: method.cardholderName,
      last4: method.cardLast4,
      expiryMonth: method.expiryMonth,
      expiryYear: method.expiryYear,
      billingAddress: method.billingAddress ?? null,
      isDefault: method.isDefault ?? true,
      createdAt: method.createdAt,
      updatedAt: method.updatedAt,
    };
  }

  private sanitizeCardNumber(raw: string): string {
    const digits = raw.replace(/[^0-9]/g, '');
    if (!digits) {
      throw new BadRequestException('Vui lòng nhập số thẻ Visa.');
    }
    return digits;
  }

  private validateVisaNumber(digits: string) {
    if (!digits.startsWith('4')) {
      throw new BadRequestException('Hiện chỉ hỗ trợ thẻ Visa.');
    }

    if (digits.length < 13 || digits.length > 19) {
      throw new BadRequestException('Số thẻ Visa phải có 13-19 chữ số.');
    }

    if (!this.isLuhnValid(digits)) {
      throw new BadRequestException('Số thẻ Visa không hợp lệ.');
    }
  }

  private ensureNotExpired(month: number, year: number) {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    if (year < currentYear) {
      throw new BadRequestException('Thẻ Visa đã hết hạn.');
    }

    if (year === currentYear && month < currentMonth) {
      throw new BadRequestException('Thẻ Visa đã hết hạn.');
    }

    if (year > currentYear + 20) {
      throw new BadRequestException('Năm hết hạn không hợp lệ.');
    }
  }

  private isLuhnValid(cardNumber: string): boolean {
    let sum = 0;
    let shouldDouble = false;

    for (let i = cardNumber.length - 1; i >= 0; i -= 1) {
      let digit = Number(cardNumber[i]);
      if (Number.isNaN(digit)) {
        return false;
      }

      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      shouldDouble = !shouldDouble;
    }

    return sum % 10 === 0;
  }

  private encryptCardNumber(cardNumber: string) {
    const key = this.getEncryptionKey();
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', key, iv);

    const encrypted = Buffer.concat([
      cipher.update(cardNumber, 'utf8'),
      cipher.final(),
    ]);

    const authTag = cipher.getAuthTag();

    return {
      ciphertext: encrypted.toString('base64'),
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
    };
  }

  private getEncryptionKey(): CipherKey {
    if (this.encryptionKey) {
      return this.encryptionKey;
    }

    const raw = this.configService.get<string>('PAYMENT_DATA_ENCRYPTION_KEY');
    if (!raw) {
      throw new InternalServerErrorException(
        'PAYMENT_DATA_ENCRYPTION_KEY chưa được cấu hình.',
      );
    }

    const normalized = this.normalizeKey(raw);
    if (normalized.length !== 32) {
      throw new InternalServerErrorException(
        'PAYMENT_DATA_ENCRYPTION_KEY phải có độ dài 32 bytes (AES-256).',
      );
    }

    this.encryptionKey = normalized;
    return normalized;
  }

  private normalizeKey(raw: string): Buffer {
    const trimmed = raw.trim();

    if (/^[0-9a-fA-F]{64}$/u.test(trimmed)) {
      return Buffer.from(trimmed, 'hex');
    }

    try {
      const base64Decoded = Buffer.from(trimmed, 'base64');
      if (base64Decoded.length === 32) {
        return base64Decoded;
      }
    } catch (error) {
      this.logger.warn('Không thể giải mã khóa AES ở định dạng base64.');
    }

    const utf8Buffer = Buffer.from(trimmed, 'utf8');
    return utf8Buffer;
  }
}
