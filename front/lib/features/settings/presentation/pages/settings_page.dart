import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:front/features/auth/data/auth_repository.dart';
import 'package:front/features/gallery/data/cache/photo_cache_service.dart';
import 'package:front/features/settings/data/settings_repository.dart';
import 'package:front/features/shared/presentation/controllers/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthRepository _authRepository = AuthRepository();
  final PhotoCacheService _cacheService = PhotoCacheService();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final ThemeController _themeController = ThemeController.instance;

  String? _userEmail;
  bool _wifiOnlyUpload = false;
  bool _isDarkMode = false;
  bool _isClearingCache = false;
  bool _isLoadingCache = true;
  int _cacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _settingsRepository.initialize();

    final email = await _authRepository.getEmail();
    final wifiOnly = _settingsRepository.wifiOnlyUpload;
    final isDark = _settingsRepository.isDarkMode;
    await _loadCacheStats();

    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _wifiOnlyUpload = wifiOnly;
      _isDarkMode = isDark;
    });
  }

  Future<void> _loadCacheStats() async {
    setState(() {
      _isLoadingCache = true;
    });
    final stats = await _cacheService.getCacheStats();
    final totalSize = stats['totalSizeBytes'] as int? ?? 0;
    if (!mounted) return;
    setState(() {
      _cacheSizeBytes = totalSize;
      _isLoadingCache = false;
    });
  }

  Future<void> _handleLogout() async {
    await _authRepository.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _handleClearCache() async {
    setState(() {
      _isClearingCache = true;
    });
    await _cacheService.clearAllCache();
    await _loadCacheStats();
    if (!mounted) return;
    setState(() {
      _isClearingCache = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('캐시가 삭제되었습니다.')));
  }

  Future<void> _onWifiToggle(bool value) async {
    setState(() {
      _wifiOnlyUpload = value;
    });
    await _settingsRepository.setWifiOnlyUpload(value);
  }

  Future<void> _onDarkModeToggle(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await _themeController.setDarkMode(value);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final exponent = math.min(
      (math.log(bytes.toDouble()) / math.log(1024)).floor(),
      units.length - 1,
    );
    final size = bytes / math.pow(1024, exponent).toDouble();
    return '${size.toStringAsFixed(size >= 10 || size == size.floorToDouble() ? 0 : 1)} ${units[exponent]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _buildSectionTitle(title: '계정'),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(_userEmail ?? '로그인 정보가 없습니다'),
            subtitle: const Text('로그아웃하면 초기 화면으로 이동합니다'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: OutlinedButton(
              onPressed: () {
                _handleLogout();
              },
              child: const Text('로그아웃'),
            ),
          ),
          const Divider(),
          _buildSectionTitle(title: '환경 설정'),
          SwitchListTile(
            title: const Text('Wi-Fi로만 업로드'),
            subtitle: const Text('모바일 데이터 사용 시 업로드하지 않습니다'),
            value: _wifiOnlyUpload,
            onChanged: (value) {
              _onWifiToggle(value);
            },
          ),
          SwitchListTile(
            title: const Text('다크 모드'),
            value: _isDarkMode,
            onChanged: (value) {
              _onDarkModeToggle(value);
            },
          ),
          const Divider(),
          _buildSectionTitle(title: '캐시 관리'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('캐시 사용량'),
            subtitle: Text(
              _isLoadingCache ? '계산 중...' : _formatBytes(_cacheSizeBytes),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: OutlinedButton.icon(
              onPressed: _isClearingCache
                  ? null
                  : () {
                      _handleClearCache();
                    },
              icon: _isClearingCache
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('캐시 삭제'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
