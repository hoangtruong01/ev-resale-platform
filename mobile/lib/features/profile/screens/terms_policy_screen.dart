import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Điều khoản & Chính sách')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Quy định sử dụng nền tảng EVN',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.grey900),
          ),
          SizedBox(height: 16),
          Text(
            '1. Quy định chung\n'
            'Nền tảng EVN là nơi kết nối người mua và người bán pin xe điện cũ. Chúng tôi cung cấp công cụ xác thực (eKYC) và thanh toán đảm bảo (Escrow) để bảo vệ quyền lợi cả hai bên.\n\n'
            '2. Quy trình xác thực\n'
            'Tất cả người dùng tham gia giao dịch trên 10 triệu VNĐ bắt buộc phải hoàn tất xác thực danh tính eKYC.\n\n'
            '3. Chính sách thanh toán\n'
            'Tiền cọc (50%) sẽ được hệ thống giữ cho đến khi hợp đồng được ký và sản phẩm được bàn giao. Nếu có tranh chấp, Admin sẽ là bên trung gian hòa giải.\n\n'
            '4. Giám sát IOT\n'
            'Người mua có quyền truy cập dữ liệu IOT (SOH, SOC, Voltage) của pin ngay sau khi hợp đồng được ký kết để đảm bảo chất lượng hàng hóa.',
            style: TextStyle(fontSize: 14, color: AppTheme.grey700, height: 1.5),
          ),
        ],
      ),
    );
  }
}
