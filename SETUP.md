# EVN Market - Setup Instructions

## Prerequisites
- Docker và Docker Compose đã cài đặt
- Node.js 18+ đã cài đặt
- Yarn đã cài đặt
- pgAdmin 4 đã cài đặt

## Quick Start với Docker

### 1. Clone và setup
```bash
cd e:\SUN25\Second-hand-EVN-Battery-Trading-Platform
```

### 2. Khởi động database với Docker
```bash
docker-compose up postgres pgadmin -d
```

### 3. Setup Backend
```bash
cd be
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```

### 4. Setup Frontend (terminal mới)
```bash
cd FE
yarn install
yarn dev
```

## Manual Setup (không dùng Docker)

### 1. Backend Setup
```bash
cd be

# Cài đặt dependencies
npm install

# Generate Prisma client
npx prisma generate

# Chạy migration
npx prisma migrate dev --name init

# Start backend
npm run start:dev
```

### 2. Frontend Setup
```bash
cd FE

# Cài đặt dependencies
yarn install

# Start frontend
yarn dev
```

## Database Configuration

### pgAdmin 4 Connection:
- Host: localhost
- Port: 5432
- Database: evn_market
- Username: postgres
- Password: postgres123

### Web Access:
- pgAdmin Web: http://localhost:8080
  - Email: admin@evnmarket.com
  - Password: admin123

## Application URLs

- Frontend: http://localhost:3001
- Backend API: http://localhost:3000
- API Documentation (Swagger): http://localhost:3000/api
- pgAdmin: http://localhost:8080

## Environment Files

### Backend (.env)
```
DATABASE_URL="postgresql://postgres:postgres123@localhost:5432/evn_market?schema=public"
PORT=3000
NODE_ENV=development
JWT_SECRET=evn-market-super-secret-key-2025
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://localhost:3001
```

### Frontend (.env)
```
NUXT_PUBLIC_API_BASE_URL=http://localhost:3000/api
NODE_ENV=development
```

## Useful Commands

### Prisma Commands
```bash
# Generate client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Reset database
npx prisma migrate reset

# Open Prisma Studio
npx prisma studio
```

### Docker Commands
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Rebuild services
docker-compose up --build
```

## Troubleshooting

### Database Connection Issues
1. Kiểm tra PostgreSQL đang chạy: `docker ps`
2. Kiểm tra DATABASE_URL trong .env
3. Thử connect qua pgAdmin trước

### Port Conflicts
- Frontend: port 3001
- Backend: port 3000
- PostgreSQL: port 5432
- pgAdmin: port 8080

### Prisma Issues
```bash
# Clear generated files
rm -rf node_modules/.prisma
rm -rf generated

# Regenerate
npx prisma generate
```

## Next Steps
1. Khởi tạo database và tables
2. Seed sample data
3. Test API endpoints
4. Test frontend connectivity