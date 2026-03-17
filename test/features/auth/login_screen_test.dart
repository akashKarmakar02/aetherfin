import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/app/session/app_session_scope.dart';
import 'package:aetherfin/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/support/fake_app_session_auth_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    debugAppPlatformOverride = AppPlatform.windows;
  });

  tearDown(() {
    debugAppPlatformOverride = null;
  });

  testWidgets('login screen renders and signs in through the controller', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final factory = FakeAppSessionAuthClientFactory(
      onDiscoverServers: (url) async => <JellyfinServerCandidate>[
        fakeServerCandidate('http://verified.local'),
      ],
      onAuthenticateByName: (baseUrl, username, password) async {
        return JellyfinAuthenticationResult(
          accessToken: 'new-token',
          user: fakeUser('Demo'),
        );
      },
      onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Demo'),
    );
    final controller = AppSessionController(
      preferences: prefs,
      authClientFactory: factory.build,
    );
    await controller.initialize();
    await controller.connectToServer('verified.local');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSessionScope(
            notifier: controller,
            child: const LoginScreen(),
          ),
        ),
      ),
    );

    expect(find.text('Authenticate with Jellyfin'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(controller.phase, AppSessionPhase.loggedIn);
    expect(controller.user?.name, 'Demo');
  });
}
