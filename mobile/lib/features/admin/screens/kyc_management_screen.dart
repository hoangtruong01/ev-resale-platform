import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import 'kyc_review_detail_screen.dart';

/// Screen for Admin to view and manage pending KYC registration requests.
class KycManagementScreen extends ConsumerWidget {
  const KycManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingKyc = ref.watch(_pendingKycProvider);

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text(
          'Quản lý eKYC',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.grey900,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_pendingKycProvider),
        child: pendingKyc.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                const SizedBox(height: 16),
                Text('Lỗi: ${error.toString()}'),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 64, color: AppTheme.grey300),
                        SizedBox(height: 16),
                        Text(
                          'Không có yêu cầu eKYC nào đang chờ phê duyệt',
                          style: TextStyle(color: AppTheme.grey600),
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
      ),
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _pendingKycProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users/kyc/pending');
  return List<Map<String, dynamic>>.from(res.data);
});

// ─── Widgets ──────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.grey900.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SĐT: $phone',
                    style: const TextStyle(color: AppTheme.grey600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ngày gửi: ${_formatDate(submittedAt)}',
                    style: TextStyle(
                      color: AppTheme.grey500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
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
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đang chờ',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 10,
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
