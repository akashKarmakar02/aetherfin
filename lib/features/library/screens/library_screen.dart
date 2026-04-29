import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/platform/app_platform.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/session/app_session_scope.dart';
import '../data/library_loader.dart';
import '../models/library_view_data.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.loader = const AppLibraryLoader()});

  final AppLibraryLoader loader;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _desktopContentMaxWidth = 1000.0;

  Future<LibraryOverviewViewData>? _future;
  String? _sessionKey;

  bool get _isCupertino => currentAppPlatform == AppPlatform.cupertino;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.watch(context);
    final nextKey = [
      session.serverUrl,
      session.accessToken,
      session.user?.id,
    ].join('|');
    if (_sessionKey == nextKey && _future != null) {
      return;
    }
    _sessionKey = nextKey;
    _future = widget.loader.loadOverview(session);
  }

  void _reload() {
    final session = AppSessionScope.read(context);
    setState(() {
      _future = widget.loader.loadOverview(session);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileCupertino = _isCupertino && constraints.maxWidth < 700;
        return FutureBuilder<LibraryOverviewViewData>(
          future: _future,
          builder: (context, snapshot) {
            final content = _LibraryOverviewBody(
              data: snapshot.data,
              isLoading: snapshot.connectionState != ConnectionState.done,
              error: snapshot.error,
              onRetry: _reload,
            );
            if (isMobileCupertino) {
              return CupertinoPageScaffold(
                navigationBar: const CupertinoNavigationBar(
                  middle: Text('Library'),
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
      },
    );
  }
}

class _LibraryOverviewBody extends StatelessWidget {
  const _LibraryOverviewBody({
    required this.data,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final LibraryOverviewViewData? data;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCupertinoMobile =
        currentAppPlatform == AppPlatform.cupertino &&
        MediaQuery.sizeOf(context).width < 700;
    final horizontalPadding = isCupertinoMobile ? 18.0 : 20.0;
    final topPadding = isCupertinoMobile ? 18.0 : 24.0;
    final bottomPadding = isCupertinoMobile ? 32.0 : 36.0;
    final hasContent = data?.hasContent ?? false;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _LibraryScreenState._desktopContentMaxWidth,
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
                      'Library',
                      style: (isCupertinoMobile
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Browse the collections available on your Jellyfin server.',
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
            child: _LibraryStatusState(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'Loading libraries...',
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        else if (error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _LibraryStatusState(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Could not load your libraries',
              message: 'Try again in a moment.',
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          )
        else if (!hasContent)
          SliverFillRemaining(
            hasScrollBody: false,
            child: const _LibraryStatusState(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'No libraries available',
              message: 'This server does not expose any supported libraries yet.',
            ),
          )
        else
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _LibraryScreenState._desktopContentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    children: [
                      for (final entry in data!.entries) ...[
                        _LibraryOverviewRow(entry: entry),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LibraryOverviewRow extends StatelessWidget {
  const _LibraryOverviewRow({required this.entry});

  final LibraryOverviewEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final itemId = entry.item.id;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (itemId ?? '').isEmpty
            ? null
            : () {
                context.pushNamed(
                  AppRoutes.libraryCollectionName,
                  pathParameters: {'id': itemId!},
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _collectionIcon(entry.item.collectionType),
                  color: scheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.item.name ?? entry.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((entry.subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (entry.artworkUrl != null) ...[
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 112,
                    height: 64,
                    child: Image.network(
                      entry.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryStatusState extends StatelessWidget {
  const _LibraryStatusState({
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

IconData _collectionIcon(String? collectionType) {
  return switch (collectionType?.toLowerCase()) {
    'movies' => Icons.local_movies_outlined,
    'tvshows' => Icons.tv_outlined,
    'music' => Icons.music_note_outlined,
    'boxsets' => Icons.collections_bookmark_outlined,
    'playlists' => Icons.playlist_play_outlined,
    'folders' => Icons.folder_outlined,
    'livetv' => Icons.live_tv_outlined,
    'musicvideos' => Icons.video_library_outlined,
    'photos' => Icons.photo_library_outlined,
    'trailers' => Icons.ondemand_video_outlined,
    'homevideos' => Icons.video_collection_outlined,
    _ => Icons.folder_open_outlined,
  };
}
