import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

class AdminSupportTicketsScreen extends ConsumerStatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  ConsumerState<AdminSupportTicketsScreen> createState() => _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState extends ConsumerState<AdminSupportTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (_tabController.index) {
      0 => 'OPEN',
      1 => 'IN_PROGRESS',
      2 => 'RESOLVED',
      _ => 'OPEN'
    };

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Yêu cầu hỗ trợ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.grey100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tiêu đề, email...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGreen,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.grey500,
                tabs: const [
                  Tab(text: 'Đang mở'),
                  Tab(text: 'Đang xử lý'),
                  Tab(text: 'Đã giải quyết'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _TicketsTabContent(
        status: status,
        search: _searchCtrl.text,
      ),
    );
  }
}

class _TicketsTabContent extends ConsumerWidget {
  final String status;
  final String search;

  const _TicketsTabContent({
    required this.status,
    required this.search,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryParams = {
      'status': status,
      'limit': 50,
      'page': 1,
      if (search.isNotEmpty) 'search': search,
    };

    final ticketsAsync = ref.watch(_ticketsProvider(queryParams));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_ticketsProvider(queryParams)),
      child: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Lỗi tải ticket: $err'),
              TextButton(
                onPressed: () => ref.invalidate(_ticketsProvider(queryParams)),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
        data: (res) {
          List<dynamic> itemsList = [];
          if (res is List) {
            itemsList = res;
          } else if (res is Map && res['data'] != null) {
            itemsList = res['data'];
          }
          final items = List<Map<String, dynamic>>.from(itemsList);

          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.support_agent_rounded, size: 64, color: AppTheme.grey300),
                      SizedBox(height: 16),
                      Text('Không tìm thấy yêu cầu hỗ trợ nào', style: TextStyle(color: AppTheme.grey500)),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final item = items[index];
              return _TicketCard(
                ticket: item,
                onActionDone: () {
                  ref.invalidate(_ticketsProvider(queryParams));
                },
              );
            },
          );
        },
      ),
    );
  }
}

final _ticketsProvider = FutureProvider.autoDispose.family<dynamic, Map<String, dynamic>>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/support-tickets', queryParameters: params);
  return res.data;
});

class _TicketCard extends ConsumerWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onActionDone;

  const _TicketCard({required this.ticket, required this.onActionDone});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String newStatus) async {
    final dio = ref.read(dioProvider);
    final id = ticket['id'];

    try {
      await dio.patch('/admin/support-tickets/$id', data: {'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chuyển trạng thái ticket sang $newStatus'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        onActionDone();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ticket['title'] ?? 'Hỗ trợ kỹ thuật';
    final desc = ticket['description'] ?? '';
    final userEmail = ticket['user']?['email'] ?? ticket['email'] ?? 'N/A';
    final userPhone = ticket['user']?['phone'] ?? 'N/A';
    final status = ticket['status'] as String? ?? 'OPEN';

    final statusColor = switch (status.toUpperCase()) {
      'RESOLVED' => AppTheme.success,
      'IN_PROGRESS' => AppTheme.warning,
      _ => AppTheme.error
    };

    final statusLabel = switch (status.toUpperCase()) {
      'RESOLVED' => 'Đã giải quyết',
      'IN_PROGRESS' => 'Đang xử lý',
      _ => 'Đang mở'
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.grey900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: AppTheme.grey700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.grey100, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gửi bởi: $userEmail', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('SĐT: $userPhone', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                ],
              ),
              if (ticket['createdAt'] != null)
                Text(
                  AppUtils.timeAgo(ticket['createdAt']),
                  style: const TextStyle(color: AppTheme.grey400, fontSize: 11, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status.toUpperCase() == 'OPEN')
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(context, ref, 'IN_PROGRESS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                  label: const Text('Nhận xử lý', style: TextStyle(fontSize: 13, color: Colors.white)),
                ),
              if (status.toUpperCase() == 'IN_PROGRESS') ...[
                OutlinedButton(
                  onPressed: () => _updateStatus(context, ref, 'OPEN'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.grey600,
                    side: const BorderSide(color: AppTheme.grey300),
                    minimumSize: const Size(90, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Trả lại', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(context, ref, 'RESOLVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    minimumSize: const Size(110, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text('Giải quyết', style: TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
