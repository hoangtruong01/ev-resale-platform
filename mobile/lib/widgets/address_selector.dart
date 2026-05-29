import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import 'app_text_field.dart';

class AddressSelector extends ConsumerStatefulWidget {
  final String? initialStreetAddress;
  final String? initialWard;
  final String? initialDistrict;
  final String? initialProvince;
  final void Function({
    required String streetAddress,
    required String ward,
    required String district,
    required String province,
  }) onAddressChanged;

  const AddressSelector({
    super.key,
    this.initialStreetAddress,
    this.initialWard,
    this.initialDistrict,
    this.initialProvince,
    required this.onAddressChanged,
  });

  @override
  ConsumerState<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends ConsumerState<AddressSelector> {
  // Manual Input Mode (Fallback)
  bool _isManualMode = false;

  // Loading states
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  // Dropdown lists
  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  List<WardModel> _wards = [];

  // Selections
  ProvinceModel? _selectedProvince;
  DistrictModel? _selectedDistrict;
  WardModel? _selectedWard;

  // Controllers for manual inputs and streetAddress
  final _streetCtrl = TextEditingController();
  final _manualWardCtrl = TextEditingController();
  final _manualDistrictCtrl = TextEditingController();
  final _manualProvinceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _streetCtrl.text = widget.initialStreetAddress ?? '';
    _manualWardCtrl.text = widget.initialWard ?? '';
    _manualDistrictCtrl.text = widget.initialDistrict ?? '';
    _manualProvinceCtrl.text = widget.initialProvince ?? '';

    // Listen to changes in manual mode
    _streetCtrl.addListener(_notifyChanged);
    _manualWardCtrl.addListener(_notifyChanged);
    _manualDistrictCtrl.addListener(_notifyChanged);
    _manualProvinceCtrl.addListener(_notifyChanged);

    // Load Level 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProvinces();
    });
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _manualWardCtrl.dispose();
    _manualDistrictCtrl.dispose();
    _manualProvinceCtrl.dispose();
    super.dispose();
  }

  // Load level 1: Provinces
  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final service = ref.read(addressServiceProvider);
      final list = await service.getProvinces();
      setState(() {
        _provinces = list;
        
        // Auto select if initial data matches
        if (widget.initialProvince != null && widget.initialProvince!.isNotEmpty) {
          final match = list.firstWhere(
            (p) => p.name.toLowerCase() == widget.initialProvince!.toLowerCase(),
            orElse: () => const ProvinceModel(code: -1, name: '', codename: ''),
          );
          if (match.code != -1) {
            _selectedProvince = match;
            _loadDistricts(match.code);
          }
        }
      });
    } catch (e) {
      // Auto fallback to manual mode on error
      setState(() => _isManualMode = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải địa chỉ tự động. Đã chuyển sang nhập tay.')),
      );
    } finally {
      setState(() => _isLoadingProvinces = false);
    }
  }

  // Load level 2: Districts
  Future<void> _loadDistricts(int provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
      _selectedDistrict = null;
      _selectedWard = null;
    });
    try {
      final service = ref.read(addressServiceProvider);
      final list = await service.getDistricts(provinceCode);
      setState(() {
        _districts = list;

        // Auto select district
        if (widget.initialDistrict != null && widget.initialDistrict!.isNotEmpty) {
          final match = list.firstWhere(
            (d) => d.name.toLowerCase() == widget.initialDistrict!.toLowerCase(),
            orElse: () => const DistrictModel(code: -1, name: '', codename: ''),
          );
          if (match.code != -1) {
            _selectedDistrict = match;
            _loadWards(match.code);
          }
        }
      });
    } catch (e) {
      setState(() => _isManualMode = true);
    } finally {
      setState(() => _isLoadingDistricts = false);
    }
  }

  // Load level 3: Wards
  Future<void> _loadWards(int districtCode) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _selectedWard = null;
    });
    try {
      final service = ref.read(addressServiceProvider);
      final list = await service.getWards(districtCode);
      setState(() {
        _wards = list;

        // Auto select ward
        if (widget.initialWard != null && widget.initialWard!.isNotEmpty) {
          final match = list.firstWhere(
            (w) => w.name.toLowerCase() == widget.initialWard!.toLowerCase(),
            orElse: () => const WardModel(code: -1, name: '', codename: ''),
          );
          if (match.code != -1) {
            _selectedWard = match;
            _notifyChanged();
          }
        }
      });
    } catch (e) {
      setState(() => _isManualMode = true);
    } finally {
      setState(() => _isLoadingWards = false);
    }
  }

  void _notifyChanged() {
    if (_isManualMode) {
      widget.onAddressChanged(
        streetAddress: _streetCtrl.text.trim(),
        ward: _manualWardCtrl.text.trim(),
        district: _manualDistrictCtrl.text.trim(),
        province: _manualProvinceCtrl.text.trim(),
      );
    } else {
      widget.onAddressChanged(
        streetAddress: _streetCtrl.text.trim(),
        ward: _selectedWard?.name ?? '',
        district: _selectedDistrict?.name ?? '',
        province: _selectedProvince?.name ?? '',
      );
    }
  }

  void _toggleManualMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = [];
      _wards = [];
      
      _manualProvinceCtrl.clear();
      _manualDistrictCtrl.clear();
      _manualWardCtrl.clear();
    });
    _notifyChanged();
    if (!_isManualMode) {
      _loadProvinces();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Manual Switch button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Chọn địa chỉ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(' *', style: TextStyle(color: AppTheme.error)),
              ],
            ),
            TextButton.icon(
              onPressed: _toggleManualMode,
              icon: Icon(
                _isManualMode ? Icons.map_outlined : Icons.edit_note_outlined,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              label: Text(
                _isManualMode ? 'Chọn theo danh sách' : 'Nhập tay thủ công',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (!_isManualMode) ...[
          // DROPDOWN SELECTS
          // Province Dropdown
          _buildDropdownContainer(
            label: 'Tỉnh / Thành phố',
            child: _isLoadingProvinces
                ? const LinearProgressIndicator(color: AppTheme.primaryGreen, backgroundColor: Colors.transparent)
                : DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<ProvinceModel>(
                      value: _selectedProvince,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      hint: Text(
                        'Chọn Tỉnh / Thành',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.grey400
                              : AppTheme.grey500,
                        ),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: _provinces.map((p) {
                        return DropdownMenuItem<ProvinceModel>(
                          value: p,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedProvince = val;
                          });
                          _loadDistricts(val.code);
                        }
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // District Dropdown
          _buildDropdownContainer(
            label: 'Quận / Huyện',
            isDisabled: _selectedProvince == null,
            child: _isLoadingDistricts
                ? const LinearProgressIndicator(color: AppTheme.primaryGreen, backgroundColor: Colors.transparent)
                : DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<DistrictModel>(
                      value: _selectedDistrict,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      hint: Text(
                        'Chọn Quận / Huyện',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.grey400
                              : AppTheme.grey500,
                        ),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: _districts.map((d) {
                        return DropdownMenuItem<DistrictModel>(
                          value: d,
                          child: Text(d.name),
                        );
                      }).toList(),
                      onChanged: _selectedProvince == null
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDistrict = val;
                                });
                                _loadWards(val.code);
                              }
                            },
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Ward Dropdown
          _buildDropdownContainer(
            label: 'Phường / Xã',
            isDisabled: _selectedDistrict == null,
            child: _isLoadingWards
                ? const LinearProgressIndicator(color: AppTheme.primaryGreen, backgroundColor: Colors.transparent)
                : DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<WardModel>(
                      value: _selectedWard,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      hint: Text(
                        'Chọn Phường / Xã',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.grey400
                              : AppTheme.grey500,
                        ),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: _wards.map((w) {
                        return DropdownMenuItem<WardModel>(
                          value: w,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: _selectedDistrict == null
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedWard = val;
                                });
                                _notifyChanged();
                              }
                            },
                    ),
                  ),
          ),
        ] else ...[
          // MANUAL INPUT FIELDS
          AppTextField(
            controller: _manualProvinceCtrl,
            label: 'Tỉnh / Thành phố',
            hint: 'Ví dụ: Hà Nội',
            prefixIcon: Icons.location_city_outlined,
            forceLightStyle: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _manualDistrictCtrl,
            label: 'Quận / Huyện',
            hint: 'Ví dụ: Đống Đa',
            prefixIcon: Icons.holiday_village_outlined,
            forceLightStyle: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _manualWardCtrl,
            label: 'Phường / Xã',
            hint: 'Ví dụ: Láng Thượng',
            prefixIcon: Icons.home_work_outlined,
            forceLightStyle: true,
          ),
        ],

        const SizedBox(height: 12),

        // Street Address Input
        AppTextField(
          controller: _streetCtrl,
          label: 'Số nhà, tên đường',
          hint: 'Ví dụ: 123 Lê Lợi hoặc tên ngõ/xóm',
          prefixIcon: Icons.my_location_outlined,
          forceLightStyle: true,
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
    bool isDisabled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.grey400 : AppTheme.grey500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: isDisabled
                ? (isDark ? AppTheme.grey800 : AppTheme.grey100)
                : (isDark ? AppTheme.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled
                  ? (isDark ? AppTheme.grey700 : AppTheme.grey200)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.grey300),
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
