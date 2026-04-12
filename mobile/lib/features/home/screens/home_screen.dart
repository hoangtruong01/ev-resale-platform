import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/battery_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

// Providers
final homeBatteriesProvider = FutureProvider<BatteryListResponse>((ref) {
  return ref.read(batteryServiceProvider).getBatteries(limit: 6);
});

final homeVehiclesProvider = FutureProvider<VehicleListResponse>((ref) {
  return ref.read(vehicleServiceProvider).getVehicles(limit: 6);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final batteries = ref.watch(homeBatteriesProvider);
    final vehicles = ref.watch(homeVehiclesProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () async {
          ref.invalidate(homeBatteriesProvider);
          ref.invalidate(homeVehiclesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xin chào, ${user?.displayName.split(' ').last ?? 'bạn'}! 👋',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tìm kiếm pin xe điện hôm nay',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification bell
                              IconButton(
                                onPressed: () =>
                                    context.push('/notifications'),
                                icon: const Icon(Icons.notifications_outlined,
                                    color: Colors.white, size: 26),
                              ),
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: user?.avatar != null
                                    ? ClipOval(
                                        child: AppNetworkImage(
                                            url: user!.avatar!, width: 40, height: 40))
                                    : Text(
                                        (user?.displayName.isNotEmpty == true)
                                            ? user!.displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          GestureDetector(
                            onTap: () => context.push('/batteries'),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 16),
                                  Icon(Icons.search, color: AppTheme.grey400),
                                  SizedBox(width: 10),
                                  Text(
                                    'Tìm kiếm pin, xe điện...',
                                    style: TextStyle(
                                        color: AppTheme.grey400, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Danh mục',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CategoryCard(
                          icon: Icons.battery_charging_full_rounded,
                          label: 'Pin điện',
                          color: AppTheme.primaryGreen,
                          onTap: () => context.go('/batteries'),
                        ),
                        _CategoryCard(
                          icon: Icons.electric_car_rounded,
                          label: 'Xe điện',
                          color: AppTheme.accentOrange,
                          onTap: () => context.go('/vehicles'),
                        ),
                        _CategoryCard(
                          icon: Icons.gavel_rounded,
                          label: 'Đấu giá',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.go('/auctions'),
                        ),
                        _CategoryCard(
                          icon: Icons.message_outlined,
                          label: 'Tin nhắn',
                          color: AppTheme.info,
                          onTap: () => context.go('/chat'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentOrange.withValues(alpha: 0.9),
                      AppTheme.accentYellow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🔋 Pin chất lượng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Phí giao dịch thấp chỉ từ 1%',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.battery_charging_full_rounded,
                          size: 60, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Batteries
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 0, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pin điện nổi bật',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.go('/batteries'),
                      child: const Text('Xem tất cả',
                          style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),

            // Battery horizontal list
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: batteries.when(
                  loading: () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => const _BatteryCardSkeleton(),
                  ),
                  error: (e, _) => Center(child: Text('Lỗi: $e')),
                  data: (data) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.data.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        BatteryCard(battery: data.data[i]),
                  ),
                ),
              ),
            ),

            // Featured Vehicles
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 0, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Xe điện nổi bật',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.go('/vehicles'),
                      child: const Text('Xem tất cả',
                          style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),

            // Vehicle list
            vehicles.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Lỗi: $e')),
              ),
              data: (data) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => VehicleListTile(vehicle: data.data[i]),
                  childCount: data.data.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class BatteryCard extends StatelessWidget {
  final BatteryModel battery;
  const BatteryCard({super.key, required this.battery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/batteries/${battery.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AppNetworkImage(
                url: battery.thumbnailUrl,
                height: 120,
                width: double.infinity,
                placeholderIcon: Icons.battery_charging_full_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    battery.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${battery.condition}%',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${battery.capacity}kWh',
                        style: const TextStyle(
                            color: AppTheme.grey600, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppUtils.formatCurrency(battery.price),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleListTile extends StatelessWidget {
  final VehicleModel vehicle;
  const VehicleListTile({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vehicles/${vehicle.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: AppNetworkImage(
                url: vehicle.thumbnailUrl,
                width: 110,
                height: 90,
                placeholderIcon: Icons.electric_car_rounded,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.brand} • ${vehicle.year}',
                      style: const TextStyle(
                          color: AppTheme.grey600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.grey400),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            vehicle.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.grey400, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppUtils.formatCurrency(vehicle.price),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryCardSkeleton extends StatelessWidget {
  const _BatteryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
