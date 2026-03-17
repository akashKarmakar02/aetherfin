import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/features/player/data/player_loader.dart';
import 'package:aetherfin/features/player/models/player_view_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../api/support/fake_http_client_adapter.dart';

const _clientInfo = JellyfinClientInfo(
  clientName: 'Aetherfin',
  deviceName: 'Linux',
  deviceId: 'dev-1',
  version: '1.0.0',
);

void main() {
  group('PlayerLoader', () {
    test('loads playback data using Jellyfin defaults and resume position', () async {
      final adapter = FakeHttpClientAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      adapter.onGet('/Users/user-1/Items/episode-1', (_) {
        return jsonResponse(
          const <String, dynamic>{
            'Id': 'episode-1',
            'Type': 'Episode',
            'Name': 'Episode 1',
            'UserData': <String, dynamic>{
              'PlaybackPositionTicks': 900000000,
            },
          },
        );
      });
      adapter.onRequest(
        (options) =>
            options.method == 'POST' &&
            options.path == '/Items/episode-1/PlaybackInfo',
        (_) {
          return jsonResponse(
            const <String, dynamic>{
              'PlaySessionId': 'play-episode-1',
              'MediaSources': <Map<String, dynamic>>[
                <String, dynamic>{
                  'Id': 'source-1',
                  'Container': 'mkv',
                  'DefaultAudioStreamIndex': 3,
                  'MediaStreams': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'Index': 3,
                      'Type': 'Audio',
                      'DisplayTitle': 'English',
                      'IsDefault': true,
                    },
                    <String, dynamic>{
                      'Index': 7,
                      'Type': 'Subtitle',
                      'DisplayTitle': 'English CC',
                    },
                  ],
                },
              ],
            },
          );
        },
      );

      final loader = PlayerLoader(
        baseUrl: 'https://jellyfin.local',
        accessToken: 'token',
        clientInfo: _clientInfo,
        userId: 'user-1',
        dio: dio,
      );
      final data = await loader.load('episode-1');

      expect(data.item.id, 'episode-1');
      expect(data.startPositionTicks, 900000000);
      expect(data.selectedAudioStreamIndex, 3);
      expect(data.selectedSubtitleStreamIndex, -1);
      expect(data.playSessionId, 'play-episode-1');
      expect(data.streamUrl, contains('/Videos/episode-1/stream'));
    });

    test('reloads stream with explicit audio and subtitle indices', () async {
      final adapter = FakeHttpClientAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      adapter.onRequest(
        (options) =>
            options.method == 'POST' &&
            options.path == '/Items/episode-2/PlaybackInfo',
        (_) {
          return jsonResponse(
            const <String, dynamic>{
              'PlaySessionId': 'play-episode-2',
              'MediaSources': <Map<String, dynamic>>[
                <String, dynamic>{
                  'Id': 'source-2',
                  'Container': 'mkv',
                  'MediaStreams': <Map<String, dynamic>>[
                    <String, dynamic>{'Index': 1, 'Type': 'Audio'},
                    <String, dynamic>{'Index': 5, 'Type': 'Subtitle'},
                  ],
                },
              ],
            },
          );
        },
      );

      final loader = PlayerLoader(
        baseUrl: 'https://jellyfin.local',
        accessToken: 'token',
        clientInfo: _clientInfo,
        userId: 'user-1',
        dio: dio,
      );
      final current = PlayerViewData(
        requestedItemId: 'episode-2',
        item: JellyfinBaseItem(id: 'episode-2', type: 'Episode'),
        streamUrl: 'https://old',
        mediaSource: JellyfinMediaSourceInfo(id: 'source-2'),
        playSessionId: 'play-old',
        startPositionTicks: 0,
        selectedAudioStreamIndex: 0,
        selectedSubtitleStreamIndex: -1,
      );

      final data = await loader.reloadStream(
        current: current,
        startPositionTicks: 120000000,
        audioStreamIndex: 1,
        subtitleStreamIndex: -1,
      );

      expect(data.selectedAudioStreamIndex, 1);
      expect(data.selectedSubtitleStreamIndex, -1);
      expect(data.streamUrl, contains('audioStreamIndex=1'));
      expect(data.streamUrl, contains('subtitleStreamIndex=-1'));
      expect(data.streamUrl, contains('startTimeTicks=120000000'));
    });
  });
}
