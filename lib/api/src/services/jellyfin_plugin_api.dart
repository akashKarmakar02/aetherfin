import '../models/jellyfin_models.dart';
import '../models/plugin_settings.dart';
import 'jellyfin_api_base.dart';

class JellyfinPluginApi extends JellyfinApiBase {
  JellyfinPluginApi({
    required super.baseUrl,
    required super.clientInfo,
    required super.accessToken,
    super.dio,
  });

  Future<StreamyfinPluginConfig> getStreamyfinPluginConfig() async {
    final response = await client.get<Map<String, dynamic>>(
      '/Streamyfin/config',
      options: jellyfinOptions(),
    );
    return StreamyfinPluginConfig.fromJson(response.data ?? {});
  }

  Future<void> deleteDeviceRegistration(String deviceId) async {
    await client.delete<void>(
      '/Streamyfin/device/$deviceId',
      options: jellyfinOptions(),
    );
  }

  Future<void> deleteStreamyfinDevice(String deviceId) {
    return deleteDeviceRegistration(deviceId);
  }

  Future<List<JellyfinPluginInfo>> getPlugins() async {
    final response = await client.get<List<dynamic>>(
      '/Plugins',
      options: jellyfinOptions(),
    );
    final data = response.data ?? const [];
    return data
        .whereType<Map>()
        .map((item) => JellyfinPluginInfo.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<bool> hasMediaBarPlugin() async {
    final plugins = await getPlugins();
    return plugins.any((plugin) {
      final values = [
        plugin.name,
        plugin.id,
        plugin.configurationFileName,
      ].whereType<String>().map((value) => value.toLowerCase());
      return values.any(
        (value) =>
            value.contains('media bar') ||
            value.contains('mediabar') ||
            value.contains('media-bar'),
      );
    });
  }
}
