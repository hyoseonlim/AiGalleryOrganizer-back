import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/photo_models.dart';

/// Logging helper
void _log(String message, {bool isError = false}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'PhotoCache',
    level: isError ? 900 : 500,
  );
}

/// Service for caching photo metadata and thumbnails
class PhotoCacheService {
  static const String _metadataPrefix = 'photo_metadata_';
  static const String _thumbnailPrefix = 'photo_thumbnail_';
  static const String _cacheTimestampPrefix = 'cache_ts_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  // Singleton pattern
  static final PhotoCacheService _instance = PhotoCacheService._internal();
  factory PhotoCacheService() => _instance;
  PhotoCacheService._internal();

  SharedPreferences? _prefs;
  Directory? _cacheDir;

  /// Initialize cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // 썸네일을 영구 저장소에 저장 (앱 삭제 전까지 유지)
      _cacheDir = await getApplicationDocumentsDirectory();
      _log('캐시 서비스 초기화 완료 (영구 저장소)');
    } catch (e) {
      _log('캐시 서비스 초기화 실패: $e', isError: true);
    }
  }

  /// Generates a cache key from a string (using MD5 hash)
  String _generateCacheKey(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Checks if cache is expired
  bool _isCacheExpired(String key, {Duration? maxAge}) {
    if (_prefs == null) return true;

    final timestampKey = '$_cacheTimestampPrefix$key';
    final timestamp = _prefs!.getInt(timestampKey);

    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cacheTime);
    final maxCacheAge = maxAge ?? _defaultCacheDuration;

    return age > maxCacheAge;
  }

  /// Saves cache timestamp
  Future<void> _saveCacheTimestamp(String key) async {
    if (_prefs == null) return;

    final timestampKey = '$_cacheTimestampPrefix$key';
    await _prefs!.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ========== Metadata Caching ==========

  /// Gets cached metadata for a photo
  Future<PhotoMetadata?> getCachedMetadata(
    String photoId, {
    Duration? maxAge,
  }) async {
    if (_prefs == null) {
      _log('SharedPreferences가 초기화되지 않음', isError: true);
      return null;
    }

    try {
      final key = '$_metadataPrefix$photoId';

      // Check if cache is expired
      if (_isCacheExpired(key, maxAge: maxAge)) {
        _log('메타데이터 캐시 만료: $photoId');
        return null;
      }

      final jsonString = _prefs!.getString(key);
      if (jsonString == null) {
        _log('메타데이터 캐시 미스: $photoId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = PhotoMetadata.fromMap(json);

      _log('메타데이터 캐시 히트: $photoId');
      return metadata;
    } catch (e) {
      _log('메타데이터 캐시 로드 오류: $e', isError: true);
      return null;
    }
  }

  /// Caches metadata for a photo
  Future<bool> cacheMetadata(String photoId, PhotoMetadata metadata) async {
    if (_prefs == null) {
      _log('SharedPreferences가 초기화되지 않음', isError: true);
      return false;
    }

    try {
      final key = '$_metadataPrefix$photoId';
      final jsonString = jsonEncode(metadata.toMap());

      await _prefs!.setString(key, jsonString);
      await _saveCacheTimestamp(key);

      _log('메타데이터 캐시 저장 성공: $photoId');
      return true;
    } catch (e) {
      _log('메타데이터 캐시 저장 오류: $e', isError: true);
      return false;
    }
  }

  /// Removes cached metadata for a photo
  Future<bool> removeCachedMetadata(String photoId) async {
    if (_prefs == null) return false;

    try {
      final key = '$_metadataPrefix$photoId';
      final timestampKey = '$_cacheTimestampPrefix$key';

      await _prefs!.remove(key);
      await _prefs!.remove(timestampKey);

      _log('메타데이터 캐시 삭제: $photoId');
      return true;
    } catch (e) {
      _log('메타데이터 캐시 삭제 오류: $e', isError: true);
      return false;
    }
  }

  // ========== Thumbnail Caching ==========

  /// Gets the cache file path for a thumbnail
  Future<File?> _getThumbnailCacheFile(String photoId) async {
    if (_cacheDir == null) return null;

    final cacheKey = _generateCacheKey(photoId);
    final thumbnailDir = Directory('${_cacheDir!.path}/thumbnails');

    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }

    return File('${thumbnailDir.path}/$cacheKey.jpg');
  }

  /// Gets cached thumbnail for a photo
  Future<File?> getCachedThumbnail(
    String photoId, {
    Duration? maxAge,
  }) async {
    try {
      final cacheFile = await _getThumbnailCacheFile(photoId);
      if (cacheFile == null) return null;

      // Check if file exists
      if (!await cacheFile.exists()) {
        _log('썸네일 캐시 미스: $photoId');
        return null;
      }

      // Check if cache is expired
      final key = '$_thumbnailPrefix$photoId';
      if (_isCacheExpired(key, maxAge: maxAge)) {
        _log('썸네일 캐시 만료: $photoId');
        await cacheFile.delete();
        return null;
      }

      _log('썸네일 캐시 히트: $photoId');
      return cacheFile;
    } catch (e) {
      _log('썸네일 캐시 로드 오류: $e', isError: true);
      return null;
    }
  }

  /// Caches thumbnail for a photo
  Future<File?> cacheThumbnail(String photoId, List<int> imageBytes) async {
    try {
      final cacheFile = await _getThumbnailCacheFile(photoId);
      if (cacheFile == null) return null;

      await cacheFile.writeAsBytes(imageBytes);

      final key = '$_thumbnailPrefix$photoId';
      await _saveCacheTimestamp(key);

      _log('썸네일 캐시 저장 성공: $photoId');
      return cacheFile;
    } catch (e) {
      _log('썸네일 캐시 저장 오류: $e', isError: true);
      return null;
    }
  }

  /// Caches thumbnail using file path as identifier
  Future<File?> cacheThumbnailByFilePath(String filePath, List<int> imageBytes) async {
    try {
      // Generate photo ID from file path
      final photoId = _generateCacheKey(filePath);
      return await cacheThumbnail(photoId, imageBytes);
    } catch (e) {
      _log('파일 경로 기반 썸네일 캐시 저장 오류: $e', isError: true);
      return null;
    }
  }

  /// Removes cached thumbnail for a photo
  Future<bool> removeCachedThumbnail(String photoId) async {
    try {
      final cacheFile = await _getThumbnailCacheFile(photoId);
      if (cacheFile == null) return false;

      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }

      if (_prefs != null) {
        final key = '$_thumbnailPrefix$photoId';
        final timestampKey = '$_cacheTimestampPrefix$key';
        await _prefs!.remove(timestampKey);
      }

      _log('썸네일 캐시 삭제: $photoId');
      return true;
    } catch (e) {
      _log('썸네일 캐시 삭제 오류: $e', isError: true);
      return false;
    }
  }

  // ========== Cache Management ==========

  /// Clears all cached metadata
  Future<int> clearAllMetadataCache() async {
    if (_prefs == null) return 0;

    try {
      final keys = _prefs!.getKeys();
      int count = 0;

      for (final key in keys) {
        if (key.startsWith(_metadataPrefix)) {
          await _prefs!.remove(key);
          final timestampKey = '$_cacheTimestampPrefix$key';
          await _prefs!.remove(timestampKey);
          count++;
        }
      }

      _log('모든 메타데이터 캐시 삭제: $count개');
      return count;
    } catch (e) {
      _log('메타데이터 캐시 전체 삭제 오류: $e', isError: true);
      return 0;
    }
  }

  /// Clears all cached thumbnails
  Future<int> clearAllThumbnailCache() async {
    try {
      if (_cacheDir == null) return 0;

      final thumbnailDir = Directory('${_cacheDir!.path}/thumbnails');
      if (!await thumbnailDir.exists()) return 0;

      final files = await thumbnailDir.list().toList();
      int count = 0;

      for (final file in files) {
        if (file is File) {
          await file.delete();
          count++;
        }
      }

      // Clear timestamps from SharedPreferences
      if (_prefs != null) {
        final keys = _prefs!.getKeys();
        for (final key in keys) {
          if (key.startsWith('$_cacheTimestampPrefix$_thumbnailPrefix')) {
            await _prefs!.remove(key);
          }
        }
      }

      _log('모든 썸네일 캐시 삭제: $count개');
      return count;
    } catch (e) {
      _log('썸네일 캐시 전체 삭제 오류: $e', isError: true);
      return 0;
    }
  }

  /// Clears all cache (metadata + thumbnails)
  Future<Map<String, int>> clearAllCache() async {
    final metadataCount = await clearAllMetadataCache();
    final thumbnailCount = await clearAllThumbnailCache();

    return {
      'metadata': metadataCount,
      'thumbnails': thumbnailCount,
    };
  }

  /// Gets cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      int metadataCount = 0;
      int thumbnailCount = 0;
      int thumbnailSizeBytes = 0;

      // Count metadata cache
      if (_prefs != null) {
        final keys = _prefs!.getKeys();
        metadataCount = keys.where((k) => k.startsWith(_metadataPrefix)).length;
      }

      // Count thumbnail cache
      if (_cacheDir != null) {
        final thumbnailDir = Directory('${_cacheDir!.path}/thumbnails');
        if (await thumbnailDir.exists()) {
          final files = await thumbnailDir.list().toList();
          for (final file in files) {
            if (file is File) {
              thumbnailCount++;
              thumbnailSizeBytes += await file.length();
            }
          }
        }
      }

      return {
        'metadataCount': metadataCount,
        'thumbnailCount': thumbnailCount,
        'thumbnailSizeBytes': thumbnailSizeBytes,
        'thumbnailSizeMB': (thumbnailSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      _log('캐시 통계 조회 오류: $e', isError: true);
      return {
        'metadataCount': 0,
        'thumbnailCount': 0,
        'thumbnailSizeBytes': 0,
        'thumbnailSizeMB': '0.00',
      };
    }
  }

  /// Clears expired cache entries
  Future<Map<String, int>> clearExpiredCache({Duration? maxAge}) async {
    int expiredMetadata = 0;
    int expiredThumbnails = 0;

    try {
      // Clear expired metadata
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((k) => k.startsWith(_metadataPrefix)).toList();
        for (final key in keys) {
          if (_isCacheExpired(key, maxAge: maxAge)) {
            await _prefs!.remove(key);
            final timestampKey = '$_cacheTimestampPrefix$key';
            await _prefs!.remove(timestampKey);
            expiredMetadata++;
          }
        }
      }

      // Clear expired thumbnails
      if (_cacheDir != null && _prefs != null) {
        final thumbnailDir = Directory('${_cacheDir!.path}/thumbnails');
        if (await thumbnailDir.exists()) {
          final files = await thumbnailDir.list().toList();
          for (final file in files) {
            if (file is File) {
              final fileName = file.path.split('/').last.replaceAll('.jpg', '');
              final key = '$_thumbnailPrefix$fileName';
              if (_isCacheExpired(key, maxAge: maxAge)) {
                await file.delete();
                final timestampKey = '$_cacheTimestampPrefix$key';
                await _prefs!.remove(timestampKey);
                expiredThumbnails++;
              }
            }
          }
        }
      }

      _log('만료된 캐시 삭제: 메타데이터 $expiredMetadata개, 썸네일 $expiredThumbnails개');
    } catch (e) {
      _log('만료된 캐시 삭제 오류: $e', isError: true);
    }

    return {
      'metadata': expiredMetadata,
      'thumbnails': expiredThumbnails,
    };
  }
}