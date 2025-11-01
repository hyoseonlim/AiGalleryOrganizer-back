import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../data/models/photo_models.dart';
import '../data/repositories/local_photo_repository.dart';
import '../data/cache/photo_cache_service.dart';
import 'image_service.dart';

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'GalleryService',
    level: level.index * 300,
    error: error,
  );
}

final _localRepo = LocalPhotoRepository();
final _photoCacheService = PhotoCacheService();

/// 백엔드에서 이미지 목록을 불러오고 로컬 썸네일 캐시와 통합
///
/// 프로세스:
/// 1. 백엔드 API에서 이미지 목록 조회 (/api/users/me/images)
/// 2. 로컬 캐시에서 썸네일 확인 (있으면 사용)
/// 3. 없으면 view URL로 썸네일 다운로드 후 캐시
/// 4. Photo 객체 리스트 반환
Future<List<Photo>> loadPhotosFromBackend({
  Function(int current, int total)? onProgress,
}) async {
  try {
    _log('백엔드에서 이미지 목록 불러오기 시작');

    // 1. 백엔드에서 이미지 목록 조회
    final imageResponses = await getMyImages();
    _log('백엔드 이미지 ${imageResponses.length}개 조회 완료');

    final photos = <Photo>[];

    for (var i = 0; i < imageResponses.length; i++) {
      final imageResponse = imageResponses[i];
      final imageId = imageResponse.id.toString();

      try {
        // 2. 로컬 캐시에서 썸네일 확인
        final cachedThumbnail = await _photoCacheService.getCachedThumbnail(imageId);

        if (cachedThumbnail != null) {
          // 캐시 히트: 로컬 썸네일 사용
          _log('썸네일 캐시 히트: $imageId', level: LogLevel.debug);

          final photo = Photo(
            id: imageId,
            url: 'cache://$imageId', // 로컬 캐시 경로
            remoteUrl: imageResponse.url,
            fileName: imageResponse.url?.split('/').last ?? 'image_$imageId',
            createdAt: imageResponse.uploadedAt,
            fileSize: imageResponse.fileSize,
            metadata: PhotoMetadata(
              systemTags: imageResponse.aiTags.map((tag) => PhotoTag(
                id: tag,
                name: tag,
                type: TagType.system,
              )).toList(),
              additionalInfo: imageResponse.metadata?.toMap(),
            ),
            uploadStatus: UploadStatus.completed,
          );

          photos.add(photo);
        } else {
          // 캐시 미스: view URL 조회 및 썸네일 다운로드
          _log('썸네일 캐시 미스: $imageId, view URL 조회 중', level: LogLevel.debug);

          final viewResponse = await getImageViewUrl(imageResponse.id);
          if (viewResponse != null) {
            // 썸네일 다운로드 및 캐시 저장
            try {
              final response = await http.get(Uri.parse(viewResponse.url));
              if (response.statusCode == 200) {
                final thumbnailBytes = response.bodyBytes;

                // 캐시에 저장
                await _photoCacheService.cacheThumbnail(imageId, thumbnailBytes);
                _log('썸네일 다운로드 및 캐시 저장 완료: $imageId', level: LogLevel.debug);

                final photo = Photo(
                  id: imageId,
                  url: 'cache://$imageId',
                  remoteUrl: viewResponse.url,
                  fileName: imageResponse.url?.split('/').last ?? viewResponse.url.split('/').last,
                  createdAt: imageResponse.uploadedAt,
                  fileSize: imageResponse.fileSize,
                  metadata: PhotoMetadata(
                    systemTags: imageResponse.aiTags.map((tag) => PhotoTag(
                      id: tag,
                      name: tag,
                      type: TagType.system,
                    )).toList(),
                    additionalInfo: imageResponse.metadata?.toMap(),
                  ),
                  uploadStatus: UploadStatus.completed,
                );

                photos.add(photo);
              } else {
                _log('썸네일 다운로드 실패: $imageId (${response.statusCode})', level: LogLevel.warning);
              }
            } catch (e) {
              _log('썸네일 다운로드 오류: $imageId - $e', level: LogLevel.error, error: e);
            }
          } else {
            _log('view URL 조회 실패: $imageId', level: LogLevel.warning);
          }
        }

        onProgress?.call(i + 1, imageResponses.length);
      } catch (e) {
        _log('이미지 처리 오류: $imageId - $e', level: LogLevel.error, error: e);
      }
    }

    _log('이미지 목록 불러오기 완료: ${photos.length}/${imageResponses.length}개');
    return photos;
  } catch (e) {
    _log('이미지 목록 불러오기 실패: $e', level: LogLevel.error, error: e);
    rethrow;
  }
}

/// 백엔드와 로컬 데이터를 병합하여 완전한 갤러리 목록 생성
///
/// 프로세스:
/// 1. 백엔드에서 이미지 목록 불러오기
/// 2. 로컬에만 있는 업로드 중인 이미지 추가
/// 3. 날짜별로 그룹화하여 반환
Future<Map<String, List<Photo>>> loadGalleryPhotos({
  Function(int current, int total)? onProgress,
}) async {
  try {
    _log('갤러리 사진 목록 불러오기 시작');

    // 1. 백엔드에서 완료된 이미지 불러오기
    final backendPhotos = await loadPhotosFromBackend(onProgress: onProgress);

    // 2. 로컬에서 업로드 중인 이미지 가져오기
    final uploadingPhotos = await _localRepo.getUploadingPhotos();
    _log('업로드 중인 이미지: ${uploadingPhotos.length}개');

    // 3. 병합 (업로드 중인 이미지가 우선)
    final allPhotos = [...uploadingPhotos, ...backendPhotos];
    _log('전체 이미지: ${allPhotos.length}개 (백엔드: ${backendPhotos.length}, 업로드 중: ${uploadingPhotos.length})');

    // 4. 날짜별로 그룹화
    final photosByDate = <String, List<Photo>>{};
    for (final photo in allPhotos) {
      final date = photo.createdAt ?? DateTime.now();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!photosByDate.containsKey(dateKey)) {
        photosByDate[dateKey] = [];
      }
      photosByDate[dateKey]!.add(photo);
    }

    // 5. 각 날짜별 리스트를 최신순으로 정렬
    for (final entry in photosByDate.entries) {
      entry.value.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.now();
        final bTime = b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime); // 최신순
      });
    }

    _log('날짜별 그룹화 완료: ${photosByDate.length}개 날짜');
    return photosByDate;
  } catch (e) {
    _log('갤러리 사진 목록 불러오기 실패: $e', level: LogLevel.error, error: e);
    rethrow;
  }
}