import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/dio_client.dart';
import '../models/vehicle_model.dart';

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService(ref.watch(dioProvider));
});

class VehicleService {
  final Dio _dio;
  VehicleService(this._dio);

  Future<VehicleListResponse> getVehicles({
    int page = 1,
    int limit = 10,
    String? search,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
    int? maxYear,
    String? location,
    String? sortBy,
    String? sortOrder,
  }) async {
    final effectiveBrand = (brand != null && brand.isNotEmpty)
        ? brand
        : (search != null && search.isNotEmpty ? search : null);

    final response = await _dio.get('/vehicles', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (effectiveBrand != null) 'brand': effectiveBrand,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minYear != null) 'minYear': minYear,
      if (maxYear != null) 'maxYear': maxYear,
      if (location != null && location.isNotEmpty) 'location': location,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'approvalStatus': 'APPROVED',
    });
    return VehicleListResponse.fromJson(response.data);
  }

  Future<VehicleModel> getVehicleById(String id) async {
    final response = await _dio.get('/vehicles/$id');
    return VehicleModel.fromJson(response.data);
  }

  Future<VehicleListResponse> getMyVehicles({int page = 1, int limit = 10}) async {
    final response = await _dio.get('/vehicles/my-vehicles', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return VehicleListResponse.fromJson(response.data);
  }

  Future<VehicleModel> createVehicle(Map<String, dynamic> data) async {
    final response = await _dio.post('/vehicles', data: data);
    return VehicleModel.fromJson(response.data);
  }

  Future<VehicleModel> updateVehicle(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/vehicles/$id', data: data);
    return VehicleModel.fromJson(response.data);
  }

  Future<void> deleteVehicle(String id) async {
    await _dio.delete('/vehicles/$id');
  }

  Future<Map<String, dynamic>> suggestPrice({
    required String brand,
    required String model,
    required int year,
    required String condition,
    int? mileage,
  }) async {
    final response = await _dio.post('/ai/vehicles/suggest-price', data: {
      'brand': brand,
      'model': model,
      'year': year,
      'condition': condition,
      if (mileage != null) 'mileage': mileage,
    });
    return response.data;
  }

  Future<List<String>> uploadListingImages(List<XFile> files) async {
    if (files.isEmpty) {
      return [];
    }

    final formData = FormData();
    for (final file in files) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        formData.files.add(MapEntry(
          'files',
          MultipartFile.fromBytes(bytes, filename: file.name),
        ));
      } else {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ));
      }
    }

    final response = await _dio.post('/uploads/listing-images', data: formData);
    final images = (response.data?['images'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return images
        .map((item) => item['url'] as String)
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
