import 'package:flutter/widgets.dart';

abstract class PlayerPlaybackAdapter extends ChangeNotifier {
  bool get isInitialized;
  bool get isPlaying;
  bool get hasError;
  String? get errorDescription;
  Duration get position;
  Duration get duration;
  double? get aspectRatio;

  Future<void> open(
    Uri uri, {
    Duration startPosition = Duration.zero,
    bool autoplay = true,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Widget buildView({BoxFit fit = BoxFit.contain});

  Future<void> disposeAdapter();
}
