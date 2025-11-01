import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:developer' as developer;

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'MetadataExtractor',
    level: level.index * 300,
    error: error,
  );
}

/// 이미지 파일에서 추출한 메타데이터
class ImageMetadata {
  final int width;
  final int height;
  final int fileSize;
  final DateTime? dateTaken;
  final String? mimeType;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? exifData;

  ImageMetadata({
    required this.width,
    required this.height,
    required this.fileSize,
    this.dateTaken,
    this.mimeType,
    this.latitude,
    this.longitude,
    this.exifData,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'file_size': fileSize,
      if (dateTaken != null) 'date_taken': dateTaken!.toIso8601String(),
      if (mimeType != null) 'mime_type': mimeType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (exifData != null) 'exif_data': exifData,
    };
  }

  @override
  String toString() {
    return 'ImageMetadata(${width}x$height, ${fileSize}B, taken: $dateTaken)';
  }
}

/// 이미지 파일에서 메타데이터 추출
Future<ImageMetadata?> extractImageMetadata(File file) async {
  try {
    _log('메타데이터 추출 시작: ${file.path}', level: LogLevel.debug);

    // 파일 크기
    final fileSize = await file.length();

    // 이미지 디코딩
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      _log('이미지 디코딩 실패: ${file.path}', level: LogLevel.error);
      return null;
    }

    // 기본 정보
    final width = image.width;
    final height = image.height;

    // MIME 타입 추출
    String? mimeType;
    if (file.path.toLowerCase().endsWith('.jpg') ||
        file.path.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (file.path.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else if (file.path.toLowerCase().endsWith('.gif')) {
      mimeType = 'image/gif';
    } else if (file.path.toLowerCase().endsWith('.webp')) {
      mimeType = 'image/webp';
    } else if (file.path.toLowerCase().endsWith('.bmp')) {
      mimeType = 'image/bmp';
    } else if (file.path.toLowerCase().endsWith('.heic') ||
               file.path.toLowerCase().endsWith('.heif')) {
      mimeType = 'image/heic';
    }

    // EXIF 데이터 추출
    DateTime? dateTaken;
    double? latitude;
    double? longitude;
    Map<String, dynamic>? exifData;

    // EXIF 데이터가 있는지 확인
    try {
      // 촬영 날짜 추출
      final dateTimeOriginal = image.exif.exifIfd['DateTimeOriginal'];
      if (dateTimeOriginal != null) {
        exifData ??= <String, dynamic>{};
        final dateTimeStr = dateTimeOriginal.toString();
        dateTaken = _parseExifDateTime(dateTimeStr);
        exifData['DateTimeOriginal'] = dateTimeStr;
      }
    } catch (e) {
      _log('촬영 날짜 파싱 오류', level: LogLevel.debug, error: e);
    }

    // GPS 좌표 추출
    try {
      final gpsLat = image.exif.gpsIfd['GPSLatitude'];
      final gpsLon = image.exif.gpsIfd['GPSLongitude'];
      final gpsLatRef = image.exif.gpsIfd['GPSLatitudeRef'];
      final gpsLonRef = image.exif.gpsIfd['GPSLongitudeRef'];

      if (gpsLat != null && gpsLon != null) {
        exifData ??= <String, dynamic>{};
        final latStr = gpsLat.toString();
        final lonStr = gpsLon.toString();
        final latRef = gpsLatRef?.toString() ?? 'N';
        final lonRef = gpsLonRef?.toString() ?? 'E';

        latitude = _parseGpsCoordinate(latStr, latRef);
        longitude = _parseGpsCoordinate(lonStr, lonRef);

        exifData['GPSLatitude'] = latStr;
        exifData['GPSLongitude'] = lonStr;
      }
    } catch (e) {
      _log('GPS 좌표 파싱 오류', level: LogLevel.debug, error: e);
    }

    // 추가 EXIF 정보
    try {
      final make = image.exif.imageIfd['Make'];
      final model = image.exif.imageIfd['Model'];
      final orientation = image.exif.imageIfd['Orientation'];

      if (make != null) {
        exifData ??= <String, dynamic>{};
        exifData['Make'] = make.toString();
      }
      if (model != null) {
        exifData ??= <String, dynamic>{};
        exifData['Model'] = model.toString();
      }
      if (orientation != null) {
        exifData ??= <String, dynamic>{};
        exifData['Orientation'] = orientation.toString();
      }
    } catch (e) {
      _log('추가 EXIF 데이터 파싱 오류', level: LogLevel.debug, error: e);
    }

    // 촬영 날짜가 없으면 파일 수정 시간 사용
    dateTaken ??= await file.lastModified();

    final metadata = ImageMetadata(
      width: width,
      height: height,
      fileSize: fileSize,
      dateTaken: dateTaken,
      mimeType: mimeType,
      latitude: latitude,
      longitude: longitude,
      exifData: exifData,
    );

    _log('메타데이터 추출 완료: $metadata', level: LogLevel.debug);

    return metadata;
  } catch (e) {
    _log('메타데이터 추출 중 오류 발생: ${file.path}', level: LogLevel.error, error: e);
    return null;
  }
}

/// EXIF DateTime 문자열 파싱 (형식: "YYYY:MM:DD HH:MM:SS")
DateTime? _parseExifDateTime(String dateTimeStr) {
  try {
    // EXIF 형식: "2024:01:15 14:30:45"
    final parts = dateTimeStr.split(' ');
    if (parts.length != 2) return null;

    final dateParts = parts[0].split(':');
    final timeParts = parts[1].split(':');

    if (dateParts.length != 3 || timeParts.length != 3) return null;

    return DateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
      int.parse(timeParts[2]), // second
    );
  } catch (e) {
    _log('EXIF DateTime 파싱 실패: $dateTimeStr', level: LogLevel.debug, error: e);
    return null;
  }
}

/// GPS 좌표 파싱
/// 형식: "41, 53, 23.45" (degrees, minutes, seconds)
double? _parseGpsCoordinate(String coordinate, String ref) {
  try {
    final parts = coordinate.split(',').map((s) => s.trim()).toList();
    if (parts.isEmpty) return null;

    // Degrees, minutes, seconds 형식인 경우
    if (parts.length == 3) {
      final degrees = double.parse(parts[0]);
      final minutes = double.parse(parts[1]);
      final seconds = double.parse(parts[2]);

      var result = degrees + (minutes / 60.0) + (seconds / 3600.0);

      // 남반구(S) 또는 서경(W)인 경우 음수로 변환
      if (ref == 'S' || ref == 'W') {
        result = -result;
      }

      return result;
    }

    // 단일 숫자인 경우
    if (parts.length == 1) {
      var result = double.parse(parts[0]);
      if (ref == 'S' || ref == 'W') {
        result = -result;
      }
      return result;
    }

    return null;
  } catch (e) {
    _log('GPS 좌표 파싱 실패: $coordinate', level: LogLevel.debug, error: e);
    return null;
  }
}