import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';

class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  ConsumerState<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedType = 'all'; // all, vehicle, battery, accessory

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
    final status = switch (_tabController.index) {
      0 => 'PENDING',
      1 => 'APPROVED',
      2 => 'REJECTED',
      _ => 'PENDING'
    };

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Duyệt tin đăng'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search and Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm tin đăng...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedType,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryGreen),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'vehicle', child: Text('Xe điện')),
                        DropdownMenuItem(value: 'battery', child: Text('Pin EV')),
                        DropdownMenuItem(value: 'accessory', child: Text('Phụ kiện')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedType = val);
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
                unselectedLabelColor: AppTheme.grey500,
                tabs: const [
                  Tab(text: 'Chờ duyệt'),
                  Tab(text: 'Đã duyệt'),
                  Tab(text: 'Từ chối'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _ListingsTabContent(
        status: status,
        type: _selectedType,
        search: _searchCtrl.text,
      ),
    );
  }
}

class _ListingsTabContent extends ConsumerWidget {
  final String status;
  final String type;
  final String search;

  const _ListingsTabContent({
    required this.status,
    required this.type,
    required this.search,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryParams = {
      'approvalStatus': status,
      'limit': 50,
      'page': 1,
      if (search.isNotEmpty) 'search': search,
    };
    
    final listingsAsync = ref.watch(_listingsProvider(queryParams));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_listingsProvider(queryParams)),
      child: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Lỗi tải danh sách: $err'),
              TextButton(
                onPressed: () => ref.invalidate(_listingsProvider(queryParams)),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
        data: (res) {
          var items = List<Map<String, dynamic>>.from(res['data'] ?? []);
          
          // Filter locally by type if not all
          if (type != 'all') {
            items = items.where((x) => x['type'] == type).toList();
          }

          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.grey300),
                      SizedBox(height: 16),
                      Text('Không có bài đăng nào', style: TextStyle(color: AppTheme.grey500)),
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
              return _ListingItemCard(
                item: item,
                onActionDone: () {
                  ref.invalidate(_listingsProvider(queryParams));
                },
              );
            },
          );
        },
      ),
    );
  }
}

final _listingsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/listings', queryParameters: params);
  return Map<String, dynamic>.from(res.data);
});

class _ListingItemCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final VoidCallback onActionDone;

  const _ListingItemCard({required this.item, required this.onActionDone});

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final id = item['id'];
    final typePlural = item['type'] == 'vehicle' 
        ? 'vehicles' 
        : (item['type'] == 'battery' ? 'batteries' : 'accessories');
    
    try {
      await dio.put('/admin/$typePlural/$id/approve');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã phê duyệt bài đăng'), backgroundColor: AppTheme.success),
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

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối bài đăng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối kiểm duyệt tin đăng này:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Lý do từ chối...',
                fillColor: AppTheme.grey100,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey600)),
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
    final id = item['id'];
    final typePlural = item['type'] == 'vehicle' 
        ? 'vehicles' 
        : (item['type'] == 'battery' ? 'batteries' : 'accessories');
    
    try {
      await dio.put('/admin/$typePlural/$id/reject', data: {'reason': reasonCtrl.text.trim()});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối bài đăng'), backgroundColor: AppTheme.error),
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

  Future<void> _toggleSpam(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final id = item['id'];
    final typePlural = item['type'] == 'vehicle' 
        ? 'vehicles' 
        : (item['type'] == 'battery' ? 'batteries' : 'accessories');
    
    try {
      await dio.put('/admin/$typePlural/$id/spam', data: {'reason': 'Spam flagged by admin'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu spam và ẩn bài viết'), backgroundColor: Colors.amber),
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

  Future<void> _toggleVerify(BuildContext context, WidgetRef ref, bool isCurrentlyVerified) async {
    final dio = ref.read(dioProvider);
    final id = item['id'];
    final typePlural = item['type'] == 'vehicle' 
        ? 'vehicles' 
        : (item['type'] == 'battery' ? 'batteries' : 'accessories');
    
    final action = isCurrentlyVerified ? 'unverify' : 'verify';
    try {
      await dio.put('/admin/$typePlural/$id/$action');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyVerified ? 'Đã hủy xác thực sản phẩm' : 'Đã xác thực sản phẩm thành công'),
            backgroundColor: AppTheme.primaryGreen,
          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = item['approvalStatus'] == 'PENDING';
    final isApproved = item['approvalStatus'] == 'APPROVED';
    final isSpam = item['isSpamSuspicious'] == true || (item['spamScore'] ?? 0) > 50;
    final isVerified = item['isVerified'] == true;
    final images = item['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : null;

    final typeLabel = switch (item['type']) {
      'vehicle' => 'Xe điện',
      'battery' => 'Pin EV',
      'accessory' => 'Phụ kiện',
      _ => 'Sản phẩm'
    };

    final typeColor = switch (item['type']) {
      'vehicle' => AppTheme.accentOrange,
      'battery' => AppTheme.primaryGreen,
      'accessory' => AppTheme.info,
      _ => AppTheme.grey500
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSpam ? AppTheme.error.withValues(alpha: 0.5) : AppTheme.grey200, width: isSpam ? 1.5 : 1),
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
                    color: AppTheme.grey100,
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppTheme.grey400))
                        : const Icon(Icons.image, color: AppTheme.grey400),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const SizedBox(width: 6),
                          if (isVerified)
                            const Icon(Icons.verified_rounded, color: Colors.amber, size: 16),
                          if (isSpam) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'AI Spam: ${item['spamScore']}%',
                                style: const TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] ?? 'Không tên',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.grey900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatCurrency(item['price'] ?? 0),
                        style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Additional metadata
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: AppTheme.grey100, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bán bởi: ${item['seller']?['fullName'] ?? item['seller']?['name'] ?? 'N/A'}',
                  style: const TextStyle(color: AppTheme.grey600, fontSize: 12),
                ),
                Text(
                  AppUtils.timeAgo(item['createdAt'] ?? ''),
                  style: const TextStyle(color: AppTheme.grey400, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          // Spam Reasons list if any
          if (isSpam && (item['spamReasons'] as List? ?? []).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'Lý do spam: ${(item['spamReasons'] as List).join(', ')}',
                style: const TextStyle(color: AppTheme.error, fontSize: 11),
              ),
            ),
          // Action Buttons Footer
          Container(
            color: AppTheme.grey50,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isApproved) ...[
                  IconButton(
                    onPressed: () => _toggleVerify(context, ref, isVerified),
                    icon: Icon(isVerified ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber),
                    tooltip: 'Xác thực bài đăng',
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => _toggleSpam(context, ref),
                  icon: const Icon(Icons.flag_outlined, color: AppTheme.grey600),
                  tooltip: 'Đánh dấu Spam',
                ),
                if (isPending) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _reject(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Từ chối', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _approve(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Phê duyệt', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
