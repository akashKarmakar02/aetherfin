import '../../../api/api.dart';

class PlayerViewData {
  const PlayerViewData({
    required this.requestedItemId,
    required this.item,
    required this.streamUrl,
    required this.mediaSource,
    required this.playSessionId,
    required this.startPositionTicks,
    required this.selectedAudioStreamIndex,
    required this.selectedSubtitleStreamIndex,
  });

  final String requestedItemId;
  final JellyfinBaseItem item;
  final String streamUrl;
  final JellyfinMediaSourceInfo mediaSource;
  final String? playSessionId;
  final int startPositionTicks;
  final int selectedAudioStreamIndex;
  final int selectedSubtitleStreamIndex;

  List<JellyfinMediaStreamInfo> get audioStreams => mediaSource.audioStreams;
  List<JellyfinMediaStreamInfo> get subtitleStreams => mediaSource.subtitleStreams;

  String get playMethod => mediaSource.isTranscoding ? 'Transcode' : 'DirectPlay';

  PlayerViewData copyWith({
    String? streamUrl,
    JellyfinMediaSourceInfo? mediaSource,
    String? playSessionId,
    int? startPositionTicks,
    int? selectedAudioStreamIndex,
    int? selectedSubtitleStreamIndex,
  }) {
    return PlayerViewData(
      requestedItemId: requestedItemId,
      item: item,
      streamUrl: streamUrl ?? this.streamUrl,
      mediaSource: mediaSource ?? this.mediaSource,
      playSessionId: playSessionId ?? this.playSessionId,
      startPositionTicks: startPositionTicks ?? this.startPositionTicks,
      selectedAudioStreamIndex:
          selectedAudioStreamIndex ?? this.selectedAudioStreamIndex,
      selectedSubtitleStreamIndex:
          selectedSubtitleStreamIndex ?? this.selectedSubtitleStreamIndex,
    );
  }
}
