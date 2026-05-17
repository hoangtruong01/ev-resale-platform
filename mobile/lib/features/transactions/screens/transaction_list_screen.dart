import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
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
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có giao dịch nào.',
                style: TextStyle(color: AppTheme.grey600),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
                  ),
                  title: Text(
                    tx['title'] ?? 'Giao dịch #${tx['id']?.toString().substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Trạng thái: ${tx['status']}'),
                      if (tx['amount'] != null)
                        Text(
                          'Số tiền: ${tx['amount']} VNĐ',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.grey400),
                  onTap: () {
                    // TODO: Navigate to detail
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
