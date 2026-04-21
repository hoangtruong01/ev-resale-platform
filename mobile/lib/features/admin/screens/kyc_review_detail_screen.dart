import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

/// Screen for Admin to review an individual KYC request with full images.
class KycReviewDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic> profileData;

  const KycReviewDetailScreen({
    super.key,
    required this.userId,
    required this.profileData,
  });

  @override
  ConsumerState<KycReviewDetailScreen> createState() =>
      _KycReviewDetailScreenState();
}

class _KycReviewDetailScreenState extends ConsumerState<KycReviewDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(String decision) async {
    if (_isSubmitting) return;

    if (decision == 'REJECTED' && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập lý do từ chối.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/users/kyc/${widget.userId}/review',
        data: {'decision': decision, 'notes': _notesController.text.trim()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'APPROVED'
                  ? 'Đã duyệt thành công!'
                  : 'Đã từ chối yêu cầu.',
            ),
            backgroundColor: decision == 'APPROVED'
                ? AppTheme.success
                : AppTheme.orange500,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.response?.data['message'] ?? e.message}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.profileData['user'] as Map<String, dynamic>?;
    final fullName = user?['fullName'] ?? 'Người dùng';
    final idNumber = widget.profileData['idNumber'] ?? 'Chưa cung cấp';
    final idType = widget.profileData['idType'] ?? 'CMND/CCCD';
    final idFrontImage = widget.profileData['idFrontImage'];
    final idBackImage = widget.profileData['idBackImage'];
    final faceImage = widget.profileData['faceImage'];

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Chi tiết phê duyệt KYC'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.grey900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header Info
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: user?['avatar'] != null
                        ? NetworkImage(user!['avatar'])
                        : null,
                    child: user?['avatar'] == null
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: AppTheme.primaryGreen,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.grey900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $idNumber ($idType)',
                          style: const TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['email'] ?? 'Không có email',
                          style: const TextStyle(
                            color: AppTheme.grey500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Document Images
            _buildSectionHeader('Hình ảnh tài liệu'),
            _buildImageCard('Mặt trước CMND/CCCD', idFrontImage),
            _buildImageCard('Mặt sau CMND/CCCD', idBackImage),
            _buildImageCard('Ảnh chụp khuôn mặt', faceImage),

            const SizedBox(height: 12),

            // Decision Area
            _buildSectionHeader('Quyết định phê duyệt'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ghi chú (Bắt buộc nếu từ chối)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.grey700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhập ghi chú hoặc lý do từ chối...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.grey200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      fillColor: AppTheme.grey50,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitDecision('REJECTED'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Từ chối',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitDecision('APPROVED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Duyệt ngay',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.grey500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.grey800,
              ),
            ),
          ),
          if (imageUrl != null)
            GestureDetector(
              onTap: () => _showFullScreenImage(imageUrl),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Image.network(
                  _getFullUrl(imageUrl),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: AppTheme.grey100,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.grey400,
                        size: 40,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: AppTheme.grey100,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Không có hình ảnh',
                  style: TextStyle(color: AppTheme.grey400, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getFullUrl(String path) {
    // If it's already a full URL, return it
    if (path.startsWith('http')) return path;

    final origin = AppConstants.baseUrl.replaceAll('/api', '');
    return '$origin${path.startsWith('/') ? '' : '/'}$path';
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      _getFullUrl(imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
