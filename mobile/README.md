# EVN Battery Trading - Flutter Mobile App

## Cài đặt Flutter SDK

Vì bạn chưa có Flutter SDK (chỉ có Dart SDK tại `D:\mobi\dart-sdk`), cần cài Flutter:

### Cách 1: Tải trực tiếp (Khuyến nghị)

1. Vào https://flutter.dev/docs/get-started/install/windows
2. Tải `flutter_windows_stable.zip` (khoảng 700MB)
3. Giải nén vào `D:\mobi\flutter`
4. Thêm `D:\mobi\flutter\bin` vào PATH:
   - Windows → System Properties → Environment Variables → Path → New → `D:\mobi\flutter\bin`
5. Mở terminal mới và chạy: `flutter doctor`

### Cách 2: Dùng Chocolatey
```powershell
# Chạy PowerShell as Administrator
choco install flutter
```

### Cách 3: Dùng winget
```powershell
winget install --id Google.Flutter
```

---

## Chạy App

### 1. Cài dependencies
```bash
cd d:\EVN\second-hand-evn-battery-trading-platform\mobile
flutter pub get
```

### 2. Chạy trên Android Emulator
```bash
# Mở Android Studio → AVD Manager → Tạo/Chạy emulator
flutter run
```

### 3. Chạy trên thiết bị thật (Android)
```bash
# Bật Developer Mode + USB Debugging trên điện thoại
flutter devices   # Kiểm tra thiết bị
flutter run
```

---

## Cấu hình API

Sửa file `mobile/.env`:
```
# Android Emulator
API_BASE_URL=http://10.0.2.2:3000/api

# Thiết bị thật (thay bằng IP máy tính của bạn)
API_BASE_URL=http://192.168.1.xxx:3000/api

# Production
API_BASE_URL=https://api.evn-battery.vn/api
```

---

## Cấu trúc Project

```
mobile/lib/
├── main.dart                    # Entry point
├── core/
│   ├── constants/               # Hằng số
│   ├── theme/                   # Theme & màu sắc EVN
│   ├── network/                 # Dio HTTP client + JWT interceptor
│   ├── router/                  # GoRouter navigation
│   └── utils/                   # Format tiền, ngày
├── models/                      # Data models
│   ├── user_model.dart
│   ├── battery_model.dart
│   ├── vehicle_model.dart
│   ├── auction_model.dart
│   └── chat_model.dart
├── services/                    # API services
│   ├── auth_service.dart
│   ├── battery_service.dart
│   └── vehicle_service.dart
├── features/
│   ├── auth/                    # Login, Register, Forgot Password
│   ├── home/                    # Home screen
│   ├── batteries/               # List + Detail
│   ├── vehicles/                # List + Detail
│   ├── auctions/                # List + Detail (real-time)
│   ├── chat/                    # Chat list + Room
│   ├── profile/                 # Profile + Settings
│   └── notifications/           # Notifications
└── widgets/                     # Shared widgets
    ├── main_shell.dart          # Bottom navigation
    ├── app_text_field.dart
    ├── loading_button.dart
    └── app_network_image.dart
```

---

## Màn Hình Đã Build

| Màn hình | Status |
|----------|--------|
| Splash Screen | ✅ |
| Login | ✅ |
| Register | ✅ |
| Forgot Password (3 bước) | ✅ |
| Home | ✅ |
| Battery List + Filter | ✅ |
| Battery Detail | ✅ |
| Vehicle List | ✅ |
| Vehicle Detail | ✅ |
| Auction List (tabs + timer) | ✅ |
| Chat List | ✅ |
| Chat Room | ✅ |
| Profile | ✅ |
| Notifications | ✅ |

---

## Yêu cầu hệ thống

- Flutter SDK ≥ 3.16.0
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code
- Android SDK (API 21+)
- Backend NestJS đang chạy ở port 3000
