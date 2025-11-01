import 'package:flutter/material.dart';
import '../../../settings/data/settings_repository.dart';

/// Controls app-wide theme mode and persists the preference.
class ThemeController extends ChangeNotifier {
  ThemeController._internal();

  static final ThemeController _instance = ThemeController._internal();
  static ThemeController get instance => _instance;

  ThemeMode _themeMode = ThemeMode.light;
  final SettingsRepository _settingsRepository = SettingsRepository();

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    await _settingsRepository.initialize();
    _themeMode = _settingsRepository.isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _settingsRepository.setDarkMode(isDark);
    notifyListeners();
  }
}
