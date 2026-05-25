import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

class AdminContractsScreen extends ConsumerWidget {
  const AdminContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> contracts = [
      {
        'id': 'CTR-202605-0012',
        'buyer': 'Nguyễn Văn Hùng',
        'seller': 'Công ty Năng Lượng Xanh',
        'battery': 'Pin VinFast VF8 - SOH 92%',
        'amount': 38000000.0,
        'status': 'SIGNED', // SIGNED, WAITING_BUYER, WAITING_SELLER, CANCELLED
        'date': '2026-05-24T14:32:00Z',
      },
      {
        'id': 'CTR-202605-0011',
        'buyer': 'Trần Minh Hoàng',
        'seller': 'Lê Quốc Khánh (Cá nhân)',
        'battery': 'Pin CATL LFP 72V 100Ah',
        'amount': 15500000.0,
        'status': 'WAITING_BUYER',
        'date': '2026-05-24T09:15:00Z',
      },
      {
        'id': 'CTR-202605-0010',
        'buyer': 'Phạm Thuỳ Linh',
        'seller': 'Đại lý Pin EV Sài Gòn',
        'battery': 'Pin LG Chem 400V (VinFast e34)',
        'amount': 45000000.0,
        'status': 'WAITING_SELLER',
        'date': '2026-05-23T16:45:00Z',
      },
      {
        'id': 'CTR-202605-0009',
        'buyer': 'Vũ Đức Hải',
        'seller': 'Nguyễn Hoàng Nam',
        'battery': 'Pin Lithium NCM 60V 50Ah',
        'amount': 8200000.0,
        'status': 'CANCELLED',
        'date': '2026-05-22T11:20:00Z',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Quản lý Hợp đồng'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: contracts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final contract = contracts[index];
          return _ContractCard(contract: contract);
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final Map<String, dynamic> contract;

  const _ContractCard({required this.contract});

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = contract['status'] as String;

    final statusLabel = switch (status) {
      'SIGNED' => 'Đã ký kết',
      'WAITING_BUYER' => 'Chờ người mua ký',
      'WAITING_SELLER' => 'Chờ người bán ký',
      'CANCELLED' => 'Đã huỷ bỏ',
      _ => 'Chờ xử lý'
    };

    final statusColor = switch (status) {
      'SIGNED' => AppTheme.success,
      'WAITING_BUYER' => AppTheme.info,
      'WAITING_SELLER' => AppTheme.warning,
      'CANCELLED' => AppTheme.error,
      _ => AppTheme.grey500
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID & Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  contract['id'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: isDark ? Colors.white10 : AppTheme.grey100, height: 1),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract['battery'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.grey900),
                ),
                const SizedBox(height: 12),
                
                // Buyer / Seller info
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 14, color: AppTheme.grey400),
                    const SizedBox(width: 8),
                    Text('Mua: ', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    Text(contract['buyer'], style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey800, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 14, color: AppTheme.grey400),
                    const SizedBox(width: 8),
                    Text('Bán: ', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    Text(contract['seller'], style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey800, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Total amount & signature date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giá trị hợp đồng', style: TextStyle(fontSize: 10, color: AppTheme.grey400)),
                        const SizedBox(height: 2),
                        Text(
                          AppUtils.formatCurrency(contract['amount']),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    Text(
                      'Tạo ngày: ${_formatDate(contract['date'])}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.grey500, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action button footer
          Container(
            color: isDark ? AppTheme.darkCard : AppTheme.grey50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Show contract view dialogue
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Xem Hợp đồng ${contract['id']}'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập - Tự do - Hạnh phúc\n\nHỢP ĐỒNG MUA BÁN THƯƠNG MẠI PIN',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text('Bên A (Người bán): ${contract['seller']}'),
                              Text('Bên B (Người mua): ${contract['buyer']}'),
                              const SizedBox(height: 12),
                              Text('Nội dung: Mua bán sản phẩm ${contract['battery']}. Trị giá hợp đồng là ${AppUtils.formatCurrency(contract['amount'])}.'),
                              const SizedBox(height: 12),
                              const Text('Điều khoản: Bên B chuyển cọc đặt chỗ vào tài khoản ví Escrow an toàn của EVN-Market. Sau khi nghiệm thu giao dịch, sàn sẽ giải ngân cho Bên A.'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Xem văn bản', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(110, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
