import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Backend server configuration
const String _baseUrl = 'https://your-backend-api.com'; // TODO: Replace with actual backend URL
const String _downloadEndpoint = '/api/v1/download';        // TODO: Replace with actual endpoint

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
}

/// Downloads a single file from the backend server and saves it to cache
/// Returns the local file path or null if download fails
Future<Map<String, dynamic>?> downloadFileToCache(String fileId, {String? fileName}) async {
  try {
    final uri = Uri.parse('$_baseUrl$_downloadEndpoint/$fileId');

    _log('Downloading file: $fileId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final downloadDir = Directory('${cacheDir.path}/downloads');

      // Create downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Generate file name
      final fileNameToUse = fileName ?? 'download_$fileId';
      final filePath = '${downloadDir.path}/$fileNameToUse';

      // Write file to cache
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _log('Download successful: $filePath', level: LogLevel.info);
      return {
        'success': true,
        'fileId': fileId,
        'filePath': filePath,
        'fileSize': response.bodyBytes.length,
        'message': 'File downloaded successfully'
      };
    } else {
      _log('Download failed (Status: ${response.statusCode}): $fileId',
          level: LogLevel.warning);
      return {
        'success': false,
        'fileId': fileId,
        'error': 'Status ${response.statusCode}',
        'message': response.body
      };
    }
  } catch (e) {
    _log('Download error: $fileId', level: LogLevel.error, error: e);
    return {
      'success': false,
      'fileId': fileId,
      'error': e.toString()
    };
  }
}

/// Downloads thumbnails for multiple files to cache
/// Returns a summary of the download operation
Future<Map<String, dynamic>> downloadThumbnailsToCache(
  List<String> fileIds, {
  Function(int current, int total)? onProgress,
}) async {
  final downloadResults = <Map<String, dynamic>>[];
  final failedFiles = <String>[];
  int successCount = 0;

  _log('Starting thumbnail download batch: ${fileIds.length} files');

  for (var i = 0; i < fileIds.length; i++) {
    final fileId = fileIds[i];
    try {
      // Download thumbnail version (you might need to adjust endpoint)
      final thumbnailResult = await downloadFileToCache(
        fileId,
        fileName: 'thumb_$fileId.jpg',
      );

      if (thumbnailResult != null && thumbnailResult['success'] == true) {
        downloadResults.add(thumbnailResult);
        successCount++;
      } else {
        failedFiles.add(fileId);
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, fileIds.length);
    } catch (e) {
      _log('Thumbnail download failed: $fileId', level: LogLevel.error, error: e);
      failedFiles.add(fileId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalFiles': fileIds.length,
    'successCount': successCount,
    'failedCount': failedFiles.length,
    'failedFiles': failedFiles,
    'results': downloadResults,
  };

  _log('Thumbnail download complete: $successCount/${fileIds.length} successful');

  return summary;
}

/// Downloads multiple files to cache directory
/// Returns a summary of the download operation
Future<Map<String, dynamic>> downloadMultipleFiles(
  List<String> fileIds, {
  Function(int current, int total)? onProgress,
}) async {
  final downloadResults = <Map<String, dynamic>>[];
  final failedFiles = <String>[];
  int successCount = 0;

  _log('Starting batch download: ${fileIds.length} files');

  for (var i = 0; i < fileIds.length; i++) {
    final fileId = fileIds[i];
    try {
      final downloadResult = await downloadFileToCache(fileId);

      if (downloadResult != null && downloadResult['success'] == true) {
        downloadResults.add(downloadResult);
        successCount++;
      } else {
        failedFiles.add(fileId);
      }

      // Call progress callback if provided
      onProgress?.call(i + 1, fileIds.length);
    } catch (e) {
      _log('File download failed: $fileId', level: LogLevel.error, error: e);
      failedFiles.add(fileId);
    }
  }

  final summary = {
    'success': successCount > 0,
    'totalFiles': fileIds.length,
    'successCount': successCount,
    'failedCount': failedFiles.length,
    'failedFiles': failedFiles,
    'results': downloadResults,
  };

  _log('Batch download complete: $successCount/${fileIds.length} successful');

  return summary;
}

/// Downloads multiple files using a batch endpoint (if supported by backend)
/// This is more efficient than individual downloads for large batches
Future<Map<String, dynamic>?> downloadBatchFiles(List<String> fileIds) async {
  try {
    final uri = Uri.parse('$_baseUrl$_downloadEndpoint/batch');

    _log('Starting batch download request: ${fileIds.length} files');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: '{"fileIds": ${fileIds.map((id) => '"$id"').toList()}}',
    );

    if (response.statusCode == 200) {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final downloadDir = Directory('${cacheDir.path}/downloads/batch');

      // Create downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Save batch zip file
      final zipPath = '${downloadDir.path}/batch_${DateTime.now().millisecondsSinceEpoch}.zip';
      final file = File(zipPath);
      await file.writeAsBytes(response.bodyBytes);

      _log('Batch download successful: $zipPath', level: LogLevel.info);
      return {
        'success': true,
        'totalFiles': fileIds.length,
        'zipPath': zipPath,
        'fileSize': response.bodyBytes.length,
        'message': 'Batch downloaded successfully',
      };
    } else {
      _log('Batch download failed (Status: ${response.statusCode})',
          level: LogLevel.warning);
      return {
        'success': false,
        'totalFiles': fileIds.length,
        'error': 'Status ${response.statusCode}',
        'message': response.body,
      };
    }
  } catch (e) {
    _log('Batch download error', level: LogLevel.error, error: e);
    return {
      'success': false,
      'totalFiles': fileIds.length,
      'error': e.toString(),
    };
  }
}

/// Clears all downloaded files from cache
Future<bool> clearDownloadCache() async {
  try {
    final cacheDir = await getTemporaryDirectory();
    final downloadDir = Directory('${cacheDir.path}/downloads');

    if (await downloadDir.exists()) {
      await downloadDir.delete(recursive: true);
      _log('Download cache cleared successfully', level: LogLevel.info);
      return true;
    }

    return true;
  } catch (e) {
    _log('Failed to clear download cache', level: LogLevel.error, error: e);
    return false;
  }
}