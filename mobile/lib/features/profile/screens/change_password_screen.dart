import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/loading_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ thông tin', isError: true);
      return;
    }
    if (_newCtrl.text.length < 6) {
      _showSnack('Mật khẩu mới ít nhất 6 ký tự', isError: true);
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _showSnack('Xác nhận mật khẩu không khớp', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
            confirmPassword: _confirmCtrl.text,
          );
      _showSnack('Đổi mật khẩu thành công');
      if (mounted) context.pop();
    } catch (e) {
      _showSnack(parseApiError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tạo mật khẩu mới cho tài khoản của bạn',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập mật khẩu hiện tại và mật khẩu mới để hoàn tất.',
              style: TextStyle(color: AppTheme.grey600),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _currentCtrl,
              label: 'Mật khẩu hiện tại',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureCurrent,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _newCtrl,
              label: 'Mật khẩu mới',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscureNew,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                icon: Icon(
                  _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmCtrl,
              label: 'Xác nhận mật khẩu mới',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _submit,
              label: 'Cập nhật mật khẩu',
            ),
          ],
        ),
      ),
    );
  }
}
