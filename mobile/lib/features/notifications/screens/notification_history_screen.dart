import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/app_notification_item.dart';
import '../providers/app_notification_providers.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(appNotificationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thông báo'),
        actions: [
          TextButton(
            onPressed: () => ref.read(appNotificationHistoryProvider.notifier).markAllAsRead(),
            child: const Text('Đọc tất cả'),
          ),
          IconButton(
            onPressed: () => _showClearDialog(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: asyncHistory.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyHistory();
          }

          final important = items.where((e) => e.isImportant).toList();
          final other = items.where((e) => !e.isImportant).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(appNotificationHistoryProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  total: items.length,
                  unread: items.where((e) => !e.isRead).length,
                  important: important.length,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Quan trọng'),
                const SizedBox(height: 8),
                if (important.isEmpty)
                  const _SectionEmpty(text: 'Chưa có thông báo quan trọng')
                else
                  ...important.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(
                          item: item,
                          onTap: () {
                            if (!item.isRead) {
                              ref.read(appNotificationHistoryProvider.notifier).markAsRead(item.id);
                            }
                            if (item.route != null && item.route!.isNotEmpty) {
                              context.push(item.route!);
                            }
                          },
                        ),
                      )),
                const SizedBox(height: 8),
                _SectionHeader(title: 'Khác'),
                const SizedBox(height: 8),
                if (other.isEmpty)
                  const _SectionEmpty(text: 'Không có mục nào khác')
                else
                  ...other.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(
                          item: item,
                          onTap: () => ref.read(appNotificationHistoryProvider.notifier).markAsRead(item.id),
                        ),
                      )),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá lịch sử thông báo'),
        content: const Text('Bạn có muốn xoá toàn bộ lịch sử thông báo đã lưu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(appNotificationHistoryProvider.notifier).clearHistory();
            },
            child: const Text('Xoá', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int unread;
  final int important;

  const _SummaryCard({required this.total, required this.unread, required this.important});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _Metric(label: 'Tổng', value: '$total'),
          const _MetricDivider(),
          _Metric(label: 'Chưa đọc', value: '$unread'),
          const _MetricDivider(),
          _Metric(label: 'Quan trọng', value: '$important'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.white24);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  }
}

class _SectionEmpty extends StatelessWidget {
  final String text;
  const _SectionEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Text(text, style: const TextStyle(color: AppTheme.grey600)),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_off_outlined, size: 72, color: AppTheme.grey300),
            SizedBox(height: 12),
            Text('Chưa có lịch sử thông báo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text(
              'Các thông báo quan trọng sẽ được lưu tại đây để bạn xem lại bất cứ lúc nào.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _color(item.type);
    final icon = _icon(item.type);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: item.isRead ? AppTheme.grey200 : color.withValues(alpha: 0.28)),
            color: item.isRead ? Theme.of(context).cardColor : color.withValues(alpha: 0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.message, style: const TextStyle(fontSize: 13, color: AppTheme.grey600, height: 1.3)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(AppUtils.timeAgo(item.createdAt.toIso8601String()), style: const TextStyle(fontSize: 11, color: AppTheme.grey400)),
                        const SizedBox(width: 10),
                        if (item.actionLabel != null)
                          Text(item.actionLabel!, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _color(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.success => AppTheme.success,
      AppNotificationType.error => AppTheme.error,
      AppNotificationType.warning => AppTheme.warning,
      AppNotificationType.info => AppTheme.info,
    };
  }

  IconData _icon(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.success => Icons.check_circle_rounded,
      AppNotificationType.error => Icons.error_rounded,
      AppNotificationType.warning => Icons.warning_amber_rounded,
      AppNotificationType.info => Icons.info_rounded,
    };
  }
}
