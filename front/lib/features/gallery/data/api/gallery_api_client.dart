import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import 'package:front/core/network/network_policy_service.dart';
import 'package:front/features/auth/data/auth_repository.dart';

import 'models/api_response.dart';

// Logging levels
enum _LogLevel { debug, info, warning, error }

/// Gallery feature용 중앙 API 클라이언트
/// 인증, 로깅, 에러 처리를 통합 관리
class GalleryApiClient {
  final String baseUrl;
  final http.Client? httpClient;

  GalleryApiClient({this.baseUrl = 'http://localhost:8000', this.httpClient});

  http.Client get _client => httpClient ?? http.Client();

  /// 로그 출력
  void _log(String message, {_LogLevel level = _LogLevel.info, Object? error}) {
    developer.log(
      message,
      time: DateTime.now(),
      name: 'GalleryAPI',
      level: level.index * 300,
      error: error,
    );
  }

  /// 인증 토큰 가져오기
  String? _getAuthToken() {
    return AuthRepository().cachedAccessToken;
  }

  /// 공통 헤더 생성 (인증 포함)
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final token = _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
  }

  /// GET 요청
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      _log('GET 요청: $uri', level: _LogLevel.debug);

      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final response = await _client.get(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
      );

      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      _log('GET 요청 오류: $endpoint', level: _LogLevel.error, error: e);
      return ApiResponse.fromException(e);
    }
  }

  /// POST 요청
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      _log('POST 요청: $uri', level: _LogLevel.debug);

      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final response = await _client.post(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      _log('POST 요청 오류: $endpoint', level: _LogLevel.error, error: e);
      return ApiResponse.fromException(e);
    }
  }

  /// PUT 요청 (JSON)
  Future<ApiResponse<T>> putJson<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      _log('PUT 요청: $uri', level: _LogLevel.debug);

      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final response = await _client.put(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      _log('PUT 요청 오류: $endpoint', level: _LogLevel.error, error: e);
      return ApiResponse.fromException(e);
    }
  }

  /// PUT 요청 (파일 업로드용)
  Future<ApiResponse<void>> putBytes(
    String url, {
    required List<int> bytes,
    Map<String, String>? headers,
  }) async {
    try {
      _log('PUT 요청 (bytes): $url', level: _LogLevel.debug);

      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('PUT 요청 성공', level: _LogLevel.debug);
        return ApiResponse.success(data: null, statusCode: response.statusCode);
      } else {
        _log(
          'PUT 요청 실패 (status: ${response.statusCode})',
          level: _LogLevel.warning,
        );
        return ApiResponse.failure(
          error: 'Upload failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _log('PUT 요청 오류: $url', level: _LogLevel.error, error: e);
      return ApiResponse.fromException(e);
    }
  }

  /// DELETE 요청
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      _log('DELETE 요청: $uri', level: _LogLevel.debug);

      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final response = await _client.delete(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
      );

      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      _log('DELETE 요청 오류: $endpoint', level: _LogLevel.error, error: e);
      return ApiResponse.fromException(e);
    }
  }

  /// GET 요청 (바이트 응답용 - 이미지 다운로드)
  Future<ApiResponse<List<int>>> getBytes(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      _log('GET 요청 (bytes): $url', level: _LogLevel.debug);

      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final response = await _client.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        _log(
          'GET 요청 성공 (bytes: ${response.bodyBytes.length})',
          level: _LogLevel.debug,
        );
        return ApiResponse.success(
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      } else {
        _log(
          'GET 요청 실패 (status: ${response.statusCode})',
          level: _LogLevel.warning,
        );
        return ApiResponse.failure(
          error: 'Download failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _log('GET 요청 오류: $url', level: _LogLevel.error, error: e);
      return ApiResponse.fromException(e);
    }
  }

  /// URI 생성
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }
    return uri;
  }

  /// HTTP 응답 처리
  ApiResponse<T> _handleResponse<T>(
    http.Response response, {
    T Function(Map<String, dynamic>)? parser,
  }) {
    final statusCode = response.statusCode;

    // 204 No Content
    if (statusCode == 204) {
      _log('응답 성공 (204 No Content)', level: _LogLevel.debug);
      // For void types (T = void), we need to handle null carefully
      // ignore: unnecessary_cast
      return ApiResponse.success(data: null as T, statusCode: statusCode);
    }

    // 200-299 성공
    if (statusCode >= 200 && statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          // ignore: unnecessary_cast
          return ApiResponse.success(data: null as T, statusCode: statusCode);
        }

        final jsonData = jsonDecode(response.body);

        // parser가 제공된 경우 파싱
        if (parser != null && jsonData is Map<String, dynamic>) {
          final data = parser(jsonData);
          return ApiResponse.success(data: data, statusCode: statusCode);
        }

        // parser가 없으면 원본 데이터 반환
        return ApiResponse.success(data: jsonData as T, statusCode: statusCode);
      } catch (e) {
        _log('JSON 파싱 오류', level: _LogLevel.error, error: e);
        return ApiResponse.fromException(e, statusCode: statusCode);
      }
    }

    // 422 Validation Error
    if (statusCode == 422) {
      try {
        final errorData = jsonDecode(response.body);
        final details = (errorData['detail'] as List<dynamic>?)
            ?.map((e) => '${e['loc']?.join('.')}: ${e['msg']}')
            .join(', ');
        _log('검증 오류 (422): $details', level: _LogLevel.warning);
        return ApiResponse.failure(
          error: '검증 오류: $details',
          statusCode: statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(error: '검증 오류', statusCode: statusCode);
      }
    }

    // 404 Not Found
    if (statusCode == 404) {
      _log('리소스를 찾을 수 없음 (404)', level: _LogLevel.warning);
      return ApiResponse.failure(
        error: '리소스를 찾을 수 없습니다',
        statusCode: statusCode,
      );
    }

    // 기타 오류
    _log('HTTP 오류 (status: $statusCode)', level: _LogLevel.warning);
    return ApiResponse.failure(
      error: 'HTTP 오류: $statusCode',
      message: response.body,
      statusCode: statusCode,
    );
  }

  /// 클라이언트 종료
  void dispose() {
    if (httpClient == null) {
      _client.close();
    }
  }
}
