import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

class AuthService {
  final Dio _dio;
  AuthService(this._dio);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null) 'phone': phone,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('/auth/profile');
    return UserModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/auth/password/forgot', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String resetId,
    required String otp,
  }) async {
    final response = await _dio.post('/auth/password/verify', data: {
      'resetId': resetId,
      'otp': otp,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> resendOtp({
    required String resetId,
  }) async {
    final response = await _dio.post('/auth/password/resend', data: {
      'resetId': resetId,
    });
    return response.data;
  }

  Future<void> resetPassword({
    required String resetId,
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    await _dio.post('/auth/password/reset', data: {
      'resetId': resetId,
      'resetToken': resetToken,
      'password': password,
      'confirmPassword': confirmPassword,
    });
  }

  Future<AuthResponse> googleLogin(String idToken) async {
    final response = await _dio.post('/auth/google/verify', data: {
      'credential': idToken,
    });
    return AuthResponse.fromJson(response.data);
  }
}
