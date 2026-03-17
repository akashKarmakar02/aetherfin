import 'package:dio/dio.dart';

import '../transport/base_api_client.dart';

class MarlinSearchResponse {
  MarlinSearchResponse({
    this.ids = const [],
    this.raw = const {},
  });

  final List<String> ids;
  final Map<String, dynamic> raw;

  factory MarlinSearchResponse.fromJson(Map<String, dynamic> json) {
    final ids = json['ids'] is List
        ? (json['ids'] as List).map((item) => item.toString()).toList()
        : const <String>[];
    return MarlinSearchResponse(ids: ids, raw: json);
  }
}

class MarlinSearchApi {
  MarlinSearchApi({
    required String baseUrl,
    Dio? dio,
  }) : client = BaseApiClient(baseUrl: baseUrl, dio: dio);

  final BaseApiClient client;

  Future<MarlinSearchResponse> search({
    required String query,
    required List<String> includeItemTypes,
    CancelToken? cancelToken,
  }) async {
    final params = [
      'q=${Uri.encodeQueryComponent(query)}',
      for (final type in includeItemTypes)
        'includeItemTypes=${Uri.encodeQueryComponent(type)}',
    ].join('&');

    final response = await client.get<Map<String, dynamic>>(
      '/search?$params',
      cancelToken: cancelToken,
    );
    return MarlinSearchResponse.fromJson(response.data ?? {});
  }
}
