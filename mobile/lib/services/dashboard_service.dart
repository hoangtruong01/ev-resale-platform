import 'dart:async';
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
  final String? itemType;
  final String? sourceId;
  final String? location;

  const DashboardFavoriteData({
    required this.id,
    required this.title,
    required this.price,
    this.thumbnail,
    this.itemType,
    this.sourceId,
    this.location,
  });

  factory DashboardFavoriteData.fromJson(Map<String, dynamic> json) {
    return DashboardFavoriteData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sản phẩm',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      thumbnail: json['thumbnail'] as String?,
      itemType: json['itemType'] as String?,
      sourceId: json['sourceId'] as String?,
      location: json['location'] as String?,
    );
  }
}

class DashboardFavoritesNotifier extends AsyncNotifier<List<DashboardFavoriteData>> {
  @override
  FutureOr<List<DashboardFavoriteData>> build() {
    return ref.watch(dashboardServiceProvider).getFavorites();
  }

  Future<void> addFavorite({
    String? vehicleId,
    String? batteryId,
    String? auctionId,
    required DashboardFavoriteData tempFavorite,
  }) async {
    final previousState = state;
    if (state.hasValue) {
      final list = List<DashboardFavoriteData>.from(state.value!);
      if (!list.any((fav) => fav.sourceId == tempFavorite.sourceId)) {
        list.add(tempFavorite);
        state = AsyncData(list);
      }
    }

    try {
      await ref.read(dashboardServiceProvider).addFavorite(
        vehicleId: vehicleId,
        batteryId: batteryId,
        auctionId: auctionId,
      );
      final freshList = await ref.read(dashboardServiceProvider).getFavorites();
      state = AsyncData(freshList);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> removeFavorite(String favoriteId) async {
    final previousState = state;
    if (state.hasValue) {
      final list = List<DashboardFavoriteData>.from(state.value!);
      list.removeWhere((fav) => fav.id == favoriteId);
      state = AsyncData(list);
    }

    try {
      await ref.read(dashboardServiceProvider).removeFavorite(favoriteId);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> removeFavoriteBySourceId(String sourceId) async {
    final previousState = state;
    String? favId;
    if (state.hasValue) {
      final list = List<DashboardFavoriteData>.from(state.value!);
      final idx = list.indexWhere((fav) => fav.sourceId == sourceId);
      if (idx != -1) {
        favId = list[idx].id;
        list.removeAt(idx);
        state = AsyncData(list);
      }
    }

    try {
      if (favId != null && !favId.startsWith('temp_')) {
        await ref.read(dashboardServiceProvider).removeFavorite(favId);
      } else {
        final freshList = await ref.read(dashboardServiceProvider).getFavorites();
        final realItem = freshList.firstWhere(
          (fav) => fav.sourceId == sourceId,
          orElse: () => throw Exception('Item not found'),
        );
        await ref.read(dashboardServiceProvider).removeFavorite(realItem.id);
        final updatedList = await ref.read(dashboardServiceProvider).getFavorites();
        state = AsyncData(updatedList);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}

final dashboardFavoritesProvider =
    AsyncNotifierProvider<DashboardFavoritesNotifier, List<DashboardFavoriteData>>(
  DashboardFavoritesNotifier.new,
);

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

  Future<void> addFavorite({
    String? vehicleId,
    String? batteryId,
    String? auctionId,
  }) async {
    await _dio.post('/dashboard/favorites', data: {
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (batteryId != null) 'batteryId': batteryId,
      if (auctionId != null) 'auctionId': auctionId,
    });
  }

  Future<void> removeFavorite(String favoriteId) async {
    await _dio.delete('/dashboard/favorites/$favoriteId');
  }
}
