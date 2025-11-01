import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/photo_models.dart';
import '../cache/photo_cache_service.dart';

/// 로컬 사진 저장소 - 사진 파일과 메타데이터를 로컬에 저장/관리
class LocalPhotoRepository {
  static const String _photoIndexKey = 'local_photo_index';
  static const String _photoMetadataPrefix = 'local_photo_meta_';

  final PhotoCacheService _cacheService;
  SharedPreferences? _prefs;
  Directory? _originalPhotosDir;

  // Singleton pattern
  static final LocalPhotoRepository _instance = LocalPhotoRepository._internal();
  factory LocalPhotoRepository() => _instance;
  LocalPhotoRepository._internal() : _cacheService = PhotoCacheService();

  void _log(String message, {bool isError = false}) {
    developer.log(
      message,
      time: DateTime.now(),
      name: 'LocalPhotoRepository',
      level: isError ? 900 : 500,
    );
  }

  /// 저장소 초기화
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 썸네일 캐시 초기화
      await _cacheService.initialize();

      // 원본 사진 디렉토리 초기화 (다운로드된 원본 저장용)
      final appDir = await getApplicationDocumentsDirectory();
      _originalPhotosDir = Directory(path.join(appDir.path, 'original_photos'));
      if (!await _originalPhotosDir!.exists()) {
        await _originalPhotosDir!.create(recursive: true);
      }

      _log('로컬 사진 저장소 초기화 완료 (메타데이터 + 썸네일 + 원본 다운로드)');
    } catch (e) {
      _log('로컬 사진 저장소 초기화 실패: $e', isError: true);
    }
  }

  /// 사진 메타데이터를 로컬에 저장 (원본 파일은 저장하지 않음)
  /// sourceFile은 썸네일 생성 후 크기 확인용으로만 사용
  Future<Photo?> savePhotoMetadata({
    required String fileName,
    required int fileSize,
    List<int>? thumbnailBytes,
  }) async {
    try {
      if (_prefs == null) {
        _log('저장소가 초기화되지 않음', isError: true);
        return null;
      }

      // 고유 ID 생성
      final photoId = DateTime.now().millisecondsSinceEpoch.toString();

      // 썸네일 캐시 저장
      if (thumbnailBytes != null) {
        await _cacheService.cacheThumbnail(photoId, thumbnailBytes);
      }

      // Photo 객체 생성 (url은 임시로 photoId 사용, 나중에 remoteUrl로 업데이트)
      final photo = Photo(
        id: photoId,
        url: photoId, // 임시 ID, remoteUrl이 설정되면 그걸 사용
        remoteUrl: null, // 백엔드 업로드 후 설정
        fileName: fileName,
        createdAt: DateTime.now(),
        fileSize: fileSize,
        metadata: const PhotoMetadata(
          systemTags: [],
          userTags: [],
        ),
        uploadStatus: UploadStatus.pending,
      );

      // 메타데이터 저장
      await _savePhotoMetadata(photo);

      // 인덱스에 추가
      await _addToIndex(photoId);

      _log('사진 메타데이터 로컬 저장 완료: $photoId');

      return photo;
    } catch (e) {
      _log('사진 저장 실패: $e', isError: true);
      return null;
    }
  }

  /// 백엔드에서 받은 정보로 사진 업데이트
  Future<void> updatePhotoFromBackend({
    required String photoId,
    required String remoteUrl,
    PhotoMetadata? metadata,
  }) async {
    try {
      final photo = await _loadPhotoMetadata(photoId);
      if (photo != null) {
        final updatedPhoto = photo.copyWith(
          url: remoteUrl,
          remoteUrl: remoteUrl,
          metadata: metadata ?? photo.metadata,
          uploadStatus: UploadStatus.completed,
        );
        await _savePhotoMetadata(updatedPhoto);
        _log('사진 백엔드 정보 업데이트: $photoId');
      }
    } catch (e) {
      _log('백엔드 정보 업데이트 실패: $e', isError: true);
    }
  }


  /// 모든 로컬 사진 가져오기
  Future<List<Photo>> getAllPhotos() async {
    try {
      if (_prefs == null) {
        _log('저장소가 초기화되지 않음', isError: true);
        return [];
      }

      final photoIds = _getPhotoIndex();
      final photos = <Photo>[];

      for (final photoId in photoIds) {
        final photo = await _loadPhotoMetadata(photoId);
        if (photo != null) {
          photos.add(photo);
        }
      }

      // 최신순으로 정렬
      photos.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      _log('로컬 사진 로드 완료: ${photos.length}개');

      return photos;
    } catch (e) {
      _log('사진 로드 실패: $e', isError: true);
      return [];
    }
  }

  /// 날짜별로 그룹화된 사진 가져오기
  Future<Map<String, List<Photo>>> getPhotosByDate() async {
    final allPhotos = await getAllPhotos();
    final groupedPhotos = <String, List<Photo>>{};

    for (final photo in allPhotos) {
      final dateKey = _formatDate(photo.createdAt ?? DateTime.now());
      if (!groupedPhotos.containsKey(dateKey)) {
        groupedPhotos[dateKey] = [];
      }
      groupedPhotos[dateKey]!.add(photo);
    }

    return groupedPhotos;
  }

  /// 업로드 중이거나 대기 중인 사진만 가져오기
  Future<List<Photo>> getUploadingPhotos() async {
    try {
      final allPhotos = await getAllPhotos();
      final uploadingPhotos = allPhotos.where((photo) =>
        photo.uploadStatus == UploadStatus.pending ||
        photo.uploadStatus == UploadStatus.uploading
      ).toList();

      _log('업로드 중인 사진: ${uploadingPhotos.length}개');
      return uploadingPhotos;
    } catch (e) {
      _log('업로드 중인 사진 조회 실패: $e', isError: true);
      return [];
    }
  }

  /// 사진 업로드 상태 업데이트
  Future<void> updateUploadStatus(String photoId, UploadStatus status) async {
    try {
      final photo = await _loadPhotoMetadata(photoId);
      if (photo != null) {
        final updatedPhoto = photo.copyWith(uploadStatus: status);
        await _savePhotoMetadata(updatedPhoto);
        _log('사진 업로드 상태 업데이트: $photoId -> $status');
      }
    } catch (e) {
      _log('업로드 상태 업데이트 실패: $e', isError: true);
    }
  }

  /// 백엔드에서 받은 메타데이터로 사진 업데이트
  Future<void> updatePhotoMetadata(String photoId, PhotoMetadata metadata) async {
    try {
      final photo = await _loadPhotoMetadata(photoId);
      if (photo != null) {
        final updatedPhoto = photo.copyWith(
          metadata: metadata,
          uploadStatus: UploadStatus.completed,
        );
        await _savePhotoMetadata(updatedPhoto);
        _log('사진 메타데이터 업데이트: $photoId');
      }
    } catch (e) {
      _log('메타데이터 업데이트 실패: $e', isError: true);
    }
  }

  /// 사진 삭제 (메타데이터, 썸네일, 원본 모두 삭제)
  Future<bool> deletePhoto(String photoId) async {
    try {
      if (_prefs == null) {
        return false;
      }

      // 썸네일 캐시 삭제
      await _cacheService.removeCachedThumbnail(photoId);

      // 원본 이미지 삭제 (있는 경우)
      await deleteOriginalPhoto(photoId);

      // 메타데이터 삭제
      await _prefs!.remove('$_photoMetadataPrefix$photoId');

      // 인덱스에서 제거
      await _removeFromIndex(photoId);

      _log('사진 메타데이터, 썸네일, 원본 삭제 완료: $photoId');

      // TODO: 백엔드에 삭제 요청 보내기
      // await deletePhotoFromBackend(photoId);

      return true;
    } catch (e) {
      _log('사진 삭제 실패: $e', isError: true);
      return false;
    }
  }

  /// 여러 사진 삭제
  Future<int> deletePhotos(List<String> photoIds) async {
    int deletedCount = 0;

    for (final photoId in photoIds) {
      if (await deletePhoto(photoId)) {
        deletedCount++;
      }
    }

    _log('일괄 삭제 완료: $deletedCount/${photoIds.length}');

    return deletedCount;
  }

  /// 썸네일 가져오기
  Future<File?> getThumbnail(String photoId) async {
    return await _cacheService.getCachedThumbnail(photoId);
  }

  /// 원본 이미지가 로컬에 있는지 확인
  Future<File?> getOriginalPhoto(String photoId) async {
    try {
      if (_originalPhotosDir == null) {
        _log('원본 사진 디렉토리가 초기화되지 않음', isError: true);
        return null;
      }

      final file = File(path.join(_originalPhotosDir!.path, '$photoId.jpg'));
      if (await file.exists()) {
        _log('로컬 원본 이미지 발견: $photoId');
        return file;
      }
      return null;
    } catch (e) {
      _log('원본 이미지 확인 실패: $e', isError: true);
      return null;
    }
  }

  /// 원본 이미지를 로컬에 저장 (다운로드 버튼 클릭 시)
  Future<File?> saveOriginalPhoto(String photoId, List<int> imageBytes) async {
    try {
      if (_originalPhotosDir == null) {
        _log('원본 사진 디렉토리가 초기화되지 않음', isError: true);
        return null;
      }

      final file = File(path.join(_originalPhotosDir!.path, '$photoId.jpg'));
      await file.writeAsBytes(imageBytes);

      _log('원본 이미지 로컬 저장 완료: $photoId (${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');

      return file;
    } catch (e) {
      _log('원본 이미지 저장 실패: $e', isError: true);
      return null;
    }
  }

  /// 원본 이미지 삭제
  Future<bool> deleteOriginalPhoto(String photoId) async {
    try {
      if (_originalPhotosDir == null) return false;

      final file = File(path.join(_originalPhotosDir!.path, '$photoId.jpg'));
      if (await file.exists()) {
        await file.delete();
        _log('원본 이미지 삭제 완료: $photoId');
        return true;
      }
      return false;
    } catch (e) {
      _log('원본 이미지 삭제 실패: $e', isError: true);
      return false;
    }
  }

  // ========== Private Methods ==========

  /// 사진 메타데이터 저장
  Future<void> _savePhotoMetadata(Photo photo) async {
    if (_prefs == null) return;

    final key = '$_photoMetadataPrefix${photo.id}';
    final jsonString = jsonEncode(photo.toMap());
    await _prefs!.setString(key, jsonString);
  }

  /// 사진 메타데이터 로드
  Future<Photo?> _loadPhotoMetadata(String photoId) async {
    if (_prefs == null) return null;

    try {
      final key = '$_photoMetadataPrefix$photoId';
      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Photo.fromMap(json);
    } catch (e) {
      _log('메타데이터 로드 실패: $photoId - $e', isError: true);
      return null;
    }
  }

  /// 사진 인덱스 가져오기
  List<String> _getPhotoIndex() {
    if (_prefs == null) return [];

    final indexJson = _prefs!.getString(_photoIndexKey);
    if (indexJson == null) return [];

    final List<dynamic> indexList = jsonDecode(indexJson);
    return indexList.map((e) => e.toString()).toList();
  }

  /// 인덱스에 사진 추가
  Future<void> _addToIndex(String photoId) async {
    if (_prefs == null) return;

    final index = _getPhotoIndex();
    if (!index.contains(photoId)) {
      index.add(photoId);
      await _prefs!.setString(_photoIndexKey, jsonEncode(index));
    }
  }

  /// 인덱스에서 사진 제거
  Future<void> _removeFromIndex(String photoId) async {
    if (_prefs == null) return;

    final index = _getPhotoIndex();
    index.remove(photoId);
    await _prefs!.setString(_photoIndexKey, jsonEncode(index));
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;
    return '$year년 $month월 $day일';
  }
}
