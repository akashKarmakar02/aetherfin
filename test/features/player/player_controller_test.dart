import 'package:aetherfin/api/api.dart';
import 'package:aetherfin/features/player/data/player_data_source.dart';
import 'package:aetherfin/features/player/models/player_view_data.dart';
import 'package:aetherfin/features/player/playback/player_playback_adapter.dart';
import 'package:aetherfin/features/player/player_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerController', () {
    test('initial load opens the stream at the Jellyfin resume position', () async {
      final loader = _FakePlayerDataSource(
        loadResult: _viewData(
          streamUrl: 'https://example.com/stream-1.m3u8',
          startPositionTicks: 450000000,
        ),
      );
      final playback = _FakePlaybackAdapter();
      final controller = PlayerController(
        itemId: 'episode-1',
        loader: loader,
        playbackAdapter: playback,
      );

      await controller.initialize();

      expect(playback.openedUris, [Uri.parse('https://example.com/stream-1.m3u8')]);
      expect(playback.lastStartPosition, const Duration(seconds: 45));
      expect(playback.isPlaying, isTrue);
      expect(loader.startedReports, hasLength(1));
      await controller.close();
    });

    test('audio switching reloads the stream and preserves playback position', () async {
      final initial = _viewData(
        streamUrl: 'https://example.com/stream-1.m3u8',
        selectedAudioStreamIndex: 0,
      );
      final reloaded = _viewData(
        streamUrl: 'https://example.com/stream-2.m3u8',
        selectedAudioStreamIndex: 2,
        selectedSubtitleStreamIndex: -1,
      );
      final loader = _FakePlayerDataSource(
        loadResult: initial,
        reloadResult: reloaded,
      );
      final playback = _FakePlaybackAdapter();
      final controller = PlayerController(
        itemId: 'episode-1',
        loader: loader,
        playbackAdapter: playback,
      );
      await controller.initialize();

      playback.setPosition(const Duration(minutes: 3, seconds: 12));
      await controller.selectAudioStream(2);

      expect(loader.lastReloadAudioStreamIndex, 2);
      expect(loader.lastReloadStartPositionTicks, 1920000000);
      expect(playback.openedUris.last, Uri.parse('https://example.com/stream-2.m3u8'));
      expect(playback.lastStartPosition, const Duration(minutes: 3, seconds: 12));
      expect(controller.viewData?.selectedAudioStreamIndex, 2);
      await controller.close();
    });

    test('subtitle switch failures keep current playback and surface a message', () async {
      final loader = _FakePlayerDataSource(
        loadResult: _viewData(streamUrl: 'https://example.com/stream-1.m3u8'),
        reloadError: StateError('switch failed'),
      );
      final playback = _FakePlaybackAdapter();
      final controller = PlayerController(
        itemId: 'episode-1',
        loader: loader,
        playbackAdapter: playback,
      );
      await controller.initialize();

      await controller.selectSubtitleStream(8);

      expect(
        controller.message,
        'Could not switch streams. Playback kept the previous selection.',
      );
      expect(playback.openedUris, hasLength(1));
      await controller.close();
    });
  });
}

class _FakePlayerDataSource implements PlayerDataSource {
  _FakePlayerDataSource({
    required this.loadResult,
    this.reloadResult,
    this.reloadError,
  });

  final PlayerViewData loadResult;
  final PlayerViewData? reloadResult;
  final Object? reloadError;
  final List<JellyfinPlaybackReport> startedReports = [];
  final List<JellyfinPlaybackReport> progressReports = [];
  final List<JellyfinPlaybackReport> stoppedReports = [];
  int? lastReloadAudioStreamIndex;
  int? lastReloadSubtitleStreamIndex;
  int? lastReloadStartPositionTicks;

  @override
  Future<PlayerViewData> load(String itemId) async => loadResult;

  @override
  Future<PlayerViewData> reloadStream({
    required PlayerViewData current,
    required int startPositionTicks,
    required int audioStreamIndex,
    required int subtitleStreamIndex,
  }) async {
    lastReloadAudioStreamIndex = audioStreamIndex;
    lastReloadSubtitleStreamIndex = subtitleStreamIndex;
    lastReloadStartPositionTicks = startPositionTicks;
    if (reloadError != null) {
      throw reloadError!;
    }
    return reloadResult ?? current;
  }

  @override
  Future<void> reportPlaybackProgress(JellyfinPlaybackReport report) async {
    progressReports.add(report);
  }

  @override
  Future<void> reportPlaybackStarted(JellyfinPlaybackReport report) async {
    startedReports.add(report);
  }

  @override
  Future<void> reportPlaybackStopped(JellyfinPlaybackReport report) async {
    stoppedReports.add(report);
  }
}

class _FakePlaybackAdapter extends PlayerPlaybackAdapter {
  final List<Uri> openedUris = [];
  Duration lastStartPosition = Duration.zero;
  bool disposed = false;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(hours: 1);

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get hasError => false;

  @override
  String? get errorDescription => null;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  double? get aspectRatio => 16 / 9;

  @override
  Future<void> open(
    Uri uri, {
    Duration startPosition = Duration.zero,
    bool autoplay = true,
  }) async {
    openedUris.add(uri);
    lastStartPosition = startPosition;
    _isInitialized = true;
    _position = startPosition;
    _isPlaying = autoplay;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _position = position;
    notifyListeners();
  }

  void setPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  @override
  Widget buildView({BoxFit fit = BoxFit.contain}) {
    return const SizedBox(key: Key('fake_player_view'));
  }

  @override
  Future<void> disposeAdapter() async {
    disposed = true;
  }
}

PlayerViewData _viewData({
  required String streamUrl,
  int startPositionTicks = 0,
  int selectedAudioStreamIndex = 0,
  int selectedSubtitleStreamIndex = -1,
}) {
  return PlayerViewData(
    requestedItemId: 'episode-1',
    item: JellyfinBaseItem(id: 'episode-1', type: 'Episode', name: 'Episode 1'),
    streamUrl: streamUrl,
    mediaSource: JellyfinMediaSourceInfo(
      id: 'source-1',
      mediaStreams: [
        JellyfinMediaStreamInfo(
          index: 0,
          type: JellyfinMediaStreamType.audio,
        ),
        JellyfinMediaStreamInfo(
          index: 2,
          type: JellyfinMediaStreamType.audio,
        ),
        JellyfinMediaStreamInfo(
          index: 8,
          type: JellyfinMediaStreamType.subtitle,
        ),
      ],
    ),
    playSessionId: 'play-1',
    startPositionTicks: startPositionTicks,
    selectedAudioStreamIndex: selectedAudioStreamIndex,
    selectedSubtitleStreamIndex: selectedSubtitleStreamIndex,
  );
}
