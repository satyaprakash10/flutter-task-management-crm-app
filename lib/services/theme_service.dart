import 'package:flutter/material.dart';
import 'kv_store.dart';

class ThemeService {
  static const String _key = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static Future<void> init() async {
    final v = await KVStore.getString(_key);
    switch (v) {
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      case 'system':
        mode.value = ThemeMode.system;
        break;
      default:
        mode.value = ThemeMode.light;
    }
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    final s = m == ThemeMode.dark
        ? 'dark'
        : (m == ThemeMode.system ? 'system' : 'light');
    await KVStore.setString(_key, s);
  }
}
