import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/sepay_payment.dart';
import '../services/payment_service.dart';

class SepayPaymentScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final double amount;
  final String paymentType;

  const SepayPaymentScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.paymentType,
  });

  @override
  ConsumerState<SepayPaymentScreen> createState() => _SepayPaymentScreenState();
}

class _SepayPaymentScreenState extends ConsumerState<SepayPaymentScreen>
    with TickerProviderStateMixin {
  SepayPayment? _payment;
  bool _loading = true;
  String? _error;

  Timer? _pollingTimer;
  Timer? _countdownTimer;
  Duration _remaining = const Duration(minutes: 15);
  bool _checking = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _createPayment();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = ref.read(paymentServiceProvider);
      final payment = await svc.createSepayPayment(
        transactionId: widget.transactionId,
        paymentType: widget.paymentType,
      );
      if (!mounted) return;
      setState(() {
        _payment = payment;
        _loading = false;
        _remaining = payment.expireAt.difference(DateTime.now());
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
      _startCountdown();
      _startPolling(payment.paymentAttemptId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final p = _payment;
      if (p == null) return;
      final rem = p.expireAt.difference(DateTime.now());
      setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
      if (rem.isNegative) {
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
      }
    });
  }

  void _startPolling(String attemptId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus(attemptId);
    });
  }

  Future<void> _checkStatus(String attemptId) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final svc = ref.read(paymentServiceProvider);
      final result = await svc.getSepayStatus(attemptId);
      if (!mounted) return;
      if (result.isSuccess) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        context.pushReplacement(
          '/transactions/${widget.transactionId}/payment/result',
          extra: {'success': true, 'amount': result.amount},
        );
      } else if (result.isFailed) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        context.pushReplacement(
          '/transactions/${widget.transactionId}/payment/result',
          extra: {'success': false, 'amount': result.amount},
        );
      }
    } catch (_) {
      // ignore polling errors silently
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _simulatePayment(bool success) async {
    final p = _payment;
    if (p == null || _checking) return;
    setState(() => _checking = true);
    try {
      final svc = ref.read(paymentServiceProvider);
      await svc.simulateSepayPayment(
        paymentAttemptId: p.paymentAttemptId,
        success: success,
      );
      await _checkStatus(p.paymentAttemptId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi giả lập thanh toán: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatCountdown() {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _countdownColor {
    if (_remaining.inMinutes >= 5) return AppTheme.primaryGreen;
    if (_remaining.inMinutes >= 2) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : const Color(0xFFF0FDF4);
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.grey900;
    final textSecondary = isDark ? Colors.white60 : AppTheme.grey500;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Thanh toán SePay'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        actions: [
          if (_payment != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _countdownColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: _countdownColor),
                      const SizedBox(width: 4),
                      Text(
                        _formatCountdown(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _countdownColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(isDark, cardBg, textPrimary, textSecondary),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Đang tạo mã QR...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _createPayment,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _payment!;
    final isExpired = _remaining == Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Sandbox test panel
          _buildTestModePanel(isDark, p),
          const SizedBox(height: 16),

          // Header info
          _buildHeaderBanner(isDark, p),
          const SizedBox(height: 20),

          // QR Code card
          _buildQrCard(isDark, cardBg, textPrimary, textSecondary, p, isExpired),
          const SizedBox(height: 16),

          // Bank info card
          _buildBankInfoCard(isDark, cardBg, textPrimary, textSecondary, p),
          const SizedBox(height: 16),

          // Transfer content card
          _buildTransferContentCard(isDark, cardBg, textPrimary, p),
          const SizedBox(height: 16),

          // Amount card
          _buildAmountCard(isDark, cardBg, textPrimary, textSecondary, p),
          const SizedBox(height: 24),

          // Check payment button
          if (!isExpired)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checking
                    ? null
                    : () => _checkStatus(p.paymentAttemptId),
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label:
                    Text(_checking ? 'Đang kiểm tra...' : 'Đã chuyển khoản rồi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (isExpired)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _createPayment,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tạo lại mã QR mới'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Steps guide
          _buildStepsGuide(isDark, textPrimary, textSecondary),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTestModePanel(bool isDark, SepayPayment p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'BẢNG THỬ NGHIỆM (TEST MODE)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quét QR thật sẽ chuyển tiền thật! Để kiểm tra luồng Thành công / Thất bại không tốn tiền, hãy bấm nút giả lập bên dưới:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF78350F),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : () => _simulatePayment(true),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Test Thành công'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : () => _simulatePayment(false),
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                  label: const Text('Test Thất bại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark, SepayPayment p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.15),
            AppTheme.primaryGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quét mã QR bằng app ngân hàng bất kỳ để thanh toán. QR có hiệu lực trong 15 phút.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppTheme.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    SepayPayment p,
    bool isExpired,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : AppTheme.grey200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: Color(0xFF0052CC), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mã QR VietQR',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              // Live indicator
              if (!isExpired)
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          // QR image
          if (isExpired)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppTheme.grey100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_off_rounded,
                      size: 48, color: AppTheme.grey400),
                  const SizedBox(height: 8),
                  Text(
                    'QR đã hết hạn',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  p.qrUrl,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 220,
                    height: 220,
                    color: AppTheme.grey100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported_outlined,
                            size: 40, color: AppTheme.grey400),
                        const SizedBox(height: 8),
                        Text(
                          'Không tải được QR',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),
          Text(
            'Hỗ trợ tất cả ngân hàng VN',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),

          // Bank logos row
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BankBadge(name: 'MB', color: const Color(0xFF003087)),
              const SizedBox(width: 8),
              _BankBadge(name: 'VCB', color: const Color(0xFF007A4D)),
              const SizedBox(width: 8),
              _BankBadge(name: 'TCB', color: const Color(0xFFE31C39)),
              const SizedBox(width: 8),
              _BankBadge(name: 'ACB', color: const Color(0xFF0073CF)),
              const SizedBox(width: 8),
              _BankBadge(name: '+20', color: AppTheme.grey500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    SepayPayment p,
  ) {
    return _InfoCard(
      isDark: isDark,
      cardBg: cardBg,
      icon: Icons.account_balance_rounded,
      iconColor: const Color(0xFF0052CC),
      title: 'Thông tin tài khoản',
      children: [
        _InfoRow(
          label: 'Ngân hàng',
          value: p.bankName,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
        ),
        _InfoRow(
          label: 'Số tài khoản',
          value: p.bankAccountNumber,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onCopy: () => _copyToClipboard(p.bankAccountNumber, 'số tài khoản'),
        ),
        _InfoRow(
          label: 'Chủ tài khoản',
          value: p.bankAccountName,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTransferContentCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    SepayPayment p,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1a3a2a), const Color(0xFF0f2419)]
              : [
                  AppTheme.primaryGreen.withValues(alpha: 0.08),
                  AppTheme.primaryGreen.withValues(alpha: 0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nội dung chuyển khoản',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppTheme.grey500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.transferContent,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚠️ Nhập đúng nội dung này để xác nhận tự động',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.amber.shade300 : AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _copyToClipboard(p.transferContent, 'nội dung chuyển khoản'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    SepayPayment p,
  ) {
    return _InfoCard(
      isDark: isDark,
      cardBg: cardBg,
      icon: Icons.payments_rounded,
      iconColor: AppTheme.primaryGreen,
      title: 'Số tiền',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cần chuyển',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            GestureDetector(
              onTap: () => _copyToClipboard(
                  p.amount.toStringAsFixed(0), 'số tiền'),
              child: Row(
                children: [
                  Text(
                    AppUtils.formatCurrency(p.amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded,
                      size: 14, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepsGuide(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final steps = [
      ('1', 'Mở app ngân hàng bất kỳ trên điện thoại'),
      ('2', 'Quét mã QR hoặc nhập thông tin thủ công'),
      ('3', 'Nhập đúng nội dung chuyển khoản'),
      ('4', 'Xác nhận và hoàn tất — hệ thống tự động ghi nhận'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hướng dẫn thanh toán',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.$2,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── Helper widgets ───────────────────

class _BankBadge extends StatelessWidget {
  final String name;
  final Color color;

  const _BankBadge({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.isDark,
    required this.cardBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : AppTheme.grey900;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppTheme.grey200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCopy,
                  child: const Icon(Icons.copy_rounded,
                      size: 14, color: AppTheme.primaryGreen),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
