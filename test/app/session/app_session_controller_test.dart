import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/app/router/app_routes.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_app_session_auth_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  group('AppSessionController', () {
    test('restores a valid persisted session into loggedIn state', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'valid-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo('Home Server'),
        onGetCurrentUser: (baseUrl, accessToken) async {
          expect(accessToken, 'valid-token');
          return fakeUser('Asha');
        },
      );

      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );

      await controller.initialize();

      expect(controller.phase, AppSessionPhase.loggedIn);
      expect(controller.routeLocation, AppRoutes.homePath);
      expect(controller.user?.name, 'Asha');
      expect(controller.displayServerName, 'Home Server');
    });

    test('clears an expired persisted token and returns to connect', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'expired-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo(),
        onGetCurrentUser: (baseUrl, accessToken) async {
          throw ApiException(
            message: 'expired',
            type: ApiErrorType.response,
            statusCode: 401,
          );
        },
      );

      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );

      await controller.initialize();

      expect(controller.phase, AppSessionPhase.enterServer);
      expect(controller.errorMessage, 'Saved session expired. Sign in again.');
      expect(prefs.getString('token'), isNull);
    });

    test('restores saved server context without a token into login state', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo('Saved Server'),
      );

      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );

      await controller.initialize();

      expect(controller.phase, AppSessionPhase.enterCredentials);
      expect(controller.routeLocation, AppRoutes.loginPath);
      expect(controller.displayServerName, 'Saved Server');
    });

    test('connect and login persist the authenticated session', () async {
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onDiscoverServers: (url) async => <JellyfinServerCandidate>[
          fakeServerCandidate('http://verified.local'),
        ],
        onAuthenticateByName: (baseUrl, username, password) async {
          expect(username, 'demo');
          expect(password, 'secret');
          return JellyfinAuthenticationResult(
            accessToken: 'new-token',
            user: fakeUser('Demo'),
          );
        },
        onGetCurrentUser: (baseUrl, accessToken) async {
          expect(accessToken, 'new-token');
          return fakeUser('Demo');
        },
      );

      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );

      await controller.initialize();
      await controller.connectToServer('verified.local:8096');
      await controller.login(username: 'demo', password: 'secret');

      expect(controller.phase, AppSessionPhase.loggedIn);
      expect(controller.routeLocation, AppRoutes.homePath);
      expect(prefs.getString('serverUrl'), 'http://verified.local');
      expect(prefs.getString('token'), 'new-token');
      expect(prefs.getString('userName'), 'Demo');
    });

    test('failed login keeps the controller on the login step', () async {
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onDiscoverServers: (url) async => <JellyfinServerCandidate>[
          fakeServerCandidate('http://verified.local'),
        ],
        onAuthenticateByName: (baseUrl, username, password) async {
          throw ApiException(
            message: 'bad credentials',
            type: ApiErrorType.response,
            statusCode: 401,
          );
        },
      );

      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );

      await controller.initialize();
      await controller.connectToServer('verified.local');
      await controller.login(username: 'demo', password: 'wrong');

      expect(controller.phase, AppSessionPhase.enterCredentials);
      expect(controller.errorMessage, 'Invalid username or password.');
      expect(prefs.getString('token'), isNull);
    });
  });
}
