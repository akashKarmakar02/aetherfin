import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/platform/app_platform.dart';
import '../../../app/session/app_session_scope.dart';
import '../../../shared/widgets/mobile_cupertino_media_chrome.dart';
import '../data/home_media_bar_loader.dart';
import '../models/home_media_bar_view_data.dart';
import '../widgets/home_continue_watching_section.dart';
import '../widgets/home_media_bar_carousel.dart';
import '../widgets/home_media_shelf_section.dart';

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
                                viewData?.source ?? JellyfinMediaBarSource.none,
                            mobileArtwork: _mobileCarouselArtwork,
                          ),
                          // SizedBox(height: 250, width: 500),
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
                          if ((viewData?.nextUpEntries ?? const []).isNotEmpty) ...[
                            SizedBox(height: isMobileCupertino ? 20 : 28),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobileCupertino ? 14 : 0,
                              ),
                              child: HomeMediaShelfSection(
                                title: 'Next Up',
                                entries: viewData!.nextUpEntries,
                              ),
                            ),
                          ],
                          if ((viewData?.recentlyAddedEntries ?? const [])
                              .isNotEmpty) ...[
                            SizedBox(height: isMobileCupertino ? 20 : 28),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobileCupertino ? 14 : 0,
                              ),
                              child: HomeMediaShelfSection(
                                title: 'Recently Added',
                                entries: viewData!.recentlyAddedEntries,
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
                        child: MobileCupertinoMediaHeader(),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: MobileCupertinoMediaNavBar(
                          selectedDestination: MobileCupertinoDestination.home,
                          onHomePressed: null,
                          onSearchPressed: () =>
                              context.goNamed(AppRoutes.searchName),
                        ),
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
