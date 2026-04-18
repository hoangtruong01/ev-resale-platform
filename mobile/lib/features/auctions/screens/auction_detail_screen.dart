import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/auction_model.dart';
import '../../../widgets/app_network_image.dart';
import '../providers/auction_providers.dart';

class AuctionDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const AuctionDetailScreen({super.key, required this.id});

  @override
  ConsumerState<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  final _bidController = TextEditingController();
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  String _countdown = 'Đang tải...';
  bool _isBidding = false;

  @override
  void initState() {
    super.initState();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _bidController.dispose();
    super.dispose();
  }

  void _startRealtimeUpdates() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final notifier = ref.read(auctionRealtimeTickProvider(widget.id).notifier);
      notifier.state = notifier.state + 1;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final auction = ref.read(auctionDetailProvider(widget.id)).value;
      if (auction == null) return;
      setState(() {
        _countdown = AppUtils.formatCountdown(auction.endDateTime);
      });
    });
  }

  Future<void> _placeBid(AuctionModel auction) async {
    final amount = double.tryParse(
      _bidController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mức giá hợp lệ.')),
      );
      return;
    }

    if (amount < auction.currentPrice + auction.bidStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Giá bid tối thiểu là ${AppUtils.formatCurrency(auction.currentPrice + auction.bidStep)}',
          ),
        ),
      );
      return;
    }

    setState(() => _isBidding = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auctions/${widget.id}/bid', data: {'amount': amount});
      if (!mounted) return;
      _bidController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt giá thành công.')),
      );
      final notifier = ref.read(auctionRealtimeTickProvider(widget.id).notifier);
      notifier.state = notifier.state + 1;
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parseApiError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isBidding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auctionAsync = ref.watch(auctionDetailProvider(widget.id));
    final bidsAsync = ref.watch(auctionBidsProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đấu giá')),
      body: auctionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text('Không tải được dữ liệu: $error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(auctionDetailProvider(widget.id)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (auction) {
          _countdown = AppUtils.formatCountdown(auction.endDateTime);

          final minBid = auction.currentPrice + auction.bidStep;
          final canBid = auction.status == 'ACTIVE' && !auction.isEnded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AuctionHeaderCard(auction: auction, countdown: _countdown),
              const SizedBox(height: 16),
              _AuctionMetaCard(auction: auction),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đặt giá',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giá tối thiểu: ${AppUtils.formatCurrency(minBid)}',
                        style: const TextStyle(color: AppTheme.grey600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bidController,
                        enabled: canBid && !_isBidding,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nhập số tiền muốn bid (VND)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [1, 2, 3]
                            .map(
                              (times) => ActionChip(
                                label: Text(
                                  '+ ${AppUtils.formatCurrency(auction.bidStep * times)}',
                                ),
                                onPressed: canBid && !_isBidding
                                    ? () {
                                        final value = minBid + (auction.bidStep * (times - 1));
                                        _bidController.text = value.toStringAsFixed(0);
                                      }
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canBid && !_isBidding ? () => _placeBid(auction) : null,
                          icon: _isBidding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.gavel_rounded),
                          label: Text(_isBidding
                              ? 'Đang gửi giá...'
                              : (canBid ? 'Đặt giá ngay' : 'Phiên không còn nhận bid')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch sử đặt giá',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      bidsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Text(
                          'Không tải được lịch sử bid: $error',
                          style: const TextStyle(color: AppTheme.error),
                        ),
                        data: (bids) {
                          if (bids.isEmpty) {
                            return const Text(
                              'Chưa có lượt bid nào.',
                              style: TextStyle(color: AppTheme.grey600),
                            );
                          }
                          return Column(
                            children: bids
                                .map(
                                  (bid) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    title: Text(
                                      bid.bidder?.fullName ?? 'Người dùng',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(AppUtils.timeAgo(bid.createdAt)),
                                    trailing: Text(
                                      AppUtils.formatCurrency(bid.amount),
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuctionHeaderCard extends StatelessWidget {
  final AuctionModel auction;
  final String countdown;

  const _AuctionHeaderCard({required this.auction, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppNetworkImage(
                url: auction.thumbnailUrl,
                width: double.infinity,
                height: 220,
                placeholderIcon: Icons.gavel_rounded,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: auction.isEnded ? AppTheme.grey600 : AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    auction.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        countdown,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auction.itemTypeLabel,
                  style: const TextStyle(color: AppTheme.grey500),
                ),
                const SizedBox(height: 6),
                Text(
                  auction.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if ((auction.description ?? '').isNotEmpty)
                  Text(
                    auction.description!,
                    style: const TextStyle(color: AppTheme.grey700),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PriceBlock(
                      label: 'Giá hiện tại',
                      value: AppUtils.formatCurrency(auction.currentPrice),
                      valueColor: AppTheme.primaryGreen,
                    ),
                    _PriceBlock(
                      label: 'Giá khởi điểm',
                      value: AppUtils.formatCurrency(auction.startingPrice),
                      valueColor: AppTheme.grey700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionMetaCard extends StatelessWidget {
  final AuctionModel auction;

  const _AuctionMetaCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin phiên đấu giá',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _MetaRow(label: 'Bước giá', value: AppUtils.formatCurrency(auction.bidStep)),
            _MetaRow(label: 'Số lượng', value: '${auction.lotQuantity}'),
            _MetaRow(label: 'Địa điểm', value: auction.location ?? 'Không có'),
            _MetaRow(label: 'Liên hệ', value: auction.contactPhone ?? 'Không có'),
            _MetaRow(label: 'Bắt đầu', value: AppUtils.formatDateTime(auction.startTime)),
            _MetaRow(label: 'Kết thúc', value: AppUtils.formatDateTime(auction.endTime)),
            _MetaRow(label: 'Số lượt bid', value: '${auction.bidCount ?? 0}'),
            _MetaRow(label: 'Người bán', value: auction.seller?.fullName ?? 'Không rõ'),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.grey600),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _PriceBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.grey500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
