import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/vehicle_service.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';

final vehicleDetailProvider =
    FutureProvider.family<VehicleModel, String>((ref, id) {
  return ref.read(vehicleServiceProvider).getVehicleById(id);
});

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  final _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(widget.id));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: vehicleAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (vehicle) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Colors.black,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemCount:
                          vehicle.images.isEmpty ? 1 : vehicle.images.length,
                      itemBuilder: (_, i) => AppNetworkImage(
                        url: vehicle.images.isEmpty
                            ? null
                            : vehicle.images[i],
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.electric_car_rounded,
                      ),
                    ),
                    if (vehicle.images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            vehicle.images.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: i == _currentImageIndex ? 20 : 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: i == _currentImageIndex
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.brand,
                            style: const TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: vehicle.isAvailable
                                ? AppTheme.success.withOpacity(0.1)
                                : AppTheme.grey100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.statusLabel,
                            style: TextStyle(
                              color: vehicle.isAvailable
                                  ? AppTheme.success
                                  : AppTheme.grey600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppUtils.formatCurrency(vehicle.price),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Thông số xe',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _SpecGrid(vehicle: vehicle),
                    if (vehicle.description != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Mô tả',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        vehicle.description!,
                        style: const TextStyle(
                          color: AppTheme.grey600,
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: vehicleAsync.value == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Nhắn tin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vehicleAsync.value!.isAvailable ? () {} : null,
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Mua ngay'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  final VehicleModel vehicle;
  const _SpecGrid({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final specs = [
      {'icon': Icons.calendar_today_outlined, 'label': 'Năm SX', 'value': '${vehicle.year}'},
      {'icon': Icons.speed_outlined, 'label': 'Số km', 'value': vehicle.mileage != null ? '${AppUtils.formatNumber(vehicle.mileage)} km' : 'N/A'},
      {'icon': Icons.settings_outlined, 'label': 'Hộp số', 'value': vehicle.transmission ?? 'N/A'},
      {'icon': Icons.palette_outlined, 'label': 'Màu sắc', 'value': vehicle.color ?? 'N/A'},
      {'icon': Icons.airline_seat_recline_normal_outlined, 'label': 'Số ghế', 'value': vehicle.seatCount?.toString() ?? 'N/A'},
      {'icon': Icons.location_on_outlined, 'label': 'Khu vực', 'value': vehicle.location},
      {'icon': Icons.verified_outlined, 'label': 'Bảo hành', 'value': vehicle.hasWarranty == true ? 'Có' : 'Không'},
      {'icon': Icons.info_outline, 'label': 'Tình trạng', 'value': vehicle.condition},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: specs.length,
      itemBuilder: (_, i) {
        final spec = specs[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(spec['icon'] as IconData,
                  size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spec['label'] as String,
                      style: const TextStyle(
                          color: AppTheme.grey400,
                          fontSize: 11),
                    ),
                    Text(
                      spec['value'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
