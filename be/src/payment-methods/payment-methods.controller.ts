import {
  Body,
  Controller,
  Get,
  Post,
  Req,
  UseGuards,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PaymentMethodsService } from './payment-methods.service';
import { SavePaymentMethodDto } from './dto/save-payment-method.dto';

@ApiTags('payment-methods')
@Controller('payment-methods')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PaymentMethodsController {
  constructor(private readonly paymentMethodsService: PaymentMethodsService) {}

  @Get('me')
  @ApiOperation({
    summary: 'Lấy danh sách phương thức thanh toán của người dùng',
  })
  async getMyMethods(@Req() req: Request) {
    const userId = this.resolveUserId(req);
    const methods = await this.paymentMethodsService.listUserMethods(userId);
    return {
      success: true,
      data: methods,
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Lưu hoặc cập nhật thẻ Visa mặc định của người dùng',
  })
  async saveDefaultMethod(
    @Req() req: Request,
    @Body() body: SavePaymentMethodDto,
  ) {
    const userId = this.resolveUserId(req);
    const method = await this.paymentMethodsService.savePaymentMethod(
      userId,
      body,
    );
    return {
      success: true,
      data: method,
      message: 'Cập nhật phương thức thanh toán thành công.',
    };
  }

  private resolveUserId(req: Request): string {
    const user = req.user as
      | { id?: string; userId?: string; sub?: string }
      | undefined;
    const userId = user?.userId || user?.sub || user?.id;
    if (!userId) {
      throw new UnauthorizedException('Không xác định được người dùng.');
    }
    return userId;
  }
}
