import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
// import '../../../features/auth/providers/auth_provider.dart';
// import '../../../core/utils/app_utils.dart';
import '../../../widgets/app_network_image.dart';
import 'kyc_verification_screen.dart';
import '../../admin/screens/kyc_management_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

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
                            backgroundColor: Colors.white.withOpacity(0.2),
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
                                    color: AppTheme.primaryGreen, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: AppTheme.primaryGreen),
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
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppTheme.accentYellow),
                            const SizedBox(width: 4),
                            Text(
                              '${user!.rating!.toStringAsFixed(1)} (${user.totalRatings} đánh giá)',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                              label: 'Đang bán', value: '0'),
                        ),
                        _VertDivider(),
                        Expanded(
                          child: _StatItem(
                              label: 'Đã bán', value: '0'),
                        ),
                        _VertDivider(),
                        Expanded(
                          child: _StatItem(
                              label: 'Đã mua', value: '0'),
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
                        onTap: () {},
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (data) {
                                final status =
                                    data['kycStatus'] as String? ?? 'UNVERIFIED';
                                final (label, color) = switch (status) {
                                  'APPROVED' => ('Đã xác thực', AppTheme.success),
                                  'PENDING' => ('Đang xét duyệt', AppTheme.warning),
                                  'REJECTED' => ('Bị từ chối', AppTheme.error),
                                  _ => ('Chưa xác thực', AppTheme.grey400),
                                };
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
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
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Cài đặt thông báo',
                        onTap: () => context.push('/notifications'),
                      ),
                      _MenuItem(
                        icon: Icons.credit_card_outlined,
                        label: 'Phương thức thanh toán',
                        onTap: () {},
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
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Lịch sử giao dịch',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline,
                        label: 'Đã lưu',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.gavel_outlined,
                        label: 'Lịch sử đấu giá',
                        onTap: () {},
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
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.policy_outlined,
                        label: 'Điều khoản & Chính sách',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: 'Về ứng dụng',
                        onTap: () {},
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
                          onTap: () {},
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.error.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              color: AppTheme.error, size: 20),
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
            child: const Text('Huỷ',
                style: TextStyle(color: AppTheme.grey600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
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
        Text(label,
            style:
                const TextStyle(color: AppTheme.grey600, fontSize: 12)),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppTheme.grey200,
    );
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppTheme.grey400),
          ],
        ),
      ),
    );
  }
}
