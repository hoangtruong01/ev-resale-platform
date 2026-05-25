import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  ConsumerState<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends ConsumerState<AdminTransactionsScreen> with SingleTickerProviderStateMixin {
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
      0 => 'processing',
      1 => 'completed',
      2 => 'disputed',
      _ => 'processing'
    };

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Quản lý giao dịch'),
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
                      hintText: 'Tìm theo mã GD, tên người dùng...',
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
                  Tab(text: 'Đang xử lý'),
                  Tab(text: 'Hoàn tất'),
                  Tab(text: 'Tranh chấp'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _TransactionsTabContent(
        status: status,
        search: _searchCtrl.text,
      ),
    );
  }
}

class _TransactionsTabContent extends ConsumerWidget {
  final String status;
  final String search;

  const _TransactionsTabContent({
    required this.status,
    required this.search,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryKey = 'status=$status&search=${Uri.encodeComponent(search)}';

    final transactionsAsync = ref.watch(_transactionsProvider(queryKey));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_transactionsProvider(queryKey)),
      child: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Lỗi tải giao dịch: $err'),
              TextButton(
                onPressed: () => ref.invalidate(_transactionsProvider(queryKey)),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
        data: (res) {
          // Inside the REST API, the response could be a List or Map with 'data'
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
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.grey300),
                      SizedBox(height: 16),
                      Text('Không tìm thấy giao dịch nào', style: TextStyle(color: AppTheme.grey500)),
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
              return _TransactionCard(
                tx: item,
                onActionDone: () {
                  ref.invalidate(_transactionsProvider(queryKey));
                },
              );
            },
          );
        },
      ),
    );
  }
}

final _transactionsProvider = FutureProvider.autoDispose.family<dynamic, String>((ref, queryKey) async {
  final uri = Uri.parse('http://placeholder.local/?$queryKey');
  final status = uri.queryParameters['status'] ?? 'processing';
  final search = uri.queryParameters['search'] ?? '';

  final params = {
    'status': status,
    'limit': 50,
    'page': 1,
    if (search.isNotEmpty) 'search': search,
  };

  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/transactions', queryParameters: params);
  return res.data;
});

class _TransactionCard extends ConsumerWidget {
  final Map<String, dynamic> tx;
  final VoidCallback onActionDone;

  const _TransactionCard({required this.tx, required this.onActionDone});

  Future<void> _resolveDispute(BuildContext context, WidgetRef ref) async {
    String resolution = 'BUYER'; // BUYER or SELLER
    final notesCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Giải quyết tranh chấp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn bên nhận phán quyết có lợi:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Radio<String>(
                    value: 'BUYER',
                    groupValue: resolution,
                    onChanged: (val) => setModalState(() => resolution = val!),
                  ),
                  const Text('Người mua (Buyer)'),
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'SELLER',
                    groupValue: resolution,
                    onChanged: (val) => setModalState(() => resolution = val!),
                  ),
                  const Text('Người bán (Seller)'),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Ghi chú/Lý do phán quyết:'),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  hintText: 'Nhập lý do phân xử...',
                  fillColor: AppTheme.grey100,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Xác nhận phán quyết'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final dio = ref.read(dioProvider);
    final id = tx['id'];
    try {
      await dio.post('/admin/transactions/$id/resolve-dispute', data: {
        'resolution': resolution,
        'notes': notesCtrl.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã phân xử tranh chấp giao dịch thành công'), backgroundColor: AppTheme.success),
        );
        onActionDone();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi giải quyết: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyerName = tx['buyer']?['fullName'] ?? tx['buyer']?['name'] ?? 'N/A';
    final sellerName = tx['seller']?['fullName'] ?? tx['seller']?['name'] ?? 'N/A';
    final amount = tx['amount'] ?? tx['price'] ?? 0;
    final status = tx['status'] as String? ?? 'PENDING';
    final isDisputed = status.toUpperCase() == 'DISPUTED';
    final code = tx['id'].toString().substring(0, 8).toUpperCase();

    final statusColor = switch (status.toUpperCase()) {
      'COMPLETED' => AppTheme.success,
      'PROCESSING' => AppTheme.info,
      'DISPUTED' => AppTheme.error,
      'CANCELLED' => AppTheme.grey500,
      _ => AppTheme.warning
    };

    final statusLabel = switch (status.toUpperCase()) {
      'COMPLETED' => 'Thành công',
      'PROCESSING' => 'Đang xử lý',
      'DISPUTED' => 'Tranh chấp',
      'CANCELLED' => 'Đã hủy',
      _ => 'Đang chờ'
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
              Text(
                'Mã GD: #$code',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.grey900, fontSize: 14),
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
          const SizedBox(height: 12),
          Text(
            'Sản phẩm: ${tx['battery']?['name'] ?? tx['vehicle']?['name'] ?? tx['accessory']?['name'] ?? 'Giao dịch EVN'}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mua: $buyerName', style: const TextStyle(color: AppTheme.grey600, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Bán: $sellerName', style: const TextStyle(color: AppTheme.grey600, fontSize: 12)),
                ],
              ),
              Text(
                AppUtils.formatCurrency(amount),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, fontSize: 16),
              ),
            ],
          ),
          if (tx['createdAt'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Ngày tạo: ${AppUtils.timeAgo(tx['createdAt'])}',
              style: const TextStyle(color: AppTheme.grey400, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
          if (isDisputed) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Có khiếu nại tranh chấp!',
                        style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  if (tx['disputeReason'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Lý do: ${tx['disputeReason']}',
                      style: const TextStyle(color: AppTheme.grey800, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _resolveDispute(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.gavel_rounded, size: 16, color: Colors.white),
                    label: const Text('Phân xử tranh chấp', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
