import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/battery_service.dart';
import '../../../models/battery_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

final batteryDetailProvider =
    FutureProvider.family<BatteryModel, String>((ref, id) {
  return ref.read(batteryServiceProvider).getBatteryById(id);
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

    return Scaffold(
      body: batteryAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
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
                      icon: const Icon(Icons.favorite_border,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.share_outlined,
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
                      itemCount: battery.images.isEmpty ? 1 : battery.images.length,
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
                              label: 'Đã bán', color: AppTheme.error),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      battery.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.grey900),
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
                    
                    // Live Monitoring Button
                    if (battery.isActive) // Only show if active
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/battery-monitor/${battery.id}?name=${battery.name}'),
                          icon: const Icon(Icons.sensors_outlined),
                          label: const Text('Theo dõi trực tiếp qua PLC'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: const BorderSide(color: AppTheme.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Specs
                    const Text('Thông số kỹ thuật',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Condition bar
                    Row(
                      children: [
                        const Text('Tình trạng:',
                            style: TextStyle(
                                color: AppTheme.grey600, fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearPercentIndicator(
                            percent: battery.condition / 100,
                            lineHeight: 10,
                            progressColor: _conditionColor(battery.condition),
                            backgroundColor: AppTheme.grey200,
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
                        value: '${battery.capacity} kWh'),
                    if (battery.voltage != null)
                      _SpecRow(
                          label: 'Điện áp',
                          value: '${battery.voltage} V'),
                    _SpecRow(
                        label: 'Tình trạng',
                        value: AppUtils.batteryConditionLabel(
                            battery.condition)),
                    _SpecRow(
                        label: 'Khu vực',
                        value: battery.location),
                    _SpecRow(
                        label: 'Đăng ngày',
                        value: AppUtils.formatDate(battery.createdAt)),

                    if (battery.description != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Mô tả',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        battery.description!,
                        style: const TextStyle(
                            color: AppTheme.grey600,
                            height: 1.6,
                            fontSize: 14),
                      ),
                    ],

                    // Seller info
                    if (battery.seller != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Người bán',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                            child: Text(
                              battery.seller!.displayName.isNotEmpty
                                  ? battery.seller!.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18),
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
                                      fontSize: 15),
                                ),
                                if (battery.seller!.rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16,
                                          color: AppTheme.accentYellow),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${battery.seller!.rating!.toStringAsFixed(1)} (${battery.seller!.totalRatings} đánh giá)',
                                        style: const TextStyle(
                                            color: AppTheme.grey600,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
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

class _BottomBar extends StatelessWidget {
  final BatteryModel battery;
  final String? currentUserId;

  const _BottomBar({required this.battery, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isMine = battery.sellerId == currentUserId;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
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
                    onPressed: () => context.push(
                        '/chat?sellerId=${battery.sellerId}&batteryId=${battery.id}'),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Nhắn tin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: battery.isAvailable ? () {} : null,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Mua ngay'),
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
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.grey600, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.grey900,
                  fontSize: 14),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
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
