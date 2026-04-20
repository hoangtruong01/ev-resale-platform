import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import { PERMISSIONS_KEY } from './permissions.decorator';
import { normalizePermissions, type ModeratorPermission } from './permissions';

interface RequestWithUser {
  user?: {
    id?: string;
    sub?: string;
    role?: UserRole;
    moderatorPermissions?: string[];
  };
}

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.getAllAndOverride<
      ModeratorPermission[]
    >(PERMISSIONS_KEY, [context.getHandler(), context.getClass()]);

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const user = request?.user;

    if (!user) {
      throw new UnauthorizedException('Bạn cần đăng nhập để tiếp tục.');
    }

    if (user.role === UserRole.ADMIN) {
      return true;
    }

    if (user.role !== UserRole.MODERATOR) {
      throw new ForbiddenException(
        'Bạn không có quyền thực hiện hành động này.',
      );
    }

    const grantedPermissions = normalizePermissions(user.moderatorPermissions);
    const hasAllPermissions = requiredPermissions.every((permission) =>
      grantedPermissions.includes(permission),
    );

    if (!hasAllPermissions) {
      throw new ForbiddenException(
        'Bạn không có quyền thực hiện hành động này.',
      );
    }

    return true;
  }
}
