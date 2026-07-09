import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/vehicle_service.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../services/dashboard_service.dart';
import '../../home/widgets/home_widgets.dart';

final vehicleDetailProvider = FutureProvider.family<VehicleModel, String>((
  ref,
  id,
) {
  return ref.read(vehicleServiceProvider).getVehicleById(id);
});

final relatedVehiclesProvider = FutureProvider.family<List<VehicleModel>, VehicleModel>((
  ref,
  currentVehicle,
) async {
  try {
    final response = await ref.read(vehicleServiceProvider).getVehicles(
      brand: currentVehicle.brand,
      limit: 10,
    );
    final list = response.data.where((v) => v.id != currentVehicle.id).toList();
    if (list.isEmpty) {
      final fallbackResponse = await ref.read(vehicleServiceProvider).getVehicles(limit: 10);
      return fallbackResponse.data.where((v) => v.id != currentVehicle.id).toList();
    }
    return list;
  } catch (e) {
    debugPrint('Error fetching related vehicles: $e');
    return [];
  }
});

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _SpecGrid extends StatelessWidget {
  final VehicleModel vehicle;
  const _SpecGrid({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final specs = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Năm SX',
        'value': '${vehicle.year}',
      },
      {
        'icon': Icons.speed_outlined,
        'label': 'Số km',
        'value': vehicle.mileage != null
            ? '${AppUtils.formatNumber(vehicle.mileage)} km'
            : 'N/A',
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Hộp số',
        'value': vehicle.transmission ?? 'N/A',
      },
      {
        'icon': Icons.palette_outlined,
        'label': 'Màu sắc',
        'value': vehicle.color ?? 'N/A',
      },
      {
        'icon': Icons.airline_seat_recline_normal_outlined,
        'label': 'Số ghế',
        'value': vehicle.seatCount?.toString() ?? 'N/A',
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Khu vực',
        'value': vehicle.location,
      },
      {
        'icon': Icons.verified_outlined,
        'label': 'Bảo hành',
        'value': vehicle.hasWarranty == true ? 'Có' : 'Không',
      },
      {
        'icon': Icons.info_outline,
        'label': 'Tình trạng',
        'value': vehicle.condition,
      },
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white10 : AppTheme.grey200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                spec['icon'] as IconData,
                size: 18,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spec['label'] as String,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : AppTheme.grey400,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      spec['value'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.grey900,
                      ),
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

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  final _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(widget.id));
    final currentUser = ref.watch(currentUserProvider);
    final favoritesAsync = ref.watch(dashboardFavoritesProvider);
    final isFavorite = favoritesAsync.maybeWhen(
      data: (list) => list.any((fav) => fav.sourceId == widget.id),
      orElse: () => false,
    );

    return Scaffold(
      body: vehicleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
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
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          if (isFavorite) {
                            final favItem = favoritesAsync.value?.firstWhere(
                              (fav) => fav.sourceId == widget.id,
                            );
                            if (favItem != null) {
                              await ref
                                  .read(dashboardServiceProvider)
                                  .removeFavorite(favItem.id);
                            }
                          } else {
                            await ref
                                .read(dashboardServiceProvider)
                                .addFavorite(vehicleId: widget.id);
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
                      itemCount: vehicle.images.isEmpty
                          ? 1
                          : vehicle.images.length,
                      itemBuilder: (_, i) => AppNetworkImage(
                        url: vehicle.images.isEmpty ? null : vehicle.images[i],
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
                              margin: const EdgeInsets.symmetric(horizontal: 2),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            vehicle.brand,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.grey900,
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
                    const Text(
                      'Thông số xe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SpecGrid(vehicle: vehicle),
                    if (vehicle.description != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Mô tả',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

                    // Seller info
                    if (vehicle.seller != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Người bán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              vehicle.seller!.displayName.isNotEmpty
                                  ? vehicle.seller!.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.seller!.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (vehicle.seller!.rating != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: AppTheme.accentYellow,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${vehicle.seller!.rating!.toStringAsFixed(1)} (${vehicle.seller!.totalRatings} đánh giá)',
                                        style: const TextStyle(
                                          color: AppTheme.grey600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Related products
                    ref.watch(relatedVehiclesProvider(vehicle)).when(
                      data: (relatedList) {
                        if (relatedList.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Sản phẩm liên quan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.58,
                              ),
                              itemCount: relatedList.length,
                              itemBuilder: (context, index) {
                                final item = relatedList[index];
                                return ProductGridCard(
                                  imageUrl: item.thumbnailUrl,
                                  title: item.name,
                                  price: item.price,
                                  sellerName: item.seller?.displayName,
                                  location: item.location,
                                  timeAgo: formatTimeAgo(item.createdAt),
                                  placeholderIcon: Icons.electric_car_rounded,
                                  onTap: () {
                                    context.push('/vehicles/${item.id}');
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        ),
                      ),
                      error: (err, _) => const SizedBox.shrink(),
                    ),

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
          : Builder(
              builder: (context) {
                final vehicle = vehicleAsync.value!;
                final isMine = vehicle.sellerId == currentUser?.id;

                final isDarkBar = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkBar ? AppTheme.darkSurface : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDarkBar ? Colors.white10 : AppTheme.grey200,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: isMine
                      ? ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Chỉnh sửa tin đăng'),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  if (currentUser == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng đăng nhập để nhắn tin')),
                                    );
                                    return;
                                  }

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                                    ),
                                  );

                                  try {
                                    final dio = ref.read(dioProvider);
                                    final response = await dio.post('/chat/rooms', data: {
                                      'buyerId': currentUser.id,
                                      'sellerId': vehicle.sellerId,
                                      'vehicleId': vehicle.id,
                                    }).timeout(const Duration(seconds: 15));
                                    if (context.mounted) Navigator.pop(context); // close loading indicator

                                    final roomId = response.data['id'];
                                    if (roomId != null) {
                                      context.push('/chat/$roomId');
                                    }
                                  } catch (e) {
                                    if (context.mounted) Navigator.pop(context); // close loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(parseApiError(e))),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.message_outlined),
                                label: const Text('Nhắn tin'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final phone = vehicle.seller?.phone;
                                  if (phone == null || phone.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Người bán chưa đăng ký số điện thoại'),
                                        backgroundColor: AppTheme.warning,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  final Uri launchUri = Uri(
                                    scheme: 'tel',
                                    path: phone.trim(),
                                  );
                                  
                                  try {
                                    if (await canLaunchUrl(launchUri)) {
                                      await launchUrl(launchUri);
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Không thể gọi điện đến số: $phone'),
                                            backgroundColor: AppTheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: AppTheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.phone),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                                label: const Text('Gọi điện'),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
