import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../models/sepay_payment.dart';

class PaymentService {
  final Dio _dio;

  PaymentService(this._dio);

  /// Tạo phiên thanh toán SePay — trả về QR + thông tin chuyển khoản
  Future<SepayPayment> createSepayPayment({
    required String transactionId,
    required String paymentType, // FULL | DEPOSIT | BALANCE
  }) async {
    final response = await _dio.post(
      '/payments/sepay/create',
      data: {
        'transactionId': transactionId,
        'paymentType': paymentType,
      },
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return SepayPayment.fromJson(
      data,
      transactionId: transactionId,
      paymentType: paymentType,
    );
  }

  /// Polling trạng thái thanh toán SePay
  Future<SepayStatusResult> getSepayStatus(String attemptId) async {
    final response = await _dio.get('/payments/sepay/status/$attemptId');
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return SepayStatusResult.fromJson(data);
  }

  /// Giả lập thanh toán SePay (Test Mode / Sandbox)
  Future<bool> simulateSepayPayment({
    required String paymentAttemptId,
    required bool success,
  }) async {
    final response = await _dio.post(
      '/payments/sepay/simulate',
      data: {
        'paymentAttemptId': paymentAttemptId,
        'status': success ? 'SUCCESS' : 'FAILED',
      },
    );
    final data = response.data is Map ? response.data as Map : {};
    return data['success'] == true;
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentService(dio);
});
