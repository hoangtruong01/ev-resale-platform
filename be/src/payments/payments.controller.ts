import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  Headers,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CreateVnpayPaymentDto } from './dto/create-vnpay-payment.dto';
import { CreateSepayPaymentDto } from './dto/create-sepay-payment.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

interface AuthenticatedRequest extends Request {
  user?: {
    id?: string;
    sub?: string;
  };
}

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('vnpay/create-url')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  async createVnpayPayment(
    @Body() body: CreateVnpayPaymentDto,
    @Req() req: AuthenticatedRequest,
  ) {
    const userId = this.resolveUserId(req);
    const clientIp = this.extractClientIp(req);
    return this.paymentsService.createVnpayPayment(body, clientIp, userId);
  }

  @Get('vnpay/return')
  async handleVnpayReturn(
    @Query() query: Record<string, string | string[] | undefined>,
  ) {
    return this.paymentsService.handleVnpayReturn(query);
  }

  @Get('vnpay/ipn')
  async handleVnpayIpn(
    @Query() query: Record<string, string | string[] | undefined>,
  ) {
    return this.paymentsService.handleVnpayIpn(query);
  }

  // ─────────────────────────── SePay ───────────────────────────

  @Post('sepay/create')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  async createSepayPayment(
    @Body() body: CreateSepayPaymentDto,
    @Req() req: AuthenticatedRequest,
  ) {
    const userId = this.resolveUserId(req);
    return this.paymentsService.createSepayPayment(body, userId);
  }

  /**
   * SePay webhook — public endpoint, authenticated via API key in header.
   * SePay sends: POST /payments/sepay/webhook
   * Header: Authorization: Apikey <SEPAY_SECRET_KEY>
   */
  @Post('sepay/webhook')
  async handleSepayWebhook(
    @Body() body: Record<string, unknown>,
    @Headers('Authorization') authHeader: string,
  ) {
    const apiKey = (authHeader ?? '').replace('Apikey ', '').trim();
    return this.paymentsService.handleSepayWebhook(body, apiKey);
  }

  @Get('sepay/status/:attemptId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  async getSepayPaymentStatus(@Param('attemptId') attemptId: string) {
    return this.paymentsService.getSepayPaymentStatus(attemptId);
  }

  @Post('sepay/simulate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  async simulateSepayPayment(
    @Body() body: { paymentAttemptId: string; status: 'SUCCESS' | 'FAILED' },
  ) {
    return this.paymentsService.simulateSepayPayment(
      body.paymentAttemptId,
      body.status ?? 'SUCCESS',
    );
  }

  private resolveUserId(req: AuthenticatedRequest): string {
    const userId = req.user?.id ?? req.user?.sub;
    if (!userId) {
      throw new BadRequestException('User identity is required.');
    }
    return userId;
  }

  private extractClientIp(req: Request): string {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string' && forwarded.length) {
      return forwarded.split(',')[0].trim();
    }

    if (Array.isArray(forwarded) && forwarded.length) {
      return forwarded[0];
    }

    const rawIp = req.ip || req.socket.remoteAddress || '';
    return rawIp.replace('::ffff:', '') || '127.0.0.1';
  }
}
