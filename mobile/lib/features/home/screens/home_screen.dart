import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

import '../../../services/battery_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';

import '../widgets/home_widgets.dart';

final homeBatteriesProvider = FutureProvider<BatteryListResponse>((ref) {
  return ref.read(batteryServiceProvider).getBatteries(limit: 10);
});

final homeVehiclesProvider = FutureProvider<VehicleListResponse>((ref) {
  return ref.read(vehicleServiceProvider).getVehicles(limit: 10);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _activeTab = 0;
  final List<String> _tabs = ['Dành cho bạn', 'Gần bạn', 'Mới nhất', 'Video'];

  @override
  Widget build(BuildContext context) {
    final batteries = ref.watch(homeBatteriesProvider);
    final vehicles = ref.watch(homeVehiclesProvider);

    // Merge batteries + vehicles into a unified product list
    final List<_ProductItem> allProducts = [];

    batteries.whenData((data) {
      for (final b in data.data) {
        allProducts.add(_ProductItem(
          id: b.id,
          title: b.name,
          price: b.price,
          imageUrl: b.thumbnailUrl,
          sellerName: b.seller?.displayName,
          location: b.location,
          createdAt: b.createdAt,
          type: 'battery',
          icon: Icons.battery_charging_full_rounded,
        ));
      }
    });

    vehicles.whenData((data) {
      for (final v in data.data) {
        allProducts.add(_ProductItem(
          id: v.id,
          title: v.name,
          price: v.price,
          imageUrl: v.thumbnailUrl,
          sellerName: v.seller?.displayName,
          location: v.location,
          createdAt: v.createdAt,
          type: 'vehicle',
          icon: Icons.electric_car_rounded,
        ));
      }
    });

    // Sort by newest
    allProducts.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt) ?? DateTime(2020);
      final bDate = DateTime.tryParse(b.createdAt) ?? DateTime(2020);
      return bDate.compareTo(aDate);
    });

    final isLoading = batteries.isLoading || vehicles.isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.grey100,
        body: RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () async {
            ref.invalidate(homeBatteriesProvider);
            ref.invalidate(homeVehiclesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header (status bar safe area included)
              SliverToBoxAdapter(child: _buildHeader(context)),

              // 2. Categories
              SliverToBoxAdapter(child: _buildCategories(context)),

              // 2.5. Sell Banner
              SliverToBoxAdapter(child: _buildSellBanner(context)),

              // 3. Filter tabs
              SliverToBoxAdapter(child: _buildFilterTabs()),

              // 4. Product grid
              if (isLoading)
                _buildSkeletonGrid()
              else if (allProducts.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: AppTheme.grey300),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có sản phẩm nào',
                            style: TextStyle(
                              color: AppTheme.grey400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _buildProductGrid(allProducts),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryGreen,
          ],
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
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          // Search bar
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/batteries'),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: AppTheme.grey400, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tìm sản phẩm...',
                        style: TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 14,
                        ),
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
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: Colors.white, size: 20),
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
                  const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 20),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          HomeCategoryItem(
            icon: Icons.battery_charging_full_rounded,
            label: 'Pin xe điện',
            color: AppTheme.primaryGreen,
            onTap: () => context.go('/batteries'),
          ),
          HomeCategoryItem(
            icon: Icons.electric_moped_rounded,
            label: 'Xe điện',
            color: AppTheme.accentOrange,
            onTap: () => context.go('/vehicles'),
          ),
          HomeCategoryItem(
            icon: Icons.extension_rounded,
            label: 'Phụ kiện',
            color: AppTheme.info,
            onTap: () => context.go('/accessories'),
          ),
          HomeCategoryItem(
            icon: Icons.gavel_rounded,
            label: 'Đấu giá',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/auctions'),
          ),
        ],
      ),
    );
  }

  // ─── FILTER TABS ───
  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                return FilterTab(
                  label: _tabs[index],
                  isActive: _activeTab == index,
                  onTap: () => setState(() => _activeTab = index),
                );
              }),
            ),
          ),
          Container(height: 1, color: AppTheme.grey200),
        ],
      ),
    );
  }

  // ─── PRODUCT GRID ───
  SliverPadding _buildProductGrid(List<_ProductItem> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = products[index];
            return ProductGridCard(
              imageUrl: item.imageUrl,
              title: item.title,
              price: item.price,
              sellerName: item.sellerName,
              location: item.location,
              timeAgo: formatTimeAgo(item.createdAt),
              placeholderIcon: item.icon,
              onTap: () {
                if (item.type == 'battery') {
                  context.push('/batteries/${item.id}');
                } else {
                  context.push('/vehicles/${item.id}');
                }
              },
            );
          },
          childCount: products.length,
        ),
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
                const Text(
                  'Bạn muốn bán sản phẩm?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đăng bán pin, xe điện hoặc phụ kiện của bạn dễ dàng với sự hỗ trợ của AI!',
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
            onPressed: () => _showSellSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 16),
                SizedBox(width: 4),
                Text(
                  'Đăng bán',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSellSheet(BuildContext context) {
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
            const Text(
              'Đăng bán sản phẩm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _SellOption(
              icon: Icons.battery_charging_full_rounded,
              title: 'Đăng bán Pin điện',
              subtitle: 'Pin Lithium, NiMH, ...',
              color: AppTheme.primaryGreen,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/battery');
              },
            ),
            const SizedBox(height: 12),
            _SellOption(
              icon: Icons.electric_car_rounded,
              title: 'Đăng bán Xe điện',
              subtitle: 'Xe đạp điện, xe máy điện, ô tô điện',
              color: AppTheme.accentOrange,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/vehicle');
              },
            ),
            const SizedBox(height: 12),
            _SellOption(
              icon: Icons.extension_outlined,
              title: 'Đăng bán Phụ kiện',
              subtitle: 'Sạc, lốp, nội thất, điện tử',
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
