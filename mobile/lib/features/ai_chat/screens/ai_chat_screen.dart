import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/ai_chat_service.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_AiChatMessage> _messages = [];
  bool _isSending = false;
  String? _error;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(_onTextChanged);
    
    // Add initial welcome message from AI
    _messages.add(_AiChatMessage.assistant(
      'Chào bạn! 👋 Tôi là AI chuyên gia tư vấn xe điện và pin EVN.\n\n'
      '🚗 **Dịch vụ của tôi:**\n'
      '• Tư vấn chọn mua xe điện\n'
      '• Đánh giá giá trị xe & pin cũ\n'
      '• Hướng dẫn mua bán an toàn\n'
      '• Kiểm tra tình trạng pin\n'
      '• So sánh thông số kỹ thuật\n\n'
      'Hãy hỏi tôi về xe điện hoặc pin EVN nhé! ⚡',
    ));
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _charCount = _messageCtrl.text.length;
      });
    }
  }

  @override
  void dispose() {
    _messageCtrl.removeListener(_onTextChanged);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_AiChatMessage.user(text));
      _messageCtrl.clear();
      _isSending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await ref.read(aiChatServiceProvider).sendMessage(
            message: text,
            history: _buildHistory(),
          );

      if (!mounted) return;
      setState(() {
        _messages.add(_AiChatMessage.assistant(reply.response));
      });
      _scrollToBottom();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = parseApiError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  List<AiChatHistoryItem> _buildHistory() {
    final history = _messages
        .where((message) => message.content.trim().isNotEmpty)
        .map(
          (message) => AiChatHistoryItem(
            role: message.isUser ? 'user' : 'assistant',
            content: message.content,
          ),
        )
        .toList();

    if (history.length <= 10) return history;
    return history.sublist(history.length - 10);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, Color(0xFF10B981), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chat Box AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Chuyên gia xe điện toàn diện',
                  style: TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              tooltip: 'Xóa hội thoại',
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _isSending
                  ? null
                  : () => setState(() {
                        _messages.clear();
                        _messages.add(_AiChatMessage.assistant(
                          'Chào bạn! 👋 Tôi là AI chuyên gia tư vấn xe điện và pin EVN.\n\n'
                          '🚗 **Dịch vụ của tôi:**\n'
                          '• Tư vấn chọn mua xe điện\n'
                          '• Đánh giá giá trị xe & pin cũ\n'
                          '• Hướng dẫn mua bán an toàn\n'
                          '• Kiểm tra tình trạng pin\n'
                          '• So sánh thông số kỹ thuật\n\n'
                          'Hãy hỏi tôi về xe điện hoặc pin EVN nhé! ⚡',
                        ));
                        _error = null;
                      }),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.grey200,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          enabled: !_isSending,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Hỏi AI về xe điện, pin, mua bán...',
                            prefixIcon: const Icon(Icons.auto_awesome_outlined),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: isDark ? AppTheme.darkCard : AppTheme.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white12 : AppTheme.grey300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white12 : AppTheme.grey300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: !_isSending && _charCount > 0
                              ? const LinearGradient(
                                  colors: [AppTheme.primaryGreen, Color(0xFF10B981)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: _isSending || _charCount == 0 ? AppTheme.grey300 : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSending || _charCount == 0 ? null : _sendMessage,
                            customBorder: const CircleBorder(),
                            child: Center(
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🚗 Chuyên gia xe điện toàn diện • Enter để gửi • $_charCount/500',
                    style: TextStyle(
                      color: isDark ? AppTheme.grey400 : AppTheme.grey600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _AiChatMessage {
  final String content;
  final bool isUser;
  final DateTime createdAt;

  const _AiChatMessage({
    required this.content,
    required this.isUser,
    required this.createdAt,
  });

  factory _AiChatMessage.user(String content) => _AiChatMessage(
        content: content,
        isUser: true,
        createdAt: DateTime.now(),
      );

  factory _AiChatMessage.assistant(String content) => _AiChatMessage(
        content: content,
        isUser: false,
        createdAt: DateTime.now(),
      );
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -6.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8.0, bottom: 4.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF34D399), AppTheme.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 15,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.grey100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI đang suy nghĩ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                _BouncingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _AiChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    final avatar = Container(
      width: 32,
      height: 32,
      decoration: isUser
          ? const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF34D399), AppTheme.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome,
        color: Colors.white,
        size: 15,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppTheme.primaryGreen, Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : (isDark ? AppTheme.darkCard : AppTheme.grey100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.grey200,
                      ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : (isDark ? Colors.white : AppTheme.grey800),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }
}
