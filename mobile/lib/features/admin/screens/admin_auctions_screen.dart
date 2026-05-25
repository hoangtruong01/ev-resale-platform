import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

class AdminAuctionsScreen extends ConsumerStatefulWidget {
  const AdminAuctionsScreen({super.key});

  @override
  ConsumerState<AdminAuctionsScreen> createState() => _AdminAuctionsScreenState();
}

class _AdminAuctionsScreenState extends ConsumerState<AdminAuctionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Map tabs to statuses
    final approvalStatus = _tabController.index == 0 ? 'PENDING' : 'all';
    final status = switch (_tabController.index) {
      0 => 'PENDING',
      1 => 'ACTIVE',
      2 => 'ENDED',
      _ => 'all'
    };

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Quản lý Đấu giá'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search & Sort bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.grey100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => setState(() {}),
                          style: TextStyle(color: isDark ? Colors.white : AppTheme.grey900),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm đấu giá...',
                            hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.grey400),
                            prefixIcon: Icon(Icons.search, size: 18, color: isDark ? Colors.white54 : AppTheme.grey500),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort dropdown
                    DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.swap_vert_rounded, color: AppTheme.primaryGreen),
                      items: const [
                        DropdownMenuItem(value: 'createdAt', child: Text('Mới nhất')),
                        DropdownMenuItem(value: 'endTime', child: Text('Kết thúc')),
                        DropdownMenuItem(value: 'currentPrice', child: Text('Giá thầu')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _sortBy = val;
                            _sortOrder = val == 'endTime' ? 'asc' : 'desc';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGreen,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: isDark ? AppTheme.grey400 : AppTheme.grey500,
                tabs: const [
                  Tab(text: 'Chờ duyệt'),
                  Tab(text: 'Đang đấu giá'),
                  Tab(text: 'Đã kết thúc'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: AdminAuctionsList(
        status: status,
        approvalStatus: approvalStatus,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        search: _searchCtrl.text.trim(),
      ),
    );
  }
}

class AdminAuctionsList extends ConsumerWidget {
  final String status;
  final String approvalStatus;
  final String sortBy;
  final String sortOrder;
  final String search;

  const AdminAuctionsList({
    super.key,
    required this.status,
    required this.approvalStatus,
    required this.sortBy,
    required this.sortOrder,
    required this.search,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queryKey = 'status=$status&approvalStatus=$approvalStatus&sortBy=$sortBy&sortOrder=$sortOrder&search=${Uri.encodeComponent(search)}';

    final auctionsAsync = ref.watch(_auctionsProvider(queryKey));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_auctionsProvider(queryKey)),
      child: auctionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Lỗi tải đấu giá: $err', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey700)),
              TextButton(
                onPressed: () => ref.invalidate(_auctionsProvider(queryKey)),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
        data: (res) {
          final items = List<Map<String, dynamic>>.from(res['data'] ?? []);

          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.gavel_rounded, size: 64, color: isDark ? Colors.white24 : AppTheme.grey300),
                      const SizedBox(height: 16),
                      Text(
                        'Không có phiên đấu giá nào',
                        style: TextStyle(color: isDark ? AppTheme.grey400 : AppTheme.grey500),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, index) {
              final item = items[index];
              return _AuctionCard(
                auction: item,
                onActionDone: () {
                  ref.invalidate(_auctionsProvider(queryKey));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────

final _auctionsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, queryKey) async {
  final uri = Uri.parse('http://placeholder.local/?$queryKey');
  final status = uri.queryParameters['status'] ?? 'all';
  final approvalStatus = uri.queryParameters['approvalStatus'] ?? 'all';
  final sortBy = uri.queryParameters['sortBy'] ?? 'createdAt';
  final sortOrder = uri.queryParameters['sortOrder'] ?? 'desc';
  final search = uri.queryParameters['search'] ?? '';

  final params = {
    'page': 1,
    'limit': 50,
    'sortBy': sortBy,
    'sortOrder': sortOrder,
    if (status != 'all' && status != 'PENDING') 'status': status,
    if (approvalStatus != 'all') 'approvalStatus': approvalStatus,
    if (search.isNotEmpty) 'search': search,
  };

  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/auctions', queryParameters: params);
  return Map<String, dynamic>.from(res.data);
});

// ─── Auction Card Widget ──────────────────────────────────────────────────────

class _AuctionCard extends ConsumerWidget {
  final Map<String, dynamic> auction;
  final VoidCallback onActionDone;

  const _AuctionCard({required this.auction, required this.onActionDone});

  String _getItemName(Map<String, dynamic> item) {
    final title = item['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;

    final brand = item['itemBrand']?.toString().trim() ?? '';
    final model = item['itemModel']?.toString().trim() ?? '';
    if (brand.isNotEmpty || model.isNotEmpty) {
      return '$brand $model'.trim();
    }
    
    final itemType = item['itemType']?.toString().toUpperCase() ?? '';
    if (itemType == 'VEHICLE') return 'Phương tiện điện';
    if (itemType == 'BATTERY') return 'Bộ Pin EV';
    return 'Phiên đấu giá';
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return 'N/A';
    try {
      final date = DateTime.parse(iso).toLocal();
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _getTimeRemaining(String? endIso) {
    if (endIso == null) return 'N/A';
    try {
      final end = DateTime.parse(endIso);
      final diff = end.difference(DateTime.now());
      if (diff.isNegative) return 'Đã kết thúc';
      
      if (diff.inDays > 0) {
        return 'Còn lại: ${diff.inDays} ngày ${diff.inHours % 24} giờ';
      }
      if (diff.inHours > 0) {
        return 'Còn lại: ${diff.inHours} giờ ${diff.inMinutes % 60} phút';
      }
      return 'Còn lại: ${diff.inMinutes} phút';
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _proceedApprove(BuildContext context, WidgetRef ref, Map<String, dynamic> body) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/admin/auctions/${auction['id']}/approve', data: body);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã phê duyệt phiên đấu giá thành công'), backgroundColor: AppTheme.success),
        );
        onActionDone();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi duyệt: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final startTimeStr = auction['startTime']?.toString();
    if (startTimeStr == null) return;

    final startTime = DateTime.parse(startTimeStr);
    final now = DateTime.now();

    // Check if start time has already passed (late approval)
    if (startTime.isBefore(now.add(const Duration(minutes: 5)))) {
      // Calculate buffer and suggested rescheduled time
      final originalEndTime = DateTime.parse(auction['endTime'] ?? '');
      final duration = originalEndTime.difference(startTime);

      final suggestedStart = now.add(const Duration(minutes: 5)); // 5 mins buffer
      final suggestedEnd = suggestedStart.add(duration);

      final startCtrl = TextEditingController(text: suggestedStart.toLocal().toString().substring(0, 16));
      final endCtrl = TextEditingController(text: suggestedEnd.toLocal().toString().substring(0, 16));

      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final isDialogDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                SizedBox(width: 8),
                Text('Cảnh báo: Duyệt trễ!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thời gian bắt đầu ban đầu đã trôi qua. Hệ thống đề xuất tịnh tiến thời gian để bảo đảm thời lượng phiên đấu giá:'),
                const SizedBox(height: 16),
                Text('Thời gian bắt đầu mới (Đệm 5p):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDialogDark ? Colors.white70 : AppTheme.grey700)),
                const SizedBox(height: 4),
                TextField(controller: startCtrl, decoration: const InputDecoration(hintText: 'YYYY-MM-DD HH:MM')),
                const SizedBox(height: 12),
                Text('Thời gian kết thúc mới:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDialogDark ? Colors.white70 : AppTheme.grey700)),
                const SizedBox(height: 4),
                TextField(controller: endCtrl, decoration: const InputDecoration(hintText: 'YYYY-MM-DD HH:MM')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey500)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'approve'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('Duyệt đề xuất'),
              ),
            ],
          );
        },
      );

      if (!context.mounted) return;

      if (choice == 'approve') {
        try {
          final newStart = DateTime.parse(startCtrl.text.trim());
          final newEnd = DateTime.parse(endCtrl.text.trim());
          await _proceedApprove(context, ref, {
            'startTime': newStart.toUtc().toIso8601String(),
            'endTime': newEnd.toUtc().toIso8601String(),
          });
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Định dạng ngày giờ không hợp lệ!'), backgroundColor: AppTheme.error),
            );
          }
        }
      }
      return;
    }

    // Normal approval
    await _proceedApprove(context, ref, {});
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối Đấu giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối phiên đấu giá này:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(hintText: 'Lý do từ chối...'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true || reasonCtrl.text.trim().isEmpty) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.put('/admin/auctions/${auction['id']}/reject', data: {'reason': reasonCtrl.text.trim()});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối phiên đấu giá'), backgroundColor: AppTheme.error),
        );
        onActionDone();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _endEarly(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc sớm đấu giá'),
        content: const Text('Bạn có chắc muốn dừng và kết thúc sớm phiên đấu giá đang diễn ra này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.put('/admin/auctions/${auction['id']}/end');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kết thúc sớm đấu giá thành công'), backgroundColor: AppTheme.success),
        );
        onActionDone();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi dừng đấu giá: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = auction['approvalStatus'] == 'PENDING';
    final isActive = auction['status'] == 'ACTIVE';
    final currentPrice = (auction['currentPrice'] ?? auction['startingPrice'] ?? auction['startPrice'] ?? 0) as num;
    final bidCount = (auction['bidsCount'] ?? auction['bids']?.length ?? 0) as int;
    
    final media = auction['media'] as List? ?? [];
    final imageUrl = media.isNotEmpty ? media[0]['url'] : null;

    final itemType = auction['itemType']?.toString().toUpperCase() ?? 'BATTERY';
    final typeLabel = itemType == 'VEHICLE' ? 'Xe điện' : 'Bộ Pin';
    final typeColor = itemType == 'VEHICLE' ? AppTheme.accentOrange : AppTheme.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper details (Image + Text info)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: isDark ? AppTheme.darkCard : AppTheme.grey100,
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.gavel, color: AppTheme.grey400))
                        : const Icon(Icons.gavel, color: AppTheme.grey400),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            _formatDateTime(auction['startTime']),
                            style: const TextStyle(fontSize: 11, color: AppTheme.grey500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getItemName(auction),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15, 
                          color: isDark ? Colors.white : AppTheme.grey900
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Giá hiện tại', style: TextStyle(fontSize: 10, color: AppTheme.grey400)),
                              Text(
                                AppUtils.formatCurrency(currentPrice),
                                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Lượt đấu', style: TextStyle(fontSize: 10, color: AppTheme.grey400)),
                              Text(
                                '$bidCount lượt',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.white70 : AppTheme.grey800),
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
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: isDark ? Colors.white10 : AppTheme.grey100, height: 1),
          ),
          
          // Additional metadata (Seller & TimeRemaining)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bán bởi: ${auction['seller']?['fullName'] ?? auction['seller']?['name'] ?? 'N/A'}',
                  style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
                ),
                Text(
                  _getTimeRemaining(auction['endTime']),
                  style: const TextStyle(color: AppTheme.accentOrange, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Actions panel
          Container(
            color: isDark ? AppTheme.darkCard : AppTheme.grey50,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  OutlinedButton(
                    onPressed: () => _reject(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _approve(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Duyệt', style: TextStyle(fontSize: 12)),
                  ),
                ] else if (isActive) ...[
                  ElevatedButton.icon(
                    onPressed: () => _endEarly(context, ref),
                    icon: const Icon(Icons.stop_circle_rounded, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      minimumSize: const Size(120, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    label: const Text('Dừng sớm', style: TextStyle(fontSize: 12)),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.grey400.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ĐÃ KẾT THÚC',
                      style: TextStyle(color: AppTheme.grey500, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
