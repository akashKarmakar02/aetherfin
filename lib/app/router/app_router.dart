import 'package:go_router/go_router.dart';

import '../../features/auth/screens/connect_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/startup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/player/screens/player_screen.dart';
import '../../features/series/screens/series_details_screen.dart';
import '../session/app_session_controller.dart';
import 'app_routes.dart';

GoRouter createAppRouter(AppSessionController sessionController) {
  return GoRouter(
    initialLocation: AppRoutes.startupPath,
    refreshListenable: sessionController,
    redirect: (context, state) {
      if (sessionController.phase == AppSessionPhase.loggedIn) {
        final path = state.uri.path;
        if (path == AppRoutes.homePath ||
            path.startsWith('/series/') ||
            path.startsWith('/player/')) {
          return null;
        }
        print("Hola");
        return AppRoutes.homePath;
      }

      final targetLocation = sessionController.routeLocation;
      if (state.matchedLocation == targetLocation) {
        return null;
      }
      return targetLocation;
    },
    routes: [
      GoRoute(
        path: AppRoutes.startupPath,
        name: AppRoutes.startupName,
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectPath,
        name: AppRoutes.connectName,
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.seriesPath,
        name: AppRoutes.seriesName,
        builder: (context, state) => SeriesDetailsScreen(
          seriesId: state.pathParameters['id'] ?? '',
          initialSeasonIndex: int.tryParse(
            state.uri.queryParameters['seasonIndex'] ?? '',
          ),
          highlightedEpisodeId: state.uri.queryParameters['episodeId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.playerPath,
        name: AppRoutes.playerName,
        builder: (context, state) =>
            PlayerScreen(itemId: state.pathParameters['itemId'] ?? ''),
      ),
    ],
  );
}
