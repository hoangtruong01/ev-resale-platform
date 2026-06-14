import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/accessory_model.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/accessory_service.dart';
import '../../../services/battery_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../widgets/app_network_image.dart';

final myVehiclesProvider = FutureProvider<VehicleListResponse>((ref) {
  return ref.read(vehicleServiceProvider).getMyVehicles(limit: 50);
});

final myBatteriesProvider = FutureProvider<BatteryListResponse>((ref) {
  return ref.read(batteryServiceProvider).getMyBatteries(limit: 50);
});

final myAccessoriesProvider = FutureProvider<AccessoryListResponse>((ref) {
  return ref.read(accessoryServiceProvider).getMyAccessories(limit: 50);
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tin đăng của tôi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Xe'),
              Tab(text: 'Pin'),
              Tab(text: 'Phụ kiện'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateListingSheet(context),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
        body: TabBarView(
          children: [
            _ListingTab<VehicleModel>(
              itemsAsync: ref.watch(myVehiclesProvider).whenData(
                    (response) => response.data,
                  ),
              emptyIcon: Icons.electric_car_rounded,
              emptyText: 'Bạn chưa đăng bán xe nào',
              onRefresh: () async {
                await ref.refresh(myVehiclesProvider.future);
              },
              itemBuilder: (vehicle) => _ListingItem(
                title: vehicle.name,
                subtitle: '${vehicle.brand} • ${vehicle.year}',
                location: vehicle.location,
                price: vehicle.price,
                imageUrl: vehicle.thumbnailUrl,
                placeholderIcon: Icons.electric_car_rounded,
                approvalStatus: vehicle.approvalStatus,
                status: vehicle.status,
                statusLabel: vehicle.statusLabel,
                createdAt: vehicle.createdAt,
                onTap: () => context.push('/vehicles/${vehicle.id}'),
              ),
            ),
            _ListingTab<BatteryModel>(
              itemsAsync: ref.watch(myBatteriesProvider).whenData(
                    (response) => response.data,
                  ),
              emptyIcon: Icons.battery_charging_full_rounded,
              emptyText: 'Bạn chưa đăng bán pin nào',
              onRefresh: () async {
                await ref.refresh(myBatteriesProvider.future);
              },
              itemBuilder: (battery) => _ListingItem(
                title: battery.name,
                subtitle: '${battery.typeLabel} • ${battery.condition}%',
                location: battery.location,
                price: battery.price,
                imageUrl: battery.thumbnailUrl,
                placeholderIcon: Icons.battery_charging_full_rounded,
                approvalStatus: battery.approvalStatus,
                status: battery.status,
                statusLabel: battery.statusLabel,
                createdAt: battery.createdAt,
                onTap: () => context.push('/batteries/${battery.id}'),
              ),
            ),
            _ListingTab<AccessoryModel>(
              itemsAsync: ref.watch(myAccessoriesProvider).whenData(
                    (response) => response.data,
                  ),
              emptyIcon: Icons.extension_outlined,
              emptyText: 'Bạn chưa đăng bán phụ kiện nào',
              onRefresh: () async {
                await ref.refresh(myAccessoriesProvider.future);
              },
              itemBuilder: (accessory) => _ListingItem(
                title: accessory.name,
                subtitle: accessory.brand ?? accessory.category,
                location: accessory.location,
                price: accessory.price,
                imageUrl: accessory.thumbnailUrl,
                placeholderIcon: Icons.extension_outlined,
                approvalStatus: accessory.approvalStatus,
                status: accessory.status,
                statusLabel: _listingStatusLabel(accessory.status),
                createdAt: accessory.createdAt,
                onTap: () => context.push('/accessories/${accessory.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingTab<T> extends StatelessWidget {
  final AsyncValue<List<T>> itemsAsync;
  final IconData emptyIcon;
  final String emptyText;
  final RefreshCallback onRefresh;
  final Widget Function(T item) itemBuilder;

  const _ListingTab({
    required this.itemsAsync,
    required this.emptyIcon,
    required this.emptyText,
    required this.onRefresh,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
      error: (error, _) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 160),
            Center(child: Text('Lỗi: $error')),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              children: [
                const SizedBox(height: 140),
                Icon(emptyIcon, size: 64, color: AppTheme.grey300),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    emptyText,
                    style: const TextStyle(color: AppTheme.grey600),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => itemBuilder(items[index]),
          ),
        );
      },
    );
  }
}

class _ListingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final double price;
  final String? imageUrl;
  final IconData placeholderIcon;
  final String approvalStatus;
  final String status;
  final String statusLabel;
  final String createdAt;
  final VoidCallback onTap;

  const _ListingItem({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.placeholderIcon,
    required this.approvalStatus,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: imageUrl,
              width: 92,
              height: 92,
              borderRadius: BorderRadius.circular(12),
              placeholderIcon: placeholderIcon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.grey600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.grey400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppUtils.formatCurrency(price),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StatusChip(status: approvalStatus, isApproval: true),
                      _StatusChip(status: status, label: statusLabel),
                      if (createdAt.isNotEmpty)
                        _MetaChip(label: AppUtils.timeAgo(createdAt)),
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

class _StatusChip extends StatelessWidget {
  final String status;
  final String? label;
  final bool isApproval;

  const _StatusChip({
    required this.status,
    this.label,
    this.isApproval = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final text = label ??
        (isApproval ? _approvalStatusLabel(normalized) : _listingStatusLabel(normalized));
    final color = isApproval
        ? _approvalStatusColor(normalized)
        : _listingStatusColor(normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.grey600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

void _showCreateListingSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Đăng tin mới',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full_rounded),
            title: const Text('Đăng bán pin điện'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/sell/battery');
            },
          ),
          ListTile(
            leading: const Icon(Icons.electric_car_rounded),
            title: const Text('Đăng bán xe điện'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/sell/vehicle');
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Đăng bán phụ kiện'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/sell/accessory');
            },
          ),
        ],
      ),
    ),
  );
}

String _approvalStatusLabel(String status) {
  return switch (status) {
    'APPROVED' => 'Đã duyệt',
    'REJECTED' => 'Bị từ chối',
    'PENDING' => 'Đang duyệt',
    _ => status,
  };
}

Color _approvalStatusColor(String status) {
  return switch (status) {
    'APPROVED' => AppTheme.success,
    'REJECTED' => AppTheme.error,
    'PENDING' => AppTheme.warning,
    _ => AppTheme.grey600,
  };
}

String _listingStatusLabel(String status) {
  return switch (status.toUpperCase()) {
    'AVAILABLE' => 'Còn hàng',
    'SOLD' => 'Đã bán',
    'AUCTION' => 'Đấu giá',
    'RESERVED' => 'Đã đặt cọc',
    _ => status,
  };
}

Color _listingStatusColor(String status) {
  return switch (status.toUpperCase()) {
    'AVAILABLE' => AppTheme.info,
    'SOLD' => AppTheme.grey600,
    'AUCTION' => AppTheme.accentOrange,
    'RESERVED' => AppTheme.warning,
    _ => AppTheme.grey600,
  };
}
