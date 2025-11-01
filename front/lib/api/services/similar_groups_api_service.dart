import '../models/api_models.dart';
import '../base_api.dart';

/// 유사 그룹 API 서비스
class SimilarGroupsApiService extends BaseApi {
  SimilarGroupsApiService() : super('SimilarGroupsAPI');

  /// 유사한 이미지 그룹 찾기 및 생성
  Future<List<SimilarGroupResponse>> findAndGroupImages({
    double eps = 0.15,
    int minSamples = 2,
  }) async {
    return post(
      '${ApiConfig.apiPrefix}/similar-groups/',
      queryParameters: {
        'eps': eps.toString(),
        'min_samples': minSamples.toString(),
      },
      fromJson: (data) => (data as List)
          .map((item) => SimilarGroupResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 제안된 유사 그룹 목록 조회
  Future<List<SimilarGroupResponse>> getSuggestedGroups() async {
    return get(
      '${ApiConfig.apiPrefix}/similar-groups/',
      fromJson: (data) => (data as List)
          .map((item) => SimilarGroupResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 특정 유사 그룹의 이미지 목록 조회
  Future<List<ImageResponse>> getImagesForGroup(int groupId) async {
    return get(
      '${ApiConfig.apiPrefix}/similar-groups/$groupId/images',
      fromJson: (data) => (data as List)
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 제안된 유사 그룹 거절
  Future<void> rejectSuggestedGroup(int groupId) async {
    return delete('${ApiConfig.apiPrefix}/similar-groups/$groupId');
  }

  /// 제안된 유사 그룹 확인 및 선택된 이미지 삭제
  Future<void> confirmSuggestedGroup(
    int groupId,
    List<int> imageIdsToDelete,
  ) async {
    return post(
      '${ApiConfig.apiPrefix}/similar-groups/$groupId/confirm',
      body: {'image_ids_to_delete': imageIdsToDelete},
    );
  }

  /// 대표 이미지만 남기고 나머지 삭제
  Future<void> confirmBestImageForGroup(int groupId) async {
    return post('${ApiConfig.apiPrefix}/similar-groups/$groupId/confirm-best');
  }
}
