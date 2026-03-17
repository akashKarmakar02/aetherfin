import 'package:aetherfin/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_client_adapter.dart';

void main() {
  group('BaseApiClient', () {
    test('normalizes trailing slashes', () {
      final adapter = FakeHttpClientAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final client = BaseApiClient(
        baseUrl: 'https://example.com/',
        dio: dio,
      );

      expect(client.baseUrl, 'https://example.com');
      expect(client.dio.options.baseUrl, 'https://example.com');
      expect(client.resolvePath('items'), '/items');
      expect(client.resolvePath('/items'), '/items');
    });

    test('maps bad responses to ApiException', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/boom', (options) {
        throw DioException(
          requestOptions: options,
          response: Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 500,
            data: const <String, dynamic>{'error': 'boom'},
          ),
          type: DioExceptionType.badResponse,
          message: 'server exploded',
        );
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = BaseApiClient(baseUrl: 'https://example.com', dio: dio);

      await expectLater(
        () => client.get<Map<String, dynamic>>('/boom'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.type, 'type', ApiErrorType.response)
              .having((error) => error.statusCode, 'statusCode', 500)
              .having((error) => error.path, 'path', '/boom'),
        ),
      );
    });

    test('maps cancelled requests to ApiException', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/cancelled', (options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'cancelled',
        );
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = BaseApiClient(baseUrl: 'https://example.com', dio: dio);

      await expectLater(
        () => client.get<Map<String, dynamic>>('/cancelled'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.cancelled,
          ),
        ),
      );
    });
  });
}

