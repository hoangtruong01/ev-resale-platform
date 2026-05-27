import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../auth/session_state_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/batteries/screens/battery_list_screen.dart';
import '../../features/batteries/screens/battery_detail_screen.dart';
import '../../features/batteries/screens/sell_battery_screen.dart';
import '../../features/vehicles/screens/vehicle_list_screen.dart';
import '../../features/vehicles/screens/vehicle_detail_screen.dart';
import '../../features/vehicles/screens/sell_vehicle_screen.dart';
import '../../features/accessories/screens/accessory_list_screen.dart';
import '../../features/accessories/screens/accessory_detail_screen.dart';
import '../../features/accessories/screens/sell_accessory_screen.dart';
import '../../features/auctions/screens/auction_list_screen.dart';
import '../../features/auctions/screens/auction_detail_screen.dart';
import '../../features/auctions/screens/create_auction_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../widgets/main_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/batteries/screens/battery_monitor_screen.dart';
import '../../features/transactions/screens/transaction_list_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/compare/screens/compare_screen.dart';
import '../../features/ai_chat/screens/ai_chat_screen.dart';

// Admin imports
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_listings_screen.dart';
import '../../features/admin/screens/admin_transactions_screen.dart';
import '../../features/admin/screens/admin_support_tickets_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_more_screen.dart';
import '../../features/admin/screens/admin_auctions_screen.dart';
import '../../features/admin/screens/admin_fees_screen.dart';
import '../../features/admin/screens/admin_contracts_screen.dart';
import '../../features/admin/screens/admin_permissions_screen.dart';
import '../../features/admin/screens/kyc_management_screen.dart';
import '../../widgets/admin_shell.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Set admin mode on startup if user already has admin credentials
    final initialUser = _ref.read(authStateProvider).value?.user;
    if (initialUser?.isAdmin == true || initialUser?.isModerator == true) {
      _ref.read(adminModeProvider.notifier).state = true;
    }

    _ref.listen(authStateProvider, (prev, next) {
      final user = next.value?.user;
      if (user?.isAdmin == true || user?.isModerator == true) {
        _ref.read(adminModeProvider.notifier).state = true;
      }
      notifyListeners();
    });
    _ref.listen(sessionExpiredTickProvider, (_, __) => notifyListeners());
    _ref.listen(adminModeProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final sessionExpiredTick = _ref.read(sessionExpiredTickProvider);

    final isLoggedIn = authState.value?.isAuthenticated ?? false;
    final isPublicRoute = state.matchedLocation.startsWith('/auth') ||
        state.matchedLocation == '/splash' ||
        state.matchedLocation == '/welcome';

    if (sessionExpiredTick > 0 && !isPublicRoute) {
      return '/auth/login';
    }

    if (!isLoggedIn && !isPublicRoute) {
      return '/welcome';
    }

    final user = authState.value?.user;
    final userHasAdminRights = user?.isAdmin == true || user?.isModerator == true;

    if (isLoggedIn) {
      final isGoingToAdmin = state.matchedLocation.startsWith('/admin');

      final isAdminMode = _ref.read(adminModeProvider);

      if (userHasAdminRights && isAdminMode) {
        // Force admins in admin mode to stay within admin screens
        if (!isGoingToAdmin) {
          return '/admin';
        }
      } else {
        // Normal users, or admins who switched off admin mode, cannot access admin pages
        if (isGoingToAdmin) {
          return '/';
        }
        if (isPublicRoute && state.matchedLocation != '/splash') {
          return '/';
        }
      }
    }
    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome / Landing page (before login)
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
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

      GoRoute(
        path: '/ai-chat',
        builder: (context, state) => const AiChatScreen(),
      ),

      // Admin shell with bottom nav
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/listings',
            builder: (context, state) => const AdminListingsScreen(),
          ),
          GoRoute(
            path: '/admin/transactions',
            builder: (context, state) => const AdminTransactionsScreen(),
          ),
          GoRoute(
            path: '/admin/support',
            builder: (context, state) => const AdminSupportTicketsScreen(),
          ),
          GoRoute(
            path: '/admin/more',
            builder: (context, state) => const AdminMoreScreen(),
          ),
          GoRoute(
            path: '/admin/kyc',
            builder: (context, state) => const KycManagementScreen(),
          ),
          GoRoute(
            path: '/admin/auctions',
            builder: (context, state) => const AdminAuctionsScreen(),
          ),
          GoRoute(
            path: '/admin/contracts',
            builder: (context, state) => const AdminContractsScreen(),
          ),
          GoRoute(
            path: '/admin/fees',
            builder: (context, state) => const AdminFeesScreen(),
          ),
          GoRoute(
            path: '/admin/permissions',
            builder: (context, state) => const AdminPermissionsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) {
              final tabIndexStr = state.uri.queryParameters['tab'];
              final tabIndex = int.tryParse(tabIndexStr ?? '') ?? 0;
              return AdminSettingsScreen(initialTab: tabIndex);
            },
          ),
        ],
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.matchedLocation, child: child),
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
            path: '/accessories',
            builder: (context, state) => const AccessoryListScreen(),
          ),
          GoRoute(
            path: '/accessories/:id',
            builder: (context, state) =>
                AccessoryDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/sell/accessory',
            builder: (context, state) => const SellAccessoryScreen(),
          ),
          GoRoute(
            path: '/sell/battery',
            builder: (context, state) => const SellBatteryScreen(),
          ),
          GoRoute(
            path: '/sell/vehicle',
            builder: (context, state) => const SellVehicleScreen(),
          ),
          GoRoute(
            path: '/auctions',
            builder: (context, state) => const AuctionListScreen(),
          ),
          GoRoute(
            path: '/auctions/create',
            builder: (context, state) => const CreateAuctionScreen(),
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
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionListScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/compare',
            builder: (context, state) => const CompareScreen(),
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
