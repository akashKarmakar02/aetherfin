import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/session/app_session_scope.dart';
import '../../../shared/widgets/mobile_cupertino_media_chrome.dart';
import '../../player/player_navigation.dart';
import '../../series/series_navigation.dart';
import '../data/search_loader.dart';
import '../models/search_view_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.loader = const AppSearchLoader()});

  final AppSearchLoader loader;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _exampleSearches = [
    'Lord of the Rings',
    'Severance',
    'Dune',
    'Blue Eye Samurai',
    'Arrival',
    'Andor',
  ];
  static const _desktopContentMaxWidth = 1000.0;

  final _queryController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  int _requestId = 0;
  String? _sessionKey;
  bool _isLoading = false;
  Object? _error;
  SearchViewData? _viewData;

  bool get _isCupertino => currentAppPlatform == AppPlatform.cupertino;
  String get _query => _queryController.text.trim();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.watch(context);
    final nextKey = [
      session.serverUrl,
      session.accessToken,
      session.user?.id,
    ].join('|');
    if (_sessionKey == nextKey) {
      return;
    }
    _sessionKey = nextKey;
    if (_query.isNotEmpty) {
      _runSearch(immediate: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleQueryChanged(String _) {
    _debounce?.cancel();
    setState(() {
      _error = null;
      if (_query.isEmpty) {
        _viewData = null;
        _isLoading = false;
      }
    });
    if (_query.isEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch({bool immediate = false}) async {
    if (!mounted) {
      return;
    }

    final query = _query;
    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = null;
        _viewData = null;
      });
      return;
    }

    final session = AppSessionScope.read(context);
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
      if (immediate) {
        _viewData = null;
      }
    });

    try {
      final data = await widget.loader.load(session, query);
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _viewData = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  void _applySuggestion(String query) {
    _queryController
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _handleQueryChanged(query);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileCupertino = _isCupertino && constraints.maxWidth < 700;
        if (isMobileCupertino) {
          return _buildMobileCupertinoScaffold(context);
        }
        return _isCupertino
            ? _buildCupertinoScaffold(context)
            : _buildDesktopScaffold(context);
      },
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search your Jellyfin library using $_backendLabel.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        YaruSearchField(
                          controller: _queryController,
                          focusNode: _focusNode,
                          autofocus: true,
                          hintText:
                              'Movies, series, episodes, collections, actors',
                          style: YaruSearchFieldStyle.filledOutlined,
                          height: 40,
                          radius: const Radius.circular(12),
                          contentPadding: const EdgeInsets.only(
                            left: 14,
                            right: 14,
                            top: 10,
                            bottom: 10,
                          ),
                          onChanged: _handleQueryChanged,
                          onClear: () {
                            _queryController.clear();
                            _handleQueryChanged('');
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: _SearchLoadingIndicator()),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _desktopContentMaxWidth,
                      ),
                      child: _buildDesktopContent(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoScaffold(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Search')),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: CupertinoSearchTextField(
                  controller: _queryController,
                  focusNode: _focusNode,
                  autofocus: true,
                  placeholder: 'Movies, series, episodes',
                  onChanged: _handleQueryChanged,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Using $_backendLabel',
                    style: theme.textTheme.textStyle.copyWith(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: _SearchLoadingIndicator()),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: _buildCupertinoContent(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCupertinoScaffold(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, topInset + 58, 16, 98),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search', style: theme.textTheme.navLargeTitleTextStyle),
                  const SizedBox(height: 14),
                  CupertinoSearchTextField(
                    controller: _queryController,
                    focusNode: _focusNode,
                    autofocus: true,
                    placeholder: 'Movies, series, episodes',
                    onChanged: _handleQueryChanged,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Using $_backendLabel',
                    style: theme.textTheme.textStyle.copyWith(
                      fontSize: 13,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const SizedBox(
                      height: 280,
                      child: Center(child: _SearchLoadingIndicator()),
                    )
                  else
                    _buildCupertinoContent(context),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MobileCupertinoMediaHeader(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MobileCupertinoMediaNavBar(
              selectedDestination: MobileCupertinoDestination.search,
              onHomePressed: () => context.goNamed(AppRoutes.homeName),
              onSearchPressed: null,
            ),
          ),
        ],
      ),
    );
  }

  String get _backendLabel =>
      (_viewData?.backend ?? SearchBackend.jellyfin).label;

  Widget _buildDesktopContent(BuildContext context) {
    final query = _query;
    final viewData = _viewData;
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    if (query.isEmpty) {
      return _DesktopSuggestionState(
        suggestions: _exampleSearches,
        onSuggestionPressed: _applySuggestion,
      );
    }
    if (_error != null && viewData == null) {
      return _DesktopErrorState(onRetry: () => _runSearch(immediate: true));
    }
    if (viewData == null) {
      return const _DesktopLoadingPlaceholder();
    }
    if (!viewData.hasResults) {
      return _DesktopEmptyResults(query: query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in viewData.sections) ...[
          _DesktopSearchSection(section: section),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildCupertinoContent(BuildContext context) {
    final query = _query;
    final viewData = _viewData;
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    if (query.isEmpty) {
      return _CupertinoSuggestionState(
        suggestions: _exampleSearches,
        onSuggestionPressed: _applySuggestion,
      );
    }
    if (_error != null && viewData == null) {
      return _CupertinoErrorState(onRetry: () => _runSearch(immediate: true));
    }
    if (viewData == null) {
      return const SizedBox.shrink();
    }
    if (!viewData.hasResults) {
      return _CupertinoEmptyResults(query: query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in viewData.sections) ...[
          _CupertinoSearchSection(section: section),
          const SizedBox(height: 26),
        ],
      ],
    );
  }
}

class _SearchLoadingIndicator extends StatelessWidget {
  const _SearchLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return switch (currentAppPlatform) {
      AppPlatform.cupertino => const CupertinoActivityIndicator(radius: 18),
      _ => const SizedBox(
        height: 42,
        width: 42,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    };
  }
}

class _DesktopSearchSection extends StatelessWidget {
  const _DesktopSearchSection({required this.section});

  final SearchSectionViewData section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            // border: Border.all(
            //   color: scheme.outlineVariant.withValues(alpha: 0.28),
            // ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < section.entries.length; i++)
                _DesktopSearchRow(
                  entry: section.entries[i],
                  showDivider: i != section.entries.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopSearchRow extends StatelessWidget {
  const _DesktopSearchRow({required this.entry, required this.showDivider});

  final SearchResultEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onTap = _tapHandler(context, entry.item);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.18),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            _SearchArtwork(
              artworkUrl: entry.artworkUrl,
              artworkKind: entry.artworkKind,
              desktop: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.item.name ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((entry.subtitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if ((entry.item.overview ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.item.overview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (onTap != null)
              Icon(
                YaruIcons.go_next,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _typeLabel(entry.item),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoSearchSection extends StatelessWidget {
  const _CupertinoSearchSection({required this.section});

  final SearchSectionViewData section;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final sectionHeight = _cupertinoSectionHeight(context, section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: sectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: section.entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _CupertinoSearchCard(entry: section.entries[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CupertinoSearchCard extends StatelessWidget {
  const _CupertinoSearchCard({required this.entry});

  final SearchResultEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final onTap = _tapHandler(context, entry.item);
    final subtitle = entry.subtitle;
    final hasSubtitle = (subtitle ?? '').isNotEmpty;
    final titleStyle = theme.textTheme.textStyle.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final subtitleStyle = theme.textTheme.textStyle.copyWith(
      fontSize: 12,
      height: 1.2,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final width = switch (entry.artworkKind) {
      SearchArtworkKind.poster => 124.0,
      SearchArtworkKind.landscape => 196.0,
      SearchArtworkKind.circle => 104.0,
    };

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchArtwork(
              artworkUrl: entry.artworkUrl,
              artworkKind: entry.artworkKind,
              desktop: false,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: textScaler.scale(15) * 1.2 * 2,
                    child: Text(
                      entry.item.name ?? 'Untitled',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _cupertinoSectionHeight(
  BuildContext context,
  SearchSectionViewData section,
) {
  const titleFontSize = 15.0;
  const titleLineHeight = 1.2;
  const subtitleFontSize = 12.0;
  const subtitleLineHeight = 1.2;
  const artworkGap = 10.0;
  const subtitleGap = 4.0;
  const minimumHeight = 228.0;
  const bottomAllowance = 4.0;

  final textScaler = MediaQuery.textScalerOf(context);
  var artworkHeight = 0.0;
  var hasSubtitle = false;

  for (final entry in section.entries) {
    final nextArtworkHeight = _searchArtworkSize(
      artworkKind: entry.artworkKind,
      desktop: false,
    ).height;
    if (nextArtworkHeight > artworkHeight) {
      artworkHeight = nextArtworkHeight;
    }
    hasSubtitle = hasSubtitle || (entry.subtitle ?? '').isNotEmpty;
  }

  if (artworkHeight == 0) {
    return minimumHeight;
  }

  final titleHeight = textScaler.scale(titleFontSize) * titleLineHeight * 2;
  final subtitleHeight = hasSubtitle
      ? textScaler.scale(subtitleFontSize) * subtitleLineHeight
      : 0;
  final totalHeight =
      artworkHeight +
      artworkGap +
      titleHeight +
      subtitleHeight +
      (hasSubtitle ? subtitleGap : 0) +
      bottomAllowance;

  return totalHeight < minimumHeight ? minimumHeight : totalHeight;
}

class _SearchArtwork extends StatelessWidget {
  const _SearchArtwork({
    required this.artworkUrl,
    required this.artworkKind,
    required this.desktop,
  });

  final String? artworkUrl;
  final SearchArtworkKind artworkKind;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final size = _searchArtworkSize(artworkKind: artworkKind, desktop: desktop);
    final borderRadius = switch (artworkKind) {
      SearchArtworkKind.poster => BorderRadius.circular(desktop ? 12 : 18),
      SearchArtworkKind.landscape => BorderRadius.circular(desktop ? 12 : 16),
      SearchArtworkKind.circle => BorderRadius.circular(999),
    };

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size.width,
        height: size.height,
        color: _fallbackColor(context),
        child: artworkUrl == null
            ? _ArtworkPlaceholder(kind: artworkKind)
            : Image.network(
                artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _ArtworkPlaceholder(kind: artworkKind),
              ),
      ),
    );
  }

  Color _fallbackColor(BuildContext context) {
    if (desktop) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    return CupertinoColors.tertiarySystemFill.resolveFrom(context);
  }
}

Size _searchArtworkSize({
  required SearchArtworkKind artworkKind,
  required bool desktop,
}) {
  return switch ((desktop, artworkKind)) {
    (true, SearchArtworkKind.poster) => const Size(54, 82),
    (true, SearchArtworkKind.landscape) => const Size(104, 58),
    (true, SearchArtworkKind.circle) => const Size(52, 52),
    (false, SearchArtworkKind.poster) => const Size(124, 178),
    (false, SearchArtworkKind.landscape) => const Size(196, 110),
    (false, SearchArtworkKind.circle) => const Size(96, 96),
  };
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({required this.kind});

  final SearchArtworkKind kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      SearchArtworkKind.poster => Icons.movie_creation_outlined,
      SearchArtworkKind.landscape => Icons.live_tv_rounded,
      SearchArtworkKind.circle => Icons.person_outline_rounded,
    };

    return Center(child: Icon(icon, size: 24));
  }
}

class _DesktopSuggestionState extends StatelessWidget {
  const _DesktopSuggestionState({
    required this.suggestions,
    required this.onSuggestionPressed,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    YaruIcons.search,
                    size: 26,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Start with something specific',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a title, series, or actor to begin searching your library.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final suggestion in suggestions)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: const StadiumBorder(),
                        backgroundColor: scheme.surfaceContainerLowest,
                        foregroundColor: scheme.onSurface,
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => onSuggestionPressed(suggestion),
                      child: Text(suggestion),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CupertinoSuggestionState extends StatelessWidget {
  const _CupertinoSuggestionState({
    required this.suggestions,
    required this.onSuggestionPressed,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionPressed;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search your library',
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'Results follow your Streamyfin search engine setting when the plugin is available.',
          style: CupertinoTheme.of(
            context,
          ).textTheme.textStyle.copyWith(color: secondary),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in suggestions)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(999),
                onPressed: () => onSuggestionPressed(suggestion),
                child: Text(
                  suggestion,
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.textStyle.copyWith(fontSize: 14),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DesktopLoadingPlaceholder extends StatelessWidget {
  const _DesktopLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _DesktopEmptyResults extends StatelessWidget {
  const _DesktopEmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'No results found for "$query".',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CupertinoEmptyResults extends StatelessWidget {
  const _CupertinoEmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Text(
      'No results found for "$query".',
      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }
}

class _DesktopErrorState extends StatelessWidget {
  const _DesktopErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Search failed. Try again.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CupertinoErrorState extends StatelessWidget {
  const _CupertinoErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Search failed. Try again.',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

VoidCallback? _tapHandler(BuildContext context, JellyfinBaseItem item) {
  if (seriesNavigationTargetForItem(item) != null) {
    return () => pushSeriesDetailsForItem(context, item);
  }
  if (item.isMovie || item.type == 'Video') {
    return () => pushPlayerForItem(context, item);
  }
  return null;
}

String _typeLabel(JellyfinBaseItem item) {
  return switch (item.type) {
    'Movie' => 'Movie',
    'Series' => 'Series',
    'Episode' => 'Episode',
    'BoxSet' => 'Collection',
    'Person' => 'Actor',
    final type? => type,
    null => 'Item',
  };
}
