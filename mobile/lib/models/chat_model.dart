import 'user_model.dart';

class ChatRoomModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? vehicleId;
  final String? batteryId;
  final UserModel? buyer;
  final UserModel? seller;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final String createdAt;
  final String updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.vehicleId,
    this.batteryId,
    this.buyer,
    this.seller,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) => ChatRoomModel(
        id: json['id'] ?? '',
        buyerId: json['buyerId'] ?? '',
        sellerId: json['sellerId'] ?? '',
        vehicleId: json['vehicleId'],
        batteryId: json['batteryId'],
        buyer: json['buyer'] != null ? UserModel.fromJson(json['buyer']) : null,
        seller: json['seller'] != null
            ? UserModel.fromJson(json['seller'])
            : null,
        lastMessage: json['messages'] != null && (json['messages'] as List).isNotEmpty
            ? ChatMessageModel.fromJson((json['messages'] as List).last)
            : null,
        unreadCount: json['unreadCount'] ?? 0,
        createdAt: json['createdAt'] ?? '',
        updatedAt: json['updatedAt'] ?? '',
      );

  UserModel? getOtherUser(String currentUserId) {
    if (buyerId == currentUserId) return seller;
    return buyer;
  }
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final Map<String, dynamic>? metadata;
  final String? readAt;
  final String createdAt;
  final UserModel? sender;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.metadata,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        senderId: json['senderId'] ?? '',
        content: json['content'] ?? '',
        metadata: json['metadata'],
        readAt: json['readAt'],
        createdAt: json['createdAt'] ?? '',
        sender: json['sender'] != null
            ? UserModel.fromJson(json['sender'])
            : null,
      );

  bool get isRead => readAt != null;
  bool isMine(String userId) => senderId == userId;
}
