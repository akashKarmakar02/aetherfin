import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../player/player_navigation.dart';
import '../../series/series_navigation.dart';
import '../models/home_media_bar_view_data.dart';

enum HomeMediaBarMobileArtwork { primary, poster }

class HomeMediaBarCarousel extends StatefulWidget {
  const HomeMediaBarCarousel({
    super.key,
    required this.entries,
    this.source = JellyfinMediaBarSource.none,
    this.mobileArtwork = HomeMediaBarMobileArtwork.primary,
  });

  final List<HomeMediaBarEntry> entries;
  final JellyfinMediaBarSource source;
  final HomeMediaBarMobileArtwork mobileArtwork;

  @override
  State<HomeMediaBarCarousel> createState() => _HomeMediaBarCarouselState();
}

class _HomeMediaBarCarouselState extends State<HomeMediaBarCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HomeMediaBarCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length) {
      _currentIndex = 0;
      _pageController.jumpToPage(0);
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.entries.length < 2) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      final nextPage = (_currentIndex + 1) % widget.entries.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    if (entries.isEmpty) {
      return const _EmptyHero();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final isMobileCupertino =
            currentAppPlatform == AppPlatform.cupertino && compact;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(height: 250, width: 500),
            AspectRatio(
              aspectRatio: isMobileCupertino
                  ? 0.62
                  : compact
                  ? 16 / 10.4
                  : 16 / 8.6,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: entries.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _HeroCard(
                        entry: entries[index],
                        source: widget.source,
                        mobileArtwork: widget.mobileArtwork,
                      );
                    },
                  ),
                  if (entries.length > 1 && !isMobileCupertino) ...[
                    Positioned(
                      left: compact ? 8 : 16,
                      top: 0,
                      bottom: 0,
                      child: _HeroArrowButton(
                        icon: CupertinoIcons.chevron_left,
                        onPressed: () {
                          final previous =
                              (_currentIndex - 1 + entries.length) %
                              entries.length;
                          _pageController.animateToPage(
                            previous,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: compact ? 8 : 16,
                      top: 0,
                      bottom: 0,
                      child: _HeroArrowButton(
                        icon: CupertinoIcons.chevron_right,
                        onPressed: () {
                          final next = (_currentIndex + 1) % entries.length;
                          _pageController.animateToPage(
                            next,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 6,
                children: List.generate(
                  entries.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _currentIndex
                        ? (isMobileCupertino ? 16 : 18)
                        : 6,
                    height: isMobileCupertino ? 5 : 6,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.entry,
    required this.source,
    required this.mobileArtwork,
  });

  final HomeMediaBarEntry entry;
  final JellyfinMediaBarSource source;
  final HomeMediaBarMobileArtwork mobileArtwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = entry.item;
    final navigationTarget = seriesNavigationTargetForItem(item);
    final metadata = _formatMetadata(item);
    final genres = item.genres.take(3).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 260 || constraints.maxWidth < 520;
        final isMobileCupertino =
            currentAppPlatform == AppPlatform.cupertino &&
            constraints.maxWidth < 520;
        final ultraCompact = constraints.maxHeight < 210;
        final horizontalPadding = isMobileCupertino
            ? 14.0
            : compact
            ? 18.0
            : 34.0;
        final topPadding = isMobileCupertino
            ? 14.0
            : compact
            ? 18.0
            : 34.0;
        final bottomPadding = isMobileCupertino
            ? 18.0
            : compact
            ? 18.0
            : 28.0;
        final logoHeight = isMobileCupertino
            ? 58.0
            : ultraCompact
            ? 40.0
            : compact
            ? 54.0
            : 74.0;
        final titleStyle =
            (compact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium)
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700);
        final heroBackgroundColor = currentAppPlatform == AppPlatform.linux
            ? theme.colorScheme.surface
            : const Color(0xFF101115);
        final heroImageUrl = isMobileCupertino
            ? switch (mobileArtwork) {
                HomeMediaBarMobileArtwork.primary =>
                  entry.primaryUrl ?? entry.posterUrl ?? entry.backdropUrl,
                HomeMediaBarMobileArtwork.poster =>
                  entry.posterUrl ?? entry.primaryUrl ?? entry.backdropUrl,
              }
            : source == JellyfinMediaBarSource.list
            ? entry.backdropUrl
            : (entry.backdropUrl ?? entry.primaryUrl ?? entry.posterUrl);

        return MouseRegion(
          cursor: navigationTarget != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: GestureDetector(
            onTap: navigationTarget == null
                ? null
                : () => pushSeriesDetailsForItem(context, item),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobileCupertino ? 0 : 4,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isMobileCupertino ? 0 : 28),
                color: heroBackgroundColor,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (heroImageUrl != null)
                    Image.network(
                      heroImageUrl,
                      fit: BoxFit.cover,
                      alignment: isMobileCupertino
                          ? Alignment.topCenter
                          : Alignment.center,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: isMobileCupertino ? 0.04 : 0.10,
                          ),
                          Colors.black.withValues(
                            alpha: isMobileCupertino ? 0.72 : 0.80,
                          ),
                        ],
                        stops: const [0.25, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(
                            alpha: isMobileCupertino ? 0.46 : 0.82,
                          ),
                          Colors.transparent,
                        ],
                        stops: isMobileCupertino
                            ? const [0.12, 0.68]
                            : const [0, 0.62],
                      ),
                    ),
                  ),

                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: -2,
                    height: 4,
                    child: ColoredBox(color: Color(0xFF101315)),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.logoUrl != null)
                          Image.network(
                            entry.logoUrl!,
                            height: logoHeight,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (_, _, _) => Text(
                              item.name ?? 'Untitled',
                              style: titleStyle,
                            ),
                          )
                        else
                          Text(item.name ?? 'Untitled', style: titleStyle),
                        if (metadata.isNotEmpty) ...[
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            metadata,
                            textAlign: isMobileCupertino
                                ? TextAlign.center
                                : null,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: isMobileCupertino
                                  ? 11
                                  : compact
                                  ? 12
                                  : null,
                            ),
                          ),
                        ],
                        if (!ultraCompact &&
                            (item.overview ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobileCupertino
                                  ? constraints.maxWidth * 0.82
                                  : compact
                                  ? constraints.maxWidth * 0.72
                                  : 420,
                            ),
                            child: Text(
                              item.overview!,
                              textAlign: isMobileCupertino
                                  ? TextAlign.center
                                  : null,
                              maxLines: isMobileCupertino
                                  ? 2
                                  : compact
                                  ? 1
                                  : 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.94),
                                height: 1.45,
                                fontSize: isMobileCupertino
                                    ? 12
                                    : compact
                                    ? 13
                                    : null,
                              ),
                            ),
                          ),
                        ],
                        if (genres.isNotEmpty) ...[
                          SizedBox(height: isMobileCupertino ? 8 : 12),
                          Wrap(
                            alignment: isMobileCupertino
                                ? WrapAlignment.center
                                : WrapAlignment.start,
                            spacing: isMobileCupertino ? 6 : 8,
                            runSpacing: isMobileCupertino ? 6 : 8,
                            children: [
                              for (final genre
                                  in (isMobileCupertino
                                      ? genres.take(1)
                                      : genres))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    genre,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.90,
                                          ),
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(
                          height: isMobileCupertino
                              ? 12
                              : compact
                              ? 12
                              : 18,
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: item.id == null
                                  ? null
                                  : () => pushPlayerForItem(context, item),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 14 : 18,
                                  vertical: compact ? 12 : 16,
                                ),
                              ),
                              icon: Icon(
                                CupertinoIcons.play_fill,
                                size: compact ? 14 : 16,
                              ),
                              label: const Text('Play'),
                            ),
                            if (!isMobileCupertino && navigationTarget != null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    pushSeriesDetailsForItem(context, item),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.24),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 14 : 18,
                                    vertical: compact ? 12 : 16,
                                  ),
                                ),
                                icon: Icon(
                                  CupertinoIcons.info_circle_fill,
                                  size: compact ? 14 : 16,
                                ),
                                label: Text(
                                  item.isEpisode ? 'Details' : 'View Show',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroArrowButton extends StatelessWidget {
  const _HeroArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(999),
        ),
        child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 16)),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media Bar plugin not available',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Install and enable the Jellyfin Media Bar plugin to render the Apple TV-style hero carousel here.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

String _formatMetadata(dynamic item) {
  final rating = item.communityRating is num
      ? '★ ${(item.communityRating as num).toStringAsFixed(1)}'
      : null;
  final year = item.productionYear?.toString();
  final officialRating = item.raw['OfficialRating']?.toString();
  final type = officialRating ?? item.type?.toString();
  return [
    rating,
    year,
    type,
  ].whereType<String>().where((v) => v.isNotEmpty).join(' • ');
}
