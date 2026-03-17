import 'package:dio/dio.dart';

enum ApiErrorType { network, timeout, cancelled, response, unknown }

class ApiException implements Exception {
  ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.path,
    this.data,
  });

  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final String? path;
  final Object? data;

  factory ApiException.fromDioException(DioException error) {
    final path = error.requestOptions.path;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: error.message ?? 'Request timed out',
          type: ApiErrorType.timeout,
          path: path,
          data: error.response?.data,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: error.message ?? 'Request cancelled',
          type: ApiErrorType.cancelled,
          path: path,
          data: error.response?.data,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: error.message ?? 'Unexpected response',
          type: ApiErrorType.response,
          path: path,
          data: error.response?.data,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: error.message ?? 'Network error',
          type: ApiErrorType.network,
          path: path,
          data: error.response?.data,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? 'Unknown error',
          type: ApiErrorType.unknown,
          path: path,
          data: error.response?.data,
          statusCode: error.response?.statusCode,
        );
    }
  }

  @override
  String toString() {
    return 'ApiException(type: $type, statusCode: $statusCode, path: $path, message: $message)';
  }
}
