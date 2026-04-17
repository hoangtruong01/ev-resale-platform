import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/vehicle_service.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

final vehicleListProvider = FutureProvider<VehicleListResponse>((ref) {
  return ref.read(vehicleServiceProvider).getVehicles();
});

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xe điện'),
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm xe điện...',
                prefixIcon: Icon(Icons.search, color: AppTheme.grey400),
              ),
              onSubmitted: (v) {
                ref.invalidate(vehicleListProvider);
              },
            ),
          ),
          Expanded(
            child: vehiclesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (data) {
                if (data.data.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.electric_car_rounded,
                          size: 64,
                          color: AppTheme.grey200,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy xe nào',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _VehicleCard(vehicle: data.data[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vehicles/${vehicle.id}'),
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AppNetworkImage(
                url: vehicle.thumbnailUrl,
                height: 180,
                width: double.infinity,
                placeholderIcon: Icons.electric_car_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: vehicle.isAvailable
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.grey100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          vehicle.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: vehicle.isAvailable
                                ? AppTheme.success
                                : AppTheme.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car_outlined,
                        size: 14,
                        color: AppTheme.grey400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.brand} • ${vehicle.year}',
                        style: const TextStyle(
                          color: AppTheme.grey600,
                          fontSize: 13,
                        ),
                      ),
                      if (vehicle.mileage != null) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppTheme.grey400),
                        ),
                        Text(
                          '${AppUtils.formatNumber(vehicle.mileage)} km',
                          style: const TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.grey400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vehicle.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.grey400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppUtils.formatCurrency(vehicle.price),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      if (vehicle.hasWarranty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                size: 12,
                                color: AppTheme.info,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Bảo hành',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
