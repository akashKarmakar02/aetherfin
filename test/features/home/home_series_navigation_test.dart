import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/router/app_routes.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/app/session/app_session_scope.dart';
import 'package:aetherfin/features/home/data/home_media_bar_loader.dart';
import 'package:aetherfin/features/home/models/home_media_bar_view_data.dart';
import 'package:aetherfin/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/support/fake_app_session_auth_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'serverUrl': 'http://demo.local',
      'token': 'valid-token',
    });
    debugAppPlatformOverride = AppPlatform.windows;
  });

  tearDown(() {
    debugAppPlatformOverride = null;
  });

  testWidgets('hero series action routes to series details', (tester) async {
    final controller = await _buildController();
    final router = _buildRouter(
      controller,
      homeLoader: (_) async => HomeMediaBarViewData(
        hasPlugin: true,
        source: JellyfinMediaBarSource.list,
        entries: [
          HomeMediaBarEntry(
            item: JellyfinBaseItem(
              id: 'series-1',
              type: 'Series',
              name: 'Severance',
              overview: 'Mark leads a team of office workers.',
              genres: const ['Thriller'],
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: controller,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Show'));
    await tester.pumpAndSettle();

    expect(find.text('series:series-1'), findsOneWidget);
  });

  testWidgets('continue watching episode routes to parent series details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _buildController();
    final router = _buildRouter(
      controller,
      homeLoader: (_) async => HomeMediaBarViewData(
        hasPlugin: true,
        source: JellyfinMediaBarSource.list,
        entries: [
          HomeMediaBarEntry(
            item: JellyfinBaseItem(
              id: 'series-1',
              type: 'Series',
              name: 'Severance',
            ),
          ),
        ],
        continueWatchingEntries: [
          HomeMediaBarEntry(
            item: JellyfinBaseItem(
              id: 'ep-2',
              type: 'Episode',
              name: 'Blue Box',
              seriesId: 'series-parent',
              parentIndexNumber: 2,
              raw: {
                'UserData': {'PlayedPercentage': 42},
              },
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: controller,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Blue Box'));
    await tester.tap(find.text('Blue Box'));
    await tester.pumpAndSettle();

    expect(find.text('series:series-parent season:2 episode:ep-2'), findsOneWidget);
  });

  testWidgets('next up episode routes to parent series details', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _buildController();
    final router = _buildRouter(
      controller,
      homeLoader: (_) async => HomeMediaBarViewData(
        hasPlugin: true,
        source: JellyfinMediaBarSource.list,
        entries: const [],
        nextUpEntries: [
          HomeMediaBarEntry(
            item: JellyfinBaseItem(
              id: 'ep-5',
              type: 'Episode',
              name: 'The We We Are',
              seriesId: 'series-parent',
              seriesName: 'Severance',
              parentIndexNumber: 2,
              indexNumber: 10,
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: controller,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('The We We Are'));
    await tester.tap(find.text('The We We Are'));
    await tester.pumpAndSettle();

    expect(find.text('series:series-parent season:2 episode:ep-5'), findsOneWidget);
  });

  testWidgets('recently added movie routes to player', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _buildController();
    final router = _buildRouter(
      controller,
      homeLoader: (_) async => HomeMediaBarViewData(
        hasPlugin: true,
        source: JellyfinMediaBarSource.list,
        entries: const [],
        recentlyAddedEntries: [
          HomeMediaBarEntry(
            item: JellyfinBaseItem(
              id: 'movie-1',
              type: 'Movie',
              name: 'Sinners',
              productionYear: 2025,
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: controller,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sinners'));
    await tester.tap(find.text('Sinners'));
    await tester.pumpAndSettle();

    expect(find.text('player:movie-1'), findsOneWidget);
  });
}

Future<AppSessionController> _buildController() async {
  final prefs = await SharedPreferences.getInstance();
  final controller = AppSessionController(
    preferences: prefs,
    authClientFactory: FakeAppSessionAuthClientFactory(
      onGetPublicSystemInfo: (baseUrl, accessToken) async =>
          fakePublicSystemInfo('Home Server'),
      onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Asha'),
    ).build,
  );
  await controller.initialize();
  return controller;
}

GoRouter _buildRouter(
  AppSessionController controller, {
  required HomeMediaBarLoader homeLoader,
}) {
  return GoRouter(
    initialLocation: AppRoutes.homePath,
    routes: [
      GoRoute(
        path: AppRoutes.homePath,
        builder: (context, state) => HomeScreen(loader: homeLoader),
      ),
      GoRoute(
        path: AppRoutes.seriesPath,
        name: AppRoutes.seriesName,
        builder: (context, state) {
          final seriesId = state.pathParameters['id'] ?? '';
          final season = state.uri.queryParameters['seasonIndex'];
          final episode = state.uri.queryParameters['episodeId'];
          return Scaffold(
            body: Center(
              child: Text(
                [
                  'series:$seriesId',
                  if (season != null) 'season:$season',
                  if (episode != null) 'episode:$episode',
                ].join(' '),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.playerPath,
        name: AppRoutes.playerName,
        builder: (context, state) {
          final itemId = state.pathParameters['itemId'] ?? '';
          return Scaffold(body: Center(child: Text('player:$itemId')));
        },
      ),
    ],
  );
}
