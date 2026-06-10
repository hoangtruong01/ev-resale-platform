import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../models/app_notification_item.dart';
import '../services/app_notification_store.dart';

final appNotificationHistoryProvider =
    AsyncNotifierProvider<AppNotificationHistoryNotifier, List<AppNotificationItem>>(
  AppNotificationHistoryNotifier.new,
);

final appNotificationUnreadCountProvider = Provider<int>((ref) {
  final history = ref.watch(appNotificationHistoryProvider);
  return history.maybeWhen(
    data: (items) => items.where((e) => e.isImportant && !e.isRead).length,
    orElse: () => 0,
  );
});

class AppNotificationHistoryNotifier
    extends AsyncNotifier<List<AppNotificationItem>> {
  AppNotificationStore get _store => ref.read(appNotificationStoreProvider);

  @override
  Future<List<AppNotificationItem>> build() async {
    ref.listen(authStateProvider, (_, next) {
      final isAuthenticated = next.value?.isAuthenticated ?? false;
      if (!isAuthenticated) {
        state = const AsyncData([]);
      } else {
        ref.invalidateSelf();
      }
    });

    final isAuthenticated = ref.watch(authStateProvider).value?.isAuthenticated ?? false;
    if (!isAuthenticated) return const [];
    return _store.loadAll();
  }

  Future<void> push({
    required String title,
    required String message,
    required AppNotificationType type,
    AppNotificationOrigin origin = AppNotificationOrigin.system,
    bool isImportant = true,
    String? actionLabel,
    String? route,
  }) async {
    final item = AppNotificationItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      origin: origin,
      isRead: false,
      isImportant: isImportant,
      createdAt: DateTime.now(),
      actionLabel: actionLabel,
      route: route,
    );
    await _store.add(item);
    ref.invalidateSelf();
  }

  Future<void> markAsRead(String id) async {
    await _store.markAsRead(id);
    ref.invalidateSelf();
  }

  Future<void> markAllAsRead() async {
    await _store.markAllAsRead();
    ref.invalidateSelf();
  }

  Future<void> clearHistory() async {
    await _store.clear();
    ref.invalidateSelf();
  }
}
