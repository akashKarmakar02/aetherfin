import '../../../api/api.dart';
import '../models/player_view_data.dart';

abstract class PlayerDataSource {
  Future<PlayerViewData> load(String itemId);

  Future<PlayerViewData> reloadStream({
    required PlayerViewData current,
    required int startPositionTicks,
    required int audioStreamIndex,
    required int subtitleStreamIndex,
  });

  Future<void> reportPlaybackStarted(JellyfinPlaybackReport report);

  Future<void> reportPlaybackProgress(JellyfinPlaybackReport report);

  Future<void> reportPlaybackStopped(JellyfinPlaybackReport report);
}
