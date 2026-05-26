import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overviewAsync = ref.watch(_dashboardOverviewProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
        elevation: 0,
        title: const Text(
          'Tổng quan hệ thống',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_dashboardOverviewProvider),
        child: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải dữ liệu hệ thống: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(_dashboardOverviewProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final supportTickets = data['supportTickets'] as Map<String, dynamic>;
            final users = data['users'] as Map<String, dynamic>;
            final txStats = data['transactionOverview'] as Map<String, dynamic>;
            final feeRevenue = data['feeRevenue'] ?? 0;

            final totalSupportPending = (supportTickets['pending'] ?? 0) + (supportTickets['processing'] ?? 0);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Title: việc cần làm
                _SectionTitle(
                  title: 'Việc cần xử lý',
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Kiểm duyệt',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Compact action list for Moderation actions (Apple design style)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      _ActionRow(
                        label: 'Bài viết chờ duyệt',
                        value: (data['pendingPosts'] ?? 0).toString(),
                        icon: Icons.assignment_turned_in_rounded,
                        color: AppTheme.warning,
                        isDark: isDark,
                        onTap: () => context.go('/admin/listings'),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : AppTheme.grey100),
                      _ActionRow(
                        label: 'Đấu giá chờ duyệt',
                        value: (data['pendingAuctions'] ?? 0).toString(),
                        icon: Icons.gavel_rounded,
                        color: Colors.purple,
                        isDark: isDark,
                        onTap: () => context.go('/admin/listings'),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : AppTheme.grey100),
                      _ActionRow(
                        label: 'Yêu cầu KYC chờ',
                        value: (users['pendingKyc'] ?? 0).toString(),
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppTheme.info,
                        isDark: isDark,
                        onTap: () => context.go('/admin/kyc'),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white10 : AppTheme.grey100),
                      _ActionRow(
                        label: 'Hỗ trợ chưa xử lý',
                        value: totalSupportPending.toString(),
                        subtitle: '${supportTickets['pending'] ?? 0} mới, ${supportTickets['processing'] ?? 0} xử lý',
                        icon: Icons.support_agent_rounded,
                        color: AppTheme.error,
                        isDark: isDark,
                        onTap: () => context.go('/admin/support'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Title: Số liệu vận hành
                _SectionTitle(title: 'Số liệu vận hành', isDark: isDark),
                const SizedBox(height: 10),

                // Emerald large card for Fee Revenue
                _LargeRevenueCard(
                  label: 'Doanh thu phí hệ thống',
                  value: AppUtils.formatCurrency(feeRevenue),
                  icon: Icons.monetization_on_rounded,
                  color: AppTheme.primaryGreen,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // 2 columns for Total users & processing transactions
                Row(
                  children: [
                    Expanded(
                      child: _OperationalCard(
                        label: 'Tổng người dùng',
                        value: (users['total'] ?? 0).toString(),
                        icon: Icons.people_alt_rounded,
                        color: Colors.indigo,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OperationalCard(
                        label: 'Giao dịch đang chạy',
                        value: (data['processingTransactions'] ?? 0).toString(),
                        icon: Icons.swap_horizontal_circle_rounded,
                        color: Colors.deepOrange,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Transaction Status Distribution
                _SectionTitle(title: 'Phân bổ giao dịch', isDark: isDark),
                const SizedBox(height: 10),
                _TransactionStatsCard(stats: txStats, isDark: isDark),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _dashboardOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/dashboard/overview');
  return Map<String, dynamic>.from(res.data);
});

class _ActionRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionRow({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.grey800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.grey500),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: value == '0' 
                          ? (isDark ? Colors.white10 : AppTheme.grey100) 
                          : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: value == '0' 
                            ? (isDark ? Colors.white38 : AppTheme.grey400) 
                            : color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.grey400, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeRevenueCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _LargeRevenueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppTheme.grey500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _OperationalCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : AppTheme.grey900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : AppTheme.grey500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.grey800,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TransactionStatsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isDark;

  const _TransactionStatsCard({this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = (stats?['total'] ?? 0) as int;
    final successful = (stats?['successful'] ?? 0) as int;
    final processing = (stats?['processing'] ?? 0) as int;
    final cancelled = (stats?['cancelled'] ?? 0) as int;

    final successfulPct = total > 0 ? (successful / total * 100).round() : 0;
    final processingPct = total > 0 ? (processing / total * 100).round() : 0;
    final cancelledPct = total > 0 ? (cancelled / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng giao dịch đã phát sinh:',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppTheme.grey500),
              ),
              Text(
                '$total',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.grey900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: 'Thành công ($successful)',
            percent: successfulPct,
            color: AppTheme.success,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: 'Đang xử lý ($processing)',
            percent: processingPct,
            color: AppTheme.warning,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: 'Đã huỷ ($cancelled)',
            percent: cancelledPct,
            color: AppTheme.error,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  final bool isDark;

  const _StatBar({
    required this.label,
    required this.percent,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppTheme.grey700)),
            Text('$percent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.grey900)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
