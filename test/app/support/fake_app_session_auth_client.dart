import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/app/session/app_session_auth_client.dart';

class FakeAppSessionAuthClientFactory {
  FakeAppSessionAuthClientFactory({
    this.onDiscoverServers,
    this.onGetPublicSystemInfo,
    this.onAuthenticateByName,
    this.onGetCurrentUser,
  });

  final Future<List<JellyfinServerCandidate>> Function(String url)?
      onDiscoverServers;
  final Future<JellyfinPublicSystemInfo> Function(
    String baseUrl,
    String? accessToken,
  )? onGetPublicSystemInfo;
  final Future<JellyfinAuthenticationResult> Function(
    String baseUrl,
    String username,
    String password,
  )? onAuthenticateByName;
  final Future<JellyfinUser> Function(
    String baseUrl,
    String? accessToken,
  )? onGetCurrentUser;

  AppSessionAuthClient build({
    required String baseUrl,
    required JellyfinClientInfo clientInfo,
    String? accessToken,
  }) {
    return _FakeAppSessionAuthClient(
      baseUrl: baseUrl,
      accessToken: accessToken,
      onDiscoverServers: onDiscoverServers,
      onGetPublicSystemInfo: onGetPublicSystemInfo,
      onAuthenticateByName: onAuthenticateByName,
      onGetCurrentUser: onGetCurrentUser,
    );
  }
}

class _FakeAppSessionAuthClient implements AppSessionAuthClient {
  _FakeAppSessionAuthClient({
    required this.baseUrl,
    required this.accessToken,
    this.onDiscoverServers,
    this.onGetPublicSystemInfo,
    this.onAuthenticateByName,
    this.onGetCurrentUser,
  });

  final String baseUrl;
  final String? accessToken;
  final Future<List<JellyfinServerCandidate>> Function(String url)?
      onDiscoverServers;
  final Future<JellyfinPublicSystemInfo> Function(
    String baseUrl,
    String? accessToken,
  )? onGetPublicSystemInfo;
  final Future<JellyfinAuthenticationResult> Function(
    String baseUrl,
    String username,
    String password,
  )? onAuthenticateByName;
  final Future<JellyfinUser> Function(
    String baseUrl,
    String? accessToken,
  )? onGetCurrentUser;

  @override
  Future<JellyfinAuthenticationResult> authenticateByName({
    required String username,
    required String password,
  }) {
    if (onAuthenticateByName == null) {
      throw UnimplementedError('authenticateByName was not configured');
    }
    return onAuthenticateByName!(baseUrl, username, password);
  }

  @override
  Future<List<JellyfinServerCandidate>> discoverServers(String url) {
    if (onDiscoverServers == null) {
      throw UnimplementedError('discoverServers was not configured');
    }
    return onDiscoverServers!(url);
  }

  @override
  Future<JellyfinUser> getCurrentUser() {
    if (onGetCurrentUser == null) {
      throw UnimplementedError('getCurrentUser was not configured');
    }
    return onGetCurrentUser!(baseUrl, accessToken);
  }

  @override
  Future<JellyfinPublicSystemInfo> getPublicSystemInfo() {
    if (onGetPublicSystemInfo == null) {
      throw UnimplementedError('getPublicSystemInfo was not configured');
    }
    return onGetPublicSystemInfo!(baseUrl, accessToken);
  }
}

JellyfinServerCandidate fakeServerCandidate(String address) {
  return JellyfinServerCandidate(
    address: address,
    systemInfo: JellyfinPublicSystemInfo(
      name: 'Demo Jellyfin',
      serverName: 'Demo Jellyfin',
      version: '10.10.0',
    ),
  );
}

JellyfinPublicSystemInfo fakePublicSystemInfo([String? name]) {
  return JellyfinPublicSystemInfo(
    name: name ?? 'Demo Jellyfin',
    serverName: name ?? 'Demo Jellyfin',
    version: '10.10.0',
  );
}

JellyfinUser fakeUser([String? name]) {
  return JellyfinUser(
    id: 'user-1',
    name: name ?? 'Demo User',
  );
}
