import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  String _selectedPeriod = '7d';

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(_analyticsProvider(_selectedPeriod));

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Thống kê hệ thống'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _selectedPeriod = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('7 ngày qua')),
              const PopupMenuItem(value: '30d', child: Text('30 ngày qua')),
              const PopupMenuItem(value: '3m', child: Text('3 tháng qua')),
              const PopupMenuItem(value: '6m', child: Text('6 tháng qua')),
              const PopupMenuItem(value: '1y', child: Text('1 năm qua')),
            ],
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_analyticsProvider(_selectedPeriod)),
        child: analyticsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (data) {
            final metrics = data['metrics'] as Map<String, dynamic>;
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Metrics
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _MetricCard(
                      label: 'Tổng doanh thu',
                      value: AppUtils.formatCurrency(metrics['totalRevenue'] ?? 0),
                      trend: metrics['revenueTrend'] ?? 0,
                      icon: Icons.payments_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                    _MetricCard(
                      label: 'Tổng giao dịch',
                      value: (metrics['totalTransactions'] ?? 0).toString(),
                      trend: metrics['transactionsTrend'] ?? 0,
                      icon: Icons.swap_horiz_rounded,
                      color: AppTheme.info,
                    ),
                    _MetricCard(
                      label: 'Người dùng mới',
                      value: (metrics['activeUsers'] ?? 0).toString(),
                      trend: metrics['usersTrend'] ?? 0,
                      icon: Icons.person_add_rounded,
                      color: AppTheme.warning,
                    ),
                    _MetricCard(
                      label: 'Tin đăng mới',
                      value: (metrics['totalPosts'] ?? 0).toString(),
                      trend: metrics['postsTrend'] ?? 0,
                      icon: Icons.post_add_rounded,
                      color: Colors.purple,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Transaction Status Distribution
                _SectionTitle(title: 'Phân bổ giao dịch'),
                _TransactionStatsCard(stats: data['transactionStats']),
                
                const SizedBox(height: 20),
                
                // Top Users
                _SectionTitle(title: 'Người dùng nổi bật'),
                ...((data['topUsers'] as List? ?? []).map((user) => _UserListItem(user: user))),
                
                const SizedBox(height: 20),
                
                // System Health
                _SectionTitle(title: 'Tình trạng hệ thống'),
                _SystemHealthCard(health: data['systemHealth']),
                
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _analyticsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, period) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/analytics', queryParameters: {'period': period});
  return Map<String, dynamic>.from(res.data);
});

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final num trend;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = trend >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 10,
                      color: isPositive ? AppTheme.success : AppTheme.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend.abs()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(color: AppTheme.grey500, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.grey900),
      ),
    );
  }
}

class _TransactionStatsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _TransactionStatsCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final successful = stats?['successful'] ?? 0;
    final pending = stats?['pending'] ?? 0;
    final cancelled = stats?['cancelled'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        children: [
          _StatBar(label: 'Thành công', value: successful.toDouble(), color: AppTheme.success),
          const SizedBox(height: 12),
          _StatBar(label: 'Đang xử lý', value: pending.toDouble(), color: AppTheme.warning),
          const SizedBox(height: 12),
          _StatBar(label: 'Đã hủy', value: cancelled.toDouble(), color: AppTheme.error),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _StatBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.grey700)),
            Text('${value.toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
            child: user['avatar'] == null ? const Icon(Icons.person, color: AppTheme.primaryGreen) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${user['transactions'] ?? 0} giao dịch', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
              ],
            ),
          ),
          Text(
            AppUtils.formatCurrency(user['revenue'] ?? 0),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  final Map<String, dynamic>? health;
  const _SystemHealthCard({this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HealthItem(label: 'Uptime', value: '${health?['uptime'] ?? 0}%', isGood: true),
          _HealthItem(label: 'Load', value: '${health?['avgLoad'] ?? 0}%', isGood: (health?['avgLoad'] ?? 0) < 80),
          _HealthItem(label: 'Errors', value: '${health?['errorsPerHour'] ?? 0}', isGood: (health?['errorsPerHour'] ?? 0) < 10),
        ],
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isGood;

  const _HealthItem({required this.label, required this.value, required this.isGood});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isGood ? AppTheme.success : AppTheme.error)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
      ],
    );
  }
}
