import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final transactionListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/transactions/my');
  final data = response.data;
  if (data is Map && data['data'] is List) {
    return data['data'] as List<dynamic>;
  } else if (data is List) {
    return data;
  }
  return [];
});
