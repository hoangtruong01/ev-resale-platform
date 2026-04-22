import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String _defaultGoogleWebClientId =
      '164378065650-atjepgg14csvf084nb8eh1lhn7h8cjn2.apps.googleusercontent.com';
  static const String _googleWebClientIdFromDefine =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  // API
  static String get baseUrl {
    final envBaseUrl = dotenv.env['API_BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  static String get googleWebClientId {
    if (_googleWebClientIdFromDefine.isNotEmpty) {
      return _googleWebClientIdFromDefine;
    }

    final envValue = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    return _defaultGoogleWebClientId;
  }

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int pageSize = 10;

  // Cache
  static const Duration cacheTimeout = Duration(hours: 1);

  // Battery Types (Vietnamese labels)
  static const Map<String, String> batteryTypeLabels = {
    'LITHIUM_ION': 'Lithium-Ion (Li-ion)',
    'LITHIUM_POLYMER': 'Lithium Polymer (LiPo)',
    'NICKEL_METAL_HYDRIDE': 'Nickel Metal Hydride (NiMH)',
    'LEAD_ACID': 'Chì-Axit',
  };

  // Battery Status
  static const Map<String, String> batteryStatusLabels = {
    'AVAILABLE': 'Còn hàng',
    'SOLD': 'Đã bán',
    'AUCTION': 'Đấu giá',
    'RESERVED': 'Đã đặt cọc',
  };

  // Auction Status
  static const Map<String, String> auctionStatusLabels = {
    'PENDING': 'Sắp diễn ra',
    'ACTIVE': 'Đang đấu giá',
    'ENDED': 'Đã kết thúc',
    'CANCELLED': 'Đã huỷ',
  };

  // Transaction Status
  static const Map<String, String> transactionStatusLabels = {
    'PENDING': 'Chờ xử lý',
    'COMPLETED': 'Hoàn thành',
    'CANCELLED': 'Đã huỷ',
    'REFUNDED': 'Hoàn tiền',
  };

  // Sorting Options
  static const List<Map<String, String>> sortOptions = [
    {'label': 'Mới nhất', 'value': 'newest'},
    {'label': 'Giá thấp nhất', 'value': 'price_asc'},
    {'label': 'Giá cao nhất', 'value': 'price_desc'},
    {'label': 'Dung lượng cao nhất', 'value': 'capacity_desc'},
    {'label': 'Tình trạng tốt nhất', 'value': 'condition_desc'},
  ];
}
