import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

// Backend server configuration
const String _baseUrl = 'https://your-backend-api.com'; // TODO: Replace with actual backend URL
const String _deleteEndpoint = '/api/images/';        // TODO: Replace with actual endpoint

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

/// Deletes a single file from the backend server
/// Returns the server response or null if delete fails
Future<Map<String, dynamic>?> deleteFileFromBackend(String fileId) async {
  try {
    final uri = Uri.parse('$_baseUrl$_deleteEndpoint/$fileId');

    _log('파일 삭제 요청: $fileId');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _log('파일 삭제 성공: $fileId', level: LogLevel.info);
      return {
        'success': true,
        'fileId': fileId,
        'message': 'File deleted successfully'
      };
    } else {
      _log('파일 삭제 실패 (상태 코드: ${response.statusCode}): $fileId',
          level: LogLevel.warning);
      return {
        'success': false,
        'fileId': fileId,
        'error': 'Status ${response.statusCode}',
        'message': response.body
      };
    }
  } catch (e) {
    _log('파일 삭제 오류: $fileId', level: LogLevel.error, error: e);
    return {
      'success': false,
      'fileId': fileId,
      'error': e.toString()
    };
  }
}

/// Deletes multiple files from the backend server
/// Returns a summary of the delete operation
Future<Map<String, dynamic>> deleteMultipleFiles(
  List<String> fileIds, {
  Function(int current, int total)? onProgress,
}) async {
  final deleteResults = <Map<String, dynamic>>[];
  final failedFiles = <String>[];
  int successCount = 0;

  _log('일괄 삭제 시작: ${fileIds.length}개의 파일');

  for (var i = 0; i < fileIds.length; i++) {
    final fileId = fileIds[i];
    try {
      final deleteResult = await deleteFileFromBackend(fileId);

      if (deleteResult != null && deleteResult['success'] == true) {
        deleteResults.add(deleteResult);
        successCount++;
      } else {
        failedFiles.add(fileId);
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, fileIds.length);
    } catch (e) {
      _log('파일 삭제 실패: $fileId', level: LogLevel.error, error: e);
      failedFiles.add(fileId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalFiles': fileIds.length,
    'successCount': successCount,
    'failedCount': failedFiles.length,
    'failedFiles': failedFiles,
    'results': deleteResults,
  };

  _log('일괄 삭제 완료: $successCount/${fileIds.length} 성공');

  return summary;
}

/// Deletes multiple files using a batch endpoint (if supported by backend)
/// This is more efficient than individual deletes for large batches
Future<Map<String, dynamic>?> deleteBatchFiles(List<String> fileIds) async {
  try {
    final uri = Uri.parse('$_baseUrl$_deleteEndpoint/batch');

    _log('배치 삭제 시작: ${fileIds.length}개의 파일');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode({
        'fileIds': fileIds,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      final responseData = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      _log('배치 삭제 성공: ${fileIds.length}개의 파일', level: LogLevel.info);
      return {
        'success': true,
        'totalFiles': fileIds.length,
        'successCount': fileIds.length,
        'failedCount': 0,
        'failedFiles': [],
        'data': responseData,
      };
    } else {
      _log('배치 삭제 실패 (상태 코드: ${response.statusCode})',
          level: LogLevel.warning);
      return {
        'success': false,
        'totalFiles': fileIds.length,
        'successCount': 0,
        'failedCount': fileIds.length,
        'failedFiles': fileIds,
        'error': 'Status ${response.statusCode}',
        'message': response.body,
      };
    }
  } catch (e) {
    _log('배치 삭제 오류', level: LogLevel.error, error: e);
    return {
      'success': false,
      'totalFiles': fileIds.length,
      'successCount': 0,
      'failedCount': fileIds.length,
      'failedFiles': fileIds,
      'error': e.toString(),
    };
  }
}