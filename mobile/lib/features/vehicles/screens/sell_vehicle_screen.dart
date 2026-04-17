import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/vehicle_service.dart';

class SellVehicleScreen extends ConsumerStatefulWidget {
  const SellVehicleScreen({super.key});

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
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _hasWarranty = false;
  bool _isSubmitting = false;
  final List<File> _images = [];
  final _picker = ImagePicker();

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
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked.map((file) => File(file.path)));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(vehicleServiceProvider);
      final imageUrls = _images.isNotEmpty
          ? await service.uploadListingImages(_images)
          : <String>[];

      final description = _buildDescription();

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
        if (imageUrls.isNotEmpty) 'images': imageUrls,
      };

      await service.createVehicle(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bán xe điện thành công!')),
      );
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

  String _buildDescription() {
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng bán xe điện')),
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
                  'Nhập thông tin xe để đăng bán. Giao diện đã đồng bộ theo web.',
                  style: TextStyle(color: AppTheme.grey600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên xe *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá bán (VNĐ) *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) return 'Giá không hợp lệ';
                  return null;
                },
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
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Khu vực *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
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
                decoration: const InputDecoration(labelText: 'Mô tả *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              Text(
                'Hình ảnh',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
                      child: Image.file(
                        file,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? 'Đang gửi...' : 'Đăng bán'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
