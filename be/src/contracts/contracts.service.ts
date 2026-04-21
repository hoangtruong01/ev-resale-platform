import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ContractPartyRole,
  ContractStatus,
  Prisma,
  UserRole,
  TransactionStatus,
} from '@prisma/client';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import { promises as fs } from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { SignContractDto } from './dto';

const contractDetailInclude = {
  transaction: {
    include: {
      seller: {
        select: {
          id: true,
          fullName: true,
          email: true,
          phone: true,
        },
      },
      purchase: {
        include: {
          buyer: {
            select: {
              id: true,
              fullName: true,
              email: true,
              phone: true,
              address: true,
            },
          },
        },
      },
      chatRoom: {
        include: {
          buyer: {
            select: {
              id: true,
              fullName: true,
              email: true,
              phone: true,
              address: true,
            },
          },
        },
      },
      vehicle: {
        select: {
          id: true,
          name: true,
        },
      },
      battery: {
        select: {
          id: true,
          name: true,
        },
      },
    },
  },
  signatures: true,
} as const;

type ContractDetail = Prisma.ContractGetPayload<{
  include: typeof contractDetailInclude;
}>;

type ContractSignatureInput = {
  buffer: Buffer;
  extension: '.png' | '.jpg';
  mime: string;
};

@Injectable()
export class ContractsService {
  private readonly logger = new Logger(ContractsService.name);
  private readonly uploadsRoot = path.join(process.cwd(), 'uploads');
  private readonly contractsRoot = path.join(this.uploadsRoot, 'contracts');
  private readonly signaturesDir = path.join(this.contractsRoot, 'signatures');
  private readonly finalDir = path.join(this.contractsRoot, 'final');

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
    private readonly configService: ConfigService,
  ) {}

  async handleTransactionCompleted(transactionId: string) {
    try {
      const contract = await this.ensureContractForTransaction(transactionId);
      if (!contract.requestEmailSentAt) {
        await this.sendSignatureRequests(contract.id);
      }
    } catch (error) {
      const reason =
        error instanceof Error ? error.message : String(error ?? 'unknown');
      this.logger.error(
        `Failed to initialize contract for transaction ${transactionId}: ${reason}`,
        error instanceof Error ? error.stack : undefined,
      );
    }
  }

  async getContractForUser(
    transactionId: string,
    userId: string,
    userRole: UserRole,
  ) {
    const contract = await this.prisma.contract.findUnique({
      where: { transactionId },
      include: contractDetailInclude,
    });

    if (!contract) {
      throw new NotFoundException('Không tìm thấy hợp đồng cho giao dịch này.');
    }

    const buyer = this.extractBuyer(contract);
    const isBuyer = buyer?.id === userId;
    const isSeller = contract.transaction.seller.id === userId;

    if (!isBuyer && !isSeller && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('Bạn không có quyền xem hợp đồng này.');
    }

    return this.mapContractResponse(contract);
  }

  async signContract(
    transactionId: string,
    userId: string,
    userRole: UserRole,
    payload: SignContractDto,
  ) {
    const contract = await this.prisma.contract.findUnique({
      where: { transactionId },
      include: contractDetailInclude,
    });

    if (!contract) {
      throw new NotFoundException('Không tìm thấy hợp đồng cho giao dịch này.');
    }

    if (contract.status === ContractStatus.COMPLETED) {
      throw new BadRequestException('Hợp đồng đã được ký xong.');
    }

    const buyer = this.extractBuyer(contract);
    const now = new Date();

    let role: ContractPartyRole | null = null;
    if (buyer?.id === userId) {
      role = ContractPartyRole.BUYER;
    } else if (contract.transaction.seller.id === userId) {
      role = ContractPartyRole.SELLER;
    } else if (userRole === UserRole.ADMIN) {
      throw new ForbiddenException(
        'Quản trị viên không thể ký thay cho các bên.',
      );
    } else {
      throw new ForbiddenException('Bạn không có quyền ký hợp đồng này.');
    }

    if (role === ContractPartyRole.BUYER && contract.buyerSignedAt) {
      throw new BadRequestException('Người mua đã ký hợp đồng.');
    }

    if (role === ContractPartyRole.SELLER && contract.sellerSignedAt) {
      throw new BadRequestException('Người bán đã ký hợp đồng.');
    }

    const signatureInput = this.extractSignature(payload.signatureData);
    const signaturePath = await this.storeSignature(
      contract.id,
      role,
      signatureInput,
    );

    await this.prisma.contractSignature.upsert({
      where: {
        contractId_role: {
          contractId: contract.id,
          role,
        },
      },
      create: {
        contractId: contract.id,
        userId,
        role,
        signaturePath,
      },
      update: {
        userId,
        signaturePath,
        signedAt: now,
      },
    });

    const updateData: Prisma.ContractUpdateInput = {};
    let nextStatus: ContractStatus = contract.status;

    if (role === ContractPartyRole.BUYER) {
      updateData.buyerSignedAt = now;
      nextStatus = contract.sellerSignedAt
        ? ContractStatus.COMPLETED
        : ContractStatus.BUYER_SIGNED;
    } else {
      updateData.sellerSignedAt = now;
      nextStatus = contract.buyerSignedAt
        ? ContractStatus.COMPLETED
        : ContractStatus.SELLER_SIGNED;
    }

    updateData.status = nextStatus;
    if (nextStatus === ContractStatus.COMPLETED) {
      updateData.completedAt = now;
    }

    if (
      contract.transaction.status !== TransactionStatus.DEPOSIT_PAID &&
      contract.transaction.status !== TransactionStatus.CONTRACT_SIGNED && // Allow if already partially signed
      contract.transaction.status !== TransactionStatus.AWAITING_BALANCE // Allow if already completed signing (idempotency)
    ) {
      throw new BadRequestException(
        'Bạn chỉ có thể ký hợp đồng sau khi đã thanh toán tiền cọc.',
      );
    }

    const updated = await this.prisma.contract.update({
      where: { id: contract.id },
      data: updateData,
      include: contractDetailInclude,
    });

    if (nextStatus === ContractStatus.COMPLETED) {
      await this.prisma.transaction.update({
        where: { id: contract.transactionId },
        data: { status: TransactionStatus.AWAITING_BALANCE },
      });
      await this.generateAndSendFinalContract(updated);
    }

    return this.mapContractResponse(updated);
  }

  async listContractsForAdmin(userRole: UserRole, status?: string) {
    if (userRole !== UserRole.ADMIN) {
      throw new ForbiddenException(
        'Chỉ quản trị viên mới được truy cập danh sách hợp đồng.',
      );
    }

    const normalizedStatus = this.normalizeStatus(status);

    const contracts = await this.prisma.contract.findMany({
      where: normalizedStatus ? { status: normalizedStatus } : undefined,
      orderBy: { createdAt: 'desc' },
      include: contractDetailInclude,
    });

    return contracts.map((item) => this.mapContractResponse(item));
  }

  private async ensureContractForTransaction(transactionId: string) {
    const existing = await this.prisma.contract.findUnique({
      where: { transactionId },
    });

    if (existing) {
      return existing;
    }

    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
      include: {
        seller: {
          select: {
            id: true,
            fullName: true,
            email: true,
          },
        },
        purchase: {
          include: {
            buyer: {
              select: {
                id: true,
                fullName: true,
                email: true,
              },
            },
          },
        },
        chatRoom: {
          include: {
            buyer: {
              select: {
                id: true,
                fullName: true,
                email: true,
              },
            },
          },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundException('Không tìm thấy giao dịch để tạo hợp đồng.');
    }

    const buyer =
      transaction.purchase?.buyer ?? transaction.chatRoom?.buyer ?? null;

    if (!buyer) {
      throw new BadRequestException(
        'Giao dịch chưa có thông tin người mua để tạo hợp đồng.',
      );
    }

    const templatePath = this.resolveTemplatePath();

    return this.prisma.contract.create({
      data: {
        transactionId,
        buyerId: buyer.id,
        sellerId: transaction.seller.id,
        templatePath,
      },
    });
  }

  private async sendSignatureRequests(contractId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
      include: contractDetailInclude,
    });

    if (!contract) {
      throw new NotFoundException('Không tìm thấy hợp đồng để gửi yêu cầu ký.');
    }

    const buyer = this.extractBuyer(contract);
    const seller = contract.transaction.seller;

    if (!buyer || !buyer.email) {
      this.logger.warn(
        `Skipping buyer signature email for contract ${contract.id} because buyer email is missing.`,
      );
    }

    if (!seller.email) {
      this.logger.warn(
        `Skipping seller signature email for contract ${contract.id} because seller email is missing.`,
      );
    }

    const signUrl = this.buildSigningUrl(contract.transactionId);
    const subject = 'Yêu cầu ký hợp đồng giao dịch EVN';
    const assetDescription = this.buildAssetDescription(contract);

    const template = (displayName: string) => `
      <p>Chào ${displayName},</p>
      <p>Giao dịch của bạn ${assetDescription} đã được thanh toán. Vui lòng ký hợp đồng để hoàn tất.</p>
      ${signUrl ? `<p>Bạn có thể ký hợp đồng tại: <a href="${signUrl}">${signUrl}</a></p>` : '<p>Vui lòng đăng nhập vào hệ thống để ký hợp đồng.</p>'}
      <p>Trân trọng,<br/>EVN Marketplace</p>
    `;

    const tasks: Promise<unknown>[] = [];

    if (buyer?.email) {
      tasks.push(
        this.mailService.sendMail({
          to: buyer.email,
          subject,
          html: template(buyer.fullName ?? 'Quý khách'),
        }),
      );
    }

    if (seller.email) {
      tasks.push(
        this.mailService.sendMail({
          to: seller.email,
          subject,
          html: template(seller.fullName ?? 'Quý khách'),
        }),
      );
    }

    if (tasks.length > 0) {
      try {
        await Promise.all(tasks);
        await this.prisma.contract.update({
          where: { id: contract.id },
          data: { requestEmailSentAt: new Date() },
        });
      } catch (error) {
        const message =
          error instanceof Error ? error.message : String(error ?? 'unknown');
        this.logger.error(
          `Không thể gửi email yêu cầu ký hợp đồng ${contract.id}: ${message}`,
        );
      }
    }
  }

  private async generateAndSendFinalContract(contract: ContractDetail) {
    const buyer = this.extractBuyer(contract);
    const seller = contract.transaction.seller;

    if (!buyer || !buyer.email) {
      this.logger.warn(
        `Contract ${contract.id} completed but buyer email is missing.`,
      );
    }

    if (!seller.email) {
      this.logger.warn(
        `Contract ${contract.id} completed but seller email is missing.`,
      );
    }

    const pdfBuffer = await this.buildFinalPdf(contract);
    const targetDir = path.join(this.finalDir, contract.transactionId);
    await this.ensureDir(targetDir);

    const filename = `hop-dong-${contract.transactionId}.pdf`;
    const absolutePath = path.join(targetDir, filename);
    await fs.writeFile(absolutePath, pdfBuffer);

    const relativePath = this.toRelativePath(absolutePath);
    await this.prisma.contract.update({
      where: { id: contract.id },
      data: {
        finalPdfPath: relativePath,
      },
    });

    const attachments = [
      {
        filename,
        path: absolutePath,
      },
    ];

    const subject = 'Hợp đồng giao dịch EVN đã hoàn tất';
    const assetDescription = this.buildAssetDescription(contract);
    const htmlContent = (displayName: string) => `
      <p>Chào ${displayName},</p>
      <p>Hợp đồng giao dịch ${assetDescription} đã được cả hai bên ký xác nhận.</p>
      <p>Bản hợp đồng có chữ ký đã được đính kèm theo email này.</p>
      <p>Trân trọng,<br/>EVN Marketplace</p>
    `;

    const tasks: Promise<unknown>[] = [];

    if (buyer?.email && !contract.finalEmailSentAt) {
      tasks.push(
        this.mailService.sendMail({
          to: buyer.email,
          subject,
          html: htmlContent(buyer.fullName ?? 'Quý khách'),
          attachments,
        }),
      );
    }

    if (seller.email && !contract.finalEmailSentAt) {
      tasks.push(
        this.mailService.sendMail({
          to: seller.email,
          subject,
          html: htmlContent(seller.fullName ?? 'Quý khách'),
          attachments,
        }),
      );
    }

    if (tasks.length > 0) {
      try {
        await Promise.all(tasks);
        await this.prisma.contract.update({
          where: { id: contract.id },
          data: { finalEmailSentAt: new Date() },
        });
      } catch (error) {
        const reason =
          error instanceof Error ? error.message : String(error ?? 'unknown');
        this.logger.error(
          `Không thể gửi hợp đồng hoàn tất ${contract.id}: ${reason}`,
        );
      }
    }
  }

  private async buildFinalPdf(contract: ContractDetail) {
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage([595.28, 841.89]); // A4
    const { width, height } = page.getSize();

    // Embed font
    const fontRegular = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    // 1. Header with styling
    page.drawRectangle({
      x: 0,
      y: height - 60,
      width,
      height: 60,
      color: rgb(0.1, 0.45, 0.25), // Primary Green
    });

    page.drawText('EVN BATTERY MARKETPLACE', {
      x: 40,
      y: height - 38,
      size: 20,
      font: fontBold,
      color: rgb(1, 1, 1),
    });

    page.drawText('Nền tảng mua bán pin xe điện cũ uy tín nhất Việt Nam', {
      x: 40,
      y: height - 52,
      size: 9,
      font: fontRegular,
      color: rgb(0.9, 0.9, 0.9),
    });

    // 2. Title
    let cursorY = height - 100;
    page.drawText('HỢP ĐỒNG MUA BÁN & CHỨNG NHẬN GIAO DỊCH', {
      x: width / 2 - 140,
      y: cursorY,
      size: 14,
      font: fontBold,
      color: rgb(0.1, 0.1, 0.1),
    });
    cursorY -= 20;
    page.drawText(`Số (ID): ${contract.id}`, {
      x: width / 2 - 60,
      y: cursorY,
      size: 8,
      font: fontRegular,
      color: rgb(0.5, 0.5, 0.5),
    });

    cursorY -= 40;

    // 3. Info Sections
    const drawSection = (title: string, y: number) => {
      page.drawText(title.toUpperCase(), {
        x: 40,
        y,
        size: 11,
        font: fontBold,
        color: rgb(0.1, 0.45, 0.25),
      });
      page.drawLine({
        start: { x: 40, y: y - 5 },
        end: { x: width - 40, y: y - 5 },
        thickness: 1,
        color: rgb(0.1, 0.45, 0.25),
        opacity: 0.2,
      });
    };

    // --- BÊN BÁN ---
    drawSection('Bên bán (Seller)', cursorY);
    cursorY -= 25;
    const seller = contract.transaction.seller;
    page.drawText(`Họ và tên: ${seller.fullName ?? '...'}`, {
      x: 50,
      y: cursorY,
      size: 10,
      font: fontRegular,
    });
    cursorY -= 15;
    page.drawText(
      `Email: ${seller.email ?? '...'} | SĐT: ${seller.phone ?? '...'}`,
      { x: 50, y: cursorY, size: 10, font: fontRegular },
    );

    cursorY -= 35;

    // --- BÊN MUA ---
    drawSection('Bên mua (Buyer)', cursorY);
    cursorY -= 25;
    const buyer = this.extractBuyer(contract);
    page.drawText(`Họ và tên: ${buyer?.fullName ?? '...'}`, {
      x: 50,
      y: cursorY,
      size: 10,
      font: fontRegular,
    });
    cursorY -= 15;
    page.drawText(
      `Email: ${buyer?.email ?? '...'} | SĐT: ${buyer?.phone ?? '...'}`,
      { x: 50, y: cursorY, size: 10, font: fontRegular },
    );

    cursorY -= 35;

    // --- THÔNG TIN TÀI SẢN ---
    drawSection('Thông tin sản phẩm & Giao dịch', cursorY);
    cursorY -= 25;

    // Table Header
    page.drawRectangle({
      x: 40,
      y: cursorY - 5,
      width: width - 80,
      height: 20,
      color: rgb(0.95, 0.95, 0.95),
    });
    page.drawText('Hạng mục', { x: 50, y: cursorY, size: 10, font: fontBold });
    page.drawText('Chi tiết', { x: 200, y: cursorY, size: 10, font: fontBold });

    cursorY -= 20;
    const assetDescription = this.buildAssetDescription(contract);
    page.drawText('Tên tài sản:', {
      x: 50,
      y: cursorY,
      size: 10,
      font: fontRegular,
    });
    page.drawText(assetDescription.toUpperCase(), {
      x: 200,
      y: cursorY,
      size: 10,
      font: fontBold,
    });

    cursorY -= 20;
    page.drawText('Giá thỏa thuận:', {
      x: 50,
      y: cursorY,
      size: 10,
      font: fontRegular,
    });
    page.drawText(
      `${Number(contract.transaction.amount).toLocaleString('vi-VN')} VNĐ`,
      {
        x: 200,
        y: cursorY,
        size: 10,
        font: fontBold,
        color: rgb(0.8, 0.1, 0.1),
      },
    );

    cursorY -= 20;
    page.drawText('Trạng thái thanh toán:', {
      x: 50,
      y: cursorY,
      size: 10,
      font: fontRegular,
    });
    page.drawText('Đã thanh toán cọc 50% - Chờ thanh toán hoàn tất', {
      x: 200,
      y: cursorY,
      size: 10,
      font: fontRegular,
    });

    // 4. Signatures Section
    cursorY = 250;
    page.drawText('BÊN MUA KÝ TÊN', {
      x: 80,
      y: cursorY,
      size: 11,
      font: fontBold,
    });
    page.drawText('BÊN BÁN KÝ TÊN', {
      x: width - 200,
      y: cursorY,
      size: 11,
      font: fontBold,
    });

    const buyerSignature = contract.signatures.find(
      (item) => item.role === ContractPartyRole.BUYER,
    );
    const sellerSignature = contract.signatures.find(
      (item) => item.role === ContractPartyRole.SELLER,
    );

    if (buyerSignature) {
      const buyerImage = await this.embedSignatureImage(
        pdfDoc,
        buyerSignature.signaturePath,
      );
      page.drawImage(buyerImage, { x: 60, y: 150, width: 140, height: 70 });
      page.drawText(
        `Ký ngày: ${buyerSignature.signedAt.toLocaleDateString('vi-VN')}`,
        {
          x: 80,
          y: 135,
          size: 9,
          font: fontRegular,
          color: rgb(0.5, 0.5, 0.5),
        },
      );
    }

    if (sellerSignature) {
      const sellerImage = await this.embedSignatureImage(
        pdfDoc,
        sellerSignature.signaturePath,
      );
      page.drawImage(sellerImage, {
        x: width - 220,
        y: 150,
        width: 140,
        height: 70,
      });
      page.drawText(
        `Ký ngày: ${sellerSignature.signedAt.toLocaleDateString('vi-VN')}`,
        {
          x: width - 200,
          y: 135,
          size: 9,
          font: fontRegular,
          color: rgb(0.5, 0.5, 0.5),
        },
      );
    }

    // 5. Footer
    page.drawRectangle({
      x: 0,
      y: 0,
      width,
      height: 30,
      color: rgb(0.95, 0.95, 0.95),
    });
    page.drawText('© 2026 EVN Battery Marketplace. Mọi quyền được bảo lưu.', {
      x: width / 2 - 130,
      y: 10,
      size: 8,
      font: fontRegular,
      color: rgb(0.4, 0.4, 0.4),
    });

    return Buffer.from(await pdfDoc.save());
  }

  private async embedSignatureImage(
    pdfDoc: PDFDocument,
    signaturePath: string,
  ) {
    const absolutePath = this.toAbsolutePath(signaturePath);
    const buffer = await fs.readFile(absolutePath);
    const lower = absolutePath.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return pdfDoc.embedJpg(buffer);
    }

    return pdfDoc.embedPng(buffer);
  }

  private extractSignature(data: string): ContractSignatureInput {
    const match = data.match(/^data:(image\/(png|jpeg));base64,(.+)$/i);
    let mime = 'image/png';
    let base64 = data;

    if (match) {
      mime = match[1].toLowerCase();
      base64 = match[3];
    }

    const buffer = Buffer.from(base64, 'base64');
    const extension = mime.includes('jpeg') ? '.jpg' : '.png';

    return { buffer, extension, mime };
  }

  private async storeSignature(
    contractId: string,
    role: ContractPartyRole,
    input: ContractSignatureInput,
  ) {
    const dir = path.join(this.signaturesDir, contractId);
    await this.ensureDir(dir);

    const filename = `${role.toLowerCase()}-${Date.now()}${input.extension}`;
    const absolutePath = path.join(dir, filename);
    await fs.writeFile(absolutePath, input.buffer);

    return this.toRelativePath(absolutePath);
  }

  private toRelativePath(fullPath: string) {
    const relative = path.relative(this.uploadsRoot, fullPath);
    return relative.split(path.sep).join('/');
  }

  private toAbsolutePath(input: string) {
    if (!input) {
      return input;
    }

    if (path.isAbsolute(input)) {
      return input;
    }

    return path.join(this.uploadsRoot, input);
  }

  private async ensureDir(target: string) {
    await fs.mkdir(target, { recursive: true });
  }

  private async fileExists(filePath: string) {
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  private resolveTemplatePath() {
    const configured = this.configService.get<string>('CONTRACT_TEMPLATE_PATH');
    if (!configured) {
      return null;
    }

    return path.isAbsolute(configured)
      ? configured
      : path.join(process.cwd(), configured);
  }

  private buildSigningUrl(transactionId: string) {
    const baseUrl = this.configService.get<string>('CONTRACT_SIGNING_URL');
    if (!baseUrl) {
      return null;
    }

    return `${baseUrl.replace(/\/$/, '')}/${transactionId}`;
  }

  private extractBuyer(contract: ContractDetail) {
    return (
      contract.transaction.purchase?.buyer ??
      contract.transaction.chatRoom?.buyer ??
      null
    );
  }

  private buildAssetDescription(contract: ContractDetail) {
    if (contract.transaction.vehicle) {
      return `xe ${contract.transaction.vehicle.name}`;
    }

    if (contract.transaction.battery) {
      return `pin ${contract.transaction.battery.name}`;
    }

    return 'sản phẩm';
  }

  private mapContractResponse(contract: ContractDetail) {
    const buyer = this.extractBuyer(contract);
    return {
      id: contract.id,
      transactionId: contract.transactionId,
      status: contract.status,
      buyerSignedAt: contract.buyerSignedAt,
      sellerSignedAt: contract.sellerSignedAt,
      completedAt: contract.completedAt,
      requestEmailSentAt: contract.requestEmailSentAt,
      finalEmailSentAt: contract.finalEmailSentAt,
      finalPdfPath: contract.finalPdfPath,
      templatePath: contract.templatePath,
      createdAt: contract.createdAt,
      updatedAt: contract.updatedAt,
      parties: {
        buyer: buyer
          ? {
              id: buyer.id,
              name: buyer.fullName,
              email: buyer.email,
              phone: buyer.phone,
              address: buyer.address,
            }
          : null,
        seller: {
          id: contract.transaction.seller.id,
          name: contract.transaction.seller.fullName,
          email: contract.transaction.seller.email,
          phone: contract.transaction.seller.phone,
        },
      },
      asset: contract.transaction.vehicle
        ? {
            type: 'vehicle',
            id: contract.transaction.vehicle.id,
            name: contract.transaction.vehicle.name,
          }
        : contract.transaction.battery
          ? {
              type: 'battery',
              id: contract.transaction.battery.id,
              name: contract.transaction.battery.name,
            }
          : null,
      signatures: contract.signatures.map((signature) => ({
        role: signature.role,
        signedAt: signature.signedAt,
        signaturePath: signature.signaturePath,
      })),
    };
  }

  private normalizeStatus(status?: string) {
    if (!status) {
      return undefined;
    }

    const normalized = status.toUpperCase();
    const values = Object.values(ContractStatus) as string[];

    if (values.includes(normalized)) {
      return normalized as ContractStatus;
    }

    return undefined;
  }

  // ─── New methods for by-contractId flow ──────────────────────────────────

  /**
   * Get contract status by contractId (used by Flutter chat card)
   */
  async getContractStatus(contractId: string, userId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
      select: {
        id: true,
        status: true,
        buyerId: true,
        sellerId: true,
        transactionId: true,
        transaction: {
          select: {
            status: true,
            depositAmount: true,
            balanceAmount: true,
          },
        },
      },
    });

    if (!contract) {
      throw new NotFoundException('Không tìm thấy hợp đồng.');
    }

    if (contract.buyerId !== userId && contract.sellerId !== userId) {
      throw new ForbiddenException('Bạn không có quyền xem hợp đồng này.');
    }

    return {
      contractId: contract.id,
      status: contract.status,
      transactionStatus: contract.transaction.status,
      depositAmount: contract.transaction.depositAmount,
      balanceAmount: contract.transaction.balanceAmount,
    };
  }

  /**
   * Sign contract by contractId (Flutter flow without transactionId)
   */
  async signContractById(
    contractId: string,
    userId: string,
    payload: SignContractDto,
  ) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
      include: contractDetailInclude,
    });

    if (!contract) {
      throw new NotFoundException('Không tìm thấy hợp đồng.');
    }

    const buyer = this.extractBuyer(contract);
    const isBuyer = buyer?.id === userId;
    const isSeller = contract.transaction.seller.id === userId;

    if (!isBuyer && !isSeller) {
      throw new ForbiddenException('Bạn không có quyền ký hợp đồng này.');
    }

    if (
      contract.status === ContractStatus.COMPLETED ||
      contract.status === ContractStatus.CANCELLED
    ) {
      throw new BadRequestException(
        'Hợp đồng đã hoàn thành hoặc bị huỷ, không thể ký.',
      );
    }

    const role = isBuyer ? ContractPartyRole.BUYER : ContractPartyRole.SELLER;

    // Check if already signed by this party
    const existingSig = await this.prisma.contractSignature.findFirst({
      where: { contractId, role },
    });
    if (existingSig) {
      throw new BadRequestException('Bạn đã ký hợp đồng này rồi.');
    }

    // Save signature
    const signaturePath = await this.saveSignatureFile(
      contractId,
      role,
      payload.signatureData,
    );

    await this.prisma.contractSignature.create({
      data: {
        contractId,
        userId: isBuyer
          ? (contract as any).buyerId
          : (contract as any).sellerId,
        role,
        signedAt: new Date(),
        signaturePath,
      },
    });

    // Determine new status
    const otherRole =
      role === ContractPartyRole.BUYER
        ? ContractPartyRole.SELLER
        : ContractPartyRole.BUYER;

    const otherSigned = await this.prisma.contractSignature.findFirst({
      where: { contractId, role: otherRole },
    });

    let newStatus: ContractStatus;
    if (otherSigned) {
      newStatus = ContractStatus.COMPLETED;
    } else if (role === ContractPartyRole.BUYER) {
      newStatus = ContractStatus.BUYER_SIGNED;
    } else {
      newStatus = ContractStatus.SELLER_SIGNED;
    }

    if (
      contract.transaction.status !== TransactionStatus.DEPOSIT_PAID &&
      contract.transaction.status !== TransactionStatus.CONTRACT_SIGNED &&
      contract.transaction.status !== TransactionStatus.AWAITING_BALANCE
    ) {
      throw new BadRequestException(
        'Bạn chỉ có thể ký hợp đồng sau khi đã thanh toán tiền cọc.',
      );
    }

    const updatedContract = await this.prisma.contract.update({
      where: { id: contractId },
      data: { status: newStatus },
      include: contractDetailInclude,
    });

    if (newStatus === ContractStatus.COMPLETED) {
      await this.prisma.transaction.update({
        where: { id: contract.transactionId },
        data: { status: TransactionStatus.AWAITING_BALANCE },
      });
      await this.generateAndSendFinalContract(updatedContract);
    }
  }

  private async saveSignatureFile(
    contractId: string,
    role: string,
    base64Data: string,
  ): Promise<string> {
    const fs = await import('fs/promises');
    const path = await import('path');
    const signatureDir = path.join(process.cwd(), 'uploads', 'signatures');
    await fs.mkdir(signatureDir, { recursive: true });

    const fileName = `${contractId}_${role}_${Date.now()}.png`;
    const filePath = path.join(signatureDir, fileName);

    const base64Image = base64Data.replace(/^data:image\/\w+;base64,/, '');
    await fs.writeFile(filePath, Buffer.from(base64Image, 'base64'));

    return `/uploads/signatures/${fileName}`;
  }

  private async generateAndSendFinalPdf(contractId: string, contract: any) {
    console.log(`Generating final PDF for contract ${contractId}`);
    await this.prisma.contract.update({
      where: { id: contractId },
      data: {
        finalPdfPath: `/uploads/contracts/final_${contractId}.pdf`,
        completedAt: new Date(),
        finalEmailSentAt: new Date(),
      },
    });
  }

  private getBuyerFromChatRoom(room: any) {
    return room.buyer;
  }
}
