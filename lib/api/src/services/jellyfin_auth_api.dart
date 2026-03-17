import '../models/jellyfin_models.dart';
import '../transport/base_api_client.dart';
import 'jellyfin_api_base.dart';

class JellyfinAuthApi extends JellyfinApiBase {
  JellyfinAuthApi({
    required super.baseUrl,
    required super.clientInfo,
    super.accessToken,
    super.dio,
  });

  Future<List<JellyfinServerCandidate>> discoverServers(String url) async {
    try {
      final discoveryClient = BaseApiClient(baseUrl: url);
      final response = await discoveryClient.get<Map<String, dynamic>>(
        '/System/Info/Public',
      );
      final systemInfo = JellyfinPublicSystemInfo.fromJson(response.data ?? {});
      return [
        JellyfinServerCandidate(
          address: discoveryClient.baseUrl,
          systemInfo: systemInfo,
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<JellyfinPublicSystemInfo> getPublicSystemInfo() async {
    final response = await client.get<Map<String, dynamic>>('/System/Info/Public');
    return JellyfinPublicSystemInfo.fromJson(response.data ?? {});
  }

  Future<JellyfinAuthenticationResult> authenticateByName({
    required String username,
    required String password,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      '/Users/AuthenticateByName',
      data: {
        'Username': username,
        'Pw': password,
      },
      options: jellyfinOptions(token: null),
    );
    return JellyfinAuthenticationResult.fromJson(response.data ?? {});
  }

  Future<bool> isQuickConnectEnabled() async {
    final response = await client.get<bool>(
      '/QuickConnect/Enabled',
      options: jellyfinOptions(token: null),
    );
    return response.data == true;
  }

  Future<bool> quickConnectEnabled() => isQuickConnectEnabled();

  Future<JellyfinQuickConnectResult> initiateQuickConnect() async {
    final response = await client.post<Map<String, dynamic>>(
      '/QuickConnect/Initiate',
      options: jellyfinOptions(token: null),
    );
    return JellyfinQuickConnectResult.fromJson(response.data ?? {});
  }

  Future<JellyfinQuickConnectResult> getQuickConnectState(String secret) async {
    final response = await client.get<Map<String, dynamic>>(
      '/QuickConnect/Connect',
      queryParameters: {'Secret': secret},
      options: jellyfinOptions(token: null),
    );
    return JellyfinQuickConnectResult.fromJson(response.data ?? {});
  }

  Future<JellyfinAuthenticationResult> authenticateWithQuickConnect(
    String secret,
  ) async {
    final response = await client.post<Map<String, dynamic>>(
      '/Users/AuthenticateWithQuickConnect',
      data: {'secret': secret},
      options: jellyfinOptions(token: null),
    );
    return JellyfinAuthenticationResult.fromJson(response.data ?? {});
  }

  Future<void> authorizeQuickConnect({
    required String code,
    String? userId,
  }) async {
    await client.post<void>(
      '/QuickConnect/Authorize',
      queryParameters: {
        'Code': code,
        'UserId': userId,
      },
      options: jellyfinOptions(),
    );
  }

  Future<JellyfinQuickConnectResult> quickConnectState(String secret) {
    return getQuickConnectState(secret);
  }

  Future<JellyfinUser> getCurrentUser() async {
    final response = await client.get<Map<String, dynamic>>(
      '/Users/Me',
      options: jellyfinOptions(),
    );
    return JellyfinUser.fromJson(response.data ?? {});
  }
}
