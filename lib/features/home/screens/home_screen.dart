import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../../app/session/app_session_scope.dart';
import '../data/home_media_bar_loader.dart';
import '../models/home_media_bar_view_data.dart';
import '../widgets/home_continue_watching_section.dart';
import '../widgets/home_media_bar_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.loader = loadHomeMediaBar});

  final HomeMediaBarLoader loader;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Change this to `poster` to use poster artwork for the mobile hero.
  static const _mobileCarouselArtwork = HomeMediaBarMobileArtwork.primary;

  Future<HomeMediaBarViewData>? _future;
  String? _cacheKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.watch(context);
    final nextKey = [
      session.serverUrl,
      session.accessToken,
      session.user?.id,
    ].join('|');
    if (_cacheKey == nextKey && _future != null) {
      return;
    }
    _cacheKey = nextKey;
    _future = widget.loader(session);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileCupertino =
            currentAppPlatform == AppPlatform.cupertino &&
            constraints.maxWidth < 700;

        return SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: FutureBuilder<HomeMediaBarViewData>(
              future: _future,
              builder: (context, snapshot) {
                final viewData = snapshot.data;
                final isLoading =
                    snapshot.connectionState != ConnectionState.done;

                final content = isLoading
                    ? const _HomeSkeleton()
                    : snapshot.hasError
                    ? _HomeError(
                        onRetry: () {
                          final session = AppSessionScope.watch(context);
                          setState(() {
                            _future = widget.loader(session);
                          });
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              HomeMediaBarCarousel(
                                entries: viewData?.entries ?? const [],
                                source:
                                    viewData?.source ??
                                    JellyfinMediaBarSource.none,
                                mobileArtwork: _mobileCarouselArtwork,
                              ),
                          if ((viewData?.continueWatchingEntries ?? const [])
                              .isNotEmpty) ...[
                            SizedBox(height: isMobileCupertino ? 20 : 28),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobileCupertino ? 14 : 0,
                              ),
                              child: HomeContinueWatchingSection(
                                entries: viewData!.continueWatchingEntries,
                              ),
                            ),
                          ],
                        ],
                      );

                if (isMobileCupertino) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 98),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [content],
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _MobileAppleTvHeader(),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _MobileAppleTvNavBar(),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MobileAppleTvHeader extends StatelessWidget {
  const _MobileAppleTvHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 4),
      child: Row(
        children: [
          Text(
            'tv',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                'DR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileAppleTvNavBar extends StatelessWidget {
  const _MobileAppleTvNavBar();

  static const _items = [
    ('Apple TV', CupertinoIcons.tv, true),
    ('MLS', CupertinoIcons.sportscourt, false),
    ('Downloads', CupertinoIcons.arrow_down_to_line, false),
    ('Search', CupertinoIcons.search, false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in _items)
              _MobileNavItem(
                title: item.$1,
                icon: item.$2,
                selected: item.$3,
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.theme,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.52);

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 28 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 8.6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not load home content',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The Jellyfin media bar request failed. Try again.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
