class SepayPayment {
  final String paymentAttemptId;
  final String qrUrl;
  final String transferContent;
  final double amount;
  final String bankAccountNumber;
  final String bankAccountName;
  final String bankName;
  final DateTime expireAt;
  final String transactionId;
  final String paymentType;

  const SepayPayment({
    required this.paymentAttemptId,
    required this.qrUrl,
    required this.transferContent,
    required this.amount,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.bankName,
    required this.expireAt,
    required this.transactionId,
    required this.paymentType,
  });

  factory SepayPayment.fromJson(
    Map<String, dynamic> json, {
    required String transactionId,
    required String paymentType,
  }) {
    return SepayPayment(
      paymentAttemptId: json['paymentAttemptId'] as String? ?? '',
      qrUrl: json['qrUrl'] as String? ?? '',
      transferContent: json['transferContent'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      bankAccountName: json['bankAccountName'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      expireAt: DateTime.tryParse(json['expireAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(minutes: 15)),
      transactionId: transactionId,
      paymentType: paymentType,
    );
  }
}

class SepayStatusResult {
  final String status;
  final String transactionId;
  final double amount;
  final String paymentType;

  const SepayStatusResult({
    required this.status,
    required this.transactionId,
    required this.amount,
    required this.paymentType,
  });

  factory SepayStatusResult.fromJson(Map<String, dynamic> json) {
    return SepayStatusResult(
      status: json['status'] as String? ?? 'PENDING',
      transactionId: json['transactionId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentType: json['paymentType'] as String? ?? 'FULL',
    );
  }

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';
  bool get isPending => status == 'PENDING';
}
