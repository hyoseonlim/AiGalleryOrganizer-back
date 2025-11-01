import '../gallery_api_client.dart';
import '../models/api_response.dart';
import '../../models/photo_models.dart';

/// 이미지 조회 관련 API 엔드포인트
class ImageApi {
  final GalleryApiClient _client;

  ImageApi(this._client);

  /// 특정 사용자의 모든 이미지 상태
  /// [
  ///   {
  ///     "id": 0,
  ///     "url": "string",
  ///     "uploaded_at": "2025-11-01T05:49:25.626Z",
  ///     "ai_processing_status": "PENDING"
  ///   }
  /// ]
  Future<ApiResponse<List<ImageResponse>>> getMyImages({String? userId}) async {
    final response = await _client.get<List<dynamic>>(
      '/api/users/users/me/images',
    );

    if (response.success && response.data != null) {
      try {
        final images = (response.data as List<dynamic>)
            .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(
          data: images,
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '이미지 목록 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      error: response.error ?? '이미지 목록 조회 실패',
      statusCode: response.statusCode,
    );
  }

  /// 특정 이미지의 view URL 조회 (CloudFront URL)
  /// {
  ///   "image_id": 0,
  ///   "url": "string"
  /// }
  Future<ApiResponse<ImageViewableResponse>> getImageViewUrl(int imageId) async {
    final response = await _client.get<ImageViewableResponse>(
      '/api/images/$imageId/view',
      parser: (json) => ImageViewableResponse.fromMap(json),
    );

    return response;
  }

}
