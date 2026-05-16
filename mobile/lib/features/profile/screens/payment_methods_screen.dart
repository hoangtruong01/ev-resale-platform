import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(title: const Text('Phương thức thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PaymentMethodItem(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Ví VNPAY',
            subtitle: 'Liên kết ví để thanh toán nhanh chóng',
            isLinked: true,
          ),
          const SizedBox(height: 12),
          _PaymentMethodItem(
            icon: Icons.credit_card_rounded,
            title: 'Thẻ ATM / Internet Banking',
            subtitle: 'Thanh toán qua cổng VNPAY',
            isLinked: false,
          ),
          const SizedBox(height: 24),
          const Text(
            'Lưu ý: Nền tảng EVN sử dụng cổng thanh toán VNPAY để đảm bảo an toàn giao dịch Escrow.',
            style: TextStyle(fontSize: 12, color: AppTheme.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLinked;

  const _PaymentMethodItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
              ],
            ),
          ),
          if (isLinked)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
          else
            const Icon(Icons.chevron_right, color: AppTheme.grey400),
        ],
      ),
    );
  }
}
