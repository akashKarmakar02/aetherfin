import 'package:flutter/material.dart';

import '../../../app/platform/app_platform.dart';
import '../../player/player_navigation.dart';
import '../../series/series_navigation.dart';
import '../models/home_media_bar_view_data.dart';

class HomeContinueWatchingSection extends StatelessWidget {
  const HomeContinueWatchingSection({super.key, required this.entries});

  final List<HomeMediaBarEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isMobileCupertino =
        currentAppPlatform == AppPlatform.cupertino &&
        MediaQuery.sizeOf(context).width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMobileCupertino
              ? 'Continue Watching on Jellyfin  >'
              : 'Continue Watching',
          style:
              (isMobileCupertino
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: isMobileCupertino ? 12 : 14),
        SizedBox(
          height: isMobileCupertino ? 154 : 174,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                SizedBox(width: isMobileCupertino ? 12 : 16),
            itemBuilder: (context, index) {
              return _ContinueWatchingCard(entry: entries[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingCard extends StatefulWidget {
  const _ContinueWatchingCard({required this.entry});

  final HomeMediaBarEntry entry;

  @override
  State<_ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<_ContinueWatchingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playedPercentage = _playedPercentage(widget.entry);
    final isMobileCupertino =
        currentAppPlatform == AppPlatform.cupertino &&
        MediaQuery.sizeOf(context).width < 700;
    final artworkUrl =
        widget.entry.posterUrl ??
        widget.entry.primaryUrl ??
        widget.entry.backdropUrl;
    final baseTitleStyle =
        (isMobileCupertino
                ? theme.textTheme.bodyMedium
                : theme.textTheme.titleMedium)
            ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    final hoveredTitleStyle = baseTitleStyle.copyWith(
      fontSize: (baseTitleStyle.fontSize ?? (isMobileCupertino ? 14 : 16)) +
          (isMobileCupertino ? 1.5 : 3),
      letterSpacing: -0.2,
    );
    final baseProgressHeight = isMobileCupertino ? 3.0 : 4.0;
    final hoveredProgressHeight = isMobileCupertino ? 5.0 : 6.0;
    final navigationTarget = seriesNavigationTargetForItem(widget.entry.item);

    return MouseRegion(
      cursor: navigationTarget != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: navigationTarget == null
            ? null
            : () => pushSeriesDetailsForItem(context, widget.entry.item),
        child: SizedBox(
          width: isMobileCupertino ? 240 : 270,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobileCupertino ? 12 : 20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Colors.white.withValues(alpha: 0.06),
                  child: artworkUrl != null
                      ? Image.network(
                          artworkUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : null,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: 13,
                  right: 13,
                  bottom: _isHovered
                      ? (isMobileCupertino ? 18 : 26)
                      : (isMobileCupertino ? 16 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        style: _isHovered ? hoveredTitleStyle : baseTitleStyle,
                        child: Text(
                          widget.entry.item.name ?? 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMobileCupertino)
                        Text(
                          'Recently Added',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: 13,
                  right: 13,
                  bottom: _isHovered ? 14 : 16,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: _isHovered
                          ? hoveredProgressHeight
                          : baseProgressHeight,
                    ),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (context, progressHeight, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: progressHeight,
                          value: playedPercentage.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(
                            alpha: _isHovered ? 0.26 : 0.18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.42),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.entry.item.id == null
                        ? null
                        : () => pushPlayerForItem(context, widget.entry.item),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _playedPercentage(HomeMediaBarEntry entry) {
  final userData = entry.item.raw['UserData'];
  if (userData is! Map) return 0;

  final percentage = userData['PlayedPercentage'];
  if (percentage is num) {
    return percentage / 100;
  }

  final playbackTicks = userData['PlaybackPositionTicks'];
  final runtimeTicks = entry.item.raw['RunTimeTicks'];
  if (playbackTicks is num && runtimeTicks is num && runtimeTicks > 0) {
    return playbackTicks / runtimeTicks;
  }

  return 0;
}
