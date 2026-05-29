import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auction_service.dart';
import '../../../widgets/address_selector.dart';

class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _bidStepController = TextEditingController();
  final _buyNowPriceController = TextEditingController();
  final _lotQuantityController = TextEditingController(text: '1');
  final _itemBrandController = TextEditingController();
  final _itemModelController = TextEditingController();
  final _itemYearController = TextEditingController();
  final _itemCapacityController = TextEditingController();
  final _itemConditionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  String _streetAddress = '';
  String _ward = '';
  String _district = '';
  String _province = '';

  final List<XFile> _images = [];
  final _picker = ImagePicker();

  String _itemType = 'BATTERY';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _bidStepController.dispose();
    _buyNowPriceController.dispose();
    _lotQuantityController.dispose();
    _itemBrandController.dispose();
    _itemModelController.dispose();
    _itemYearController.dispose();
    _itemCapacityController.dispose();
    _itemConditionController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked);
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startTime ?? now.add(const Duration(minutes: 10)))
        : (_endTime ?? (_startTime?.add(const Duration(hours: 2)) ?? now.add(const Duration(hours: 2))));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  int? _parseInt(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  double? _parseDouble(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc.')),
      );
      return;
    }

    if (!_endTime!.isAfter(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu.')),
      );
      return;
    }

    final startingPrice = _parseDouble(_startingPriceController.text);
    final bidStep = _parseDouble(_bidStepController.text);
    final lotQuantity = _parseInt(_lotQuantityController.text);
    if (startingPrice == null || bidStep == null || lotQuantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá khởi điểm, bước giá và số lượng phải hợp lệ.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auctionService = ref.read(auctionServiceProvider);
      
      // Upload images first
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await auctionService.uploadListingImages(_images);
      }

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'startingPrice': startingPrice,
        'bidStep': bidStep,
        'buyNowPrice': _parseDouble(_buyNowPriceController.text),
        'startTime': _startTime!.toIso8601String(),
        'endTime': _endTime!.toIso8601String(),
        'itemType': _itemType,
        'lotQuantity': lotQuantity,
        'itemBrand': _itemBrandController.text.trim().isEmpty
            ? null
            : _itemBrandController.text.trim(),
        'itemModel': _itemModelController.text.trim().isEmpty
            ? null
            : _itemModelController.text.trim(),
        'itemYear': _parseInt(_itemYearController.text),
        'itemCapacity': _parseInt(_itemCapacityController.text),
        'itemCondition': _parseInt(_itemConditionController.text),
        'location': _locationController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'contactEmail': _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        'imageUrls': imageUrls,
      };

      payload.removeWhere((key, value) => value == null);

      await auctionService.createAuction(payload);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo đấu giá thành công, đang chờ duyệt.')),
      );
      context.go('/auctions');
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parseApiError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Chưa chọn';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/${value.year}';
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Trường này là bắt buộc';
              }
              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo đấu giá mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Tiêu đề', _titleController, required: true),
            const SizedBox(height: 12),
            _buildTextField(
              'Mô tả',
              _descriptionController,
              maxLines: 3,
              hint: 'Mô tả tình trạng, điểm nổi bật của sản phẩm',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _itemType,
              decoration: const InputDecoration(labelText: 'Loại sản phẩm'),
              items: const [
                DropdownMenuItem(value: 'BATTERY', child: Text('Pin điện')),
                DropdownMenuItem(value: 'VEHICLE', child: Text('Xe điện')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _itemType = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Giá khởi điểm (VND)',
                    _startingPriceController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'Bước giá (VND)',
                    _bidStepController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Giá mua ngay (VND)',
                    _buyNowPriceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'Số lượng lô',
                    _lotQuantityController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickDateTime(isStart: true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Bắt đầu: ${_formatDateTime(_startTime)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickDateTime(isStart: false),
                    icon: const Icon(Icons.timer_off_outlined),
                    label: Text('Kết thúc: ${_formatDateTime(_endTime)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField('Thương hiệu', _itemBrandController),
            const SizedBox(height: 12),
            _buildTextField('Model', _itemModelController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Năm sản xuất',
                    _itemYearController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'Dung lượng',
                    _itemCapacityController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Tình trạng (%)',
              _itemConditionController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            FormField<String>(
              initialValue: _locationController.text,
              validator: (value) {
                if (_locationController.text.trim().isEmpty) {
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
                        _locationController.text = composed;
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
            _buildTextField(
              'Số điện thoại liên hệ',
              _contactPhoneController,
              required: true,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Email liên hệ',
              _contactEmailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hình ảnh sản phẩm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
                InkWell(
                  onTap: _isSubmitting ? null : _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.grey500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.gavel_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              label: Text(_isSubmitting ? 'Đang gửi...' : 'Tạo đấu giá'),
            ),
          ],
        ),
      ),
    );
  }
}
