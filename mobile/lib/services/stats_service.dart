import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/stats_model.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(ref.watch(dioProvider));
});

class StatsService {
  final Dio _dio;
  StatsService(this._dio);

  Future<StatsOverview> getOverview() async {
    final response = await _dio.get('/stats/overview');
    return StatsOverview.fromJson(response.data);
  }
}
