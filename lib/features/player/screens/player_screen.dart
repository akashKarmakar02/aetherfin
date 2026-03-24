import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru_window/yaru_window.dart';

import '../../../api/api.dart';
import '../../../app/session/app_session_scope.dart';
import '../data/player_loader.dart';
import '../models/player_view_data.dart';
import '../player_controller.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  PlayerController? _controller;
  final FocusNode _focusNode = FocusNode(debugLabel: 'player_screen');
  String? _sessionKey;
  bool _isVideoFullscreen = false;
  Offset? _lastPointerPosition;
  YaruWindowInstance? _window;

  @override
  void initState() {
    super.initState();
    _setFullscreenSystemUi(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isMobileOs) {
      _window ??= YaruWindow.of(context);
    }
    final session = AppSessionScope.watch(context);
    final nextSessionKey = [
      session.serverUrl,
      session.accessToken,
      session.user?.id,
      widget.itemId,
    ].join('|');
    if (nextSessionKey == _sessionKey) {
      return;
    }

    _sessionKey = nextSessionKey;
    unawaited(_controller?.close());
    final controller = PlayerController(
      itemId: widget.itemId,
      loader: PlayerLoader.fromSession(session),
    );
    _controller = controller;
    unawaited(controller.initialize());
  }

  @override
  void dispose() {
    _setFullscreenSystemUi(false);
    if (!_isMobileOs && _isVideoFullscreen) {
      unawaited(_window?.restore());
    }
    _focusNode.dispose();
    unawaited(_controller?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        final title = viewData?.item.name ?? 'Player';

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyF): () {
              unawaited(_toggleFullscreen());
            },
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_isVideoFullscreen) {
                unawaited(_exitFullscreen());
              }
            },
          },
          child: PopScope(
            canPop: !_isVideoFullscreen,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && _isVideoFullscreen) {
                unawaited(_closePlayer());
              }
            },
            child: Focus(
              autofocus: true,
              focusNode: _focusNode,
              child: Material(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: controller.toggleControls,
                      child: MouseRegion(
                        onEnter: (_) {
                          _handlePointerActivity(controller);
                        },
                        onHover: (event) {
                          _handlePointerActivity(
                            controller,
                            position: event.position,
                          );
                        },
                        onExit: (_) {
                          _lastPointerPosition = null;
                        },
                        child: Listener(
                          onPointerDown: (event) {
                            _handlePointerActivity(
                              controller,
                              position: event.position,
                              force: true,
                            );
                          },
                          onPointerSignal: (_) {
                            _handlePointerActivity(controller, force: true);
                          },
                          child: ColoredBox(
                            color: Colors.black,
                            child: viewData == null
                                ? const SizedBox.shrink()
                                : controller.playbackAdapter.buildView(),
                          ),
                        ),
                      ),
                    ),
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (controller.error != null && viewData == null)
                      _PlayerErrorOverlay(
                        onRetry: controller.retry,
                        onClose: () => unawaited(_closePlayer()),
                      ),
                    if (controller.showControls && viewData != null)
                      _PlayerControlsOverlay(
                        title: title,
                        controller: controller,
                        isFullscreen: _isVideoFullscreen,
                        onToggleFullscreen: _toggleFullscreen,
                        onClose: _closePlayer,
                      ),
                    if (controller.message != null)
                      Positioned(
                        top: MediaQuery.viewPaddingOf(context).top + 20,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                controller.message!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFullscreen() async {
    if (_isVideoFullscreen) {
      await _exitFullscreen();
      return;
    }
    await _enterFullscreen();
  }

  Future<void> _enterFullscreen() async {
    if (_isMobileOs) {
      _setFullscreenSystemUi(true);
    } else {
      final window = YaruWindow.of(context);
      await window.fullscreen();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isVideoFullscreen = true;
    });
    _controller?.revealControls();
    _focusNode.requestFocus();
  }

  Future<void> _exitFullscreen() async {
    if (_isMobileOs) {
      _setFullscreenSystemUi(false);
    } else {
      final window = YaruWindow.of(context);
      await window.restore();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isVideoFullscreen = false;
    });
    _controller?.revealControls();
    _focusNode.requestFocus();
  }

  Future<void> _closePlayer() async {
    if (_isVideoFullscreen) {
      await _exitFullscreen();
    }
    if (!mounted) {
      return;
    }
    GoRouter.of(context).pop();
  }

  void _handlePointerActivity(
    PlayerController controller, {
    Offset? position,
    bool force = false,
  }) {
    final lastPosition = _lastPointerPosition;
    final hasMoved =
        force ||
        position == null ||
        lastPosition == null ||
        (position - lastPosition).distanceSquared > 1;
    _lastPointerPosition = position ?? lastPosition;
    if (!hasMoved) {
      return;
    }
    controller.revealControls();
    _focusNode.requestFocus();
  }

  void _setFullscreenSystemUi(bool fullscreen) {
    if (!_isMobileOs) {
      return;
    }
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  bool get _isMobileOs =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

class _PlayerControlsOverlay extends StatelessWidget {
  const _PlayerControlsOverlay({
    required this.title,
    required this.controller,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.onClose,
  });

  final String title;
  final PlayerController controller;
  final bool isFullscreen;
  final Future<void> Function() onToggleFullscreen;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top + 16;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 16;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.62),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.72),
          ],
          stops: const [0, 0.35, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _PlayerIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => unawaited(onClose()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _PlayerIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () => _showSettingsSheet(context),
                ),
                const SizedBox(width: 8),
                _PlayerIconButton(
                  icon: isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  onPressed: () => unawaited(onToggleFullscreen()),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _PlayerIconButton(
                  icon: controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  onPressed: controller.togglePlayback,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(controller.position),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.24),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: controller.duration.inMilliseconds == 0
                          ? 0
                          : controller.position.inMilliseconds.clamp(
                                  0,
                                  controller.duration.inMilliseconds,
                                ) /
                                controller.duration.inMilliseconds,
                      onChanged: (value) {
                        final nextPosition = Duration(
                          milliseconds:
                              (controller.duration.inMilliseconds * value)
                                  .round(),
                        );
                        controller.seek(nextPosition);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(controller.duration),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettingsSheet(BuildContext context) async {
    final viewData = controller.viewData;
    if (viewData == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111214),
      barrierColor: Colors.black.withValues(alpha: 0.5),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playback options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Change audio and subtitle tracks for the current stream.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 16),
                _StreamSettingsGroup(
                  children: [
                    _StreamSettingsEntry(
                      icon: Icons.volume_up_rounded,
                      title: 'Audio',
                      subtitle: _selectedAudioLabel(viewData),
                      onTap: () => _showAudioSelectionSheet(context),
                    ),
                    _StreamSettingsEntry(
                      icon: Icons.subtitles_rounded,
                      title: 'Subtitles',
                      subtitle: _selectedSubtitleLabel(viewData),
                      onTap: () => _showSubtitleSelectionSheet(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAudioSelectionSheet(BuildContext context) async {
    final viewData = controller.viewData;
    if (viewData == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111214),
      barrierColor: Colors.black.withValues(alpha: 0.5),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionSheetHeader(
                title: 'Audio',
                subtitle: 'Choose the audio track for this playback session.',
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final stream in viewData.audioStreams)
                      _SettingsOptionTile(
                        label: _streamPrimaryLabel(
                          stream,
                          fallback: 'Audio ${stream.index ?? 0}',
                        ),
                        detail: _audioStreamDetail(stream),
                        selected:
                            controller.viewData?.selectedAudioStreamIndex ==
                            stream.index,
                        onTap: () async {
                          final value = stream.index;
                          if (value == null) {
                            return;
                          }
                          Navigator.of(context).pop();
                          await controller.selectAudioStream(value);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSubtitleSelectionSheet(BuildContext context) async {
    final viewData = controller.viewData;
    if (viewData == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111214),
      barrierColor: Colors.black.withValues(alpha: 0.5),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionSheetHeader(
                title: 'Subtitles',
                subtitle: 'Choose subtitles for this playback session.',
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _SettingsOptionTile(
                      label: 'Off',
                      detail: 'Disable subtitles',
                      selected:
                          controller.viewData?.selectedSubtitleStreamIndex ==
                          -1,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await controller.selectSubtitleStream(-1);
                      },
                    ),
                    for (final stream in viewData.subtitleStreams)
                      _SettingsOptionTile(
                        label: _streamPrimaryLabel(
                          stream,
                          fallback: 'Subtitle ${stream.index ?? 0}',
                        ),
                        detail: _subtitleStreamDetail(stream),
                        selected:
                            controller.viewData?.selectedSubtitleStreamIndex ==
                            stream.index,
                        onTap: () async {
                          final value = stream.index;
                          if (value == null) {
                            return;
                          }
                          Navigator.of(context).pop();
                          await controller.selectSubtitleStream(value);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _selectedAudioLabel(PlayerViewData viewData) {
    final stream = viewData.audioStreams.firstWhere(
      (entry) => entry.index == viewData.selectedAudioStreamIndex,
      orElse: () => JellyfinMediaStreamInfo(index: viewData.selectedAudioStreamIndex),
    );
    return _streamPrimaryLabel(
      stream,
      fallback: 'Audio ${viewData.selectedAudioStreamIndex}',
    );
  }

  String _selectedSubtitleLabel(PlayerViewData viewData) {
    if (viewData.selectedSubtitleStreamIndex == -1) {
      return 'Off';
    }
    final stream = viewData.subtitleStreams.firstWhere(
      (entry) => entry.index == viewData.selectedSubtitleStreamIndex,
      orElse: () =>
          JellyfinMediaStreamInfo(index: viewData.selectedSubtitleStreamIndex),
    );
    return _streamPrimaryLabel(
      stream,
      fallback: 'Subtitle ${viewData.selectedSubtitleStreamIndex}',
    );
  }
}

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.38),
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: size),
    );
  }
}

class _PlayerErrorOverlay extends StatelessWidget {
  const _PlayerErrorOverlay({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF15171B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playback could not start.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Check the item stream, your network, or the Jellyfin playback configuration.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                    OutlinedButton(
                      onPressed: onClose,
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  const _SettingsOptionTile({
    required this.label,
    this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: detail == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                detail!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 13,
                ),
              ),
            ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: Colors.white)
          : null,
    );
  }
}

class _SelectionSheetHeader extends StatelessWidget {
  const _SelectionSheetHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamSettingsGroup extends StatelessWidget {
  const _StreamSettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class _StreamSettingsEntry extends StatelessWidget {
  const _StreamSettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withValues(alpha: 0.54),
      ),
      onTap: onTap,
    );
  }
}

String _streamPrimaryLabel(
  JellyfinMediaStreamInfo stream, {
  required String fallback,
}) {
  return stream.title ??
      stream.language?.toUpperCase() ??
      stream.displayTitle ??
      fallback;
}

String _audioStreamDetail(JellyfinMediaStreamInfo stream) {
  final parts = <String>[
    if ((stream.displayTitle ?? '').isNotEmpty) stream.displayTitle!,
    if ((stream.codec ?? '').isNotEmpty) stream.codec!.toUpperCase(),
    if ((stream.channelLayout ?? '').isNotEmpty) stream.channelLayout!,
    if (stream.isDefault) 'Default',
  ];
  return parts.join(' • ');
}

String _subtitleStreamDetail(JellyfinMediaStreamInfo stream) {
  final parts = <String>[
    if ((stream.displayTitle ?? '').isNotEmpty) stream.displayTitle!,
    if (stream.isForced) 'Forced',
    if (stream.isExternal) 'External',
    if (stream.isDefault) 'Default',
  ];
  return parts.join(' • ');
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '${duration.inMinutes.remainder(60)}:$seconds';
}
