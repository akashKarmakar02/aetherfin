import 'package:dio/dio.dart';

import '../models/jellyseerr_models.dart';
import '../transport/base_api_client.dart';

class JellyseerrApi {
  JellyseerrApi({
    required String baseUrl,
    Dio? dio,
  }) : client = BaseApiClient(baseUrl: baseUrl, dio: dio) {
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_cookies.isNotEmpty) {
            options.headers['Cookie'] = _cookies.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .join('; ');
          }
          final xsrfToken = _cookies['XSRF-TOKEN'];
          if (xsrfToken != null) {
            options.headers['XSRF-TOKEN'] = xsrfToken;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final setCookieValues = response.headers.map['set-cookie'] ?? const [];
          for (final cookie in setCookieValues) {
            final pair = cookie.split(';').first;
            final separator = pair.indexOf('=');
            if (separator > 0) {
              _cookies[pair.substring(0, separator)] = pair.substring(
                separator + 1,
              );
            }
          }
          handler.next(response);
        },
      ),
    );
  }

  static const String _apiV1 = '/api/v1';
  final BaseApiClient client;
  final Map<String, String> _cookies = <String, String>{};

  bool get hasSession => _cookies.isNotEmpty;

  Future<JellyseerrTestResult> test() async {
    final hadSession = hasSession;
    try {
      final response = await client.get<Map<String, dynamic>>('$_apiV1/status');
      final version = response.data?['version']?.toString();
      final isValid = _isVersionSupported(version);
      return JellyseerrTestResult(
        isValid: isValid,
        requiresPassword: !hadSession,
      );
    } catch (_) {
      return const JellyseerrTestResult(
        isValid: false,
        requiresPassword: false,
      );
    }
  }

  Future<JellyseerrUser> login({
    required String username,
    required String password,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      '$_apiV1/auth/jellyfin',
      data: {
        'username': username,
        'password': password,
        'email': username,
      },
    );
    return JellyseerrUser.fromJson(response.data ?? {});
  }

  Future<List<JellyseerrDiscoverSlider>> discoverSettings() async {
    final response = await client.get<List<dynamic>>(
      '$_apiV1/settings/discover',
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => JellyseerrDiscoverSlider.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<JellyseerrSearchResults> discover({
    required String endpoint,
    Map<String, dynamic>? params,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1$endpoint',
      queryParameters: params,
    );
    return JellyseerrSearchResults.fromJson(response.data ?? {});
  }

  Future<List<JellyseerrGenreSliderItem>> getGenreSliders({
    required String endpoint,
    Map<String, dynamic>? params,
  }) async {
    final response = await client.get<List<dynamic>>(
      '$_apiV1/discover/genreslider$endpoint',
      queryParameters: params,
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => JellyseerrGenreSliderItem.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<JellyseerrSearchResults> search({
    required String query,
    int page = 1,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/search',
      queryParameters: {
        'query': query,
        'page': page,
      },
    );
    return JellyseerrSearchResults.fromJson(response.data ?? {});
  }

  Future<JellyseerrMediaRequest> requestMedia(
    JellyseerrMediaRequestBody request,
  ) async {
    final response = await client.post<Map<String, dynamic>>(
      '$_apiV1/request',
      data: request.toJson(),
    );
    return JellyseerrMediaRequest.fromJson(response.data ?? {});
  }

  Future<JellyseerrMediaRequest> request(
    JellyseerrMediaRequestBody request,
  ) {
    return requestMedia(request);
  }

  Future<JellyseerrMediaRequest> getRequest(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/request/$id',
    );
    return JellyseerrMediaRequest.fromJson(response.data ?? {});
  }

  Future<JellyseerrMediaRequest> approveRequest(int requestId) async {
    final response = await client.post<Map<String, dynamic>>(
      '$_apiV1/request/$requestId/approve',
    );
    return JellyseerrMediaRequest.fromJson(response.data ?? {});
  }

  Future<JellyseerrMediaRequest> declineRequest(int requestId) async {
    final response = await client.post<Map<String, dynamic>>(
      '$_apiV1/request/$requestId/decline',
    );
    return JellyseerrMediaRequest.fromJson(response.data ?? {});
  }

  Future<JellyseerrRequestResults> requests({
    String filter = 'all',
    int take = 10,
    String sort = 'modified',
    int skip = 0,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/request',
      queryParameters: {
        'filter': filter,
        'take': take,
        'sort': sort,
        'skip': skip,
      },
    );
    return JellyseerrRequestResults.fromJson(response.data ?? {});
  }

  Future<JellyseerrMovieDetails> movieDetails(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/movie/$id',
    );
    return JellyseerrMovieDetails.fromJson(response.data ?? {});
  }

  Future<JellyseerrPersonDetails> personDetails(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/person/$id',
    );
    return JellyseerrPersonDetails.fromJson(response.data ?? {});
  }

  Future<JellyseerrCombinedCredit> personCombinedCredits(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/person/$id/combined_credits',
    );
    return JellyseerrCombinedCredit.fromJson(response.data ?? {});
  }

  Future<JellyseerrRating> movieRatings(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/movie/$id/ratings',
    );
    return JellyseerrRating.fromJson(response.data ?? {});
  }

  Future<JellyseerrTvDetails> tvDetails(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/tv/$id',
    );
    return JellyseerrTvDetails.fromJson(response.data ?? {});
  }

  Future<JellyseerrRating> tvRatings(int id) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/tv/$id/ratings',
    );
    return JellyseerrRating.fromJson(response.data ?? {});
  }

  Future<JellyseerrSeasonDetails> tvSeason(int id, int seasonId) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/tv/$id/season/$seasonId',
    );
    return JellyseerrSeasonDetails.fromJson(response.data ?? {});
  }

  Future<JellyseerrUserResults> users({
    Map<String, dynamic>? params,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/user',
      queryParameters: params,
    );
    return JellyseerrUserResults.fromJson(response.data ?? {});
  }

  Future<JellyseerrUserResults> user({
    Map<String, dynamic>? params,
  }) {
    return users(params: params);
  }

  Future<JellyseerrIssue> submitIssue({
    required int mediaId,
    required int issueType,
    required String message,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      '$_apiV1/issue',
      data: {
        'mediaId': mediaId,
        'issueType': issueType,
        'message': message,
      },
    );
    return JellyseerrIssue.fromJson(response.data ?? {});
  }

  Future<List<JellyseerrServiceServer>> service(String type) async {
    final response = await client.get<List<dynamic>>(
      '$_apiV1/service/$type',
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => JellyseerrServiceServer.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<JellyseerrServiceServerDetails> serviceDetails(
    String type,
    int id,
  ) async {
    final response = await client.get<Map<String, dynamic>>(
      '$_apiV1/service/$type/$id',
    );
    return JellyseerrServiceServerDetails.fromJson(response.data ?? {});
  }

  void clearSession() {
    _cookies.clear();
  }

  bool _isVersionSupported(String? version) {
    if (version == null || version.isEmpty) return false;
    final parts = version.split('.').map(int.tryParse).toList();
    final major = parts.isNotEmpty ? (parts[0] ?? 0) : 0;
    return major >= 2;
  }
}
