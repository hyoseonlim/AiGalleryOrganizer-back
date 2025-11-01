import '../models/api_models.dart';
import '../base_api.dart';

/// 사용자 API 서비스
class UserApiService extends BaseApi {
  UserApiService() : super('UserAPI');

  /// 사용자 생성 (회원가입)
  Future<UserResponse> createUser(UserCreate user) async {
    return post(
      '${ApiConfig.apiPrefix}/users/',
      body: user.toMap(),
      fromJson: (data) => UserResponse.fromMap(data as Map<String, dynamic>),
      requiresAuth: false,
    );
  }

  /// 현재 사용자 정보 조회
  Future<UserResponse> getCurrentUser() async {
    return get(
      '${ApiConfig.apiPrefix}/users/me',
      fromJson: (data) => UserResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 사용자 목록 조회
  Future<List<UserResponse>> getUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    return get(
      '${ApiConfig.apiPrefix}/users/',
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
      fromJson: (data) => (data as List)
          .map((item) => UserResponse.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 특정 사용자 조회
  Future<UserResponse> getUserById(int userId) async {
    return get(
      '${ApiConfig.apiPrefix}/users/$userId',
      fromJson: (data) => UserResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 사용자 정보 업데이트
  Future<UserResponse> updateUser(int userId, UserUpdate update) async {
    return put(
      '${ApiConfig.apiPrefix}/users/$userId',
      body: update.toMap(),
      fromJson: (data) => UserResponse.fromMap(data as Map<String, dynamic>),
    );
  }

  /// 사용자 삭제
  Future<void> deleteUser(int userId) async {
    return delete('${ApiConfig.apiPrefix}/users/$userId');
  }
}
