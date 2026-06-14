import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleNotifier extends StateNotifier<Locale?> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'selected_locale';

  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final code = await _storage.read(key: _key);
      if (code != null) {
        super.state = Locale(code);
      }
    } catch (_) {}
  }

  @override
  set state(Locale? value) {
    super.state = value;
    _saveLocale(value);
  }

  Future<void> _saveLocale(Locale? value) async {
    try {
      if (value != null) {
        await _storage.write(key: _key, value: value.languageCode);
      } else {
        await _storage.delete(key: _key);
      }
    } catch (_) {}
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);
