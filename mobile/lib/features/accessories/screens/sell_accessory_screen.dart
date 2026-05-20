import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/accessory_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/user_model.dart';

class SellAccessoryScreen extends ConsumerStatefulWidget {
  const SellAccessoryScreen({super.key});

  @override
  ConsumerState<SellAccessoryScreen> createState() =>
      _SellAccessoryScreenState();
}

class _SellAccessoryScreenState extends ConsumerState<SellAccessoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _category;
  String? _condition;
  bool _isSubmitting = false;
  final List<XFile> _images = [];

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
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
      final service = ref.read(accessoryServiceProvider);
      final imageUrls = _images.isNotEmpty
          ? await service.uploadListingImages(_images)
          : <String>[];

      final user = ref.read(currentUserProvider);
      final description = _buildDescription(user);

      final payload = {
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'condition': _condition,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': description,
        'location': _locationCtrl.text.trim(),
        if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
        if (_modelCtrl.text.trim().isNotEmpty)
          'compatibleModel': _modelCtrl.text.trim(),
        if (imageUrls.isNotEmpty) 'images': imageUrls,
      };

      await service.createAccessory(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bán phụ kiện thành công!')),
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
      appBar: AppBar(title: const Text('Đăng bán phụ kiện')),
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
                  'Nhập thông tin phụ kiện để đăng bán. Số điện thoại và Email sẽ tự động đính kèm từ tài khoản của bạn.',
                  style: TextStyle(color: AppTheme.grey600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Image Upload Section (AT THE VERY TOP)
              Text(
                'Hình ảnh sản phẩm *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey800,
                  fontSize: 15,
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
                decoration: const InputDecoration(labelText: 'Tên phụ kiện *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Danh mục *'),
                items: const [
                  DropdownMenuItem(value: 'CHARGER', child: Text('Bộ sạc')),
                  DropdownMenuItem(value: 'TIRE', child: Text('Lốp xe')),
                  DropdownMenuItem(value: 'INTERIOR', child: Text('Nội thất')),
                  DropdownMenuItem(
                    value: 'EXTERIOR',
                    child: Text('Ngoại thất'),
                  ),
                  DropdownMenuItem(
                    value: 'ELECTRONICS',
                    child: Text('Điện - điện tử'),
                  ),
                  DropdownMenuItem(value: 'SAFETY', child: Text('An toàn')),
                  DropdownMenuItem(
                    value: 'MAINTENANCE',
                    child: Text('Bảo dưỡng'),
                  ),
                  DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                ],
                onChanged: (value) => setState(() => _category = value),
                validator: (value) => value == null ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(labelText: 'Tình trạng *'),
                items: const [
                  DropdownMenuItem(value: 'New', child: Text('Mới')),
                  DropdownMenuItem(value: 'Like New', child: Text('Như mới')),
                  DropdownMenuItem(value: 'Good', child: Text('Tốt')),
                  DropdownMenuItem(
                    value: 'Used',
                    child: Text('Đã qua sử dụng'),
                  ),
                ],
                onChanged: (value) => setState(() => _condition = value),
                validator: (value) => value == null ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Thương hiệu'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dòng xe tương thích',
                ),
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
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 20),

              // 3. Price (AT THE BOTTOM, RIGHT ABOVE POST BUTTON)
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Giá bán',
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
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 24),

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
