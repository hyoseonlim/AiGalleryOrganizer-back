import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:front/core/network/network_policy_service.dart';

import '../data/models/photo_models.dart';

// Backend server configuration
const String _baseUrl = 'http://localhost:8000';
const String _myImagesEndpoint = '/api/users/me/images';
const String _imageViewEndpoint = '/api/images';
const String _trashEndpoint = '/api/images/trash';

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
    name: 'ImageService',
    level: level.index * 300,
    error: error,
  );
}

/// 현재 사용자의 모든 이미지 조회
Future<List<ImageResponse>> getMyImages() async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_myImagesEndpoint');
    _log('사용자 이미지 목록 조회');

    final response = await http.get(uri, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final images = data
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList();
      _log('이미지 목록 조회 성공: ${images.length}개');
      return images;
    } else {
      _log(
        '이미지 목록 조회 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      throw Exception('이미지 목록 조회 실패: ${response.statusCode}');
    }
  } catch (e) {
    _log('이미지 목록 조회 오류: $e', level: LogLevel.error, error: e);
    rethrow;
  }
}

/// 특정 이미지의 view URL 조회 (CloudFront URL)
Future<ImageViewableResponse?> getImageViewUrl(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_imageViewEndpoint/$imageId/view');
    _log('이미지 view URL 조회: $imageId');

    final response = await http.get(uri, headers: _getAuthHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final viewResponse = ImageViewableResponse.fromMap(data);
      _log('이미지 view URL 조회 성공: $imageId');
      return viewResponse;
    } else if (response.statusCode == 404) {
      _log('이미지를 찾을 수 없음: $imageId', level: LogLevel.warning);
      return null;
    } else {
      _log(
        '이미지 view URL 조회 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      return null;
    }
  } catch (e) {
    _log('이미지 view URL 조회 오류: $imageId - $e', level: LogLevel.error, error: e);
    return null;
  }
}

/// 휴지통의 모든 이미지 조회 (소프트 삭제된 이미지)
Future<List<ImageResponse>> getTrashedImages() async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_trashEndpoint');
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
