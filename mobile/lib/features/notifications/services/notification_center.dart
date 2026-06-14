import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/app_toast.dart';
import '../models/app_notification_item.dart';
import '../providers/app_notification_providers.dart';

final appNotificationCenterProvider = Provider<AppNotificationCenter>((ref) {
  return AppNotificationCenter(ref);
});

class AppNotificationCenter {
  final Ref _ref;

  AppNotificationCenter(this._ref);

  Future<void> showToast(
    BuildContext context, {
    required String title,
    required String message,
    required AppNotificationType type,
    bool saveToHistory = false,
    AppNotificationOrigin origin = AppNotificationOrigin.system,
    bool isImportant = true,
    String? actionLabel,
    String? route,
    Duration duration = const Duration(seconds: 3),
  }) async {
    AppToastController.instance.show(
      context,
      title: title,
      message: message,
      type: type,
      duration: duration,
    );

    if (saveToHistory) {
      await _ref.read(appNotificationHistoryProvider.notifier).push(
            title: title,
            message: message,
            type: type,
            origin: origin,
            isImportant: isImportant,
            actionLabel: actionLabel,
            route: route,
          );
    }
  }

  Future<void> showGlobalToast({
    required String title,
    required String message,
    required AppNotificationType type,
    bool saveToHistory = false,
    AppNotificationOrigin origin = AppNotificationOrigin.system,
    bool isImportant = true,
    String? actionLabel,
    String? route,
    Duration duration = const Duration(seconds: 3),
  }) async {
    AppToastController.instance.showGlobal(
      title: title,
      message: message,
      type: type,
      duration: duration,
    );

    if (saveToHistory) {
      await _ref.read(appNotificationHistoryProvider.notifier).push(
            title: title,
            message: message,
            type: type,
            origin: origin,
            isImportant: isImportant,
            actionLabel: actionLabel,
            route: route,
          );
    }
  }

  Future<void> saveImportantNotification({
    required String title,
    required String message,
    required AppNotificationType type,
    AppNotificationOrigin origin = AppNotificationOrigin.system,
    String? actionLabel,
    String? route,
  }) {
    return _ref.read(appNotificationHistoryProvider.notifier).push(
          title: title,
          message: message,
          type: type,
          origin: origin,
          isImportant: true,
          actionLabel: actionLabel,
          route: route,
        );
  }
}
