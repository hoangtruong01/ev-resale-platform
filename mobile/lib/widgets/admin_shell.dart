import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin/listings') return 1;
    if (location == '/admin/transactions') return 2;
    if (location == '/admin/support') return 3;
    if (location == '/admin/settings') return 4;
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _AdminBottomNavBar(
        selectedIndex: selectedIndex,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/listings');
        break;
      case 2:
        context.go('/admin/transactions');
        break;
      case 3:
        context.go('/admin/support');
        break;
      case 4:
        context.go('/admin/settings');
        break;
    }
  }
}

class _AdminBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AdminBottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppTheme.grey200.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AdminNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Tổng quan',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _AdminNavItem(
                icon: Icons.fact_check_outlined,
                activeIcon: Icons.fact_check_rounded,
                label: 'Duyệt bài',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _AdminNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Giao dịch',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _AdminNavItem(
                icon: Icons.support_agent_outlined,
                activeIcon: Icons.support_agent_rounded,
                label: 'Hỗ trợ',
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
              _AdminNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Cài đặt',
                isSelected: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppTheme.primaryGreen : AppTheme.grey400,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
