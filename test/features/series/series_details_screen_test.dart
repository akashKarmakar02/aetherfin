import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/app/platform/app_platform.dart';
import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/app/session/app_session_scope.dart';
import 'package:aetherfin/features/series/data/series_details_loader.dart';
import 'package:aetherfin/features/series/models/series_details_view_data.dart';
import 'package:aetherfin/features/series/screens/series_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';

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

  testWidgets('route params are forwarded into the series details loader', (
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

    late SeriesDetailsRequest capturedRequest;
    final router = GoRouter(
      initialLocation: '/series/series-1?seasonIndex=2&episodeId=ep-s2-1',
      routes: [
        GoRoute(
          path: '/series/:id',
          builder: (context, state) => SeriesDetailsScreen(
            seriesId: state.pathParameters['id'] ?? '',
            initialSeasonIndex: int.tryParse(
              state.uri.queryParameters['seasonIndex'] ?? '',
            ),
            highlightedEpisodeId: state.uri.queryParameters['episodeId'],
            loader: (session, request) async {
              capturedRequest = request;
              return _buildViewData(
                selectedSeasonIndex: request.seasonIndex ?? 1,
                highlightedEpisodeId: request.highlightedEpisodeId,
                episodeTitle: 'The We We Are',
                showNextUp: false,
                showExtras: false,
                showRelated: false,
                showCast: true,
              );
            },
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: controller,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(capturedRequest.seriesId, 'series-1');
    expect(capturedRequest.seasonIndex, 2);
    expect(capturedRequest.highlightedEpisodeId, 'ep-s2-1');
    expect(find.text('Cast & Crew'), findsOneWidget);
    expect(find.text('Trailers & Extras'), findsNothing);
    expect(find.text('Related'), findsNothing);
  });

  testWidgets('changing season reloads the episode rail', (tester) async {
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

    final requests = <SeriesDetailsRequest>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AppSessionScope(
          notifier: controller,
          child: SeriesDetailsScreen(
            seriesId: 'series-1',
            loader: (session, request) async {
              requests.add(request);
              final season = request.seasonIndex ?? 1;
              return _buildViewData(
                selectedSeasonIndex: season,
                highlightedEpisodeId: request.highlightedEpisodeId,
                episodeTitle:
                    season == 1 ? 'Good News About Hell' : 'The We We Are',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requests.first.seasonIndex, isNull);

    await tester.tap(find.byType(YaruPopupMenuButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Season 2').last);
    await tester.pumpAndSettle();

    expect(requests.last.seasonIndex, 2);
    expect(find.text('The We We Are'), findsOneWidget);
  });
}

SeriesDetailsViewData _buildViewData({
  required int selectedSeasonIndex,
  required String? highlightedEpisodeId,
  required String episodeTitle,
  bool showNextUp = true,
  bool showExtras = true,
  bool showRelated = true,
  bool showCast = true,
}) {
  final series = JellyfinBaseItem(
    id: 'series-1',
    type: 'Series',
    name: 'Severance',
    overview: 'Mark leads a team of office workers.',
    genres: const ['Thriller', 'Mystery'],
    productionYear: 2022,
    officialRating: 'TV-14',
    userData: JellyfinUserData(isFavorite: false),
  );
  final seasons = [
    JellyfinBaseItem(
      id: 'season-1',
      type: 'Season',
      name: 'Season 1',
      indexNumber: 1,
      childCount: 9,
    ),
    JellyfinBaseItem(
      id: 'season-2',
      type: 'Season',
      name: 'Season 2',
      indexNumber: 2,
      childCount: 10,
    ),
  ];
  final episode = JellyfinBaseItem(
    id: highlightedEpisodeId ?? 'episode-1',
    type: 'Episode',
    name: episodeTitle,
    seriesId: 'series-1',
    parentIndexNumber: selectedSeasonIndex,
    indexNumber: 1,
    overview: 'Episode overview',
    runTimeTicks: 34200000000,
  );

  return SeriesDetailsViewData(
    series: series,
    selectedSeasonIndex: selectedSeasonIndex,
    highlightedEpisodeId: highlightedEpisodeId,
    starringText: showCast ? 'Starring Adam Scott, Britt Lower' : null,
    seriesPosterUrl: 'http://demo.local/poster.jpg',
    seriesBackdropUrl: 'http://demo.local/backdrop.jpg',
    seriesLogoUrl: null,
    selectedSeason: SeriesDetailsSeasonData(
      item: seasons[selectedSeasonIndex - 1],
      title: 'Season $selectedSeasonIndex',
      episodeCount: selectedSeasonIndex == 1 ? 9 : 10,
    ),
    seasons: seasons
        .map(
          (season) => SeriesDetailsSeasonData(
            item: season,
            title: season.name!,
            episodeCount: season.childCount ?? 0,
          ),
        )
        .toList(growable: false),
    episodes: [
      SeriesDetailsEpisodeEntry(
        item: episode,
        imageUrl: 'http://demo.local/episode.jpg',
        title: episodeTitle,
        subtitle: 'S${selectedSeasonIndex}E1',
        description: 'Episode overview',
        runtimeLabel: '57 min',
        isHighlighted: highlightedEpisodeId == episode.id,
      ),
    ],
    nextUpEntries: showNextUp
        ? [
            SeriesDetailsMediaEntry(
              item: episode,
              imageUrl: 'http://demo.local/next.jpg',
              title: 'Good News About Hell',
              subtitle: 'S1E1',
            ),
          ]
        : const [],
    extraEntries: showExtras
        ? [
            SeriesDetailsMediaEntry(
              item: JellyfinBaseItem(
                id: 'extra-1',
                type: 'Trailer',
                name: 'Season 2 Trailer',
              ),
              imageUrl: 'http://demo.local/trailer.jpg',
              title: 'Season 2 Trailer',
            ),
          ]
        : const [],
    relatedEntries: showRelated
        ? [
            SeriesDetailsMediaEntry(
              item: JellyfinBaseItem(
                id: 'related-series',
                type: 'Series',
                name: 'Dark Matter',
              ),
              posterUrl: 'http://demo.local/related.jpg',
              title: 'Dark Matter',
            ),
          ]
        : const [],
    castEntries: showCast
        ? [
            SeriesDetailsPersonEntry(
              person: JellyfinPerson(
                id: 'person-1',
                name: 'Adam Scott',
                role: 'Mark',
              ),
              imageUrl: 'http://demo.local/person.jpg',
            ),
          ]
        : const [],
  );
}
