import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistence of user-configurable settings.
class SettingsRepository {
  static const String _wifiOnlyKey = 'settings_wifi_only_upload';
  static const String _darkModeKey = 'settings_dark_mode';

  SettingsRepository._internal();

  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get wifiOnlyUpload => _prefs?.getBool(_wifiOnlyKey) ?? false;

  Future<void> setWifiOnlyUpload(bool value) async {
    await initialize();
    await _prefs!.setBool(_wifiOnlyKey, value);
  }

  bool get isDarkMode => _prefs?.getBool(_darkModeKey) ?? false;

  Future<void> setDarkMode(bool value) async {
    await initialize();
    await _prefs!.setBool(_darkModeKey, value);
  }
}
