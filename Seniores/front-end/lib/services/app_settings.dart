import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ValueNotifier<ThemeMode> {
  AppSettings._() : super(ThemeMode.light);
  static final instance = AppSettings._();
  Future<void> load() async {
    final mode = (await SharedPreferences.getInstance()).getString('theme');
    value = ThemeMode.values
        .firstWhere((m) => m.name == mode, orElse: () => ThemeMode.light);
  }

  Future<void> change(ThemeMode mode) async {
    await (await SharedPreferences.getInstance()).setString('theme', mode.name);
    value = mode;
  }
}
