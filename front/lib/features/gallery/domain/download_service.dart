import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:front/core/network/network_policy_service.dart';

import '../data/cache/photo_cache_service.dart';
import '../data/models/photo_models.dart';

// Backend server configuration
const String _baseUrl = 'http://localhost:8000';
const String _imageViewEndpoint = '/api/images';

// TODO: 실제 인증 토큰을 가져오는 함수로 교체 필요
String? _getAuthToken() {
  // 임시로 null 반환. SharedPreferences나 secure storage에서 토큰 가져오기
  return null;
}

Map<String, String> _getAuthHeaders() {
  final token = _getAuthToken();
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'DownloadService',
    level: level.index * 300,
    error: error,
  );
}

/// 이미지 view URL 조회 (CloudFront를 통해 제공)
/// Get a publicly viewable URL for a completed image
Future<ImageViewableResponse?> getImageViewUrl(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_imageViewEndpoint/$imageId/view');

    _log('이미지 view URL 조회: $imageId');

    final response = await http.get(uri, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final viewResponse = ImageViewableResponse.fromMap(data);
      _log('이미지 view URL 조회 성공: $imageId', level: LogLevel.info);
      return viewResponse;
    } else if (response.statusCode == 404) {
      _log('이미지를 찾을 수 없음: $imageId', level: LogLevel.warning);
      return null;
    } else {
      _log(
        '이미지 view URL 조회 실패 (Status: ${response.statusCode}): $imageId',
        level: LogLevel.warning,
      );
      return null;
    }
  } catch (e) {
    _log('이미지 view URL 조회 오류: $imageId', level: LogLevel.error, error: e);
    return null;
  }
}

/// CloudFront URL에서 이미지를 다운로드하여 로컬에 저장
/// Downloads an image from CloudFront URL and saves it to cache
Future<Map<String, dynamic>?> downloadImageFromUrl(
  String imageUrl,
  int imageId, {
  String? fileName,
}) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    _log('이미지 다운로드 시작: $imageId from $imageUrl');

    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final downloadDir = Directory('${cacheDir.path}/downloads');

      // Create downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Generate file name
      final fileNameToUse = fileName ?? 'image_$imageId.jpg';
      final filePath = '${downloadDir.path}/$fileNameToUse';

      // Write file to cache
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _log('이미지 다운로드 성공: $filePath', level: LogLevel.info);
      return {
        'success': true,
        'imageId': imageId,
        'filePath': filePath,
        'fileSize': response.bodyBytes.length,
        'message': '이미지 다운로드 완료',
      };
    } else {
      _log(
        '이미지 다운로드 실패 (Status: ${response.statusCode}): $imageId',
        level: LogLevel.warning,
      );
      return {
        'success': false,
        'imageId': imageId,
        'error': 'Status ${response.statusCode}',
        'message': response.body,
      };
    }
  } catch (e) {
    _log('이미지 다운로드 오류: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 이미지를 다운로드 (view URL 조회 후 다운로드)
/// Downloads a single image file to cache
Future<Map<String, dynamic>?> downloadImageToCache(
  int imageId, {
  String? fileName,
}) async {
  try {
    // 1. Get view URL
    final viewResponse = await getImageViewUrl(imageId);
    if (viewResponse == null) {
      return {
        'success': false,
        'imageId': imageId,
        'error': '이미지 URL을 가져올 수 없습니다',
      };
    }

    // 2. Download from CloudFront URL
    return await downloadImageFromUrl(
      viewResponse.url,
      imageId,
      fileName: fileName,
    );
  } catch (e) {
    _log('이미지 다운로드 실패: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 썸네일 다운로드 (캐싱 지원)
/// Note: 현재 API는 별도의 썸네일 엔드포인트를 제공하지 않으므로
/// 원본 이미지를 다운로드하여 썸네일로 사용합니다.
Future<File?> downloadThumbnailWithCache(
  int imageId, {
  bool forceRefresh = false,
}) async {
  final cacheService = PhotoCacheService();

  try {
    // 1. Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedFile = await cacheService.getCachedThumbnail(
        imageId.toString(),
      );
      if (cachedFile != null) {
        _log('썸네일 캐시 히트: $imageId', level: LogLevel.info);
        return cachedFile;
      }
    }

    // 2. Cache miss or force refresh - download from backend
    _log('썸네일 캐시 미스 - 이미지 다운로드: $imageId');

    // Get view URL
    final viewResponse = await getImageViewUrl(imageId);
    if (viewResponse == null) {
      _log('썸네일용 이미지 URL을 가져올 수 없음: $imageId', level: LogLevel.warning);
      return null;
    }

    // Download image
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final response = await http.get(Uri.parse(viewResponse.url));

    if (response.statusCode == 200) {
      // 3. Cache the downloaded thumbnail
      final cachedFile = await cacheService.cacheThumbnail(
        imageId.toString(),
        response.bodyBytes,
      );

      _log('썸네일 다운로드 및 캐싱 성공: $imageId', level: LogLevel.info);
      return cachedFile;
    } else {
      _log(
        '썸네일 다운로드 실패 (상태 코드: ${response.statusCode}): $imageId',
        level: LogLevel.warning,
      );
      return null;
    }
  } catch (e) {
    _log('썸네일 다운로드 오류: $imageId', level: LogLevel.error, error: e);
    return null;
  }
}

/// 여러 썸네일 일괄 다운로드 (캐싱 지원)
Future<Map<String, dynamic>> downloadThumbnailsToCache(
  List<int> imageIds, {
  Function(int current, int total)? onProgress,
  bool forceRefresh = false,
}) async {
  final downloadResults = <Map<String, dynamic>>[];
  final failedImages = <int>[];
  int successCount = 0;

  _log('썸네일 일괄 다운로드 시작: ${imageIds.length}개');

  for (var i = 0; i < imageIds.length; i++) {
    final imageId = imageIds[i];
    try {
      final thumbnailFile = await downloadThumbnailWithCache(
        imageId,
        forceRefresh: forceRefresh,
      );

      if (thumbnailFile != null) {
        downloadResults.add({
          'imageId': imageId,
          'filePath': thumbnailFile.path,
          'success': true,
        });
        successCount++;
      } else {
        failedImages.add(imageId);
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, imageIds.length);
    } catch (e) {
      _log('썸네일 다운로드 실패: $imageId', level: LogLevel.error, error: e);
      failedImages.add(imageId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalImages': imageIds.length,
    'successCount': successCount,
    'failedCount': failedImages.length,
    'failedImages': failedImages,
    'results': downloadResults,
  };

  _log('썸네일 일괄 다운로드 완료: $successCount/${imageIds.length} 성공');

  return summary;
}

/// 여러 이미지 일괄 다운로드
Future<Map<String, dynamic>> downloadMultipleImages(
  List<int> imageIds, {
  Function(int current, int total)? onProgress,
}) async {
  final downloadResults = <Map<String, dynamic>>[];
  final failedImages = <int>[];
  int successCount = 0;

  _log('이미지 일괄 다운로드 시작: ${imageIds.length}개');

  for (var i = 0; i < imageIds.length; i++) {
    final imageId = imageIds[i];
    try {
      final downloadResult = await downloadImageToCache(imageId);

      if (downloadResult != null && downloadResult['success'] == true) {
        downloadResults.add(downloadResult);
        successCount++;
      } else {
        failedImages.add(imageId);
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, imageIds.length);
    } catch (e) {
      _log('이미지 다운로드 실패: $imageId', level: LogLevel.error, error: e);
      failedImages.add(imageId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalImages': imageIds.length,
    'successCount': successCount,
    'failedCount': failedImages.length,
    'failedImages': failedImages,
    'results': downloadResults,
  };

  _log('이미지 일괄 다운로드 완료: $successCount/${imageIds.length} 성공');

  return summary;
}

/// 여러 이미지의 view URL을 한 번에 조회
Future<Map<int, ImageViewableResponse>> getMultipleImageViewUrls(
  List<int> imageIds, {
  Function(int current, int total)? onProgress,
}) async {
  final results = <int, ImageViewableResponse>{};

  _log('일괄 view URL 조회 시작: ${imageIds.length}개의 이미지');

  for (var i = 0; i < imageIds.length; i++) {
    final imageId = imageIds[i];
    try {
      final viewResponse = await getImageViewUrl(imageId);
      if (viewResponse != null) {
        results[imageId] = viewResponse;
      }
      onProgress?.call(i + 1, imageIds.length);
    } catch (e) {
      _log('view URL 조회 실패: $imageId', level: LogLevel.error, error: e);
    }
  }

  _log('일괄 view URL 조회 완료: ${results.length}/${imageIds.length} 성공');

  return results;
}

/// Clears all downloaded files from cache
Future<bool> clearDownloadCache() async {
  try {
    final cacheDir = await getTemporaryDirectory();
    final downloadDir = Directory('${cacheDir.path}/downloads');

    if (await downloadDir.exists()) {
      await downloadDir.delete(recursive: true);
      _log('Download cache cleared successfully', level: LogLevel.info);
      return true;
    }

    return true;
  } catch (e) {
    _log('Failed to clear download cache', level: LogLevel.error, error: e);
    return false;
  }
}
