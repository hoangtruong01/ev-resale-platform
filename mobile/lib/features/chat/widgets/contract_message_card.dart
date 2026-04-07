import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../screens/signature_pad_screen.dart';

/// A special chat message card that shows when a contract has been proposed.
/// Both parties can tap "Ký hợp đồng" to open the signature screen.
class ContractMessageCard extends ConsumerWidget {
  final String contractId;
  final String transactionId;
  final String assetName;
  final double agreedPrice;
  final String proposedByUserId;
  final String currentUserId;

  const ContractMessageCard({
    super.key,
    required this.contractId,
    required this.transactionId,
    required this.assetName,
    required this.agreedPrice,
    required this.proposedByUserId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractStatus = ref.watch(_contractStatusProvider(contractId));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.1),
                  AppTheme.primaryDark.withOpacity(0.06),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu ký Hợp đồng số',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.grey900,
                        ),
                      ),
                      Text(
                        'Cả hai bên cần ký xác nhận',
                        style: TextStyle(fontSize: 11, color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
                contractStatus.when(
                  loading: () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error_outline,
                      color: AppTheme.error, size: 20),
                  data: (status) => _StatusChip(status: status),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Sản phẩm',
                  value: assetName,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Giá thỏa thuận',
                  value: '${_formatCurrency(agreedPrice)} VNĐ',
                  valueColor: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 16),
                contractStatus.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (status) {
                    if (status == 'COMPLETED') {
                      return const _CompletedBanner();
                    }
                    return _SignButton(
                      contractId: contractId,
                      currentUserId: currentUserId,
                      onSigned: () => ref.invalidate(_contractStatusProvider(contractId)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(formatted[i]);
    }
    return buffer.toString();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _contractStatusProvider =
    FutureProvider.autoDispose.family<String, String>((ref, contractId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/contracts/$contractId/status');
  final data = res.data as Map<String, dynamic>;
  return data['status'] as String? ?? 'PENDING';
});

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'COMPLETED' => ('Đã ký', AppTheme.success),
      'PENDING' => ('Chờ ký', AppTheme.warning),
      'BUYER_SIGNED' => ('Mua đã ký', AppTheme.info),
      'SELLER_SIGNED' => ('Bán đã ký', AppTheme.info),
      _ => ('Không xác định', AppTheme.grey400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey400),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.grey600)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.grey900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
          SizedBox(width: 6),
          Text(
            'Hợp đồng đã được cả hai bên ký!',
            style: TextStyle(
              color: AppTheme.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignButton extends ConsumerStatefulWidget {
  final String contractId;
  final String currentUserId;
  final VoidCallback onSigned;

  const _SignButton({
    required this.contractId,
    required this.currentUserId,
    required this.onSigned,
  });

  @override
  ConsumerState<_SignButton> createState() => _SignButtonState();
}

class _SignButtonState extends ConsumerState<_SignButton> {
  bool _isSigning = false;

  Future<void> _openSignaturePad() async {
    final signatureData = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePadScreen()),
    );

    if (signatureData == null || !mounted) return;

    setState(() => _isSigning = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/contracts/${widget.contractId}/sign',
        data: {
          'userId': widget.currentUserId,
          'signatureData': signatureData,
        },
      );
      widget.onSigned();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSigning ? null : _openSignaturePad,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _isSigning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.draw_outlined, color: Colors.white, size: 18),
        label: Text(
          _isSigning ? 'Đang xử lý...' : 'Ký hợp đồng của tôi',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
