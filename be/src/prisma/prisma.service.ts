import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly pool: Pool;

  constructor() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is required to initialize Prisma');
    }

    const pool = new Pool({ connectionString });
    const adapter = new PrismaPg(pool);

    super({
      adapter,
      log: ['query', 'info', 'warn', 'error'],
    });

    this.pool = pool;
  }

  async onModuleInit() {
    await this.$connect();
    console.log('🔗 Connected to PostgreSQL database');
  }

  async onModuleDestroy() {
    await this.$disconnect();
    await this.pool.end();
    console.log('🔌 Disconnected from PostgreSQL database');
  }

  async cleanDb() {
    if (process.env.NODE_ENV === 'production') return;

    // Delete data in reverse order of dependencies
    const modelNames = Reflect.ownKeys(this).filter((key) => key[0] !== '_');

    return Promise.all(
      modelNames.map((modelName) => {
        const model = this[modelName as keyof typeof this];
        if (model && typeof model === 'object' && 'deleteMany' in model) {
          return (model as any).deleteMany();
        }
      }),
    );
  }
}
