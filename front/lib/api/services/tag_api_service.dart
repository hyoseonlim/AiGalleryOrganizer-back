import '../models/api_models.dart';
import '../base_api.dart';

/// 태그 & 카테고리 API 서비스
class TagApiService extends BaseApi {
  TagApiService() : super('TagAPI');

  // ============================================================================
  // Category API
  // ============================================================================

  /// 모든 카테고리 조회
  Future<List<CategoryResponse>> getAllCategories({
    int skip = 0,
    int limit = 100,
  }) async {
    return get(
      '${ApiConfig.apiPrefix}/categories/',
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
      fromJson: (data) => (data as List)
          .map((item) => CategoryResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 카테고리 생성
  Future<CategoryResponse> createCategory(CategoryCreate category) async {
    return post(
      '${ApiConfig.apiPrefix}/categories/',
      body: category.toMap(),
      fromJson: (data) => CategoryResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 특정 카테고리 조회
  Future<CategoryResponse> getCategoryById(int categoryId) async {
    return get(
      '${ApiConfig.apiPrefix}/categories/$categoryId',
      fromJson: (data) => CategoryResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 카테고리 업데이트
  Future<CategoryResponse> updateCategory(
    int categoryId,
    CategoryUpdate update,
  ) async {
    return put(
      '${ApiConfig.apiPrefix}/categories/$categoryId',
      body: update.toMap(),
      fromJson: (data) => CategoryResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(int categoryId) async {
    return delete('${ApiConfig.apiPrefix}/categories/$categoryId');
  }

  // ============================================================================
  // Tag API
  // ============================================================================

  /// 모든 태그 조회
  Future<List<TagResponse>> getAllTags({
    int skip = 0,
    int limit = 100,
  }) async {
    return get(
      '${ApiConfig.apiPrefix}/tags/',
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
      fromJson: (data) => (data as List)
          .map((item) => TagResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 태그 생성
  Future<TagResponse> createTag(TagCreate tag) async {
    return post(
      '${ApiConfig.apiPrefix}/tags/',
      body: tag.toMap(),
      fromJson: (data) => TagResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 특정 태그 조회
  Future<TagResponse> getTagById(int tagId) async {
    return get(
      '${ApiConfig.apiPrefix}/tags/$tagId',
      fromJson: (data) => TagResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 태그 업데이트
  Future<TagResponse> updateTag(int tagId, TagUpdate update) async {
    return put(
      '${ApiConfig.apiPrefix}/tags/$tagId',
      body: update.toMap(),
      fromJson: (data) => TagResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 태그 삭제
  Future<void> deleteTag(int tagId) async {
    return delete('${ApiConfig.apiPrefix}/tags/$tagId');
  }
}
