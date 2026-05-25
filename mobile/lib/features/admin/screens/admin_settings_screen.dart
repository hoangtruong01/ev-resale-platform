import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/session_state_provider.dart';
import 'package:go_router/go_router.dart';
import 'kyc_review_detail_screen.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AdminSettingsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: Text(_tabController.index == 0 ? 'Cấu hình phí' : 'Quản lý người dùng'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horizontal_circle_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Chuyển về User Mode',
            onPressed: () {
              ref.read(adminModeProvider.notifier).state = false;
              context.go('/');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: isDark ? AppTheme.grey400 : AppTheme.grey500,
          tabs: const [
            Tab(text: 'Cấu hình phí'),
            Tab(text: 'Người dùng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlatformConfigSection(),
          _UserManagementSection(),
        ],
      ),
    );
  }
}

// ─── SECTION 1: Platform Config ───────────────────────────────────────────────

class _PlatformConfigSection extends ConsumerStatefulWidget {
  const _PlatformConfigSection();

  @override
  ConsumerState<_PlatformConfigSection> createState() => _PlatformConfigSectionState();
}

class _PlatformConfigSectionState extends ConsumerState<_PlatformConfigSection> {
  final _commissionCtrl = TextEditingController();
  final _maxDurationCtrl = TextEditingController();
  final _minIncrementCtrl = TextEditingController();
  bool _autoEndAuctions = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _maxDurationCtrl.dispose();
    _minIncrementCtrl.dispose();
    super.dispose();
  }

  void _loadSettings(List<dynamic> settings) {
    for (final s in settings) {
      if (s is Map) {
        final key = s['key'];
        final val = s['value'];
        if (key == 'commissionRate') {
          _commissionCtrl.text = val?.toString() ?? '0';
        } else if (key == 'maxAuctionDuration') {
          _maxDurationCtrl.text = val?.toString() ?? '7';
        } else if (key == 'minBidIncrement') {
          _minIncrementCtrl.text = val?.toString() ?? '50000';
        } else if (key == 'autoEndAuctions') {
          _autoEndAuctions = val == 'true' || val == true;
        }
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/admin/settings', data: {
        'commissionRate': double.tryParse(_commissionCtrl.text) ?? 0.0,
        'maxAuctionDuration': int.tryParse(_maxDurationCtrl.text) ?? 7,
        'minBidIncrement': double.tryParse(_minIncrementCtrl.text) ?? 50000.0,
        'autoEndAuctions': _autoEndAuctions,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật cấu hình hệ thống'), backgroundColor: AppTheme.success),
        );
        ref.invalidate(_settingsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsAsync = ref.watch(_settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG SỐ VẬN HÀNH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.grey500,
            ),
          ),
          const SizedBox(height: 12),

          settingsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (data) {
              if (_commissionCtrl.text.isEmpty) {
                _loadSettings(data);
              }

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingTextField(
                        label: 'Phần trăm hoa hồng sàn (%)',
                        controller: _commissionCtrl,
                        hint: 'Ví dụ: 2.5',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 16),
                      _SettingTextField(
                        label: 'Thời gian đấu giá tối đa (ngày)',
                        controller: _maxDurationCtrl,
                        hint: 'Ví dụ: 7',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _SettingTextField(
                        label: 'Mức tăng bước giá tối thiểu (VND)',
                        controller: _minIncrementCtrl,
                        hint: 'Ví dụ: 50000',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Tự động kết thúc đấu giá khi hết giờ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: _autoEndAuctions,
                            onChanged: (val) => setState(() => _autoEndAuctions = val),
                            activeColor: AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Lưu thông số', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

final _settingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/settings');
  return res.data as List<dynamic>;
});

class _SettingTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _SettingTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : AppTheme.grey700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: isDark ? AppTheme.darkCard : AppTheme.grey50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.grey200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.grey200)),
          ),
        ),
      ],
    );
  }
}

// ─── SECTION 2: User Management ───────────────────────────────────────────────

class _UserManagementSection extends ConsumerStatefulWidget {
  const _UserManagementSection();

  @override
  ConsumerState<_UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends ConsumerState<_UserManagementSection> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final search = _searchCtrl.text;
    final usersAsync = ref.watch(_usersProvider(search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => setState(() {}),
              style: TextStyle(color: isDark ? Colors.white : AppTheme.grey900),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm email, họ tên...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.grey400),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : AppTheme.grey500),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(_usersProvider(search)),
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey700))),
              data: (res) {
                final usersList = List<Map<String, dynamic>>.from(res['users'] ?? []);

                if (usersList.isEmpty) {
                  return Center(child: Text('Không tìm thấy người dùng nào', style: TextStyle(color: isDark ? AppTheme.grey400 : AppTheme.grey500)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: usersList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = usersList[index];
                    return _UserCard(
                      user: user,
                      onActionDone: () => ref.invalidate(_usersProvider(search)),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

final _usersProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, search) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/users', queryParameters: {
    'limit': 50,
    'page': 1,
    if (search.isNotEmpty) 'search': search,
  });
  return Map<String, dynamic>.from(res.data);
});

class _UserCard extends ConsumerWidget {
  final Map<String, dynamic> user;
  final VoidCallback onActionDone;

  const _UserCard({required this.user, required this.onActionDone});

  Future<void> _toggleBlock(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final id = user['id'];
    final isBlocked = user['status'] == 'blocked';
    final action = isBlocked ? 'unblock' : 'block';

    try {
      await dio.put('/admin/users/$id/$action');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBlocked ? 'Đã mở khoá tài khoản' : 'Đã khoá tài khoản người dùng'),
            backgroundColor: isBlocked ? AppTheme.success : AppTheme.error,
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

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedRole = user['role'] ?? 'USER';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          title: Text(
            'Thay đổi vai trò',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.grey900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Người dùng (USER)', style: TextStyle(color: isDark ? Colors.white80 : AppTheme.grey800)),
                value: 'USER',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
                activeColor: AppTheme.primaryGreen,
              ),
              RadioListTile<String>(
                title: Text('Quản trị viên (ADMIN)', style: TextStyle(color: isDark ? Colors.white80 : AppTheme.grey800)),
                value: 'ADMIN',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
                activeColor: AppTheme.primaryGreen,
              ),
              RadioListTile<String>(
                title: Text('Điều phối viên (MODERATOR)', style: TextStyle(color: isDark ? Colors.white80 : AppTheme.grey800)),
                value: 'MODERATOR',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Huỷ',
                style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Cập nhật',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final dio = ref.read(dioProvider);
    final id = user['id'];
    try {
      await dio.put('/admin/users/$id/role', data: {'role': selectedRole});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật vai trò người dùng'), backgroundColor: AppTheme.success),
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

  Future<void> _managePermissions(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final id = user['id'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? data;
    try {
      final res = await dio.get('/admin/moderators/$id/permissions');
      data = Map<String, dynamic>.from(res.data);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải quyền hạn: $e'), backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    if (context.mounted) Navigator.pop(context);
    if (data == null) return;

    final available = List<String>.from(data['availablePermissions'] ?? []);
    final current = List<String>.from(data['permissions'] ?? []);
    final selectedPermissions = Set<String>.from(current);

    if (!context.mounted) return;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Quyền hạn Moderator'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((perm) {
                final isChecked = selectedPermissions.contains(perm);
                final label = switch (perm) {
                  'MODERATE_POSTS' => 'Duyệt bài viết xe/pin',
                  'MARK_SPAM' => 'Đánh dấu spam tin đăng',
                  'HANDLE_SUPPORT_TICKETS' => 'Xử lý ticket hỗ trợ',
                  _ => perm
                };

                return CheckboxListTile(
                  title: Text(label),
                  value: isChecked,
                  onChanged: (val) {
                    setModalState(() {
                      if (val == true) {
                        selectedPermissions.add(perm);
                      } else {
                        selectedPermissions.remove(perm);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ', style: TextStyle(color: AppTheme.grey600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu quyền'),
            ),
          ],
        ),
      ),
    );

    if (updated != true) return;

    try {
      await dio.put('/admin/moderators/$id/permissions', data: {
        'permissions': selectedPermissions.toList(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật quyền hạn Moderator'), backgroundColor: AppTheme.success),
        );
        onActionDone();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu quyền: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = user['name'] ?? 'Ẩn danh';
    final email = user['email'] ?? 'N/A';
    final phone = user['phone'] ?? 'Chưa cung cấp';
    final role = user['role'] ?? 'USER';
    final isBlocked = user['status'] == 'blocked';
    final kycStatus = user['kycStatus'] ?? 'UNVERIFIED';
    final createdAtStr = user['createdAt'] != null ? AppUtils.timeAgo(user['createdAt']) : 'N/A';
    final profile = user['profile'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppTheme.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header (Avatar + Name)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                      child: user['avatar'] == null
                          ? const Icon(Icons.person, size: 32, color: AppTheme.primaryGreen)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.grey900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBlocked 
                                  ? AppTheme.error.withValues(alpha: 0.1) 
                                  : AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBlocked ? 'ĐÃ KHÓA' : role,
                              style: TextStyle(
                                color: isBlocked ? AppTheme.error : AppTheme.primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: isDark ? Colors.white10 : AppTheme.grey100, height: 1),
                const SizedBox(height: 20),
                
                // Information section
                _buildInfoTitle(context, 'Thông tin cá nhân'),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.email_outlined, 'Email', email),
                _buildInfoRow(context, Icons.phone_android_outlined, 'Số điện thoại', phone),
                _buildInfoRow(context, Icons.calendar_month_outlined, 'Ngày tham gia', createdAtStr),
                
                const SizedBox(height: 20),
                _buildInfoTitle(context, 'Trạng thái eKYC'),
                const SizedBox(height: 12),
                _buildKycStatusRow(context, kycStatus),
                
                if (profile != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoTitle(context, 'Thông tin chi tiết tài liệu eKYC'),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, Icons.badge_outlined, 'Số CMND/CCCD', profile['idNumber'] ?? 'Chưa cung cấp'),
                  _buildInfoRow(context, Icons.assignment_ind_outlined, 'Loại giấy tờ', profile['idType'] ?? 'CMND/CCCD'),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white54 : AppTheme.grey500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : AppTheme.grey400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.grey800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycStatusRow(BuildContext context, String status) {
    final kycColor = switch (status) {
      'APPROVED' => AppTheme.success,
      'PENDING' => AppTheme.warning,
      'REJECTED' => AppTheme.error,
      _ => AppTheme.grey400
    };
    final kycText = switch (status) {
      'APPROVED' => 'eKYC đã xác thực thành công',
      'PENDING' => 'Đang chờ Admin duyệt eKYC',
      'REJECTED' => 'eKYC bị từ chối / eKYC thất bại',
      _ => 'Chưa cập nhật tài liệu eKYC'
    };

    return Row(
      children: [
        Icon(
          status == 'APPROVED'
              ? Icons.verified_user_rounded
              : status == 'PENDING'
                  ? Icons.pending_actions_rounded
                  : status == 'REJECTED'
                      ? Icons.gpp_bad_rounded
                      : Icons.help_outline_rounded,
          size: 18,
          color: kycColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            kycText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kycColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = user['name'] ?? 'Ẩn danh';
    final email = user['email'] ?? 'N/A';
    final role = user['role'] ?? 'USER';
    final isBlocked = user['status'] == 'blocked';
    final isModerator = role == 'MODERATOR';
    final kycStatus = user['kycStatus'] ?? 'UNVERIFIED';
    final profile = user['profile'] as Map<String, dynamic>?;

    return Card(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.white10 : AppTheme.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showUserDetails(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.grey900)),
                        Text(email, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              kycStatus == 'APPROVED'
                                  ? Icons.verified_user_rounded
                                  : kycStatus == 'PENDING'
                                      ? Icons.pending_actions_rounded
                                      : kycStatus == 'REJECTED'
                                          ? Icons.gpp_bad_rounded
                                          : Icons.help_outline_rounded,
                              size: 14,
                              color: kycStatus == 'APPROVED'
                                  ? AppTheme.success
                                  : kycStatus == 'PENDING'
                                      ? AppTheme.warning
                                      : kycStatus == 'REJECTED'
                                          ? AppTheme.error
                                          : AppTheme.grey400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              kycStatus == 'APPROVED'
                                  ? 'eKYC thành công'
                                  : kycStatus == 'PENDING'
                                      ? 'eKYC chờ duyệt'
                                      : kycStatus == 'REJECTED'
                                          ? 'eKYC thất bại'
                                          : 'Chưa cập nhật eKYC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kycStatus == 'APPROVED'
                                    ? AppTheme.success
                                    : kycStatus == 'PENDING'
                                        ? AppTheme.warning
                                        : kycStatus == 'REJECTED'
                                            ? AppTheme.error
                                            : AppTheme.grey500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isBlocked ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBlocked ? 'Đã khóa' : role,
                      style: TextStyle(
                        color: isBlocked ? AppTheme.error : AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (kycStatus != 'UNVERIFIED' && profile != null) ...[
                  TextButton.icon(
                    onPressed: () async {
                      final profileDataForScreen = Map<String, dynamic>.from(profile);
                      profileDataForScreen['user'] = {
                        'id': user['id'],
                        'fullName': user['name'] ?? name,
                        'email': email,
                        'phone': user['phone'] ?? '',
                        'avatar': user['avatar'],
                      };

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KycReviewDetailScreen(
                            userId: user['id'] ?? '',
                            profileData: profileDataForScreen,
                          ),
                        ),
                      );
                      if (result == true) {
                        onActionDone();
                      }
                    },
                    icon: const Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryGreen),
                    label: const Text(
                      'Duyệt eKYC',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isModerator) ...[
                  TextButton.icon(
                    onPressed: () => _managePermissions(context, ref),
                    icon: const Icon(Icons.lock_person_outlined, size: 16),
                    label: const Text('Quyền hạn', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () => _changeRole(context, ref),
                  icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                  label: const Text('Đổi vai trò', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _toggleBlock(context, ref),
                  icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.lock_outline, size: 16, color: isBlocked ? AppTheme.success : AppTheme.error),
                  label: Text(
                    isBlocked ? 'Mở khoá' : 'Khoá',
                    style: TextStyle(fontSize: 12, color: isBlocked ? AppTheme.success : AppTheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION 3: eKYC Requests ──────────────────────────────────────────────────

class _KycRequestSection extends ConsumerWidget {
  const _KycRequestSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingKyc = ref.watch(_pendingKycProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_pendingKycProvider),
      child: pendingKyc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Lỗi: ${error.toString()}', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.grey700)),
              TextButton(
                onPressed: () => ref.invalidate(_pendingKycProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 64, color: AppTheme.grey300),
                      const SizedBox(height: 16),
                      Text(
                        'Không có yêu cầu eKYC nào đang chờ phê duyệt',
                        style: TextStyle(color: isDark ? AppTheme.grey400 : AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final user = profile['user'] as Map<String, dynamic>?;

              return _KycRequestCard(
                profileId: profile['id'],
                userId: user?['id'] ?? '',
                fullName: user?['fullName'] ?? 'Người dùng EVN',
                email: user?['email'] ?? 'N/A',
                phone: user?['phone'] ?? 'N/A',
                avatar: user?['avatar'],
                submittedAt: profile['updatedAt'] ?? profile['createdAt'] ?? '',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KycReviewDetailScreen(
                        userId: user?['id'] ?? '',
                        profileData: profile,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(_pendingKycProvider);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

final _pendingKycProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users/kyc/pending');
  return List<Map<String, dynamic>>.from(res.data);
});

class _KycRequestCard extends StatelessWidget {
  final String profileId;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String? avatar;
  final String submittedAt;
  final VoidCallback onTap;

  const _KycRequestCard({
    required this.profileId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatar,
    required this.submittedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
              child: avatar == null
                  ? const Icon(Icons.person, color: AppTheme.primaryGreen)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SĐT: $phone',
                    style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ngày gửi: ${_formatDate(submittedAt)}',
                    style: const TextStyle(color: AppTheme.grey400, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.chevron_right, color: AppTheme.grey400),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đang chờ',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate.split('T')[0];
    }
  }
}
