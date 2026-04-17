import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/accessory_service.dart';
import '../../../models/accessory_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

final accessoryDetailProvider = FutureProvider.family<AccessoryModel, String>((
  ref,
  id,
) {
  return ref.read(accessoryServiceProvider).getAccessoryById(id);
});

class AccessoryDetailScreen extends ConsumerWidget {
  final String id;
  const AccessoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessoryAsync = ref.watch(accessoryDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phụ kiện')),
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
