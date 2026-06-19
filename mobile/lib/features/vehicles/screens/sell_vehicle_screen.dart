import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/vehicle_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/vehicle_model.dart';

import '../../../widgets/address_selector.dart';

class SellVehicleScreen extends ConsumerStatefulWidget {
  final VehicleModel? initialVehicle;
  const SellVehicleScreen({super.key, this.initialVehicle});

  @override
  ConsumerState<SellVehicleScreen> createState() => _SellVehicleScreenState();
}

class _SellVehicleScreenState extends ConsumerState<SellVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _transmissionCtrl = TextEditingController();
  final _seatCountCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _streetAddress = '';
  String _ward = '';
  String _district = '';
  String _province = '';

  bool _hasWarranty = false;
  bool _isSubmitting = false;
  bool _isSuggestingPrice = false;
  double? _lastSuggestedPrice;
  final List<XFile> _images = [];
  // Existing image URLs from initialVehicle (kept when editing)
  List<String> _existingImageUrls = [];
  final _picker = ImagePicker();

  bool get _isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;
    if (v != null) {
      _nameCtrl.text = v.name;
      _priceCtrl.text = v.price.toStringAsFixed(0);
      _brandCtrl.text = v.brand;
      _modelCtrl.text = v.model;
      _yearCtrl.text = v.year.toString();
      _conditionCtrl.text = v.condition;
      _locationCtrl.text = v.location;
      _colorCtrl.text = v.color ?? '';
      _transmissionCtrl.text = v.transmission ?? '';
      _seatCountCtrl.text = v.seatCount?.toString() ?? '';
      _mileageCtrl.text = v.mileage?.toString() ?? '';
      _descriptionCtrl.text = v.description ?? '';
      _hasWarranty = v.hasWarranty ?? false;
      _existingImageUrls = List<String>.from(v.images);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _conditionCtrl.dispose();
    _locationCtrl.dispose();
    _colorCtrl.dispose();
    _transmissionCtrl.dispose();
    _seatCountCtrl.dispose();
    _mileageCtrl.dispose();
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
      final service = ref.read(vehicleServiceProvider);
      final newImageUrls = _images.isNotEmpty
          ? await service.uploadListingImages(_images)
          : <String>[];

      // Merge: keep existing + add newly picked
      final allImages = [..._existingImageUrls, ...newImageUrls];

      final user = ref.read(currentUserProvider);
      final description = _buildDescription(user);

      final payload = {
        'name': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'year': int.tryParse(_yearCtrl.text.trim()) ?? 0,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'condition': _conditionCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'transmission': _transmissionCtrl.text.trim(),
        'seatCount': int.tryParse(_seatCountCtrl.text.trim()) ?? 0,
        'hasWarranty': _hasWarranty,
        'description': description,
        if (_mileageCtrl.text.trim().isNotEmpty)
          'mileage': int.tryParse(_mileageCtrl.text.trim()),
        if (allImages.isNotEmpty) 'images': allImages,
      };

      if (_isEditing) {
        await service.updateVehicle(widget.initialVehicle!.id, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật tin đăng thành công!')),
        );
      } else {
        await service.createVehicle(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng bán xe điện thành công!')),
        );
      }
      Navigator.pop(context, _isEditing);
    } catch (error) {
      if (!mounted) return;
      final msg = _parseError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gửi yêu cầu đăng bán thành công! Vui lòng đợi Admin duyệt để tin được hiển thị.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _parseError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join('\n');
        if (msg is String) return msg;
      }
    }
    return 'Có lỗi xảy ra: $error';
  }

  Future<void> _suggestPrice() async {
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final year = int.tryParse(_yearCtrl.text.trim());
    final condition = _conditionCtrl.text.trim();
    final mileage = int.tryParse(_mileageCtrl.text.trim());

    if (brand.isEmpty || model.isEmpty || year == null || condition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập hãng, dòng xe, năm và tình trạng để gợi ý giá.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSuggestingPrice = true);

    try {
      final service = ref.read(vehicleServiceProvider);
      final response = await service.suggestPrice(
        brand: brand,
        model: model,
        year: year,
        condition: condition,
        mileage: mileage,
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
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        final message =
            response['message'] as String? ??
            'Chưa đủ dữ liệu so sánh trên thị trường để gợi ý giá trị.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            userFriendlyError =
                'Kết nối mạng quá hạn. Vui lòng kiểm tra lại đường truyền.';
          }
        }

        userFriendlyError = userFriendlyError
            .replaceAll(
              'year must not be greater than',
              'Năm sản xuất không được lớn hơn',
            )
            .replaceAll(
              'year must not be less than 2000',
              'Năm sản xuất không được nhỏ hơn năm 2000',
            )
            .replaceAll(
              'mileage must not be greater than',
              'Số km đã đi không được lớn hơn',
            )
            .replaceAll(
              'mileage must not be less than 0',
              'Số km đã đi không được nhỏ hơn 0',
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa tin đăng' : 'Đăng bán xe điện'),
      ),
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
                  'Nhập thông tin xe để đăng bán. Số điện thoại và Email sẽ tự động đính kèm từ tài khoản của bạn.',
                  style: TextStyle(color: AppTheme.grey600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Image Upload Section (AT THE VERY TOP)
              Text(
                'Hình ảnh xe *',
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
                decoration: const InputDecoration(labelText: 'Tên xe *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Hãng xe *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(labelText: 'Dòng xe *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Năm sản xuất *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bắt buộc';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 2000) {
                    return 'Năm không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionCtrl,
                decoration: const InputDecoration(labelText: 'Tình trạng *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
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
                        onAddressChanged:
                            ({
                              required streetAddress,
                              required ward,
                              required district,
                              required province,
                            }) {
                              _streetAddress = streetAddress;
                              _ward = ward;
                              _district = district;
                              _province = province;

                              final parts =
                                  [streetAddress, ward, district, province]
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
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(labelText: 'Màu sắc *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transmissionCtrl,
                decoration: const InputDecoration(labelText: 'Truyền động *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _seatCountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số chỗ ngồi *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bắt buộc';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Số chỗ không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Odo (km)'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _hasWarranty,
                onChanged: (value) => setState(() => _hasWarranty = value),
                title: const Text('Còn bảo hành'),
                contentPadding: EdgeInsets.zero,
              ),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết *',
                ),
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
              const SizedBox(height: 24),

              // 4. Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(
                    _isSubmitting
                        ? (_isEditing ? 'Đang cập nhật...' : 'Đang đăng tin...')
                        : (_isEditing ? 'Cập nhật tin đăng' : 'Đăng bán ngay'),
                  ),
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
