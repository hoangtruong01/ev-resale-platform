import { Injectable } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type AuditAction =
  | 'UPDATE_USER_ROLE'
  | 'UPDATE_MODERATOR_PERMISSIONS'
  | 'HANDLE_SUPPORT_TICKET'
  | 'UPDATE_FEES'
  | 'RESOLVE_TRANSACTION_DISPUTE'
  | 'UPDATE_SYSTEM_SETTINGS';

interface AuditLogInput {
  actorId: string;
  actorRole?: UserRole | string;
  action: AuditAction;
  targetType?: string;
  targetId?: string;
  metadata?: Record<string, unknown>;
}

@Injectable()
export class AuditLogsService {
  constructor(private readonly prisma: PrismaService) {}

  async log(input: AuditLogInput) {
    return this.prisma.auditLog.create({
      data: {
        actorId: input.actorId,
        actorRole: input.actorRole ? String(input.actorRole) : undefined,
        action: input.action,
        targetType: input.targetType,
        targetId: input.targetId,
        metadata: (input.metadata ?? undefined) as Prisma.InputJsonValue,
      },
    });
  }
}
