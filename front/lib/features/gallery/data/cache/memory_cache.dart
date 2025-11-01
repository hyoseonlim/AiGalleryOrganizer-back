import '../models/photo_models.dart';

/// 메모리 기반 사진 캐시
/// 앱 세션 동안만 유지되며, 네트워크 요청을 최소화합니다.
class PhotoMemoryCache {
  // Photo 캐시 (Map<photoId, Photo>)
  final Map<String, Photo> _photoCache = {};

  // 썸네일 바이트 캐시 (Map<photoId, bytes>)
  final Map<String, List<int>> _thumbnailCache = {};

  // ImageResponse 캐시 (Map<imageId, ImageResponse>)
  final Map<int, ImageResponse> _imageResponseCache = {};

  // Singleton pattern
  static final PhotoMemoryCache _instance = PhotoMemoryCache._internal();
  factory PhotoMemoryCache() => _instance;
  PhotoMemoryCache._internal();

  // ========== Photo 캐시 ==========

  /// Photo 가져오기
  Photo? getPhoto(String photoId) => _photoCache[photoId];

  /// Photo 저장
  void setPhoto(String photoId, Photo photo) {
    _photoCache[photoId] = photo;
  }

  /// Photo 제거
  void removePhoto(String photoId) {
    _photoCache.remove(photoId);
    _thumbnailCache.remove(photoId);
  }

  /// 모든 Photo 가져오기
  List<Photo> getAllPhotos() => _photoCache.values.toList();

  /// Photo 캐시 개수
  int get photoCount => _photoCache.length;

  // ========== 썸네일 캐시 ==========

  /// 썸네일 바이트 가져오기
  List<int>? getThumbnail(String photoId) => _thumbnailCache[photoId];

  /// 썸네일 바이트 저장
  void setThumbnail(String photoId, List<int> bytes) {
    _thumbnailCache[photoId] = bytes;
  }

  /// 썸네일 제거
  void removeThumbnail(String photoId) {
    _thumbnailCache.remove(photoId);
  }

  // ========== ImageResponse 캐시 ==========

  /// ImageResponse 가져오기
  ImageResponse? getImageResponse(int imageId) => _imageResponseCache[imageId];

  /// ImageResponse 저장
  void setImageResponse(int imageId, ImageResponse imageResponse) {
    _imageResponseCache[imageId] = imageResponse;
  }

  /// ImageResponse 제거
  void removeImageResponse(int imageId) {
    _imageResponseCache.remove(imageId);
  }

  // ========== 일괄 작업 ==========

  /// 전체 캐시 초기화
  void clear() {
    _photoCache.clear();
    _thumbnailCache.clear();
    _imageResponseCache.clear();
  }

  /// 특정 Photo와 관련된 모든 캐시 제거
  void removeAllRelated(String photoId) {
    removePhoto(photoId);
    removeThumbnail(photoId);
  }

  /// 캐시 상태 정보
  Map<String, int> getCacheInfo() {
    return {
      'photos': _photoCache.length,
      'thumbnails': _thumbnailCache.length,
      'imageResponses': _imageResponseCache.length,
    };
  }
}
