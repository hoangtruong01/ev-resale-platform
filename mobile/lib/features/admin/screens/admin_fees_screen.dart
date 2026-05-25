import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class AdminFeesScreen extends ConsumerStatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  ConsumerState<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends ConsumerState<AdminFeesScreen> {
  double _commissionRate = 5.0;
  double _withdrawFee = 1.0;
  double _depositMinimum = 500000;
  double _auctionFee = 50000;
  bool _isSaving = false;

  void _saveFees() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate API save
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật cấu hình Phí & Hoa hồng thành công'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Phí & Hoa hồng'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
                : const Icon(Icons.check_rounded, color: AppTheme.primaryGreen),
            onPressed: _isSaving ? null : _saveFees,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Doanh thu Phí', style: TextStyle(fontSize: 12, color: AppTheme.grey500)),
                        const SizedBox(height: 4),
                        Text(
                          AppUtils.formatCurrency(45290000),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 4),
                        const Text('+12.4% so với tháng trước', style: TextStyle(fontSize: 10, color: AppTheme.success)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giao dịch hoàn tất', style: TextStyle(fontSize: 12, color: AppTheme.grey500)),
                        const SizedBox(height: 4),
                        Text(
                          '148 phiên',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.grey900),
                        ),
                        const SizedBox(height: 4),
                        const Text('+8.2% giao dịch cọc', style: TextStyle(fontSize: 10, color: AppTheme.info)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'CẤU HÌNH BIỂU PHÍ HỆ THỐNG',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.grey500),
            ),
            const SizedBox(height: 12),

            // Commission Rate slider card
            _buildConfigCard(
              title: 'Tỷ lệ chiết khấu Sàn (Commission)',
              value: '${_commissionRate.toStringAsFixed(1)}%',
              description: 'Áp dụng trên tổng giá trị giao dịch thành công (người bán chịu phí).',
              child: Slider(
                value: _commissionRate,
                min: 0.0,
                max: 15.0,
                divisions: 30,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) => setState(() => _commissionRate = val),
              ),
            ),
            const SizedBox(height: 16),

            // Withdraw Fee card
            _buildConfigCard(
              title: 'Phí rút tiền về ngân hàng',
              value: '${_withdrawFee.toStringAsFixed(1)}%',
              description: 'Phí rút tiền từ ví tài khoản về thẻ ngân hàng liên kết.',
              child: Slider(
                value: _withdrawFee,
                min: 0.0,
                max: 5.0,
                divisions: 10,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) => setState(() => _withdrawFee = val),
              ),
            ),
            const SizedBox(height: 16),

            // Minimum Escrow Deposit
            _buildConfigCard(
              title: 'Đặt cọc tối thiểu (Escrow)',
              value: AppUtils.formatCurrency(_depositMinimum),
              description: 'Số tiền tối thiểu khách hàng cần nạp cọc trước khi kích hoạt quy trình ký hợp đồng giao dịch pin.',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() { if (_depositMinimum > 100000) _depositMinimum -= 100000; }),
                      child: const Text('-100k', style: TextStyle(color: AppTheme.error)),
                    ),
                    Text(
                      AppUtils.formatCurrency(_depositMinimum),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _depositMinimum += 100000),
                      child: const Text('+100k', style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Auction Entry Fee
            _buildConfigCard(
              title: 'Phí tham gia đấu giá',
              value: AppUtils.formatCurrency(_auctionFee),
              description: 'Phí vé tham gia/tạo phiên đấu giá để hạn chế tài khoản spam ảo.',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() { if (_auctionFee > 10000) _auctionFee -= 10000; }),
                      child: const Text('-10k', style: TextStyle(color: AppTheme.error)),
                    ),
                    Text(
                      AppUtils.formatCurrency(_auctionFee),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _auctionFee += 10000),
                      child: const Text('+10k', style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required String value,
    required String description,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.grey900),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: AppTheme.grey500),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
