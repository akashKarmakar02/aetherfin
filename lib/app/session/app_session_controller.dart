import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api.dart';
import '../platform/app_platform.dart';
import '../router/app_routes.dart';
import 'app_session_auth_client.dart';

enum AppSessionPhase {
  restoring,
  enterServer,
  checkingServer,
  enterCredentials,
  signingIn,
  loggedIn,
}

class AppSessionController extends ChangeNotifier {
  AppSessionController({
    SharedPreferences? preferences,
    AppSessionAuthClientFactory authClientFactory =
        buildJellyfinAppSessionAuthClient,
    this.clientName = 'Aetherfin',
    this.appVersion = '1.0.0',
  })  : _providedPreferences = preferences,
        _authClientFactory = authClientFactory;

  static const String _serverUrlKey = 'serverUrl';
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'userId';
  static const String _userNameKey = 'userName';
  static const String _deviceIdKey = 'deviceId';

  final SharedPreferences? _providedPreferences;
  final AppSessionAuthClientFactory _authClientFactory;
  final String clientName;
  final String appVersion;

  SharedPreferences? _preferences;
  JellyfinClientInfo? _clientInfo;
  bool _initialized = false;

  AppSessionPhase _phase = AppSessionPhase.restoring;
  String? _errorMessage;
  String? _serverUrl;
  JellyfinPublicSystemInfo? _serverInfo;
  JellyfinUser? _user;
  String? _accessToken;

  AppSessionPhase get phase => _phase;
  JellyfinClientInfo? get clientInfo => _clientInfo;
  String? get errorMessage => _errorMessage;
  String? get serverUrl => _serverUrl;
  JellyfinPublicSystemInfo? get serverInfo => _serverInfo;
  JellyfinUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get hasVerifiedServer => _serverInfo != null && _serverUrl != null;
  String get suggestedServerUrl => _serverUrl ?? '';
  String get displayServerName =>
      _serverInfo?.serverName ?? _serverInfo?.name ?? 'Jellyfin Server';

  String get routeLocation => switch (_phase) {
        AppSessionPhase.restoring => AppRoutes.startupPath,
        AppSessionPhase.enterServer || AppSessionPhase.checkingServer =>
          AppRoutes.connectPath,
        AppSessionPhase.enterCredentials || AppSessionPhase.signingIn =>
          AppRoutes.loginPath,
        AppSessionPhase.loggedIn => AppRoutes.homePath,
      };

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _preferences = _providedPreferences ?? await SharedPreferences.getInstance();
    final deviceId =
        _preferences!.getString(_deviceIdKey) ?? _generateDeviceId();
    await _preferences!.setString(_deviceIdKey, deviceId);

    _clientInfo = JellyfinClientInfo(
      clientName: clientName,
      deviceName: _platformDeviceName,
      deviceId: deviceId,
      version: appVersion,
    );

    _serverUrl = _preferences!.getString(_serverUrlKey);
    _accessToken = _preferences!.getString(_tokenKey);

    if (_serverUrl != null && _accessToken != null) {
      await _restorePersistedSession();
      return;
    }

    if (_serverUrl != null) {
      await _restoreServerContext();
      return;
    }

    _phase = AppSessionPhase.enterServer;
    notifyListeners();
  }

  Future<void> connectToServer(String rawUrl) async {
    await _ensureInitialized();

    _phase = AppSessionPhase.checkingServer;
    _errorMessage = null;
    notifyListeners();

    final normalizedInput = _normalizeServerUrl(rawUrl);
    final client = _anonymousClient(normalizedInput);
    final candidates = await client.discoverServers(normalizedInput);

    if (candidates.isEmpty) {
      _phase = AppSessionPhase.enterServer;
      _errorMessage = 'Could not reach a Jellyfin server at that URL.';
      notifyListeners();
      return;
    }

    final selected = candidates.first;
    _serverUrl = selected.address;
    _serverInfo = selected.systemInfo;
    _user = null;
    _accessToken = null;

    await _preferences?.setString(_serverUrlKey, selected.address);
    await _clearSavedAuth(notify: false);

    _phase = AppSessionPhase.enterCredentials;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    await _ensureInitialized();

    final serverUrl = _serverUrl;
    if (serverUrl == null || serverUrl.isEmpty) {
      _phase = AppSessionPhase.enterServer;
      _errorMessage = 'Enter a server URL first.';
      notifyListeners();
      return;
    }

    _phase = AppSessionPhase.signingIn;
    _errorMessage = null;
    notifyListeners();

    final client = _anonymousClient(serverUrl);

    try {
      final authResult = await client.authenticateByName(
        username: username,
        password: password,
      );
      final token = authResult.accessToken;

      if (token == null || token.isEmpty) {
        throw ApiException(
          message: 'The server did not return an access token.',
          type: ApiErrorType.response,
        );
      }

      final authenticatedClient = _authClientFactory(
        baseUrl: serverUrl,
        clientInfo: _clientInfo!,
        accessToken: token,
      );

      final currentUser = await authenticatedClient.getCurrentUser();
      _accessToken = token;
      _user = currentUser;

      await _preferences?.setString(_tokenKey, token);
      await _preferences?.setString(_userIdKey, currentUser.id ?? '');
      await _preferences?.setString(_userNameKey, currentUser.name ?? username);

      _phase = AppSessionPhase.loggedIn;
      notifyListeners();
    } on ApiException catch (error) {
      _phase = AppSessionPhase.enterCredentials;
      _errorMessage = _mapLoginError(error);
      notifyListeners();
    } catch (_) {
      _phase = AppSessionPhase.enterCredentials;
      _errorMessage = 'Login failed. Check your credentials and try again.';
      notifyListeners();
    }
  }

  Future<void> changeServer() async {
    await _ensureInitialized();
    _serverInfo = null;
    _user = null;
    _accessToken = null;
    _errorMessage = null;
    await _clearSavedAuth(notify: false);
    _phase = AppSessionPhase.enterServer;
    notifyListeners();
  }

  Future<void> logout() async {
    await _ensureInitialized();
    _serverInfo = null;
    _user = null;
    _accessToken = null;
    _errorMessage = null;
    await _clearSavedAuth(notify: false);
    _phase = AppSessionPhase.enterServer;
    notifyListeners();
  }

  void dismissError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _restorePersistedSession() async {
    final serverUrl = _serverUrl;
    final token = _accessToken;
    if (serverUrl == null || token == null) {
      _phase = AppSessionPhase.enterServer;
      notifyListeners();
      return;
    }

    try {
      final authenticatedClient = _authClientFactory(
        baseUrl: serverUrl,
        clientInfo: _clientInfo!,
        accessToken: token,
      );

      _serverInfo = await authenticatedClient.getPublicSystemInfo();
      _user = await authenticatedClient.getCurrentUser();
      _phase = AppSessionPhase.loggedIn;
      notifyListeners();
    } catch (_) {
      _user = null;
      _accessToken = null;
      await _clearSavedAuth(notify: false);
      _phase = AppSessionPhase.enterServer;
      _errorMessage = 'Saved session expired. Sign in again.';
      notifyListeners();
    }
  }

  Future<void> _restoreServerContext() async {
    final serverUrl = _serverUrl;
    if (serverUrl == null) {
      _phase = AppSessionPhase.enterServer;
      notifyListeners();
      return;
    }

    try {
      final client = _anonymousClient(serverUrl);
      _serverInfo = await client.getPublicSystemInfo();
      _phase = AppSessionPhase.enterCredentials;
      notifyListeners();
    } catch (_) {
      _serverInfo = null;
      _phase = AppSessionPhase.enterServer;
      _errorMessage = 'Saved server URL could not be reached.';
      notifyListeners();
    }
  }

  Future<void> _clearSavedAuth({required bool notify}) async {
    await _preferences?.remove(_tokenKey);
    await _preferences?.remove(_userIdKey);
    await _preferences?.remove(_userNameKey);
    if (notify) {
      notifyListeners();
    }
  }

  AppSessionAuthClient _anonymousClient(String baseUrl) {
    return _authClientFactory(
      baseUrl: baseUrl,
      clientInfo: _clientInfo!,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await initialize();
  }

  String _normalizeServerUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  String get _platformDeviceName => switch (currentAppPlatform) {
        AppPlatform.linux => 'Linux',
        AppPlatform.windows => 'Windows',
        AppPlatform.cupertino => switch (defaultTargetPlatform) {
            TargetPlatform.android => 'Android',
            TargetPlatform.iOS => 'iPhone',
            TargetPlatform.macOS => 'macOS',
            _ => 'Apple Device',
          },
        AppPlatform.material => 'Flutter',
      };

  String _generateDeviceId() {
    final random = Random();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final salt = random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'aetherfin-$timestamp-$salt';
  }

  String _mapLoginError(ApiException error) {
    return switch (error.statusCode) {
      401 => 'Invalid username or password.',
      403 => 'This user is not allowed to sign in.',
      408 => 'The server took too long to respond.',
      429 => 'Too many requests. Try again in a moment.',
      _ => 'Login failed. Check the server and try again.',
    };
  }
}
