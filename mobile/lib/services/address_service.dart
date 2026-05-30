import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

class AddressService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://provinces.open-api.vn/api/v2',
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 5000),
  ));

  // Memory caches for static administrative levels
  List<ProvinceModel>? _provincesCache;
  final Map<int, List<DistrictModel>> _districtsCache = {};
  final Map<int, List<WardModel>> _wardsCache = {};

  /// Tải danh sách Tỉnh/Thành phố
  Future<List<ProvinceModel>> getProvinces() async {
    if (_provincesCache != null) {
      return _provincesCache!;
    }

    try {
      final response = await _dio.get('/p/');
      final data = response.data;
      if (data is List) {
        final provinces = data
            .map((item) => ProvinceModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        
        // Sắp xếp theo tên tiếng Việt
        provinces.sort((a, b) => a.name.compareTo(b.name));

        _provincesCache = provinces;
        return provinces;
      }
      return const [];
    } catch (e) {
      print('Lỗi tải danh sách Tỉnh/Thành phố: $e');
      rethrow;
    }
  }

  /// Tải danh sách Quận/Huyện theo Tỉnh/Thành phố
  Future<List<DistrictModel>> getDistricts(int provinceCode) async {
    if (_districtsCache.containsKey(provinceCode)) {
      return _districtsCache[provinceCode]!;
    }

    try {
      final response = await _dio.get('/p/$provinceCode', queryParameters: {'depth': 2});
      final data = response.data;
      if (data is Map && data['districts'] is List) {
        final districtsList = data['districts'] as List;
        final districts = districtsList
            .map((item) => DistrictModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // Sắp xếp theo tên tiếng Việt
        districts.sort((a, b) => a.name.compareTo(b.name));

        _districtsCache[provinceCode] = districts;
        return districts;
      }
      return const [];
    } catch (e) {
      print('Lỗi tải danh sách Quận/Huyện: $e');
      rethrow;
    }
  }

  /// Tải danh sách Phường/Xã theo Tỉnh/Thành phố
  Future<List<WardModel>> getWards(int provinceCode) async {
    if (_wardsCache.containsKey(provinceCode)) {
      return _wardsCache[provinceCode]!;
    }

    try {
      final response = await _dio.get('/p/$provinceCode', queryParameters: {'depth': 2});
      final data = response.data;
      if (data is Map && data['wards'] is List) {
        final wardsList = data['wards'] as List;
        final wards = wardsList
            .map((item) => WardModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // Sắp xếp theo tên tiếng Việt
        wards.sort((a, b) => a.name.compareTo(b.name));

        _wardsCache[provinceCode] = wards;
        return wards;
      }
      return const [];
    } catch (e) {
      print('Lỗi tải danh sách Phường/Xã: $e');
      rethrow;
    }
  }
}
