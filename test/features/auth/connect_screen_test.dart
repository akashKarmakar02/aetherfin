import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/app/session/app_session_scope.dart';
import 'package:aetherfin/features/auth/screens/connect_screen.dart';
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

  testWidgets('connect screen renders and submits the server url', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = AppSessionController(
      preferences: prefs,
      authClientFactory: FakeAppSessionAuthClientFactory(
        onDiscoverServers: (url) async => [
          fakeServerCandidate('http://verified.local'),
        ],
      ).build,
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSessionScope(
            notifier: controller,
            child: const ConnectScreen(),
          ),
        ),
      ),
    );

    expect(find.text('Add your Jellyfin server'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'verified.local');
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(controller.phase, AppSessionPhase.enterCredentials);
    expect(controller.serverUrl, 'http://verified.local');
  });
}
