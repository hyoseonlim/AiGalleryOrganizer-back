import '../models/api_models.dart';
import '../base_api.dart';

/// 앨범 API 서비스
class AlbumApiService extends BaseApi {
  AlbumApiService() : super('AlbumAPI');

  /// 모든 앨범 조회
  Future<List<AlbumResponse>> getAllAlbums() async {
    return get(
      '${ApiConfig.apiPrefix}/albums/',
      fromJson: (data) => (data as List)
          .map((item) => AlbumResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 앨범 생성
  Future<AlbumResponse> createAlbum(AlbumCreate album) async {
    return post(
      '${ApiConfig.apiPrefix}/albums/',
      body: album.toMap(),
      fromJson: (data) => AlbumResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 특정 앨범 조회
  Future<AlbumResponse> getAlbumById(int albumId) async {
    return get(
      '${ApiConfig.apiPrefix}/albums/$albumId',
      fromJson: (data) => AlbumResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 앨범 업데이트
  Future<AlbumResponse> updateAlbum(int albumId, AlbumUpdate update) async {
    return put(
      '${ApiConfig.apiPrefix}/albums/$albumId',
      body: update.toMap(),
      fromJson: (data) => AlbumResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 앨범 삭제
  Future<void> deleteAlbum(int albumId) async {
    return delete('${ApiConfig.apiPrefix}/albums/$albumId');
  }

  /// 앨범에 이미지 추가
  Future<void> addImagesToAlbum(int albumId, List<int> imageIds) async {
    return post(
      '${ApiConfig.apiPrefix}/albums/$albumId/images',
      body: {'image_ids': imageIds},
    );
  }

  /// 앨범에서 이미지 제거
  Future<void> removeImagesFromAlbum(int albumId, List<int> imageIds) async {
    return delete(
      '${ApiConfig.apiPrefix}/albums/$albumId/images',
      body: {'image_ids': imageIds},
    );
  }
}
