import '../gallery_api_client.dart';
import '../models/api_response.dart';
import '../../models/photo_models.dart';

/// 다운로드 관련 API 엔드포인트
class DownloadApi {
  final GalleryApiClient _client;

  DownloadApi(this._client);

  /// 이미지 view URL 조회 (CloudFront URL)
  Future<ApiResponse<ImageViewableResponse>> getImageViewUrl(int imageId) async {
    final response = await _client.get<ImageViewableResponse>(
      '/api/images/$imageId/view',
      parser: (json) => ImageViewableResponse.fromMap(json),
    );

    return response;
  }

  /// CloudFront URL에서 이미지 다운로드 (바이트 반환)
  Future<ApiResponse<List<int>>> downloadImageBytes(String imageUrl) async {
    final response = await _client.getBytes(imageUrl);
    return response;
  }
}
