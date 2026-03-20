import 'package:aetherfin/app/session/app_session_controller.dart';
import 'package:aetherfin/features/search/data/search_loader.dart';
import 'package:aetherfin/features/search/models/search_view_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/support/fake_http_client_adapter.dart';
import '../../app/support/fake_app_session_auth_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'serverUrl': 'https://demo.local',
      'token': 'valid-token',
    });
  });

  test('uses Streamystats when selected by the Streamyfin plugin config', () async {
    final adapter = FakeHttpClientAdapter();
    adapter.onGet('/Streamyfin/config', (_) {
      return jsonResponse(
        const <String, dynamic>{
          'settings': <String, dynamic>{
            'searchEngine': <String, dynamic>{
              'locked': false,
              'value': 'Streamystats',
            },
            'streamyStatsServerUrl': <String, dynamic>{
              'locked': false,
              'value': 'https://stats.local',
            },
          },
        },
      );
    });
    adapter.onGet('/api/search', (options) {
      expect(
        options.headers['Authorization'],
        'MediaBrowser Token="valid-token"',
      );
      switch (options.queryParameters['type']) {
        case 'movies':
          return jsonResponse(
            const <String, dynamic>{
              'data': <String, dynamic>{
                'movies': <String>['movie-2', 'movie-1'],
                'total': 2,
              },
            },
          );
        default:
          return jsonResponse(
            const <String, dynamic>{
              'data': <String, dynamic>{'total': 0},
            },
          );
      }
    });
    adapter.onGet('/Items', (options) {
      expect(options.queryParameters['Ids'], 'movie-2,movie-1');
      return jsonResponse(
        const <String, dynamic>{
          'Items': <Map<String, dynamic>>[
            <String, dynamic>{
              'Id': 'movie-1',
              'Type': 'Movie',
              'Name': 'Arrival',
              'ProductionYear': 2016,
              'ImageTags': <String, dynamic>{'Primary': 'tag-1'},
            },
            <String, dynamic>{
              'Id': 'movie-2',
              'Type': 'Movie',
              'Name': 'Alien',
              'ProductionYear': 1979,
              'ImageTags': <String, dynamic>{'Primary': 'tag-2'},
            },
          ],
        },
      );
    });

    final session = await _buildSessionController();
    final loader = AppSearchLoader(dio: Dio()..httpClientAdapter = adapter);
    final data = await loader.load(session, 'alien');

    expect(data.backend, SearchBackend.streamystats);
    expect(data.sections.single.title, 'Movies');
    expect(
      data.sections.single.entries.map((entry) => entry.item.name).toList(),
      <String>['Alien', 'Arrival'],
    );
  });

  test('falls back to Jellyfin search when the configured Marlin URL is missing', () async {
    final adapter = FakeHttpClientAdapter();
    adapter.onGet('/Streamyfin/config', (_) {
      return jsonResponse(
        const <String, dynamic>{
          'settings': <String, dynamic>{
            'searchEngine': <String, dynamic>{
              'locked': false,
              'value': 'Marlin',
            },
            'marlinServerUrl': <String, dynamic>{
              'locked': false,
              'value': '',
            },
          },
        },
      );
    });
    adapter.onGet('/Items', (options) {
      expect(options.queryParameters['SearchTerm'], 'silo');
      switch (options.queryParameters['IncludeItemTypes']) {
        case 'Series':
          return jsonResponse(
            const <String, dynamic>{
              'Items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'Id': 'series-1',
                  'Type': 'Series',
                  'Name': 'Silo',
                  'ProductionYear': 2023,
                  'ImageTags': <String, dynamic>{'Primary': 'tag-series'},
                },
              ],
            },
          );
        default:
          return jsonResponse(
            const <String, dynamic>{'Items': <Map<String, dynamic>>[]},
          );
      }
    });

    final session = await _buildSessionController();
    final loader = AppSearchLoader(dio: Dio()..httpClientAdapter = adapter);
    final data = await loader.load(session, 'silo');

    expect(data.backend, SearchBackend.jellyfin);
    expect(data.sections.single.title, 'Series');
    expect(data.sections.single.entries.single.item.name, 'Silo');
  });
}

Future<AppSessionController> _buildSessionController() async {
  final prefs = await SharedPreferences.getInstance();
  final controller = AppSessionController(
    preferences: prefs,
    authClientFactory: FakeAppSessionAuthClientFactory(
      onGetPublicSystemInfo: (baseUrl, accessToken) async =>
          fakePublicSystemInfo('Demo Server'),
      onGetCurrentUser: (baseUrl, accessToken) async => fakeUser('Demo User'),
    ).build,
  );
  await controller.initialize();
  return controller;
}
