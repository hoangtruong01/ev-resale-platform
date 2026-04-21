import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/auth/session_state_provider.dart';

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Auth state notifier
class AuthNotifier extends AsyncNotifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<AuthState> build() async {
    return _loadFromStorage();
  }

  Future<AuthState> _loadFromStorage() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');
      final userJson = await _storage.read(key: 'user_data');
      if (token != null && userJson != null) {
        // Keep backward compatibility for older sessions that do not yet store refresh token.
        if (refreshToken == null || refreshToken.isEmpty) {
          await _storage.deleteAll();
          return const AuthState();
        }
        final user = UserModel.fromJson(jsonDecode(userJson));
        return AuthState(user: user);
      }
    } catch (_) {}
    return const AuthState();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.login(email: email, password: password);
      await _saveAuth(response);
      ref.read(sessionExpiredTickProvider.notifier).state = 0;
      state = AsyncValue.data(AuthState(user: response.user));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: parseApiError(e)));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await _saveAuth(response);
      ref.read(sessionExpiredTickProvider.notifier).state = 0;
      state = AsyncValue.data(AuthState(user: response.user));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: parseApiError(e)));
    }
  }

  Future<void> googleLogin(String idToken) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.googleLogin(idToken);
      await _saveAuth(response);
      ref.read(sessionExpiredTickProvider.notifier).state = 0;
      state = AsyncValue.data(AuthState(user: response.user));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: parseApiError(e)));
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = const AsyncValue.data(AuthState());
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Missing Google ID token');
      }

      final authService = ref.read(authServiceProvider);
      final response = await authService.googleLogin(idToken);
      await _saveAuth(response);
      ref.read(sessionExpiredTickProvider.notifier).state = 0;
      state = AsyncValue.data(AuthState(user: response.user));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: parseApiError(e)));
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    ref.read(sessionExpiredTickProvider.notifier).state = 0;
    state = const AsyncValue.data(AuthState());
  }

  Future<void> refreshProfile() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getProfile();
      await _storage.write(
          key: 'user_data', value: jsonEncode(user.toJson()));
      state = AsyncValue.data(AuthState(user: user));
    } catch (_) {}
  }

  Future<void> _saveAuth(AuthResponse response) async {
    await _storage.write(
        key: 'access_token', value: response.accessToken);
    await _storage.write(
      key: 'refresh_token', value: response.refreshToken);
    await _storage.write(
        key: 'user_data', value: jsonEncode(response.user.toJson()));
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Convenience provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value?.user;
});
