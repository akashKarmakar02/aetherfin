import '../../api/api.dart';

abstract class AppSessionAuthClient {
  Future<List<JellyfinServerCandidate>> discoverServers(String url);

  Future<JellyfinPublicSystemInfo> getPublicSystemInfo();

  Future<JellyfinAuthenticationResult> authenticateByName({
    required String username,
    required String password,
  });

  Future<JellyfinUser> getCurrentUser();
}

typedef AppSessionAuthClientFactory = AppSessionAuthClient Function({
  required String baseUrl,
  required JellyfinClientInfo clientInfo,
  String? accessToken,
});

AppSessionAuthClient buildJellyfinAppSessionAuthClient({
  required String baseUrl,
  required JellyfinClientInfo clientInfo,
  String? accessToken,
}) {
  return JellyfinAppSessionAuthClient(
    JellyfinAuthApi(
      baseUrl: baseUrl,
      clientInfo: clientInfo,
      accessToken: accessToken,
    ),
  );
}

class JellyfinAppSessionAuthClient implements AppSessionAuthClient {
  JellyfinAppSessionAuthClient(this._api);

  final JellyfinAuthApi _api;

  @override
  Future<JellyfinAuthenticationResult> authenticateByName({
    required String username,
    required String password,
  }) {
    return _api.authenticateByName(
      username: username,
      password: password,
    );
  }

  @override
  Future<List<JellyfinServerCandidate>> discoverServers(String url) {
    return _api.discoverServers(url);
  }

  @override
  Future<JellyfinUser> getCurrentUser() {
    return _api.getCurrentUser();
  }

  @override
  Future<JellyfinPublicSystemInfo> getPublicSystemInfo() {
    return _api.getPublicSystemInfo();
  }
}
