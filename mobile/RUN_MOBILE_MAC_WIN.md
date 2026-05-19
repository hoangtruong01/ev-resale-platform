# Huong dan chay Mobile tren macOS va Windows

Tai lieu nay huong dan chay app Flutter trong thu muc `mobile/` tren simulator/emulator.

## 1) Cau hinh chung (ap dung cho ca macOS va Windows)

### 1.1 Cai Flutter va kiem tra moi truong

- Cai Flutter SDK (ban dang dung Flutter 3.41+ thi giu nguyen).
- Kiem tra:

```bash
flutter doctor
```

Neu thieu thanh phan nao, `flutter doctor` se bao ro.

### 1.2 Tao file .env

Trong thu muc `mobile/`, tao `.env` tu file mau:

```bash
cd mobile
cp .env.example .env
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Cap nhat `API_BASE_URL` theo moi truong:

- Android Emulator: `http://10.0.2.2:3000/api`
- iOS Simulator (macOS): `http://localhost:3000/api`
- Thiet bi that: `http://<IP_MAY_TINH>:3000/api`

### 1.3 Cai dependencies

```bash
cd mobile
flutter pub get
```

### 1.4 Khoi dong backend (neu can login/lay du lieu)

Backend mac dinh chay o port 3000.

```bash
cd be
yarn
yarn start:dev
```

## 2) macOS

### 2.1 Chay iOS Simulator

1. Cai Xcode tu App Store
2. Mo Xcode mot lan de hoan tat cai dat
3. Cai iOS Simulator (Xcode > Settings > Platforms)
4. Mo Simulator:

```bash
open -a Simulator
```

5. Chay app:

```bash
cd mobile
flutter run -d ios
```

### 2.2 Chay Android Emulator (tuy chon)

1. Cai Android Studio
2. Mo Android Studio > Device Manager
3. Tao AVD va khoi dong emulator
4. Chay app:

```bash
cd mobile
flutter run -d <deviceId>
```

Lay `deviceId` bang:

```bash
flutter devices
```

## 3) Windows

> iOS Simulator khong ho tro tren Windows. Chi chay Android Emulator.

### 3.1 Cai Android Studio + AVD

1. Cai Android Studio
2. Mo Android Studio > Device Manager
3. Tao AVD va khoi dong emulator

### 3.2 Chay app

```bash
cd mobile
flutter run -d <deviceId>
```

Lay `deviceId` bang:

```bash
flutter devices
```

## 4) Loi thuong gap

- Neu `flutter devices` khong thay emulator:
  - Kiem tra emulator da mo chua
  - Chay `flutter doctor` de kiem tra Android SDK/Xcode
- Neu khong goi duoc API:
  - Kiem tra `API_BASE_URL` trong `.env`
  - Android Emulator phai dung `10.0.2.2` thay cho `localhost`
- Neu build iOS loi:
  - Mo `ios/Runner.xcworkspace` bang Xcode va build mot lan
