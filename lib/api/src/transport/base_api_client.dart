import 'package:dio/dio.dart';

import 'api_exception.dart';

class BaseApiClient {
  BaseApiClient({
    required String baseUrl,
    Dio? dio,
    BaseOptions? options,
  })  : baseUrl = normalizeBaseUrl(baseUrl),
        dio = dio ??
            Dio(
              options ??
                  BaseOptions(
                    baseUrl: normalizeBaseUrl(baseUrl),
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 30),
                    responseType: ResponseType.json,
                  ),
            ) {
    this.dio.options.baseUrl = this.baseUrl;
  }

  final String baseUrl;
  final Dio dio;

  static String normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String resolvePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return path;
    }
    return '/$path';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        resolvePath(path),
        queryParameters: _stripNulls(queryParameters),
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        resolvePath(path),
        data: data,
        queryParameters: _stripNulls(queryParameters),
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.patch<T>(
        resolvePath(path),
        data: data,
        queryParameters: _stripNulls(queryParameters),
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete<T>(
        resolvePath(path),
        data: data,
        queryParameters: _stripNulls(queryParameters),
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Map<String, dynamic>? _stripNulls(Map<String, dynamic>? values) {
    if (values == null) return null;
    final next = <String, dynamic>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        next[entry.key] = entry.value;
      }
    }
    return next;
  }
}
