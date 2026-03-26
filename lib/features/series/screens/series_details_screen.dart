import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/session/app_session_scope.dart';
import '../../player/player_navigation.dart';
import '../data/series_details_loader.dart';
import '../models/series_details_view_data.dart';

class SeriesDetailsScreen extends StatefulWidget {
  const SeriesDetailsScreen({
    super.key,
    required this.seriesId,
    this.initialSeasonIndex,
    this.highlightedEpisodeId,
    this.loader = loadSeriesDetails,
  });

  final String seriesId;
  final int? initialSeasonIndex;
  final String? highlightedEpisodeId;
  final SeriesDetailsLoader loader;

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _episodesKey = GlobalKey();
  final GlobalKey _extrasKey = GlobalKey();

  late SeriesDetailsRequest _request;
  SeriesDetailsViewData? _viewData;
  Object? _error;
  bool _isLoading = true;
  bool _isRefreshingSeason = false;
  bool _isTogglingFavorite = false;
  bool _isFavorite = false;
  String? _sessionKey;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _request = SeriesDetailsRequest(
      seriesId: widget.seriesId,
      seasonIndex: widget.initialSeasonIndex,
      highlightedEpisodeId: widget.highlightedEpisodeId,
    );
  }

  @override
  void didUpdateWidget(covariant SeriesDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seriesId != widget.seriesId ||
        oldWidget.initialSeasonIndex != widget.initialSeasonIndex ||
        oldWidget.highlightedEpisodeId != widget.highlightedEpisodeId) {
      _request = SeriesDetailsRequest(
        seriesId: widget.seriesId,
        seasonIndex: widget.initialSeasonIndex,
        highlightedEpisodeId: widget.highlightedEpisodeId,
      );
      _load(forceFullScreen: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.watch(context);
    final nextSessionKey = [
      session.serverUrl,
      session.accessToken,
      session.user?.id,
      widget.seriesId,
      widget.initialSeasonIndex,
      widget.highlightedEpisodeId,
    ].join('|');
    if (_sessionKey == nextSessionKey) {
      return;
    }
    _sessionKey = nextSessionKey;
    _load(forceFullScreen: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool forceFullScreen}) async {
    final session = AppSessionScope.read(context);
    final loadVersion = ++_loadVersion;

    setState(() {
      _error = null;
      if (forceFullScreen || _viewData == null) {
        _isLoading = true;
      } else {
        _isRefreshingSeason = true;
      }
    });

    try {
      final data = await widget.loader(session, _request);
      if (!mounted || loadVersion != _loadVersion) {
        return;
      }
      setState(() {
        _viewData = data;
        _isFavorite = data.series.userData?.isFavorite ?? false;
        _isLoading = false;
        _isRefreshingSeason = false;
      });
    } catch (error) {
      if (!mounted || loadVersion != _loadVersion) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
        _isRefreshingSeason = false;
      });
    }
  }

  Future<void> _selectSeason(
    int seasonIndex, {
    String? highlightedEpisodeId,
  }) async {
    if (_request.seasonIndex == seasonIndex &&
        _request.highlightedEpisodeId == highlightedEpisodeId) {
      return;
    }

    _request = _request.copyWith(
      seasonIndex: seasonIndex,
      highlightedEpisodeId: highlightedEpisodeId,
    );
    await _load(forceFullScreen: false);
  }

  Future<void> _focusEpisodes({JellyfinBaseItem? episode}) async {
    if (episode != null && episode.parentIndexNumber != null) {
      await _selectSeason(episode.parentIndexNumber!);
    }

    if (!mounted) {
      return;
    }
    await _scrollToKey(_episodesKey);
  }

  Future<void> _scrollToExtras() => _scrollToKey(_extrasKey);

  Future<void> _scrollToKey(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  Future<void> _toggleFavorite() async {
    final data = _viewData;
    final session = AppSessionScope.read(context);
    final baseUrl = session.serverUrl;
    final accessToken = session.accessToken;
    final clientInfo = session.clientInfo;
    final userId = session.user?.id;
    if (data == null ||
        baseUrl == null ||
        accessToken == null ||
        clientInfo == null ||
        userId == null ||
        _isTogglingFavorite) {
      return;
    }

    final nextValue = !_isFavorite;
    setState(() {
      _isFavorite = nextValue;
      _isTogglingFavorite = true;
    });

    final libraryApi = JellyfinLibraryApi(
      baseUrl: baseUrl,
      clientInfo: clientInfo,
      accessToken: accessToken,
    );

    try {
      await libraryApi.updateFavoriteStatus(
        userId: userId,
        itemId: data.series.id!,
        isFavorite: nextValue,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = !nextValue;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCupertinoMobile =
            currentAppPlatform == AppPlatform.cupertino &&
            constraints.maxWidth < 820;
        final isLinuxDesktop = currentAppPlatform == AppPlatform.linux;

        if (_isLoading && _viewData == null) {
          return _SeriesDetailsLoading(isCupertinoMobile: isCupertinoMobile);
        }

        if (_error != null && _viewData == null) {
          return _SeriesDetailsError(
            isCupertinoMobile: isCupertinoMobile,
            isLinuxDesktop: isLinuxDesktop,
            onRetry: () => _load(forceFullScreen: true),
          );
        }

        final data = _viewData;
        if (data == null) {
          return const SizedBox.shrink();
        }

        final heroMeta = _heroMeta(data.series);
        final heroFacts = _heroFacts(data);

        return Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: const BoxDecoration(),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(bottom: isCupertinoMobile ? 48 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SeriesHero(
                      data: data,
                      heroMeta: heroMeta,
                      heroFacts: heroFacts,
                      isCupertinoMobile: isCupertinoMobile,
                      isLinuxDesktop: isLinuxDesktop,
                      showOverlayBackButton: !isLinuxDesktop,
                      isFavorite: _isFavorite,
                      isTogglingFavorite: _isTogglingFavorite,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(AppRoutes.homeName);
                        }
                      },
                      onPrimaryAction: () {
                        if (data.hasNextUp) {
                          pushPlayerForItem(
                            context,
                            data.nextUpEntries.first.item,
                          );
                          return;
                        }
                        _focusEpisodes();
                      },
                      onFavoriteToggle: _toggleFavorite,
                      onTrailerAction: data.hasTrailerAction
                          ? _scrollToExtras
                          : null,
                    ),
                    if (_isRefreshingSeason)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCupertinoMobile ? 14 : 28,
                        18,
                        isCupertinoMobile ? 14 : 28,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            key: _episodesKey,
                            child: _SeasonSelector(
                              data: data,
                              isCupertinoMobile: isCupertinoMobile,
                              isLinuxDesktop: isLinuxDesktop,
                              onSeasonChanged: (seasonIndex) {
                                _selectSeason(seasonIndex);
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          _EpisodesRail(
                            entries: data.episodes,
                            isCupertinoMobile: isCupertinoMobile,
                            onSelected: (entry) {
                              _selectSeason(
                                entry.item.parentIndexNumber ??
                                    data.selectedSeasonIndex,
                              );
                            },
                            onPlay: (entry) =>
                                pushPlayerForItem(context, entry.item),
                          ),
                          const SizedBox(height: 28),
                          if (data.hasNextUp) ...[
                            _SectionHeader(title: 'Next Up'),
                            const SizedBox(height: 14),
                            _EpisodeMediaRail(
                              entries: data.nextUpEntries,
                              isCupertinoMobile: isCupertinoMobile,
                              onTap: (entry) =>
                                  _focusEpisodes(episode: entry.item),
                              onPlay: (entry) =>
                                  pushPlayerForItem(context, entry.item),
                            ),
                            const SizedBox(height: 28),
                          ],
                          if (data.hasExtras) ...[
                            _SectionHeader(title: 'Trailers & Extras'),
                            const SizedBox(height: 14),
                            Container(
                              key: _extrasKey,
                              child: _MediaRail(
                                entries: data.extraEntries,
                                isCupertinoMobile: isCupertinoMobile,
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                          if (data.hasRelated) ...[
                            _SectionHeader(title: 'Related'),
                            const SizedBox(height: 14),
                            _RelatedRail(entries: data.relatedEntries),
                            const SizedBox(height: 28),
                          ],
                          if (data.hasCast) ...[
                            _SectionHeader(title: 'Cast & Crew'),
                            const SizedBox(height: 14),
                            _CastRail(entries: data.castEntries),
                          ],
                        ],
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
}

class _SeriesHero extends StatelessWidget {
  const _SeriesHero({
    required this.data,
    required this.heroMeta,
    required this.heroFacts,
    required this.isCupertinoMobile,
    required this.isLinuxDesktop,
    required this.showOverlayBackButton,
    required this.isFavorite,
    required this.isTogglingFavorite,
    required this.onBack,
    required this.onPrimaryAction,
    required this.onFavoriteToggle,
    required this.onTrailerAction,
  });

  final SeriesDetailsViewData data;
  final String heroMeta;
  final String heroFacts;
  final bool isCupertinoMobile;
  final bool isLinuxDesktop;
  final bool showOverlayBackButton;
  final bool isFavorite;
  final bool isTogglingFavorite;
  final VoidCallback onBack;
  final VoidCallback onPrimaryAction;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTrailerAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = data.series;
    final topControlInset = MediaQuery.viewPaddingOf(context).top +
        (isLinuxDesktop ? kYaruTitleBarHeight + 12 : 12);

    return ClipRect(
      child: AspectRatio(
        aspectRatio: isCupertinoMobile ? 0.82 : 16 / 8.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFF0E1114)),
              child: data.seriesBackdropUrl == null
                  ? const SizedBox.shrink()
                  : Image.network(
                      data.seriesBackdropUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.82),
                    const Color(0xFF101315),
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.86),
                    Colors.black.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
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
            if (showOverlayBackButton)
              Positioned(
                top: topControlInset,
                left: isCupertinoMobile ? 12 : 20,
                child: _GlassIconButton(
                  icon: CupertinoIcons.back,
                  onPressed: onBack,
                ),
              ),
            Positioned(
              top: topControlInset,
              right: isCupertinoMobile ? 12 : 20,
              child: Row(
                children: [
                  if (onTrailerAction != null) ...[
                    _GlassIconButton(
                      icon: CupertinoIcons.film,
                      onPressed: onTrailerAction!,
                    ),
                    const SizedBox(width: 10),
                  ],
                  _GlassIconButton(
                    icon: isFavorite
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.add,
                    onPressed: onFavoriteToggle,
                    busy: isTogglingFavorite,
                  ),
                ],
              ),
            ),
            Positioned(
              left: isCupertinoMobile ? 16 : 38,
              right: isCupertinoMobile ? 16 : 42,
              bottom: isCupertinoMobile ? 24 : 34,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCupertinoMobile ? double.infinity : 620,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.seriesLogoUrl != null)
                      Image.network(
                        data.seriesLogoUrl!,
                        height: isCupertinoMobile ? 60 : 94,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (_, _, _) => _HeroTitle(
                          text: series.name ?? 'Untitled',
                          isCupertinoMobile: isCupertinoMobile,
                        ),
                      )
                    else
                      _HeroTitle(
                        text: series.name ?? 'Untitled',
                        isCupertinoMobile: isCupertinoMobile,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      heroMeta,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (heroFacts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        heroFacts,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                    if ((series.overview ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        series.overview!,
                        maxLines: isCupertinoMobile ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.94),
                          height: 1.42,
                        ),
                      ),
                    ],
                    if ((data.starringText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        data.starringText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _PrimaryHeroButton(
                          label: data.hasNextUp
                              ? 'Continue'
                              : 'Browse Episodes',
                          onPressed: onPrimaryAction,
                          isCupertinoMobile: isCupertinoMobile,
                        ),
                        // if (data.seriesPosterUrl != null)
                        //   _GlassPosterPill(
                        //     posterUrl: data.seriesPosterUrl!,
                        //     title: series.name ?? 'Series',
                        //   ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesDetailsLoading extends StatelessWidget {
  const _SeriesDetailsLoading({required this.isCupertinoMobile});

  final bool isCupertinoMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      // color: const Color(0xFF090B0D),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCupertinoMobile)
              const CupertinoActivityIndicator(radius: 16)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading series details...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesDetailsError extends StatelessWidget {
  const _SeriesDetailsError({
    required this.isCupertinoMobile,
    required this.isLinuxDesktop,
    required this.onRetry,
  });

  final bool isCupertinoMobile;
  final bool isLinuxDesktop;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not load this series.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Check your connection and try again.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          if (isCupertinoMobile)
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Retry'),
            )
          else
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );

    return Material(
      color: const Color(0xFF090B0D),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: isLinuxDesktop
              ? YaruBorderContainer(
                  padding: EdgeInsets.zero,
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
                  child: body,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: body,
                ),
        ),
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.data,
    required this.isCupertinoMobile,
    required this.isLinuxDesktop,
    required this.onSeasonChanged,
  });

  final SeriesDetailsViewData data;
  final bool isCupertinoMobile;
  final bool isLinuxDesktop;
  final ValueChanged<int> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    if (data.seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    if (data.seasons.length == 1) {
      final title = data.selectedSeason?.title ?? data.seasons.first.title;

      if (isCupertinoMobile) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(title, style: const TextStyle(color: Colors.white)),
        );
      }

      if (isLinuxDesktop) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(title, style: const TextStyle(color: Colors.white)),
      );
    }

    if (isCupertinoMobile && data.seasons.length <= 4) {
      return CupertinoSlidingSegmentedControl<int>(
        groupValue: data.selectedSeasonIndex,
        thumbColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        children: {
          for (final season in data.seasons)
            (season.indexNumber ?? 0): Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                season.title,
                style: const TextStyle(color: Colors.black),
              ),
            ),
        },
        onValueChanged: (value) {
          if (value != null) {
            onSeasonChanged(value);
          }
        },
      );
    }

    final yaruDropdown = YaruPopupMenuButton<int>(
      initialValue: data.selectedSeasonIndex,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      onSelected: onSeasonChanged,
      child: Text(
        data.selectedSeason?.title ?? 'Season',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      itemBuilder: (context) {
        return [
          for (final season in data.seasons)
            PopupMenuItem<int>(
              value: season.indexNumber ?? 0,
              child: Text(season.title),
            ),
        ];
      },
    );

    if (isLinuxDesktop) {
      return yaruDropdown;
    }

    if (isCupertinoMobile) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        onPressed: () => _showSeasonPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.selectedSeason?.title ?? 'Season',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: yaruDropdown,
    );
  }

  Future<void> _showSeasonPicker(BuildContext context) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Choose season'),
          actions: [
            for (final season in data.seasons)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (season.indexNumber != null) {
                    onSeasonChanged(season.indexNumber!);
                  }
                },
                child: Text(season.title),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }
}

class _EpisodesRail extends StatelessWidget {
  const _EpisodesRail({
    required this.entries,
    required this.isCupertinoMobile,
    required this.onSelected,
    required this.onPlay,
  });

  final List<SeriesDetailsEpisodeEntry> entries;
  final bool isCupertinoMobile;
  final ValueChanged<SeriesDetailsEpisodeEntry> onSelected;
  final ValueChanged<SeriesDetailsEpisodeEntry> onPlay;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptySectionCopy(
        title: 'No episodes are available for this season yet.',
      );
    }

    return SizedBox(
      height: isCupertinoMobile ? 214 : 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _EpisodeMediaCard(
            entry: entry,
            runtimeLabel: entry.runtimeLabel,
            isCupertinoMobile: isCupertinoMobile,
            onTap: () => onSelected(entry),
            onPlay: () => onPlay(entry),
          );
        },
      ),
    );
  }
}

class _EpisodeMediaRail extends StatelessWidget {
  const _EpisodeMediaRail({
    required this.entries,
    required this.isCupertinoMobile,
    this.onTap,
    this.onPlay,
  });

  final List<SeriesDetailsMediaEntry> entries;
  final bool isCupertinoMobile;
  final ValueChanged<SeriesDetailsMediaEntry>? onTap;
  final ValueChanged<SeriesDetailsMediaEntry>? onPlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCupertinoMobile ? 214 : 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _EpisodeMediaCard(
            entry: entry,
            runtimeLabel: null,
            isCupertinoMobile: isCupertinoMobile,
            onTap: onTap == null ? null : () => onTap!(entry),
            onPlay: onPlay == null ? null : () => onPlay!(entry),
          );
        },
      ),
    );
  }
}

class _MediaRail extends StatelessWidget {
  const _MediaRail({required this.entries, required this.isCupertinoMobile});

  final List<SeriesDetailsMediaEntry> entries;
  final bool isCupertinoMobile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCupertinoMobile ? 188 : 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _LandscapeCard(
            entry: entry,
            isCupertinoMobile: isCupertinoMobile,
          );
        },
      ),
    );
  }
}

class _RelatedRail extends StatelessWidget {
  const _RelatedRail({required this.entries});

  final List<SeriesDetailsMediaEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _RelatedPosterCard(entry: entry);
        },
      ),
    );
  }
}

class _CastRail extends StatelessWidget {
  const _CastRail({required this.entries});

  final List<SeriesDetailsPersonEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) => _CastCard(entry: entries[index]),
      ),
    );
  }
}

class _EpisodeMediaCard extends StatelessWidget {
  const _EpisodeMediaCard({
    required this.entry,
    required this.runtimeLabel,
    required this.isCupertinoMobile,
    required this.onTap,
    required this.onPlay,
  });

  final SeriesDetailsMediaEntry entry;
  final String? runtimeLabel;
  final bool isCupertinoMobile;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardBorderRadius = BorderRadius.all(Radius.circular(22));
    const footerBorderRadius = BorderRadius.vertical(top: Radius.circular(16));
    final footerHeight = isCupertinoMobile ? 104.0 : 129.0;
    final metaLine = [
      entry.subtitle,
      runtimeLabel,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    final body = RepaintBoundary(
      child: Container(
        width: isCupertinoMobile ? 286 : 332,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1E),
          borderRadius: cardBorderRadius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: cardBorderRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (entry.imageUrl != null)
              Image.network(
                entry.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.34),
                    const Color(0xFF2C3729).withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: footerHeight,
              child: ClipRRect(
                borderRadius: footerBorderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!isCupertinoMobile)
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    DecoratedBox(
                      // Mobile season rails stuttered with a per-card blur filter.
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF6C756A,
                        ).withValues(alpha: isCupertinoMobile ? 0.22 : 0.16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.02),
                            Colors.black.withValues(
                              alpha: isCupertinoMobile ? 0.18 : 0.12,
                            ),
                            Colors.black.withValues(
                              alpha: isCupertinoMobile ? 0.28 : 0.22,
                            ),
                          ],
                          stops: const [0, 0.36, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.eyebrow ?? 'Episode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.74),
                              letterSpacing: 0.7,
                              fontWeight: FontWeight.w500,
                              fontSize: isCupertinoMobile ? 10.5 : 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            entry.title ?? 'Untitled',
                            maxLines: isCupertinoMobile ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (isCupertinoMobile
                                        ? theme.textTheme.titleMedium
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isCupertinoMobile ? 13 : 15,
                                      height: 1.08,
                                      letterSpacing: -0.15,
                                    ),
                          ),
                          if ((entry.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              entry.description!,
                              maxLines: isCupertinoMobile ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: isCupertinoMobile ? 12.5 : 13.5,
                                height: 1.22,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  metaLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    fontSize: isCupertinoMobile ? 11.5 : 12,
                                  ),
                                ),
                              ),
                              if (onPlay != null) ...[
                                const SizedBox(width: 6),
                                _MiniPlayButton(onPressed: onPlay!),
                              ],
                              const SizedBox(width: 8),
                              Icon(
                                Icons.more_horiz,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.78),
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
          ],
        ),
      ),
    );

    if (onTap == null) {
      return body;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: body),
    );
  }
}

class _LandscapeCard extends StatelessWidget {
  const _LandscapeCard({required this.entry, required this.isCupertinoMobile});

  final SeriesDetailsMediaEntry entry;
  final bool isCupertinoMobile;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: isCupertinoMobile ? 252 : 292,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (entry.imageUrl != null)
                  Image.network(
                    entry.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.76),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((entry.eyebrow ?? '').isNotEmpty)
                        Text(
                          entry.eyebrow!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.70),
                                letterSpacing: 0.6,
                              ),
                        ),
                      if ((entry.eyebrow ?? '').isNotEmpty)
                        const SizedBox(height: 4),
                      Text(
                        entry.title ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((entry.subtitle ?? '').isNotEmpty)
                  Text(
                    entry.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                if ((entry.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.62),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return body;
  }
}

class _RelatedPosterCard extends StatelessWidget {
  const _RelatedPosterCard({required this.entry});

  final SeriesDetailsMediaEntry entry;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final itemId = entry.item.id;
          if (itemId == null) {
            return;
          }
          context.pushNamed(
            AppRoutes.seriesName,
            pathParameters: {'id': itemId},
          );
        },
        child: SizedBox(
          width: 154,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: entry.posterUrl == null
                      ? const SizedBox.shrink()
                      : Image.network(
                          entry.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.title ?? 'Untitled',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((entry.subtitle ?? '').isNotEmpty)
                Text(
                  entry.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  const _CastCard({required this.entry});

  final SeriesDetailsPersonEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: entry.imageUrl == null
                ? Icon(
                    CupertinoIcons.person_solid,
                    color: Colors.white.withValues(alpha: 0.72),
                  )
                : Image.network(
                    entry.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      CupertinoIcons.person_solid,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.person.name ?? 'Unknown',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((entry.person.role ?? '').isNotEmpty)
                  Flexible(
                    child: Text(
                      entry.person.role!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          CupertinoIcons.chevron_right,
          size: 18,
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ],
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.text, required this.isCupertinoMobile});

  final String text;
  final bool isCupertinoMobile;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          (isCupertinoMobile
                  ? Theme.of(context).textTheme.displaySmall
                  : Theme.of(context).textTheme.displayMedium)
              ?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
    );
  }
}

class _PrimaryHeroButton extends StatelessWidget {
  const _PrimaryHeroButton({
    required this.label,
    required this.onPressed,
    required this.isCupertinoMobile,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isCupertinoMobile;

  @override
  Widget build(BuildContext context) {
    if (isCupertinoMobile) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: busy ? null : onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayButton extends StatelessWidget {
  const _MiniPlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        foregroundColor: Colors.white,
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      icon: const Icon(CupertinoIcons.play_fill, size: 16),
    );
  }
}

class _EmptySectionCopy extends StatelessWidget {
  const _EmptySectionCopy({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

String _heroMeta(JellyfinBaseItem item) {
  final labels = <String>['TV Show', ...item.genres.take(2)];
  return labels.join(' · ');
}

String _heroFacts(SeriesDetailsViewData data) {
  final parts = <String>[
    if (data.series.productionYear != null) '${data.series.productionYear}',
    if (data.seasons.isNotEmpty)
      '${data.seasons.length} ${data.seasons.length == 1 ? 'Season' : 'Seasons'}',
    if ((data.series.officialRating ?? '').isNotEmpty)
      data.series.officialRating!,
  ];
  return parts.join(' • ');
}
