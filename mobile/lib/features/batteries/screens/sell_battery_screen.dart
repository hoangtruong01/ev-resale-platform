import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/battery_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../widgets/address_selector.dart';

class SellBatteryScreen extends ConsumerStatefulWidget {
  const SellBatteryScreen({super.key});

  @override
  ConsumerState<SellBatteryScreen> createState() => _SellBatteryScreenState();
}

class _SellBatteryScreenState extends ConsumerState<SellBatteryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _streetAddress = '';
  String _ward = '';
  String _district = '';
  String _province = '';

  String? _type;
  bool _isSubmitting = false;
  bool _isSuggestingPrice = false;
  double? _lastSuggestedPrice;
  final List<XFile> _images = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _conditionCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(batteryServiceProvider);
      final imageUrls = _images.isNotEmpty
          ? await service.uploadListingImages(_images)
          : <String>[];

      final user = ref.read(currentUserProvider);
      final description = _buildDescription(user);

      final payload = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'capacity': double.tryParse(_capacityCtrl.text.trim()) ?? 0,
        'condition': int.tryParse(_conditionCtrl.text.trim()) ?? 0,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': description,
        'location': _locationCtrl.text.trim(),
        if (imageUrls.isNotEmpty) 'images': imageUrls,
      };

      await service.createBattery(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng bán pin thành công!')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _suggestPrice() async {
    final type = _type;
    final capacity = double.tryParse(_capacityCtrl.text.trim());
    final condition = int.tryParse(_conditionCtrl.text.trim());

    if (type == null || capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại pin và nhập dung lượng hợp lệ.'),
        ),
      );
      return;
    }

    if (condition == null || condition < 0 || condition > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tình trạng pin từ 0-100.')),
      );
      return;
    }

    setState(() => _isSuggestingPrice = true);

    try {
      final service = ref.read(batteryServiceProvider);
      final response = await service.suggestPrice(
        type: type,
        capacity: capacity,
        condition: condition,
      );
      final suggested = response['suggestedPrice'];

      if (suggested is num) {
        final priceValue = suggested.round();
        _priceCtrl.text = priceValue.toString();
        _lastSuggestedPrice = priceValue.toDouble();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gợi ý giá thành công: ${priceValue.toString()} VNĐ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        final message = response['message'] as String? ?? 'Chưa đủ dữ liệu so sánh trên thị trường để gợi ý giá trị.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.amber.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        String userFriendlyError = 'Không thể kết nối đến hệ thống gợi ý giá.';
        if (error is DioException) {
          final response = error.response;
          if (response != null && response.data is Map) {
            final data = response.data as Map;
            if (data.containsKey('message')) {
              final msg = data['message'];
              if (msg is List) {
                userFriendlyError = msg.join('\n');
              } else if (msg is String) {
                userFriendlyError = msg;
              }
            }
          } else if (error.type == DioExceptionType.connectionTimeout ||
                     error.type == DioExceptionType.receiveTimeout) {
            userFriendlyError = 'Kết nối mạng quá hạn. Vui lòng kiểm tra lại đường truyền.';
          }
        }

        userFriendlyError = userFriendlyError
            .replaceAll('capacity must not be greater than 1000', 'Dung lượng pin tối đa được phép gợi ý là 1000 kWh')
            .replaceAll('capacity must not be less than 0.1', 'Dung lượng pin không được nhỏ hơn 0.1 kWh')
            .replaceAll('condition must not be greater than 100', 'Tình trạng pin không được lớn hơn 100%')
            .replaceAll('condition must not be less than 0', 'Tình trạng pin không được nhỏ hơn 0%');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userFriendlyError,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSuggestingPrice = false);
      }
    }
  }

  String _buildDescription(UserModel? user) {
    final phone = user?.phone ?? '';
    final email = user?.email ?? '';
    final contact = [
      if (phone.isNotEmpty) 'Liên hệ: $phone',
      if (email.isNotEmpty) email,
    ].join(' | ');

    if (contact.isEmpty) {
      return _descriptionCtrl.text.trim();
    }

    return '${_descriptionCtrl.text.trim()}\n\n$contact';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng bán pin điện')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.grey200),
                ),
                child: const Text(
                  'Nhập thông tin pin để đăng bán. Số điện thoại và Email sẽ tự động đính kèm từ tài khoản của bạn.',
                  style: TextStyle(color: AppTheme.grey600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Image Upload Section (AT THE VERY TOP)
              Text(
                'Hình ảnh sản phẩm *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.grey800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map(
                    (file) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb 
                        ? Image.network(
                            file.path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(file.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.grey200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppTheme.grey400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Product Information
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên pin *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Loại pin *'),
                items: const [
                  DropdownMenuItem(
                    value: 'LITHIUM_ION',
                    child: Text('Lithium-Ion'),
                  ),
                  DropdownMenuItem(
                    value: 'LITHIUM_POLYMER',
                    child: Text('Lithium Polymer'),
                  ),
                  DropdownMenuItem(
                    value: 'NICKEL_METAL_HYDRIDE',
                    child: Text('NiMH'),
                  ),
                  DropdownMenuItem(value: 'LEAD_ACID', child: Text('Chì-Axit')),
                ],
                onChanged: (value) => setState(() => _type = value),
                validator: (value) => value == null ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dung lượng (kWh) *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Dung lượng không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tình trạng (%) *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0 || parsed > 100) {
                    return 'Tình trạng 0-100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FormField<String>(
                initialValue: _locationCtrl.text,
                validator: (value) {
                  if (_locationCtrl.text.trim().isEmpty) {
                    return 'Vui lòng chọn địa chỉ đầy đủ';
                  }
                  return null;
                },
                builder: (formState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddressSelector(
                        initialStreetAddress: _streetAddress,
                        initialWard: _ward,
                        initialDistrict: _district,
                        initialProvince: _province,
                        onAddressChanged: ({
                          required streetAddress,
                          required ward,
                          required district,
                          required province,
                        }) {
                          _streetAddress = streetAddress;
                          _ward = ward;
                          _district = district;
                          _province = province;

                          final parts = [streetAddress, ward, district, province]
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final composed = parts.join(', ');
                          _locationCtrl.text = composed;
                          formState.didChange(composed);
                        },
                      ),
                      if (formState.hasError) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            formState.errorText ?? '',
                            style: const TextStyle(color: AppTheme.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 20),

              // 3. Price & AI Suggestion (AT THE BOTTOM, RIGHT ABOVE POST BUTTON)
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Giá bán & Gợi ý từ AI',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.grey800,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá bán (VNĐ) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) return 'Giá không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSuggestingPrice ? null : _suggestPrice,
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                      label: Text(
                        _isSuggestingPrice
                            ? 'Đang tính toán...'
                            : 'Gợi ý giá bằng AI',
                      ),
                    ),
                  ),
                ],
              ),
              if (_lastSuggestedPrice != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Giá gợi ý gần nhất: ${_lastSuggestedPrice!.toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // 4. Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? 'Đang đăng tin...' : 'Đăng bán ngay'),
                ),
              ),
              const SizedBox(height: 120), // Spacing for bottom navigation bar
            ],
          ),
        ),
      ),
    );
  }
}
