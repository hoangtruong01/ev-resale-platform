import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Widget _buildInfoRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
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
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppTheme.grey500),
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

  bool _canPay(TransactionItem item) {
    // Only buyer can initiate payment
    if (item.role != 'buyer') return false;
    return [
      'PENDING',
      'AWAITING_DEPOSIT',
      'AWAITING_BALANCE',
    ].contains(item.status);
  }

  String _paymentType(TransactionItem item) {
    return switch (item.status) {
      'AWAITING_DEPOSIT' => 'DEPOSIT',
      'AWAITING_BALANCE' => 'BALANCE',
      _ => 'FULL',
    };
  }

  void _showTransactionDetailSheet(BuildContext context, TransactionItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppTheme.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết Giao dịch',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.grey900,
                    ),
                  ),
                  _StatusChip(item: item),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'MÃ GD: #${item.id}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white54 : AppTheme.grey500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.grey900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.amountLabel,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _DetailRow(
                  label: 'Vai trò của bạn',
                  value: item.roleLabel,
                  isDark: isDark),
              _DetailRow(
                  label: 'Phân loại', value: item.productType, isDark: isDark),
              _DetailRow(
                label: item.role == 'seller' ? 'Người mua' : 'Người bán',
                value: item.partnerName,
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Ngày giao dịch',
                value:
                    item.createdAtLabel.isNotEmpty ? item.createdAtLabel : 'N/A',
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Hợp đồng',
                value: item.hasContract
                    ? (item.contractStatus == 'SIGNED'
                        ? 'Đã ký kết'
                        : 'Đang chờ ký')
                    : 'Không có hợp đồng',
                valueColor: item.hasContract ? AppTheme.primaryGreen : null,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Payment button (only for buyers with payable status)
              if (_canPay(item)) ...[  
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giao dịch đang chờ thanh toán. Nhấn để thanh toán ngay!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : AppTheme.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                        '/transactions/${item.id}/payment',
                        extra: {
                          'amount': item.amount,
                          'paymentType': _paymentType(item),
                        },
                      );
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Thanh toán ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? Colors.white30 : AppTheme.grey300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đóng',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.grey700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showTransactionDetailSheet(context, item),
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
                                color:
                                    isDark ? Colors.white54 : AppTheme.grey600,
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
                  _buildInfoRow(
                      context, 'Người bán:', item.sellerName ?? '---'),
                  _buildInfoRow(
                      context, 'Người mua:', item.buyerName ?? '---'),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppTheme.grey600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? (isDark ? Colors.white : AppTheme.grey800),
              ),
            ),
          ),
        ],
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
