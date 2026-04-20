import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/chat_model.dart';

final chatRoomsProvider = FutureProvider<List<ChatRoomModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }

  final dio = ref.watch(dioProvider);
  final response = await dio.get('/chat/rooms', queryParameters: {
    'userId': user.id,
  });

  final payload = response.data;
  if (payload is! List) {
    return const [];
  }

  return payload
      .whereType<Map>()
      .map((item) => ChatRoomModel.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidate(chatRoomsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(chatRoomsProvider),
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
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
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.message_outlined,
                      size: 52,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsProvider);
            },
            child: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) {
              final room = rooms[i];
              final currentUserId = user?.id ?? '';
              final otherUser = room.getOtherUser(currentUserId);
              final lastMessage = room.lastMessage;

              return ListTile(
                onTap: () => context.push('/chat/${room.id}'),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  child: otherUser?.avatar != null
                      ? ClipOval(
                          child: Image.network(
                            otherUser!.avatar!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        )
                      : const Icon(Icons.person, color: AppTheme.primaryGreen),
                ),
                title: Text(
                  otherUser?.displayName ?? 'Người dùng',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  lastMessage?.content.isNotEmpty == true
                      ? lastMessage!.content
                      : 'Chưa có tin nhắn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.grey600, fontSize: 13),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastMessage != null
                          ? AppUtils.timeAgo(lastMessage.createdAt)
                          : AppUtils.timeAgo(room.updatedAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.grey500),
                    ),
                    const SizedBox(height: 4),
                    if (room.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${room.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          );
        },
      ),
    );
  }
}
