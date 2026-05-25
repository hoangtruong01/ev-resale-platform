import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class AdminPermissionsScreen extends ConsumerStatefulWidget {
  const AdminPermissionsScreen({super.key});

  @override
  ConsumerState<AdminPermissionsScreen> createState() => _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState extends ConsumerState<AdminPermissionsScreen> {
  final List<Map<String, dynamic>> _moderators = [
    {
      'id': 'mod-01',
      'name': 'Lê Quang Huy',
      'email': 'huy.le@evnmarket.com',
      'permissions': {
        'MODERATE_POSTS': true,
        'HANDLE_SUPPORT_TICKETS': true,
        'MANAGE_ESCROW': false,
      }
    },
    {
      'id': 'mod-02',
      'name': 'Nguyễn Phương Thảo',
      'email': 'thao.nguyen@evnmarket.com',
      'permissions': {
        'MODERATE_POSTS': true,
        'HANDLE_SUPPORT_TICKETS': false,
        'MANAGE_ESCROW': false,
      }
    },
    {
      'id': 'mod-03',
      'name': 'Đặng Quốc Bảo',
      'email': 'bao.dang@evnmarket.com',
      'permissions': {
        'MODERATE_POSTS': false,
        'HANDLE_SUPPORT_TICKETS': true,
        'MANAGE_ESCROW': false,
      }
    }
  ];

  void _togglePermission(int modIndex, String key, bool value) {
    setState(() {
      _moderators[modIndex]['permissions'][key] = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật quyền cho ${_moderators[modIndex]['name']}'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Quyền Moderator'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DANH SÁCH KIỂM DUYỆT VIÊN (MODERATORS)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.grey500),
            ),
            const SizedBox(height: 12),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _moderators.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, modIndex) {
                final mod = _moderators[modIndex];
                final permissions = mod['permissions'] as Map<String, dynamic>;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: Text(mod['name'][0], style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(mod['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.grey900)),
                    subtitle: Text(mod['email'], style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: isDark ? Colors.white10 : AppTheme.grey100, height: 1),
                      ),
                      SwitchListTile(
                        value: permissions['MODERATE_POSTS'],
                        activeColor: AppTheme.primaryGreen,
                        title: const Text('Kiểm duyệt bài đăng (MODERATE_POSTS)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Quyền duyệt/từ chối sản phẩm xe điện & pin nạp lên sàn.', style: TextStyle(fontSize: 11, color: AppTheme.grey500)),
                        onChanged: (val) => _togglePermission(modIndex, 'MODERATE_POSTS', val),
                      ),
                      SwitchListTile(
                        value: permissions['HANDLE_SUPPORT_TICKETS'],
                        activeColor: AppTheme.primaryGreen,
                        title: const Text('Xử lý Tickets hỗ trợ (HANDLE_SUPPORT_TICKETS)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Quyền chat trực tiếp tranh chấp giải quyết khiếu nại khách hàng.', style: TextStyle(fontSize: 11, color: AppTheme.grey500)),
                        onChanged: (val) => _togglePermission(modIndex, 'HANDLE_SUPPORT_TICKETS', val),
                      ),
                      SwitchListTile(
                        value: permissions['MANAGE_ESCROW'],
                        activeColor: AppTheme.primaryGreen,
                        title: const Text('Quản lý Ký gửi (MANAGE_ESCROW)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Quyền can thiệp giải ngân tiền cọc hoàn cọc ví trung gian.', style: TextStyle(fontSize: 11, color: AppTheme.grey500)),
                        onChanged: (val) => _togglePermission(modIndex, 'MANAGE_ESCROW', val),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
