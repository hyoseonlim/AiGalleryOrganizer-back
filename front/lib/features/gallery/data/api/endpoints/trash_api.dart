import '../gallery_api_client.dart';
import '../models/api_response.dart';
import '../../models/photo_models.dart';

/// 휴지통 관련 API 엔드포인트
class TrashApi {
  final GalleryApiClient _client;

  TrashApi(this._client);

  /// 이미지 소프트 삭제 (휴지통으로 이동)
  Future<ApiResponse<void>> softDeleteImage(int imageId) async {
    final response = await _client.delete<void>(
      '/api/images/$imageId',
    );

    return response;
  }

  /// 휴지통에서 이미지 복원
  Future<ApiResponse<ImageResponse>> restoreImage(int imageId) async {
    final response = await _client.post<ImageResponse>(
      '/api/images/$imageId/restore',
      parser: (json) => ImageResponse.fromMap(json),
    );

    return response;
  }

  /// 휴지통에서 이미지 영구 삭제
  Future<ApiResponse<void>> permanentlyDeleteImage(int imageId) async {
    final response = await _client.delete<void>(
      '/api/images/trash/$imageId',
    );

    return response;
  }

  /// 휴지통의 모든 이미지 조회
  Future<ApiResponse<List<ImageResponse>>> getTrashedImages() async {
    final response = await _client.get<List<dynamic>>(
      '/api/images/trash',
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
          error: '휴지통 이미지 목록 파싱 오류: $e',
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      error: response.error ?? '휴지통 이미지 목록 조회 실패',
      statusCode: response.statusCode,
    );
  }
}
