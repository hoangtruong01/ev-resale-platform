import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppUtils {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final _numberFormatter = NumberFormat('#,###', 'vi_VN');

  /// Format số tiền VNĐ
  static String formatCurrency(dynamic amount) {
    if (amount == null) return '0 ₫';
    final value = double.tryParse(amount.toString()) ?? 0;
    return _currencyFormatter.format(value);
  }

  /// Format số có dấu phân cách
  static String formatNumber(dynamic number) {
    if (number == null) return '0';
    final value = double.tryParse(number.toString()) ?? 0;
    return _numberFormatter.format(value);
  }

  /// Format ngày tháng
  static String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy', 'vi').format(date.toLocal());
  }

  /// Format ngày giờ
  static String formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return DateFormat('HH:mm dd/MM/yyyy', 'vi').format(date.toLocal());
  }

  /// Thời gian tương đối (vd: "3 phút trước")
  static String timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return formatDate(dateStr);
  }

  /// Countdown timer cho auction
  static String formatCountdown(DateTime endTime) {
    final now = DateTime.now();
    final diff = endTime.difference(now);
    if (diff.isNegative) return 'Đã kết thúc';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  /// Tình trạng pin thành text + màu
  static String batteryConditionLabel(int condition) {
    if (condition >= 90) return 'Xuất sắc';
    if (condition >= 75) return 'Tốt';
    if (condition >= 60) return 'Khá';
    if (condition >= 40) return 'Trung bình';
    return 'Kém';
  }

  /// Rút gọn text
  static String truncate(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Validate phone VN
  static bool isValidPhone(String phone) {
    return RegExp(r'^(0|\+84)[3-9]\d{8}$').hasMatch(phone);
  }

  /// Resolve image URL (prepend base URL if relative)
  static String? resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    // Remove /api from base URL to get the server origin
    final origin = AppConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return '$origin$normalizedPath';
  }
}
