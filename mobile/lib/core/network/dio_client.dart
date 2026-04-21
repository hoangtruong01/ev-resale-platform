import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../auth/session_state_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

class AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();
  static Future<String?>? _refreshingTokenFuture;
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshRequest = request.path.contains('/auth/refresh');
    final wasRetried = request.extra['retried'] == true;

    if (isUnauthorized && !isRefreshRequest && !wasRetried) {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken != null) {
        try {
          final retryDio = Dio(
            BaseOptions(
              baseUrl: AppConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final retryOptions = request.copyWith(
            headers: {
              ...request.headers,
              'Authorization': 'Bearer $newAccessToken',
            },
            extra: {
              ...request.extra,
              'retried': true,
            },
          );

          final response = await retryDio.fetch(retryOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          // Fall through and trigger session expiration handling below.
        }
      }

      await _storage.deleteAll();
      _ref.read(sessionExpiredTickProvider.notifier).state++;
    }

    handler.next(err);
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshingTokenFuture != null) {
      return _refreshingTokenFuture;
    }

    final completer = Completer<String?>();
    _refreshingTokenFuture = completer.future;

    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        return completer.future;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      final payload = response.data;
      if (payload is! Map) {
        completer.complete(null);
        return completer.future;
      }

      final newAccessToken = payload['access_token'] as String?;
      final newRefreshToken = payload['refresh_token'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        completer.complete(null);
        return completer.future;
      }

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: newAccessToken,
      );

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefreshToken,
        );
      }

      completer.complete(newAccessToken);
      return completer.future;
    } catch (_) {
      completer.complete(null);
      return completer.future;
    } finally {
      _refreshingTokenFuture = null;
    }
  }
}

/// Generic API error handler
String parseApiError(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List) return msg.join(', ');
    }
    return error.message ?? 'Lỗi kết nối';
  }
  return error.toString();
}
