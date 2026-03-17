import 'package:aetherfin/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_client_adapter.dart';

void main() {
  group('JellyseerrApi', () {
    test('tests the server and stores cookies for later requests', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/api/v1/status', (_) {
        return jsonResponse(
          const <String, dynamic>{'version': '2.1.0'},
          headers: const <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            'set-cookie': <String>[
              'XSRF-TOKEN=csrf-token; Path=/',
              'connect.sid=session-1; Path=/',
            ],
          },
        );
      });
      adapter.onPost('/api/v1/auth/jellyfin', (options) {
        expect(options.headers['Cookie'], contains('XSRF-TOKEN=csrf-token'));
        expect(options.headers['Cookie'], contains('connect.sid=session-1'));
        expect(options.headers['XSRF-TOKEN'], 'csrf-token');
        return jsonResponse(
          const <String, dynamic>{
            'id': 10,
            'email': 'demo@example.com',
            'displayName': 'Demo',
          },
          headers: const <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            'set-cookie': <String>['connect.sid=session-2; Path=/'],
          },
        );
      });

      final api = JellyseerrApi(
        baseUrl: 'https://jellyseerr.local',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final status = await api.test();
      final user = await api.login(username: 'demo', password: 'secret');

      expect(status.isValid, isTrue);
      expect(status.requiresPassword, isTrue);
      expect(user.displayName, 'Demo');
      expect(api.hasSession, isTrue);
    });

    test('searches and parses results using the stored session cookies', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/api/v1/status', (_) {
        return jsonResponse(
          const <String, dynamic>{'version': '2.1.0'},
          headers: const <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            'set-cookie': <String>['connect.sid=session-1; Path=/'],
          },
        );
      });
      adapter.onGet('/api/v1/search', (options) {
        expect(options.headers['Cookie'], contains('connect.sid=session-1'));
        expect(options.queryParameters['query'], 'alien');
        expect(options.queryParameters['page'], 2);
        return jsonResponse(
          const <String, dynamic>{
            'page': 2,
            'totalPages': 3,
            'totalResults': 1,
            'results': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 11,
                'mediaType': 'movie',
                'title': 'Alien',
              },
            ],
          },
        );
      });

      final api = JellyseerrApi(
        baseUrl: 'https://jellyseerr.local',
        dio: Dio()..httpClientAdapter = adapter,
      );

      await api.test();
      final results = await api.search(query: 'alien', page: 2);

      expect(results.page, 2);
      expect(results.results.single.title, 'Alien');
    });

    test('supports request and user endpoints', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onPost('/api/v1/request', (options) {
        expect(
          options.data,
          const <String, dynamic>{'mediaType': 'movie', 'mediaId': 42},
        );
        return jsonResponse(
          const <String, dynamic>{'id': 99, 'status': 2, 'mediaType': 'movie'},
        );
      });
      adapter.onGet('/api/v1/user', (options) {
        expect(options.queryParameters['take'], 1);
        return jsonResponse(
          const <String, dynamic>{
            'page': 1,
            'totalPages': 1,
            'totalResults': 1,
            'results': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'displayName': 'Admin'},
            ],
          },
        );
      });

      final api = JellyseerrApi(
        baseUrl: 'https://jellyseerr.local',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final request = await api.request(
        JellyseerrMediaRequestBody(mediaType: 'movie', mediaId: 42),
      );
      final users = await api.user(params: const <String, dynamic>{'take': 1});

      expect(request.id, 99);
      expect(users.results.single.displayName, 'Admin');
    });
  });
}

