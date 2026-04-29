import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import '../theme/cupertino_app_theme.dart';
import '../theme/linux_app_theme.dart';
import '../theme/windows_app_theme.dart';
import 'router/app_routes.dart';
import 'platform/app_platform.dart';
import 'session/app_session_controller.dart';
import 'session/app_session_scope.dart';
import 'shell/platform_shell.dart';

class AetherfinApp extends StatelessWidget {
  const AetherfinApp({
    super.key,
    required this.router,
    required this.sessionController,
    this.enableLinuxTray = true,
  });

  final GoRouter router;
  final AppSessionController sessionController;
  final bool enableLinuxTray;

  String _currentLinuxPath(GoRouter router) {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isNotEmpty) {
      final activePath = configuration.last.matchedLocation;
      if (activePath.isNotEmpty) {
        return activePath;
      }
    }

    final routeInfoPath = router.routeInformationProvider.value.uri.path;
    if (routeInfoPath.isNotEmpty) {
      return routeInfoPath;
    }

    return AppRoutes.startupPath;
  }

  bool _isFullscreenPath(String path) {
    return path.startsWith('/player/');
  }

  @override
  Widget build(BuildContext context) {
    return AppSessionScope(
      notifier: sessionController,
      child: switch (currentAppPlatform) {
        AppPlatform.linux => YaruTheme(
          builder: (context, yaru, child) {
            final lightTheme = LinuxAppTheme.resolve(yaru.theme);
            final darkTheme = LinuxAppTheme.resolve(yaru.darkTheme);
            return MaterialApp.router(
              title: 'Aetherfin',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              routerConfig: router,
              builder: (context, routeChild) {
                return AnimatedBuilder(
                  animation: router.routerDelegate,
                  builder: (context, _) {
                    final currentPath = _currentLinuxPath(router);
                    if (_isFullscreenPath(currentPath)) {
                      return routeChild ?? const SizedBox.shrink();
                    }
                    return LinuxWindowShell(
                      enableTray: enableLinuxTray,
                      extendBodyBehindTitleBar:
                          currentPath.startsWith('/series/'),
                      showBackButton:
                          currentPath.startsWith('/series/') ||
                          currentPath.startsWith('/library/'),
                      isHomeSelected: currentPath == AppRoutes.homePath,
                      isLibrarySelected: currentPath == AppRoutes.libraryPath,
                      isLoading: currentPath == AppRoutes.startupPath,
                      isSearchSelected: currentPath == AppRoutes.searchPath,
                      onHomePressed: () => router.goNamed(AppRoutes.homeName),
                      onLibraryPressed: () =>
                          router.goNamed(AppRoutes.libraryName),
                      showTitlebarOption: [
                        "/home",
                        "/library",
                        "/search",
                      ].contains(currentPath),
                      onSearchPressed: () =>
                          router.goNamed(AppRoutes.searchName),
                      onBackPressed: () {
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          router.goNamed(AppRoutes.homeName);
                        }
                      },
                      child: routeChild ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
        ),
        AppPlatform.cupertino => CupertinoApp.router(
          title: 'Aetherfin',
          debugShowCheckedModeBanner: false,
          theme: CupertinoAppThemes.theme,
          routerConfig: router,
          builder: (context, routeChild) {
            return ValueListenableBuilder<RouteInformation>(
              valueListenable: router.routeInformationProvider,
              builder: (context, routeInformation, _) {
                final currentPath = routeInformation.uri.path;
                if (_isFullscreenPath(currentPath)) {
                  return routeChild ?? const SizedBox.shrink();
                }
                return CupertinoRootShell(
                  child: routeChild ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
        AppPlatform.windows => MaterialApp.router(
          title: 'Aetherfin',
          debugShowCheckedModeBanner: false,
          theme: WindowsAppTheme.build(),
          routerConfig: router,
          builder: (context, routeChild) {
            return ValueListenableBuilder<RouteInformation>(
              valueListenable: router.routeInformationProvider,
              builder: (context, routeInformation, _) {
                final currentPath = routeInformation.uri.path;
                if (_isFullscreenPath(currentPath)) {
                  return routeChild ?? const SizedBox.shrink();
                }
                return DesktopMaterialShell(
                  child: routeChild ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
        AppPlatform.material => MaterialApp.router(
          title: 'Aetherfin',
          debugShowCheckedModeBanner: false,
          theme: WindowsAppTheme.build(),
          routerConfig: router,
          builder: (context, routeChild) {
            return ValueListenableBuilder<RouteInformation>(
              valueListenable: router.routeInformationProvider,
              builder: (context, routeInformation, _) {
                final currentPath = routeInformation.uri.path;
                if (_isFullscreenPath(currentPath)) {
                  return routeChild ?? const SizedBox.shrink();
                }
                return DesktopMaterialShell(
                  child: routeChild ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      },
    );
  }
}
