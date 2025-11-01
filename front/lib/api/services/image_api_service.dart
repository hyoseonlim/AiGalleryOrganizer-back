import '../models/api_models.dart';
import '../base_api.dart';

/// 이미지 API 서비스
class ImageApiService extends BaseApi {
  ImageApiService() : super('ImageAPI');

  /// 현재 사용자의 모든 이미지 조회
  Future<List<ImageResponse>> getMyImages() async {
    return get(
      '${ApiConfig.apiPrefix}/users/me/images',
      fromJson: (data) => (data as List)
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 모든 이미지 조회 (페이지네이션)
  Future<List<ImageResponse>> getAllImages({
    int skip = 0,
    int limit = 100,
  }) async {
    return get(
      '${ApiConfig.apiPrefix}/images/',
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
      fromJson: (data) => (data as List)
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 이미지 view URL 조회
  Future<ImageViewableResponse> getImageViewUrl(int imageId) async {
    return get(
      '${ApiConfig.apiPrefix}/images/$imageId/view',
      fromJson: (data) => ImageViewableResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 이미지 바이트 다운로드 (CloudFront URL 등)
  Future<List<int>> downloadImageBytes(String imageUrl) async {
    return getBytes(imageUrl, requiresAuth: false);
  }

  /// Presigned URL 요청
  Future<PresignedUrlResponse> requestUploadUrls(
    ImageUploadRequest request,
  ) async {
    return post(
      '${ApiConfig.apiPrefix}/images/upload/request',
      body: request.toMap(),
      fromJson: (data) => PresignedUrlResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 업로드 완료 알림
  Future<UploadCompleteResponse> notifyUploadComplete(
    int imageId,
    ImageMetadata metadata,
  ) async {
    return post(
      '${ApiConfig.apiPrefix}/images/upload/complete',
      body: {
        'image_id': imageId,
        'metadata': metadata.toMap(),
      },
      fromJson: (data) => UploadCompleteResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 이미지 소프트 삭제 (휴지통으로 이동)
  Future<void> softDeleteImage(int imageId) async {
    return delete('${ApiConfig.apiPrefix}/images/$imageId');
  }

  /// 휴지통 이미지 조회
  Future<List<ImageResponse>> getTrashedImages() async {
    return get(
      '${ApiConfig.apiPrefix}/images/trash',
      fromJson: (data) => (data as List)
          .map((item) => ImageResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 이미지 복원
  Future<ImageResponse> restoreImage(int imageId) async {
    return post(
      '${ApiConfig.apiPrefix}/images/$imageId/restore',
      fromJson: (data) => ImageResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 이미지 영구 삭제
  Future<void> permanentlyDeleteImage(int imageId) async {
    return delete('${ApiConfig.apiPrefix}/images/trash/$imageId');
  }

  /// 이미지에 태그 추가
  Future<void> addTagsToImage(int imageId, List<String> tagNames) async {
    return post(
      '${ApiConfig.apiPrefix}/images/$imageId/tags',
      body: {'tag_names': tagNames},
    );
  }

  /// 이미지에서 태그 제거
  Future<void> removeTagsFromImage(int imageId, List<String> tagNames) async {
    return delete(
      '${ApiConfig.apiPrefix}/images/$imageId/tags',
      body: {'tag_names': tagNames},
    );
  }

  /// AI 분석 결과 수신
  Future<void> receiveAnalysisResults(
    int imageId,
    ImageAnalysisResult result,
  ) async {
    return post(
      '${ApiConfig.apiPrefix}/images/$imageId/analysis-results',
      body: result.toMap(),
      requiresAuth: false,
    );
  }
}
