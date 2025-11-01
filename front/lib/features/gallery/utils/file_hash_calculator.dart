import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;

// Logging configuration
enum LogLevel { debug, info, warning, error }

void _log(String message, {LogLevel level = LogLevel.info, Object? error}) {
  developer.log(
    message,
    time: DateTime.now(),
    name: 'FileHashCalculator',
    level: level.index * 300,
    error: error,
  );
}

/// 파일의 SHA-256 해시값 계산
/// 파일 내용을 읽어 SHA-256 해시를 생성하여 16진수 문자열로 반환
Future<String?> calculateFileHash(File file) async {
  try {
    _log('해시 계산 시작: ${file.path}', level: LogLevel.debug);

    // 파일을 읽어 해시 계산
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes);
    final hashString = hash.toString();

    _log('해시 계산 완료: $hashString', level: LogLevel.debug);

    return hashString;
  } catch (e) {
    _log('해시 계산 중 오류 발생: ${file.path}', level: LogLevel.error, error: e);
    return null;
  }
}

/// 여러 파일의 해시값을 한번에 계산
/// 파일 경로를 키로, 해시값을 값으로 하는 Map 반환
Future<Map<String, String>> calculateMultipleFileHashes(
  List<File> files, {
  Function(int current, int total)? onProgress,
}) async {
  final hashes = <String, String>{};

  _log('여러 파일 해시 계산 시작: ${files.length}개', level: LogLevel.debug);

  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    final hash = await calculateFileHash(file);

    if (hash != null) {
      hashes[file.path] = hash;
    }

    onProgress?.call(i + 1, files.length);
  }

  _log('여러 파일 해시 계산 완료: ${hashes.length}/${files.length}', level: LogLevel.debug);

  return hashes;
}

/// 바이트 배열의 SHA-256 해시값 계산
/// 메모리에 이미 로드된 데이터의 해시를 계산할 때 사용
String calculateBytesHash(List<int> bytes) {
  final hash = sha256.convert(bytes);
  return hash.toString();
}

/// MD5 해시값 계산 (호환성을 위해 제공)
/// 일부 백엔드 시스템에서 MD5를 사용할 경우를 대비
Future<String?> calculateFileHashMD5(File file) async {
  try {
    _log('MD5 해시 계산 시작: ${file.path}', level: LogLevel.debug);

    final bytes = await file.readAsBytes();
    final hash = md5.convert(bytes);
    final hashString = hash.toString();

    _log('MD5 해시 계산 완료: $hashString', level: LogLevel.debug);

    return hashString;
  } catch (e) {
    _log('MD5 해시 계산 중 오류 발생: ${file.path}', level: LogLevel.error, error: e);
    return null;
  }
}
