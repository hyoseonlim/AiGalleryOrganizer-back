import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/api_response.dart';

/// HTTP client for gallery API
class GalleryApiClient {
  GalleryApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  final String baseUrl;
  final Duration timeout;

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.failure(
        error: 'GET 요청 실패: $e',
      );
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.failure(
        error: 'POST 요청 실패: $e',
      );
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.failure(
        error: 'DELETE 요청 실패: $e',
      );
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.failure(
        error: 'PUT 요청 실패: $e',
      );
    }
  }

  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final data = response.body.isNotEmpty
            ? jsonDecode(response.body) as T
            : null;
        return ApiResponse.success(
          data: data as T,
          statusCode: statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          error: '응답 파싱 실패: $e',
          statusCode: statusCode,
        );
      }
    } else {
      String errorMessage = 'HTTP $statusCode';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (_) {
        // Use default error message
      }
      return ApiResponse.failure(
        error: errorMessage,
        statusCode: statusCode,
      );
    }
  }
}