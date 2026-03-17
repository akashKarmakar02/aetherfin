import 'package:aetherfin/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_client_adapter.dart';

void main() {
  group('StreamystatsApi', () {
    test('search sends Jellyfin token auth and parses id results', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/api/search', (options) {
        expect(
          options.headers['Authorization'],
          'MediaBrowser Token="jf-token"',
        );
        expect(options.queryParameters['q'], 'silo');
        expect(options.queryParameters['format'], 'ids');
        expect(options.queryParameters['type'], 'movie');
        expect(options.queryParameters['limit'], 5);
        return jsonResponse(
          const <String, dynamic>{
            'data': <String, dynamic>{
              'movies': <String>['m-1'],
              'series': <String>['s-1'],
              'total': 2,
            },
          },
        );
      });

      final api = StreamystatsApi(
        baseUrl: 'https://stats.local',
        jellyfinToken: 'jf-token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final result = await api.search(
        StreamystatsSearchParams(
          query: 'silo',
          format: 'ids',
          type: 'movie',
          limit: 5,
        ),
      );

      expect(result, isA<StreamystatsSearchIdsResponse>());
      expect((result as StreamystatsSearchIdsResponse).movies, <String>['m-1']);
      expect(result.total, 2);
    });

    test('parses recommendations responses', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/api/recommendations', (options) {
        expect(options.queryParameters['jellyfinServerId'], 'server-1');
        expect(options.queryParameters['includeBasedOn'], true);
        expect(options.queryParameters['includeReasons'], true);
        return jsonResponse(
          const <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'item': <String, dynamic>{
                  'id': 'item-1',
                  'name': 'Arrival',
                  'type': 'Movie',
                },
                'similarity': 0.92,
                'reason': 'Because you watched Contact',
              },
            ],
          },
        );
      });

      final api = StreamystatsApi(
        baseUrl: 'https://stats.local',
        jellyfinToken: 'jf-token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final result = await api.getRecommendations(
        StreamystatsRecommendationsParams(
          jellyfinServerId: 'server-1',
          includeBasedOn: true,
          includeReasons: true,
        ),
      );

      expect(result.data.single.item?.name, 'Arrival');
      expect(result.data.single.reason, 'Because you watched Contact');
    });

    test('supports watchlist CRUD and item mutations', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onPost('/api/watchlists', (options) {
        expect(options.data, const <String, dynamic>{'name': 'Favorites'});
        return jsonResponse(
          const <String, dynamic>{
            'data': <String, dynamic>{'id': 7, 'name': 'Favorites'},
          },
        );
      });
      adapter.onPatch('/api/watchlists/7', (options) {
        expect(options.data, const <String, dynamic>{'description': 'Updated'});
        return jsonResponse(
          const <String, dynamic>{
            'data': <String, dynamic>{'id': 7, 'description': 'Updated'},
          },
        );
      });
      adapter.onPost('/api/watchlists/7/items', (options) {
        expect(options.data, const <String, dynamic>{'itemId': 'item-1'});
        return jsonResponse(
          const <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'watchlistId': 7, 'itemId': 'item-1'},
          },
        );
      });
      adapter.onDelete('/api/watchlists/7/items/item-1', (_) {
        return jsonResponse(
          const <String, dynamic>{'success': true, 'message': 'removed'},
        );
      });
      adapter.onDelete('/api/watchlists/7', (_) {
        return jsonResponse(
          const <String, dynamic>{'success': true, 'message': 'deleted'},
        );
      });

      final api = StreamystatsApi(
        baseUrl: 'https://stats.local',
        jellyfinToken: 'jf-token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final created = await api.createWatchlist(
        StreamystatsCreateWatchlistRequest(name: 'Favorites'),
      );
      final updated = await api.updateWatchlist(
        7,
        StreamystatsUpdateWatchlistRequest(description: 'Updated'),
      );
      final added = await api.addWatchlistItem(7, 'item-1');
      final removed = await api.removeWatchlistItem(7, 'item-1');
      final deleted = await api.deleteWatchlist(7);

      expect(created.data?.id, 7);
      expect(updated.data?.description, 'Updated');
      expect(added.success, isTrue);
      expect(removed.success, isTrue);
      expect(deleted.success, isTrue);
    });
  });
}

