import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

// ─── KYC Status Provider ─────────────────────────────────────────────────────

final kycStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users/kyc/status');
  return Map<String, dynamic>.from(res.data as Map);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberCtrl = TextEditingController();
  final _issuePlaceCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();

  String _idType = 'CCCD';
  DateTime? _issueDate;
  File? _frontImage;
  File? _backImage;
  File? _faceImage;
  bool _isSubmitting = false;
  String? _errorMsg;
  String? _successMsg;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _issuePlaceCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String slot) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      if (slot == 'front') _frontImage = file;
      if (slot == 'back') _backImage = file;
      if (slot == 'face') _faceImage = file;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frontImage == null) {
      setState(() => _errorMsg = 'Vui lòng chọn ảnh mặt trước CMND/CCCD');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
      _successMsg = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'idNumber': _idNumberCtrl.text.trim(),
        'idType': _idType,
        'fullNameOnId': _fullNameCtrl.text.trim().isNotEmpty ? _fullNameCtrl.text.trim() : null,
        'idIssuePlace': _issuePlaceCtrl.text.trim().isNotEmpty ? _issuePlaceCtrl.text.trim() : null,
        if (_issueDate != null) 'idIssueDate': _issueDate!.toIso8601String(),
        'images': [
          await MultipartFile.fromFile(_frontImage!.path, filename: 'front.jpg'),
          if (_backImage != null)
            await MultipartFile.fromFile(_backImage!.path, filename: 'back.jpg'),
          if (_faceImage != null)
            await MultipartFile.fromFile(_faceImage!.path, filename: 'face.jpg'),
        ],
      });

      await dio.post('/users/kyc/submit', data: formData);

      setState(() {
        _successMsg = 'Đã nộp hồ sơ! Vui lòng chờ xét duyệt (1–3 ngày làm việc).';
        _isSubmitting = false;
      });

      ref.invalidate(kycStatusProvider);
    } on DioException catch (e) {
      setState(() {
        _errorMsg = parseApiError(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycStatus = ref.watch(kycStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Xác thực danh tính (eKYC)'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.grey900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: kycStatus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildForm(),
        data: (data) {
          final status = data['kycStatus'] as String? ?? 'UNVERIFIED';
          if (status == 'APPROVED') return _buildApprovedView();
          if (status == 'PENDING') return _buildPendingView();
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildApprovedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded,
                  size: 56, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Danh tính đã xác thực',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tài khoản đã được xác thực danh tính thành công. Bạn có thể ký hợp đồng số.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 56, color: AppTheme.warning),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang chờ xét duyệt',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hồ sơ xác thực đã được nộp và đang chờ quản trị viên xét duyệt. Thường mất 1–3 ngày làm việc.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            _InfoBanner(),
            const SizedBox(height: 20),

            // Step 1: ID info
            _SectionLabel(step: '1', label: 'Thông tin giấy tờ tùy thân'),
            const SizedBox(height: 12),

            // ID Type selector
            Row(
              children: ['CCCD', 'CMND', 'PASSPORT'].map((type) {
                final selected = _idType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _idType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.primaryGreen : AppTheme.grey200,
                        ),
                      ),
                      child: Text(
                        type,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected ? Colors.white : AppTheme.grey600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _idNumberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số CMND/CCCD/Hộ chiếu *',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ tên đầy đủ (như trên giấy tờ)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),

            // Issue date picker
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Ngày cấp',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText: _issueDate != null
                        ? '${_issueDate!.day.toString().padLeft(2, '0')}/'
                            '${_issueDate!.month.toString().padLeft(2, '0')}/'
                            '${_issueDate!.year}'
                        : 'Chọn ngày cấp',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _issuePlaceCtrl,
              decoration: const InputDecoration(
                labelText: 'Nơi cấp',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Photos
            _SectionLabel(step: '2', label: 'Chụp/tải ảnh giấy tờ'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ImagePickerCard(
                    label: 'Mặt trước *',
                    image: _frontImage,
                    icon: Icons.credit_card,
                    onTap: () => _pickImage('front'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImagePickerCard(
                    label: 'Mặt sau',
                    image: _backImage,
                    icon: Icons.credit_card_two_tone_outlined,
                    onTap: () => _pickImage('back'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selfie card
            _ImagePickerCard(
              label: 'Ảnh chân dung (selfie)',
              image: _faceImage,
              icon: Icons.face_outlined,
              onTap: () => _pickImage('face'),
              fullWidth: true,
            ),
            const SizedBox(height: 24),

            // Error/success messages
            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMsg!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            if (_successMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_successMsg!,
                          style: const TextStyle(color: AppTheme.success, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: AppTheme.primaryGreen,
                disabledBackgroundColor: AppTheme.grey200,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Nộp hồ sơ xác thực',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime(2020),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _issueDate = date);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.08),
            AppTheme.primaryGreen.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Xác thực danh tính là bắt buộc trước khi ký hợp đồng số. '
              'Thông tin sẽ được bảo mật và chỉ dùng cho mục đích pháp lý.',
              style: TextStyle(fontSize: 13, color: AppTheme.grey700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String step;
  final String label;
  const _SectionLabel({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey900)),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final String label;
  final File? image;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ImagePickerCard({
    required this.label,
    required this.image,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: fullWidth ? 120 : 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? AppTheme.primaryGreen : AppTheme.grey200,
            width: image != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: AppTheme.grey400),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhấn để chọn ảnh',
                    style: TextStyle(fontSize: 11, color: AppTheme.grey400),
                  ),
                ],
              ),
      ),
    );
  }
}
