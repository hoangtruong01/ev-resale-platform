import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/session_state_provider.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Bảng điều khiển mở rộng'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horizontal_circle_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Chuyển về User Mode',
            onPressed: () {
              ref.read(adminModeProvider.notifier).state = false;
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DANH MỤC QUẢN TRỊ VIÊN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.grey500,
              ),
            ),
            const SizedBox(height: 12),

            // Navigation menu items
            _buildMenuCard(context, [
              _buildMenuItem(
                context,
                icon: Icons.people_alt_rounded,
                color: AppTheme.primaryGreen,
                title: 'Quản Lý Người Dùng',
                subtitle: 'Phân quyền, khóa/mở khóa tài khoản & phê duyệt eKYC',
                onTap: () => context.push('/admin/settings?tab=1'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.description_rounded,
                color: AppTheme.info,
                title: 'Hợp Đồng & Cọc',
                subtitle: 'Xem giao kèo thương mại, tiền cọc sàn đấu giá',
                onTap: () => context.push('/admin/contracts'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.percent_rounded,
                color: Colors.purple,
                title: 'Cấu Hình Phí',
                subtitle: 'Biểu phí giao dịch, nạp/rút và hoa hồng sàn',
                onTap: () => context.push('/admin/fees'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.shield_rounded,
                color: Colors.teal,
                title: 'Quyền Moderator',
                subtitle: 'Thiết lập giới hạn quyền điều phối viên',
                onTap: () => context.push('/admin/permissions'),
              ),
              _buildMenuItem(
                context,
                icon: Icons.tune_rounded,
                color: AppTheme.accentOrange,
                title: 'Cài Đặt Hệ Thống',
                subtitle: 'Thông số bước giá, bước đấu và tự động hóa',
                onTap: () => context.push('/admin/settings?tab=0'),
              ),
            ]),

            const SizedBox(height: 24),
            
            // Simple operational actions
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                ),
                title: Text(
                  'Đăng xuất hệ thống',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.grey900,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.grey400, size: 20),
                onTap: () async {
                  ref.read(adminModeProvider.notifier).state = false;
                  context.go('/auth/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isDark ? Colors.white : AppTheme.grey900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: AppTheme.grey500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.grey400, size: 20),
    );
  }
}
