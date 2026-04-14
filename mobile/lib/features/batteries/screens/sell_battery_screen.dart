import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/battery_service.dart';

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
  final _voltageCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _type;
  bool _isSubmitting = false;
  bool _isSuggestingPrice = false;
  double? _lastSuggestedPrice;
  final List<File> _images = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _voltageCtrl.dispose();
    _conditionCtrl.dispose();
    _locationCtrl.dispose();
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
      final service = ref.read(batteryServiceProvider);
      final imageUrls = _images.isNotEmpty
          ? await service.uploadListingImages(_images)
          : <String>[];

      final description = _buildDescription();

      final payload = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'capacity': double.tryParse(_capacityCtrl.text.trim()) ?? 0,
        'condition': int.tryParse(_conditionCtrl.text.trim()) ?? 0,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': description,
        'location': _locationCtrl.text.trim(),
        if (_voltageCtrl.text.trim().isNotEmpty)
          'voltage': double.tryParse(_voltageCtrl.text.trim()),
        if (imageUrls.isNotEmpty) 'images': imageUrls,
      };

      await service.createBattery(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bán pin thành công!')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $error')),
      );
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
        const SnackBar(content: Text('Vui lòng chọn loại pin và nhập dung lượng hợp lệ.')),
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
            SnackBar(content: Text('Gợi ý giá: ${priceValue.toString()} VNĐ')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được giá gợi ý.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gợi ý giá: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSuggestingPrice = false);
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
      appBar: AppBar(title: const Text('Đăng bán pin điện')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên pin *'),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSuggestingPrice ? null : _suggestPrice,
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                      label: Text(_isSuggestingPrice
                          ? 'Đang gợi ý...'
                          : 'Gợi ý giá từ AI'),
                    ),
                  ),
                ],
              ),
              if (_lastSuggestedPrice != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Giá gợi ý gần nhất: ${_lastSuggestedPrice!.toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(color: AppTheme.grey600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Loại pin *'),
                items: const [
                  DropdownMenuItem(value: 'LITHIUM_ION', child: Text('Lithium-Ion')),
                  DropdownMenuItem(value: 'LITHIUM_POLYMER', child: Text('Lithium Polymer')),
                  DropdownMenuItem(value: 'NICKEL_METAL_HYDRIDE', child: Text('NiMH')),
                  DropdownMenuItem(value: 'LEAD_ACID', child: Text('Chì-Axit')),
                ],
                onChanged: (value) => setState(() => _type = value),
                validator: (value) => value == null ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dung lượng (kWh) *'),
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
                controller: _voltageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Điện áp (V)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tình trạng (%) *'),
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
              Text('Hình ảnh',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.grey800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map(
                    (file) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file,
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  ),
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.grey200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: AppTheme.grey400),
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
