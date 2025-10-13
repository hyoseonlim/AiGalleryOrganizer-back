import 'dart:io';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

final ImagePicker _imagePicker = ImagePicker();

// Backend server configuration
const String _baseUrl = 'https://your-backend-api.com'; // TODO: Replace with actual backend URL
const String _uploadEndpoint = '/api/v1/upload';        // TODO: Replace with actual endpoint

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  final levelStr = level.toString().split('.').last.toUpperCase();
  final timestamp = DateTime.now().toIso8601String();

  developer.log(
    message,
    time: DateTime.now(),
    name: 'GalleryDomain',
    level: level.index * 300,
    error: error,
  );

  // Optional: You can also add file logging or remote logging here
  // Example: logToFile('[$timestamp][$levelStr] $message');
}

/// Uploads a file to the backend server using stream
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

    _log('Uploading file: $fileNameToUse ($length bytes)');

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

    // Upload files with paths using uploadMultipleFiles
    final summary = await uploadMultipleFiles(imageFiles, onProgress: onProgress);

    // Upload stream files individually (for web platform)
    for (final streamFile in streamFiles) {
      try {
        final uploadResult = await uploadFileStreamToBackend(
          streamFile['stream'] as Stream<List<int>>,
          streamFile['size'] as int,
          streamFile['name'] as String,
        );
        if (uploadResult != null && uploadResult['success'] == true) {
          summary['results'].add(uploadResult);
          summary['successCount']++;
        } else {
          summary['failedFiles'].add(streamFile['name']);
          summary['failedCount']++;
        }
      } catch (e) {
        _log('스트림 파일 업로드 실패: ${streamFile['name']}', level: LogLevel.error, error: e);
        summary['failedFiles'].add(streamFile['name']);
        summary['failedCount']++;
      }
    }

    summary['totalFiles'] = imageFiles.length + streamFiles.length;
    return summary;
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

      // Use uploadMultipleFiles for batch upload with progress tracking
      final summary = await uploadMultipleFiles(files, onProgress: onProgress);
      return summary;
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
}) async {
  final pickedFiles = await _imagePicker.pickMultiImage();

  if (pickedFiles.isNotEmpty) {
    _log('갤러리에서 ${pickedFiles.length}개의 이미지 선택됨');

    final files = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();

    // Use uploadMultipleFiles for batch upload with progress tracking
    final summary = await uploadMultipleFiles(files, onProgress: onProgress);
    return summary;
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