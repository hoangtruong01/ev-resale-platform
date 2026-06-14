import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/models/app_notification_item.dart';

class AppToastController {
  static final AppToastController instance = AppToastController._();
  AppToastController._();

  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  GlobalKey<ScaffoldMessengerState> get messengerKey => _messengerKey;

  void show(
    BuildContext context, {
    required String title,
    required String message,
    required AppNotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    _showOnMessenger(
      messenger,
      title: title,
      message: message,
      type: type,
      duration: duration,
    );
  }

  void showGlobal({
    required String title,
    required String message,
    required AppNotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    _showOnMessenger(
      messenger,
      title: title,
      message: message,
      type: type,
      duration: duration,
    );
  }

  void _showOnMessenger(
    ScaffoldMessengerState messenger, {
    required String title,
    required String message,
    required AppNotificationType type,
    required Duration duration,
  }) {
    final color = _color(type);
    final icon = _icon(type);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          content: _ToastContent(
            title: title,
            message: message,
            color: color,
            icon: icon,
          ),
        ),
      );
  }

  Color _color(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return AppTheme.success;
      case AppNotificationType.error:
        return AppTheme.error;
      case AppNotificationType.warning:
        return AppTheme.warning;
      case AppNotificationType.info:
        return AppTheme.info;
    }
  }

  IconData _icon(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return Icons.check_circle_rounded;
      case AppNotificationType.error:
        return Icons.error_rounded;
      case AppNotificationType.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationType.info:
        return Icons.info_rounded;
    }
  }
}

class AppToast {
  static void success(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.show(
      context,
      title: title,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.show(
      context,
      title: title,
      message: message,
      type: AppNotificationType.error,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.show(
      context,
      title: title,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  static void info(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.show(
      context,
      title: title,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
    );
  }

  static void globalSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.showGlobal(
      title: title,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  static void globalError({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.showGlobal(
      title: title,
      message: message,
      type: AppNotificationType.error,
      duration: duration,
    );
  }

  static void globalWarning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.showGlobal(
      title: title,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  static void globalInfo({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppToastController.instance.showGlobal(
      title: title,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
    );
  }
}

class _ToastContent extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;

  const _ToastContent({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13, color: AppTheme.grey600, height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
