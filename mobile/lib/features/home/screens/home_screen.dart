import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evn_battery_trading/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';

import '../../../services/battery_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../services/dashboard_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';

import '../widgets/home_widgets.dart';

final homeBatteriesProvider = FutureProvider.autoDispose<BatteryListResponse>((ref) {
  return ref.read(batteryServiceProvider).getBatteries(limit: 10);
});

final homeVehiclesProvider = FutureProvider.autoDispose<VehicleListResponse>((ref) {
  return ref.read(vehicleServiceProvider).getVehicles(limit: 10);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _activeTab = 0;

  List<String> _getTabs(AppLocalizations l10n) => [
        l10n.homeTabForYou,
        l10n.homeTabNearYou,
        l10n.homeTabLatest,
        l10n.homeTabVideo,
      ];

  @override
  Widget build(BuildContext context) {
    try {
      final batteries = ref.watch(homeBatteriesProvider);
      final vehicles = ref.watch(homeVehiclesProvider);
      final favoritesAsync = ref.watch(dashboardFavoritesProvider);

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              ref.invalidate(homeBatteriesProvider);
              ref.invalidate(homeVehiclesProvider);
              ref.invalidate(dashboardFavoritesProvider);
            },
            child: batteries.when(
              loading: () => _buildLoadingContent(context),
              error: (err, stack) {
                if (kDebugMode) {
                  debugPrint('[HomeScreen] batteries error: $err');
                  debugPrint('[HomeScreen] stack: $stack');
                }
                return _buildErrorContent(context, parseApiError(err));
              },
              data: (batteryData) {
                return vehicles.when(
                  loading: () => _buildLoadingContent(context),
                  error: (err, stack) {
                    if (kDebugMode) {
                      debugPrint('[HomeScreen] vehicles error: $err');
                      debugPrint('[HomeScreen] stack: $stack');
                    }
                    return _buildErrorContent(context, parseApiError(err));
                  },
                  data: (vehicleData) {
                    return _buildMainContent(context, batteryData, vehicleData, favoritesAsync);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e, stack) {
      // Prevent white screen by catching any unexpected build errors
      if (kDebugMode) {
        debugPrint('[HomeScreen] CRITICAL BUILD ERROR: $e');
        debugPrint('[HomeScreen] stack: $stack');
      }
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi khi tải trang chủ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.grey900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode ? e.toString() : 'Vui lòng thử lại sau',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : AppTheme.grey500,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(homeBatteriesProvider);
                    ref.invalidate(homeVehiclesProvider);
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingContent(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildCategories(context)),
        SliverToBoxAdapter(child: _buildSellBanner(context)),
        SliverToBoxAdapter(child: _buildFilterTabs()),
        _buildSkeletonGrid(),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, String message) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildCategories(context)),
        SliverToBoxAdapter(child: _buildSellBanner(context)),
        SliverToBoxAdapter(child: _buildFilterTabs()),
        _buildErrorState(message),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    BatteryListResponse batteryData,
    VehicleListResponse vehicleData,
    AsyncValue<List<DashboardFavoriteData>> favoritesAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Merge and sort products
    final List<_ProductItem> allProducts = [];

    for (final b in batteryData.data) {
      allProducts.add(
        _ProductItem(
          id: b.id,
          title: b.name,
          price: b.price,
          imageUrl: b.thumbnailUrl,
          sellerName: b.seller?.displayName,
          location: b.location,
          createdAt: b.createdAt,
          type: 'battery',
          icon: Icons.battery_charging_full_rounded,
        ),
      );
    }

    for (final v in vehicleData.data) {
      allProducts.add(
        _ProductItem(
          id: v.id,
          title: v.name,
          price: v.price,
          imageUrl: v.thumbnailUrl,
          sellerName: v.seller?.displayName,
          location: v.location,
          createdAt: v.createdAt,
          type: 'vehicle',
          icon: Icons.electric_car_rounded,
        ),
      );
    }

    if (_activeTab == 1) {
      // Gần bạn (Near You)
      allProducts.sort((a, b) {
        final aNear = a.location.toLowerCase().contains('hà nội') || a.location.toLowerCase().contains('hanoi');
        final bNear = b.location.toLowerCase().contains('hà nội') || b.location.toLowerCase().contains('hanoi');
        if (aNear && !bNear) return -1;
        if (!aNear && bNear) return 1;
        final aDate = DateTime.tryParse(a.createdAt) ?? DateTime(2020);
        final bDate = DateTime.tryParse(b.createdAt) ?? DateTime(2020);
        return bDate.compareTo(aDate);
      });
    } else if (_activeTab == 2) {
      // Mới nhất (Latest)
      allProducts.sort((a, b) {
        final aDate = DateTime.tryParse(a.createdAt) ?? DateTime(2020);
        final bDate = DateTime.tryParse(b.createdAt) ?? DateTime(2020);
        return bDate.compareTo(aDate);
      });
    } else if (_activeTab == 3) {
      // Video
      final videoProducts = allProducts.where((p) => p.title.toLowerCase().contains('vinfast') || p.title.toLowerCase().contains('tesla')).toList();
      allProducts.clear();
      allProducts.addAll(videoProducts);
    } else {
      // Dành cho bạn (For You)
      allProducts.sort((a, b) => a.price.compareTo(b.price));
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildCategories(context)),
        SliverToBoxAdapter(child: _buildSellBanner(context)),
        SliverToBoxAdapter(child: _buildFilterTabs()),
        if (allProducts.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppTheme.grey300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.homeNoProducts,
                      style: const TextStyle(color: AppTheme.grey400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          _buildProductGrid(allProducts, favoritesAsync),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorServerConnection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppTheme.grey600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppTheme.grey200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: AppTheme.grey500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'URL: ${AppConstants.baseUrl}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(homeBatteriesProvider);
                ref.invalidate(homeVehiclesProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                l10n.btnRetry,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
        ),
      ),
      child: Row(
        children: [
          // Menu icon
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Search bar
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppTheme.grey400,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.searchPlaceholder,
                        style: const TextStyle(color: AppTheme.grey400, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Favorite icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Consumer(
                    builder: (context, ref, _) {
                      final favoritesAsync = ref.watch(dashboardFavoritesProvider);
                      return DashboardFavoritesScreen(
                        favoritesAsync: favoritesAsync,
                      );
                    },
                  ),
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Notification icon
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORIES ───
  Widget _buildCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          HomeCategoryItem(
            icon: Icons.battery_charging_full_rounded,
            label: l10n.categoryBattery,
            color: AppTheme.primaryGreen,
            onTap: () => context.push('/batteries'),
          ),
          HomeCategoryItem(
            icon: Icons.electric_moped_rounded,
            label: l10n.categoryVehicle,
            color: AppTheme.accentOrange,
            onTap: () => context.push('/vehicles'),
          ),
          HomeCategoryItem(
            icon: Icons.extension_rounded,
            label: l10n.categoryAccessory,
            color: AppTheme.info,
            onTap: () => context.push('/accessories'),
          ),
          HomeCategoryItem(
            icon: Icons.gavel_rounded,
            label: l10n.categoryAuction,
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/auctions'),
          ),
        ],
      ),
    );
  }

  // ─── FILTER TABS ───
  Widget _buildFilterTabs() {
    final l10n = AppLocalizations.of(context)!;
    final tabs = _getTabs(l10n);
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: List.generate(tabs.length, (index) {
                return FilterTab(
                  label: tabs[index],
                  isActive: _activeTab == index,
                  onTap: () => setState(() => _activeTab = index),
                );
              }),
            ),
          ),
          Container(
            height: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : AppTheme.grey200,
          ),
        ],
      ),
    );
  }

  // ─── PRODUCT GRID ───
  SliverPadding _buildProductGrid(
    List<_ProductItem> products,
    AsyncValue<List<DashboardFavoriteData>> favoritesAsync,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = products[index];
          final isFavorite = favoritesAsync.maybeWhen(
            data: (list) => list.any((fav) => fav.sourceId == item.id),
            orElse: () => false,
          );

          return ProductGridCard(
            imageUrl: item.imageUrl,
            title: item.title,
            price: item.price,
            sellerName: item.sellerName,
            location: item.location,
            timeAgo: formatTimeAgo(item.createdAt),
            placeholderIcon: item.icon,
            isFavorite: isFavorite,
            onFavoriteTap: () async {
              try {
                if (isFavorite) {
                  final favItem = favoritesAsync.value?.firstWhere(
                    (fav) => fav.sourceId == item.id,
                  );
                  if (favItem != null) {
                    await ref
                        .read(dashboardServiceProvider)
                        .removeFavorite(favItem.id);
                  }
                } else {
                  if (item.type == 'battery') {
                    await ref
                        .read(dashboardServiceProvider)
                        .addFavorite(batteryId: item.id);
                  } else {
                    await ref
                        .read(dashboardServiceProvider)
                        .addFavorite(vehicleId: item.id);
                  }
                }
                ref.invalidate(dashboardFavoritesProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            onTap: () {
              if (item.type == 'battery') {
                context.push('/batteries/${item.id}');
              } else {
                context.push('/vehicles/${item.id}');
              }
            },
          );
        }, childCount: products.length),
      ),
    );
  }

  // ─── SKELETON GRID ───
  SliverPadding _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ProductCardSkeleton(),
          childCount: 6,
        ),
      ),
    );
  }

  // ─── SELL BANNER ───
  Widget _buildSellBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeSellBannerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeSellBannerSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showSellSheet(context, l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryGreen,
              elevation: 0,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                  l10n.btnPostSell,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.grey600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal product item ───
class _ProductItem {
  final String id;
  final String title;
  final double price;
  final String? imageUrl;
  final String? sellerName;
  final String location;
  final String createdAt;
  final String type;
  final IconData icon;

  const _ProductItem({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
    this.sellerName,
    required this.location,
    required this.createdAt,
    required this.type,
    required this.icon,
  });
}
