import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/loading_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản sử dụng'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(authStateProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    final authState = ref.read(authStateProvider).value;
    if (authState?.isAuthenticated == true) {
      context.go('/');
    } else if (authState?.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState!.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.grey900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đăng ký',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tạo tài khoản để bắt đầu mua bán pin xe điện',
                style: TextStyle(color: AppTheme.grey600),
              ),
              const SizedBox(height: 28),

              AppTextField(
                controller: _fullNameCtrl,
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập họ và tên';
                  if (v.length < 2) return 'Tên quá ngắn';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'email@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập email';
                  if (!v.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _phoneCtrl,
                label: 'Số điện thoại',
                hint: '0912345678',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập số điện thoại';
                  if (!RegExp(r'^(0|\+84)[3-9]\d{8}$').hasMatch(v)) {
                    return 'SĐT không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordCtrl,
                label: 'Mật khẩu',
                hint: 'Ít nhất 6 ký tự',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.grey400,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                  if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.grey400,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Xác nhận mật khẩu';
                  if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Terms Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                    activeColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              color: AppTheme.grey600, fontSize: 14),
                          children: [
                            const TextSpan(text: 'Tôi đồng ý với '),
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' và '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              LoadingButton(
                isLoading: _isLoading,
                onPressed: _register,
                label: 'Tạo tài khoản',
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: AppTheme.grey600),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
