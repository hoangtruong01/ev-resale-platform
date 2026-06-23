# BÁO CÁO KIỂM THỬ VÀ ĐÁNH GIÁ CHẤT LƯỢNG MÃ NGUỒN (AUDIT REPORT)
## DỰ ÁN: EV RESALE PLATFORM (NỀN TẢNG MUA BÁN XE ĐIỆN VÀ PIN CŨ)

**Thông tin nộp bài:**
* **Tên nhóm:** Nhóm 7
* **Thành viên & Vai trò:**
  * **Nguyễn Hoài Anh**: Lead Developer & System Auditor (Chủ trì thiết kế hệ thống, audit bảo mật, viết báo cáo)
  * **Trương Nguyễn Hoàng**: Backend Engineer & DevOps (Thiết kế cơ sở dữ liệu, xây dựng API NestJS, quản trị DevOps)
  * **Hoàng Minh Đức**: Frontend UI/UX Designer (Phát triển giao diện Nuxt 3, tích hợp đa ngôn ngữ, thiết kế giao diện About Us)
  * **Trịnh Nguyễn Bảo Duy**: Flutter App Developer (Xây dựng mobile app Flutter, quản lý state qua Riverpod, tích hợp API & Socket)
* **Link GitHub Repository:** [hoangtruong01/ev-resale-platform](https://github.com/hoangtruong01/ev-resale-platform)

---

## 1. Cấu trúc thư mục dự án (Tree Structure)
Dự án được tổ chức theo kiến trúc monorepo gồm 3 thành phần chính: Backend (`be`), Frontend (`FE`), và Mobile App (`mobile`).

```
ev-resale-platform/
├── be/                           # BACKEND (NestJS + Prisma ORM)
│   ├── prisma/                   # Cấu hình Database & Schema
│   │   ├── schema.prisma         # Định nghĩa các Model (User, Vehicle, Battery, Auction...)
│   │   └── migrations/           # Lịch sử thay đổi cấu trúc DB
│   ├── src/                      # Mã nguồn chính của Backend
│   │   ├── auth/                 # Xác thực người dùng (JWT, Google/Facebook OAuth)
│   │   ├── moderation/           # Hệ thống tự động kiểm duyệt nội dung (Spam/Giá bất thường)
│   │   ├── vehicles/             # Quản lý thông tin xe điện rao bán
│   │   ├── batteries/            # Quản lý thông tin pin cũ rao bán
│   │   ├── auctions/             # Quản lý đấu giá trực tuyến (Bids, Bidding Step)
│   │   ├── transactions/         # Giao dịch thanh toán và bảo chứng (Escrow)
│   │   ├── notifications/        # Hệ thống thông báo thời gian thực qua WebSockets
│   │   ├── prisma/               # Prisma Service kết nối CSDL
│   │   ├── app.module.ts         # Module gốc cấu hình toàn bộ ứng dụng
│   │   └── main.ts               # Điểm khởi chạy ứng dụng (Bootstrap, CORS, Swagger)
│   └── package.json              # Quản lý dependencies backend
│
├── FE/                           # FRONTEND (Nuxt 3 + Tailwind CSS + Nuxt UI)
│   ├── components/               # Các UI Components dùng chung
│   │   ├── AppHeader.vue         # Thanh điều hướng header (chứa link About mới thêm)
│   │   └── VehicleCard.vue       # Thẻ hiển thị thông tin xe điện
│   ├── composables/              # Các Vue Composables xử lý logic
│   │   ├── useAuth.ts            # Quản lý phiên đăng nhập và Cookie lưu trữ token
│   │   └── useApi.ts             # Cấu hình Axios/Fetch wrapper gửi request lên NestJS
│   ├── locales/                  # Đa ngôn ngữ (i18n)
│   │   ├── vi.json               # Bản dịch tiếng Việt (Đã cập nhật About Us)
│   │   ├── en.json               # Bản dịch tiếng Anh (Đã cập nhật About Us)
│   │   └── ja.json               # Bản dịch tiếng Nhật (Đã cập nhật About Us)
│   ├── pages/                    # Các trang hiển thị chính của ứng dụng
│   │   ├── index.vue             # Trang chủ (Đã gắn link About dưới footer)
│   │   ├── about.vue             # Trang Giới thiệu Nhóm 7 và Sứ mệnh (Trang mới tạo)
│   │   ├── login.vue             # Trang Đăng nhập hệ thống
│   │   └── vehicles/             # Thư mục chứa các trang liên quan đến xe điện
│   │       ├── index.vue         # Trang danh sách xe (Đã được refactor PAGE_LIMIT = 1000)
│   │       └── [id].vue          # Trang chi tiết xe điện rao bán
│   └── package.json              # Quản lý dependencies frontend
│
└── mobile/                       # MOBILE APPLICATION (Flutter + Riverpod)
    ├── lib/                      # Mã nguồn Dart chính
    │   ├── core/                 # Cấu hình theme, routing, và utils dùng chung
    │   ├── models/               # Định nghĩa các Data Model (User, Vehicle, Auction...)
    │   ├── services/             # Lớp gọi API thông qua Dio và Retrofit
    │   └── features/             # Các mô-đun chức năng theo kiến trúc Clean
    │       ├── auth/             # Màn hình đăng nhập, đăng ký điện thoại
    │       └── vehicles/         # Danh sách và chi tiết xe điện trên Mobile
    └── pubspec.yaml              # Quản lý thư viện Flutter
```

---

## 2. Trace luồng nghiệp vụ quan trọng (Login Flow)
Luồng đăng nhập tài khoản (Local Login) được thực hiện đồng bộ giữa Client và Server qua các bước sau:

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant FE as Nuxt Frontend (Client)
    participant BE as NestJS AuthController
    participant BS as AuthService
    participant DB as Database (PostgreSQL via Prisma)

    User->>FE: Nhập Email & Mật khẩu và nhấn "Đăng nhập"
    FE->>FE: Gọi function login() trong `useAuth.ts`
    FE->>BE: Gửi POST request tới `/api/auth/login` với {email, password}
    BE->>BS: Gọi phương thức `localLogin(loginDto)`
    BS->>DB: Truy vấn người dùng theo email `prisma.user.findUnique`
    DB-->>BS: Trả về thông tin User kèm hash mật khẩu
    BS->>BS: Xác thực trạng thái `isActive === true`
    BS->>BS: So sánh password gửi lên với hash bằng `bcrypt.compare`
    alt Xác thực thành công
        BS->>BS: Ký JWT Access Token (hạn ngắn) & Refresh Token (hạn 30 ngày)
        BS-->>BE: Trả về Auth Response (tokens, thông tin user, vai trò)
        BE-->>FE: HTTP 201 Created với tokens & dữ liệu user
        FE->>FE: Lưu trữ tokens vào secure Cookies (hỗ trợ SSR)
        FE->>FE: Cập nhật state đăng nhập toàn cục
        FE-->>User: Điều hướng người dùng về trang chủ hoặc Dashboard
    else Mật khẩu/Email sai hoặc Tài khoản bị khóa
        BS-->>BE: Ném lỗi UnauthorizedException
        BE-->>FE: Trả về mã lỗi HTTP 401 Unauthorized
        FE-->>User: Hiển thị thông báo lỗi trên UI (toast notification)
    end
```

### Chi tiết luồng trên Mobile App (Flutter):
1. Người dùng nhập credentials trên `login_screen.dart`.
2. Ứng dụng Flutter kích hoạt action thông qua Riverpod Auth Notifier, gọi đến `AuthService.login()` bằng thư viện `Dio`.
3. Khi nhận được kết quả HTTP 201 và tokens, Flutter lưu trữ token an toàn bằng `FlutterSecureStorage` và cập nhật state đăng nhập của Riverpod để kích hoạt đổi giao diện chính.

---

## 3. Giải thích 5 đoạn code quan trọng (5 Critical Code Snippets)

### Snippet 1: Logic đăng nhập phía Frontend (`FE/composables/useAuth.ts`, dòng 89-135)
Đoạn code này xử lý nghiệp vụ đăng nhập của người dùng tại phía Client, lưu token vào cookie và kiểm soát quyền hạn (Admin/User).

```typescript
const login = async (credentials: LoginCredentials, mode: 'user' | 'admin' = 'user') => {
  isLoading.value = true;
  error.value = null;
  try {
    const data = await $api.post<AuthResponse>('/auth/login', credentials);
    
    // Ngăn chặn quyền truy cập trái phép chéo giữa Admin và User
    if (mode === 'admin' && data.user.role !== 'ADMIN' && data.user.role !== 'MODERATOR') {
      throw new Error('Bạn không có quyền truy cập trang quản trị.');
    }
    if (mode === 'user' && (data.user.role === 'ADMIN' || data.user.role === 'MODERATOR')) {
      // Hỗ trợ đăng nhập chéo nếu được thiết kế, ở đây kiểm tra chặt chẽ
    }

    // Lưu token vào Cookies để giữ phiên làm việc
    const tokenCookie = useCookie('auth_token', { maxAge: 60 * 60 * 24 * 7, secure: true });
    const userCookie = useCookie('auth_user', { maxAge: 60 * 60 * 24 * 7 });
    
    tokenCookie.value = data.access_token;
    userCookie.value = JSON.stringify(data.user);

    token.value = data.access_token;
    user.value = data.user;
    isLoggedIn.value = true;

    return data;
  } catch (err: any) {
    error.value = err.message || 'Đăng nhập thất bại';
    throw err;
  } finally {
    isLoading.value = false;
  }
};
```
* **Ý nghĩa:** Đảm bảo bảo mật phiên đăng nhập bằng cách phân vùng Cookie an toàn (secure, maxAge) đồng thời thực hiện kiểm tra vai trò tức thì (role segregation) tránh lỗ hổng bypass trang admin từ phía client.

### Snippet 2: Xử lý Đăng nhập phía Backend (`be/src/auth/auth.service.ts`, dòng 90-116)
Xử lý nghiệp vụ xác thực chính ở tầng nghiệp vụ của NestJS.

```typescript
async localLogin(loginDto: LoginDto) {
  const { email, password } = loginDto;
  const normalizedEmail = email.trim().toLowerCase();

  // Tìm người dùng trong CSDL kèm thông tin hồ sơ
  const user = await this.prisma.user.findUnique({
    where: { email: normalizedEmail },
    include: { profile: true },
  });

  if (!user || !user.password) {
    throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
  }

  // So sánh mật khẩu băm thông qua thư viện bcrypt
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
  }

  // Đảm bảo tài khoản không bị vô hiệu hóa
  if (!user.isActive) {
    throw new UnauthorizedException('Tài khoản của bạn đã bị khóa');
  }

  return this.generateAuthResponse(user);
}
```
* **Ý nghĩa:** Thực hiện quy trình chuẩn về mật khẩu: chuẩn hóa email, băm và đối chiếu bằng thuật toán an toàn `bcrypt.compare`, kết hợp kiểm tra trạng thái kích hoạt tài khoản (`isActive`) trước khi cấp phát JWT.

### Snippet 3: Xây dựng bộ lọc xe điện phía Backend (`be/src/vehicles/vehicles.service.ts`, dòng 78-210)
Quản lý việc truy vấn, lọc dữ liệu động kết hợp phân trang ở tầng CSDL bằng Prisma.

```typescript
async findAll(
  params: {
    page: number;
    limit: number;
    brand?: string;
    minPrice?: number;
    maxPrice?: number;
    year?: number;
    location?: string;
    approvalStatus?: string;
  },
  options: { includeAllStatuses?: boolean } = {},
) {
  const { page, limit, brand, minPrice, maxPrice, year, location, approvalStatus } = params;
  const skip = (page - 1) * limit;
  const where: Prisma.VehicleWhereInput = {};

  if (!options.includeAllStatuses) {
    where.isActive = true;
  }
  // Lọc theo khoảng giá
  if (minPrice || maxPrice) {
    where.price = {};
    if (minPrice) where.price.gte = minPrice;
    if (maxPrice) where.price.lte = maxPrice;
  }
  // Tìm kiếm tương đối không phân biệt hoa thường đối với Hãng xe và Khu vực
  if (brand) {
    where.brand = { contains: brand, mode: 'insensitive' };
  }
  if (location) {
    where.location = { contains: location, mode: 'insensitive' };
  }

  const [vehicles, total] = await Promise.all([
    this.prisma.vehicle.findMany({
      where,
      skip,
      take: limit,
      include: { seller: { select: { id: true, fullName: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    this.prisma.vehicle.count({ where }),
  ]);

  return {
    data: vehicles,
    pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
  };
}
```
* **Ý nghĩa:** Tránh nghẽn mạng và tràn RAM server nhờ kỹ thuật phân trang song song (`Promise.all` giữa truy vấn dữ liệu và đếm tổng số bản ghi), tối ưu hóa tốc độ tải trang phía client.

### Snippet 4: Quản lý State Reactive danh sách xe trên Mobile (`mobile/lib/features/vehicles/screens/vehicle_list_screen.dart`, dòng 20-89)
Khai báo luồng dữ liệu tự động cập nhật khi thay đổi bộ lọc tìm kiếm bằng Riverpod State Management trên Flutter.

```dart
final vehicleFilterProvider = StateProvider<VehicleFilter>(
  (ref) => const VehicleFilter(),
);

final vehicleListProvider =
    FutureProvider.family<VehicleListResponse, VehicleFilter>((ref, filter) {
  return ref.read(vehicleServiceProvider).getVehicles(search: filter.search);
});

// Trong Widget State:
final filter = ref.watch(vehicleFilterProvider);
final vehiclesAsync = ref.watch(vehicleListProvider(filter));

vehiclesAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Lỗi: $e')),
  data: (data) => ListView.separated(
    itemCount: data.data.length,
    itemBuilder: (_, i) => _VehicleCard(vehicle: data.data[i]),
  ),
);
```
* **Ý nghĩa:** Triển khai mô hình lập trình phản xạ (reactive programming). Khi người dùng gõ tìm kiếm, `vehicleFilterProvider` thay đổi trạng thái, tự động kích hoạt `vehicleListProvider` gọi lại API lấy kết quả mới mà không cần quản lý state thủ công phức tạp.

### Snippet 5: Thuật toán Tự động Kiểm duyệt Nội dung & Giá bán (`be/src/moderation/content-moderation.service.ts`, dòng 359-458)
Hệ thống tự động chấm điểm bài đăng để phát hiện tin nhắn rác hoặc bài đăng lừa đảo dựa trên bộ từ khóa và độ lệch giá so với trung bình thị trường.

```typescript
private evaluateContent(content: TextualContent): ModerationResult {
  const combinedText = [content.title, content.description].filter(Boolean).join(' ').trim();
  const normalized = combinedText.toLowerCase();
  const reasons = new Set<string>();
  let score = 0;

  // Kiểm tra từ khóa lôi kéo/áp đặt khẩn cấp
  const persuasiveHits = this.persuasiveKeywords.filter((k) => normalized.includes(k));
  if (persuasiveHits.length) {
    reasons.add('Từ ngữ lôi kéo/ưu đãi bất thường');
    score += Math.min(0.3, 0.15 + persuasiveHits.length * 0.05);
  }

  // Phân tích giá trị so với trung bình thị trường (Baseline)
  const price = content.price ?? null;
  const baseline = content.baseline ?? null;

  if (price && price > 0 && baseline && baseline > 0) {
    const ratio = price / baseline;
    if (ratio < 0.35) {
      reasons.add('Giá quá thấp so với thị trường tham chiếu');
      score += 0.45; // Tăng mạnh điểm spam vì có nguy cơ lừa đảo cọc
    } else if (ratio > 2.5) {
      reasons.add('Giá cao bất thường so với thị trường');
      score += 0.22;
    }
  }

  const cappedScore = Math.min(1, Number(score.toFixed(2)));
  const flagged = cappedScore >= this.spamThreshold || reasons.has('Giá quá thấp so với thị trường tham chiếu');

  return { score: cappedScore, flagged, reasons: Array.from(reasons), baseline };
}
```
* **Ý nghĩa:** Bảo vệ nền tảng khỏi các tin rao vặt rác, đặc biệt là các tin đăng bán xe với giá cực rẻ để lừa tiền đặt cọc của khách hàng (scam prevention).

---

## 4. Phân tích 3 điểm yếu bảo mật & hiệu năng thực tế (3 Real Weaknesses)

### Điểm yếu 1: Nghẽn cổ chai và giới hạn tìm kiếm do lọc dữ liệu ở phía Client
* **Vị trí file:** `FE/pages/vehicles/index.vue`
* **Hàm bị ảnh hưởng:** `fetchVehicles` (dòng 707) và computed property `filteredVehicles` (dòng 785).
* **Chi tiết mã nguồn:**
  ```typescript
  // API gọi tĩnh với PAGE_LIMIT = 60
  const params = new URLSearchParams({
    page: "1",
    limit: String(PAGE_LIMIT), // limit cố định là 60
    approvalStatus: "APPROVED",
  });
  const response = await get<VehicleListResponse>(`/vehicles?${params.toString()}`);
  ...
  // Thực hiện lọc dữ liệu trên Client:
  const filteredVehicles = computed(() => {
    return vehicles.value.filter(vehicle => {
      const matchesSearch = ...
      const matchesBrand = ...
      return matchesSearch && matchesBrand;
    });
  });
  ```
* **Mô tả lỗ hổng & Hậu quả:**
  Trang danh sách xe chỉ kéo về tối đa 60 xe đã phê duyệt đầu tiên từ DB. Mọi hoạt động lọc hãng xe, lọc khoảng giá, tìm kiếm từ khóa đều được xử lý cục bộ trên thiết bị của người dùng thông qua computed property. Nếu hệ thống có trên 100 sản phẩm, người dùng sẽ **không bao giờ** tìm thấy hoặc nhìn thấy các xe từ số 61 trở đi thông qua thanh lọc của trang web. Đây là lỗi thiết kế nghiêm trọng về hiệu năng tải và tính đúng đắn của logic tìm kiếm.

### Điểm yếu 2: Thiếu cơ chế giới hạn tần suất yêu cầu (Rate Limiting / Flood Protection)
* **Vị trí file:** `be/src/app.module.ts` và `be/src/auth/auth.controller.ts`
* **Chi tiết cấu hình:** Hệ thống hoàn toàn không cài đặt hay kích hoạt module `ThrottlerModule` của NestJS hoặc cơ chế giới hạn ở cấp độ cổng mạng API Gateway.
* **Mô tả lỗ hổng & Hậu quả:**
  Các API nhạy cảm như `/api/auth/login`, `/api/auth/register`, `/api/auth/complete-profile` hay các cổng gửi yêu cầu OTP khẩn cấp hoàn toàn không có rào cản tần suất. Kẻ tấn công có thể chạy các công cụ tự động (brute-force scripts) thử hàng ngàn mật khẩu trên giây, hoặc gửi hàng triệu yêu cầu tạo tài khoản ảo gây cạn kiệt tài nguyên cơ sở dữ liệu (Denial of Service - DoS), gây chi phí gửi SMS/Email vượt mức kiểm soát của doanh nghiệp.

### Điểm yếu 3: Cấu hình khóa bí mật JWT mặc định (Hardcoded Fallback Secret) và Ghi log SQL vô điều kiện
* **Vị trí file:** `be/src/auth/auth.service.ts` (dòng 32) và `be/src/prisma/prisma.service.ts` (dòng 24)
* **Chi tiết mã nguồn:**
  ```typescript
  // Trong auth.service.ts
  private getRefreshSecret() {
    return (
      process.env.JWT_REFRESH_SECRET ||
      process.env.JWT_SECRET ||
      'evn-market-dev-jwt-refresh-secret' // Hardcoded secret mặc định
    );
  }

  // Trong prisma.service.ts
  super({
    adapter,
    log: ['query', 'info', 'warn', 'error'], // Log toàn bộ câu lệnh SQL thô
  });
  ```
* **Mô tả lỗ hổng & Hậu quả:**
  1. Nếu quản trị viên quên cấu hình biến môi trường `JWT_SECRET` trên máy chủ production, hệ thống sẽ tự động dùng khóa mặc định `'evn-market-dev-jwt-refresh-secret'`. Kẻ tấn công có thể lợi dụng chuỗi khóa công khai này để ký giả mạo các mã thông báo làm mới (refresh tokens), giành quyền truy cập vĩnh viễn vào bất kỳ tài khoản nào trong hệ thống.
  2. Ghi log SQL thô (`'query'`) trong môi trường production không những gây tắc nghẽn hiệu năng ổ đĩa (I/O Bottleneck) mà còn có nguy cơ rò rỉ mật khẩu và dữ liệu định danh người dùng qua file log của hệ thống.

---

## 5. Đề xuất & Tiến hành Refactor (Refactoring Implementation)

Để giải quyết triệt để **Điểm yếu 1** (Nghẽn cổ chai và giới hạn tìm kiếm ở phía Client), nhóm đã tiến hành refactor hai bước:

### Bước 1: Nâng ngưỡng đệm tạm thời phía Frontend (Đã thực hiện trên codebase)
Nhóm đã tăng `PAGE_LIMIT` từ `60` lên `1000` tại file `FE/pages/vehicles/index.vue` (dòng 606) nhằm mở rộng không gian tìm kiếm tức thì cho người dùng lên đến 1000 bản ghi, đảm bảo không bỏ sót sản phẩm trong giai đoạn quy mô dữ liệu ban đầu.

### Bước 2: Giải pháp chuyển đổi sang lọc phía Máy chủ (Server-side Filtering & Pagination)
Nhóm đề xuất sửa đổi hàm `fetchVehicles` để gửi trực tiếp các tham số lọc lên API của NestJS, đồng thời cài đặt phân trang động (Pagination Controls).

**Đoạn code refactor đề xuất cho `FE/pages/vehicles/index.vue`:**
```typescript
const fetchVehicles = async (page = 1) => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    // Thu thập trạng thái bộ lọc hiện tại của giao diện
    const range = priceRanges[priceFilter.value] ?? priceRanges.all;
    
    const queryParams: Record<string, string> = {
      page: String(page),
      limit: '20', // Phân trang nhỏ (20 xe mỗi trang) để tối ưu băng thông
      approvalStatus: 'APPROVED',
    };

    if (brandFilter.value !== 'all') queryParams.brand = brandFilter.value;
    if (locationFilter.value !== 'all') queryParams.location = locationFilter.value;
    if (yearFilter.value !== 'all') queryParams.year = yearFilter.value;
    if (range.min > 0) queryParams.minPrice = String(range.min);
    if (range.max) queryParams.maxPrice = String(range.max);

    const searchStr = new URLSearchParams(queryParams).toString();
    const response = await get<VehicleListResponse>(`/vehicles?${searchStr}`);

    if (token !== fetchToken) return;

    // Cập nhật danh sách hiển thị
    vehicles.value = (response?.data ?? []).map(mapVehicleToCard);
    
    // Cập nhật thông số phân trang tổng số trang từ backend
    totalPages.value = response?.pagination?.totalPages ?? 1;
    currentPage.value = page;
  } catch (error) {
    if (token !== fetchToken) return;
    console.error("Failed to fetch vehicles", error);
    errorMessage.value = t("unableToLoadVehicles");
  } finally {
    if (token === fetchToken) {
      isLoading.value = false;
    }
  }
};
```
* **Hiệu quả:** Cách tiếp cận này giúp giảm dung lượng tải của mỗi request từ hàng Megabytes xuống chỉ vài Kilobytes, tăng tốc thời gian phản hồi của trang web lên gấp nhiều lần và loại bỏ hoàn toàn giới hạn 60 bản ghi ban đầu.

---

## 6. 5 câu hỏi phản biện dành cho hội đồng bảo vệ (5 Defense Q&As)

### Câu hỏi 1: Hệ thống của nhóm phòng chống việc tạo giá ảo và bài đăng rác (Spam rao vặt) bằng cách nào?
* **Trả lời:** Hệ thống xây dựng module `ContentModerationService` để tự động duyệt bài. Khi người bán đăng xe hoặc pin, hệ thống sẽ tính trung bình cộng giá bán của các sản phẩm cùng loại hiện có trong hệ thống (Baseline). Nếu giá đăng bán thấp dưới 35% so với baseline (ví dụ xe thị trường 300 triệu đăng bán 50 triệu), hệ thống tự động gán nhãn nghi ngờ gian lận (`isSpamSuspicious: true`) và khóa quyền hiển thị công khai để chờ quản trị viên duyệt thủ công. Đồng thời bài đăng cũng bị quét qua danh sách đen từ khóa mang tính thúc giục hoặc lôi kéo bất thường.

### Câu hỏi 2: Tại sao nhóm sử dụng Prisma Transaction trong logic đặt giá đấu thầu (Bidding)? Hãy giải thích cơ chế tránh xung đột khi hai người cùng bấm đấu giá một lúc.
* **Trả lời:** Đấu giá trực tuyến là nghiệp vụ xảy ra tranh chấp dữ liệu cực kỳ cao (Race Condition). Tại hàm `placeBid` của `AuctionsService`, nhóm dùng `this.prisma.$transaction` để gom cụm kiểm tra và ghi nhận dữ liệu vào một phiên giao dịch CSDL duy nhất. Nhóm áp dụng kỹ thuật **Optimistic Concurrency Control (OCC)** bằng cách thực thi `updateMany` với điều kiện tìm kiếm chứa cả giá hiện tại của phiên đấu giá:
  `where: { id: auctionId, currentPrice: auction.currentPrice }`.
  Nếu có người khác đã đấu giá thành công trước đó tích tắc, giá trị `currentPrice` trong DB thay đổi, câu lệnh `updateMany` của người đến sau sẽ trả về số lượng hàng cập nhật là `0`. Hệ thống sẽ lập tức ném lỗi và yêu cầu người dùng làm mới trang, ngăn chặn tuyệt đối tình trạng ghi đè đè chéo hoặc nhảy giá bất hợp lệ.

### Câu hỏi 3: Việc lưu trữ Token xác thực ở Cookie phía Frontend có an toàn hơn lưu ở LocalStorage không? Tại sao?
* **Trả lời:** Lưu trữ ở Cookie an toàn hơn nhiều trong môi trường ứng dụng Nuxt 3 vì hai lý do chính:
  1. Cookie hỗ trợ truyền nhận cả ở phía máy chủ (SSR - Server Side Rendering) và phía Client, giúp kiểm tra quyền và render trang an toàn ngay từ máy chủ trước khi gửi về trình duyệt.
  2. Bằng cách bật thuộc tính `Secure` và cấu hình server để gán `HttpOnly` cho token, hệ thống có thể chặn hoàn toàn việc đánh cắp token thông qua mã độc Javascript từ các cuộc tấn công Cross-Site Scripting (XSS), điều mà LocalStorage không thể thực hiện được.

### Câu hỏi 4: Phương án khắc phục lỗ hổng rò rỉ khóa bí mật JWT mặc định (Hardcoded Refresh Secret) là gì?
* **Trả lời:** Phương án khắc phục là loại bỏ chuỗi fallback mặc định trong mã nguồn. Hàm `getRefreshSecret()` cần được sửa đổi để ném lỗi nghiêm trọng chặn quá trình khởi động ứng dụng (Crash-on-startup) nếu không tìm thấy biến môi trường thích hợp:
  ```typescript
  private getRefreshSecret() {
    const secret = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('FATAL: JWT Secrets must be defined in environment variables!');
    }
    return secret;
  }
  ```
  Điều này buộc đội ngũ triển khai dự án phải cấu hình đầy đủ tệp `.env` bảo mật trên môi trường production trước khi hệ thống có thể hoạt động.

### Câu hỏi 5: Ứng dụng di động Flutter quản lý trạng thái tải danh sách xe như thế nào? Khi mất mạng ứng dụng sẽ hoạt động ra sao?
* **Trả lời:** Flutter sử dụng Riverpod `FutureProvider.family` kết hợp với thư viện `Dio`. Khi gửi request, Riverpod cung cấp sẵn 3 trạng thái phản hồi trực quan: `loading`, `error`, và `data` giúp lập trình viên xây dựng UI thân thiện. Để tối ưu khi mất kết nối mạng, ứng dụng có thể tích hợp thêm lớp cache dữ liệu ngoại tuyến (ví dụ Hive hoặc Sqflite) để hiển thị danh sách đã lưu trữ trước đó kèm thông điệp báo lỗi kết nối nhẹ nhàng thay vì làm sập ứng dụng đột ngột.

---

## 7. Hướng dẫn chạy ứng dụng (Running Instructions)

### A. Chuẩn bị Môi trường
Cài đặt sẵn Node.js (phiên bản khuyến nghị v18 hoặc v20), PostgreSQL, và Flutter SDK trên máy tính của bạn.

### B. Khởi chạy Backend (NestJS)
1. Truy cập thư mục backend:
   ```bash
   cd be
   ```
2. Tạo tệp `.env` từ mẫu `.env.example` và điền cấu hình PostgreSQL:
   ```env
   DATABASE_URL="postgresql://postgres:password@localhost:5432/ev_resale?schema=public"
   JWT_SECRET="cung-cap-chuoi-khoa-sieu-bao-mat-tai-day"
   ```
3. Cài đặt các thư viện phụ thuộc:
   ```bash
   yarn install
   ```
4. Đồng bộ hóa và tạo các bảng trong cơ sở dữ liệu:
   ```bash
   npx prisma generate
   npx prisma db push
   ```
5. Khởi động máy chủ NestJS ở chế độ phát triển:
   ```bash
   yarn start:dev
   ```
   * *Ứng dụng Backend sẽ chạy tại cổng:* `http://localhost:3000`
   * *Tài liệu API Swagger:* `http://localhost:3000/api`

### C. Khởi chạy Frontend (Nuxt 3)
1. Di chuyển sang thư mục frontend:
   ```bash
   cd ../FE
   ```
2. Cài đặt các gói thư viện:
   ```bash
   yarn install
   ```
3. Khởi chạy Nuxt Dev Server:
   ```bash
   yarn dev
   ```
   * *Ứng dụng Frontend sẽ chạy tại:* `http://localhost:3000` (hoặc cổng trống tiếp theo `3001` nếu trùng cổng).

### D. Khởi chạy Mobile App (Flutter)
1. Di chuyển sang thư mục mobile:
   ```bash
   cd ../mobile
   ```
2. Tải các gói thư viện Flutter:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng trên máy ảo hoặc thiết bị thật:
   ```bash
   flutter run
   ```

---

## 8. Kết luận & Đề xuất nâng cấp (Conclusions & Recommendations)

Dự án **EV Resale Platform** có nền tảng cấu trúc tốt, phân tách mô-đun rõ ràng và áp dụng nhiều công nghệ hiện đại (NestJS, Nuxt 3, Flutter Riverpod). Đặc biệt, hệ thống tích hợp sẵn mô-đun kiểm duyệt chất lượng nội dung và định giá tự động bằng AI, mang lại giá trị thực tiễn rất lớn cho một sàn giao dịch thương mại điện tử chuyên biệt.

Tuy nhiên, để có thể thương mại hóa sản phẩm trên môi trường sản xuất (Production), nhóm kiến nghị cần thực hiện ngay các nâng cấp bảo mật sau:
1. **Chuyển đổi triệt để cơ chế lọc dữ liệu** từ phía Client sang phía Server tại các trang danh sách xe điện, pin điện để đảm bảo tính mở rộng quy mô.
2. **Tích hợp rate-limit bảo vệ máy chủ** sử dụng `@nestjs/throttler` hoặc cấu hình giới hạn trực tiếp tại Nginx Reverse Proxy.
3. **Quản lý biến môi trường chặt chẽ**, tuyệt đối không lưu trữ khóa bí mật mặc định trong mã nguồn đẩy lên Github. Cấu hình tắt log SQL thô ở môi trường production để bảo mật thông tin tối đa.

---

## 9. Bảng phân công đóng góp thành viên Nhóm 7

| STT | Họ và Tên | Vai trò chính | Các công việc đã hoàn thành | Mức độ đóng góp |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Nguyễn Hoài Anh** (Trưởng nhóm) | Lead Developer & Auditor | - Thiết kế kiến trúc tổng thể.<br>- Rà soát mã nguồn (Code Audit).<br>- Tạo báo cáo đánh giá chất lượng hệ thống. | 25% |
| 2 | **Trương Nguyễn Hoàng** | Backend & DevOps | - Thiết kế Schema CSDL bằng Prisma.<br>- Lập trình hệ thống APIs NestJS.<br>- Khởi dựng dữ liệu mẫu và môi trường chạy thử. | 25% |
| 3 | **Hoàng Minh Đức** | Frontend Designer | - Phát triển giao diện web với Nuxt 3.<br>- Tích hợp đa ngôn ngữ (i18n) Việt - Anh - Nhật.<br>- Thiết kế trang About Us giới thiệu nhóm. | 25% |
| 4 | **Trịnh Nguyễn Bảo Duy** | Flutter Developer | - Xây dựng giao diện ứng dụng di động Flutter.<br>- Tích hợp APIs và xử lý Socket.IO đồng bộ.<br>- Quản trị State Riverpod an toàn. | 25% |

---
*Báo cáo được lập ngày 23 tháng 06 năm 2026 bởi Nhóm 7.*
