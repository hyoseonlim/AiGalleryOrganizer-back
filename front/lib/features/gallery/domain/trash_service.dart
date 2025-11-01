import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front/core/network/network_policy_service.dart';

import '../data/models/photo_models.dart';

// Backend server configuration
const String _baseUrl = 'http://localhost:8000';
const String _softDeleteEndpoint = '/api/images';
const String _restoreEndpoint = '/api/images';
const String _permanentDeleteEndpoint = '/api/images/trash';
const String _trashListEndpoint = '/api/images/trash';

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

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'TrashService',
    level: level.index * 300,
    error: error,
  );
}

/// 이미지를 소프트 삭제 (휴지통으로 이동)
/// Soft delete an image. The image will be moved to trash.
Future<Map<String, dynamic>> softDeleteImage(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_softDeleteEndpoint/$imageId');

    _log('이미지 소프트 삭제 요청: $imageId');

    final response = await http.delete(uri, headers: _getAuthHeaders());

    if (response.statusCode == 204) {
      _log('이미지 소프트 삭제 성공: $imageId', level: LogLevel.info);
      return {
        'success': true,
        'imageId': imageId,
        'message': '이미지가 휴지통으로 이동되었습니다',
      };
    } else {
      _log(
        '이미지 소프트 삭제 실패 (상태 코드: ${response.statusCode}): $imageId',
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
    _log('이미지 소프트 삭제 오류: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 여러 이미지를 소프트 삭제 (휴지통으로 이동)
Future<Map<String, dynamic>> softDeleteMultipleImages(
  List<int> imageIds, {
  Function(int current, int total)? onProgress,
}) async {
  final deleteResults = <Map<String, dynamic>>[];
  final failedImages = <int>[];
  int successCount = 0;

  _log('일괄 소프트 삭제 시작: ${imageIds.length}개의 이미지');

  for (var i = 0; i < imageIds.length; i++) {
    final imageId = imageIds[i];
    try {
      final deleteResult = await softDeleteImage(imageId);

      if (deleteResult['success'] == true) {
        deleteResults.add(deleteResult);
        successCount++;
      } else {
        failedImages.add(imageId);
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, imageIds.length);
    } catch (e) {
      _log('이미지 소프트 삭제 실패: $imageId', level: LogLevel.error, error: e);
      failedImages.add(imageId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalImages': imageIds.length,
    'successCount': successCount,
    'failedCount': failedImages.length,
    'failedImages': failedImages,
    'results': deleteResults,
  };

  _log('일괄 소프트 삭제 완료: $successCount/${imageIds.length} 성공');

  return summary;
}

/// 휴지통에서 이미지 복원
/// Restore a soft-deleted image from trash
Future<Map<String, dynamic>> restoreImage(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_restoreEndpoint/$imageId/restore');

    _log('이미지 복원 요청: $imageId');

    final response = await http.post(uri, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final restoredImage = ImageResponse.fromMap(data);
      _log('이미지 복원 성공: $imageId', level: LogLevel.info);
      return {
        'success': true,
        'imageId': imageId,
        'image': restoredImage,
        'message': '이미지가 복원되었습니다',
      };
    } else {
      _log(
        '이미지 복원 실패 (상태 코드: ${response.statusCode}): $imageId',
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
    _log('이미지 복원 오류: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 여러 이미지를 휴지통에서 복원
Future<Map<String, dynamic>> restoreMultipleImages(
  List<int> imageIds, {
  Function(int current, int total)? onProgress,
}) async {
  final restoreResults = <Map<String, dynamic>>[];
  final failedImages = <int>[];
  int successCount = 0;

  _log('일괄 복원 시작: ${imageIds.length}개의 이미지');

  for (var i = 0; i < imageIds.length; i++) {
    final imageId = imageIds[i];
    try {
      final restoreResult = await restoreImage(imageId);

      if (restoreResult['success'] == true) {
        restoreResults.add(restoreResult);
        successCount++;
      } else {
        failedImages.add(imageId);
      }

      onProgress?.call(i + 1, imageIds.length);
    } catch (e) {
      _log('이미지 복원 실패: $imageId', level: LogLevel.error, error: e);
      failedImages.add(imageId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalImages': imageIds.length,
    'successCount': successCount,
    'failedCount': failedImages.length,
    'failedImages': failedImages,
    'results': restoreResults,
  };

  _log('일괄 복원 완료: $successCount/${imageIds.length} 성공');

  return summary;
}

/// 휴지통에서 이미지를 영구 삭제
/// Permanently delete an image from trash and S3
Future<Map<String, dynamic>> permanentlyDeleteImage(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_permanentDeleteEndpoint/$imageId');

    _log('이미지 영구 삭제 요청: $imageId');

    final response = await http.delete(uri, headers: _getAuthHeaders());

    if (response.statusCode == 204) {
      _log('이미지 영구 삭제 성공: $imageId', level: LogLevel.info);
      return {
        'success': true,
        'imageId': imageId,
        'message': '이미지가 영구적으로 삭제되었습니다',
      };
    } else {
      _log(
        '이미지 영구 삭제 실패 (상태 코드: ${response.statusCode}): $imageId',
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
    _log('이미지 영구 삭제 오류: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 여러 이미지를 휴지통에서 영구 삭제
Future<Map<String, dynamic>> permanentlyDeleteMultipleImages(
  List<int> imageIds, {
  Function(int current, int total)? onProgress,
}) async {
  final deleteResults = <Map<String, dynamic>>[];
  final failedImages = <int>[];
  int successCount = 0;

  _log('일괄 영구 삭제 시작: ${imageIds.length}개의 이미지');

  for (var i = 0; i < imageIds.length; i++) {
    final imageId = imageIds[i];
    try {
      final deleteResult = await permanentlyDeleteImage(imageId);

      if (deleteResult['success'] == true) {
        deleteResults.add(deleteResult);
        successCount++;
      } else {
        failedImages.add(imageId);
      }

      onProgress?.call(i + 1, imageIds.length);
    } catch (e) {
      _log('이미지 영구 삭제 실패: $imageId', level: LogLevel.error, error: e);
      failedImages.add(imageId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalImages': imageIds.length,
    'successCount': successCount,
    'failedCount': failedImages.length,
    'failedImages': failedImages,
    'results': deleteResults,
  };

  _log('일괄 영구 삭제 완료: $successCount/${imageIds.length} 성공');

  return summary;
}

/// 휴지통의 모든 이미지 조회
/// Get all soft-deleted images for the current user
Future<List<ImageResponse>> getTrashedImages() async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_trashListEndpoint');
    _log('휴지통 이미지 목록 조회');

    final response = await http.get(uri, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final images = data
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList();
      _log('휴지통 이미지 목록 조회 성공: ${images.length}개');
      return images;
    } else {
      _log(
        '휴지통 이미지 목록 조회 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      throw Exception('휴지통 이미지 목록 조회 실패: ${response.statusCode}');
    }
  } catch (e) {
    _log('휴지통 이미지 목록 조회 오류: $e', level: LogLevel.error, error: e);
    rethrow;
  }
}
