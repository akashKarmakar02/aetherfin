import 'package:dio/dio.dart';

import '../transport/base_api_client.dart';

class JellyfinClientInfo {
  const JellyfinClientInfo({
    required this.clientName,
    required this.deviceName,
    required this.deviceId,
    required this.version,
  });

  final String clientName;
  final String deviceName;
  final String deviceId;
  final String version;
}

abstract class JellyfinApiBase {
  JellyfinApiBase({
    required String baseUrl,
    required this.clientInfo,
    this.accessToken,
    Dio? dio,
  }) : client = BaseApiClient(baseUrl: baseUrl, dio: dio);

  final BaseApiClient client;
  final JellyfinClientInfo clientInfo;
  final String? accessToken;

  String buildAuthorizationHeader([String? token]) {
    final segments = <String>[
      'Client="${clientInfo.clientName}"',
      'Device="${clientInfo.deviceName}"',
      'DeviceId="${clientInfo.deviceId}"',
      'Version="${clientInfo.version}"',
    ];
    final resolvedToken = token ?? accessToken;
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      segments.add('Token="$resolvedToken"');
    }
    return 'MediaBrowser ${segments.join(', ')}';
  }

  Options jellyfinOptions({
    String? token,
    Map<String, Object?>? headers,
    ResponseType? responseType,
  }) {
    return Options(
      headers: {
        'Authorization': buildAuthorizationHeader(token),
        if (headers != null) ...headers,
      },
      responseType: responseType,
    );
  }

  String buildUrl(String path) => '${client.baseUrl}${client.resolvePath(path)}';
}
