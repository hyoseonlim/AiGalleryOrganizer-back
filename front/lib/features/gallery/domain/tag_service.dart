import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front/core/network/network_policy_service.dart';
import 'package:front/features/auth/data/auth_repository.dart';
import '../data/models/photo_models.dart';

// Backend server configuration
const String _baseUrl = 'http://localhost:8000';

// Auth repository instance
final _authRepository = AuthRepository();

Future<Map<String, String>> _getAuthHeaders() async {
  final token = await _authRepository.getAccessToken();
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
    name: 'TagService',
    level: level.index * 300,
    error: error,
  );
}

/// Tag response model
class TagResponse {
  final int id;
  final String name;
  final int? userId;
  final int categoryId;
  final CategoryResponse category;

  const TagResponse({
    required this.id,
    required this.name,
    this.userId,
    required this.categoryId,
    required this.category,
  });

  factory TagResponse.fromMap(Map<String, dynamic> map) {
    return TagResponse(
      id: map['id'] as int,
      name: map['name'] as String,
      userId: map['user_id'] as int?,
      categoryId: map['category_id'] as int,
      category: CategoryResponse.fromMap(map['category'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'category_id': categoryId,
      'category': category.toMap(),
    };
  }
}

/// Category response model
class CategoryResponse {
  final int id;
  final String name;

  const CategoryResponse({
    required this.id,
    required this.name,
  });

  factory CategoryResponse.fromMap(Map<String, dynamic> map) {
    return CategoryResponse(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// 모든 태그 목록 조회
/// Get all tags for the current user
/// OpenAPI: GET /api/tags/
Future<Map<String, dynamic>> getAllTags({
  int skip = 0,
  int limit = 100,
}) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl/api/tags/').replace(
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );

    _log('태그 목록 조회');

    final headers = await _getAuthHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final tags = data
          .map((item) => TagResponse.fromMap(item as Map<String, dynamic>))
          .toList();
      _log('태그 목록 조회 성공: ${tags.length}개');
      return {
        'success': true,
        'tags': tags,
        'count': tags.length,
      };
    } else {
      _log(
        '태그 목록 조회 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      return {
        'success': false,
        'error': 'Status ${response.statusCode}',
        'message': response.body,
      };
    }
  } catch (e) {
    _log('태그 목록 조회 오류: $e', level: LogLevel.error, error: e);
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// 이미지에 태그 추가
/// Add tags to an image
/// OpenAPI: POST /api/images/{image_id}/tags
Future<Map<String, dynamic>> addTagsToImage(
  int imageId,
  List<String> tagNames,
) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl/api/images/$imageId/tags');

    _log('이미지에 태그 추가: $imageId, 태그: $tagNames');

    final headers = await _getAuthHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'tag_names': tagNames}),
    );

    if (response.statusCode == 204) {
      _log('태그 추가 성공: $imageId', level: LogLevel.info);
      return {
        'success': true,
        'imageId': imageId,
        'addedTags': tagNames,
        'message': '태그가 추가되었습니다',
      };
    } else {
      _log(
        '태그 추가 실패 (상태 코드: ${response.statusCode}): $imageId',
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
    _log('태그 추가 오류: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 이미지에서 태그 제거
/// Remove tags from an image
/// OpenAPI: DELETE /api/images/{image_id}/tags
Future<Map<String, dynamic>> removeTagsFromImage(
  int imageId,
  List<String> tagNames,
) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl/api/images/$imageId/tags');

    _log('이미지에서 태그 제거: $imageId, 태그: $tagNames');

    final headers = await _getAuthHeaders();
    final request = http.Request('DELETE', uri)
      ..headers.addAll(headers)
      ..body = jsonEncode({'tag_names': tagNames});

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 204) {
      _log('태그 제거 성공: $imageId', level: LogLevel.info);
      return {
        'success': true,
        'imageId': imageId,
        'removedTags': tagNames,
        'message': '태그가 제거되었습니다',
      };
    } else {
      _log(
        '태그 제거 실패 (상태 코드: ${response.statusCode}): $imageId',
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
    _log('태그 제거 오류: $imageId', level: LogLevel.error, error: e);
    return {'success': false, 'imageId': imageId, 'error': e.toString()};
  }
}

/// 모든 카테고리 목록 조회
/// Get all categories
/// OpenAPI: GET /api/categories/
Future<Map<String, dynamic>> getAllCategories({
  int skip = 0,
  int limit = 100,
}) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl/api/categories/').replace(
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );

    _log('카테고리 목록 조회');

    final headers = await _getAuthHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final categories = data
          .map((item) => CategoryResponse.fromMap(item as Map<String, dynamic>))
          .toList();
      _log('카테고리 목록 조회 성공: ${categories.length}개');
      return {
        'success': true,
        'categories': categories,
        'count': categories.length,
      };
    } else {
      _log(
        '카테고리 목록 조회 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      return {
        'success': false,
        'error': 'Status ${response.statusCode}',
        'message': response.body,
      };
    }
  } catch (e) {
    _log('카테고리 목록 조회 오류: $e', level: LogLevel.error, error: e);
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// 사용자 태그 추가 (photo_metadata_bottom_sheet.dart 호환성)
/// Add a user tag to an image (creates tag if it doesn't exist)
Future<PhotoTag?> addUserTag(String photoId, String tagName) async {
  try {
    final imageId = int.parse(photoId);
    final result = await addTagsToImage(imageId, [tagName]);

    if (result['success'] == true) {
      // Return a PhotoTag with the tag name
      // Note: We don't have the actual tag ID from the API response (204 No Content)
      // The tag will be properly loaded when fetching image details
      return PhotoTag(
        id: tagName, // Use tag name as temporary ID
        name: tagName,
        type: TagType.user,
      );
    }
    return null;
  } catch (e) {
    _log('addUserTag 오류: $e', level: LogLevel.error, error: e);
    return null;
  }
}

/// 태그 삭제 (photo_metadata_bottom_sheet.dart 호환성)
/// Remove a tag from an image
Future<bool> deleteTag(String photoId, String tagId) async {
  try {
    final imageId = int.parse(photoId);
    // tagId is actually the tag name in our PhotoTag model
    final result = await removeTagsFromImage(imageId, [tagId]);

    return result['success'] == true;
  } catch (e) {
    _log('deleteTag 오류: $e', level: LogLevel.error, error: e);
    return false;
  }
}

/// 이미지의 AI 태그를 카테고리별로 조회
/// Get AI tags for an image by querying categories with image_id
/// OpenAPI: GET /api/categories/{category_id}?image_id={image_id}
Future<List<PhotoTag>> fetchAiTagsForImage(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();

    _log('이미지 $imageId의 AI 태그 조회 시작');

    // 1. 모든 카테고리 목록 가져오기
    final categoriesResult = await getAllCategories();
    if (categoriesResult['success'] != true) {
      _log('카테고리 목록 조회 실패', level: LogLevel.error);
      return [];
    }

    final categories = categoriesResult['categories'] as List<CategoryResponse>? ?? [];
    _log('카테고리 ${categories.length}개 조회');

    final allTags = <PhotoTag>[];

    // 2. 각 카테고리에 대해 해당 이미지의 태그 조회
    for (final category in categories) {
      try {
        final uri = Uri.parse('$_baseUrl/api/categories/${category.id}').replace(
          queryParameters: {'image_id': imageId.toString()},
        );

        _log('카테고리 ${category.name}(${category.id})에서 이미지 $imageId 태그 조회', level: LogLevel.debug);

        final headers = await _getAuthHeaders();
        final response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _log('카테고리 응답: $data', level: LogLevel.debug);

          // 응답에서 태그 정보 추출 (구조는 실제 응답에 따라 조정 필요)
          // 예상: {"id": 1, "name": "animal", "tags": ["dog", "cat"]}
          if (data is Map<String, dynamic>) {
            final tags = data['tags'] as List<dynamic>?;
            if (tags != null && tags.isNotEmpty) {
              for (final tagName in tags) {
                allTags.add(PhotoTag(
                  id: '${category.name}:$tagName',
                  name: tagName.toString(),
                  type: TagType.system,
                  category: category.name,
                ));
                _log('  태그 추가: ${category.name}:$tagName', level: LogLevel.debug);
              }
            }
          }
        } else if (response.statusCode != 404) {
          // 404는 해당 카테고리에 태그가 없는 경우이므로 무시
          _log('카테고리 ${category.name} 조회 실패 (${response.statusCode})', level: LogLevel.warning);
        }
      } catch (e) {
        _log('카테고리 ${category.name} 처리 오류: $e', level: LogLevel.error, error: e);
      }
    }

    _log('이미지 $imageId AI 태그 조회 완료: ${allTags.length}개');
    return allTags;
  } catch (e) {
    _log('AI 태그 조회 오류: $e', level: LogLevel.error, error: e);
    return [];
  }
}

/// 이미지 상세 정보 조회 (태그 포함)
/// Get detailed image information including tags
/// This fetches the image from backend and updates the local Photo with remote tags
Future<Photo?> fetchImageDetails(String photoId) async {
  try {
    final imageId = int.parse(photoId);
    await NetworkPolicyService.instance.ensureAllowedConnectivity();

    // Get all user images and find the specific one
    final uri = Uri.parse('$_baseUrl/api/users/me/images');
    _log('이미지 상세 정보 조회: $photoId');

    final headers = await _getAuthHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final images = data
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList();

      // Find the specific image
      final imageResponse = images.firstWhere(
        (img) => img.id == imageId,
        orElse: () => throw Exception('Image not found'),
      );

      _log('이미지 상세 정보 조회 성공: $photoId');

      // 카테고리별로 AI 태그 조회 (category:tag_name 형식)
      final systemTags = await fetchAiTagsForImage(imageId);
      _log('AI 태그 조회 완료: ${systemTags.length}개');

      // Create Photo object with updated AI tags
      final photo = Photo(
        id: photoId,
        url: 'cache://$photoId',
        remoteUrl: imageResponse.url,
        fileName: imageResponse.url?.split('/').last ?? 'image_$photoId',
        createdAt: imageResponse.uploadedAt,
        fileSize: imageResponse.fileSize,
        metadata: PhotoMetadata(
          systemTags: systemTags,
          userTags: [], // User tags should be preserved from existing photo
          additionalInfo: imageResponse.metadata?.toMap(),
        ),
        uploadStatus: UploadStatus.completed,
      );

      return photo;
    } else {
      _log(
        '이미지 상세 정보 조회 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      return null;
    }
  } catch (e) {
    _log('이미지 상세 정보 조회 오류: $e', level: LogLevel.error, error: e);
    return null;
  }
}