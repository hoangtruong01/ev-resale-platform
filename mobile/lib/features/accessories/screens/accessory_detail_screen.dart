import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/accessory_service.dart';
import '../../../models/accessory_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import 'sell_accessory_screen.dart';
import '../../home/widgets/home_widgets.dart';

final accessoryDetailProvider = FutureProvider.family<AccessoryModel, String>((
  ref,
  id,
) {
  return ref.read(accessoryServiceProvider).getAccessoryById(id);
});

final relatedAccessoriesProvider = FutureProvider.family<List<AccessoryModel>, AccessoryModel>((
  ref,
  currentAccessory,
) async {
  try {
    final response = await ref.read(accessoryServiceProvider).getAccessories(
      category: currentAccessory.category,
      limit: 10,
    );
    final list = response.data.where((a) => a.id != currentAccessory.id).toList();
    if (list.isEmpty) {
      final fallbackResponse = await ref.read(accessoryServiceProvider).getAccessories(limit: 10);
      return fallbackResponse.data.where((a) => a.id != currentAccessory.id).toList();
    }
    return list;
  } catch (e) {
    debugPrint('Error fetching related accessories: $e');
    return [];
  }
});

class AccessoryDetailScreen extends ConsumerWidget {
  final String id;
  const AccessoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessoryAsync = ref.watch(accessoryDetailProvider(id));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phụ kiện')),
      bottomNavigationBar: accessoryAsync.value == null
          ? null
          : Builder(
              builder: (context) {
                final accessory = accessoryAsync.value!;
                final isMine = accessory.sellerId == currentUser?.id;

                return Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.grey200)),
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
                          onPressed: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SellAccessoryScreen(
                                  initialAccessory: accessory,
                                ),
                              ),
                            );
                            if (updated == true) {
                              ref.invalidate(accessoryDetailProvider(id));
                            }
                          },
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
                                      'sellerId': accessory.sellerId,
                                      'accessoryId': accessory.id,
                                    }).timeout(const Duration(seconds: 15));
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading indicator

                                    final roomId = response.data['id'];
                                    if (roomId != null) {
                                      context.push('/chat/$roomId');
                                    }
                                  } catch (e) {
                                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading indicator
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
                                  final phone = accessory.seller?.phone;
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
      body: accessoryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Lỗi: $e'),
            ],
          ),
        ),
        data: (accessory) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppNetworkImage(
                    url: accessory.thumbnailUrl,
                    height: 240,
                    width: double.infinity,
                    placeholderIcon: Icons.extension_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                accessory.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppUtils.formatCurrency(accessory.price),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Danh mục', value: accessory.category),
              _InfoRow(label: 'Tình trạng', value: accessory.condition),
              if (accessory.brand != null && accessory.brand!.isNotEmpty)
                _InfoRow(label: 'Thương hiệu', value: accessory.brand!),
              if (accessory.compatibleModel != null &&
                  accessory.compatibleModel!.isNotEmpty)
                _InfoRow(
                  label: 'Tương thích',
                  value: accessory.compatibleModel!,
                ),
              _InfoRow(label: 'Khu vực', value: accessory.location),
              const SizedBox(height: 12),
              Text(
                'Mô tả',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                accessory.description ?? 'Chưa có mô tả',
                style: const TextStyle(color: AppTheme.grey600),
              ),

              // Seller info
              if (accessory.seller != null) ...[
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
                        accessory.seller!.displayName.isNotEmpty
                            ? accessory.seller!.displayName[0].toUpperCase()
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
                            accessory.seller!.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (accessory.seller!.rating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppTheme.accentYellow,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${accessory.seller!.rating!.toStringAsFixed(1)} (${accessory.seller!.totalRatings} đánh giá)',
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
              ref.watch(relatedAccessoriesProvider(accessory)).when(
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
                            placeholderIcon: Icons.extension_outlined,
                            onTap: () {
                              context.push('/accessories/${item.id}');
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
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppTheme.grey500)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
