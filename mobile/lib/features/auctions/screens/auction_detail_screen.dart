import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuctionDetailScreen extends StatelessWidget {
  final String id;
  const AuctionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đấu giá')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đấu giá theo thời gian thực',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kết nối WebSocket để xem và đặt giá\ntrực tiếp tại đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey600),
            ),
            const SizedBox(height: 24),
            Text(
              'Auction ID: $id',
              style: const TextStyle(color: AppTheme.grey400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
