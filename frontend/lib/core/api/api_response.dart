enum ApiStatus { initial, loading, success, error }

/// Strongly typed API response container carrying data and error message.
class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? errorMessage;

  const ApiResponse._({required this.status, this.data, this.errorMessage});

  factory ApiResponse.initial() =>
      const ApiResponse._(status: ApiStatus.initial);

  factory ApiResponse.loading() =>
      const ApiResponse._(status: ApiStatus.loading);

  factory ApiResponse.success(T data) =>
      ApiResponse._(status: ApiStatus.success, data: data);

  factory ApiResponse.error(String message) =>
      ApiResponse._(status: ApiStatus.error, errorMessage: message);

  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
  bool get hasError => isError;
}
