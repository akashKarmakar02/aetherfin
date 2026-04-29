import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../api/api.dart';
import 'data/player_data_source.dart';
import 'models/player_view_data.dart';
import 'playback/player_playback_adapter.dart';
import 'playback/video_player_playback_adapter.dart';

class PlayerController extends ChangeNotifier {
  static const Duration _positionUiUpdateInterval = Duration(milliseconds: 250);

  PlayerController({
    required this.itemId,
    required PlayerDataSource loader,
    PlayerPlaybackAdapter? playbackAdapter,
  }) : _loader = loader,
       _playbackAdapter = playbackAdapter ?? VideoPlayerPlaybackAdapter() {
    _playbackAdapter.addListener(_handlePlaybackChanged);
  }

  final String itemId;
  final PlayerDataSource _loader;
  final PlayerPlaybackAdapter _playbackAdapter;
  Timer? _controlsTimer;
  Timer? _reportingTimer;

  PlayerViewData? _viewData;
  Object? _error;
  String? _message;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _lastUiNotifiedPosition = Duration.zero;
  bool _didSendStarted = false;
  bool _isClosed = false;

  PlayerViewData? get viewData => _viewData;
  Object? get error => _error;
  String? get message => _message;
  bool get isLoading => _isLoading;
  bool get showControls => _showControls;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  PlayerPlaybackAdapter get playbackAdapter => _playbackAdapter;

  Future<void> initialize() async {
    await _load();
  }

  Future<void> retry() => _load();

  void revealControls() {
    final wasHidden = !_showControls;
    _showControls = true;
    _scheduleControlsHide();
    if (wasHidden) {
      notifyListeners();
    }
  }

  void toggleControls() {
    _showControls = !_showControls;
    if (_showControls) {
      _scheduleControlsHide();
    } else {
      _controlsTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> togglePlayback() async {
    if (_isPlaying) {
      await _playbackAdapter.pause();
      await _reportProgress(isPaused: true);
    } else {
      await _playbackAdapter.play();
      revealControls();
      await _reportProgress(isPaused: false);
    }
  }

  Future<void> seek(Duration nextPosition) async {
    await _playbackAdapter.seekTo(nextPosition);
    _position = nextPosition;
    _lastUiNotifiedPosition = nextPosition;
    notifyListeners();
    await _reportProgress();
  }

  Future<void> selectAudioStream(int audioStreamIndex) async {
    final current = _viewData;
    if (current == null ||
        current.selectedAudioStreamIndex == audioStreamIndex) {
      return;
    }

    await _switchStream(
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: current.selectedSubtitleStreamIndex,
    );
  }

  Future<void> selectSubtitleStream(int subtitleStreamIndex) async {
    final current = _viewData;
    if (current == null ||
        current.selectedSubtitleStreamIndex == subtitleStreamIndex) {
      return;
    }
    await _switchStream(
      audioStreamIndex: current.selectedAudioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }
    _message = null;
    notifyListeners();
  }

  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    await _reportStopped();
    _controlsTimer?.cancel();
    _reportingTimer?.cancel();
    _playbackAdapter.removeListener(_handlePlaybackChanged);
    await _playbackAdapter.disposeAdapter();
    super.dispose();
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    _message = null;
    notifyListeners();

    try {
      final data = await _loader.load(itemId);
      _viewData = data;
      await _openCurrentStream(
        startPositionTicks: data.startPositionTicks,
        reportStart: true,
      );
      _startReporting();
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _error = error;
      _viewData = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _switchStream({
    required int audioStreamIndex,
    required int subtitleStreamIndex,
  }) async {
    final current = _viewData;
    if (current == null) {
      return;
    }

    final resumeTicks = _ticksFromDuration(_position);
    try {
      final next = await _loader.reloadStream(
        current: current,
        startPositionTicks: resumeTicks,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
      );
      if (kDebugMode) {
        debugPrint(
          'Player stream URL after track change'
          ' [audio=$audioStreamIndex, subtitle=$subtitleStreamIndex]: '
          '${next.streamUrl}',
        );
      }
      _viewData = next;
      await _openCurrentStream(
        startPositionTicks: resumeTicks,
        reportStart: false,
      );
      _message = null;
      notifyListeners();
    } catch (_) {
      _message =
          'Could not switch streams. Playback kept the previous selection.';
      notifyListeners();
    }
  }

  Future<void> _openCurrentStream({
    required int startPositionTicks,
    required bool reportStart,
  }) async {
    final data = _viewData;
    if (data == null) {
      return;
    }

    _didSendStarted = false;
    await _playbackAdapter.open(
      Uri.parse(data.streamUrl),
      startPosition: _durationFromTicks(startPositionTicks),
      autoplay: true,
      audioStreamIndex: data.selectedAudioStreamIndex - 1,
      subtitleStreamIndex: data.selectedSubtitleStreamIndex,
      externalSubtitleUrl: data.externalSubtitleUrl,
    );
    revealControls();
    if (reportStart) {
      await _reportStarted();
    }
  }

  void _handlePlaybackChanged() {
    final wasPlaying = _isPlaying;
    final previousDuration = _duration;
    final previousPosition = _position;
    final previousMessage = _message;
    _isPlaying = _playbackAdapter.isPlaying;
    _position = _playbackAdapter.position;
    _duration = _playbackAdapter.duration;

    if (_playbackAdapter.hasError) {
      _message =
          _playbackAdapter.errorDescription ??
          'Playback encountered an unexpected error.';
    }

    if (!wasPlaying && _isPlaying) {
      revealControls();
      return;
    }

    final shouldNotifyForPosition =
        _showControls &&
        _position != previousPosition &&
        (_position - _lastUiNotifiedPosition).abs() >=
            _positionUiUpdateInterval;

    if (shouldNotifyForPosition) {
      _lastUiNotifiedPosition = _position;
    }

    if (_isPlaying != wasPlaying ||
        _duration != previousDuration ||
        _message != previousMessage ||
        shouldNotifyForPosition) {
      notifyListeners();
    }
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (!_isPlaying) {
        return;
      }
      _showControls = false;
      notifyListeners();
    });
  }

  void _startReporting() {
    _reportingTimer?.cancel();
    _reportingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportProgress();
    });
  }

  Future<void> _reportStarted() async {
    final report = _buildReport();
    if (report == null || _didSendStarted) {
      return;
    }
    _didSendStarted = true;
    try {
      await _loader.reportPlaybackStarted(report);
    } catch (_) {}
  }

  Future<void> _reportProgress({bool? isPaused}) async {
    final report = _buildReport(isPaused: isPaused ?? !_isPlaying);
    if (report == null) {
      return;
    }
    try {
      await _loader.reportPlaybackProgress(report);
    } catch (_) {}
  }

  Future<void> _reportStopped() async {
    final report = _buildReport(isPaused: true);
    if (report == null) {
      return;
    }
    try {
      await _loader.reportPlaybackStopped(report);
    } catch (_) {}
  }

  JellyfinPlaybackReport? _buildReport({bool isPaused = false}) {
    final data = _viewData;
    final itemId = data?.item.id;
    if (data == null || itemId == null) {
      return null;
    }
    return JellyfinPlaybackReport(
      itemId: itemId,
      mediaSourceId: data.mediaSource.id,
      playSessionId: data.playSessionId,
      positionTicks: _ticksFromDuration(_position),
      playbackStartTimeTicks: data.startPositionTicks,
      playMethod: data.playMethod,
      audioStreamIndex: data.selectedAudioStreamIndex,
      subtitleStreamIndex: data.selectedSubtitleStreamIndex,
      isPaused: isPaused,
    );
  }

  int _ticksFromDuration(Duration duration) {
    return duration.inMicroseconds * 10;
  }

  Duration _durationFromTicks(int ticks) {
    return Duration(microseconds: ticks ~/ 10);
  }
}
