import { Body, Controller, Get, Post, Query, Req } from '@nestjs/common';
import type { Request } from 'express';
import { PaymentsService } from './payments.service';
import { CreateVnpayPaymentDto } from './dto/create-vnpay-payment.dto';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('vnpay/create-url')
  async createVnpayPayment(
    @Body() body: CreateVnpayPaymentDto,
    @Req() req: Request,
  ) {
    const clientIp = this.extractClientIp(req);
    return this.paymentsService.createVnpayPayment(body, clientIp);
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
