import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import 'dart:async';

final myNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }
  final service = ref.watch(notificationServiceProvider);
  return service.getMyNotifications(user.id);
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return 0;
  }
  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount(user.id);
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(myNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead(user.id);
    await _refreshAll();
  }

  Future<void> _markOneAsRead(String id) async {
    final service = ref.read(notificationServiceProvider);
    await service.markAsRead(id);
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Thông báo'),
            const SizedBox(width: 8),
            unreadCountAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Đọc tất cả',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshAll,
              child: ListView(
                children: const [
                  SizedBox(height: 140),
                  Center(
                    child: Text(
                      'Bạn chưa có thông báo nào',
                      style: TextStyle(color: AppTheme.grey600),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final notif = notifications[i];
                return _NotifTile(
                  notification: notif,
                  onTap: () {
                    if (!notif.isRead) {
                      _markOneAsRead(notif.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotifTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    final icon = _typeIcon(notification.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppTheme.primaryGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notification.message,
              style: const TextStyle(color: AppTheme.grey600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              AppUtils.timeAgo(notification.createdAt),
              style: const TextStyle(color: AppTheme.grey400, fontSize: 11),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'AUCTION_WON':
        return AppTheme.success;
      case 'AUCTION_LOST':
        return AppTheme.error;
      case 'PAYMENT_RECEIVED':
        return AppTheme.primaryGreen;
      case 'BID_PLACED':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.info;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'AUCTION_WON':
        return Icons.emoji_events_rounded;
      case 'AUCTION_LOST':
        return Icons.gavel_rounded;
      case 'PAYMENT_RECEIVED':
        return Icons.payments_outlined;
      case 'BID_PLACED':
        return Icons.price_change_outlined;
      case 'REVIEW_RECEIVED':
        return Icons.star_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }
}
