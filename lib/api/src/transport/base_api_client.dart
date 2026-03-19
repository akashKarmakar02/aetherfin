import 'package:dio/dio.dart';

import 'api_exception.dart';

class BaseApiClient {
  BaseApiClient({
    required String baseUrl,
    Dio? dio,
    BaseOptions? options,
    bool? enableResponseCache,
  })  : baseUrl = normalizeBaseUrl(baseUrl),
        enableResponseCache = enableResponseCache ?? dio == null,
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
  final bool enableResponseCache;

  static const Duration _cacheTtl = Duration(minutes: 1);
  static const String disableCacheExtraKey = 'disableResponseCache';
  static final Map<String, _CachedResponse> _responseCache =
      <String, _CachedResponse>{};
  static final Map<String, Future<Response<dynamic>>> _inflightGetRequests =
      <String, Future<Response<dynamic>>>{};

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
    final normalizedQueryParameters = _stripNulls(queryParameters);
    final shouldUseCache =
        enableResponseCache && options?.extra?[disableCacheExtraKey] != true;
    final cacheKey = shouldUseCache
        ? _buildCacheKey(
            path: path,
            queryParameters: normalizedQueryParameters,
            options: options,
          )
        : null;

    try {
      if (cacheKey != null) {
        final cachedResponse = _responseCache[cacheKey];
        if (cachedResponse != null && !cachedResponse.isExpired) {
          return _cloneResponse<T>(cachedResponse.response);
        }

        final inflightRequest = _inflightGetRequests[cacheKey];
        if (inflightRequest != null) {
          return _cloneResponse<T>(await inflightRequest);
        }
      }

      final request = dio.get<T>(
        resolvePath(path),
        queryParameters: normalizedQueryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (cacheKey == null) {
        return await request;
      }

      final wrappedRequest = request.then<Response<dynamic>>((response) {
        final dynamicResponse = _cloneResponse<dynamic>(response);
        _responseCache[cacheKey] = _CachedResponse(
          response: dynamicResponse,
          expiresAt: DateTime.now().add(_cacheTtl),
        );
        return dynamicResponse;
      });
      _inflightGetRequests[cacheKey] = wrappedRequest;

      try {
        return _cloneResponse<T>(await wrappedRequest);
      } finally {
        _inflightGetRequests.remove(cacheKey);
      }
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

  void clearGetCache({String? pathPrefix}) {
    final resolvedPrefix = pathPrefix == null ? null : resolvePath(pathPrefix);
    final keysToRemove = _responseCache.keys
        .where(
          (key) => _matchesCacheScope(
            key,
            pathPrefix: resolvedPrefix,
          ),
        )
        .toList(growable: false);
    for (final key in keysToRemove) {
      _responseCache.remove(key);
      _inflightGetRequests.remove(key);
    }
  }

  String _buildCacheKey({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    final resolvedPath = resolvePath(path);
    final headerValue =
        options?.headers?['Authorization']?.toString() ??
        dio.options.headers['Authorization']?.toString() ??
        '';
    final responseType =
        (options?.responseType ?? dio.options.responseType).name;
    final queryFingerprint = _canonicalizeValue(queryParameters) ?? '';

    return '$baseUrl|$resolvedPath|$queryFingerprint|$responseType|$headerValue';
  }

  bool _matchesCacheScope(String key, {String? pathPrefix}) {
    if (!key.startsWith('$baseUrl|')) {
      return false;
    }
    if (pathPrefix == null) {
      return true;
    }

    final parts = key.split('|');
    if (parts.length < 2) {
      return false;
    }
    return parts[1].startsWith(pathPrefix);
  }

  String? _canonicalizeValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '$key:${_canonicalizeValue(value[key])}').join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_canonicalizeValue).join(',')}]';
    }
    return value.toString();
  }

  Response<T> _cloneResponse<T>(Response<dynamic> response) {
    return Response<T>(
      data: response.data as T?,
      headers: response.headers,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: Map<String, dynamic>.from(response.extra),
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
    );
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

class _CachedResponse {
  const _CachedResponse({
    required this.response,
    required this.expiresAt,
  });

  final Response<dynamic> response;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
