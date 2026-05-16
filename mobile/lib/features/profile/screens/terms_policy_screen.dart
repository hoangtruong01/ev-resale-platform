import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Điều khoản & Chính sách',
                style: TextStyle(color: AppTheme.grey900, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              background: Container(color: Colors.white),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            leading: const BackButton(color: AppTheme.grey900),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildPolicySection(
                    icon: Icons.gavel_rounded,
                    title: '1. Quy định chung',
                    content: 'Nền tảng EVN là nơi kết nối người mua và người bán pin xe điện cũ. Chúng tôi cung cấp công cụ xác thực (eKYC) và thanh toán đảm bảo (Escrow) để bảo vệ quyền lợi cả hai bên.',
                  ),
                  _buildPolicySection(
                    icon: Icons.verified_user_rounded,
                    title: '2. Quy trình xác thực',
                    content: 'Tất cả người dùng tham gia giao dịch trên 10 triệu VNĐ bắt buộc phải hoàn tất xác thực danh tính eKYC qua CCCD gắn chip.',
                  ),
                  _buildPolicySection(
                    icon: Icons.payments_rounded,
                    title: '3. Chính sách thanh toán',
                    content: 'Tiền cọc (50%) sẽ được hệ thống giữ cho đến khi hợp đồng được ký và sản phẩm được bàn giao. Nếu có tranh chấp, Admin sẽ là bên trung gian hòa giải.',
                  ),
                  _buildPolicySection(
                    icon: Icons.sensors_rounded,
                    title: '4. Giám sát IOT',
                    content: 'Người mua có quyền truy cập dữ liệu IOT (SOH, SOC, Voltage) của pin ngay sau khi hợp đồng được ký kết để đảm bảo chất lượng hàng hóa.',
                  ),
                  _buildPolicySection(
                    icon: Icons.security_rounded,
                    title: '5. Bảo mật thông tin',
                    content: 'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn và chỉ chia sẻ với đối tác giao dịch khi có sự đồng ý của cả hai bên.',
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Cập nhật lần cuối: 16/05/2026',
                      style: TextStyle(color: AppTheme.grey400, fontSize: 12),
                    ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.description_rounded, color: AppTheme.primaryGreen, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy định sử dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'Vui lòng đọc kỹ các quy định để đảm bảo giao dịch an toàn.',
                  style: TextStyle(fontSize: 12, color: AppTheme.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.grey900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.grey700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
