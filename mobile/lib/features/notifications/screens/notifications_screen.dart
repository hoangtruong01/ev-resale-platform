import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Đọc tất cả',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _sampleNotifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final notif = _sampleNotifications[i];
          return _NotifTile(notification: notif);
        },
      ),
    );
  }
}

class _Notification {
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  const _Notification({
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });
}

final _sampleNotifications = [
  _Notification(
    title: 'Tin đăng được duyệt',
    message: 'Pin Lithium-Ion 60kWh của bạn đã được duyệt',
    type: 'SYSTEM_ALERT',
    isRead: false,
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 5))
        .toIso8601String(),
  ),
  _Notification(
    title: 'Đấu giá kết thúc',
    message: 'Phiên đấu giá pin xe điện đã kết thúc',
    type: 'AUCTION_WON',
    isRead: false,
    createdAt: DateTime.now()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
  ),
  _Notification(
    title: 'Tin nhắn mới',
    message: 'Bạn có tin nhắn mới từ người mua',
    type: 'REVIEW_RECEIVED',
    isRead: true,
    createdAt: DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
  ),
];

class _NotifTile extends StatelessWidget {
  final _Notification notification;
  const _NotifTile({required this.notification});

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
