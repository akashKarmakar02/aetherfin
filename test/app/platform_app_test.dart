import 'package:aetherfin/app/app.dart';
import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/router/app_router.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/app/shell/platform_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_app_session_auth_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('linux app mounts the Linux shell host', (tester) async {
    debugAppPlatformOverride = AppPlatform.linux;
    final prefs = await SharedPreferences.getInstance();
    final controller = AppSessionController(
      preferences: prefs,
      authClientFactory: FakeAppSessionAuthClientFactory(
        onGetPublicSystemInfo: (baseUrl, accessToken) async =>
            fakePublicSystemInfo(),
      ).build,
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

    expect(find.byType(LinuxWindowShell), findsOneWidget);
    debugAppPlatformOverride = null;
  });

  testWidgets('windows app mounts the desktop material shell host', (
    tester,
  ) async {
    debugAppPlatformOverride = AppPlatform.windows;
    final prefs = await SharedPreferences.getInstance();
    final controller = AppSessionController(
      preferences: prefs,
      authClientFactory: FakeAppSessionAuthClientFactory().build,
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

    expect(find.byType(DesktopMaterialShell), findsOneWidget);
    debugAppPlatformOverride = null;
  });

  testWidgets('cupertino platforms mount the cupertino shell host', (
    tester,
  ) async {
    debugAppPlatformOverride = AppPlatform.cupertino;
    final prefs = await SharedPreferences.getInstance();
    final controller = AppSessionController(
      preferences: prefs,
      authClientFactory: FakeAppSessionAuthClientFactory().build,
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

    expect(find.byType(CupertinoRootShell), findsOneWidget);
    debugAppPlatformOverride = null;
  });
}
