/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  final int? statusCode;

  const ApiResponse({
    this.data,
    this.error,
    required this.success,
    this.statusCode,
  });

  /// Success response
  factory ApiResponse.success({
    required T data,
    int? statusCode,
  }) {
    return ApiResponse(
      data: data,
      success: true,
      statusCode: statusCode,
    );
  }

  /// Error/Failure response
  factory ApiResponse.failure({
    required String error,
    int? statusCode,
  }) {
    return ApiResponse(
      error: error,
      success: false,
      statusCode: statusCode,
    );
  }

  /// Error response (alias for failure)
  factory ApiResponse.error(String error) {
    return ApiResponse.failure(error: error);
  }

  /// Check if response has data
  bool get hasData => data != null;

  @override
  String toString() => 'ApiResponse(success: $success, statusCode: $statusCode, error: $error, hasData: $hasData)';
}