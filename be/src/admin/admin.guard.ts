import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request?.user;

    if (user && (user.role === 'ADMIN' || user.role === 'MODERATOR')) {
      return true;
    }

    throw new ForbiddenException(
      'Chỉ quản trị viên hoặc kiểm duyệt viên mới có quyền truy cập.',
    );
  }
}
