import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:front/core/network/network_policy_service.dart';
import 'package:front/features/auth/data/auth_repository.dart';

/// API 기본 설정
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api';
}

/// 로그 레벨
enum LogLevel {
  debug,
  info,
  warning,
  error;

  int get value => index * 300;
}

/// 기본 API 클래스
abstract class BaseApi {
  final String serviceName;
  final AuthRepository _authRepository = AuthRepository();

  BaseApi(this.serviceName);

  /// 인증 헤더 가져오기
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _authRepository.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 로깅
  void log(String message, {LogLevel level = LogLevel.info, Object? error}) {
    developer.log(
      message,
      time: DateTime.now(),
      name: serviceName,
      level: level.value,
      error: error,
    );
  }

  /// GET 요청
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);
      log('GET $endpoint');

      final headers = requiresAuth
          ? await getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http.get(uri, headers: headers);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      log('GET $endpoint 오류: $e', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  /// POST 요청
  Future<T> post<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Object? body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);
      log('POST $endpoint');

      final headers = customHeaders ??
          (requiresAuth
              ? await getAuthHeaders()
              : {'Content-Type': 'application/json'});

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null
            ? (body is String ? body : jsonEncode(body))
            : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      log('POST $endpoint 오류: $e', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  /// PUT 요청
  Future<T> put<T>(
    String endpoint, {
    Object? body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      log('PUT $endpoint');

      final headers = requiresAuth
          ? await getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      log('PUT $endpoint 오류: $e', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  /// DELETE 요청
  Future<T> delete<T>(
    String endpoint, {
    Object? body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      log('DELETE $endpoint');

      final headers = requiresAuth
          ? await getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http.delete(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      log('DELETE $endpoint 오류: $e', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  /// 바이트 다운로드 (이미지, 파일 등)
  Future<List<int>> getBytes(
    String url, {
    bool requiresAuth = false,
  }) async {
    try {
      await NetworkPolicyService.instance.ensureAllowedConnectivity();

      final uri = Uri.parse(url);
      log('GET (bytes) $url');

      final headers = requiresAuth ? await getAuthHeaders() : <String, String>{};

      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('바이트 다운로드 성공: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      }

      log('바이트 다운로드 실패 (status: ${response.statusCode})', level: LogLevel.error);
      throw ApiException(response.statusCode, '다운로드 실패');
    } catch (e) {
      log('GET (bytes) $url 오류: $e', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  /// 응답 처리
  T _handleResponse<T>(http.Response response, T Function(dynamic)? fromJson) {
    log('Response status: ${response.statusCode}', level: LogLevel.debug);

    // 204 No Content
    if (response.statusCode == 204) {
      return null as T;
    }

    // 성공 응답 (200-299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (fromJson != null && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        return fromJson(data);
      }
      return response.body as T;
    }

    // 에러 응답
    log('요청 실패 (status: ${response.statusCode})', level: LogLevel.error);

    String errorMessage = '요청 실패: ${response.statusCode}';
    if (response.body.isNotEmpty) {
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (_) {
        errorMessage = response.body;
      }
    }

    throw ApiException(response.statusCode, errorMessage);
  }
}

/// API 예외
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
