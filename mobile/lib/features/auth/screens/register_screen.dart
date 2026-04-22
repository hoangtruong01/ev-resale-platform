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
        SnackBar(
          content: const Text('Vui lòng đồng ý với điều khoản sử dụng'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await ref
        .read(authStateProvider.notifier)
        .register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    final authState = ref.read(authStateProvider).value;
    if (authState?.isAuthenticated == true) {
      context.go('/');
    } else if (authState?.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState!.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEFFCF3),
                  Colors.white,
                  Color(0xFFFFF7ED),
                ],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Custom Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.grey900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Header
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tạo tài khoản',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentOrange,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Bắt đầu mua bán pin xe điện an toàn và thuận tiện',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Register Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.grey200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Họ và tên',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _fullNameCtrl,
                            hint: 'Nhập họ và tên',
                            prefixIcon: Icons.person_outline,
                            forceLightStyle: true,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Nhập họ và tên';
                              if (v.length < 2) return 'Tên quá ngắn';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _emailCtrl,
                            hint: 'email@example.com',
                            prefixIcon: Icons.email_outlined,
                            forceLightStyle: true,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nhập email';
                              if (!v.contains('@')) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Số điện thoại',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _phoneCtrl,
                            hint: '09xxxxxxx',
                            prefixIcon: Icons.phone_outlined,
                            forceLightStyle: true,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Nhập số điện thoại';
                              if (!RegExp(
                                r'^(0|\+84)[3-9]\d{8}$',
                              ).hasMatch(v)) {
                                return 'SĐT không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Mật khẩu',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _passwordCtrl,
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            forceLightStyle: true,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.grey400,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Nhập mật khẩu';
                              if (v.length < 6)
                                return 'Mật khẩu ít nhất 6 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Xác nhận mật khẩu',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _confirmCtrl,
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            forceLightStyle: true,
                            obscureText: _obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.grey400,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Xác nhận mật khẩu';
                              if (v != _passwordCtrl.text)
                                return 'Mật khẩu không khớp';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Terms Checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (v) => setState(
                                    () => _agreedToTerms = v ?? false,
                                  ),
                                  activeColor: AppTheme.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _agreedToTerms = !_agreedToTerms,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: AppTheme.grey600,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Tôi đồng ý với '),
                                        TextSpan(
                                          text: 'Điều khoản',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const TextSpan(text: ' & '),
                                        TextSpan(
                                          text: 'Bảo mật',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          LoadingButton(
                            isLoading: _isLoading,
                            onPressed: _register,
                            label: 'Tạo tài khoản',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: const TextStyle(color: AppTheme.grey600),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            color: AppTheme.accentYellow,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
