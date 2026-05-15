import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/network/dio_client.dart';
import '../models/auction_model.dart';

final auctionServiceProvider = Provider<AuctionService>((ref) {
  return AuctionService(ref.watch(dioProvider));
});

class AuctionService {
  final Dio _dio;
  AuctionService(this._dio);

  Future<List<AuctionModel>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? itemType,
  }) async {
    final response = await _dio.get('/auctions', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (itemType != null) 'itemType': itemType,
    });
    
    final data = response.data;
    if (data is List) {
      return data.map((e) => AuctionModel.fromJson(e)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => AuctionModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<AuctionModel> getAuctionById(String id) async {
    final response = await _dio.get('/auctions/$id');
    return AuctionModel.fromJson(response.data);
  }

  Future<AuctionModel> createAuction(Map<String, dynamic> data) async {
    final response = await _dio.post('/auctions', data: data);
    return AuctionModel.fromJson(response.data);
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
