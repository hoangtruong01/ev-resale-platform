import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when an unauthorized API response is detected.
final sessionExpiredTickProvider = StateProvider<int>((ref) => 0);

/// Trạng thái bật/tắt chế độ quản trị viên trên mobile.
final adminModeProvider = StateProvider<bool>((ref) => false);

