import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../models/auction_model.dart';
import '../../../core/utils/app_utils.dart';
import '../../../widgets/app_network_image.dart';

// Stub providers - connect to real API when backend is running
final auctionListProvider = FutureProvider<List<AuctionModel>>((ref) async {
  // TODO: connect to auction service
  await Future.delayed(const Duration(milliseconds: 800));
  return [];
});

class AuctionListScreen extends ConsumerWidget {
  const AuctionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(auctionListProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đấu giá'),
          bottom: const TabBar(
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.grey400,
            indicatorColor: AppTheme.primaryGreen,
            tabs: [
              Tab(text: 'Đang diễn ra'),
              Tab(text: 'Sắp diễn ra'),
              Tab(text: 'Đã kết thúc'),
            ],
          ),
        ),
        body: auctionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (auctions) {
            final active = auctions.where((a) => a.status == 'ACTIVE').toList();
            final pending = auctions
                .where((a) => a.status == 'PENDING')
                .toList();
            final ended = auctions.where((a) => a.status == 'ENDED').toList();

            return TabBarView(
              children: [
                _AuctionTabContent(
                  auctions: active,
                  emptyMsg: 'Chưa có phiên đấu giá nào đang diễn ra',
                ),
                _AuctionTabContent(
                  auctions: pending,
                  emptyMsg: 'Không có phiên sắp tới',
                ),
                _AuctionTabContent(
                  auctions: ended,
                  emptyMsg: 'Chưa có phiên kết thúc',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: AppTheme.primaryGreen,
          icon: const Icon(Icons.add),
          label: const Text('Tạo đấu giá'),
        ),
      ),
    );
  }
}

class _AuctionTabContent extends StatelessWidget {
  final List<AuctionModel> auctions;
  final String emptyMsg;

  const _AuctionTabContent({required this.auctions, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gavel_rounded, size: 64, color: AppTheme.grey200),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: AppTheme.grey600)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: auctions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => AuctionCard(auction: auctions[i]),
    );
  }
}

class AuctionCard extends StatefulWidget {
  final AuctionModel auction;
  const AuctionCard({super.key, required this.auction});

  @override
  State<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<AuctionCard> {
  late Timer _timer;
  late String _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = AppUtils.formatCountdown(widget.auction.endDateTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _countdown = AppUtils.formatCountdown(widget.auction.endDateTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    return GestureDetector(
      onTap: () => context.push('/auctions/${auction.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AppNetworkImage(
                    url: auction.thumbnailUrl,
                    height: 160,
                    width: double.infinity,
                    placeholderIcon: Icons.gavel_rounded,
                  ),
                ),
                // Live badge
                if (auction.isActive)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Countdown
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _countdown,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.itemTypeLabel,
                    style: const TextStyle(
                      color: AppTheme.grey400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auction.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá hiện tại',
                            style: TextStyle(
                              color: AppTheme.grey400,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            AppUtils.formatCurrency(auction.currentPrice),
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (auction.bidCount != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: AppTheme.grey400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${auction.bidCount} lượt bid',
                              style: const TextStyle(
                                color: AppTheme.grey600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
