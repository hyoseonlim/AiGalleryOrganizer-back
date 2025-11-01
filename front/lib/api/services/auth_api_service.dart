import 'package:front/features/auth/data/auth_repository.dart';
import '../models/api_models.dart';
import '../base_api.dart';

/// 인증 API 서비스
class AuthApiService extends BaseApi {
  AuthApiService() : super('AuthAPI');

  final _authRepository = AuthRepository();

  /// 로그인
  Future<Token> login(String username, String password, String email) async {
    final token = await post<Token>(
      '${ApiConfig.apiPrefix}/auth/login',
      body: 'username=$username&password=$password&grant_type=password',
      customHeaders: {'Content-Type': 'application/x-www-form-urlencoded'},
      fromJson: (data) => Token.fromMap(data as Map<String, dynamic>),
      requiresAuth: false,
    );

    // 토큰 저장
    await _authRepository.saveCredentials(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      email: email,
    );
    log('토큰 저장 완료');

    return token;
  }

  /// 토큰 재발급
  Future<Token> reissueToken(String refreshToken, String email) async {
    final token = await post<Token>(
      '${ApiConfig.apiPrefix}/auth/reissue',
      body: {'refresh_token': refreshToken},
      fromJson: (data) => Token.fromMap(data as Map<String, dynamic>),
      requiresAuth: false,
    );

    // 새 토큰 저장
    await _authRepository.saveCredentials(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      email: email,
    );
    log('새 토큰 저장 완료');

    return token;
  }

  /// 로그아웃
  Future<void> logout() async {
    await _authRepository.clear();
    log('로그아웃 완료');
  }
}
