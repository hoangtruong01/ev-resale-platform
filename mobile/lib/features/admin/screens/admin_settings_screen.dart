import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/session_state_provider.dart';
import 'package:go_router/go_router.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống & User'),
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
          unselectedLabelColor: AppTheme.grey500,
          tabs: const [
            Tab(text: 'Cấu hình sàn'),
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
    final settingsAsync = ref.watch(_settingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (data) {
        // Only load text controllers once when data arrives
        if (_commissionCtrl.text.isEmpty) {
          _loadSettings(data);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông số vận hành sàn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Card(
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
                          const Text('Tự động kết thúc đấu giá khi hết giờ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Switch(
                            value: _autoEndAuctions,
                            onChanged: (val) => setState(() => _autoEndAuctions = val),
                            activeColor: AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu cấu hình hệ thống'),
              ),
            ],
          ),
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: AppTheme.grey50,
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
    final search = _searchCtrl.text;
    final usersAsync = ref.watch(_usersProvider(search));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm email, họ tên...',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(_usersProvider(search)),
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (res) {
                final usersList = List<Map<String, dynamic>>.from(res['users'] ?? []);

                if (usersList.isEmpty) {
                  return const Center(child: Text('Không tìm thấy người dùng nào'));
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
    String selectedRole = user['role'] ?? 'USER';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Thay đổi vai trò'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Người dùng (USER)'),
                value: 'USER',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Quản trị viên (ADMIN)'),
                value: 'ADMIN',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Điều phối viên (MODERATOR)'),
                value: 'MODERATOR',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Cập nhật'),
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
    
    // Fetch available and current permissions
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
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải quyền hạn: $e'), backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    if (context.mounted) Navigator.pop(context); // Pop loading
    if (data == null) return;

    final available = List<String>.from(data['availablePermissions'] ?? []);
    final current = List<String>.from(data['permissions'] ?? []);
    final selectedPermissions = Set<String>.from(current);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user['name'] ?? 'Ẩn danh';
    final email = user['email'] ?? 'N/A';
    final role = user['role'] ?? 'USER';
    final isBlocked = user['status'] == 'blocked';
    final isModerator = role == 'MODERATOR';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
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
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(email, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
