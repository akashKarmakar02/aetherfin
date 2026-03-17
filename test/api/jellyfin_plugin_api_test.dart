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
  group('JellyfinPluginApi', () {
    test('detects the media bar plugin from the plugin list', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/Plugins', (_) {
        return jsonResponse(
          const <Map<String, dynamic>>[
            <String, dynamic>{
              'Id': 'media-bar-plugin',
              'Name': 'Media Bar',
              'ConfigurationFileName': 'MediaBar.xml',
            },
          ],
        );
      });

      final api = JellyfinPluginApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      expect(await api.hasMediaBarPlugin(), isTrue);
    });

    test('parses the Streamyfin plugin config schema', () async {
      final adapter = FakeHttpClientAdapter();
      adapter.onGet('/Streamyfin/config', (_) {
        return jsonResponse(
          const <String, dynamic>{
            'settings': <String, dynamic>{
              'marlinServerUrl': <String, dynamic>{
                'locked': false,
                'value': 'https://marlin.local',
              },
            },
          },
        );
      });

      final api = JellyfinPluginApi(
        baseUrl: 'https://jellyfin.local',
        clientInfo: jellyfinClientInfo,
        accessToken: 'token',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final config = await api.getStreamyfinPluginConfig();
      expect(config.marlinServerUrl?.value, 'https://marlin.local');
      expect(config.marlinServerUrl?.locked, isFalse);
    });
  });
}
