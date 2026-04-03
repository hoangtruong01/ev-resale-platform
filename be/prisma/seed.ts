import {
  PrismaClient,
  TransactionStatus,
  PurchaseStatus,
  AuctionStatus,
  AuctionItemType,
  Prisma,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...');

  // Hash password for all users (password: "password123")
  const hashedPassword = await bcrypt.hash('password123', 10);

  // Create users (use upsert to avoid unique constraint violations)
  const users = await Promise.all([
    prisma.user.upsert({
      where: { email: 'john@example.com' },
      update: {},
      create: {
        email: 'john@example.com',
        password: hashedPassword,
        fullName: 'John Doe',
        phone: '+84901234567',
        role: 'USER',
        isProfileComplete: true,
      },
    }),
    prisma.user.upsert({
      where: { email: 'jane@example.com' },
      update: {},
      create: {
        email: 'jane@example.com',
        password: hashedPassword,
        fullName: 'Jane Smith',
        phone: '+84907654321',
        role: 'USER',
        isProfileComplete: true,
      },
    }),
    prisma.user.upsert({
      where: { email: 'admin@evnmarket.com' },
      update: {},
      create: {
        email: 'admin@evnmarket.com',
        password: hashedPassword,
        fullName: 'Admin User',
        phone: '+84900000000',
        role: 'ADMIN',
        isProfileComplete: true,
      },
    }),
  ]);

  console.log('✅ Created users:', users.length);

  // Create vehicles
  const vehicles = await Promise.all([
    prisma.vehicle.create({
      data: {
        name: 'Tesla Model 3 2021',
        brand: 'Tesla',
        model: 'Model 3',
        year: 2021,
        price: 850000000,
        mileage: 25000,
        condition: 'Excellent',
        description:
          'Tesla Model 3 trong tình trạng tuyệt vời, bảo dưỡng định kỳ.',
        images: ['/images/tesla-model3-1.jpg', '/images/tesla-model3-2.jpg'],
        location: 'Hà Nội',
        color: 'Trắng ngọc trai',
        transmission: 'Tự động',
        seatCount: 5,
        hasWarranty: true,
        sellerId: users[0].id,
      },
    }),
    prisma.vehicle.create({
      data: {
        name: 'VinFast VF8 2022',
        brand: 'VinFast',
        model: 'VF8',
        year: 2022,
        price: 1200000000,
        mileage: 15000,
        condition: 'Very Good',
        description: 'VinFast VF8 mới, ít sử dụng, còn bảo hành.',
        images: ['/images/vinfast-vf8-1.jpg', '/images/vinfast-vf8-2.jpg'],
        location: 'TP.HCM',
        color: 'Xanh rêu',
        transmission: 'Tự động',
        seatCount: 7,
        hasWarranty: true,
        sellerId: users[1].id,
      },
    }),
    prisma.vehicle.create({
      data: {
        name: 'BMW iX3 2020',
        brand: 'BMW',
        model: 'iX3',
        year: 2020,
        price: 950000000,
        mileage: 35000,
        condition: 'Good',
        description: 'BMW iX3 sang trọng, động cơ điện mạnh mẽ.',
        images: ['/images/bmw-ix3-1.jpg', '/images/bmw-ix3-2.jpg'],
        location: 'Đà Nẵng',
        color: 'Xám bạc',
        transmission: 'Tự động',
        seatCount: 5,
        hasWarranty: false,
        sellerId: users[0].id,
      },
    }),
  ]);

  console.log('✅ Created vehicles:', vehicles.length);

  // Create batteries
  const batteries = await Promise.all([
    prisma.battery.create({
      data: {
        name: 'Tesla Model 3 Battery Pack',
        type: 'LITHIUM_ION',
        capacity: 75.5,
        voltage: 350,
        condition: 85,
        price: 120000000,
        description: 'Pin Tesla Model 3 còn 85% dung lượng, hoạt động tốt.',
        images: ['/images/tesla-battery-1.jpg', '/images/tesla-battery-2.jpg'],
        location: 'Hà Nội',
        sellerId: users[1].id,
      },
    }),
    prisma.battery.create({
      data: {
        name: 'VinFast VF8 Battery',
        type: 'LITHIUM_ION',
        capacity: 87.7,
        voltage: 400,
        condition: 92,
        price: 150000000,
        description: 'Pin VinFast VF8 chất lượng cao, ít sử dụng.',
        images: [
          '/images/vinfast-battery-1.jpg',
          '/images/vinfast-battery-2.jpg',
        ],
        location: 'TP.HCM',
        sellerId: users[0].id,
      },
    }),
    prisma.battery.create({
      data: {
        name: 'BMW iX3 Battery Pack',
        type: 'LITHIUM_ION',
        capacity: 80.0,
        voltage: 400,
        condition: 78,
        price: 110000000,
        description: 'Pin BMW iX3 ổn định, thay thế kinh tế.',
        images: ['/images/bmw-battery-1.jpg', '/images/bmw-battery-2.jpg'],
        location: 'Đà Nẵng',
        sellerId: users[1].id,
      },
    }),
  ]);

  console.log('✅ Created batteries:', batteries.length);

  // Create auctions
  const auctions = await Promise.all([
    prisma.auction.create({
      data: {
        title: 'Đấu giá Tesla Model 3 2021',
        description: 'Tesla Model 3 chất lượng cao, đấu giá từ 700M',
        startingPrice: 700000000,
        currentPrice: 750000000,
        bidStep: 10000000,
        startTime: new Date(),
        endTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        status: AuctionStatus.ACTIVE,
        sellerId: users[0].id,
        itemType: AuctionItemType.VEHICLE,
        lotQuantity: 1,
        itemBrand: 'Tesla',
        itemModel: 'Model 3',
        itemYear: 2021,
        itemMileage: 25000,
        location: 'hanoi',
        contactPhone: '+84901234567',
        media: {
          create: [
            {
              url: '/images/tesla-model3-1.jpg',
              sortOrder: 0,
            },
            {
              url: '/images/tesla-model3-2.jpg',
              sortOrder: 1,
            },
          ],
        },
      },
    }),
    prisma.auction.create({
      data: {
        title: 'Đấu giá Pin VinFast VF8',
        description: 'Pin VinFast VF8 92% dung lượng, đấu giá từ 120M',
        startingPrice: 120000000,
        currentPrice: 130000000,
        bidStep: 5000000,
        startTime: new Date(),
        endTime: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
        status: AuctionStatus.ACTIVE,
        sellerId: users[0].id,
        itemType: AuctionItemType.BATTERY,
        lotQuantity: 2,
        itemBrand: 'VinFast',
        itemModel: 'VF8',
        itemCapacity: 92,
        itemCondition: 92,
        location: 'hcm',
        contactPhone: '+84907654321',
        media: {
          create: [
            {
              url: '/images/vinfast-battery-1.jpg',
              sortOrder: 0,
            },
            {
              url: '/images/vinfast-battery-2.jpg',
              sortOrder: 1,
            },
          ],
        },
      },
    }),
  ]);

  console.log('✅ Created auctions:', auctions.length);

  // Create bids
  const bids = await Promise.all([
    prisma.bid.create({
      data: {
        amount: 750000000,
        bidderId: users[1].id,
        auctionId: auctions[0].id,
      },
    }),
    prisma.bid.create({
      data: {
        amount: 130000000,
        bidderId: users[1].id,
        auctionId: auctions[1].id,
      },
    }),
  ]);

  console.log('✅ Created bids:', bids.length);

  // Create transactions
  const transactions = await Promise.all([
    prisma.transaction.create({
      data: {
        amount: 830000000,
        fee: 1500000,
        commission: 2500000,
        status: TransactionStatus.COMPLETED,
        paymentMethod: 'Chuyển khoản',
        notes: 'Giao dịch hoàn tất trong ngày',
        sellerId: users[0].id,
        vehicleId: vehicles[0].id,
      },
    }),
    prisma.transaction.create({
      data: {
        amount: 118000000,
        fee: 500000,
        commission: 1800000,
        status: TransactionStatus.COMPLETED,
        paymentMethod: 'Ví điện tử',
        notes: 'Thanh toán online',
        sellerId: users[1].id,
        batteryId: batteries[0].id,
      },
    }),
  ]);

  console.log('✅ Created transactions:', transactions.length);

  // Create purchases
  const purchases = await Promise.all([
    prisma.purchase.create({
      data: {
        buyerId: users[1].id,
        transactionId: transactions[0].id,
        status: PurchaseStatus.DELIVERED,
        deliveryDate: new Date(),
        notes: 'Giao hàng tận nơi trong 2 ngày',
      },
    }),
    prisma.purchase.create({
      data: {
        buyerId: users[0].id,
        transactionId: transactions[1].id,
        status: PurchaseStatus.SHIPPED,
        notes: 'Đang vận chuyển tới kho trung gian',
      },
    }),
  ]);

  console.log('✅ Created purchases:', purchases.length);

  // Create favorites
  // Temporary cast allows seeding new favorites until Prisma client types are regenerated.
  const prismaWithFavorites = prisma as PrismaClient & {
    favorite: {
      create: (args: any) => Promise<any>;
    };
  };

  const favorites = await Promise.all([
    prismaWithFavorites.favorite.create({
      data: {
        userId: users[0].id,
        itemType: 'VEHICLE',
        vehicleId: vehicles[1].id,
      },
    }),
    prismaWithFavorites.favorite.create({
      data: {
        userId: users[0].id,
        itemType: 'AUCTION',
        auctionId: auctions[0].id,
      },
    }),
    prismaWithFavorites.favorite.create({
      data: {
        userId: users[1].id,
        itemType: 'BATTERY',
        batteryId: batteries[1].id,
      },
    }),
  ]);

  console.log('✅ Created favorites:', favorites.length);

  // Create reviews
  const reviews = await Promise.all([
    prisma.review.create({
      data: {
        rating: 5,
        comment: 'Xe rất tốt, chất lượng như mô tả. Người bán tận tình!',
        reviewerId: users[1].id,
        userId: users[0].id,
        vehicleId: vehicles[0].id,
      },
    }),
    prisma.review.create({
      data: {
        rating: 4,
        comment: 'Pin hoạt động ổn định, giao hàng nhanh.',
        reviewerId: users[0].id,
        userId: users[1].id,
        batteryId: batteries[0].id,
      },
    }),
  ]);

  console.log('✅ Created reviews:', reviews.length);

  // Create settings (use upsert to avoid unique constraint violations)
  const settings = await Promise.all([
    prisma.settings.upsert({
      where: { key: 'site_name' },
      update: {
        value: 'EVN Market',
        type: 'string',
      },
      create: {
        key: 'site_name',
        value: 'EVN Market',
        type: 'string',
      },
    }),
    prisma.settings.upsert({
      where: { key: 'default_currency' },
      update: {
        value: 'VND',
        type: 'string',
      },
      create: {
        key: 'default_currency',
        value: 'VND',
        type: 'string',
      },
    }),
    prisma.settings.upsert({
      where: { key: 'auction_bid_step' },
      update: {
        value: '5000000',
        type: 'number',
      },
      create: {
        key: 'auction_bid_step',
        value: '5000000',
        type: 'number',
      },
    }),
  ]);

  console.log('✅ Created settings:', settings.length);

  // Seed fee & commission configuration
  const prismaClient = prisma as any;

  await prismaClient.transactionFeeSetting.upsert({
    where: { key: 'default' },
    update: {
      rate: new Prisma.Decimal(5.0),
      minFee: new Prisma.Decimal(10000),
      maxFee: new Prisma.Decimal(1000000),
    },
    create: {
      rate: new Prisma.Decimal(5.0),
      minFee: new Prisma.Decimal(10000),
      maxFee: new Prisma.Decimal(1000000),
    },
  });

  const listingFeeTiers = await Promise.all([
    prismaClient.listingFeeTier.upsert({
      where: { id: 'seed-listing-basic' },
      update: {
        name: 'Tin thường',
        duration: 30,
        features: ['Hiển thị cơ bản', 'Tìm kiếm thông thường'],
        price: new Prisma.Decimal(50000),
        enabled: true,
        order: 1,
      },
      create: {
        id: 'seed-listing-basic',
        name: 'Tin thường',
        duration: 30,
        features: ['Hiển thị cơ bản', 'Tìm kiếm thông thường'],
        price: new Prisma.Decimal(50000),
        enabled: true,
        order: 1,
      },
    }),
    prismaClient.listingFeeTier.upsert({
      where: { id: 'seed-listing-vip' },
      update: {
        name: 'Tin VIP',
        duration: 30,
        features: ['Hiển thị ưu tiên', 'Đăng lên đầu danh sách', 'Badge VIP'],
        price: new Prisma.Decimal(150000),
        enabled: true,
        order: 2,
      },
      create: {
        id: 'seed-listing-vip',
        name: 'Tin VIP',
        duration: 30,
        features: ['Hiển thị ưu tiên', 'Đăng lên đầu danh sách', 'Badge VIP'],
        price: new Prisma.Decimal(150000),
        enabled: true,
        order: 2,
      },
    }),
    prismaClient.listingFeeTier.upsert({
      where: { id: 'seed-listing-hot' },
      update: {
        name: 'Tin Hot',
        duration: 15,
        features: ['Hiển thị nổi bật', 'Màu sắc đặc biệt', 'Push notification'],
        price: new Prisma.Decimal(300000),
        enabled: true,
        order: 3,
      },
      create: {
        id: 'seed-listing-hot',
        name: 'Tin Hot',
        duration: 15,
        features: ['Hiển thị nổi bật', 'Màu sắc đặc biệt', 'Push notification'],
        price: new Prisma.Decimal(300000),
        enabled: true,
        order: 3,
      },
    }),
  ]);

  const commissionTiers = await Promise.all([
    prismaClient.commissionTier.upsert({
      where: { id: 'seed-commission-referral' },
      update: {
        name: 'Đối tác giới thiệu',
        rate: new Prisma.Decimal(2.0),
        minRequirement: 1,
        requirementUnit: 'giao dịch/tháng',
        enabled: true,
        order: 1,
      },
      create: {
        id: 'seed-commission-referral',
        name: 'Đối tác giới thiệu',
        rate: new Prisma.Decimal(2.0),
        minRequirement: 1,
        requirementUnit: 'giao dịch/tháng',
        enabled: true,
        order: 1,
      },
    }),
    prismaClient.commissionTier.upsert({
      where: { id: 'seed-commission-silver' },
      update: {
        name: 'Đại lý bạc',
        rate: new Prisma.Decimal(3.5),
        minRequirement: 10,
        requirementUnit: 'giao dịch/tháng',
        enabled: true,
        order: 2,
      },
      create: {
        id: 'seed-commission-silver',
        name: 'Đại lý bạc',
        rate: new Prisma.Decimal(3.5),
        minRequirement: 10,
        requirementUnit: 'giao dịch/tháng',
        enabled: true,
        order: 2,
      },
    }),
    prismaClient.commissionTier.upsert({
      where: { id: 'seed-commission-gold' },
      update: {
        name: 'Đại lý vàng',
        rate: new Prisma.Decimal(5.0),
        minRequirement: 50,
        requirementUnit: 'giao dịch/tháng',
        enabled: true,
        order: 3,
      },
      create: {
        id: 'seed-commission-gold',
        name: 'Đại lý vàng',
        rate: new Prisma.Decimal(5.0),
        minRequirement: 50,
        requirementUnit: 'giao dịch/tháng',
        enabled: true,
        order: 3,
      },
    }),
  ]);

  console.log('✅ Seeded fee settings');
  console.log('✅ Seeded listing fee tiers:', listingFeeTiers.length);
  console.log('✅ Seeded commission tiers:', commissionTiers.length);

  console.log('🎉 Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
