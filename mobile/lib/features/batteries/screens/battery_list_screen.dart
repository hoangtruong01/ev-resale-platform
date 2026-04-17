import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/battery_service.dart';
import '../../../models/battery_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

// Filter state
class BatteryFilter {
  final String? search;
  final String? type;
  final double? minPrice;
  final double? maxPrice;
  final int? minCondition;
  final String? sortBy;

  const BatteryFilter({
    this.search,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.minCondition,
    this.sortBy,
  });

  BatteryFilter copyWith({
    String? search,
    String? type,
    double? minPrice,
    double? maxPrice,
    int? minCondition,
    String? sortBy,
  }) => BatteryFilter(
    search: search ?? this.search,
    type: type ?? this.type,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    minCondition: minCondition ?? this.minCondition,
    sortBy: sortBy ?? this.sortBy,
  );
}

final batteryFilterProvider = StateProvider<BatteryFilter>(
  (ref) => const BatteryFilter(),
);

final batteryListProvider =
    FutureProvider.family<BatteryListResponse, BatteryFilter>((ref, filter) {
      return ref
          .read(batteryServiceProvider)
          .getBatteries(
            search: filter.search,
            type: filter.type,
            minPrice: filter.minPrice,
            maxPrice: filter.maxPrice,
            minCondition: filter.minCondition,
            sortBy: filter.sortBy,
          );
    });

class BatteryListScreen extends ConsumerStatefulWidget {
  const BatteryListScreen({super.key});

  @override
  ConsumerState<BatteryListScreen> createState() => _BatteryListScreenState();
}

class _BatteryListScreenState extends ConsumerState<BatteryListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(batteryFilterProvider);
    final batteriesAsync = ref.watch(batteryListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin điện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context, filter),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm pin...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey400),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(batteryFilterProvider.notifier).state =
                              filter.copyWith(search: null);
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) {
                ref.read(batteryFilterProvider.notifier).state = filter
                    .copyWith(search: v.isEmpty ? null : v);
              },
            ),
          ),

          // Type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _TypeChip(
                  label: 'Tất cả',
                  selected: filter.type == null,
                  onTap: () {
                    ref
                        .read(batteryFilterProvider.notifier)
                        .state = BatteryFilter(
                      search: filter.search,
                      minPrice: filter.minPrice,
                      maxPrice: filter.maxPrice,
                      minCondition: filter.minCondition,
                    );
                  },
                ),
                const SizedBox(width: 8),
                ...[
                  'LITHIUM_ION',
                  'LITHIUM_POLYMER',
                  'NICKEL_METAL_HYDRIDE',
                  'LEAD_ACID',
                ].map((type) {
                  final labels = {
                    'LITHIUM_ION': 'Li-ion',
                    'LITHIUM_POLYMER': 'LiPo',
                    'NICKEL_METAL_HYDRIDE': 'NiMH',
                    'LEAD_ACID': 'Chì-Axit',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TypeChip(
                      label: labels[type]!,
                      selected: filter.type == type,
                      onTap: () {
                        ref.read(batteryFilterProvider.notifier).state = filter
                            .copyWith(type: type);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(
            child: batteriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text('Lỗi: $e'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(batteryListProvider(filter)),
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
                        Icon(
                          Icons.battery_alert_rounded,
                          size: 64,
                          color: AppTheme.grey200,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy pin nào',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: data.data.length,
                  itemBuilder: (_, i) =>
                      _BatteryGridCard(battery: data.data[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, BatteryFilter filter) {
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : AppTheme.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : AppTheme.grey200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.grey600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BatteryGridCard extends StatelessWidget {
  final BatteryModel battery;
  const _BatteryGridCard({required this.battery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/batteries/${battery.id}'),
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AppNetworkImage(
                  url: battery.thumbnailUrl,
                  width: double.infinity,
                  placeholderIcon: Icons.battery_charging_full_rounded,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    battery.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _conditionColor(
                            battery.condition,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${battery.condition}%',
                          style: TextStyle(
                            color: _conditionColor(battery.condition),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          battery.typeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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

  Color _conditionColor(int condition) {
    if (condition >= 80) return AppTheme.success;
    if (condition >= 60) return AppTheme.warning;
    return AppTheme.error;
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final BatteryFilter filter;
  const _FilterSheet({required this.filter});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String? _selectedType;
  late double _minCondition;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.filter.type;
    _minCondition = (widget.filter.minCondition ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bộ lọc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          const Text('Loại pin', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                [
                  null,
                  'LITHIUM_ION',
                  'LITHIUM_POLYMER',
                  'NICKEL_METAL_HYDRIDE',
                  'LEAD_ACID',
                ].map((type) {
                  final label = type == null
                      ? 'Tất cả'
                      : {
                          'LITHIUM_ION': 'Li-ion',
                          'LITHIUM_POLYMER': 'LiPo',
                          'NICKEL_METAL_HYDRIDE': 'NiMH',
                          'LEAD_ACID': 'Chì-Axit',
                        }[type]!;
                  return FilterChip(
                    label: Text(label),
                    selected: _selectedType == type,
                    onSelected: (_) => setState(() => _selectedType = type),
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: _selectedType == type
                          ? Colors.white
                          : AppTheme.grey800,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 16),
          Text(
            'Tình trạng tối thiểu: ${_minCondition.round()}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _minCondition,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppTheme.primaryGreen,
            onChanged: (v) => setState(() => _minCondition = v),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(batteryFilterProvider.notifier).state =
                        const BatteryFilter();
                    Navigator.pop(context);
                  },
                  child: const Text('Xoá bộ lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(batteryFilterProvider.notifier).state = widget
                        .filter
                        .copyWith(
                          type: _selectedType,
                          minCondition: _minCondition.round(),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
