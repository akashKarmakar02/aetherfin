import 'package:aetherfin/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_client_adapter.dart';

void main() {
  group('MarlinSearchApi', () {
    test('builds repeated includeItemTypes query parameters', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onRequest(
        (options) => options.method == 'GET' && options.uri.path == '/search',
        (options) {
          expect(options.uri.queryParameters['q'], 'star wars');
          expect(
            options.uri.queryParametersAll['includeItemTypes'],
            <String>['Movie', 'Series'],
          );
          return jsonResponse(
            const <String, dynamic>{'ids': <String>['item-1', 'item-2']},
          );
        },
      );

      final api = MarlinSearchApi(
        baseUrl: 'https://marlin.local',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final results = await api.search(
        query: 'star wars',
        includeItemTypes: const <String>['Movie', 'Series'],
      );

      expect(results.ids, <String>['item-1', 'item-2']);
    });
  });
}
