import '../gallery_api_client.dart';
import '../models/api_response.dart';

class TagApi {
  TagApi(this._client);

  final GalleryApiClient _client;

  Future<ApiResponse<List<dynamic>>> getTags() {
    return _client.get<List<dynamic>>('/api/tags');
  }

  Future<ApiResponse<Map<String, dynamic>>> getTag(int tagId) {
    return _client.get<Map<String, dynamic>>('/api/tags/$tagId');
  }

  Future<ApiResponse<Map<String, dynamic>>> createTag({
    required String name,
    required int categoryId,
  }) {
    return _client.post<Map<String, dynamic>>(
      '/api/tags',
      body: {'name': name, 'category_id': categoryId},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateTag({
    required int tagId,
    String? name,
    int? categoryId,
  }) {
    return _client.putJson<Map<String, dynamic>>(
      '/api/tags/$tagId',
      body: {
        if (name != null) 'name': name,
        if (categoryId != null) 'category_id': categoryId,
      },
    );
  }

  Future<ApiResponse<void>> deleteTag(int tagId) {
    return _client.delete<void>('/api/tags/$tagId');
  }
}
