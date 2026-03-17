import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'player_playback_adapter.dart';

class VideoPlayerPlaybackAdapter extends PlayerPlaybackAdapter {
  VideoPlayerController? _controller;

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  bool get hasError => _controller?.value.hasError ?? false;

  @override
  String? get errorDescription => _controller?.value.errorDescription;

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  double? get aspectRatio {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) {
      return null;
    }
    final ratio = value.aspectRatio;
    if (!ratio.isFinite || ratio <= 0) {
      return null;
    }
    return ratio;
  }

  @override
  Future<void> open(
    Uri uri, {
    Duration startPosition = Duration.zero,
    bool autoplay = true,
  }) async {
    final previous = _controller;
    final next = VideoPlayerController.networkUrl(uri);
    next.addListener(_handleControllerChanged);

    try {
      await next.initialize();
      if (startPosition > Duration.zero) {
        await next.seekTo(startPosition);
      }
      if (autoplay) {
        await next.play();
      }
    } catch (_) {
      next.removeListener(_handleControllerChanged);
      await next.dispose();
      rethrow;
    }

    _controller = next;
    if (previous != null) {
      previous.removeListener(_handleControllerChanged);
      await previous.dispose();
    }
    notifyListeners();
  }

  @override
  Future<void> play() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.play();
  }

  @override
  Future<void> pause() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.seekTo(position);
  }

  @override
  Widget buildView({BoxFit fit = BoxFit.contain}) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final size = controller.value.size;
    final safeWidth = size.width > 0 ? size.width : 16.0;
    final safeHeight = size.height > 0 ? size.height : 9.0;

    return Center(
      child: ClipRect(
        child: FittedBox(
          fit: fit,
          child: SizedBox(
            width: safeWidth,
            height: safeHeight,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> disposeAdapter() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) {
      return;
    }
    controller.removeListener(_handleControllerChanged);
    await controller.dispose();
  }

  void _handleControllerChanged() {
    notifyListeners();
  }
}
