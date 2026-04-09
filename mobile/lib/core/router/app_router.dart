import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/batteries/screens/battery_list_screen.dart';
import '../../features/batteries/screens/battery_detail_screen.dart';
import '../../features/vehicles/screens/vehicle_list_screen.dart';
import '../../features/vehicles/screens/vehicle_detail_screen.dart';
import '../../features/auctions/screens/auction_list_screen.dart';
import '../../features/auctions/screens/auction_detail_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../widgets/main_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/batteries/screens/battery_monitor_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isAuthRoute) {
        return '/auth/login';
      }
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/batteries',
            builder: (context, state) => const BatteryListScreen(),
          ),
          GoRoute(
            path: '/batteries/:id',
            builder: (context, state) =>
                BatteryDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/vehicles',
            builder: (context, state) => const VehicleListScreen(),
          ),
          GoRoute(
            path: '/vehicles/:id',
            builder: (context, state) =>
                VehicleDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/auctions',
            builder: (context, state) => const AuctionListScreen(),
          ),
          GoRoute(
            path: '/auctions/:id',
            builder: (context, state) =>
                AuctionDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/chat/:roomId',
            builder: (context, state) =>
                ChatRoomScreen(roomId: state.pathParameters['roomId']!),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/battery-monitor/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final name = state.uri.queryParameters['name'] ?? 'Giám sát Pin';
              return BatteryMonitorScreen(batteryId: id, batteryName: name);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Trang không tìm thấy: ${state.uri}'),
          ],
        ),
      ),
    ),
  );
});
