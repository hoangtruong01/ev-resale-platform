enum AppNotificationType { success, error, warning, info }

enum AppNotificationOrigin { system, order, auction, chat, profile, custom }

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final AppNotificationOrigin origin;
  final bool isRead;
  final bool isImportant;
  final DateTime createdAt;
  final String? actionLabel;
  final String? route;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.origin,
    required this.isRead,
    required this.isImportant,
    required this.createdAt,
    this.actionLabel,
    this.route,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    AppNotificationType? type,
    AppNotificationOrigin? origin,
    bool? isRead,
    bool? isImportant,
    DateTime? createdAt,
    String? actionLabel,
    String? route,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      origin: origin ?? this.origin,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt ?? this.createdAt,
      actionLabel: actionLabel ?? this.actionLabel,
      route: route ?? this.route,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'origin': origin.name,
      'isRead': isRead,
      'isImportant': isImportant,
      'createdAt': createdAt.toIso8601String(),
      'actionLabel': actionLabel,
      'route': route,
    };
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: AppNotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AppNotificationType.info,
      ),
      origin: AppNotificationOrigin.values.firstWhere(
        (e) => e.name == json['origin'],
        orElse: () => AppNotificationOrigin.system,
      ),
      isRead: json['isRead'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      actionLabel: json['actionLabel'] as String?,
      route: json['route'] as String?,
    );
  }
}
