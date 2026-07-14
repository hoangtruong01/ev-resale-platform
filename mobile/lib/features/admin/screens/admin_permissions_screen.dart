import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

final _moderatorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/admin/users', queryParameters: {
    'role': 'MODERATOR',
    'limit': 50,
  });
  final data = res.data;
  if (data is Map && data['data'] != null) {
    return List<Map<String, dynamic>>.from(data['data']);
  }
  if (data is List) {
    return List<Map<String, dynamic>>.from(data);
  }
  return const [];
});

class AdminPermissionsScreen extends ConsumerWidget {
  const AdminPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moderatorsAsync = ref.watch(_moderatorsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Quyền Moderator'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.grey900,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_moderatorsProvider),
        child: moderatorsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text('Lỗi tải danh sách moderator: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.grey700,
                    )),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_moderatorsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (moderators) {
            if (moderators.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 64,
                            color: isDark ? Colors.white24 : AppTheme.grey300),
                        const SizedBox(height: 16),
                        Text('Chưa có moderator nào',
                            style: TextStyle(
                              color:
                                  isDark ? AppTheme.grey400 : AppTheme.grey500,
                            )),
                      ],
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DANH SÁCH KIỂM DUYỆT VIÊN (MODERATORS)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.grey500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: moderators.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, modIndex) {
                      final mod = moderators[modIndex];
                      return _ModeratorCard(moderator: mod, isDark: isDark);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeratorCard extends StatelessWidget {
  final Map<String, dynamic> moderator;
  final bool isDark;

  const _ModeratorCard({required this.moderator, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = moderator['fullName'] ?? moderator['name'] ?? 'Moderator';
    final email = moderator['email'] ?? '';
    final role = moderator['role'] ?? 'MODERATOR';

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
          child: Text(
            name.isNotEmpty ? name[0] : 'M',
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : AppTheme.grey900,
          ),
        ),
        subtitle: Text(
          '$email • $role',
          style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: isDark ? Colors.white10 : AppTheme.grey100,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppTheme.grey700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KYC: ${moderator['kycStatus'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trạng thái: ${moderator['isActive'] == true ? 'Hoạt động' : 'Tạm khóa'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey500,
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
