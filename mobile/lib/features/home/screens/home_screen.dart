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
import '../../../services/accessory_service.dart';
import '../../../services/dashboard_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/accessory_model.dart';

import '../widgets/home_widgets.dart';

class HomeFilterState {
  final String category; // 'all' | 'battery' | 'vehicle' | 'accessory'
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? batteryType;
  final int? minCondition;
  final String? brand;
  final int? minYear;
  final int? maxYear;
  final String? sortBy;
  final String? sortOrder;

  const HomeFilterState({
    this.category = 'all',
    this.minPrice,
    this.maxPrice,
    this.location,
    this.batteryType,
    this.minCondition,
    this.brand,
    this.minYear,
    this.maxYear,
    this.sortBy,
    this.sortOrder,
  });

  bool get isActive {
    return category != 'all' ||
        minPrice != null ||
        maxPrice != null ||
        (location != null && location!.isNotEmpty) ||
        batteryType != null ||
        minCondition != null ||
        (brand != null && brand!.isNotEmpty) ||
        minYear != null ||
        maxYear != null ||
        sortBy != null ||
        sortOrder != null;
  }

  HomeFilterState copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? batteryType,
    int? minCondition,
    String? brand,
    int? minYear,
    int? maxYear,
    String? sortBy,
    String? sortOrder,
  }) {
    return HomeFilterState(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      batteryType: batteryType ?? this.batteryType,
      minCondition: minCondition ?? this.minCondition,
      brand: brand ?? this.brand,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  HomeFilterState clear() {
    return const HomeFilterState();
  }
}

final homeFilterProvider = StateProvider<HomeFilterState>((ref) => const HomeFilterState());

class HomeScreenData {
  final BatteryListResponse batteries;
  final VehicleListResponse vehicles;
  final AccessoryListResponse accessories;

  HomeScreenData({
    required this.batteries,
    required this.vehicles,
    required this.accessories,
  });
}

final homeScreenDataProvider = FutureProvider.autoDispose<HomeScreenData>((ref) async {
  final filter = ref.watch(homeFilterProvider);

  final batteriesFuture = (filter.category == 'all' || filter.category == 'battery')
      ? ref.read(batteryServiceProvider).getBatteries(
            limit: 10,
            minPrice: filter.minPrice,
            maxPrice: filter.maxPrice,
            type: filter.batteryType,
            minCondition: filter.minCondition,
            location: filter.location,
            sortBy: filter.sortBy,
            sortOrder: filter.sortOrder,
          )
      : Future.value(const BatteryListResponse(data: [], total: 0, page: 1, limit: 10));

  final vehiclesFuture = (filter.category == 'all' || filter.category == 'vehicle')
      ? ref.read(vehicleServiceProvider).getVehicles(
            limit: 10,
            minPrice: filter.minPrice,
            maxPrice: filter.maxPrice,
            brand: filter.brand,
            minYear: filter.minYear,
            maxYear: filter.maxYear,
            location: filter.location,
            sortBy: filter.sortBy,
            sortOrder: filter.sortOrder,
          )
      : Future.value(const VehicleListResponse(data: [], total: 0, page: 1, limit: 10));

  final accessoriesFuture = (filter.category == 'all' || filter.category == 'accessory')
      ? ref.read(accessoryServiceProvider).getAccessories(
            limit: 10,
            minPrice: filter.minPrice,
            maxPrice: filter.maxPrice,
            location: filter.location,
            sortBy: filter.sortBy,
            sortOrder: filter.sortOrder,
          )
      : Future.value(const AccessoryListResponse(data: [], total: 0, page: 1, limit: 10));

  final results = await Future.wait([
    batteriesFuture,
    vehiclesFuture,
    accessoriesFuture,
  ]);

  return HomeScreenData(
    batteries: results[0] as BatteryListResponse,
    vehicles: results[1] as VehicleListResponse,
    accessories: results[2] as AccessoryListResponse,
  );
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
      final homeDataAsync = ref.watch(homeScreenDataProvider);
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
              ref.invalidate(homeScreenDataProvider);
              ref.invalidate(dashboardFavoritesProvider);
            },
            child: homeDataAsync.when(
              loading: () => _buildLoadingContent(context),
              error: (err, stack) {
                if (kDebugMode) {
                  debugPrint('[HomeScreen] error: $err');
                  debugPrint('[HomeScreen] stack: $stack');
                }
                return _buildErrorContent(context, parseApiError(err));
              },
              data: (homeData) {
                return _buildMainContent(context, homeData, favoritesAsync);
              },
            ),
          ),
        ),
      );
    } catch (e, stack) {
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
                    ref.invalidate(homeScreenDataProvider);
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
    HomeScreenData homeData,
    AsyncValue<List<DashboardFavoriteData>> favoritesAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Merge and sort products
    final List<_ProductItem> allProducts = [];

    for (final b in homeData.batteries.data) {
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

    for (final v in homeData.vehicles.data) {
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

    for (final a in homeData.accessories.data) {
      allProducts.add(
        _ProductItem(
          id: a.id,
          title: a.name,
          price: a.price,
          imageUrl: a.thumbnailUrl,
          sellerName: a.seller?.displayName,
          location: a.location,
          createdAt: a.createdAt,
          type: 'accessory',
          icon: Icons.extension_rounded,
        ),
      );
    }

    if (_activeTab == 1) {
      // Gần bạn (Near You)
      allProducts.sort((a, b) {
        final aNear = a.location.toLowerCase().contains('hà nội') || a.location.toLowerCase().contains('hanoi') ||
                      a.location.toLowerCase().contains('hồ chí minh') || a.location.toLowerCase().contains('ho chi minh') || a.location.toLowerCase().contains('hcm');
        final bNear = b.location.toLowerCase().contains('hà nội') || b.location.toLowerCase().contains('hanoi') ||
                      b.location.toLowerCase().contains('hồ chí minh') || b.location.toLowerCase().contains('ho chi minh') || b.location.toLowerCase().contains('hcm');
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
      final videoProducts = allProducts.where((p) => p.title.toLowerCase().contains('vinfast') || p.title.toLowerCase().contains('tesla') || p.title.toLowerCase().contains('pin')).toList();
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
                ref.invalidate(homeScreenDataProvider);
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
          // Filter Icon with Badge Dot
          Consumer(
            builder: (context, ref, _) {
              final filter = ref.watch(homeFilterProvider);
              final isFilterActive = filter.isActive;
              return GestureDetector(
                onTap: () => _showFilterSheet(context, ref),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    if (isFilterActive)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
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
            onTap: () {
              ref.read(homeFilterProvider.notifier).state = const HomeFilterState(category: 'battery');
            },
          ),
          HomeCategoryItem(
            icon: Icons.electric_moped_rounded,
            label: l10n.categoryVehicle,
            color: AppTheme.accentOrange,
            onTap: () {
              ref.read(homeFilterProvider.notifier).state = const HomeFilterState(category: 'vehicle');
            },
          ),
          HomeCategoryItem(
            icon: Icons.extension_rounded,
            label: l10n.categoryAccessory,
            color: AppTheme.info,
            onTap: () {
              ref.read(homeFilterProvider.notifier).state = const HomeFilterState(category: 'accessory');
            },
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
              if (item.type == 'accessory') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng yêu thích chỉ khả dụng cho Xe điện và Pin điện.')),
                );
                return;
              }
              try {
                if (isFavorite) {
                  await ref
                      .read(dashboardFavoritesProvider.notifier)
                      .removeFavoriteBySourceId(item.id);
                } else {
                  final tempFav = DashboardFavoriteData(
                    id: 'temp_${item.id}',
                    title: item.title,
                    price: item.price,
                    thumbnail: item.imageUrl,
                    itemType: item.type == 'battery' ? 'BATTERY' : 'VEHICLE',
                    sourceId: item.id,
                    location: item.location,
                  );
                  if (item.type == 'battery') {
                    await ref
                        .read(dashboardFavoritesProvider.notifier)
                        .addFavorite(
                          batteryId: item.id,
                          tempFavorite: tempFav,
                        );
                  } else {
                    await ref
                        .read(dashboardFavoritesProvider.notifier)
                        .addFavorite(
                          vehicleId: item.id,
                          tempFavorite: tempFav,
                        );
                  }
                }
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
              } else if (item.type == 'vehicle') {
                context.push('/vehicles/${item.id}');
              } else {
                context.push('/accessories/${item.id}');
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

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HomeFilterSheet(),
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

class _HomeFilterSheet extends ConsumerStatefulWidget {
  const _HomeFilterSheet();

  @override
  ConsumerState<_HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends ConsumerState<_HomeFilterSheet> {
  late String _category;
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _minYearCtrl = TextEditingController();
  final _maxYearCtrl = TextEditingController();
  String? _batteryType;
  double _minCondition = 0.0;
  String? _sortBy;
  String? _sortOrder;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(homeFilterProvider);
    _category = filter.category;
    _minPriceCtrl.text = filter.minPrice != null ? filter.minPrice!.round().toString() : '';
    _maxPriceCtrl.text = filter.maxPrice != null ? filter.maxPrice!.round().toString() : '';
    _locationCtrl.text = filter.location ?? '';
    _brandCtrl.text = filter.brand ?? '';
    _minYearCtrl.text = filter.minYear != null ? filter.minYear!.toString() : '';
    _maxYearCtrl.text = filter.maxYear != null ? filter.maxYear!.toString() : '';
    _batteryType = filter.batteryType;
    _minCondition = (filter.minCondition ?? 0).toDouble();
    _sortBy = filter.sortBy;
    _sortOrder = filter.sortOrder;
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _locationCtrl.dispose();
    _brandCtrl.dispose();
    _minYearCtrl.dispose();
    _maxYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top > 0
            ? MediaQuery.of(context).padding.top + 8
            : 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppTheme.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark ? Colors.white : AppTheme.grey900,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bộ lọc nâng cao',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _category = 'all';
                      _minPriceCtrl.clear();
                      _maxPriceCtrl.clear();
                      _locationCtrl.clear();
                      _brandCtrl.clear();
                      _minYearCtrl.clear();
                      _maxYearCtrl.clear();
                      _batteryType = null;
                      _minCondition = 0.0;
                      _sortBy = null;
                      _sortOrder = null;
                    });
                  },
                  child: const Text(
                    'Thiết lập lại',
                    style: TextStyle(color: AppTheme.error),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            const Text(
              'Danh mục sản phẩm',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('all', 'Tất cả', Icons.all_inclusive_rounded),
                  const SizedBox(width: 8),
                  _buildCategoryChip('vehicle', 'Xe điện', Icons.electric_car_rounded),
                  const SizedBox(width: 8),
                  _buildCategoryChip('battery', 'Pin điện', Icons.battery_charging_full_rounded),
                  const SizedBox(width: 8),
                  _buildCategoryChip('accessory', 'Phụ kiện', Icons.extension_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Khoảng giá (VND)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _minPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Tối thiểu',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _maxPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Tối đa',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Khu vực',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppTheme.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Hà Nội, TP. HCM',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            if (_category == 'all' || _category == 'battery') ...[
              const SizedBox(height: 16),
              const Text(
                'Loại pin',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildBatteryTypeChip(null, 'Tất cả'),
                  _buildBatteryTypeChip('LITHIUM_ION', 'Li-ion'),
                  _buildBatteryTypeChip('LITHIUM_POLYMER', 'LiPo'),
                  _buildBatteryTypeChip('NICKEL_METAL_HYDRIDE', 'NiMH'),
                  _buildBatteryTypeChip('LEAD_ACID', 'Chì-Axit'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tình trạng pin tối thiểu (SOH): ${_minCondition.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Slider(
                value: _minCondition,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppTheme.primaryGreen,
                onChanged: (v) => setState(() => _minCondition = v),
              ),
            ],

            if (_category == 'all' || _category == 'vehicle') ...[
              const SizedBox(height: 16),
              const Text(
                'Hãng sản xuất (Xe điện)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : AppTheme.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: VinFast, Tesla',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đời xe (Năm sản xuất)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppTheme.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _minYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Từ năm',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppTheme.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _maxYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Đến năm',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Sắp xếp theo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSortChip(null, null, 'Mặc định'),
                _buildSortChip('createdAt', 'desc', 'Mới nhất'),
                _buildSortChip('price', 'asc', 'Giá: Thấp đến Cao'),
                _buildSortChip('price', 'desc', 'Giá: Cao đến Thấp'),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(homeFilterProvider.notifier).state = const HomeFilterState();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xóa bộ lọc'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final minPrice = double.tryParse(_minPriceCtrl.text);
                      final maxPrice = double.tryParse(_maxPriceCtrl.text);
                      final location = _locationCtrl.text.trim();
                      final brand = _brandCtrl.text.trim();
                      final minYear = int.tryParse(_minYearCtrl.text);
                      final maxYear = int.tryParse(_maxYearCtrl.text);

                      ref.read(homeFilterProvider.notifier).state = HomeFilterState(
                        category: _category,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        location: location.isEmpty ? null : location,
                        batteryType: _batteryType,
                        minCondition: _minCondition > 0 ? _minCondition.round() : null,
                        brand: brand.isEmpty ? null : brand,
                        minYear: minYear,
                        maxYear: maxYear,
                        sortBy: _sortBy,
                        sortOrder: _sortOrder,
                      );
                      
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String cat, String label, IconData icon) {
    final isSelected = _category == cat;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.grey700),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _category = cat);
        }
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.grey800),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildBatteryTypeChip(String? type, String label) {
    final isSelected = _batteryType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _batteryType = type);
        }
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.grey800),
      ),
    );
  }

  Widget _buildSortChip(String? field, String? order, String label) {
    final isSelected = _sortBy == field && _sortOrder == order;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = field;
            _sortOrder = order;
          });
        }
      },
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.grey800),
      ),
    );
  }
}
