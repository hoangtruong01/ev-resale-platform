import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phương thức thanh toán'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWalletCard(),
            const SizedBox(height: 32),
            const Text(
              'Liên kết tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey900,
              ),
            ),
            const SizedBox(height: 16),
            _PaymentMethodItem(
              icon: Icons.account_balance_rounded,
              title: 'Ngân hàng Vietcombank',
              subtitle: '**** **** **** 1234',
              isLinked: true,
              logo: 'https://vuthaonews.com/wp-content/uploads/2021/07/logo-vietcombank.png',
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Ví MoMo',
              subtitle: '0987 *** 321',
              isLinked: false,
              logo: 'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png',
            ),
            const SizedBox(height: 12),
            _PaymentMethodItem(
              icon: Icons.credit_card_rounded,
              title: 'Thẻ Visa / Mastercard',
              subtitle: 'Thêm thẻ mới',
              isLinked: false,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security_rounded, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mọi thông tin thanh toán của bạn đều được mã hóa và bảo mật theo tiêu chuẩn quốc tế PCI DSS.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey600,
                        height: 1.4,
                      ),
                    ),
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

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số dư ví VNPAY',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Image.network(
                'https://sandbox.vnpayment.vn/paymentv2/Images/brands/logo-vnpay.png',
                height: 24,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '15.450.000 VNĐ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildCardAction(Icons.add_rounded, 'Nạp tiền'),
              const SizedBox(width: 16),
              _buildCardAction(Icons.arrow_outward_rounded, 'Rút tiền'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
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
  final String? logo;

  const _PaymentMethodItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLinked,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: logo != null
                ? Image.network(
                    logo!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(icon, color: AppTheme.grey400),
                  )
                : Icon(icon, color: AppTheme.grey400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.grey900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isLinked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Đã liên kết',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGreen, size: 22),
        ],
      ),
    );
  }
}
