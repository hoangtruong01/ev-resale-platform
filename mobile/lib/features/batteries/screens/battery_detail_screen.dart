import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/battery_service.dart';
import '../../../models/battery_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/network/dio_client.dart';
import '../../../services/dashboard_service.dart';
import '../../home/widgets/home_widgets.dart';

final batteryDetailProvider = FutureProvider.family<BatteryModel, String>((
  ref,
  id,
) {
  return ref.read(batteryServiceProvider).getBatteryById(id);
});

final relatedBatteriesProvider = FutureProvider.family<List<BatteryModel>, BatteryModel>((
  ref,
  currentBattery,
) async {
  try {
    final response = await ref.read(batteryServiceProvider).getBatteries(
      type: currentBattery.type,
      limit: 10,
    );
    final list = response.data.where((b) => b.id != currentBattery.id).toList();
    if (list.isEmpty) {
      final fallbackResponse = await ref.read(batteryServiceProvider).getBatteries(limit: 10);
      return fallbackResponse.data.where((b) => b.id != currentBattery.id).toList();
    }
    return list;
  } catch (e) {
    debugPrint('Error fetching related batteries: $e');
    return [];
  }
});

class BatteryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BatteryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<BatteryDetailScreen> createState() =>
      _BatteryDetailScreenState();
}

class _BatteryDetailScreenState extends ConsumerState<BatteryDetailScreen> {
  int _currentImageIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batteryAsync = ref.watch(batteryDetailProvider(widget.id));
    final currentUser = ref.watch(currentUserProvider);
    final favoritesAsync = ref.watch(dashboardFavoritesProvider);
    final isFavorite = favoritesAsync.maybeWhen(
      data: (list) => list.any((fav) => fav.sourceId == widget.id),
      orElse: () => false,
    );

    return Scaffold(
      body: batteryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (battery) => CustomScrollView(
          slivers: [
            // Image gallery app bar
            SliverAppBar(
              expandedHeight: 300,
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
                                .addFavorite(batteryId: widget.id);
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
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                      ),
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
                      itemCount: battery.images.isEmpty
                          ? 1
                          : battery.images.length,
                      itemBuilder: (_, i) => AppNetworkImage(
                        url: battery.images.isEmpty ? null : battery.images[i],
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.battery_charging_full_rounded,
                      ),
                    ),
                    if (battery.images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            battery.images.length,
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

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status chips
                    Row(
                      children: [
                        _StatusChip(
                          label: battery.typeLabel,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: battery.statusLabel,
                          color: battery.isAvailable
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                        if (!battery.isAvailable) ...[
                          const SizedBox(width: 8),
                          const _StatusChip(
                            label: 'Đã bán',
                            color: AppTheme.error,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      battery.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Text(
                      AppUtils.formatCurrency(battery.price),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),

                    const SizedBox(height: 20),



                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Specs
                    const Text(
                      'Thông số kỹ thuật',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Condition bar
                    Row(
                      children: [
                        Text(
                          'Tình trạng:',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppTheme.grey600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearPercentIndicator(
                            percent: battery.condition / 100,
                            lineHeight: 10,
                            progressColor: _conditionColor(battery.condition),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white12
                                : AppTheme.grey200,
                            barRadius: const Radius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${battery.condition}%',
                          style: TextStyle(
                            color: _conditionColor(battery.condition),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _SpecRow(label: 'Loại pin', value: battery.typeLabel),
                    _SpecRow(
                      label: 'Dung lượng',
                      value: '${battery.capacity} kWh',
                    ),
                    if (battery.voltage != null)
                      _SpecRow(label: 'Điện áp', value: '${battery.voltage} V'),
                    _SpecRow(
                      label: 'Tình trạng',
                      value: AppUtils.batteryConditionLabel(battery.condition),
                    ),
                    _SpecRow(label: 'Khu vực', value: battery.location),
                    _SpecRow(
                      label: 'Đăng ngày',
                      value: AppUtils.formatDate(battery.createdAt),
                    ),

                    if (battery.description != null) ...[
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
                        battery.description!,
                        style: const TextStyle(
                          color: AppTheme.grey600,
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Seller info
                    if (battery.seller != null) ...[
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
                              battery.seller!.displayName.isNotEmpty
                                  ? battery.seller!.displayName[0].toUpperCase()
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
                                  battery.seller!.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (battery.seller!.rating != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: AppTheme.accentYellow,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${battery.seller!.rating!.toStringAsFixed(1)} (${battery.seller!.totalRatings} đánh giá)',
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
                    ref.watch(relatedBatteriesProvider(battery)).when(
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
                                  placeholderIcon: Icons.battery_charging_full_rounded,
                                  onTap: () {
                                    context.push('/batteries/${item.id}');
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
      bottomNavigationBar: batteryAsync.value == null
          ? null
          : _BottomBar(
              battery: batteryAsync.value!,
              currentUserId: currentUser?.id,
            ),
    );
  }

  Color _conditionColor(int condition) {
    if (condition >= 80) return AppTheme.success;
    if (condition >= 60) return AppTheme.warning;
    return AppTheme.error;
  }
}

class _BottomBar extends ConsumerWidget {
  final BatteryModel battery;
  final String? currentUserId;

  const _BottomBar({required this.battery, this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = battery.sellerId == currentUserId;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : AppTheme.grey200,
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
                      if (currentUserId == null) {
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
                          'buyerId': currentUserId,
                          'sellerId': battery.sellerId,
                          'batteryId': battery.id,
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
                      final phone = battery.seller?.phone;
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
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : AppTheme.grey600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.grey900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
