import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/app/session/app_session_scope.dart';
import 'package:aetherfin/features/home/models/home_media_bar_view_data.dart';
import 'package:aetherfin/features/home/screens/home_screen.dart';
import 'package:aetherfin/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('home screen renders the media bar carousel content', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: AppSessionScope(
          notifier: controller,
          child: HomeScreen(
            loader: (_) async => HomeMediaBarViewData(
              hasPlugin: true,
              source: JellyfinMediaBarSource.list,
              entries: [
                HomeMediaBarEntry(
                  item: JellyfinBaseItem(
                    id: 'item-1',
                    type: 'Series',
                    name: 'The Studio',
                    overview: 'Seth Rogen stars in an uproarious workplace comedy.',
                    genres: const ['Comedy', 'Drama'],
                    productionYear: 2025,
                    communityRating: 8.4,
                  ),
                ),
              ],
              continueWatchingEntries: [
                HomeMediaBarEntry(
                  item: JellyfinBaseItem(
                    id: 'item-2',
                    type: 'Episode',
                    name: 'Blue Box',
                    raw: {
                      'UserData': {'PlayedPercentage': 42},
                    },
                  ),
                ),
              ],
              nextUpEntries: [
                HomeMediaBarEntry(
                  item: JellyfinBaseItem(
                    id: 'item-3',
                    type: 'Episode',
                    name: 'Chikhai Bardo',
                    seriesName: 'Severance',
                    parentIndexNumber: 2,
                    indexNumber: 9,
                  ),
                ),
              ],
              recentlyAddedEntries: [
                HomeMediaBarEntry(
                  item: JellyfinBaseItem(
                    id: 'item-4',
                    type: 'Movie',
                    name: 'Sinners',
                    productionYear: 2025,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('The Studio'), findsOneWidget);
    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('Blue Box'), findsOneWidget);
    expect(find.text('Next Up'), findsOneWidget);
    expect(find.text('Chikhai Bardo'), findsOneWidget);
    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('Sinners'), findsOneWidget);
  });
}
