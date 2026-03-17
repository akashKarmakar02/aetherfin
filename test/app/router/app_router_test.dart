import 'package:aetherfin/app/app.dart';
import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/router/app_router.dart';
import 'package:aetherfin/app/router/app_routes.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/features/home/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_app_session_auth_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    debugAppPlatformOverride = AppPlatform.windows;
  });

  tearDown(() {
    debugAppPlatformOverride = null;
  });

  group('App router', () {
    testWidgets('valid saved session redirects to home', (tester) async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'valid-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo('Home Server'),
        onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Asha'),
      );
      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );
      await controller.initialize();
      final router = createAppRouter(controller);

      await tester.pumpWidget(
        AetherfinApp(
          router: router,
          sessionController: controller,
          enableLinuxTray: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('expired token redirects back to connect', (tester) async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'expired-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo(),
        onGetCurrentUser: (baseUrl, accessToken) async {
          throw Exception('expired');
        },
      );
      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );
      await controller.initialize();
      final router = createAppRouter(controller);

      await tester.pumpWidget(
        AetherfinApp(
          router: router,
          sessionController: controller,
          enableLinuxTray: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add your Jellyfin server'), findsOneWidget);
    });

    testWidgets('verified server without token redirects to login', (
      tester,
    ) async {
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
      final router = createAppRouter(controller);

      await tester.pumpWidget(
        AetherfinApp(
          router: router,
          sessionController: controller,
          enableLinuxTray: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Authenticate with Jellyfin'), findsOneWidget);
      expect(find.textContaining('Connected server:'), findsOneWidget);
    });

    testWidgets('logout redirects back to connect', (tester) async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'valid-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo('Home Server'),
        onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Asha'),
      );
      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );
      await controller.initialize();
      final router = createAppRouter(controller);

      await tester.pumpWidget(
        AetherfinApp(
          router: router,
          sessionController: controller,
          enableLinuxTray: false,
        ),
      );
      await tester.pumpAndSettle();

      await controller.logout();
      await tester.pumpAndSettle();

      expect(find.text('Add your Jellyfin server'), findsOneWidget);
    });

    testWidgets('logged in users can navigate to the series route', (tester) async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'valid-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo('Home Server'),
        onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Asha'),
      );
      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );
      await controller.initialize();
      final router = createAppRouter(controller);

      router.goNamed(
        AppRoutes.seriesName,
        pathParameters: {'id': 'series-1'},
        queryParameters: const {'seasonIndex': '2', 'episodeId': 'ep-9'},
      );

      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/series/series-1?seasonIndex=2&episodeId=ep-9',
      );
    });

    testWidgets('logged in users can navigate to the player route', (tester) async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'serverUrl': 'http://demo.local',
        'token': 'valid-token',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo('Home Server'),
        onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Asha'),
      );
      final controller = AppSessionController(
        preferences: prefs,
        authClientFactory: factory.build,
      );
      await controller.initialize();
      final router = createAppRouter(controller);

      router.goNamed(
        AppRoutes.playerName,
        pathParameters: {'itemId': 'episode-7'},
      );

      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/player/episode-7',
      );
    });
  });
}
