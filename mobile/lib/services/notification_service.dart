import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(dioProvider));
});

class NotificationService {
  final Dio _dio;
  NotificationService(this._dio);

  Future<List<NotificationModel>> getMyNotifications(String userId) async {
    final response = await _dio.get('/notifications/user/$userId', queryParameters: {
      'page': 1,
      'limit': 30,
    });

    final payload = response.data;
    final list = (payload is Map ? payload['data'] : null);
    if (list is! List) {
      return const [];
    }

    return list
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _dio.get('/notifications/user/$userId/unread-count');
    final payload = response.data;
    if (payload is Map && payload['count'] is num) {
      return (payload['count'] as num).toInt();
    }
    return 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead(String userId) async {
    await _dio.patch('/notifications/user/$userId/mark-all-read');
  }
}
