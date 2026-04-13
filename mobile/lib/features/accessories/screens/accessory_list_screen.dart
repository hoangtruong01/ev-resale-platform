import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/accessory_service.dart';
import '../../../models/accessory_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

class AccessoryFilter {
  final String? search;
  final String? category;

  const AccessoryFilter({
    this.search,
    this.category,
  });

  AccessoryFilter copyWith({
    String? search,
    String? category,
  }) =>
      AccessoryFilter(
        search: search ?? this.search,
        category: category ?? this.category,
      );
}

final accessoryFilterProvider =
    StateProvider<AccessoryFilter>((ref) => const AccessoryFilter());

final accessoryListProvider =
    FutureProvider.family<AccessoryListResponse, AccessoryFilter>((ref, filter) {
  return ref.read(accessoryServiceProvider).getAccessories(
        search: filter.search,
        category: filter.category,
      );
});

class AccessoryListScreen extends ConsumerStatefulWidget {
  const AccessoryListScreen({super.key});

  @override
  ConsumerState<AccessoryListScreen> createState() => _AccessoryListScreenState();
}

class _AccessoryListScreenState extends ConsumerState<AccessoryListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(accessoryFilterProvider);
    final accessoriesAsync = ref.watch(accessoryListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phụ kiện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context, filter),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phụ kiện...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey400),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(accessoryFilterProvider.notifier).state =
                              filter.copyWith(search: null);
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) {
                ref.read(accessoryFilterProvider.notifier).state =
                    filter.copyWith(search: v.isEmpty ? null : v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: accessoriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.error),
                    const SizedBox(height: 12),
                    Text('Lỗi: $e'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(accessoryListProvider(filter)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (data.data.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.extension_outlined,
                            size: 64, color: AppTheme.grey200),
                        SizedBox(height: 16),
                        Text('Không tìm thấy phụ kiện',
                            style: TextStyle(color: AppTheme.grey600)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _AccessoryCard(accessory: data.data[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AccessoryFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(filter: filter),
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  final AccessoryModel accessory;
  const _AccessoryCard({required this.accessory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/accessories/${accessory.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AppNetworkImage(
                url: accessory.thumbnailUrl,
                height: 180,
                width: double.infinity,
                placeholderIcon: Icons.extension_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accessory.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppTheme.grey400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          accessory.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.grey400, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppUtils.formatCurrency(accessory.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
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

class _FilterSheet extends ConsumerWidget {
  final AccessoryFilter filter;
  const _FilterSheet({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryOptions = const [
      {'label': 'Tất cả', 'value': null},
      {'label': 'Bộ sạc', 'value': 'CHARGER'},
      {'label': 'Lốp xe', 'value': 'TIRE'},
      {'label': 'Nội thất', 'value': 'INTERIOR'},
      {'label': 'Ngoại thất', 'value': 'EXTERIOR'},
      {'label': 'Điện - điện tử', 'value': 'ELECTRONICS'},
      {'label': 'An toàn', 'value': 'SAFETY'},
      {'label': 'Bảo dưỡng', 'value': 'MAINTENANCE'},
      {'label': 'Khác', 'value': 'OTHER'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bộ lọc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryOptions.map((option) {
              final isSelected = filter.category == option['value'];
              return ChoiceChip(
                label: Text(option['label'] as String),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(accessoryFilterProvider.notifier).state =
                      filter.copyWith(category: option['value'] as String?);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }
}
