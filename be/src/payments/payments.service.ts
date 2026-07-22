import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import {
  PaymentAttemptStatus,
  PaymentGateway,
  Prisma,
  PurchaseStatus,
  TransactionStatus,
  PaymentType,
} from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { ChatService } from '../chat/chat.service';
import { ChatGateway } from '../chat/chat.gateway';
import { ContractsService } from '../contracts/contracts.service';
import { CreateVnpayPaymentDto } from './dto/create-vnpay-payment.dto';
import { CreateSepayPaymentDto } from './dto/create-sepay-payment.dto';

type VnpayQuery = Record<string, string | string[] | undefined>;

type NormalizedParams = Record<string, string>;

type TransactionWithPaymentRelations = Prisma.TransactionGetPayload<{
  include: {
    chatRoom: {
      select: {
        id: true;
        buyerId: true;
        sellerId: true;
      };
    };
    purchase: {
      select: {
        id: true;
        buyerId: true;
        status: true;
      };
    };
  };
}>;

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
    private readonly contractsService: ContractsService,
  ) {}

  async createVnpayPayment(
    dto: CreateVnpayPaymentDto,
    clientIp: string,
    currentUserId: string,
  ): Promise<{
    paymentUrl: string;
    paymentAttemptId: string;
    txnRef: string;
    amount: number;
    expireAt: string;
  }> {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: dto.transactionId },
      include: {
        chatRoom: {
          select: {
            buyerId: true,
            sellerId: true,
          },
        },
        purchase: {
          select: {
            buyerId: true,
          },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    const participantIds = new Set<string>([transaction.sellerId]);
    if (transaction.chatRoom?.buyerId) {
      participantIds.add(transaction.chatRoom.buyerId);
    }
    if (transaction.chatRoom?.sellerId) {
      participantIds.add(transaction.chatRoom.sellerId);
    }
    if (transaction.purchase?.buyerId) {
      participantIds.add(transaction.purchase.buyerId);
    }

    if (!participantIds.has(currentUserId)) {
      throw new ForbiddenException(
        'Bạn không có quyền tạo thanh toán cho giao dịch này.',
      );
    }

    const paymentType = dto.paymentType ?? PaymentType.FULL;

    this.validateTransactionStatusForPaymentType(
      transaction.status,
      paymentType,
    );

    const existingSuccessAttempt = await this.prisma.paymentAttempt.findFirst({
      where: {
        transactionId: transaction.id,
        gateway: PaymentGateway.VNPAY,
        status: PaymentAttemptStatus.SUCCESS,
        paymentType,
      },
    });

    if (existingSuccessAttempt) {
      throw new BadRequestException(
        'Giao dịch này đã có phiên thanh toán VNPay thành công cho loại thanh toán này.',
      );
    }

    const tmnCode = this.requireConfig('VNPAY_TMN_CODE');
    const hashSecret = this.requireConfig('VNPAY_HASH_SECRET');
    const basePaymentUrl =
      this.configService.get<string>('VNPAY_PAYMENT_URL') ??
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    const defaultReturnUrl = this.requireConfig('VNPAY_RETURN_URL');
    const locale = this.configService.get<string>('VNPAY_LOCALE') ?? 'vn';
    const orderType =
      this.configService.get<string>('VNPAY_DEFAULT_ORDER_TYPE') ?? 'other';

    let totalAmount = this.calculateTotalAmount(transaction);

    if (paymentType === PaymentType.DEPOSIT) {
      totalAmount = Math.round(totalAmount / 2);
    } else if (paymentType === PaymentType.BALANCE) {
      totalAmount = totalAmount - Math.round(totalAmount / 2); // 50% còn lại
    }

    if (totalAmount <= 0) {
      throw new BadRequestException('Số tiền giao dịch không hợp lệ.');
    }

    const txnRef = await this.generateUniqueTxnRef();
    const orderTypeStr =
      paymentType === PaymentType.DEPOSIT
        ? ' (Coc 50%)'
        : paymentType === PaymentType.BALANCE
          ? ' (Thanh toan not 50%)'
          : '';
    const orderInfo =
      (dto.orderInfo ?? `Thanh toan giao dich ${transaction.id}`) +
      orderTypeStr;
    const returnUrl = dto.returnUrl ?? defaultReturnUrl;

    const createDate = this.formatVnpayDate(new Date());
    const expireDate = this.addMinutes(new Date(), 15);
    const expireDateFormatted = this.formatVnpayDate(expireDate);

    const baseParams: NormalizedParams = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: tmnCode,
      vnp_Amount: String(Math.round(totalAmount * 100)),
      vnp_CurrCode: 'VND',
      vnp_TxnRef: txnRef,
      vnp_OrderInfo: orderInfo,
      vnp_OrderType: orderType,
      vnp_ReturnUrl: returnUrl,
      vnp_IpAddr: clientIp,
      vnp_CreateDate: createDate,
      vnp_ExpireDate: expireDateFormatted,
      vnp_Locale: locale,
    };

    if (dto.bankCode) {
      baseParams.vnp_BankCode = dto.bankCode;
    }

    const sortedParams = this.sortParams(baseParams);
    const signData = this.buildQueryString(sortedParams);
    const secureHash = this.sign(signData, hashSecret);

    const paymentUrl = `${basePaymentUrl}?${signData}&vnp_SecureHash=${secureHash}`;

    const attempt = await this.prisma.paymentAttempt.create({
      data: {
        transactionId: transaction.id,
        gateway: PaymentGateway.VNPAY,
        status: PaymentAttemptStatus.PENDING,
        amount: new Prisma.Decimal(totalAmount),
        bankCode: dto.bankCode ?? null,
        orderInfo,
        txnRef,
        payUrl: paymentUrl,
        ipAddress: clientIp || null,
        vnpSecureHash: secureHash,
        vnpParams: sortedParams,
        paymentType,
      },
    });

    return {
      paymentUrl,
      paymentAttemptId: attempt.id,
      txnRef,
      amount: totalAmount,
      expireAt: expireDate.toISOString(),
    };
  }

  async handleVnpayReturn(query: VnpayQuery) {
    const result = await this.processVnpayCallback(query, 'return');
    return {
      success: result.success,
      transactionId: result.transactionId,
      paymentAttemptId: result.paymentAttemptId,
      responseCode: result.responseCode,
      message: result.message,
    };
  }

  async handleVnpayIpn(query: VnpayQuery) {
    try {
      const result = await this.processVnpayCallback(query, 'ipn');
      return {
        RspCode: result.success ? '00' : '01',
        Message: result.message,
      };
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Internal server error';
      return {
        RspCode: '97',
        Message: message,
      };
    }
  }

  private async processVnpayCallback(
    query: VnpayQuery,
    source: 'return' | 'ipn',
  ): Promise<{
    success: boolean;
    transactionId: string;
    paymentAttemptId: string;
    responseCode: string | null;
    message: string;
  }> {
    const hashSecret = this.requireConfig('VNPAY_HASH_SECRET');
    const normalized = this.normalizeParams(query);

    const receivedHash = normalized.vnp_SecureHash;
    if (!receivedHash) {
      throw new BadRequestException('Thiếu chữ ký xác thực VNPay.');
    }

    const { vnp_SecureHash, vnp_SecureHashType, ...dataForHash } = normalized;
    const sorted = this.sortParams(dataForHash);
    const signData = this.buildQueryString(sorted);
    const expectedHash = this.sign(signData, hashSecret);

    if (receivedHash.toUpperCase() !== expectedHash.toUpperCase()) {
      throw new BadRequestException('Chữ ký VNPay không hợp lệ.');
    }

    const txnRef = sorted.vnp_TxnRef;
    if (!txnRef) {
      throw new BadRequestException('Thiếu mã giao dịch VNPay.');
    }

    const attempt = await this.prisma.paymentAttempt.findUnique({
      where: { txnRef },
      include: {
        transaction: {
          include: {
            chatRoom: {
              select: {
                id: true,
                buyerId: true,
                sellerId: true,
              },
            },
            purchase: {
              select: {
                id: true,
                buyerId: true,
                status: true,
              },
            },
          },
        },
      },
    });

    if (!attempt) {
      throw new NotFoundException('Không tìm thấy phiên thanh toán.');
    }

    const responseCode =
      sorted.vnp_ResponseCode ?? sorted.vnp_TransactionStatus ?? null;
    const isSuccess = responseCode === '00';

    const alreadyFinal =
      attempt.status === PaymentAttemptStatus.SUCCESS ||
      attempt.status === PaymentAttemptStatus.FAILED;

    let completedTransaction: TransactionWithPaymentRelations | null = null;

    if (!alreadyFinal) {
      await this.prisma.paymentAttempt.update({
        where: { id: attempt.id },
        data: {
          status: isSuccess
            ? PaymentAttemptStatus.SUCCESS
            : PaymentAttemptStatus.FAILED,
          responseCode,
          callbackAt: new Date(),
          vnpSecureHash: receivedHash,
          vnpParams: sorted,
        },
      });

      if (isSuccess) {
        let nextStatus: TransactionStatus = TransactionStatus.COMPLETED;
        if (attempt.paymentType === PaymentType.DEPOSIT) {
          nextStatus = TransactionStatus.DEPOSIT_PAID;
        }

        completedTransaction = await this.prisma.transaction.update({
          where: { id: attempt.transactionId },
          data: {
            status: nextStatus,
            paymentMethod: 'VNPAY',
          },
          include: {
            chatRoom: {
              select: {
                id: true,
                buyerId: true,
                sellerId: true,
              },
            },
            purchase: {
              select: {
                id: true,
                buyerId: true,
                status: true,
              },
            },
          },
        });

        if (completedTransaction.purchase) {
          const { id: purchaseId, status } = completedTransaction.purchase;
          if (status !== PurchaseStatus.CONFIRMED) {
            const refreshedPurchase = await this.prisma.purchase.update({
              where: { id: purchaseId },
              data: { status: PurchaseStatus.CONFIRMED },
              select: {
                id: true,
                buyerId: true,
                status: true,
              },
            });
            completedTransaction = {
              ...completedTransaction,
              purchase: refreshedPurchase,
            };
          }
        }

        if (completedTransaction) {
          await this.notifyPaymentSuccess(
            completedTransaction,
            attempt.id,
            attempt.amount,
            attempt.paymentType,
          );

          if (attempt.paymentType === PaymentType.DEPOSIT) {
            await this.contractsService.handleTransactionCompleted(
              completedTransaction.id,
            );
          }
        }
      }
    }

    const message = isSuccess
      ? 'Thanh toán thành công.'
      : 'Thanh toán không thành công.';

    return {
      success: isSuccess,
      transactionId: attempt.transactionId,
      paymentAttemptId: attempt.id,
      responseCode,
      message,
    };
  }

  private async notifyPaymentSuccess(
    transaction: TransactionWithPaymentRelations,
    paymentAttemptId: string,
    amount: Prisma.Decimal | number,
    paymentType: PaymentType,
  ) {
    const chatRoom = transaction.chatRoom;
    if (!chatRoom || !chatRoom.id || !chatRoom.buyerId) {
      return;
    }

    const numericAmount =
      this.toPlainNumber(amount) ?? this.calculateTotalAmount(transaction);

    try {
      const typeLabel =
        paymentType === PaymentType.DEPOSIT
          ? 'đặt cọc 50%'
          : paymentType === PaymentType.BALANCE
            ? 'thanh toán nốt 50%'
            : 'thanh toán';
      const message = await this.chatService.createMessage({
        roomId: chatRoom.id,
        senderId: chatRoom.buyerId,
        content: `Người mua đã ${typeLabel} thành công qua VNPay.`,
        metadata: {
          kind: 'payment-status',
          gateway: 'vnpay',
          status: 'success',
          transactionId: transaction.id,
          paymentAttemptId,
          amount: numericAmount,
          buyerId: chatRoom.buyerId,
          sellerId: chatRoom.sellerId,
        },
      });

      this.emitChatMessage(chatRoom.id, message);
    } catch (error) {
      const reason =
        error instanceof Error ? error.message : String(error ?? 'unknown');
      this.logger.error(
        `Không thể gửi thông báo thanh toán cho giao dịch ${transaction.id}: ${reason}`,
      );
    }
  }

  private emitChatMessage(roomId: string, payload: unknown) {
    const server = this.chatGateway?.server;
    if (!server) {
      return;
    }

    server.to(roomId).emit('chat:message', payload);
  }

  private validateTransactionStatusForPaymentType(
    status: TransactionStatus,
    paymentType: PaymentType,
  ) {
    if (status === TransactionStatus.COMPLETED) {
      throw new BadRequestException('Giao dịch này đã được thanh toán.');
    }

    if (paymentType === PaymentType.DEPOSIT) {
      if (
        status !== TransactionStatus.PENDING &&
        status !== TransactionStatus.AWAITING_DEPOSIT
      ) {
        throw new BadRequestException(
          'Giao dịch không ở trạng thái chờ đặt cọc.',
        );
      }
      return;
    }

    if (paymentType === PaymentType.BALANCE) {
      if (status !== TransactionStatus.AWAITING_BALANCE) {
        throw new BadRequestException(
          'Giao dịch không ở trạng thái chờ thanh toán phần còn lại.',
        );
      }
      return;
    }

    if (paymentType === PaymentType.FULL) {
      if (
        status !== TransactionStatus.PENDING &&
        status !== TransactionStatus.AWAITING_DEPOSIT
      ) {
        throw new BadRequestException(
          'Giao dịch không ở trạng thái chờ thanh toán toàn bộ.',
        );
      }
    }
  }

  private calculateTotalAmount(transaction: {
    amount: Prisma.Decimal | number;
    fee?: Prisma.Decimal | number | null;
    commission?: Prisma.Decimal | number | null;
  }): number {
    const values = [
      transaction.amount,
      transaction.fee,
      transaction.commission,
    ];
    return values.reduce<number>((sum, value) => {
      const numeric = this.toPlainNumber(value);
      return sum + (numeric ?? 0);
    }, 0);
  }

  private toPlainNumber(
    value: Prisma.Decimal | number | null | undefined,
  ): number | null {
    if (value === null || value === undefined) {
      return null;
    }

    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : null;
    }

    const candidate = value as Prisma.Decimal & { toNumber?: () => number };
    if (typeof candidate.toNumber === 'function') {
      return candidate.toNumber();
    }

    return Number(value);
  }

  private requireConfig(key: string): string {
    const value = this.configService.get<string>(key);
    if (!value) {
      throw new InternalServerErrorException(`Thiếu cấu hình bắt buộc: ${key}`);
    }
    return value;
  }

  private async generateUniqueTxnRef(): Promise<string> {
    for (let i = 0; i < 5; i += 1) {
      const candidate = this.buildTxnRefCandidate();
      const existing = await this.prisma.paymentAttempt.findUnique({
        where: { txnRef: candidate },
      });
      if (!existing) {
        return candidate;
      }
    }

    throw new InternalServerErrorException(
      'Không thể tạo mã giao dịch VNPay duy nhất.',
    );
  }

  private buildTxnRefCandidate(): string {
    const now = new Date();
    const timestamp = this.formatVnpayDate(now).slice(-12);
    const random = Math.floor(Math.random() * 1000)
      .toString()
      .padStart(3, '0');
    return `${timestamp}${random}`.slice(0, 20);
  }

  private formatVnpayDate(date: Date): string {
    const vnOffsetMinutes = 7 * 60;
    const utc = date.getTime() + date.getTimezoneOffset() * 60000;
    const vnTime = new Date(utc + vnOffsetMinutes * 60000);

    const year = vnTime.getFullYear();
    const month = this.pad(vnTime.getMonth() + 1);
    const day = this.pad(vnTime.getDate());
    const hours = this.pad(vnTime.getHours());
    const minutes = this.pad(vnTime.getMinutes());
    const seconds = this.pad(vnTime.getSeconds());

    return `${year}${month}${day}${hours}${minutes}${seconds}`;
  }

  private addMinutes(date: Date, minutes: number): Date {
    return new Date(date.getTime() + minutes * 60 * 1000);
  }

  private pad(value: number): string {
    return value.toString().padStart(2, '0');
  }

  private sortParams(params: NormalizedParams): NormalizedParams {
    return Object.keys(params)
      .sort()
      .reduce<NormalizedParams>((acc, key) => {
        acc[key] = params[key];
        return acc;
      }, {} as NormalizedParams);
  }

  private normalizeParams(query: VnpayQuery): NormalizedParams {
    return Object.entries(query).reduce<NormalizedParams>(
      (acc, [key, value]) => {
        if (value === undefined || value === null) {
          return acc;
        }

        if (Array.isArray(value)) {
          acc[key] = value[0];
        } else {
          acc[key] = String(value);
        }
        return acc;
      },
      {} as NormalizedParams,
    );
  }

  private buildQueryString(params: NormalizedParams): string {
    return Object.entries(params)
      .map(
        ([key, value]) =>
          `${encodeURIComponent(key)}=${encodeURIComponent(value)}`,
      )
      .join('&');
  }

  private sign(data: string, secret: string): string {
    return createHmac('sha512', secret)
      .update(data, 'utf8')
      .digest('hex')
      .toUpperCase();
  }

  // ─────────────────────────── SePay ───────────────────────────

  async createSepayPayment(
    dto: CreateSepayPaymentDto,
    currentUserId: string,
  ): Promise<{
    qrUrl: string;
    transferContent: string;
    amount: number;
    bankAccountNumber: string;
    bankAccountName: string;
    bankName: string;
    paymentAttemptId: string;
    expireAt: string;
  }> {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: dto.transactionId },
      include: {
        chatRoom: { select: { buyerId: true, sellerId: true } },
        purchase: { select: { buyerId: true } },
      },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch');
    }

    // Authorization check
    const participantIds = new Set<string>([transaction.sellerId]);
    if (transaction.chatRoom?.buyerId)
      participantIds.add(transaction.chatRoom.buyerId);
    if (transaction.chatRoom?.sellerId)
      participantIds.add(transaction.chatRoom.sellerId);
    if (transaction.purchase?.buyerId)
      participantIds.add(transaction.purchase.buyerId);

    if (!participantIds.has(currentUserId)) {
      throw new ForbiddenException(
        'Bạn không có quyền tạo thanh toán cho giao dịch này.',
      );
    }

    const paymentType = dto.paymentType ?? PaymentType.FULL;
    this.validateTransactionStatusForPaymentType(transaction.status, paymentType);

    // Check duplicate success attempt
    const existingSuccess = await this.prisma.paymentAttempt.findFirst({
      where: {
        transactionId: transaction.id,
        gateway: PaymentGateway.SEPAY,
        status: PaymentAttemptStatus.SUCCESS,
        paymentType,
      },
    });
    if (existingSuccess) {
      throw new BadRequestException(
        'Giao dịch này đã có phiên thanh toán SePay thành công cho loại thanh toán này.',
      );
    }

    // Calculate amount
    let totalAmount = this.calculateTotalAmount(transaction);
    if (paymentType === PaymentType.DEPOSIT) {
      totalAmount = Math.round(totalAmount / 2);
    } else if (paymentType === PaymentType.BALANCE) {
      totalAmount = totalAmount - Math.round(totalAmount / 2);
    }
    if (totalAmount <= 0) {
      throw new BadRequestException('Số tiền giao dịch không hợp lệ.');
    }

    // SePay config
    const merchantId =
      this.configService.get<string>('SEPAY_MERCHANT_ID') ?? 'SP-TEST-HMA24444';

    // Bank info (configurable, fallback to demo MB Bank)
    const bankAccountNumber =
      this.configService.get<string>('SEPAY_BANK_ACCOUNT_NUMBER') ??
      '0001234567890';
    const bankAccountName =
      this.configService.get<string>('SEPAY_BANK_ACCOUNT_NAME') ??
      'NGUYEN VAN A';
    const bankBin =
      this.configService.get<string>('SEPAY_BANK_BIN') ?? '970422'; // MB Bank
    const bankName =
      this.configService.get<string>('SEPAY_BANK_NAME') ?? 'MB Bank';

    // Generate unique transfer content
    const shortId = transaction.id.replace(/-/g, '').substring(0, 10).toUpperCase();
    const transferContent = `EVNPAY${shortId}`;

    // VietQR URL (SePay QR image)
    const qrUrl =
      `https://qr.sepay.vn/img` +
      `?bank=${bankBin}` +
      `&acc=${bankAccountNumber}` +
      `&template=compact` +
      `&amount=${Math.round(totalAmount)}` +
      `&des=${encodeURIComponent(transferContent)}`;

    const expireAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    const txnRef = `SP${Date.now()}${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`;

    const attempt = await this.prisma.paymentAttempt.create({
      data: {
        transactionId: transaction.id,
        gateway: PaymentGateway.SEPAY,
        status: PaymentAttemptStatus.PENDING,
        amount: new Prisma.Decimal(totalAmount),
        orderInfo: transferContent,
        txnRef,
        payUrl: qrUrl,
        paymentType,
        vnpParams: {
          merchantId,
          transferContent,
          bankAccountNumber,
          bankAccountName,
          bankBin,
          bankName,
          expireAt: expireAt.toISOString(),
        },
      },
    });

    return {
      qrUrl,
      transferContent,
      amount: totalAmount,
      bankAccountNumber,
      bankAccountName,
      bankName,
      paymentAttemptId: attempt.id,
      expireAt: expireAt.toISOString(),
    };
  }

  async handleSepayWebhook(
    body: Record<string, unknown>,
    apiKey: string,
  ): Promise<{ success: boolean; message: string }> {
    // Validate API key
    const secretKey =
      this.configService.get<string>('SEPAY_SECRET_KEY') ?? '';
    if (apiKey !== secretKey) {
      throw new UnauthorizedException('Invalid SePay API key.');
    }

    /*
     * SePay webhook body format:
     * {
     *   id: number,
     *   content: string,   // nội dung chuyển khoản
     *   transferAmount: number,
     *   transferType: 'in' | 'out',
     *   ...
     * }
     */
    const content = String(body['content'] ?? '');
    const transferAmount = Number(body['transferAmount'] ?? 0);
    const transferType = String(body['transferType'] ?? '');

    // Only process incoming transfers
    if (transferType !== 'in') {
      return { success: false, message: 'Bỏ qua giao dịch không phải chuyển tiền vào.' };
    }

    // Find pending payment attempt matching transfer content
    const attempt = await this.prisma.paymentAttempt.findFirst({
      where: {
        gateway: PaymentGateway.SEPAY,
        status: PaymentAttemptStatus.PENDING,
        orderInfo: content,
      },
      include: {
        transaction: {
          include: {
            chatRoom: { select: { id: true, buyerId: true, sellerId: true } },
            purchase: { select: { id: true, buyerId: true, status: true } },
          },
        },
      },
    });

    if (!attempt) {
      this.logger.warn(`SePay webhook: no pending attempt for content "${content}"`);
      return { success: false, message: 'Không tìm thấy phiên thanh toán khớp.' };
    }

    // Amount tolerance check (±1000 VND)
    const expectedAmount = Number(attempt.amount);
    if (Math.abs(transferAmount - expectedAmount) > 1000) {
      this.logger.warn(
        `SePay webhook: amount mismatch. Expected ${expectedAmount}, got ${transferAmount}`,
      );
      return { success: false, message: 'Số tiền không khớp.' };
    }

    // Mark attempt success
    await this.prisma.paymentAttempt.update({
      where: { id: attempt.id },
      data: {
        status: PaymentAttemptStatus.SUCCESS,
        responseCode: '00',
        callbackAt: new Date(),
        vnpParams: {
          ...(attempt.vnpParams as Record<string, unknown>),
          webhookBody: body,
        } as Prisma.InputJsonValue,
      },
    });

    // Update transaction status
    let nextStatus: TransactionStatus = TransactionStatus.COMPLETED;
    if (attempt.paymentType === PaymentType.DEPOSIT) {
      nextStatus = TransactionStatus.DEPOSIT_PAID;
    }

    const completedTransaction = await this.prisma.transaction.update({
      where: { id: attempt.transactionId },
      data: {
        status: nextStatus,
        paymentMethod: 'SEPAY',
      },
      include: {
        chatRoom: { select: { id: true, buyerId: true, sellerId: true } },
        purchase: { select: { id: true, buyerId: true, status: true } },
      },
    });

    // Update purchase status
    if (completedTransaction.purchase) {
      const { id: purchaseId, status } = completedTransaction.purchase;
      if (status !== PurchaseStatus.CONFIRMED) {
        await this.prisma.purchase.update({
          where: { id: purchaseId },
          data: { status: PurchaseStatus.CONFIRMED },
        });
      }
    }

    // Notify via chat
    await this.notifySepaySuccess(completedTransaction, attempt.id, attempt.amount, attempt.paymentType);

    // Trigger contract flow for deposit
    if (attempt.paymentType === PaymentType.DEPOSIT) {
      await this.contractsService.handleTransactionCompleted(completedTransaction.id);
    }

    return { success: true, message: 'Thanh toán SePay được xử lý thành công.' };
  }

  async getSepayPaymentStatus(attemptId: string): Promise<{
    status: string;
    transactionId: string;
    amount: number;
    paymentType: string;
  }> {
    const attempt = await this.prisma.paymentAttempt.findUnique({
      where: { id: attemptId },
    });

    if (!attempt || attempt.gateway !== PaymentGateway.SEPAY) {
      throw new NotFoundException('Không tìm thấy phiên thanh toán SePay.');
    }

    return {
      status: attempt.status,
      transactionId: attempt.transactionId,
      amount: Number(attempt.amount),
      paymentType: attempt.paymentType,
    };
  }

  async simulateSepayPayment(
    attemptId: string,
    targetStatus: 'SUCCESS' | 'FAILED',
  ): Promise<{ success: boolean; status: string; message: string }> {
    const attempt = await this.prisma.paymentAttempt.findUnique({
      where: { id: attemptId },
      include: {
        transaction: {
          include: {
            chatRoom: { select: { id: true, buyerId: true, sellerId: true } },
            purchase: { select: { id: true, buyerId: true, status: true } },
          },
        },
      },
    });

    if (!attempt || attempt.gateway !== PaymentGateway.SEPAY) {
      throw new NotFoundException('Không tìm thấy phiên thanh toán SePay.');
    }

    if (targetStatus === 'FAILED') {
      await this.prisma.paymentAttempt.update({
        where: { id: attemptId },
        data: {
          status: PaymentAttemptStatus.FAILED,
          responseCode: 'SIMULATED_FAILED',
          callbackAt: new Date(),
        },
      });
      return { success: true, status: 'FAILED', message: 'Đã giả lập thanh toán thất bại.' };
    }

    // SUCCESS
    await this.prisma.paymentAttempt.update({
      where: { id: attemptId },
      data: {
        status: PaymentAttemptStatus.SUCCESS,
        responseCode: '00',
        callbackAt: new Date(),
      },
    });

    let nextStatus: TransactionStatus = TransactionStatus.COMPLETED;
    if (attempt.paymentType === PaymentType.DEPOSIT) {
      nextStatus = TransactionStatus.DEPOSIT_PAID;
    }

    const completedTransaction = await this.prisma.transaction.update({
      where: { id: attempt.transactionId },
      data: {
        status: nextStatus,
        paymentMethod: 'SEPAY',
      },
      include: {
        chatRoom: { select: { id: true, buyerId: true, sellerId: true } },
        purchase: { select: { id: true, buyerId: true, status: true } },
      },
    });

    if (completedTransaction.purchase) {
      const { id: purchaseId, status } = completedTransaction.purchase;
      if (status !== PurchaseStatus.CONFIRMED) {
        await this.prisma.purchase.update({
          where: { id: purchaseId },
          data: { status: PurchaseStatus.CONFIRMED },
        });
      }
    }

    await this.notifySepaySuccess(completedTransaction, attempt.id, attempt.amount, attempt.paymentType);

    if (attempt.paymentType === PaymentType.DEPOSIT) {
      await this.contractsService.handleTransactionCompleted(completedTransaction.id);
    }

    return { success: true, status: 'SUCCESS', message: 'Đã giả lập thanh toán thành công!' };
  }

  private async notifySepaySuccess(
    transaction: TransactionWithPaymentRelations,
    paymentAttemptId: string,
    amount: Prisma.Decimal | number,
    paymentType: PaymentType,
  ) {
    const chatRoom = transaction.chatRoom;
    if (!chatRoom?.id || !chatRoom.buyerId) return;

    const numericAmount =
      this.toPlainNumber(amount) ?? this.calculateTotalAmount(transaction);
    const typeLabel =
      paymentType === PaymentType.DEPOSIT
        ? 'đặt cọc 50%'
        : paymentType === PaymentType.BALANCE
          ? 'thanh toán nốt 50%'
          : 'thanh toán';

    try {
      const message = await this.chatService.createMessage({
        roomId: chatRoom.id,
        senderId: chatRoom.buyerId,
        content: `Người mua đã ${typeLabel} thành công qua SePay (chuyển khoản ngân hàng).`,
        metadata: {
          kind: 'payment-status',
          gateway: 'sepay',
          status: 'success',
          transactionId: transaction.id,
          paymentAttemptId,
          amount: numericAmount,
          buyerId: chatRoom.buyerId,
          sellerId: chatRoom.sellerId,
        },
      });
      this.emitChatMessage(chatRoom.id, message);
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error ?? 'unknown');
      this.logger.error(
        `Không thể gửi thông báo SePay cho giao dịch ${transaction.id}: ${reason}`,
      );
    }
  }
}
