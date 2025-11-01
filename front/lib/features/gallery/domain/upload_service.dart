import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:front/features/auth/data/auth_repository.dart';
import 'package:front/core/network/network_policy_service.dart';
import 'thumbnail_service.dart';
import '../data/repositories/local_photo_repository.dart';
import '../data/models/photo_models.dart';

final ImagePicker _imagePicker = ImagePicker();

// Backend server configuration
const String _baseUrl = 'http://localhost:8000';
const String _uploadRequestEndpoint = '/api/images/upload/request';
const String _uploadCompleteEndpoint = '/api/images/upload/complete';

// Local photo repository instance
final _localRepo = LocalPhotoRepository();
final _authRepository = AuthRepository();

Future<Map<String, String>> _getAuthHeaders() async {
  final token = await _authRepository.getAccessToken();
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

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

/// Requests presigned URLs from the backend for uploading images
/// Returns PresignedUrlResponse or throws an exception
Future<PresignedUrlResponse> requestPresignedUrls(int imageCount) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_uploadRequestEndpoint');
    _log('Presigned URL 요청: $imageCount개의 이미지');

    final response = await http.post(
      uri,
      headers: await _getAuthHeaders(),
      body: jsonEncode({'image_count': imageCount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final presignedResponse = PresignedUrlResponse.fromMap(data);
      _log('Presigned URL 수신 성공: ${presignedResponse.presignedUrls.length}개');
      return presignedResponse;
    } else if (response.statusCode == 422) {
      // Validation error
      final errorData = jsonDecode(response.body);
      final details =
          (errorData['detail'] as List<dynamic>?)
              ?.map(
                (e) => ValidationErrorDetail.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      final errorMessages = details
          .map((d) => '${d.loc.join(".")}: ${d.msg}')
          .join(', ');
      _log('Presigned URL 요청 검증 오류: $errorMessages', level: LogLevel.error);
      throw Exception('검증 오류: $errorMessages');
    } else {
      _log(
        'Presigned URL 요청 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      throw Exception('Presigned URL 요청 실패: ${response.statusCode}');
    }
  } catch (e) {
    _log('Presigned URL 요청 오류: $e', level: LogLevel.error, error: e);
    rethrow;
  }
}

/// Uploads file directly to presigned URL (e.g., S3)
/// Returns true if upload succeeds, false otherwise
Future<bool> uploadToPresignedUrl(
  File file,
  String presignedUrl, {
  String? contentType,
}) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final fileBytes = await file.readAsBytes();
    _log(
      'Presigned URL로 파일 업로드 중: ${path.basename(file.path)} (${fileBytes.length} bytes)',
    );

    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {
        'Content-Type': contentType ?? 'application/octet-stream',
        'Content-Length': fileBytes.length.toString(),
      },
      body: fileBytes,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _log('Presigned URL 업로드 성공: ${path.basename(file.path)}');
      return true;
    } else {
      _log(
        'Presigned URL 업로드 실패 (status: ${response.statusCode})',
        level: LogLevel.warning,
      );
      return false;
    }
  } catch (e) {
    _log('Presigned URL 업로드 오류: $e', level: LogLevel.error, error: e);
    return false;
  }
}

/// Uploads a single file using presigned URL flow
/// 1. Request presigned URL from backend
/// 2. Upload file to presigned URL (S3)
/// Returns map with success status and image_id
Future<Map<String, dynamic>?> uploadFileWithPresignedUrl(
  File file, {
  String? contentType,
}) async {
  try {
    // 1. Request presigned URL
    final presignedResponse = await requestPresignedUrls(1);

    if (presignedResponse.presignedUrls.isEmpty) {
      _log('Presigned URL을 받지 못했습니다', level: LogLevel.error);
      return {'success': false, 'error': 'No presigned URL received'};
    }

    final presignedData = presignedResponse.presignedUrls.first;

    // 2. Upload to presigned URL
    final uploadSuccess = await uploadToPresignedUrl(
      file,
      presignedData.presignedUrl,
      contentType: contentType,
    );

    if (uploadSuccess) {
      return {'success': true, 'imageId': presignedData.imageId};
    } else {
      return {'success': false, 'error': 'Upload to presigned URL failed'};
    }
  } catch (e) {
    _log('파일 업로드 오류: $e', level: LogLevel.error, error: e);
    return {'success': false, 'error': e.toString()};
  }
}

/// Uploads multiple files using presigned URLs in batch
/// Returns list of upload results with image_id for each file
Future<List<Map<String, dynamic>>> uploadMultipleFilesWithPresignedUrls(
  List<File> files, {
  String? contentType,
  Function(int current, int total)? onProgress,
}) async {
  final results = <Map<String, dynamic>>[];

  try {
    // 1. Request presigned URLs for all files
    final presignedResponse = await requestPresignedUrls(files.length);

    if (presignedResponse.presignedUrls.length != files.length) {
      _log('요청한 URL 개수와 받은 URL 개수가 다릅니다', level: LogLevel.warning);
    }

    // 2. Upload each file to its presigned URL
    for (
      var i = 0;
      i < files.length && i < presignedResponse.presignedUrls.length;
      i++
    ) {
      final file = files[i];
      final presignedData = presignedResponse.presignedUrls[i];

      final uploadSuccess = await uploadToPresignedUrl(
        file,
        presignedData.presignedUrl,
        contentType: contentType,
      );

      results.add({
        'fileName': path.basename(file.path),
        'success': uploadSuccess,
        'imageId': presignedData.imageId,
      });

      onProgress?.call(i + 1, files.length);
    }

    return results;
  } catch (e) {
    _log('일괄 업로드 오류: $e', level: LogLevel.error, error: e);
    return results;
  }
}

/// Notifies backend that upload is complete for a specific image
/// Returns UploadCompleteResponse or throws an exception
Future<UploadCompleteResponse> notifyUploadComplete(int imageId) async {
  try {
    await NetworkPolicyService.instance.ensureAllowedConnectivity();
    final uri = Uri.parse('$_baseUrl$_uploadCompleteEndpoint');
    _log('업로드 완료 알림: image_id=$imageId');

    final response = await http.post(
      uri,
      headers: await _getAuthHeaders(),
      body: jsonEncode({'image_id': imageId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final completeResponse = UploadCompleteResponse.fromMap(data);
      _log(
        '업로드 완료 확인: image_id=${completeResponse.imageId}, status=${completeResponse.status}',
      );
      return completeResponse;
    } else if (response.statusCode == 422) {
      // Validation error
      final errorData = jsonDecode(response.body);
      final details =
          (errorData['detail'] as List<dynamic>?)
              ?.map(
                (e) => ValidationErrorDetail.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      final errorMessages = details
          .map((d) => '${d.loc.join(".")}: ${d.msg}')
          .join(', ');
      _log('업로드 완료 알림 검증 오류: $errorMessages', level: LogLevel.error);
      throw Exception('검증 오류: $errorMessages');
    } else {
      _log(
        '업로드 완료 알림 실패 (status: ${response.statusCode})',
        level: LogLevel.error,
      );
      throw Exception('업로드 완료 알림 실패: ${response.statusCode}');
    }
  } catch (e) {
    _log('업로드 완료 알림 오류: $e', level: LogLevel.error, error: e);
    rethrow;
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

  final imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.heic',
    '.heif',
  ];

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

    // Note: Stream files (web platform) are not yet supported with presigned URL flow
    // TODO: Implement stream-based upload for web platform
    if (streamFiles.isNotEmpty) {
      _log(
        '스트림 파일 ${streamFiles.length}개는 현재 지원되지 않습니다 (웹 플랫폼)',
        level: LogLevel.warning,
      );
      for (final streamFile in streamFiles) {
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
      final imageExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.bmp',
        '.webp',
      ];
      final files = directory.listSync(recursive: true).whereType<File>().where(
        (file) {
          final ext = path.extension(file.path).toLowerCase();
          return imageExtensions.contains(ext);
        },
      ).toList();

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

    final files = pickedFiles
        .map((pickedFile) => File(pickedFile.path))
        .toList();

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
/// Uses the new presigned URL flow:
/// 1. Request presigned URL
/// 2. Upload to presigned URL
/// 3. Notify backend upload complete
///
/// Note: 썸네일은 로컬에만 저장되며 서버에 업로드되지 않습니다
Future<void> _uploadToBackendAsync(
  Photo photo,
  File file,
  List<int>? thumbnailBytes,
) async {
  try {
    // 업로드 상태 변경
    await _localRepo.updateUploadStatus(photo.id, UploadStatus.uploading);

    // 1. Request presigned URL and upload file (원본 이미지만 업로드)
    final uploadResult = await uploadFileWithPresignedUrl(file);

    if (uploadResult != null && uploadResult['success'] == true) {
      final imageId = uploadResult['imageId'] as int;

      // 2. Notify backend that upload is complete
      try {
        final completeResponse = await notifyUploadComplete(imageId);

        // 3. Update local repository with backend data
        final remoteUrl =
            '$_baseUrl/api/images/$imageId/view'; // View URL endpoint
        await _localRepo.updatePhotoFromBackend(
          photoId: photo.id,
          remoteUrl: remoteUrl,
        );

        _log(
          '백엔드 업로드 완료: ${photo.id} -> imageId=$imageId, hash=${completeResponse.hash}',
        );
        await _localRepo.updateUploadStatus(photo.id, UploadStatus.completed);
      } catch (completeError) {
        _log(
          '업로드 완료 알림 실패: ${photo.id} - $completeError',
          level: LogLevel.warning,
          error: completeError,
        );
        // Upload succeeded but notification failed - still mark as completed
        await _localRepo.updateUploadStatus(photo.id, UploadStatus.completed);
      }
    } else {
      await _localRepo.updateUploadStatus(photo.id, UploadStatus.failed);
      _log('백엔드 업로드 실패: ${photo.id}', level: LogLevel.error);
    }
  } catch (e) {
    await _localRepo.updateUploadStatus(photo.id, UploadStatus.failed);
    _log('백엔드 업로드 오류: ${photo.id} - $e', level: LogLevel.error, error: e);
  }
}
