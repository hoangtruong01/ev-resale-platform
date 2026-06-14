import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/transaction_item.dart';
import '../providers/transaction_provider.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải danh sách giao dịch:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(transactionListProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có giao dịch nào.',
                style: TextStyle(color: AppTheme.grey600),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(transactionListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _TransactionCard(item: transactions[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionItem item;

  const _TransactionCard({required this.item});

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : AppTheme.grey500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? (isDark ? Colors.white : AppTheme.grey800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.isEmpty) return '';
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: Navigate to detail
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Icon(
                item.role == 'seller'
                    ? Icons.sell_outlined
                    : Icons.shopping_bag_outlined,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.productType} • #${_shortId(item.id)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : AppTheme.grey600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(item: item),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, 'Người bán:', item.sellerName ?? '---'),
                  _buildInfoRow(context, 'Người mua:', item.buyerName ?? '---'),
                  if (item.hasContract)
                    _buildInfoRow(
                      context,
                      'Hợp đồng:',
                      item.contractStatus ?? 'Có hợp đồng',
                      valueColor: AppTheme.primaryGreen,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.amountLabel,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (item.createdAtLabel.isNotEmpty)
                        Text(
                          item.createdAtLabel,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppTheme.grey500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TransactionItem item;

  const _StatusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: item.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        item.statusLabel,
        style: TextStyle(
          color: item.statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
