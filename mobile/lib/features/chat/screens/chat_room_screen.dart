import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../widgets/contract_message_card.dart';

// ─── Chat message model ───────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.createdAt,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: sender?['fullName'] as String? ?? 'Người dùng',
      senderAvatar: sender?['avatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  bool get isContractMessage =>
      metadata != null && metadata!['type'] == 'CONTRACT';
}

// ─── Room info provider ──────────────────────────────────────────────────────

final chatRoomProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, roomId) async {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/chat/rooms/$roomId');
    return Map<String, dynamic>.from(res.data as Map);
  },
);

// ─── Chat Room Screen ─────────────────────────────────────────────────────────

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  io.Socket? _socket;
  bool _socketConnected = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _initSocket() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _socket = io.io(
      '${AppConstants.baseUrl.replaceAll('/api', '')}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'userId': user.id})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      setState(() => _socketConnected = true);
      _socket!.emit('joinRoom', {
        'roomId': widget.roomId,
        'userId': user.id,
      });
    });

    _socket!.on('chat:history', (data) {
      if (data is Map && data['messages'] is List) {
        final msgs = (data['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        setState(() {
          _messages.clear();
          _messages.addAll(msgs);
          _loadingHistory = false;
        });
        _scrollToBottom();
      }
    });

    _socket!.on('chat:message', (data) {
      if (data is Map) {
        final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    _socket!.on('disconnect', (_) {
      setState(() => _socketConnected = false);
    });

    _socket!.connect();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || !_socketConnected) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _socket!.emit('sendMessage', {
      'roomId': widget.roomId,
      'senderId': user.id,
      'content': text,
    });

    _messageCtrl.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _proposeDeal() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Show dialog to enter agreed price
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đề xuất hợp đồng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập giá thỏa thuận để gửi yêu cầu ký hợp đồng cho cả hai bên.',
              style: TextStyle(fontSize: 13, color: AppTheme.grey600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá thỏa thuận (VNĐ) *',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
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
            child: const Text('Gửi hợp đồng'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/chat/rooms/${widget.roomId}/propose-contract',
        data: {
          'agreedPrice': priceCtrl.text.trim(),
          if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
        },
      );

      // The system message was already sent; we just update via socket event
      // But also manually add it if we got it in response
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['systemMessage'] != null) {
        final msg =
            ChatMessage.fromJson(data['systemMessage'] as Map<String, dynamic>);
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu ký hợp đồng!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final roomInfo = ref.watch(chatRoomProvider(widget.roomId));

    final otherUser = roomInfo.when(
      data: (room) {
        final buyer = room['buyer'] as Map<String, dynamic>?;
        final seller = room['seller'] as Map<String, dynamic>?;
        if (buyer?['id'] == user?.id) return seller;
        return buyer;
      },
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
              child: otherUser?['avatar'] != null
                  ? ClipOval(
                      child: Image.network(
                        otherUser!['avatar'] as String,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppTheme.primaryGreen,
                          size: 18,
                        ),
                      ),
                    )
                  : const Icon(Icons.person, color: AppTheme.primaryGreen, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser?['fullName'] as String? ?? 'Người dùng',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _socketConnected
                            ? AppTheme.success
                            : AppTheme.grey400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _socketConnected ? 'Đang kết nối' : 'Ngoại tuyến',
                      style: TextStyle(
                        fontSize: 11,
                        color: _socketConnected
                            ? AppTheme.success
                            : AppTheme.grey400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // "Chốt deal" button
          Tooltip(
            message: 'Đề xuất hợp đồng',
            child: IconButton(
              icon: const Icon(Icons.handshake_outlined),
              onPressed: _proposeDeal,
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Bắt đầu cuộc trò chuyện!',
                          style: TextStyle(color: AppTheme.grey400),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          if (msg.isContractMessage) {
                            final meta = msg.metadata!;
                            return ContractMessageCard(
                              contractId: meta['contractId'] as String,
                              transactionId: meta['transactionId'] as String,
                              assetName: meta['assetName'] as String? ?? 'Sản phẩm',
                              agreedPrice:
                                  (meta['agreedPrice'] as num?)?.toDouble() ?? 0,
                              proposedByUserId:
                                  meta['proposedBy'] as String? ?? '',
                              currentUserId: user?.id ?? '',
                            );
                          }
                          return _MessageBubble(
                            msg: msg,
                            isMine: msg.senderId == user?.id,
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.grey50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.grey200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image_outlined,
                              color: AppTheme.grey400),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _sendMessage,
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

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMine;
  const _MessageBubble({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              Text(
                msg.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppTheme.grey900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white70 : AppTheme.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
