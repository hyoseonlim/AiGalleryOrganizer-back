import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistence of authentication credentials (tokens, email).
class AuthRepository {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userEmailKey = 'auth_user_email';

  SharedPreferences? _prefs;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedEmail;
  bool _initialized = false;

  AuthRepository._internal();

  static final AuthRepository _instance = AuthRepository._internal();

  factory AuthRepository() {
    return _instance;
  }

  Future<void> _ensurePrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _ensurePrefs();
    _cachedAccessToken = _prefs!.getString(_accessTokenKey);
    _cachedRefreshToken = _prefs!.getString(_refreshTokenKey);
    _cachedEmail = _prefs!.getString(_userEmailKey);
    _initialized = true;
  }

  Future<void> saveCredentials({
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    await initialize();
    await _prefs!.setString(_accessTokenKey, accessToken);
    await _prefs!.setString(_refreshTokenKey, refreshToken);
    await _prefs!.setString(_userEmailKey, email);

    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _cachedEmail = email;
  }

  Future<void> clear() async {
    await initialize();
    await _prefs!.remove(_accessTokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_userEmailKey);

    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedEmail = null;
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    await initialize();
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }
    await initialize();
    return _cachedRefreshToken;
  }

  Future<String?> getEmail() async {
    if (_cachedEmail != null) {
      return _cachedEmail;
    }
    await initialize();
    return _cachedEmail;
  }

  String? get cachedAccessToken => _cachedAccessToken;
}
