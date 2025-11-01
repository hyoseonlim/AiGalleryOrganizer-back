import 'package:front/api/vizota_api.dart';

/// AI 제안 서비스
class SuggestionService {
  final _apiService = SimilarGroupsApiService();

  /// 유사 그룹 찾기 및 생성
  Future<List<SimilarGroupResponse>> findAndGroupImages({
    double eps = 0.15,
    int minSamples = 2,
  }) async {
    return await _apiService.findAndGroupImages(eps: eps, minSamples: minSamples);
  }

  /// 제안된 유사 그룹 목록 조회
  Future<List<SimilarGroupResponse>> getSuggestedGroups() async {
    return await _apiService.getSuggestedGroups();
  }

  /// 특정 그룹의 이미지 목록 조회
  Future<List<ImageResponse>> getImagesForGroup(int groupId) async {
    return await _apiService.getImagesForGroup(groupId);
  }

  /// 제안 거절
  Future<void> rejectSuggestion(int groupId) async {
    await _apiService.rejectSuggestedGroup(groupId);
  }

  /// 선택한 이미지 삭제하고 제안 확인
  Future<void> confirmWithSelectedImages(
    int groupId,
    List<int> imageIdsToDelete,
  ) async {
    await _apiService.confirmSuggestedGroup(groupId, imageIdsToDelete);
  }

  /// 대표 이미지만 남기고 나머지 삭제
  Future<void> confirmBestImage(int groupId) async {
    await _apiService.confirmBestImageForGroup(groupId);
  }
}
