import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminBootstrapService implements OnModuleInit {
  private readonly logger = new Logger(AdminBootstrapService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async onModuleInit() {
    const email =
      this.configService.get<string>('ADMIN_EMAIL')?.trim() ||
      'admin@evnmarket.com';
    const password =
      this.configService.get<string>('ADMIN_PASSWORD')?.trim() ||
      'ChangeMe123!';
    const fullName =
      this.configService.get<string>('ADMIN_FULL_NAME')?.trim() ||
      'System Administrator';
    const phone =
      this.configService.get<string>('ADMIN_PHONE')?.trim() || '+84000000000';

    if (!email || !password) {
      this.logger.warn(
        'Admin bootstrap skipped because ADMIN_EMAIL or ADMIN_PASSWORD is missing.',
      );
      return;
    }

    const existingAdmin = await this.prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        password: true,
        role: true,
        isActive: true,
        isProfileComplete: true,
        fullName: true,
        phone: true,
      },
    });

    if (
      existingAdmin &&
      existingAdmin.role === 'ADMIN' &&
      existingAdmin.isActive &&
      existingAdmin.isProfileComplete &&
      existingAdmin.fullName === fullName &&
      existingAdmin.phone === phone &&
      existingAdmin.password &&
      (await bcrypt.compare(password, existingAdmin.password))
    ) {
      this.logger.debug(`Admin account already configured for ${email}`);
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await this.prisma.user.upsert({
      where: { email },
      update: {
        password: hashedPassword,
        fullName,
        phone,
        role: 'ADMIN',
        isActive: true,
        isProfileComplete: true,
        provider: 'local',
      },
      create: {
        email,
        password: hashedPassword,
        fullName,
        phone,
        role: 'ADMIN',
        isActive: true,
        isProfileComplete: true,
        provider: 'local',
      },
    });

    const action = existingAdmin ? 'updated' : 'created';
    this.logger.log(`Admin account ${action} for ${email}`);
  }
}
