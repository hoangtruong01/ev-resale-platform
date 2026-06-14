import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class TransactionItem {
  final String id;
  final String title;
  final String role;
  final String roleLabel;
  final String partnerName;
  final double amount;
  final String status;
  final String statusLabel;
  final Color statusColor;
  final String createdAt;
  final String productType;
  final String? buyerName;
  final String? sellerName;
  final bool hasContract;
  final String? contractStatus;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.role,
    required this.roleLabel,
    required this.partnerName,
    required this.amount,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.createdAt,
    required this.productType,
    this.buyerName,
    this.sellerName,
    this.hasContract = false,
    this.contractStatus,
  });

  factory TransactionItem.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final id = _stringValue(json['id']);
    final sellerId = _stringValue(json['sellerId']);
    final purchaseBuyer = _mapValue(_mapValue(json['purchase'])?['buyer']);
    final chatRoom = _mapValue(json['chatRoom']);
    final chatBuyer = _mapValue(chatRoom?['buyer']);
    final seller = _mapValue(json['seller']) ?? _mapValue(chatRoom?['seller']);
    final isSeller = sellerId == currentUserId;
    final isBuyer = _stringValue(purchaseBuyer?['id']) == currentUserId ||
        _stringValue(chatBuyer?['id']) == currentUserId;
    final role = isSeller ? 'seller' : (isBuyer ? 'buyer' : 'unknown');
    final partner = isSeller ? (purchaseBuyer ?? chatBuyer) : seller;
    final rawStatus = _stringValue(json['status']);
    final status = rawStatus.isEmpty ? 'PENDING' : rawStatus.toUpperCase();

    final contract = _mapValue(json['contract']);
    final buyer = purchaseBuyer ?? chatBuyer;
    final sellerName = _displayName(seller);
    final buyerName = buyer != null ? _displayName(buyer) : null;

    return TransactionItem(
      id: id,
      title: _title(json, id),
      role: role,
      roleLabel: role == 'seller' ? 'Đã bán' : 'Đã mua',
      partnerName: _displayName(partner),
      amount: _doubleValue(json['amount']),
      status: status,
      statusLabel: _statusLabel(status),
      statusColor: _statusColor(status),
      createdAt: _stringValue(json['createdAt']),
      productType: _productType(json),
      buyerName: buyerName,
      sellerName: sellerName,
      hasContract: contract != null,
      contractStatus: contract != null ? _stringValue(contract['status']) : null,
    );
  }

  String get amountLabel => AppUtils.formatCurrency(amount);

  String get createdAtLabel {
    if (createdAt.isEmpty) return '';
    return AppUtils.timeAgo(createdAt);
  }

  String get partnerLine {
    final prefix = role == 'seller' ? 'Đã bán cho' : 'Đã mua từ';
    return '$prefix $partnerName';
  }

  static String _title(Map<String, dynamic> json, String id) {
    final vehicle = _mapValue(json['vehicle']);
    final battery = _mapValue(json['battery']);
    final accessory = _mapValue(json['accessory']);
    final auction = _mapValue(json['auction']);
    final vehicleName = _stringValue(vehicle?['name']);
    final batteryName = _stringValue(battery?['name']);
    final accessoryName = _stringValue(accessory?['name']);
    final auctionTitle = _stringValue(auction?['title']);
    final auctionName = _stringValue(auction?['name']);

    if (vehicleName.isNotEmpty) return vehicleName;
    if (batteryName.isNotEmpty) return batteryName;
    if (accessoryName.isNotEmpty) return accessoryName;
    if (auctionTitle.isNotEmpty) return auctionTitle;
    if (auctionName.isNotEmpty) return auctionName;
    return 'Giao dịch #${_shortId(id)}';
  }

  static String _productType(Map<String, dynamic> json) {
    if (json['vehicle'] != null) return 'Xe';
    if (json['battery'] != null) return 'Pin';
    if (json['accessory'] != null) return 'Phụ kiện';
    if (json['auction'] != null) return 'Đấu giá';
    return 'Khác';
  }

  static String _shortId(String id) {
    if (id.isEmpty) return '--------';
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  static Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _stringValue(dynamic value) => value?.toString() ?? '';

  static double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _displayName(Map<String, dynamic>? user) {
    final name = _stringValue(user?['name']);
    if (name.isNotEmpty) return name;
    final fullName = _stringValue(user?['fullName']);
    if (fullName.isNotEmpty) return fullName;
    final email = _stringValue(user?['email']);
    if (email.isNotEmpty) return email;
    return 'Đối tác';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'PENDING' => 'Đang chờ',
      'AWAITING_DEPOSIT' => 'Chờ đặt cọc',
      'DEPOSIT_PAID' => 'Đã đặt cọc',
      'AWAITING_CONTRACT' => 'Chờ hợp đồng',
      'CONTRACT_SIGNED' => 'Đã ký hợp đồng',
      'AWAITING_BALANCE' => 'Chờ thanh toán còn lại',
      'COMPLETED' => 'Hoàn tất',
      'CANCELLED' => 'Đã hủy',
      'REFUNDED' => 'Đã hoàn tiền',
      _ => status,
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'COMPLETED' => AppTheme.success,
      'CANCELLED' || 'REFUNDED' => AppTheme.error,
      'DEPOSIT_PAID' || 'CONTRACT_SIGNED' => AppTheme.info,
      'AWAITING_DEPOSIT' || 'AWAITING_CONTRACT' || 'AWAITING_BALANCE' =>
        AppTheme.warning,
      _ => AppTheme.grey600,
    };
  }
}
