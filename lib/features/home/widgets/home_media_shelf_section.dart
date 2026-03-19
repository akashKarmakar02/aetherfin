import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../player/player_navigation.dart';
import '../../series/series_navigation.dart';
import '../models/home_media_bar_view_data.dart';

class HomeMediaShelfSection extends StatelessWidget {
  const HomeMediaShelfSection({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
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
          title,
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
              return _HomeMediaShelfCard(entry: entries[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _HomeMediaShelfCard extends StatefulWidget {
  const _HomeMediaShelfCard({required this.entry});

  final HomeMediaBarEntry entry;

  @override
  State<_HomeMediaShelfCard> createState() => _HomeMediaShelfCardState();
}

class _HomeMediaShelfCardState extends State<_HomeMediaShelfCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.entry.item;
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
    final navigationTarget = seriesNavigationTargetForItem(item);
    final canOpenDetails = navigationTarget != null;
    final canPlay = (item.id ?? '').isNotEmpty && !item.isSeries;
    final onTap = canOpenDetails
        ? () => pushSeriesDetailsForItem(context, item)
        : canPlay
        ? () => pushPlayerForItem(context, item)
        : null;
    final onActionPressed = canPlay
        ? () => pushPlayerForItem(context, item)
        : canOpenDetails
        ? () => pushSeriesDetailsForItem(context, item)
        : null;
    final subtitle = _buildSubtitle(item);

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: onTap,
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
                          item.name ?? 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                    ],
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
                    onPressed: onActionPressed,
                    icon: Icon(
                      canPlay
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                    ),
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

String? _buildSubtitle(JellyfinBaseItem item) {
  final typeLabel = switch (item.type) {
    'Episode' => _buildEpisodeSubtitle(item),
    'Series' => _joinLabels(['Series', _yearLabel(item)]),
    'Movie' => _joinLabels(['Movie', _yearLabel(item)]),
    _ => _yearLabel(item),
  };

  return typeLabel;
}

String? _buildEpisodeSubtitle(JellyfinBaseItem item) {
  final episodeMarker = [
    if (item.parentIndexNumber != null) 'S${item.parentIndexNumber}',
    if (item.indexNumber != null) 'E${item.indexNumber}',
  ].join(' ');

  return _joinLabels([
    item.seriesName,
    if (episodeMarker.isNotEmpty) episodeMarker,
  ]);
}

String? _yearLabel(JellyfinBaseItem item) {
  final year = item.productionYear;
  if (year == null || year <= 0) {
    return null;
  }
  return '$year';
}

String? _joinLabels(List<String?> labels) {
  final filtered = labels
      .whereType<String>()
      .where((label) => label.isNotEmpty)
      .toList(growable: false);
  if (filtered.isEmpty) {
    return null;
  }
  return filtered.join(' • ');
}
