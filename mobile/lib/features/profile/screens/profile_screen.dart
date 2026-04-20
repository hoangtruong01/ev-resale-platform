import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evn_battery_trading/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/utils/app_utils.dart';
import '../../../services/dashboard_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/app_network_image.dart';
import 'kyc_verification_screen.dart';
import '../../admin/screens/kyc_management_screen.dart';

final dashboardOverviewProvider = FutureProvider<DashboardOverviewData>((ref) {
  return ref.read(dashboardServiceProvider).getOverview();
});

final dashboardOrdersProvider = FutureProvider<List<DashboardOrderData>>((ref) {
  return ref.read(dashboardServiceProvider).getOrders();
});

final dashboardFavoritesProvider = FutureProvider<List<DashboardFavoriteData>>((ref) {
  return ref.read(dashboardServiceProvider).getFavorites();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final ordersAsync = ref.watch(dashboardOrdersProvider);
    final favoritesAsync = ref.watch(dashboardFavoritesProvider);

    final overview = overviewAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const DashboardOverviewData(
        totalOrders: 0,
        favoriteCount: 0,
        activeListings: 0,
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: user?.avatar != null
                                ? ClipOval(
                                    child: AppNetworkImage(
                                      url: user!.avatar!,
                                      width: 88,
                                      height: 88,
                                    ),
                                  )
                                : Text(
                                    user?.displayName.isNotEmpty == true
                                        ? user!.displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? 'Người dùng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (user?.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppTheme.accentYellow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user!.rating!.toStringAsFixed(1)} (${user.totalRatings} đánh giá)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Menu Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.grey200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Đang bán',
                            value: '${overview.activeListings}',
                          ),
                        ),
                        const _VertDivider(),
                        Expanded(
                          child: _StatItem(
                            label: 'Đã mua',
                            value: '${overview.totalOrders}',
                          ),
                        ),
                        const _VertDivider(),
                        Expanded(
                          child: _StatItem(
                            label: 'Đã lưu',
                            value: '${overview.favoriteCount}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Menu sections
                  _MenuSection(
                    title: 'Tài khoản',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        label: 'Thông tin cá nhân',
                        onTap: () => _showProfileInfoDialog(context, user),
                      ),
                      _MenuItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Xác thực danh tính (eKYC)',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KycVerificationScreen(),
                          ),
                        ),
                        trailing: Consumer(
                          builder: (ctx, ref, _) {
                            final kycStatus = ref.watch(kycStatusProvider);
                            return kycStatus.when(
                              loading: () => const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (data) {
                                final status =
                                    data['kycStatus'] as String? ??
                                    'UNVERIFIED';
                                final (label, color) = switch (status) {
                                  'APPROVED' => (
                                    'Đã xác thực',
                                    AppTheme.success,
                                  ),
                                  'PENDING' => (
                                    'Đang xét duyệt',
                                    AppTheme.warning,
                                  ),
                                  'REJECTED' => ('Bị từ chối', AppTheme.error),
                                  _ => ('Chưa xác thực', AppTheme.grey400),
                                };
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline,
                        label: 'Đổi mật khẩu',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Cài đặt thông báo',
                        onTap: () => context.push('/notifications'),
                      ),
                      _MenuItem(
                        icon: Icons.credit_card_outlined,
                        label: 'Phương thức thanh toán',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang được cập nhật.'),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.language,
                        label: l10n.language,
                        onTap: () => _showLanguageSheet(context, ref, l10n),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _MenuSection(
                    title: 'Giao dịch',
                    items: [
                      _MenuItem(
                        icon: Icons.list_alt_outlined,
                        label: 'Tin đăng của tôi',
                        onTap: () => _showMyListingActions(context),
                      ),
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Lịch sử giao dịch',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardOrdersScreen(
                              ordersAsync: ordersAsync,
                            ),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline,
                        label: 'Đã lưu',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardFavoritesScreen(
                              favoritesAsync: favoritesAsync,
                            ),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.gavel_outlined,
                        label: 'Lịch sử đấu giá',
                        onTap: () => context.go('/auctions'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _MenuSection(
                    title: 'Hỗ trợ',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Trung tâm hỗ trợ',
                        onTap: () => context.push('/chat'),
                      ),
                      _MenuItem(
                        icon: Icons.policy_outlined,
                        label: 'Điều khoản & Chính sách',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng xem điều khoản trên website.'),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: 'Về ứng dụng',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'EVN Pin Điện',
                          applicationVersion: '1.0.0',
                          applicationLegalese: 'Nền tảng mua bán pin xe điện cũ EVN',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (user?.role == 'ADMIN' || user?.role == 'MODERATOR') ...[
                    _MenuSection(
                      title: 'Quản trị hệ thống',
                      items: [
                        _MenuItem(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Duyệt eKYC người dùng',
                          color: AppTheme.primaryGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KycManagementScreen(),
                            ),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.analytics_outlined,
                          label: 'Thống kê hệ thống',
                          onTap: () => context.go('/'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Logout
                  InkWell(
                    onTap: () => _showLogoutDialog(context, ref),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showMyListingActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Quản lý tin đăng',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.battery_charging_full_rounded),
              title: const Text('Đăng bán pin điện'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/sell/battery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.electric_car_rounded),
              title: const Text('Đăng bán xe điện'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/sell/vehicle');
              },
            ),
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: const Text('Đăng bán phụ kiện'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/sell/accessory');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileInfoDialog(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông tin cá nhân'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Họ tên: ${user?.displayName ?? 'Chưa cập nhật'}'),
            const SizedBox(height: 8),
            Text('Email: ${user?.email ?? 'Chưa cập nhật'}'),
            const SizedBox(height: 8),
            Text('Số điện thoại: ${user?.phone ?? 'Chưa cập nhật'}'),
            const SizedBox(height: 8),
            Text('Địa chỉ: ${user?.address ?? 'Chưa cập nhật'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class DashboardOrdersScreen extends StatelessWidget {
  final AsyncValue<List<DashboardOrderData>> ordersAsync;
  const DashboardOrdersScreen({super.key, required this.ordersAsync});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có giao dịch nào',
                style: TextStyle(color: AppTheme.grey600),
              ),
            );
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final order = orders[i];
              return ListTile(
                title: Text(order.itemName),
                subtitle: Text('${order.status} • ${AppUtils.timeAgo(order.createdAt)}'),
                trailing: Text(
                  AppUtils.formatCurrency(order.amount),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DashboardFavoritesScreen extends StatelessWidget {
  final AsyncValue<List<DashboardFavoriteData>> favoritesAsync;
  const DashboardFavoritesScreen({super.key, required this.favoritesAsync});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm đã lưu')),
      body: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa lưu sản phẩm nào',
                style: TextStyle(color: AppTheme.grey600),
              ),
            );
          }
          return ListView.separated(
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final favorite = favorites[i];
              return ListTile(
                title: Text(favorite.title),
                subtitle: const Text('Sản phẩm yêu thích'),
                trailing: Text(
                  AppUtils.formatCurrency(favorite.price),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showLanguageSheet(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.language,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _LanguageOption(
            label: l10n.languageVi,
            onTap: () {
              ref.read(localeProvider.notifier).state = const Locale('vi');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _LanguageOption(
            label: l10n.languageEn,
            onTap: () {
              ref.read(localeProvider.notifier).state = const Locale('en');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.grey200),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.grey600, fontSize: 12),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: AppTheme.grey200);
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey400,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => item),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.grey800),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? AppTheme.grey800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.grey400,
                ),
          ],
        ),
      ),
    );
  }
}
