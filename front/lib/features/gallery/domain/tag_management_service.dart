import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/photo_models.dart';

// Backend server configuration
const String _baseUrl = 'https://your-backend-api.com'; // TODO: Replace with actual backend URL
const String _tagEndpoint = '/api/v1/photos';           // TODO: Replace with actual endpoint

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'TagManagement',
    level: level.index * 300,
    error: error,
  );
}

/// Adds a user tag to a photo
Future<PhotoTag?> addUserTag(String photoId, String tagName) async {
  try {
    final uri = Uri.parse('$_baseUrl$_tagEndpoint/$photoId/tags');

    _log('사용자 태그 추가 요청: $photoId - $tagName');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode({
        'name': tagName,
        'type': 'user',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _log('태그 추가 성공: $tagName', level: LogLevel.info);
      return PhotoTag.fromMap(data);
    } else {
      _log('태그 추가 실패 (상태 코드: ${response.statusCode}): $tagName',
          level: LogLevel.warning);
      return null;
    }
  } catch (e) {
    _log('태그 추가 오류: $tagName', level: LogLevel.error, error: e);
    return null;
  }
}

/// Deletes a tag from a photo
Future<bool> deleteTag(String photoId, String tagId) async {
  try {
    final uri = Uri.parse('$_baseUrl$_tagEndpoint/$photoId/tags/$tagId');

    _log('태그 삭제 요청: $photoId - $tagId');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _log('태그 삭제 성공: $tagId', level: LogLevel.info);
      return true;
    } else {
      _log('태그 삭제 실패 (상태 코드: ${response.statusCode}): $tagId',
          level: LogLevel.warning);
      return false;
    }
  } catch (e) {
    _log('태그 삭제 오류: $tagId', level: LogLevel.error, error: e);
    return false;
  }
}

/// Fetches metadata for a photo
Future<PhotoMetadata?> fetchPhotoMetadata(String photoId) async {
  try {
    final uri = Uri.parse('$_baseUrl$_tagEndpoint/$photoId/metadata');

    _log('메타데이터 요청: $photoId');

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
      _log('메타데이터 로드 성공: $photoId', level: LogLevel.info);
      return PhotoMetadata.fromMap(data);
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

/// Updates multiple tags for a photo
Future<PhotoMetadata?> updatePhotoTags(
  String photoId,
  List<String> userTagNames,
) async {
  try {
    final uri = Uri.parse('$_baseUrl$_tagEndpoint/$photoId/tags/batch');

    _log('태그 일괄 업데이트 요청: $photoId');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode({
        'userTags': userTagNames,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _log('태그 일괄 업데이트 성공: $photoId', level: LogLevel.info);
      return PhotoMetadata.fromMap(data);
    } else {
      _log('태그 일괄 업데이트 실패 (상태 코드: ${response.statusCode}): $photoId',
          level: LogLevel.warning);
      return null;
    }
  } catch (e) {
    _log('태그 일괄 업데이트 오류: $photoId', level: LogLevel.error, error: e);
    return null;
  }
}