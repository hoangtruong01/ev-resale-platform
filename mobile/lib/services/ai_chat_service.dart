import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';

final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService(ref.watch(dioProvider));
});

class AiChatService {
  final Dio _dio;
  AiChatService(this._dio);

  Future<AiChatResponse> sendMessage({
    required String message,
    List<AiChatHistoryItem> history = const [],
    Map<String, dynamic>? context,
  }) async {
    final response = await _dio.post('/ai/chat', data: {
      'message': message,
      if (history.isNotEmpty)
        'history': history.map((item) => item.toJson()).toList(),
      if (context != null && context.isNotEmpty) 'context': context,
    });

    return AiChatResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class AiChatHistoryItem {
  final String role;
  final String content;

  const AiChatHistoryItem({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class AiChatResponse {
  final String response;
  final String? timestamp;
  final String? model;

  const AiChatResponse({
    required this.response,
    this.timestamp,
    this.model,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      response: json['response'] as String? ?? '',
      timestamp: json['timestamp'] as String?,
      model: json['model'] as String?,
    );
  }
}
