import 'package:front/features/gallery/data/api/models/api_response.dart';
import 'package:front/features/gallery/data/models/photo_models.dart';
import '../data/models/similar_group_models.dart';
import '../data/suggestion_api.dart';

class AiSuggestionService {
  AiSuggestionService(this._api);

  final SuggestionApi _api;

  Future<ApiResponse<List<SimilarGroup>>> getSuggestedGroups() {
    return _api.fetchSuggestedGroups();
  }

  Future<ApiResponse<List<ImageResponse>>> getGroupImages(int groupId) {
    return _api.fetchGroupImages(groupId);
  }

  Future<ApiResponse<void>> rejectGroup(int groupId) {
    return _api.rejectGroup(groupId);
  }

  Future<ApiResponse<void>> confirmGroup({
    required int groupId,
    required List<int> imageIdsToDelete,
  }) {
    return _api.confirmGroup(
      groupId: groupId,
      imageIdsToDelete: imageIdsToDelete,
    );
  }

  Future<ApiResponse<void>> confirmBest(int groupId) {
    return _api.confirmBest(groupId);
  }

  Future<ApiResponse<List<SimilarGroup>>> regenerateSuggestions({
    double eps = 0.15,
    int minSamples = 2,
  }) {
    return _api.createGroups(eps: eps, minSamples: minSamples);
  }
}
