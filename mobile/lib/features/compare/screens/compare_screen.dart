import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../widgets/app_network_image.dart';
import '../providers/compare_provider.dart';
import '../widgets/product_selection_sheet.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  void _selectProduct() async {
    final state = ref.read(compareProvider);
    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductSelectionSheet(type: state.type),
    );

    if (selected != null) {
      ref.read(compareProvider.notifier).addItem(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compareProvider);

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('So sánh sản phẩm'),
        actions: [
          if (state.items.isNotEmpty)
            IconButton(
              onPressed: () => ref.read(compareProvider.notifier).clear(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới',
            ),
        ],
      ),
      body: Column(
        children: [
          // Type Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _TypeButton(
                  label: 'Pin điện',
                  isSelected: state.type == 'battery',
                  onTap: () => ref.read(compareProvider.notifier).setType('battery'),
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  label: 'Xe điện',
                  isSelected: state.type == 'vehicle',
                  onTap: () => ref.read(compareProvider.notifier).setType('vehicle'),
                ),
              ],
            ),
          ),

          if (state.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.compare_arrows_rounded, size: 80, color: AppTheme.grey300),
                    const SizedBox(height: 24),
                    const Text(
                      'Hãy chọn tối đa 3 sản phẩm để so sánh thông số.',
                      style: TextStyle(fontSize: 15, color: AppTheme.grey600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _selectProduct,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm sản phẩm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Product Header Cards
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...state.items.map((item) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _ProductHeader(
                                item: item,
                                onRemove: () => ref.read(compareProvider.notifier).removeItem(item.id),
                              ),
                            ),
                          )),
                          if (state.items.length < 3)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: InkWell(
                                  onTap: _selectProduct,
                                  child: Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.grey200, style: BorderStyle.none),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_circle_outline, color: AppTheme.grey400, size: 32),
                                          const SizedBox(height: 8),
                                          Text('Thêm', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Comparison Table
                    _ComparisonTable(state: state),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.grey600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final dynamic item;
  final VoidCallback onRemove;

  const _ProductHeader({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: item.images.isNotEmpty ? item.images.first : '',
                  height: 80,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                AppUtils.formatCurrency(item.price),
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.cancel, color: AppTheme.grey400, size: 20),
          ),
        ),
      ],
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final CompareState state;
  const _ComparisonTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = state.type == 'battery' ? _getBatteryRows() : _getVehicleRows();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        children: rows.map((row) => _buildRow(row)).toList(),
      ),
    );
  }

  List<CompareRowData> _getBatteryRows() {
    return [
      CompareRowData(
        label: 'Dung lượng',
        values: state.items.map((i) => '${(i as BatteryModel).capacity} kWh').toList(),
      ),
      CompareRowData(
        label: 'Loại Pin',
        values: state.items.map((i) => (i as BatteryModel).typeLabel).toList(),
      ),
      CompareRowData(
        label: 'Tình trạng (SOH)',
        values: state.items.map((i) => '${(i as BatteryModel).condition}%').toList(),
      ),
      CompareRowData(
        label: 'Điện áp',
        values: state.items.map((i) => i.voltage != null ? '${i.voltage} V' : '-').toList(),
      ),
      CompareRowData(
        label: 'Vị trí',
        values: state.items.map((i) => (i as BatteryModel).location).toList(),
      ),
    ];
  }

  List<CompareRowData> _getVehicleRows() {
    return [
      CompareRowData(
        label: 'Thương hiệu',
        values: state.items.map((i) => (i as VehicleModel).brand).toList(),
      ),
      CompareRowData(
        label: 'Dòng xe',
        values: state.items.map((i) => (i as VehicleModel).model).toList(),
      ),
      CompareRowData(
        label: 'Năm sản xuất',
        values: state.items.map((i) => (i as VehicleModel).year.toString()).toList(),
      ),
      CompareRowData(
        label: 'Số km đã đi',
        values: state.items.map((i) => i.mileage != null ? '${i.mileage} km' : '-').toList(),
      ),
      CompareRowData(
        label: 'Hộp số',
        values: state.items.map((i) => (i as VehicleModel).transmission ?? '-').toList(),
      ),
      CompareRowData(
        label: 'Số chỗ ngồi',
        values: state.items.map((i) => i.seatCount?.toString() ?? '-').toList(),
      ),
      CompareRowData(
        label: 'Màu sắc',
        values: state.items.map((i) => (i as VehicleModel).color ?? '-').toList(),
      ),
      CompareRowData(
        label: 'Bảo hành',
        values: state.items.map((i) => (i as VehicleModel).hasWarranty == true ? 'Còn' : 'Hết').toList(),
      ),
    ];
  }

  Widget _buildRow(CompareRowData row) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...row.values.map((val) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        val,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.grey900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
                  // Fill empty columns if less than 3 items
                  for (int i = 0; i < 3 - row.values.length; i++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.grey100),
      ],
    );
  }
}

class CompareRowData {
  final String label;
  final List<String> values;
  CompareRowData({required this.label, required this.values});
}
