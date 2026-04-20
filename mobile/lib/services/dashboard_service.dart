import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(dioProvider));
});

class DashboardOverviewData {
  final int totalOrders;
  final int favoriteCount;
  final int activeListings;

  const DashboardOverviewData({
    required this.totalOrders,
    required this.favoriteCount,
    required this.activeListings,
  });

  factory DashboardOverviewData.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewData(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      activeListings: (json['activeListings'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardOrderData {
  final String id;
  final String itemName;
  final String status;
  final double amount;
  final String createdAt;

  const DashboardOrderData({
    required this.id,
    required this.itemName,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  factory DashboardOrderData.fromJson(Map<String, dynamic> json) {
    return DashboardOrderData(
      id: json['id'] as String? ?? '',
      itemName: json['itemName'] as String? ?? 'Sản phẩm',
      status: json['status'] as String? ?? 'PENDING',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class DashboardFavoriteData {
  final String id;
  final String title;
  final double price;
  final String? thumbnail;

  const DashboardFavoriteData({
    required this.id,
    required this.title,
    required this.price,
    this.thumbnail,
  });

  factory DashboardFavoriteData.fromJson(Map<String, dynamic> json) {
    return DashboardFavoriteData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sản phẩm',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      thumbnail: json['thumbnail'] as String?,
    );
  }
}

class DashboardService {
  final Dio _dio;
  DashboardService(this._dio);

  Future<DashboardOverviewData> getOverview() async {
    final response = await _dio.get('/dashboard/overview');
    return DashboardOverviewData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<DashboardOrderData>> getOrders() async {
    final response = await _dio.get('/dashboard/orders');
    final payload = response.data;
    final list = (payload is Map ? payload['orders'] : null);
    if (list is! List) {
      return const [];
    }
    return list
        .whereType<Map>()
        .map((item) => DashboardOrderData.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<DashboardFavoriteData>> getFavorites() async {
    final response = await _dio.get('/dashboard/favorites');
    final payload = response.data;
    final list = (payload is Map ? payload['favorites'] : null);
    if (list is! List) {
      return const [];
    }
    return list
        .whereType<Map>()
        .map((item) => DashboardFavoriteData.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
