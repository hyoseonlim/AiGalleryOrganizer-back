import 'dart:io';
import '../gallery_api_client.dart';
import '../models/api_response.dart';
import '../../models/photo_models.dart';

/// 업로드 관련 API 엔드포인트
class UploadApi {
  final GalleryApiClient _client;

  UploadApi(this._client);

  /// Presigned URL 요청
  Future<ApiResponse<PresignedUrlResponse>> requestPresignedUrls(
    int imageCount,
  ) async {
    final response = await _client.post<PresignedUrlResponse>(
      '/api/images/upload/request',
      body: {'image_count': imageCount},
      parser: (json) => PresignedUrlResponse.fromMap(json),
    );

    return response;
  }

  /// Presigned URL로 파일 업로드 (S3 등)
  Future<ApiResponse<void>> uploadToPresignedUrl(
    File file,
    String presignedUrl, {
    String? contentType,
  }) async {
    final fileBytes = await file.readAsBytes();

    final response = await _client.putBytes(
      presignedUrl,
      bytes: fileBytes,
      headers: {
        'Content-Type': contentType ?? 'application/octet-stream',
        'Content-Length': fileBytes.length.toString(),
      },
    );

    return response;
  }

  /// 업로드 완료 알림
  /// imageId: 업로드된 이미지 ID
  /// hash: 파일 해시값 (SHA-256)
  /// metadata: 이미지 메타데이터 (width, height, EXIF 등)
  Future<ApiResponse<UploadCompleteResponse>> notifyUploadComplete(
    int imageId, {
    String? hash,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'image_id': imageId,
      if (hash != null) 'hash': hash,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _client.post<UploadCompleteResponse>(
      '/api/images/upload/complete',
      body: body,
      parser: (json) => UploadCompleteResponse.fromMap(json),
    );

    return response;
  }





}
