import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/loading_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await ref
        .read(authStateProvider.notifier)
        .login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    final authState = ref.read(authStateProvider).value;
    if (authState?.isAuthenticated == true) {
      context.go('/');
    } else if (authState?.error != null) {
      _showError(authState!.error!);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    final authState = ref.read(authStateProvider).value;
    if (authState?.isAuthenticated == true) {
      context.go('/');
      return;
    }
    if (authState?.error != null) {
      _showError(authState!.error!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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

          // Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Logo & Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('⚡', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 8),
                      Text(
                        'EVN Market',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.grey900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chào mừng quay lại',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập để tiếp tục giao dịch an toàn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.grey600,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Login Card
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
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _emailCtrl,
                            hint: 'Nhập email của bạn',
                            prefixIcon: Icons.email_outlined,
                            forceLightStyle: true,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nhập email';
                              if (!v.contains('@')) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
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
                            hint: 'Nhập mật khẩu',
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/auth/forgot-password'),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          LoadingButton(
                            isLoading: _isLoading,
                            onPressed: _login,
                            label: 'Đăng nhập',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppTheme.grey300),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'hoặc tiếp tục với',
                          style: TextStyle(
                            color: AppTheme.grey500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppTheme.grey300),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Sign In
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.grey900,
                        side: const BorderSide(color: AppTheme.grey300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isGoogleLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen,
                                ),
                              ),
                            )
                          else ...[
                            const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 30,
                              color: Color(0xFF4285F4),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Đăng nhập với Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grey900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bạn mới biết EVN? ',
                        style: const TextStyle(color: AppTheme.grey600),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/auth/register'),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppTheme.accentYellow,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
