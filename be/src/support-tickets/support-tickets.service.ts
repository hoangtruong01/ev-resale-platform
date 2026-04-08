import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  Prisma,
  SupportTicketStatus,
  NotificationType,
  UserRole,
} from '@prisma/client';
import { CreateSupportTicketDto } from './dto';
import { NotificationsService } from '../notifications/notifications.service';
import { MailService } from '../mail/mail.service';
import { SmsService } from '../sms/sms.service';

@Injectable()
export class SupportTicketsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly mailService: MailService,
    private readonly smsService: SmsService,
  ) {}

  async create(payload: CreateSupportTicketDto) {
    const ticket = await this.prisma.supportTicket.create({
      data: {
        name: payload.name,
        email: payload.email,
        subject: payload.subject,
        message: payload.message,
        userId: payload.userId ?? null,
      },
    });

    const admins = await this.prisma.user.findMany({
      where: {
        role: { in: [UserRole.ADMIN, UserRole.MODERATOR] },
        isActive: true,
      },
      select: { id: true, email: true, phone: true, fullName: true },
    });

    const adminNotifications = admins.map((admin) =>
      this.notificationsService.create({
        userId: admin.id,
        title: 'Yêu cầu hỗ trợ mới',
        message: `${payload.name} vừa gửi yêu cầu hỗ trợ: ${payload.subject}.`,
        type: NotificationType.SYSTEM_ALERT,
        metadata: {
          ticketId: ticket.id,
          email: payload.email,
        },
      }),
    );

    await Promise.allSettled(adminNotifications);

    const emailTasks: Promise<unknown>[] = [];
    const smsTasks: Promise<unknown>[] = [];

    emailTasks.push(
      this.mailService.sendMail({
        to: payload.email,
        subject: `EVN Market: Đã nhận yêu cầu hỗ trợ #${ticket.id}`,
        text: `Chúng tôi đã nhận yêu cầu hỗ trợ của bạn. Mã yêu cầu: ${ticket.id}.`,
        html: `<p>Chúng tôi đã nhận yêu cầu hỗ trợ của bạn.</p><p>Mã yêu cầu: <strong>${ticket.id}</strong></p>`,
      }),
    );

    admins.forEach((admin) => {
      if (admin.email) {
        emailTasks.push(
          this.mailService.sendMail({
            to: admin.email,
            subject: `Support ticket mới #${ticket.id}`,
            text: `${payload.name} (${payload.email}) vừa gửi yêu cầu: ${payload.subject}.`,
          }),
        );
      }
      if (admin.phone) {
        smsTasks.push(
          this.smsService.sendSms(
            admin.phone,
            `Support ticket moi: ${payload.name} - ${payload.subject}. Ma: ${ticket.id}`,
          ),
        );
      }
    });

    const userRecord = payload.userId
      ? await this.prisma.user.findUnique({
          where: { id: payload.userId },
          select: { phone: true },
        })
      : null;

    if (userRecord?.phone) {
      smsTasks.push(
        this.smsService.sendSms(
          userRecord.phone,
          `EVN Market: Da nhan yeu cau ho tro #${ticket.id}.`,
        ),
      );
    }

    await Promise.allSettled([...emailTasks, ...smsTasks]);

    return ticket;
  }

  async findAll(params: {
    page?: number;
    limit?: number;
    status?: SupportTicketStatus;
    search?: string;
  }) {
    const page = Math.max(1, Math.floor(params.page ?? 1));
    const limit = Math.min(100, Math.max(1, Math.floor(params.limit ?? 20)));
    const skip = (page - 1) * limit;

    const where: Prisma.SupportTicketWhereInput = {};

    if (params.status) {
      where.status = params.status;
    }

    if (params.search) {
      where.OR = [
        { name: { contains: params.search, mode: 'insensitive' } },
        { email: { contains: params.search, mode: 'insensitive' } },
        { subject: { contains: params.search, mode: 'insensitive' } },
      ];
    }

    const [tickets, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.supportTicket.count({ where }),
    ]);

    return {
      data: tickets,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateStatus(id: string, status: SupportTicketStatus) {
    return this.prisma.supportTicket.update({
      where: { id },
      data: { status },
    });
  }
}
