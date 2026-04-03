import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/battery_model.dart';

final batteryServiceProvider = Provider<BatteryService>((ref) {
  return BatteryService(ref.watch(dioProvider));
});

class BatteryService {
  final Dio _dio;
  BatteryService(this._dio);

  Future<BatteryListResponse> getBatteries({
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    double? minPrice,
    double? maxPrice,
    int? minCondition,
    String? location,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get('/batteries', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null) 'type': type,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minCondition != null) 'minCondition': minCondition,
      if (location != null && location.isNotEmpty) 'location': location,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'approvalStatus': 'APPROVED',
    });
    return BatteryListResponse.fromJson(response.data);
  }

  Future<BatteryModel> getBatteryById(String id) async {
    final response = await _dio.get('/batteries/$id');
    return BatteryModel.fromJson(response.data);
  }

  Future<BatteryListResponse> getMyBatteries({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get('/batteries/my-batteries', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return BatteryListResponse.fromJson(response.data);
  }

  Future<BatteryModel> createBattery(Map<String, dynamic> data) async {
    final response = await _dio.post('/batteries', data: data);
    return BatteryModel.fromJson(response.data);
  }

  Future<BatteryModel> updateBattery(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/batteries/$id', data: data);
    return BatteryModel.fromJson(response.data);
  }

  Future<void> deleteBattery(String id) async {
    await _dio.delete('/batteries/$id');
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _dio.get('/batteries/statistics');
    return response.data;
  }

  Future<Map<String, dynamic>> suggestPrice({
    required String type,
    required double capacity,
    required int condition,
  }) async {
    final response = await _dio.get('/batteries/suggest-price', queryParameters: {
      'type': type,
      'capacity': capacity,
      'condition': condition,
    });
    return response.data;
  }
}
