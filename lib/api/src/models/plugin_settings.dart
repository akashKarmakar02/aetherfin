class LockableSetting<T> {
  LockableSetting({
    required this.locked,
    required this.value,
  });

  final bool locked;
  final T value;

  factory LockableSetting.fromJson(Map<String, dynamic> json) {
    return LockableSetting<T>(
      locked: json['locked'] == true,
      value: json['value'] as T,
    );
  }
}

class StreamyfinPluginConfig {
  StreamyfinPluginConfig({required this.settings});

  final Map<String, LockableSetting<dynamic>> settings;

  factory StreamyfinPluginConfig.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    final settings = <String, LockableSetting<dynamic>>{};
    if (rawSettings is Map) {
      for (final entry in rawSettings.entries) {
        if (entry.value is Map) {
          settings[entry.key.toString()] = LockableSetting<dynamic>.fromJson(
            (entry.value as Map).cast<String, dynamic>(),
          );
        }
      }
    }
    return StreamyfinPluginConfig(settings: settings);
  }

  LockableSetting<T>? setting<T>(String key) {
    final setting = settings[key];
    if (setting == null) {
      return null;
    }
    return LockableSetting<T>(
      locked: setting.locked,
      value: setting.value as T,
    );
  }

  LockableSetting<String>? get marlinServerUrl => setting<String>(
        'marlinServerUrl',
      );

  LockableSetting<String>? get streamyStatsServerUrl => setting<String>(
        'streamyStatsServerUrl',
      );

  LockableSetting<String>? get jellyseerrServerUrl => setting<String>(
        'jellyseerrServerUrl',
      );

  LockableSetting<String>? get searchEngine => setting<String>('searchEngine');
}
