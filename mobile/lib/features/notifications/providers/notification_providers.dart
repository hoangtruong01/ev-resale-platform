import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

final myNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final isAuthenticated = ref.watch(authStateProvider).value?.isAuthenticated ?? false;
  if (!isAuthenticated) {
    return const [];
  }
  final service = ref.watch(notificationServiceProvider);
  return service.getMyNotifications();
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final isAuthenticated = ref.watch(authStateProvider).value?.isAuthenticated ?? false;
  if (!isAuthenticated) {
    return 0;
  }
  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount();
});
