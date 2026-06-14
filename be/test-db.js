const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({ take: 2 });
  console.log('Users:', users.map(u => ({ id: u.id, email: u.email })));

  const vehicles = await prisma.vehicle.findMany({ 
    take: 5, 
    select: { id: true, name: true, sellerId: true, status: true, approvalStatus: true } 
  });
  console.log('Vehicles:', vehicles);
  
  const batteries = await prisma.battery.findMany({ 
    take: 5, 
    select: { id: true, name: true, sellerId: true, status: true, approvalStatus: true } 
  });
  console.log('Batteries:', batteries);
}

main().finally(() => prisma.$disconnect());
