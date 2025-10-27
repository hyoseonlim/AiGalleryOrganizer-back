import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:image/image.dart' as img;

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'ThumbnailService',
    level: level.index * 300,
    error: error,
  );
}

/// 썸네일 생성 설정
class ThumbnailConfig {
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const ThumbnailConfig({
    this.maxWidth = 300,
    this.maxHeight = 300,
    this.quality = 85,
  });

  static const ThumbnailConfig standard = ThumbnailConfig();
  static const ThumbnailConfig highQuality = ThumbnailConfig(
    maxWidth: 500,
    maxHeight: 500,
    quality: 90,
  );
  static const ThumbnailConfig lowQuality = ThumbnailConfig(
    maxWidth: 200,
    maxHeight: 200,
    quality: 70,
  );
}

/// 썸네일 생성 서비스
class ThumbnailService {
  /// 이미지 파일로부터 썸네일을 생성합니다.
  ///
  /// [file] - 원본 이미지 파일
  /// [config] - 썸네일 설정 (기본값: ThumbnailConfig.standard)
  ///
  /// Returns: 썸네일 이미지의 바이트 데이터, 실패 시 null
  static Future<Uint8List?> generateThumbnail(
    File file, {
    ThumbnailConfig config = ThumbnailConfig.standard,
  }) async {
    try {
      _log('썸네일 생성 시작: ${file.path}');

      // 파일 읽기
      final imageBytes = await file.readAsBytes();

      // 이미지 디코딩
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        _log('이미지 디코딩 실패: ${file.path}', level: LogLevel.error);
        return null;
      }

      _log('원본 이미지 크기: ${image.width}x${image.height}');

      // 썸네일 생성 (비율 유지하며 리사이즈)
      final thumbnail = img.copyResize(
        image,
        width: config.maxWidth,
        height: config.maxHeight,
        maintainAspect: true,
      );

      _log('썸네일 크기: ${thumbnail.width}x${thumbnail.height}');

      // JPEG로 인코딩
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: config.quality);

      final originalSize = imageBytes.length;
      final thumbnailSize = thumbnailBytes.length;
      final compressionRatio = ((1 - (thumbnailSize / originalSize)) * 100).toStringAsFixed(1);

      _log('썸네일 생성 완료: ${file.path} (크기 감소: $compressionRatio%)');

      return Uint8List.fromList(thumbnailBytes);
    } catch (e) {
      _log('썸네일 생성 오류: ${file.path} - $e', level: LogLevel.error, error: e);
      return null;
    }
  }

  /// 이미지 바이트 데이터로부터 썸네일을 생성합니다.
  ///
  /// [imageBytes] - 원본 이미지 바이트 데이터
  /// [config] - 썸네일 설정 (기본값: ThumbnailConfig.standard)
  ///
  /// Returns: 썸네일 이미지의 바이트 데이터, 실패 시 null
  static Future<Uint8List?> generateThumbnailFromBytes(
    Uint8List imageBytes, {
    ThumbnailConfig config = ThumbnailConfig.standard,
  }) async {
    try {
      _log('바이트 데이터로부터 썸네일 생성 시작');

      // 이미지 디코딩
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        _log('이미지 디코딩 실패', level: LogLevel.error);
        return null;
      }

      _log('원본 이미지 크기: ${image.width}x${image.height}');

      // 썸네일 생성 (비율 유지하며 리사이즈)
      final thumbnail = img.copyResize(
        image,
        width: config.maxWidth,
        height: config.maxHeight,
        maintainAspect: true,
      );

      _log('썸네일 크기: ${thumbnail.width}x${thumbnail.height}');

      // JPEG로 인코딩
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: config.quality);

      final originalSize = imageBytes.length;
      final thumbnailSize = thumbnailBytes.length;
      final compressionRatio = ((1 - (thumbnailSize / originalSize)) * 100).toStringAsFixed(1);

      _log('썸네일 생성 완료 (크기 감소: $compressionRatio%)');

      return Uint8List.fromList(thumbnailBytes);
    } catch (e) {
      _log('썸네일 생성 오류: $e', level: LogLevel.error, error: e);
      return null;
    }
  }

  /// 여러 이미지 파일의 썸네일을 일괄 생성합니다.
  ///
  /// [files] - 원본 이미지 파일 목록
  /// [config] - 썸네일 설정 (기본값: ThumbnailConfig.standard)
  /// [onProgress] - 진행률 콜백 (current, total)
  ///
  /// Returns: 파일 경로를 키로, 썸네일 바이트를 값으로 하는 맵
  static Future<Map<String, Uint8List>> generateThumbnails(
    List<File> files, {
    ThumbnailConfig config = ThumbnailConfig.standard,
    Function(int current, int total)? onProgress,
  }) async {
    final thumbnails = <String, Uint8List>{};

    _log('일괄 썸네일 생성 시작: ${files.length}개의 파일');

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final thumbnail = await generateThumbnail(file, config: config);

      if (thumbnail != null) {
        thumbnails[file.path] = thumbnail;
      }

      onProgress?.call(i + 1, files.length);
    }

    _log('일괄 썸네일 생성 완료: ${thumbnails.length}/${files.length} 성공');

    return thumbnails;
  }

  /// 이미지가 썸네일 생성을 지원하는 형식인지 확인합니다.
  ///
  /// [filePath] - 파일 경로
  ///
  /// Returns: 지원 여부
  static bool isSupportedImageFormat(String filePath) {
    final supportedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff',
      '.tga',
      '.pvr',
      '.ico',
    ];

    final extension = filePath.toLowerCase().split('.').last;
    return supportedExtensions.contains('.$extension');
  }
}
