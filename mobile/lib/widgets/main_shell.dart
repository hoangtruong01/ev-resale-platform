import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evn_battery_trading/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'floating_ai_button.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String? location;
  const MainShell({super.key, required this.child, this.location});

  int _getSelectedIndex(String currentLoc) {
    if (currentLoc.startsWith('/auctions')) return 1;
    if (currentLoc.startsWith('/sell')) return 2;
    if (currentLoc.startsWith('/support') || currentLoc.startsWith('/chat')) {
      return 3;
    }
    if (currentLoc.startsWith('/profile')) return 4;
    return 0; // home
  }

  void _showSellSheet(BuildContext context, AppLocalizations l10n) {
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
              l10n.sellProductTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _SellOption(
              icon: Icons.battery_charging_full_rounded,
              title: l10n.sellBatteryOption,
              subtitle: l10n.sellBatterySubtitle,
              color: AppTheme.primaryGreen,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/battery');
              },
            ),
            const SizedBox(height: 12),
            _SellOption(
              icon: Icons.electric_car_rounded,
              title: l10n.sellVehicleOption,
              subtitle: l10n.sellVehicleSubtitle,
              color: AppTheme.accentOrange,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/vehicle');
              },
            ),
            const SizedBox(height: 12),
            _SellOption(
              icon: Icons.extension_outlined,
              title: l10n.sellAccessoryOption,
              subtitle: l10n.sellAccessorySubtitle,
              color: AppTheme.info,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/accessory');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeLocation = location ?? GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(activeLocation);

    // Show FAB only on Home page and product detail pages (vehicles, batteries, accessories)
    final showFab = activeLocation == '/' ||
        activeLocation.startsWith('/vehicles/') ||
        activeLocation.startsWith('/batteries/') ||
        activeLocation.startsWith('/accessories/');

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (showFab)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 76,
              child: const FloatingAiButton(),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkSurface
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l10n.navHome,
                  isSelected: selectedIndex == 0,
                  badgeCount: 0,
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.gavel_outlined,
                  activeIcon: Icons.gavel_rounded,
                  label: l10n.navAuctions,
                  isSelected: selectedIndex == 1,
                  badgeCount: 0,
                  onTap: () => context.go('/auctions'),
                ),
                // Custom Elevated Center Button for "Đăng tin"
                GestureDetector(
                  onTap: () => _showSellSheet(context, l10n),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -6),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryGreen, Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          l10n.navSell,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selectedIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                            color: selectedIndex == 2 ? AppTheme.primaryGreen : AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: l10n.navChat,
                  isSelected: selectedIndex == 3,
                  badgeCount: 0,
                  onTap: () => context.go('/chat'),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: l10n.navProfile,
                  isSelected: selectedIndex == 4,
                  badgeCount: 0,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.badgeCount,
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
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
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

class _SellOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SellOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.grey600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppTheme.grey400),
          ],
        ),
      ),
    );
  }
}
