import '../../../api/api.dart';
import '../../../app/session/app_session_controller.dart';
import '../models/home_media_bar_view_data.dart';

typedef HomeMediaBarLoader =
    Future<HomeMediaBarViewData> Function(AppSessionController session);

Future<HomeMediaBarViewData> loadHomeMediaBar(
  AppSessionController session,
) async {
  final baseUrl = session.serverUrl;
  final accessToken = session.accessToken;
  final clientInfo = session.clientInfo;
  final userId = session.user?.id;

  if (baseUrl == null ||
      accessToken == null ||
      accessToken.isEmpty ||
      clientInfo == null ||
      userId == null ||
      userId.isEmpty) {
    return const HomeMediaBarViewData(
      hasPlugin: false,
      source: JellyfinMediaBarSource.none,
    );
  }

  final pluginApi = JellyfinPluginApi(
    baseUrl: baseUrl,
    clientInfo: clientInfo,
    accessToken: accessToken,
  );
  final mediaApi = JellyfinMediaApi(
    baseUrl: baseUrl,
    clientInfo: clientInfo,
    accessToken: accessToken,
  );
  final libraryApi = JellyfinLibraryApi(
    baseUrl: baseUrl,
    clientInfo: clientInfo,
    accessToken: accessToken,
  );

  try {
    final hasPlugin = await pluginApi.hasMediaBarPlugin();
    final content = hasPlugin
        ? await mediaApi.fetchMediaBarContent(
            userId: userId,
            limit: 8,
          )
        : JellyfinMediaBarContent(source: JellyfinMediaBarSource.none);
    final resumeItems = await libraryApi.getResumeItems(
      userId: userId,
      startIndex: 0,
      limit: 10,
      fields: const ['Genres'],
      enableImageTypes: const ['Primary', 'Backdrop', 'Thumb', 'Logo'],
      includeItemTypes: const ['Movie', 'Series', 'Episode'],
    );
    final entries = content.items.map((item) => _buildEntry(mediaApi, item)).toList(
          growable: false,
        );
    final continueWatchingEntries = resumeItems.items
        .map((item) => _buildEntry(mediaApi, item))
        .toList(growable: false);

    return HomeMediaBarViewData(
      hasPlugin: hasPlugin,
      source: content.source,
      entries: entries,
      continueWatchingEntries: continueWatchingEntries,
    );
  } catch (_) {
    return const HomeMediaBarViewData(
      hasPlugin: false,
      source: JellyfinMediaBarSource.none,
    );
  }
}

HomeMediaBarEntry _buildEntry(JellyfinMediaApi mediaApi, JellyfinBaseItem item) {
  return HomeMediaBarEntry(
    item: item,
    backdropUrl: _buildBackdropUrl(mediaApi, item),
    primaryUrl: mediaApi.buildPrimaryImageUrl(
      item: item,
      width: 900,
      quality: 88,
    ),
    logoUrl: mediaApi.buildLogoImageUrlById(
      itemId: item.id,
      imageTag: item.imageTags?.logo ?? item.parentLogoImageTag,
      width: 720,
    ),
    posterUrl: mediaApi.buildPrimaryImageUrl(
      item: item,
      width: 420,
      quality: 84,
    ),
  );
}

String? _buildBackdropUrl(JellyfinMediaApi mediaApi, JellyfinBaseItem item) {
  final directBackdropTag =
      item.backdropImageTags.firstOrNull ?? item.imageTags?.backdrop;
  if (directBackdropTag != null) {
    final directBackdrop = mediaApi.buildBackdropUrl(
      itemId: item.id,
      imageTag: directBackdropTag,
      width: 1600,
      quality: 84,
    );
    if (directBackdrop != null) {
      return directBackdrop;
    }
  }

  final parentBackdrop = mediaApi.buildParentBackdropImageUrl(
    item: item,
    width: 1600,
    quality: 84,
  );
  if (parentBackdrop != null) {
    return parentBackdrop;
  }

  return mediaApi.buildPrimaryImageUrl(
    item: item,
    width: 1200,
    quality: 84,
  );
}
