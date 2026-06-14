import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_notification_item.dart';

final appNotificationStoreProvider = Provider<AppNotificationStore>((ref) {
  return AppNotificationStore(const FlutterSecureStorage());
});

class AppNotificationStore {
  static const _storageKey = 'app_notification_history_v1';
  final FlutterSecureStorage _storage;

  AppNotificationStore(this._storage);

  Future<List<AppNotificationItem>> loadAll() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => AppNotificationItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<AppNotificationItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }

  Future<void> add(AppNotificationItem item) async {
    final items = await loadAll();
    final next = [item, ...items.where((e) => e.id != item.id)].take(100).toList();
    await saveAll(next);
  }

  Future<void> markAsRead(String id) async {
    final items = await loadAll();
    final next = [
      for (final item in items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    await saveAll(next);
  }

  Future<void> markAllAsRead() async {
    final items = await loadAll();
    final next = items.map((item) => item.copyWith(isRead: true)).toList();
    await saveAll(next);
  }

  Future<void> clear() => _storage.delete(key: _storageKey);
}
