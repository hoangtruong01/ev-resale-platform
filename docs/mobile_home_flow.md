# Luồng Hoạt Động & Giải Thích Code Trang Chủ Mobile (Flutter)

Tài liệu này giải thích chi tiết cấu trúc code, cơ chế quản lý trạng thái, luồng lấy dữ liệu và các tương tác giao diện tại trang chủ của ứng dụng di động **EV Battery Resale Platform** (`mobile/`).

---

## 1. Bản Đồ Thư Mục & Các File Liên Quan

Chức năng trang chủ được cấu trúc dạng **feature-based** nằm trong thư mục `mobile/lib/features/home/`:

```
mobile/lib/features/home/
├── screens/
│   ├── home_screen.dart           # Giao diện chính trang chủ (chứa bộ lọc, danh mục, danh sách sản phẩm)
│   └── global_search_screen.dart  # Trang tìm kiếm toàn cầu cho Xe, Pin và Phụ kiện
└── widgets/
    └── home_widgets.dart          # Các widget UI dùng chung (ProductGridCard, HomeCategoryItem, FilterTab, Skeleton)
```

Ngoài ra, trang chủ còn kết nối trực tiếp với các dịch vụ và định tuyến sau:
* **Định tuyến:** `mobile/lib/core/router/app_router.dart` (định nghĩa path `/` cho `HomeScreen` và `/search` cho `GlobalSearchScreen`).
* **Dịch vụ API:** `mobile/lib/services/` (`battery_service.dart`, `vehicle_service.dart`, `accessory_service.dart`).
* **Quản lý yêu thích:** `mobile/lib/features/profile/screens/profile_screen.dart` (cung cấp `dashboardFavoritesProvider` để đồng bộ nút thả tim).

---

## 2. Quản Lý Trạng Thái & Lấy Dữ Liệu (State Management)

Trang chủ sử dụng thư viện **Riverpod** làm giải pháp quản lý trạng thái chính.

### A. Quản lý Bộ lọc nâng cao (`HomeFilterState` & `homeFilterProvider`)
Trong file `home_screen.dart`, lớp `HomeFilterState` đóng vai trò lưu trữ toàn bộ tham số bộ lọc của trang chủ:
```dart
class HomeFilterState {
  final String category; // 'all' | 'battery' | 'vehicle' | 'accessory'
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? batteryType;
  final int? minCondition; // SOH tối thiểu của pin
  final String? brand;
  final int? minYear;
  final int? maxYear;
  final String? sortBy;
  final String? sortOrder;
  ...
}
```
* Trạng thái này được theo dõi thông qua `homeFilterProvider` (dạng `StateProvider`).
* Khi người dùng thay đổi bất kỳ bộ lọc nào trong Bottom Sheet (ví dụ: đổi khoảng giá, chọn loại pin, nhập đời xe), `homeFilterProvider` sẽ cập nhật trạng thái mới.

### B. Lấy dữ liệu sản phẩm tự động (`homeScreenDataProvider`)
Dữ liệu hiển thị trên trang chủ được tải thông qua `homeScreenDataProvider` (dạng `FutureProvider.autoDispose`):
* Nhà phát triển sử dụng cơ chế lắng nghe trạng thái bộ lọc `ref.watch(homeFilterProvider)`. Khi bộ lọc thay đổi, provider này sẽ tự động gọi lại các API tương ứng.
* Tối ưu hóa hiệu năng bằng cách chỉ gọi API của danh mục được chọn (nếu lọc theo danh mục cụ thể) hoặc gọi đồng thời cả 3 API qua `Future.wait` nếu chọn chế độ `"Tất cả"` (`category == 'all'`):
```dart
final results = await Future.wait([
  batteriesFuture, // Gọi getBatteries từ batteryServiceProvider
  vehiclesFuture,  // Gọi getVehicles từ vehicleServiceProvider
  accessoriesFuture, // Gọi getAccessories từ accessoryServiceProvider
]);
```
* Trạng thái tải dữ liệu được xử lý gọn gàng qua cơ chế Pattern Matching của Riverpod (`homeDataAsync.when`):
  * `loading`: Hiển thị lưới sản phẩm giả lập (`_buildSkeletonGrid` bằng Shimmer).
  * `error`: Hiển thị giao diện báo lỗi kết nối máy chủ (`_buildErrorState`) kèm nút **Thử lại** và đường dẫn URL API hiện hành.
  * `data`: Merge dữ liệu từ 3 mảng trả về và hiển thị danh sách sản phẩm thực tế.

---

## 3. Luồng Hoạt Động Của Các Thành Phần Giao Diện (UI Component Flows)

Giao diện trang chủ (`HomeScreen`) được xây dựng trên một `CustomScrollView` để hỗ trợ cuộn mượt mà và tích hợp cơ chế kéo để làm mới (`RefreshIndicator`).

### A. Thanh Header Trang Chủ (`_buildHeader`)
* **Nút Bộ Lọc nâng cao:** Nhấn vào sẽ gọi `_showFilterSheet` để mở modal Bottom Sheet. Nếu có bộ lọc đang hoạt động (`filter.isActive`), trên nút sẽ hiển thị một chấm đỏ (badge dot) để thông báo cho người dùng.
* **Thanh Tìm Kiếm:** Khi người dùng tap vào, ứng dụng sẽ chuyển hướng (điều hướng bằng GoRouter) sang trang `/search` (`GlobalSearchScreen`).
* **Nút Yêu Thích:** Điều hướng người dùng đến màn hình quản lý các sản phẩm đã lưu (`DashboardFavoritesScreen`).
* **Nút Thông Báo:** Chuyển hướng sang trang danh sách thông báo `/notifications`.

### B. Các Danh Mục Lọc Nhanh (`_buildCategories`)
Gồm 3 nút đại diện: **Pin điện**, **Xe điện**, và **Phụ kiện**.
* Khi nhấn vào một danh mục, controller sẽ cập nhật `category` tương ứng trong `homeFilterProvider`, ngay lập tức kích hoạt lấy lại dữ liệu chỉ dành riêng cho danh mục đó để giảm tải cho băng thông.

### C. Banner Đăng Bán Nhanh (`_buildSellBanner` & `_showSellSheet`)
* Thiết kế dạng gradient xanh lá bắt mắt để khuyến khích người dùng đăng bán sản phẩm của họ.
* Khi nhấn nút **"Đăng bán"**, Bottom Sheet `_showSellSheet` xuất hiện, cung cấp 3 lựa chọn kèm mô tả ngắn:
  1. *Đăng bán Pin:* Route sang `/sell/battery`.
  2. *Đăng bán Xe điện:* Route sang `/sell/vehicle`.
  3. *Đăng bán Phụ kiện:* Route sang `/sell/accessory`.

### D. Các Tab Lọc Dữ Liệu Ở Giữa Trang (`FilterTab`)
Giao diện cung cấp 4 tab điều hướng cứng phía trên danh sách sản phẩm để người dùng sắp xếp nhanh:
1. **Dành cho bạn (For You):** Dữ liệu gộp từ Xe, Pin, Phụ kiện được sắp xếp theo giá từ thấp đến cao.
2. **Gần bạn (Near You):** Danh sách được sắp xếp ưu tiên hiển thị các sản phẩm có vị trí thuộc khu vực trung tâm lớn trước (tìm kiếm từ khóa `"Hà Nội"`, `"Hồ Chí Minh"`, `"HCM"` trong trường `location`), sau đó sắp xếp theo tin mới nhất.
3. **Mới nhất (Latest):** Sắp xếp danh sách gộp giảm dần theo ngày đăng (`createdAt`).
4. **Video:** Lọc và hiển thị các bài đăng có tiêu đề chứa từ khóa liên quan đến thương hiệu nổi tiếng hoặc phụ tùng ("VinFast", "Tesla", "pin") để người dùng tìm nhanh.

### E. Lưới Sản Phẩm & Card Sản Phẩm (`ProductGridCard`)
* Giao diện hiển thị dạng lưới 2 cột (`SliverGrid` với `childAspectRatio: 0.58`).
* Mỗi sản phẩm được bao bọc trong widget `ProductGridCard` có các tính năng:
  * Hiển thị ảnh đại diện thông qua `AppNetworkImage` (hỗ trợ hiển thị ảnh mặc định tương ứng với loại danh mục nếu lỗi link ảnh).
  * Hiển thị giá tiền dạng đỏ nổi bật đã được định dạng tiền tệ VND (`AppUtils.formatCurrency`).
  * Trạng thái thả tim (yêu thích): Đồng bộ thời gian thực với `dashboardFavoritesProvider`. Khi nhấn tim, hệ thống sẽ tự động gọi API thêm/xóa yêu thích ở backend. *Lưu ý: Tính năng yêu thích chỉ hỗ trợ cho Xe điện và Pin điện, nếu nhấn vào phụ kiện sẽ hiển thị thông báo SnackBar cảnh báo.*
  * Chuyển hướng chi tiết: Nhấn vào card sẽ đẩy router sang trang chi tiết tương ứng:
    * Xe điện: `/vehicles/:id`
    * Pin điện: `/batteries/:id`
    * Phụ kiện: `/accessories/:id`

---

## 4. Giao Diện Tìm Kiếm Toàn Cầu (`GlobalSearchScreen`)

Khi nhấn vào ô tìm kiếm ở trang chủ, người dùng được chuyển tới màn hình tìm kiếm tập trung:
* **Debounce tìm kiếm (Tối ưu hóa hiệu năng):** Để tránh việc ứng dụng gọi API liên tục mỗi khi người dùng gõ một ký tự, code sử dụng một `Timer` trì hoãn:
  ```dart
  void _onSearchChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(text);
    });
  }
  ```
  Chỉ khi người dùng ngừng gõ quá 500ms, API mới thực sự được gọi.
* **Tìm kiếm song song:** API tìm kiếm gửi từ khóa đồng thời tới 3 endpoint của backend (vehicles, batteries, accessories).
* **Hiển thị phân loại Tab:** Kết quả được phân chia rõ ràng làm 3 Tab kèm theo số lượng kết quả tìm thấy ngay trên nhãn tab: `Xe điện (X)`, `Pin điện (Y)`, `Phụ kiện (Z)` để người mua dễ dàng chuyển đổi và tìm kiếm đúng sản phẩm mong muốn.
