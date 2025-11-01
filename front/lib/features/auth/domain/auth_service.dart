import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/auth_repository.dart';

const String _baseUrl = 'http://localhost:8000';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client})
    : _client = client ?? http.Client(),
      _repository = AuthRepository();

  final http.Client _client;
  final AuthRepository _repository;

  Future<void> login({required String email, required String password}) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw const AuthException('인증 토큰이 올바르지 않습니다.');
      }
      await _repository.saveCredentials(
        accessToken: accessToken,
        refreshToken: refreshToken,
        email: email,
      );
      return;
    }

    throw AuthException(_extractErrorMessage(response));
  }

  Future<void> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/users/');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    throw AuthException(_extractErrorMessage(response));
  }

  Future<void> logout() async {
    await _repository.clear();
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String) {
          return detail;
        }
        if (detail is List) {
          final messages = detail
              .map((e) {
                if (e is Map<String, dynamic>) {
                  final msg = e['msg'];
                  return msg is String ? msg : null;
                }
                return null;
              })
              .whereType<String>()
              .toList();
          if (messages.isNotEmpty) {
            return messages.join(', ');
          }
        }
      }
    } catch (_) {
      // ignore decoding errors and fall back to status-based message
    }
    return '요청에 실패했습니다. (status: ${response.statusCode})';
  }
}
