import '../gallery_api_client.dart';
import '../models/api_response.dart';

/// API endpoints for trash/delete operations
class TrashApi {
  TrashApi(this._client);

  final GalleryApiClient _client;

  /// Soft delete (move to trash) a single image
  Future<ApiResponse<void>> softDeleteImage(int imageId) async {
    final response = await _client.delete<void>('/api/v1/images/$imageId/soft-delete');
    return response;
  }

  /// Soft delete (move to trash) multiple images
  Future<ApiResponse<Map<String, dynamic>>> softDeleteMultipleImages(
    List<int> imageIds,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/images/soft-delete',
      body: {'image_ids': imageIds},
    );
    return response;
  }

  /// Permanently delete an image
  Future<ApiResponse<void>> permanentlyDeleteImage(int imageId) async {
    final response = await _client.delete<void>('/api/v1/images/$imageId');
    return response;
  }

  /// Restore image from trash
  Future<ApiResponse<void>> restoreImage(int imageId) async {
    final response = await _client.post<void>(
      '/api/v1/images/$imageId/restore',
    );
    return response;
  }

  /// Get all trashed images
  Future<ApiResponse<List<dynamic>>> getTrashedImages() async {
    final response = await _client.get<List<dynamic>>('/api/v1/trash');
    return response;
  }

  /// Empty trash (permanently delete all trashed images)
  Future<ApiResponse<void>> emptyTrash() async {
    final response = await _client.delete<void>('/api/v1/trash');
    return response;
  }
}