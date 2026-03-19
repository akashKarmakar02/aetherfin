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
  const homeFields = ['Genres'];
  const homeImageTypes = ['Primary', 'Backdrop', 'Thumb', 'Logo'];

  try {
    final hasPluginFuture = pluginApi.hasMediaBarPlugin();
    final resumeItemsFuture = libraryApi.getResumeItems(
      userId: userId,
      startIndex: 0,
      limit: 10,
      fields: homeFields,
      enableImageTypes: homeImageTypes,
      includeItemTypes: const ['Movie', 'Series', 'Episode'],
    );
    final nextUpItemsFuture = libraryApi.getNextUp(
      userId: userId,
      fields: homeFields,
      enableImageTypes: homeImageTypes,
      limit: 10,
    );
    final recentlyAddedItemsFuture = libraryApi.getItems(
      JellyfinItemsQuery(
        userId: userId,
        recursive: true,
        limit: 12,
        includeItemTypes: const ['Movie', 'Series', 'Episode'],
        enableUserData: true,
        fields: homeFields,
        enableImageTypes: homeImageTypes,
        sortBy: const ['DateCreated'],
        extra: const {'SortOrder': 'Descending'},
      ),
    );

    final hasPlugin = await hasPluginFuture;
    final content = hasPlugin
        ? await mediaApi.fetchMediaBarContent(
            userId: userId,
            limit: 8,
          )
        : JellyfinMediaBarContent(source: JellyfinMediaBarSource.none);
    final resumeItems = await resumeItemsFuture;
    final nextUpItems = await nextUpItemsFuture;
    final recentlyAddedItems = await recentlyAddedItemsFuture;
    final entries = content.items
        .map((item) => _buildEntry(mediaApi, item))
        .toList(growable: false);
    final continueWatchingEntries = resumeItems.items
        .map((item) => _buildEntry(mediaApi, item))
        .toList(growable: false);
    final nextUpEntries = nextUpItems
        .map((item) => _buildEntry(mediaApi, item))
        .toList(growable: false);
    final recentlyAddedEntries = recentlyAddedItems.items
        .map((item) => _buildEntry(mediaApi, item))
        .toList(growable: false);

    return HomeMediaBarViewData(
      hasPlugin: hasPlugin,
      source: content.source,
      entries: entries,
      continueWatchingEntries: continueWatchingEntries,
      nextUpEntries: nextUpEntries,
      recentlyAddedEntries: recentlyAddedEntries,
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
