import 'package:aetherfin/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_client_adapter.dart';

const jellyfinClientInfo = JellyfinClientInfo(
  clientName: 'Aetherfin',
  deviceName: 'Linux',
  deviceId: 'dev-1',
  version: '1.0.0',
);

void main() {
  group('JellyfinAuthApi', () {
    test('authenticates by username and password with Jellyfin headers', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onPost('/Users/AuthenticateByName', (options) {
        expect(
          options.headers['Authorization'],
          'MediaBrowser Client="Aetherfin", Device="Linux", DeviceId="dev-1", Version="1.0.0"',
        );
        expect(
          options.data,
          const <String, dynamic>{'Username': 'demo', 'Pw': 'secret'},
        );
        return jsonResponse(
          const <String, dynamic>{
            'AccessToken': 'token-1',
            'User': <String, dynamic>{'Id': 'user-1', 'Name': 'Demo'},
            'SessionInfo': <String, dynamic>{'Id': 'session-1'},
          },
        );
      });

      final api = JellyfinAuthApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        dio: Dio()..httpClientAdapter = adapter,
      );

      final result = await api.authenticateByName(
        username: 'demo',
        password: 'secret',
      );

      expect(result.accessToken, 'token-1');
      expect(result.user?.name, 'Demo');
      expect(result.sessionInfo?.id, 'session-1');
    });

    test('supports quick connect initiate, poll, authenticate, and authorize', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onPost('/QuickConnect/Initiate', (_) {
        return jsonResponse(
          const <String, dynamic>{
            'Secret': 'secret-1',
            'Code': 'ABCD',
            'Authenticated': false,
          },
        );
      });
      adapter.onGet('/QuickConnect/Connect', (options) {
        expect(options.queryParameters['Secret'], 'secret-1');
        return jsonResponse(
          const <String, dynamic>{
            'Secret': 'secret-1',
            'Code': 'ABCD',
            'Authenticated': true,
            'IsAuthorized': true,
          },
        );
      });
      adapter.onPost('/Users/AuthenticateWithQuickConnect', (options) {
        expect(options.data, const <String, dynamic>{'secret': 'secret-1'});
        return jsonResponse(
          const <String, dynamic>{
            'AccessToken': 'token-2',
            'User': <String, dynamic>{'Id': 'user-2', 'Name': 'QC User'},
          },
        );
      });
      adapter.onPost('/QuickConnect/Authorize', (options) {
        expect(options.queryParameters['Code'], 'ABCD');
        expect(options.queryParameters.containsKey('UserId'), isFalse);
        return jsonResponse(const <String, dynamic>{'ok': true});
      });

      final api = JellyfinAuthApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'existing-token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final initiated = await api.initiateQuickConnect();
      final state = await api.getQuickConnectState('secret-1');
      final authenticated = await api.authenticateWithQuickConnect('secret-1');
      await api.authorizeQuickConnect(code: 'ABCD');

      expect(initiated.code, 'ABCD');
      expect(state.authenticated, isTrue);
      expect(state.isAuthorized, isTrue);
      expect(authenticated.accessToken, 'token-2');
    });

    test('surfaces quick connect expiration as a response error', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/QuickConnect/Connect', (options) {
        throw DioException(
          requestOptions: options,
          response: Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 400,
            data: const <String, dynamic>{'error': 'expired'},
          ),
          type: DioExceptionType.badResponse,
        );
      });

      final api = JellyfinAuthApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        dio: Dio()..httpClientAdapter = adapter,
      );

      await expectLater(
        () => api.getQuickConnectState('expired-secret'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.type, 'type', ApiErrorType.response)
              .having((error) => error.statusCode, 'statusCode', 400),
        ),
      );
    });
  });
}

