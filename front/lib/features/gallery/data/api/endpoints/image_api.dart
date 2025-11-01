import '../gallery_api_client.dart';
import '../models/api_response.dart';
import '../../models/photo_models.dart';

/// API endpoints for image operations
class ImageApi {
  ImageApi(this._client);

  final GalleryApiClient _client;

  /// Get all user's images
  Future<ApiResponse<List<ImageResponse>>> getMyImages() async {
    final response = await _client.get<List<dynamic>>('/api/v1/images');

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
          error: '이미지 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      error: response.error ?? '이미지 조회 실패',
      statusCode: response.statusCode,
    );
  }

  /// Get viewable URL for an image
  Future<ApiResponse<ImageViewableResponse>> getImageViewUrl(int imageId) async {
    final response = await _client.get<Map<String, dynamic>>('/api/v1/images/$imageId/view');

    if (response.success && response.data != null) {
      try {
        final viewableResponse = ImageViewableResponse.fromMap(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: viewableResponse,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '이미지 URL 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      error: response.error ?? '이미지 URL 조회 실패',
      statusCode: response.statusCode,
    );
  }

  /// Get image by ID
  Future<ApiResponse<ImageResponse>> getImage(int imageId) async {
    final response = await _client.get<Map<String, dynamic>>('/api/v1/images/$imageId');

    if (response.success && response.data != null) {
      try {
        final image = ImageResponse.fromMap(response.data as Map<String, dynamic>);
        return ApiResponse.success(
          data: image,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '이미지 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      error: response.error ?? '이미지 조회 실패',
      statusCode: response.statusCode,
    );
  }
}