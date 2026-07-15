# Giải Thích Hệ Thống Quản Trị (Admin & Moderator System Flow)

Tài liệu này giải thích chi tiết cơ chế bảo mật phân quyền, kiến trúc API backend NestJS, giao diện Web Nuxt Dashboard và Bảng điều khiển admin trên ứng dụng di động Flutter.

---

## 1. Cơ Chế Phân Quyền & Bảo Mật (Role-Based Access Control)

Hệ thống phân chia người dùng làm 3 vai trò chính dựa trên trường `role` trong cơ sở dữ liệu:
1. **`USER`:** Người dùng thông thường (chỉ có quyền đăng bán, mua hàng, đặt giá đấu giá và chat).
2. **`MODERATOR`:** Điều phối viên (được cấp một số quyền hạn cụ thể do Admin cấu hình).
3. **`ADMIN`:** Quản trị viên tối cao (có toàn quyền cấu hình hệ thống, quản lý tài chính và phân quyền).

### A. Phân quyền ở Backend NestJS
Backend bảo vệ các endpoint quản trị bằng cách kết hợp 3 lớp Guards:
* `JwtAuthGuard`: Xác thực token JWT của người dùng.
* `RolesGuard` (kết hợp với decorator `@Roles`): Kiểm tra vai trò của tài khoản. Ví dụ, đa số API admin yêu cầu `@Roles(UserRole.ADMIN)`. Một số API kiểm duyệt được mở thêm cho Moderator bằng `@Roles(UserRole.ADMIN, UserRole.MODERATOR)`.
* `PermissionsGuard` (kết hợp với `@Permissions`): Kiểm tra quyền hạn chi tiết của Moderator.
  * Các quyền khả dụng của Moderator (`MODERATOR_PERMISSIONS`) bao gồm:
    * `MODERATE_POSTS`: Phê duyệt hoặc từ chối tin đăng bán/đấu giá.
    * `HANDLE_SUPPORT_TICKETS`: Trả lời và xử lý các yêu cầu trợ giúp.
    * `MARK_SPAM`: Đánh dấu các tin đăng rác, lừa đảo.

### B. Phân quyền ở Frontend (Web & Mobile)
* **Web Nuxt:** Sử dụng Route Middleware `auth.js` để chặn truy cập trái phép vào thư mục `/admin`. Menu Sidebar trong `admin.vue` layout tự động lọc ẩn/hiển thị các liên kết dựa trên quyền hạn thực tế của tài khoản đang đăng nhập.
* **Mobile Flutter:** Cơ chế bảo mật đặc biệt không tự động kích hoạt chế độ admin khi khởi động. Chỉ khi tài khoản có quyền Admin/Moderator và bật công tắc **Admin Mode** (lưu ở `adminModeProvider`), router (`appRouterProvider`) mới chuyển hướng người dùng vào vùng quản trị `/admin` và khóa họ trong layout `AdminShell`.

---

## 2. API Quản Trị Tại Backend (`be/src/admin/admin.controller.ts`)

Lớp `AdminController` đóng vai trò là API Gateway cho toàn bộ hoạt động quản trị, bao gồm các nhóm chức năng chính sau:

### A. Thống Kê & Báo Cáo (Analytics)
* `GET /admin/dashboard/overview`: Lấy các chỉ số thời gian thực phục vụ Dashboard tổng quan (số tin đăng chờ duyệt, KYC chờ xử lý, số giao dịch và doanh thu phí hệ thống).
* `GET /admin/analytics`: Lấy dữ liệu biểu đồ phân tích theo chu kỳ: 7 ngày, 30 ngày, 3 tháng, 6 tháng, 1 năm.
* `GET /admin/analytics/export`: Xuất dữ liệu thống kê ra định dạng file CSV gửi trực tiếp về trình duyệt.

### B. Kiểm Duyệt Tin Đăng (Listings Moderation)
* Hỗ trợ API duyệt riêng cho từng loại sản phẩm: `vehicles`, `batteries`, `accessories`, hoặc API gộp tiện lợi `listings` phục vụ màn hình kiểm duyệt chung.
* Các hành động kiểm duyệt bao gồm:
  * `approve`: Phê duyệt hiển thị công khai bài đăng.
  * `reject`: Từ chối tin đăng (yêu cầu truyền lý do từ chối để hệ thống gửi thông báo cho người đăng).
  * `spam`: Đánh dấu tin đăng rác (có tích hợp kiểm duyệt tự động dựa trên từ khóa cấm và giá ảo ở backend).
  * `verify` / `unverify`: Gắn hoặc gỡ tích xanh xác minh chất lượng sản phẩm (đặc biệt hữu ích cho pin đã qua kiểm định kỹ thuật).

### C. Quản Lý Giao Dịch & Tranh Chấp (Transactions & Disputes)
* `GET /admin/transactions`: Giám sát tất cả giao dịch mua bán và đấu giá trên sàn.
* `POST /admin/transactions/:id/resolve-dispute`: Giải quyết tranh chấp hợp đồng/tiền cọc giữa người mua và người bán. Admin có quyền ra quyết định phân xử: hoàn tiền cọc cho Buyer (`buyer-refunded`) hoặc thanh toán tiền cọc cho Seller (`seller-paid`) kèm ghi chú giải quyết.

### D. Quản Lý Người Dùng & Phê Duyệt eKYC
* `GET /admin/users`: Danh sách người dùng kèm theo chi tiết thống kê số lượng tin đăng, số giao dịch, đánh giá trung bình và trạng thái KYC.
* `PUT /admin/users/:id/block` & `unblock`: Khóa hoặc mở khóa tài khoản người dùng vi phạm chính sách.
* `PUT /admin/users/:id/role`: Nâng cấp/hạ cấp vai trò của tài khoản (từ USER lên MODERATOR/ADMIN hoặc ngược lại).
* `PUT /admin/moderators/:id/permissions`: Admin thiết lập và phân quyền chi tiết cho từng tài khoản Moderator.

### E. Quấu Hình Hệ Thống (Settings & Fees)
* `PUT /admin/settings`: Cập nhật cấu hình vận hành hệ thống (tỷ lệ hoa hồng sàn, thời gian đấu giá tối đa, bước giá đặt cược tối thiểu).
* `PUT /admin/support-tickets/:id`: Xử lý, phản hồi và đóng các ticket khiếu nại của người dùng.

---

## 3. Giao Diện Quản Trị Web Nuxt (`FE/pages/admin/`)

Được thiết kế hiện đại với giao diện Dashboard chia làm nhiều khu vực quản lý chuyên biệt:

* **Sidebar Layout (`FE/layouts/admin.vue`):** Menu sidebar động tự kiểm tra quyền và hiển thị các tab điều hướng:
  * *Thống kê & Báo cáo* (`/admin/analytics`)
  * *Quản lý người dùng* (`/admin/user`)
  * *Quyền Moderator* (`/admin/moderator-permissions`)
  * *Quản lý tin đăng* (`/admin/post`)
  * *Quản lý đấu giá* (`/admin/auctions`)
  * *Quản lý giao dịch* (`/admin/transactions`)
  * *Support tickets* (`/admin/support-tickets`)
  * *Phí & Hoa hồng* (`/admin/fees`)
* **Quản lý người dùng (`user/index.vue`):**
  * Giao diện hiển thị 4 thẻ thống kê nhanh: Tổng số user, số user đang hoạt động, số user chờ duyệt eKYC, số user bị khóa.
  * Bảng hiển thị thông tin trực quan hỗ trợ tìm kiếm theo tên, email, số điện thoại. Cho phép thao tác nhanh (Phê duyệt KYC, Khóa tài khoản, Mở khóa, Xem chi tiết, Xóa vĩnh viễn).
  * Hỗ trợ phân trang (`UPagination`) để tối ưu tốc độ tải.

---

## 4. Bảng Điều Khiển Admin Trên Mobile (`mobile/lib/features/admin/`)

Ứng dụng di động Flutter cũng được trang bị một hệ thống màn hình quản trị toàn diện, giúp Admin/Moderator vận hành hệ thống thuận tiện ngay trên điện thoại:

### A. Cấu trúc Giao diện Di động (`AdminShell`)
* Khi ở chế độ admin, ứng dụng hiển thị một thanh điều hướng bottom navigation bar riêng biệt (`_AdminBottomNavBar`) gồm 5 tab chính:
  1. **Tổng quan (`AdminAnalyticsScreen`):** Hiển thị các biểu đồ, con số trực quan về hoạt động của sàn giao dịch.
  2. **Duyệt Bài / Đấu Giá (`AdminListingsScreen`):** Nơi kiểm duyệt nhanh các yêu cầu đăng sản phẩm và phê duyệt các phiên đấu giá đang ở trạng thái chờ (`PENDING`).
  3. **Giao Dịch (`AdminTransactionsScreen`):** Theo dõi lịch trình thanh toán cọc, tiến độ ký hợp đồng điện tử của Buyer và Seller.
  4. **Hỗ Trợ Chat (`AdminSupportTicketsScreen`):** Giao diện để quản trị viên nhắn tin hỗ trợ trực tiếp thời gian thực giải quyết khiếu nại của khách hàng.
  5. **Thêm / Mở rộng (`AdminMoreScreen`):** Menu chứa các chức năng nâng cao như: Cấu hình phí sàn, Phân quyền Moderator, Cài đặt bước giá đấu giá, Phê duyệt eKYC người dùng và nút Đăng xuất an toàn.

### B. Chức năng Phê duyệt eKYC (`kyc_management_screen.dart` & `kyc_review_detail_screen.dart`)
Đây là tính năng cốt lõi trên di động giúp xác thực danh tính người dùng:
* **Màn hình danh sách (`KycManagementScreen`):** Hiển thị danh sách các tài khoản đang gửi yêu cầu xác minh thông tin cá nhân.
* **Màn hình chi tiết duyệt (`KycReviewDetailScreen`):**
  * Hiển thị đầy đủ thông tin khai báo (Họ tên, Số CCCD/CMND, Ngày sinh, Địa chỉ).
  * Cho phép bấm phóng to xem chi tiết ảnh chụp mặt trước và mặt sau của thẻ CCCD/CMND.
  * Cung cấp 2 nút hành động lớn ở cuối trang: **Từ chối (Reject)** (yêu cầu nhập lý do từ chối để thông báo lại cho khách hàng gửi lại ảnh rõ hơn) hoặc **Phê duyệt (Approve)** (kích hoạt nâng cấp tài khoản lên trạng thái KYC xác minh thành công).
