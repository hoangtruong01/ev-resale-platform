import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _auctionEnabled = true;
  bool _tradeEnabled = true;
  bool _systemEnabled = true;
  bool _marketingEnabled = false;

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt thông báo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _SwitchCard(
            icon: Icons.notifications_active_outlined,
            title: 'Thông báo đẩy',
            subtitle: 'Nhận thông báo trên điện thoại',
            value: _pushEnabled,
            onChanged: (value) => setState(() => _pushEnabled = value),
          ),
          const SizedBox(height: 12),
          _SwitchCard(
            icon: Icons.gavel_outlined,
            title: 'Đấu giá',
            subtitle: 'Khi có bid mới, thắng/thua đấu giá',
            value: _auctionEnabled,
            onChanged: (value) => setState(() => _auctionEnabled = value),
          ),
          const SizedBox(height: 12),
          _SwitchCard(
            icon: Icons.receipt_long_outlined,
            title: 'Giao dịch',
            subtitle: 'Cập nhật đơn hàng và thanh toán',
            value: _tradeEnabled,
            onChanged: (value) => setState(() => _tradeEnabled = value),
          ),
          const SizedBox(height: 12),
          _SwitchCard(
            icon: Icons.verified_user_outlined,
            title: 'Hệ thống & xác thực',
            subtitle: 'Thông báo về eKYC, bảo mật và tài khoản',
            value: _systemEnabled,
            onChanged: (value) => setState(() => _systemEnabled = value),
          ),
          const SizedBox(height: 12),
          _SwitchCard(
            icon: Icons.campaign_outlined,
            title: 'Khuyến mãi & tin tức',
            subtitle: 'Nhận cập nhật mới từ hệ thống',
            value: _marketingEnabled,
            onChanged: (value) => setState(() => _marketingEnabled = value),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu cài đặt'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_outlined, color: Colors.white, size: 32),
          SizedBox(height: 12),
          Text(
            'Quản lý thông báo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Bật hoặc tắt các loại thông báo bạn muốn nhận.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primaryGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
