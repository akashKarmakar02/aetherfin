import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../../app/session/app_session_scope.dart';
import '../../player/player_navigation.dart';
import '../../series/series_navigation.dart';
import '../data/library_loader.dart';
import '../models/library_view_data.dart';

class LibraryCollectionScreen extends StatefulWidget {
  const LibraryCollectionScreen({
    super.key,
    required this.libraryId,
    this.loader = const AppLibraryLoader(),
  });

  final String libraryId;
  final AppLibraryLoader loader;

  @override
  State<LibraryCollectionScreen> createState() => _LibraryCollectionScreenState();
}

class _LibraryCollectionScreenState extends State<LibraryCollectionScreen> {
  static const _desktopContentMaxWidth = 1120.0;
  static const _pageSize = 60;

  String? _sessionKey;
  JellyfinBaseItem? _library;
  List<LibraryCollectionEntry> _entries = const [];
  int? _totalCount;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Object? _error;

  bool get _isCupertino => currentAppPlatform == AppPlatform.cupertino;
  bool get _hasMore => (_totalCount ?? 0) > _entries.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.watch(context);
    final nextKey = [
      session.serverUrl,
      session.accessToken,
      session.user?.id,
      widget.libraryId,
    ].join('|');
    if (_sessionKey == nextKey) {
      return;
    }
    _sessionKey = nextKey;
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final session = AppSessionScope.read(context);
    setState(() {
      _isLoading = true;
      _error = null;
      _library = null;
      _entries = const [];
      _totalCount = null;
    });

    try {
      final page = await widget.loader.loadCollectionPage(
        session,
        widget.libraryId,
        limit: _pageSize,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _library = page?.library;
        _entries = page?.entries ?? const [];
        _totalCount = page?.totalCount;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }
    final session = AppSessionScope.read(context);
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await widget.loader.loadCollectionPage(
        session,
        widget.libraryId,
        library: _library,
        startIndex: _entries.length,
        limit: _pageSize,
      );
      if (!mounted || page == null) {
        return;
      }
      setState(() {
        _library = page.library;
        _entries = [..._entries, ...page.entries];
        _totalCount = page.totalCount;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _openEntry(LibraryCollectionEntry entry) {
    final item = entry.item;
    if (seriesNavigationTargetForItem(item) != null) {
      pushSeriesDetailsForItem(context, item);
      return;
    }
    if ((item.id ?? '').isNotEmpty && !item.isSeries) {
      pushPlayerForItem(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileCupertino = _isCupertino && constraints.maxWidth < 700;
        final content = _LibraryCollectionBody(
          library: _library,
          entries: _entries,
          totalCount: _totalCount,
          isLoading: _isLoading,
          isLoadingMore: _isLoadingMore,
          error: _error,
          onRetry: _loadInitial,
          onLoadMore: _loadMore,
          onOpenEntry: _openEntry,
        );
        if (isMobileCupertino) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              previousPageTitle: 'Library',
              middle: Text(_library?.name ?? 'Library'),
            ),
            child: content,
          );
        }
        return SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: content,
          ),
        );
      },
    );
  }
}

class _LibraryCollectionBody extends StatelessWidget {
  const _LibraryCollectionBody({
    required this.library,
    required this.entries,
    required this.totalCount,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.onRetry,
    required this.onLoadMore,
    required this.onOpenEntry,
  });

  final JellyfinBaseItem? library;
  final List<LibraryCollectionEntry> entries;
  final int? totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<LibraryCollectionEntry> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCupertinoMobile =
        currentAppPlatform == AppPlatform.cupertino && size.width < 700;
    final horizontalPadding = isCupertinoMobile ? 18.0 : 20.0;
    final topPadding = isCupertinoMobile ? 18.0 : 24.0;
    final bottomPadding = isCupertinoMobile ? 34.0 : 40.0;
    final crossAxisCount = _gridColumnCount(size.width, isCupertinoMobile);
    final aspectRatio = isCupertinoMobile ? 0.63 : 0.66;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _LibraryCollectionScreenState._desktopContentMaxWidth,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      library?.name ?? 'Library',
                      style: (isCupertinoMobile
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _buildLibraryMetaLine(library, totalCount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: const _CollectionStatusState(
              icon: CupertinoIcons.square_stack_3d_up,
              title: 'Loading library...',
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        else if (error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _CollectionStatusState(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Could not load this library',
              message: 'Try again in a moment.',
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          )
        else if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: const _CollectionStatusState(
              icon: CupertinoIcons.square_stack_3d_up,
              title: 'No items found',
              message: 'This library does not contain any supported items yet.',
            ),
          )
        else ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              20,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth:
                        _LibraryCollectionScreenState._desktopContentMaxWidth,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isCupertinoMobile ? 14 : 18,
                      mainAxisSpacing: isCupertinoMobile ? 18 : 22,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _LibraryPosterCard(
                        entry: entries[index],
                        onTap: () => onOpenEntry(entries[index]),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator(strokeWidth: 3)
                    : (totalCount ?? 0) > entries.length
                    ? OutlinedButton(
                        onPressed: onLoadMore,
                        child: const Text('Load more'),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LibraryPosterCard extends StatelessWidget {
  const _LibraryPosterCard({
    required this.entry,
    required this.onTap,
  });

  final LibraryCollectionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canOpen =
        seriesNavigationTargetForItem(entry.item) != null ||
        ((entry.item.id ?? '').isNotEmpty && !entry.item.isSeries);

    return MouseRegion(
      cursor: canOpen ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: canOpen ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: entry.artworkUrl != null
                    ? Image.network(
                        entry.artworkUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _LibraryPosterFallback(
                          item: entry.item,
                        ),
                      )
                    : _LibraryPosterFallback(item: entry.item),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.item.name ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((entry.subtitle ?? '').isNotEmpty)
              Text(
                entry.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LibraryPosterFallback extends StatelessWidget {
  const _LibraryPosterFallback({required this.item});

  final JellyfinBaseItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          _libraryItemFallbackIcon(item),
          color: scheme.onSurfaceVariant,
          size: 30,
        ),
      ),
    );
  }
}

class _CollectionStatusState extends StatelessWidget {
  const _CollectionStatusState({
    required this.icon,
    required this.title,
    this.message,
    this.child,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((message ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: 18),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _buildLibraryMetaLine(JellyfinBaseItem? library, int? totalCount) {
  final libraryLabel = collectionLabelForType(library?.collectionType);
  if (totalCount == null) {
    return libraryLabel;
  }
  return '$libraryLabel · ${totalCount == 1 ? '1 item' : '$totalCount items'}';
}

int _gridColumnCount(double width, bool isCupertinoMobile) {
  if (isCupertinoMobile) {
    return width < 390 ? 2 : 3;
  }
  if (width < 900) {
    return 3;
  }
  if (width < 1180) {
    return 4;
  }
  if (width < 1480) {
    return 5;
  }
  return 6;
}

IconData _libraryItemFallbackIcon(JellyfinBaseItem item) {
  return switch (item.type) {
    'Series' => Icons.tv_outlined,
    'Movie' => Icons.local_movies_outlined,
    'BoxSet' => Icons.collections_bookmark_outlined,
    'MusicVideo' => Icons.music_video_outlined,
    'Video' => Icons.video_library_outlined,
    _ => Icons.movie_creation_outlined,
  };
}
