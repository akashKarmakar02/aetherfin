import 'package:aetherfin/api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_client_adapter.dart';

const jellyfinClientInfo = JellyfinClientInfo(
  clientName: 'Aetherfin',
  deviceName: 'Linux',
  deviceId: 'dev-1',
  version: '1.0.0',
);

void main() {
  group('JellyfinMediaApi', () {
    test('parses media segments from the new endpoint', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/MediaSegments/item-1', (options) {
        expect(options.queryParameters['includeSegmentTypes'], 'Intro,Outro');
        return jsonResponse(
          const <String, dynamic>{
            'Items': <Map<String, dynamic>>[
              <String, dynamic>{
                'Type': 'Intro',
                'StartTicks': 10000000,
                'EndTicks': 30000000,
              },
              <String, dynamic>{
                'Type': 'Outro',
                'StartTicks': 90000000,
                'EndTicks': 120000000,
              },
            ],
          },
        );
      });

      final api = JellyfinMediaApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final segments = await api.fetchMediaSegments('item-1');

      expect(segments?.introSegments.single.startTime, 1);
      expect(segments?.introSegments.single.endTime, 3);
      expect(segments?.creditSegments.single.startTime, 9);
      expect(segments?.creditSegments.single.endTime, 12);
    });

    test('falls back to legacy segment endpoints when the new one fails', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/MediaSegments/item-2', (options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      adapter.onGet('/Episode/item-2/IntroTimestamps', (_) {
        return jsonResponse(
          const <String, dynamic>{
            'Valid': true,
            'IntroStart': 5.5,
            'IntroEnd': 15.5,
          },
        );
      });
      adapter.onGet('/Episode/item-2/Timestamps', (_) {
        return jsonResponse(
          const <String, dynamic>{
            'Credits': <String, dynamic>{
              'Valid': true,
              'Start': 50,
              'End': 58,
            },
          },
        );
      });

      final api = JellyfinMediaApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final segments = await api.fetchSegmentsWithFallback('item-2');

      expect(segments.introSegments.single.startTime, 5.5);
      expect(segments.creditSegments.single.endTime, 58);
    });

    test('hydrates media bar content in the order provided by the plugin list', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/web/avatars/list.txt', (options) {
        expect(options.queryParameters['userId'], 'user-1');
        return textResponse('ids\nitem-2\nitem-1\n');
      });
      adapter.onGet('/Items', (options) {
        expect(options.queryParameters['Ids'], 'item-2,item-1');
        return jsonResponse(
          const <String, dynamic>{
            'Items': <Map<String, dynamic>>[
              <String, dynamic>{
                'Id': 'item-1',
                'Type': 'Movie',
                'Name': 'First',
                'ImageTags': <String, dynamic>{'Primary': 'tag-1'},
              },
              <String, dynamic>{
                'Id': 'item-2',
                'Type': 'Series',
                'Name': 'Second',
                'ImageTags': <String, dynamic>{'Primary': 'tag-2'},
              },
            ],
          },
        );
      });

      final api = JellyfinMediaApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final content = await api.fetchMediaBarContent(userId: 'user-1');

      expect(content.source, JellyfinMediaBarSource.list);
      expect(content.itemIds, const <String>['item-2', 'item-1']);
      expect(content.items.map((item) => item.name).toList(), <String>['Second', 'First']);
    });

    test('parses playback info media streams', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onPost('/Items/item-3/PlaybackInfo', (_) {
        return jsonResponse(
          const <String, dynamic>{
            'PlaySessionId': 'play-1',
            'MediaSources': <Map<String, dynamic>>[
              <String, dynamic>{
                'Id': 'source-1',
                'Container': 'mkv',
                'DefaultAudioStreamIndex': 2,
                'DefaultSubtitleStreamIndex': 5,
                'MediaStreams': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'Index': 2,
                    'Type': 'Audio',
                    'DisplayTitle': 'English 5.1',
                    'Language': 'eng',
                    'IsDefault': true,
                  },
                  <String, dynamic>{
                    'Index': 5,
                    'Type': 'Subtitle',
                    'DisplayTitle': 'English SDH',
                    'Language': 'eng',
                    'IsForced': false,
                    'IsExternal': true,
                  },
                ],
              },
            ],
          },
        );
      });

      final api = JellyfinMediaApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final info = await api.getPlaybackInfo(itemId: 'item-3');
      final source = info.mediaSources.single;

      expect(info.playSessionId, 'play-1');
      expect(source.defaultAudioStreamIndex, 2);
      expect(source.defaultSubtitleStreamIndex, 5);
      expect(source.audioStreams.single.displayTitle, 'English 5.1');
      expect(source.subtitleStreams.single.isExternal, isTrue);
    });

    test('sends playback reporting payloads to Jellyfin session endpoints', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onPost('/Sessions/Playing', (_) => jsonResponse(const {}));
      adapter.onPost('/Sessions/Playing/Progress', (_) => jsonResponse(const {}));
      adapter.onPost('/Sessions/Playing/Stopped', (_) => jsonResponse(const {}));

      final api = JellyfinMediaApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );
      final report = JellyfinPlaybackReport(
        itemId: 'item-7',
        mediaSourceId: 'source-7',
        playSessionId: 'play-7',
        positionTicks: 420000000,
        playMethod: 'DirectPlay',
        audioStreamIndex: 1,
        subtitleStreamIndex: -1,
      );

      await api.reportPlaybackStarted(report);
      await api.reportPlaybackProgress(report);
      await api.reportPlaybackStopped(report);

      expect(adapter.requests.map((request) => request.path).toList(), <String>[
        '/Sessions/Playing',
        '/Sessions/Playing/Progress',
        '/Sessions/Playing/Stopped',
      ]);
      final firstPayload = adapter.requests.first.data as Map<String, dynamic>;
      expect(firstPayload['ItemId'], 'item-7');
      expect(firstPayload['SubtitleStreamIndex'], -1);
      expect(firstPayload['PlayMethod'], 'DirectPlay');
    });
  });
}
