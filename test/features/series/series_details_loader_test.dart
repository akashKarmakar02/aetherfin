import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/features/series/data/series_details_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../api/support/fake_http_client_adapter.dart';

void main() {
  group('loadSeriesDetailsWithApis', () {
    test('aggregates series, seasons, episodes, extras, related, and cast', () async {
      final adapter = FakeHttpClientAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      const clientInfo = JellyfinClientInfo(
        clientName: 'Aetherfin',
        deviceName: 'Test Device',
        deviceId: 'device-1',
        version: '1.0.0',
      );

      adapter.onGet('/Users/user-1/Items/series-1', (_) {
        return jsonResponse({
          'Id': 'series-1',
          'Type': 'Series',
          'Name': 'Severance',
          'Overview': 'Mark leads a team of office workers.',
          'Genres': ['Thriller', 'Mystery'],
          'ProductionYear': 2022,
          'OfficialRating': 'TV-14',
          'ImageTags': {
            'Primary': 'series-primary',
            'Logo': 'series-logo',
          },
          'BackdropImageTags': ['series-backdrop'],
          'UserData': {'IsFavorite': true},
          'People': [
            {
              'Id': 'p1',
              'Name': 'Adam Scott',
              'Role': 'Mark',
              'Type': 'Actor',
              'PrimaryImageTag': 'person-1',
            },
            {
              'Id': 'p2',
              'Name': 'Britt Lower',
              'Role': 'Helly',
              'Type': 'Actor',
              'PrimaryImageTag': 'person-2',
            },
          ],
          'RemoteTrailers': [
            {'Name': 'Official Trailer', 'Url': 'https://example.com/trailer'}
          ],
        });
      });

      adapter.onGet('/Shows/NextUp', (_) {
        return jsonResponse({
          'Items': [
            {
              'Id': 'ep-next',
              'Type': 'Episode',
              'Name': 'Good News About Hell',
              'SeriesId': 'series-1',
              'ParentIndexNumber': 1,
              'IndexNumber': 1,
              'Overview': 'Mark is promoted.',
              'ParentBackdropItemId': 'series-1',
              'ParentThumbImageTag': 'thumb-next',
            },
          ],
        });
      });

      adapter.onGet('/Shows/series-1/Seasons', (_) {
        return jsonResponse({
          'Items': [
            {
              'Id': 'season-1',
              'Type': 'Season',
              'Name': 'Season 1',
              'IndexNumber': 1,
              'ChildCount': 9,
            },
            {
              'Id': 'season-2',
              'Type': 'Season',
              'Name': 'Season 2',
              'IndexNumber': 2,
              'ChildCount': 10,
            },
          ],
        });
      });

      adapter.onRequest(
        (options) =>
            options.method == 'GET' &&
            options.path == '/Items' &&
            options.queryParameters['ParentId'] == 'series-1',
        (_) {
          return jsonResponse({
            'Items': [
              {
                'Id': 'extra-1',
                'Type': 'Trailer',
                'Name': 'Season 2 Trailer',
                'Overview': 'The office returns.',
                'ImageTags': {'Primary': 'extra-primary'},
              },
            ],
          });
        },
      );

      adapter.onGet('/Items/series-1/Similar', (_) {
        return jsonResponse({
          'Items': [
            {
              'Id': 'related-series',
              'Type': 'Series',
              'Name': 'Dark Matter',
              'ImageTags': {'Primary': 'related-primary'},
            },
            {
              'Id': 'related-movie',
              'Type': 'Movie',
              'Name': 'Not Included',
            },
          ],
        });
      });

      adapter.onRequest(
        (options) =>
            options.method == 'GET' &&
            options.path == '/Shows/series-1/Episodes' &&
            options.queryParameters['SeasonId'] == 'season-2',
        (_) {
          return jsonResponse({
            'Items': [
              {
                'Id': 'ep-s2-1',
                'Type': 'Episode',
                'Name': 'Hello, Ms. Cobel',
                'SeriesId': 'series-1',
                'ParentIndexNumber': 2,
                'IndexNumber': 1,
                'RunTimeTicks': 34200000000,
                'Overview': 'The team regroups.',
                'ParentBackdropItemId': 'series-1',
                'ParentThumbImageTag': 'thumb-s2',
              },
            ],
          });
        },
      );

      final libraryApi = JellyfinLibraryApi(
        baseUrl: 'http://demo.local',
        clientInfo: clientInfo,
        accessToken: 'token',
        dio: dio,
      );
      final mediaApi = JellyfinMediaApi(
        baseUrl: 'http://demo.local',
        clientInfo: clientInfo,
        accessToken: 'token',
        dio: dio,
      );

      final data = await loadSeriesDetailsWithApis(
        libraryApi: libraryApi,
        mediaApi: mediaApi,
        userId: 'user-1',
        request: const SeriesDetailsRequest(
          seriesId: 'series-1',
          seasonIndex: 2,
          highlightedEpisodeId: 'ep-s2-1',
        ),
      );

      expect(data.series.name, 'Severance');
      expect(data.selectedSeasonIndex, 2);
      expect(data.selectedSeason?.title, 'Season 2');
      expect(data.episodes.single.title, 'Hello, Ms. Cobel');
      expect(data.episodes.single.isHighlighted, isTrue);
      expect(data.nextUpEntries.single.title, 'Good News About Hell');
      expect(data.extraEntries.single.title, 'Season 2 Trailer');
      expect(data.relatedEntries, hasLength(1));
      expect(data.relatedEntries.single.title, 'Dark Matter');
      expect(data.castEntries, hasLength(2));
      expect(data.starringText, 'Starring Adam Scott, Britt Lower');
      expect(data.seriesBackdropUrl, contains('/Items/series-1/Images/Backdrop'));
      expect(data.seriesLogoUrl, contains('/Items/series-1/Images/Logo'));
    });
  });
}
