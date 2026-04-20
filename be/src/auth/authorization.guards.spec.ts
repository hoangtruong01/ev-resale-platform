import { Controller, Get, INestApplication, UseGuards } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { UserRole } from '@prisma/client';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import { Permissions } from './permissions.decorator';
import { PermissionsGuard } from './permissions.guard';

@Controller('authz-test')
class AuthzTestController {
  @Get('admin-only')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  adminOnly() {
    return { ok: true };
  }

  @Get('moderate-posts')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('MODERATE_POSTS')
  moderatePosts() {
    return { ok: true };
  }

  @Get('support-only')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Permissions('HANDLE_SUPPORT_TICKETS')
  supportOnly() {
    return { ok: true };
  }
}

describe('Authorization Guards', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [AuthzTestController],
      providers: [RolesGuard, PermissionsGuard],
    }).compile();

    app = moduleRef.createNestApplication();

    app.use((req: any, _res, next) => {
      const roleHeader = req.headers['x-user-role'];
      const permissionHeader = req.headers['x-user-permissions'];
      const userIdHeader = req.headers['x-user-id'];

      if (roleHeader) {
        req.user = {
          sub: userIdHeader || 'test-user-id',
          role: String(roleHeader),
          moderatorPermissions: permissionHeader
            ? String(permissionHeader)
                .split(',')
                .map((value) => value.trim())
                .filter(Boolean)
            : [],
        };
      }

      next();
    });

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns 401 when not authenticated on role-protected route', async () => {
    await request(app.getHttpServer())
      .get('/authz-test/admin-only')
      .expect(401);
  });

  it('returns 403 for authenticated user with wrong role', async () => {
    await request(app.getHttpServer())
      .get('/authz-test/admin-only')
      .set('x-user-role', 'USER')
      .expect(403);
  });

  it('returns 200 for admin role on admin-only route', async () => {
    await request(app.getHttpServer())
      .get('/authz-test/admin-only')
      .set('x-user-role', 'ADMIN')
      .expect(200);
  });

  it('returns 403 for moderator missing required permission', async () => {
    await request(app.getHttpServer())
      .get('/authz-test/moderate-posts')
      .set('x-user-role', 'MODERATOR')
      .expect(403);
  });

  it('returns 200 for moderator with required permission', async () => {
    await request(app.getHttpServer())
      .get('/authz-test/moderate-posts')
      .set('x-user-role', 'MODERATOR')
      .set('x-user-permissions', 'MODERATE_POSTS')
      .expect(200);
  });

  it('returns 200 for admin on moderator-permission route', async () => {
    await request(app.getHttpServer())
      .get('/authz-test/support-only')
      .set('x-user-role', 'ADMIN')
      .expect(200);
  });
});
