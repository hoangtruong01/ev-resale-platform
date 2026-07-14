import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

final _contractsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/contracts/admin/list');
  final data = res.data;
  if (data is List) {
    return List<Map<String, dynamic>>.from(data);
  }
  return const [];
});

class AdminContractsScreen extends ConsumerWidget {
  const AdminContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contractsAsync = ref.watch(_contractsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Quản lý Hợp đồng'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_contractsProvider),
        child: contractsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(
                  'Lỗi tải hợp đồng: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.grey700,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_contractsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (contracts) {
            if (contracts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : AppTheme.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có hợp đồng nào',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.grey400
                                : AppTheme.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final contract = contracts[index];
                return _ContractCard(contract: contract);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final Map<String, dynamic> contract;

  const _ContractCard({required this.contract});

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(iso).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = contract['status'] as String? ?? 'PENDING';
    final contractId =
        contract['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A';

    final buyerName = contract['buyer']?['fullName'] ??
        contract['buyer']?['name'] ??
        contract['buyerName'] ??
        'N/A';
    final sellerName = contract['seller']?['fullName'] ??
        contract['seller']?['name'] ??
        contract['sellerName'] ??
        'N/A';
    final productName = contract['battery']?['name'] ??
        contract['vehicle']?['name'] ??
        contract['productName'] ??
        'Sản phẩm EVN';
    final amount = contract['amount'] ?? contract['totalAmount'] ?? 0;

    final statusLabel = switch (status.toUpperCase()) {
      'SIGNED' || 'COMPLETED' => 'Đã ký kết',
      'WAITING_BUYER' || 'PENDING_BUYER' => 'Chờ người mua ký',
      'WAITING_SELLER' || 'PENDING_SELLER' => 'Chờ người bán ký',
      'CANCELLED' => 'Đã huỷ bỏ',
      'PENDING' => 'Chờ xử lý',
      _ => status
    };

    final statusColor = switch (status.toUpperCase()) {
      'SIGNED' || 'COMPLETED' => AppTheme.success,
      'WAITING_BUYER' || 'PENDING_BUYER' => AppTheme.info,
      'WAITING_SELLER' || 'PENDING_SELLER' => AppTheme.warning,
      'CANCELLED' => AppTheme.error,
      _ => AppTheme.grey500
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID & Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$contractId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: isDark ? Colors.white10 : AppTheme.grey100,
              height: 1,
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.grey900,
                  ),
                ),
                const SizedBox(height: 12),

                // Buyer / Seller info
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 14, color: AppTheme.grey400),
                    const SizedBox(width: 8),
                    const Text('Mua: ',
                        style:
                            TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    Expanded(
                      child: Text(
                        buyerName,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppTheme.grey800,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 14, color: AppTheme.grey400),
                    const SizedBox(width: 8),
                    const Text('Bán: ',
                        style:
                            TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    Expanded(
                      child: Text(
                        sellerName,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppTheme.grey800,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total amount & signature date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giá trị hợp đồng',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.grey400)),
                        const SizedBox(height: 2),
                        Text(
                          AppUtils.formatCurrency(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Tạo ngày: ${_formatDate(contract['createdAt'] ?? contract['date'])}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.grey500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
