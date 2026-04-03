# Hướng dẫn liên kết Frontend và Backend

## Cấu hình đã thực hiện

### Backend (NestJS)
- **Port**: 3000
- **API Prefix**: `/api`
- **CORS**: Đã cấu hình cho frontend port 3001
- **Endpoint test**: `GET /api/health`

### Frontend (Nuxt.js)
- **Port**: 3001
- **API Base URL**: `http://localhost:3000/api`
- **Proxy**: Đã cấu hình dev proxy cho `/api`

## Khởi chạy ứng dụng

### 1. Khởi chạy Backend
```bash
cd be
yarn install
yarn dev
```

Backend sẽ chạy trên: http://localhost:3000
API sẽ có prefix: http://localhost:3000/api

### 2. Khởi chạy Frontend
```bash
cd FE
yarn install
yarn dev
```

Frontend sẽ chạy trên: http://localhost:3001

### 3. Kiểm tra kết nối
Truy cập: http://localhost:3001/test để kiểm tra kết nối giữa FE và BE

## Sử dụng API trong Frontend

### 1. Sử dụng composable useApi (cơ bản)
```typescript
<script setup>
const { get, post } = useApi()

// Gọi API
const data = await get('/health')
const result = await post('/users', { name: 'John' })
</script>
```

### 2. Sử dụng composable useApiService (nâng cao)
```typescript
<script setup>
const { auth, batteries, vehicles, auctions } = useApiService()

// Authentication
const loginResult = await auth.login({ email, password })

// Batteries
const batteries = await batteries.getAll()
const battery = await batteries.getById('123')

// Vehicles
const vehicles = await vehicles.getAll({ page: 1, limit: 10 })

// Auctions
const auctions = await auctions.getActive()
</script>
```

## Cấu trúc API đã tạo

### Authentication
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/logout` - Đăng xuất
- `GET /api/auth/profile` - Lấy thông tin profile
- `PATCH /api/auth/profile` - Cập nhật profile

### Batteries
- `GET /api/batteries` - Danh sách pin
- `GET /api/batteries/:id` - Chi tiết pin
- `POST /api/batteries` - Tạo mới pin
- `PATCH /api/batteries/:id` - Cập nhật pin
- `DELETE /api/batteries/:id` - Xóa pin

### Vehicles
- `GET /api/vehicles` - Danh sách xe
- `GET /api/vehicles/:id` - Chi tiết xe
- `POST /api/vehicles` - Tạo mới xe
- `PATCH /api/vehicles/:id` - Cập nhật xe
- `DELETE /api/vehicles/:id` - Xóa xe

### Auctions
- `GET /api/auctions` - Danh sách đấu giá
- `GET /api/auctions/:id` - Chi tiết đấu giá
- `POST /api/auctions` - Tạo đấu giá mới
- `POST /api/auctions/:id/bid` - Đặt giá

### Files
- `POST /api/files/upload` - Upload file

## Files đã tạo/cập nhật

### Backend
- `be/src/main.ts` - Cấu hình CORS và global prefix
- `be/src/app.controller.ts` - Thêm endpoint `/health`

### Frontend
- `FE/.env` - Cấu hình API base URL
- `FE/nuxt.config.ts` - Cấu hình runtime và dev proxy
- `FE/composables/useApi.ts` - Composable cơ bản cho API calls
- `FE/composables/useApiService.ts` - Composable nâng cao với typed APIs
- `FE/types/api.ts` - Type definitions cho API
- `FE/pages/test.vue` - Trang test kết nối

## Troubleshooting

### Nếu có lỗi CORS
- Kiểm tra backend có chạy trên port 3000
- Kiểm tra cấu hình CORS trong `be/src/main.ts`

### Nếu không kết nối được API
- Kiểm tra file `.env` trong folder FE
- Kiểm tra cấu hình `nuxt.config.ts`
- Kiểm tra console browser và terminal backend

### Nếu có lỗi TypeScript
- Chạy `npm run dev` lại cho frontend
- Kiểm tra file types trong `FE/types/api.ts`

## Bước tiếp theo

1. Implement các controller thực tế trong backend (batteries, vehicles, auctions, auth)
2. Tạo database schema với Prisma
3. Implement authentication middleware
4. Tạo các pages thực tế trong frontend sử dụng API
5. Thêm error handling và loading states
6. Implement file upload functionality
7. Thêm real-time features (WebSocket) cho auction bidding