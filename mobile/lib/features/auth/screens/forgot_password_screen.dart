import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/loading_button.dart';
import '../../../core/network/dio_client.dart';

// Steps: 1=email, 2=OTP, 3=new password
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 1;
  bool _isLoading = false;
  String? _resetId;
  String? _resetToken;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      _showSnack('Nhập email hợp lệ', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      final result = await service.forgotPassword(_emailCtrl.text.trim());
      _resetId = result['data']?['id'];
      setState(() => _step = 2);
      _startResendCountdown();
      _showSnack('OTP đã được gửi đến email của bạn');
    } catch (e) {
      _showSnack(parseApiError(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
        return;
      }
      setState(() => _resendCountdown -= 1);
    });
  }

  Future<void> _resendOtp() async {
    if (_resetId == null) {
      _showSnack('Không tìm thấy yêu cầu đặt lại mật khẩu', isError: true);
      return;
    }
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      await service.resendOtp(resetId: _resetId!);
      _startResendCountdown();
      _showSnack('OTP mới đã được gửi đến email của bạn');
    } catch (e) {
      _showSnack(parseApiError(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length != 6) {
      _showSnack('Nhập OTP 6 chữ số', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      final result = await service.verifyOtp(
        resetId: _resetId!,
        otp: _otpCtrl.text.trim(),
      );
      _resetToken = result['data']?['resetToken'];
      setState(() => _step = 3);
    } catch (e) {
      _showSnack(parseApiError(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordCtrl.text.length < 6) {
      _showSnack('Mật khẩu ít nhất 6 ký tự', isError: true);
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showSnack('Mật khẩu không khớp', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      await service.resetPassword(
        resetId: _resetId!,
        resetToken: _resetToken!,
        password: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      _showSnack('Đổi mật khẩu thành công!');
      if (mounted) context.go('/auth/login');
    } catch (e) {
      _showSnack(parseApiError(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Indicator
            Row(
              children: List.generate(3, (i) {
                final active = i + 1 <= _step;
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? AppTheme.primaryGreen : AppTheme.grey200,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: active ? Colors.white : AppTheme.grey400,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (i < 2)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i + 1 < _step
                                ? AppTheme.primaryGreen
                                : AppTheme.grey200,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            if (_step == 1) ...[
              const Text('Nhập email của bạn',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                  'Chúng tôi sẽ gửi mã OTP 6 số đến email của bạn',
                  style: TextStyle(color: AppTheme.grey600)),
              const SizedBox(height: 24),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'email@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _requestOtp,
                label: 'Gửi mã OTP',
              ),
            ],

            if (_step == 2) ...[
              const Text('Nhập mã OTP',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  'Mã OTP đã được gửi đến ${_emailCtrl.text}',
                  style: const TextStyle(color: AppTheme.grey600)),
              const SizedBox(height: 24),
              AppTextField(
                controller: _otpCtrl,
                label: 'Mã OTP (6 số)',
                hint: '123456',
                prefixIcon: Icons.security_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _verifyOtp,
                label: 'Xác thực OTP',
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    _resendCountdown > 0 || _isLoading ? null : _resendOtp,
                child: Text(
                  _resendCountdown > 0
                      ? 'Gửi lại OTP sau $_resendCountdown s'
                      : 'Gửi lại OTP',
                  style: const TextStyle(color: AppTheme.primaryGreen),
                ),
              ),
            ],

            if (_step == 3) ...[
              const Text('Đặt mật khẩu mới',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Nhập mật khẩu mới cho tài khoản của bạn',
                  style: TextStyle(color: AppTheme.grey600)),
              const SizedBox(height: 24),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Mật khẩu mới',
                hint: 'Ít nhất 6 ký tự',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _resetPassword,
                label: 'Đổi mật khẩu',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
