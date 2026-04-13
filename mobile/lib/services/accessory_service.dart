import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/accessory_model.dart';

final accessoryServiceProvider = Provider<AccessoryService>((ref) {
  return AccessoryService(ref.watch(dioProvider));
});

class AccessoryService {
  final Dio _dio;
  AccessoryService(this._dio);

  Future<AccessoryListResponse> getAccessories({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _dio.get('/accessories', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (location != null && location.isNotEmpty) 'location': location,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'approvalStatus': 'APPROVED',
    });
    return AccessoryListResponse.fromJson(response.data);
  }

  Future<AccessoryModel> getAccessoryById(String id) async {
    final response = await _dio.get('/accessories/$id');
    return AccessoryModel.fromJson(response.data);
  }

  Future<AccessoryListResponse> getMyAccessories({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get('/accessories/my-accessories', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return AccessoryListResponse.fromJson(response.data);
  }

  Future<AccessoryModel> createAccessory(Map<String, dynamic> data) async {
    final response = await _dio.post('/accessories', data: data);
    return AccessoryModel.fromJson(response.data);
  }

  Future<AccessoryModel> updateAccessory(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/accessories/$id', data: data);
    return AccessoryModel.fromJson(response.data);
  }

  Future<void> deleteAccessory(String id) async {
    await _dio.delete('/accessories/$id');
  }

  Future<List<String>> uploadListingImages(List<File> files) async {
    if (files.isEmpty) {
      return [];
    }

    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      ));
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
