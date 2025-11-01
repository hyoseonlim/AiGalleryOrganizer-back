import 'package:front/features/gallery/data/api/gallery_api_client.dart';
import 'package:front/features/gallery/data/api/models/api_response.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';
import 'models/similar_group_models.dart';

class SuggestionApi {
  SuggestionApi(this._client);

  final GalleryApiClient _client;

  Future<ApiResponse<List<SimilarGroup>>> fetchSuggestedGroups() async {
    final response = await _client.get<List<dynamic>>('/api/similar-groups');
    if (response.success && response.data != null) {
      try {
        final groups = (response.data as List<dynamic>)
            .map((json) => SimilarGroup.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(
          data: groups,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '유사 그룹 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }
    return ApiResponse.failure(
      error: response.error ?? '유사 그룹 조회 실패',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<List<ImageResponse>>> fetchGroupImages(int groupId) async {
    final response = await _client.get<List<dynamic>>(
      '/api/similar-groups/$groupId/images',
    );
    if (response.success && response.data != null) {
      try {
        final images = (response.data as List<dynamic>)
            .map((json) => ImageResponse.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(
          data: images,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '그룹 이미지 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }
    return ApiResponse.failure(
      error: response.error ?? '그룹 이미지 조회 실패',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<void>> rejectGroup(int groupId) async {
    final response = await _client.delete<void>('/api/similar-groups/$groupId');
    return response;
  }

  Future<ApiResponse<void>> confirmGroup({
    required int groupId,
    required List<int> imageIdsToDelete,
  }) async {
    final response = await _client.post<void>(
      '/api/similar-groups/$groupId/confirm',
      body: {'image_ids_to_delete': imageIdsToDelete},
    );
    return response;
  }

  Future<ApiResponse<void>> confirmBest(int groupId) async {
    final response = await _client.post<void>(
      '/api/similar-groups/$groupId/confirm-best',
    );
    return response;
  }

  Future<ApiResponse<List<SimilarGroup>>> createGroups({
    double eps = 0.15,
    int minSamples = 2,
  }) async {
    final response = await _client.post<List<dynamic>>(
      '/api/similar-groups',
      body: {'eps': eps, 'min_samples': minSamples},
    );
    if (response.success && response.data != null) {
      try {
        final groups = (response.data as List<dynamic>)
            .map((json) => SimilarGroup.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(
          data: groups,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '유사 그룹 생성 응답 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }
    return ApiResponse.failure(
      error: response.error ?? '유사 그룹 생성 실패',
      statusCode: response.statusCode,
    );
  }
}
