import 'dart:io';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'thumbnail_service.dart';
import '../data/cache/photo_cache_service.dart';
import '../data/repositories/local_photo_repository.dart';
import '../data/models/photo_models.dart';

final ImagePicker _imagePicker = ImagePicker();

// Backend server configuration
const String _baseUrl = 'https://your-backend-api.com'; // TODO: Replace with actual backend URL
const String _uploadEndpoint = '/api/v1/upload';        // TODO: Replace with actual endpoint
const String _thumbnailEndpoint = '/api/v1/upload/thumbnail'; // TODO: Replace with actual endpoint

// Cache service instance
final _cacheService = PhotoCacheService();

// Local photo repository instance
final _localRepo = LocalPhotoRepository();

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'GalleryDomain',
    level: level.index * 300,
    error: error,
  );
}

/// Uploads thumbnail to the backend server
/// Returns the server response or null if upload fails
Future<Map<String, dynamic>?> _uploadThumbnailToBackend(
  List<int> thumbnailBytes,
  String originalFileName,
) async {
  try {
    final uri = Uri.parse('$_baseUrl$_thumbnailEndpoint');
    final request = http.MultipartRequest('POST', uri);

    // Create thumbnail filename
    final thumbnailFileName = 'thumb_$originalFileName';

    final multipartFile = http.MultipartFile.fromBytes(
      'thumbnail',
      thumbnailBytes,
      filename: thumbnailFileName,
    );

    request.files.add(multipartFile);
    request.fields['original_filename'] = originalFileName;

    _log('썸네일 업로드 중: $thumbnailFileName (${thumbnailBytes.length} bytes)');

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      _log('썸네일 업로드 성공: $responseBody', level: LogLevel.info);
      return {'success': true, 'data': responseBody};
    } else {
      _log('썸네일 업로드 실패 (status: ${response.statusCode})', level: LogLevel.warning);
      return {'success': false, 'error': 'Status ${response.statusCode}'};
    }
  } catch (e) {
    _log('썸네일 업로드 오류: $e', level: LogLevel.error, error: e);
    return {'success': false, 'error': e.toString()};
  }
}

/// Uploads a file to the backend server using stream
/// Also generates and uploads thumbnail, and caches it locally
/// Returns the server response or null if upload fails
Future<Map<String, dynamic>?> uploadFileToBackend(File file, {String? fileName}) async {
  try {
    final uri = Uri.parse('$_baseUrl$_uploadEndpoint');
    final request = http.MultipartRequest('POST', uri);

    // Use file stream instead of loading entire file into memory
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final fileNameToUse = fileName ?? path.basename(file.path);

    final multipartFile = http.MultipartFile(
      'file',
      stream,
      length,
      filename: fileNameToUse,
    );

    request.files.add(multipartFile);

    // Add additional headers if needed
    // request.headers['Authorization'] = 'Bearer YOUR_TOKEN';

    _log('파일 업로드 중: $fileNameToUse ($length bytes)');

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      _log('파일 업로드 성공: $responseBody', level: LogLevel.info);

      // Generate thumbnail after successful upload
      try {
        _log('썸네일 생성 시작: ${file.path}');
        final thumbnailBytes = await ThumbnailService.generateThumbnail(file);

        if (thumbnailBytes != null) {
          _log('썸네일 생성 성공: ${thumbnailBytes.length} bytes');

          // Cache thumbnail locally
          final cachedFile = await _cacheService.cacheThumbnailByFilePath(
            file.path,
            thumbnailBytes,
          );

          if (cachedFile != null) {
            _log('썸네일 로컬 캐시 저장 완료: ${cachedFile.path}');
          }

          // Upload thumbnail to backend
          final thumbnailUploadResult = await _uploadThumbnailToBackend(
            thumbnailBytes,
            fileNameToUse,
          );

          if (thumbnailUploadResult != null && thumbnailUploadResult['success'] == true) {
            _log('썸네일 백엔드 업로드 완료');
          } else {
            _log('썸네일 백엔드 업로드 실패 (원본 파일은 업로드됨)', level: LogLevel.warning);
          }
        } else {
          _log('썸네일 생성 실패 (원본 파일은 업로드됨)', level: LogLevel.warning);
        }
      } catch (thumbnailError) {
        _log('썸네일 처리 중 오류 (원본 파일은 업로드됨): $thumbnailError',
            level: LogLevel.warning, error: thumbnailError);
      }

      return {'success': true, 'data': responseBody};
    } else {
      _log('파일 업로드 실패 (status: ${response.statusCode})', level: LogLevel.warning);
      return {'success': false, 'error': 'Status ${response.statusCode}'};
    }
  } catch (e) {
    _log('파일 업로드 오류: $e', level: LogLevel.error, error: e);
    return {'success': false, 'error': e.toString()};
  }
}

/// Uploads a file from read stream (for platforms where file path is not available)
Future<Map<String, dynamic>?> uploadFileStreamToBackend(
  Stream<List<int>> readStream,
  int fileSize,
  String fileName,
) async {
  try {
    final uri = Uri.parse('$_baseUrl$_uploadEndpoint');
    final request = http.MultipartRequest('POST', uri);

    final stream = http.ByteStream(readStream);
    final multipartFile = http.MultipartFile(
      'file',
      stream,
      fileSize,
      filename: fileName,
    );

    request.files.add(multipartFile);

    _log('Uploading file stream: $fileName ($fileSize bytes)');

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      _log('Upload successful: $responseBody', level: LogLevel.info);
      return {'success': true, 'data': responseBody};
    } else {
      _log('Upload failed with status: ${response.statusCode}', level: LogLevel.warning);
      return {'success': false, 'error': 'Status ${response.statusCode}'};
    }
  } catch (e) {
    _log('Upload error: $e', level: LogLevel.error, error: e);
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> pickFile({
  Function(int current, int total)? onProgress,
  Function(Photo photo)? onPhotoSaved,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: true,
    withReadStream: true,
    readSequential: true,
  );

  final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'];

  if (result != null && result.files.isNotEmpty) {
    final imageFiles = <File>[];
    final streamFiles = <Map<String, dynamic>>[];

    // Separate files with paths and stream-only files
    for (final file in result.files) {
      final fileExtension = path.extension(file.name).toLowerCase();
      if (!imageExtensions.contains(fileExtension)) {
        _log('이미지 파일이 아닙니다. 건너뜁니다: ${file.name}', level: LogLevel.warning);
        continue;
      }

      _log('파일 선택됨: ${file.name}');

      if (file.path != null) {
        imageFiles.add(File(file.path!));
      } else if (file.readStream != null) {
        streamFiles.add({
          'stream': file.readStream!,
          'size': file.size,
          'name': file.name,
        });
      }
    }

    // Upload files with paths using new uploadAndSaveFiles
    final savedPhotos = await uploadAndSaveFiles(
      imageFiles,
      onProgress: onProgress,
      onPhotoSaved: onPhotoSaved,
    );

    final results = <Map<String, dynamic>>[];
    results.addAll(savedPhotos.map((p) => {'photoId': p.id}));
    int successCount = savedPhotos.length;
    int failedCount = 0;
    final failedFiles = <String>[];

    // Upload stream files individually (for web platform)
    for (final streamFile in streamFiles) {
      try {
        final uploadResult = await uploadFileStreamToBackend(
          streamFile['stream'] as Stream<List<int>>,
          streamFile['size'] as int,
          streamFile['name'] as String,
        );
        if (uploadResult != null && uploadResult['success'] == true) {
          results.add(uploadResult);
          successCount++;
        } else {
          failedFiles.add(streamFile['name'] as String);
          failedCount++;
        }
      } catch (e) {
        _log('스트림 파일 업로드 실패: ${streamFile['name']}', level: LogLevel.error, error: e);
        failedFiles.add(streamFile['name'] as String);
        failedCount++;
      }
    }

    return {
      'success': true,
      'totalFiles': imageFiles.length + streamFiles.length,
      'successCount': successCount,
      'failedCount': failedCount,
      'failedFiles': failedFiles,
      'results': results,
    };
  } else {
    _log('파일 선택 취소됨', level: LogLevel.debug);
    return {
      'success': false,
      'cancelled': true,
      'totalFiles': 0,
      'successCount': 0,
      'failedCount': 0,
      'failedFiles': [],
      'results': [],
    };
  }
}

/// Picks a folder and uploads all image files from it
Future<Map<String, dynamic>> pickFolder({
  Function(int current, int total)? onProgress,
  Function(Photo photo)? onPhotoSaved,
}) async {
  final result = await FilePicker.platform.getDirectoryPath();

  if (result != null) {
    _log('폴더 선택됨: $result');

    final directory = Directory(result);

    try {
      // Find all image files in the directory
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      final files = directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) {
        final ext = path.extension(file.path).toLowerCase();
        return imageExtensions.contains(ext);
      }).toList();

      _log('폴더에서 ${files.length}개의 이미지 파일 발견');

      // Use new uploadAndSaveFiles
      final savedPhotos = await uploadAndSaveFiles(
        files,
        onProgress: onProgress,
        onPhotoSaved: onPhotoSaved,
      );

      return {
        'success': true,
        'totalFiles': savedPhotos.length,
        'successCount': savedPhotos.length,
        'failedCount': 0,
        'failedFiles': <String>[],
        'results': savedPhotos.map((p) => {'photoId': p.id}).toList(),
      };
    } catch (e) {
      _log('폴더 처리 중 오류 발생: $e', level: LogLevel.error, error: e);
      return {
        'success': false,
        'error': e.toString(),
        'totalFiles': 0,
        'successCount': 0,
        'failedCount': 0,
        'failedFiles': [],
        'results': [],
      };
    }
  } else {
    _log('폴더 선택 취소됨', level: LogLevel.debug);
    return {
      'success': false,
      'cancelled': true,
      'totalFiles': 0,
      'successCount': 0,
      'failedCount': 0,
      'failedFiles': [],
      'results': [],
    };
  }
}

/// Picks multiple images from gallery and uploads them
Future<Map<String, dynamic>> openGallery({
  Function(int current, int total)? onProgress,
  Function(Photo photo)? onPhotoSaved,
}) async {
  final pickedFiles = await _imagePicker.pickMultiImage();

  if (pickedFiles.isNotEmpty) {
    _log('갤러리에서 ${pickedFiles.length}개의 이미지 선택됨');

    final files = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();

    // Use new uploadAndSaveFiles
    final savedPhotos = await uploadAndSaveFiles(
      files,
      onProgress: onProgress,
      onPhotoSaved: onPhotoSaved,
    );

    return {
      'success': true,
      'totalFiles': savedPhotos.length,
      'successCount': savedPhotos.length,
      'failedCount': 0,
      'failedFiles': <String>[],
      'results': savedPhotos.map((p) => {'photoId': p.id}).toList(),
    };
  } else {
    _log('갤러리 선택 취소됨', level: LogLevel.debug);
    return {
      'success': false,
      'cancelled': true,
      'totalFiles': 0,
      'successCount': 0,
      'failedCount': 0,
      'failedFiles': [],
      'results': [],
    };
  }
}

/// 파일을 로컬에 저장하고 백엔드에 비동기로 업로드
/// 1. 썸네일 생성
/// 2. 로컬에 저장 (즉시 UI에 표시 가능)
/// 3. 백엔드에 업로드 (비동기)
/// 4. 메타데이터 수신 및 업데이트 (비동기)
Future<List<Photo>> uploadAndSaveFiles(
  List<File> files, {
  Function(int current, int total)? onProgress,
  Function(Photo photo)? onPhotoSaved,
}) async {
  final savedPhotos = <Photo>[];

  _log('파일 업로드 및 저장 시작: ${files.length}개의 파일');

  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    try {
      // 1. 썸네일 생성
      _log('썸네일 생성 중: ${path.basename(file.path)}');
      final thumbnailBytes = await ThumbnailService.generateThumbnail(file);

      // 2. 메타데이터와 썸네일 로컬에 저장
      final photo = await _localRepo.savePhotoMetadata(
        fileName: path.basename(file.path),
        fileSize: await file.length(),
        thumbnailBytes: thumbnailBytes,
      );

      if (photo != null) {
        // 3. 원본 이미지도 로컬에 저장 (상세 페이지에서 즉시 볼 수 있도록)
        final originalBytes = await file.readAsBytes();
        await _localRepo.saveOriginalPhoto(photo.id, originalBytes);
        _log('원본 이미지 로컬 저장 완료: ${photo.id}');

        savedPhotos.add(photo);
        _log('로컬 저장 완료: ${photo.id}');

        // 콜백으로 즉시 UI 알림
        onPhotoSaved?.call(photo);

        // 4. 백엔드에 비동기 업로드 (UI 블로킹 없이)
        _uploadToBackendAsync(photo, file, thumbnailBytes);
      }

      onProgress?.call(i + 1, files.length);
    } catch (e) {
      _log('파일 처리 실패: ${file.path}', level: LogLevel.error, error: e);
    }
  }

  _log('로컬 저장 완료: ${savedPhotos.length}/${files.length}');

  return savedPhotos;
}

/// 백엔드로 비동기 업로드 (UI 블로킹 없음)
Future<void> _uploadToBackendAsync(Photo photo, File file, List<int>? thumbnailBytes) async {
  try {
    // 업로드 상태 변경
    await _localRepo.updateUploadStatus(photo.id, UploadStatus.uploading);

    // 원본 파일 업로드
    final uploadResult = await uploadFileToBackend(file);

    if (uploadResult != null && uploadResult['success'] == true) {
      // 썸네일 업로드
      String? thumbnailUrl;
      if (thumbnailBytes != null) {
        final thumbnailResult = await _uploadThumbnailToBackend(
          thumbnailBytes,
          photo.fileName ?? 'unknown',
        );
        // TODO: 백엔드 응답에서 썸네일 URL 추출
        // thumbnailUrl = thumbnailResult?['thumbnailUrl'];
      }

      // TODO: 백엔드 응답에서 원본 이미지 URL 추출
      // 실제 구현 시 백엔드 응답 형식에 맞게 수정 필요
      final remoteUrl = uploadResult['data'] != null
          ? '$_baseUrl/images/${photo.id}' // 임시 URL 생성
          : null;

      // 백엔드에서 받은 URL로 로컬 저장소 업데이트
      if (remoteUrl != null) {
        await _localRepo.updatePhotoFromBackend(
          photoId: photo.id,
          remoteUrl: remoteUrl,
          thumbnailUrl: thumbnailUrl,
        );
        _log('백엔드 URL 업데이트 완료: ${photo.id} -> $remoteUrl');
      }

      _log('백엔드 업로드 완료: ${photo.id}');

      // TODO: 백엔드에서 AI 메타데이터를 받아와서 업데이트
      // final metadata = await fetchMetadataFromBackend(photo.id);
      // if (metadata != null) {
      //   await _localRepo.updatePhotoMetadata(photo.id, metadata);
      // }
    } else {
      await _localRepo.updateUploadStatus(photo.id, UploadStatus.failed);
      _log('백엔드 업로드 실패: ${photo.id}', level: LogLevel.error);
    }
  } catch (e) {
    await _localRepo.updateUploadStatus(photo.id, UploadStatus.failed);
    _log('백엔드 업로드 오류: ${photo.id} - $e', level: LogLevel.error, error: e);
  }
}

/// Uploads multiple files in bulk with optional progress callback
/// Returns a summary of the upload operation
Future<Map<String, dynamic>> uploadMultipleFiles(
  List<File> files, {
  Function(int current, int total)? onProgress,
}) async {
  final uploadResults = <Map<String, dynamic>>[];
  final failedFiles = <String>[];
  int successCount = 0;

  _log('일괄 업로드 시작: ${files.length}개의 파일');

  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    try {
      final uploadResult = await uploadFileToBackend(file);

      if (uploadResult != null && uploadResult['success'] == true) {
        uploadResults.add(uploadResult);
        successCount++;
      } else {
        failedFiles.add(path.basename(file.path));
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, files.length);
    } catch (e) {
      _log('파일 업로드 실패: ${file.path}', level: LogLevel.error, error: e);
      failedFiles.add(path.basename(file.path));
    }
  }

  final summary = {
    'success': true,
    'totalFiles': files.length,
    'successCount': successCount,
    'failedCount': failedFiles.length,
    'failedFiles': failedFiles,
    'results': uploadResults,
  };

  _log('일괄 업로드 완료: $successCount/${files.length} 성공');

  return summary;
}