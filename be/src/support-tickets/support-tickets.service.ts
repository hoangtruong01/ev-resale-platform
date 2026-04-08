import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma, SupportTicketStatus } from '@prisma/client';
import { CreateSupportTicketDto } from './dto';

@Injectable()
export class SupportTicketsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(payload: CreateSupportTicketDto) {
    return this.prisma.supportTicket.create({
      data: {
        name: payload.name,
        email: payload.email,
        subject: payload.subject,
        message: payload.message,
        userId: payload.userId ?? null,
      },
    });
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
