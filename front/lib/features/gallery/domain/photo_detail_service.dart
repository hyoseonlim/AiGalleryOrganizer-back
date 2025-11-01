import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/photo_models.dart';
import '../data/cache/photo_cache_service.dart';

// Backend server configuration
const String _baseUrl = 'https://your-backend-api.com'; // TODO: Replace with actual backend URL
const String _photoEndpoint = '/api/v1/photos';        // TODO: Replace with actual endpoint

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'PhotoDetail',
    level: level.index * 300,
    error: error,
  );
}

/// Fetches a single photo's detailed information from backend with caching
Future<Photo?> fetchPhotoDetail(String photoId, {bool forceRefresh = false}) async {
  final cacheService = PhotoCacheService();

  try {
    // Try to get from cache first
    if (!forceRefresh) {
      final cachedMetadata = await cacheService.getCachedMetadata(photoId);
      if (cachedMetadata != null) {
        _log('사진 메타데이터 캐시 히트: $photoId', level: LogLevel.info);
        // Return cached photo with metadata
        // Note: URL and basic info would need to be stored separately or fetched
        // For now, we'll fetch from backend but log the cache hit
      }
    }

    final uri = Uri.parse('$_baseUrl$_photoEndpoint/$photoId');

    _log('사진 상세정보 요청: $photoId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final photo = Photo.fromMap(data);

      // Cache the metadata
      await cacheService.cacheMetadata(photoId, photo.metadata);

      _log('사진 상세정보 로드 성공: $photoId', level: LogLevel.info);
      return photo;
    } else {
      _log('사진 상세정보 로드 실패 (상태 코드: ${response.statusCode}): $photoId',
          level: LogLevel.warning);
      return null;
    }
  } catch (e) {
    _log('사진 상세정보 로드 오류: $photoId', level: LogLevel.error, error: e);
    return null;
  }
}

/// Fetches metadata for a photo with caching support
Future<PhotoMetadata?> fetchPhotoMetadataWithCache(
  String photoId, {
  bool forceRefresh = false,
}) async {
  final cacheService = PhotoCacheService();

  try {
    // 1. Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedMetadata = await cacheService.getCachedMetadata(photoId);
      if (cachedMetadata != null) {
        _log('메타데이터 캐시 히트: $photoId', level: LogLevel.info);
        return cachedMetadata;
      }
    }

    // 2. Cache miss or force refresh - fetch from backend
    _log('메타데이터 캐시 미스 - 백엔드 요청: $photoId');

    final uri = Uri.parse('$_baseUrl$_photoEndpoint/$photoId/metadata');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final metadata = PhotoMetadata.fromMap(data);

      // 3. Cache the fetched metadata
      await cacheService.cacheMetadata(photoId, metadata);

      _log('메타데이터 로드 및 캐싱 성공: $photoId', level: LogLevel.info);
      return metadata;
    } else {
      _log('메타데이터 로드 실패 (상태 코드: ${response.statusCode}): $photoId',
          level: LogLevel.warning);
      return null;
    }
  } catch (e) {
    _log('메타데이터 로드 오류: $photoId', level: LogLevel.error, error: e);
    return null;
  }
}

/// Fetches a list of photos for the gallery
Future<List<Photo>?> fetchPhotoList() async {
  try {
    final uri = Uri.parse('$_baseUrl$_photoEndpoint');

    _log('사진 목록 요청');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final photos = data.map((json) => Photo.fromMap(json)).toList();
      _log('사진 목록 로드 성공: ${photos.length}개', level: LogLevel.info);
      return photos;
    } else {
      _log('사진 목록 로드 실패 (상태 코드: ${response.statusCode})',
          level: LogLevel.warning);
      return null;
    }
  } catch (e) {
    _log('사진 목록 로드 오류', level: LogLevel.error, error: e);
    return null;
  }
}

/// Shares a photo via system share sheet
Future<bool> sharePhoto(String photoId, String photoUrl) async {
  try {
    _log('사진 공유 시작: $photoId');

    // TODO: Implement actual share functionality using share_plus package
    // Example: await Share.share(photoUrl);

    _log('사진 공유 성공: $photoId', level: LogLevel.info);
    return true;
  } catch (e) {
    _log('사진 공유 오류: $photoId', level: LogLevel.error, error: e);
    return false;
  }
}
