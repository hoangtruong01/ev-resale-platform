import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/app_utils.dart';
import '../../../widgets/app_network_image.dart';

// Stub - connect to chat service
final chatRoomsProvider = FutureProvider<List<dynamic>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [];
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message_outlined,
                        size: 52, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy liên hệ người bán để bắt đầu\ncuộc trò chuyện',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.grey600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/batteries'),
                    child: const Text('Xem tin đăng'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
