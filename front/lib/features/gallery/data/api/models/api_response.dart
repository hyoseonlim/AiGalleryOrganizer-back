/// API 응답을 감싸는 기본 래퍼 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.statusCode,
  });

  /// 성공 응답 생성
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  /// 실패 응답 생성
  factory ApiResponse.failure({
    required String error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
    );
  }

  /// 예외로부터 실패 응답 생성
  factory ApiResponse.fromException(Object exception, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: exception.toString(),
      statusCode: statusCode,
    );
  }
}

/// API 예외 클래스
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException (status: $statusCode): $message';
    }
    return 'ApiException: $message';
  }
}
