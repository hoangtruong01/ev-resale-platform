import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/transaction_item.dart';

final transactionListProvider =
    FutureProvider.autoDispose<List<TransactionItem>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final dio = ref.watch(dioProvider);
  final response = await dio.get('/transactions/my');
  final data = response.data;
  final List<dynamic> rawTransactions;

  if (data is Map && data['data'] is List) {
    rawTransactions = data['data'] as List<dynamic>;
  } else if (data is List) {
    rawTransactions = data;
  } else {
    rawTransactions = [];
  }

  return rawTransactions
      .whereType<Map>()
      .map(
        (item) => TransactionItem.fromJson(
          Map<String, dynamic>.from(item),
          currentUserId: user.id,
        ),
      )
      .toList();
});
