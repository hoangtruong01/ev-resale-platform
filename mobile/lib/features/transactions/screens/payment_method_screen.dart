import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class PaymentMethodScreen extends StatelessWidget {
  final String transactionId;
  final double amount;
  final String paymentType; // FULL | DEPOSIT | BALANCE

  const PaymentMethodScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.paymentType,
  });

  String get _paymentTypeLabel {
    return switch (paymentType) {
      'DEPOSIT' => 'Đặt cọc 50%',
      'BALANCE' => 'Thanh toán phần còn lại (50%)',
      _ => 'Thanh toán toàn bộ',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.grey900;
    final textSecondary = isDark ? Colors.white60 : AppTheme.grey500;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Chọn phương thức thanh toán'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            _OrderSummaryCard(
              amount: amount,
              paymentTypeLabel: _paymentTypeLabel,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
            const SizedBox(height: 28),

            Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // SePay — bank transfer QR
            _PaymentMethodCard(
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFF0052CC),
              title: 'Chuyển khoản ngân hàng (SePay)',
              subtitle: 'Quét QR VietQR — tất cả ngân hàng VN hỗ trợ',
              badgeText: 'Phổ biến',
              badgeColor: AppTheme.primaryGreen,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: () => context.push(
                '/transactions/$transactionId/payment/sepay',
                extra: {
                  'amount': amount,
                  'paymentType': paymentType,
                },
              ),
            ),
            const SizedBox(height: 12),

            // VNPay
            _PaymentMethodCard(
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFFE31C39),
              title: 'VNPay',
              subtitle: 'Thanh toán qua ví VNPay / ATM / Thẻ tín dụng',
              badgeText: null,
              badgeColor: null,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng VNPay đang được phát triển'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            _SecurityNote(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final double amount;
  final String paymentTypeLabel;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _OrderSummaryCard({
    required this.amount,
    required this.paymentTypeLabel,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : AppTheme.grey200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tóm tắt thanh toán',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? Colors.white12 : AppTheme.grey200,
            height: 1,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                paymentTypeLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              Text(
                AppUtils.formatCurrency(amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  AppUtils.formatCurrency(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (badgeText != null && badgeColor != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor!.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor!,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white30 : AppTheme.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  final bool isDark;

  const _SecurityNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppTheme.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Giao dịch được bảo mật và mã hóa. Thông tin thanh toán của bạn an toàn tuyệt đối.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppTheme.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
