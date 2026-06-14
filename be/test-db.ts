import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const users = await prisma.user.findMany({ select: { id: true, email: true }, take: 5 });
  console.log('Users:', users);

  const vehicles = await prisma.vehicle.findMany({ select: { id: true, name: true, sellerId: true, status: true, approvalStatus: true } });
  console.log('\nVehicles:', vehicles);

  const batteries = await prisma.battery.findMany({ select: { id: true, name: true, sellerId: true, status: true, approvalStatus: true } });
  console.log('\nBatteries:', batteries);
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
