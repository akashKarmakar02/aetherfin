import 'package:dio/dio.dart';

import '../../../api/api.dart';
import '../../../app/session/app_session_controller.dart';
import '../models/library_view_data.dart';

class AppLibraryLoader {
  const AppLibraryLoader({this.dio});

  final Dio? dio;

  static const _imageTypes = ['Primary', 'Backdrop', 'Thumb'];
  static const _libraryFields = ['ChildCount'];
  static const _itemFields = ['Overview', 'PrimaryImageAspectRatio'];

  Future<LibraryOverviewViewData> loadOverview(
    AppSessionController session,
  ) async {
    final context = _LibraryRequestContext.fromSession(session, dio);
    if (context == null) {
      return const LibraryOverviewViewData();
    }

    final response = await context.libraryApi.getUserViews(
      userId: context.userId,
      fields: _libraryFields,
      enableImageTypes: _imageTypes,
    );

    final entries = response.items
        .where((item) => item.collectionType?.toLowerCase() != 'books')
        .map(
          (item) => LibraryOverviewEntry(
            item: item,
            label: collectionLabelForType(item.collectionType),
            artworkUrl: _buildLibraryArtwork(context.mediaApi, item),
            subtitle: _buildLibrarySubtitle(item),
          ),
        )
        .toList(growable: false);

    return LibraryOverviewViewData(entries: entries);
  }

  Future<LibraryCollectionPageViewData?> loadCollectionPage(
    AppSessionController session,
    String libraryId, {
    int startIndex = 0,
    int limit = 60,
    JellyfinBaseItem? library,
  }) async {
    final context = _LibraryRequestContext.fromSession(session, dio);
    if (context == null || libraryId.isEmpty) {
      return null;
    }

    final resolvedLibrary =
        library ??
        await context.libraryApi.getItemById(
          itemId: libraryId,
          userId: context.userId,
          fields: _libraryFields,
          enableImageTypes: _imageTypes,
          enableUserData: true,
        );
    if (resolvedLibrary == null) {
      return null;
    }

    final response = await context.libraryApi.getItems(
      JellyfinItemsQuery(
        userId: context.userId,
        parentId: libraryId,
        recursive: true,
        limit: limit,
        fields: _itemFields,
        enableImageTypes: _imageTypes,
        enableUserData: true,
        sortBy: const ['SortName', 'ProductionYear'],
        includeItemTypes: includeItemTypesForCollection(
          resolvedLibrary.collectionType,
        ),
        extra: {
          'StartIndex': startIndex,
          'SortOrder': 'Ascending',
          'ImageTypeLimit': 1,
        },
      ),
    );

    return LibraryCollectionPageViewData(
      library: resolvedLibrary,
      entries: response.items
          .map(
            (item) => LibraryCollectionEntry(
              item: item,
              artworkUrl: _buildCollectionArtwork(context.mediaApi, item),
              subtitle: buildLibraryItemSubtitle(item),
            ),
          )
          .toList(growable: false),
      totalCount: response.totalRecordCount,
      startIndex: startIndex,
    );
  }
}

class _LibraryRequestContext {
  const _LibraryRequestContext({
    required this.userId,
    required this.libraryApi,
    required this.mediaApi,
  });

  final String userId;
  final JellyfinLibraryApi libraryApi;
  final JellyfinMediaApi mediaApi;

  static _LibraryRequestContext? fromSession(
    AppSessionController session,
    Dio? dio,
  ) {
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
      return null;
    }

    return _LibraryRequestContext(
      userId: userId,
      libraryApi: JellyfinLibraryApi(
        baseUrl: baseUrl,
        clientInfo: clientInfo,
        accessToken: accessToken,
        dio: dio,
      ),
      mediaApi: JellyfinMediaApi(
        baseUrl: baseUrl,
        clientInfo: clientInfo,
        accessToken: accessToken,
        dio: dio,
      ),
    );
  }
}

List<String>? includeItemTypesForCollection(String? collectionType) {
  return switch (collectionType?.toLowerCase()) {
    'movies' => const ['Movie'],
    'tvshows' => const ['Series'],
    'boxsets' => const ['BoxSet'],
    'homevideos' => const ['Video'],
    'musicvideos' => const ['MusicVideo'],
    _ => null,
  };
}

String collectionLabelForType(String? collectionType) {
  return switch (collectionType?.toLowerCase()) {
    'movies' => 'Movies',
    'tvshows' => 'Series',
    'music' => 'Music',
    'boxsets' => 'Collections',
    'playlists' => 'Playlists',
    'folders' => 'Folders',
    'livetv' => 'Live TV',
    'musicvideos' => 'Music videos',
    'photos' => 'Photos',
    'trailers' => 'Trailers',
    'homevideos' => 'Home videos',
    _ => 'Library',
  };
}

String? buildLibraryItemSubtitle(JellyfinBaseItem item) {
  return switch (item.type) {
    'Series' => _joinLabels(['Series', _yearLabel(item)]),
    'Movie' => _joinLabels(['Movie', _yearLabel(item)]),
    'BoxSet' => 'Collection',
    'Video' => _yearLabel(item) ?? 'Video',
    'MusicVideo' => _yearLabel(item) ?? 'Music video',
    _ => _yearLabel(item),
  };
}

String? _buildLibrarySubtitle(JellyfinBaseItem item) {
  final count = item.childCount;
  final countLabel = count == null
      ? null
      : count == 1
      ? '1 item'
      : '$count items';
  return _joinLabels([
    collectionLabelForType(item.collectionType),
    countLabel,
  ]);
}

String? _buildLibraryArtwork(
  JellyfinMediaApi mediaApi,
  JellyfinBaseItem item,
) {
  return mediaApi.buildPrimaryImageUrl(
        item: item,
        width: 320,
        height: 180,
      ) ??
      mediaApi.buildBackdropUrl(
        itemId: item.id,
        imageTag: item.backdropImageTags.firstOrNull,
        width: 320,
      );
}

String? _buildCollectionArtwork(
  JellyfinMediaApi mediaApi,
  JellyfinBaseItem item,
) {
  return mediaApi.buildPrimaryImageUrl(
        item: item,
        width: 360,
        height: 540,
      ) ??
      mediaApi.buildThumbImageUrlById(
        itemId: item.id,
        imageTag: item.imageTags?.thumb,
        width: 360,
      ) ??
      mediaApi.buildBackdropUrl(
        itemId: item.id,
        imageTag: item.backdropImageTags.firstOrNull,
        width: 360,
      );
}

String? _yearLabel(JellyfinBaseItem item) {
  final year = item.productionYear;
  if (year == null || year <= 0) {
    return null;
  }
  return '$year';
}

String? _joinLabels(List<String?> labels) {
  final filtered = labels
      .whereType<String>()
      .where((label) => label.trim().isNotEmpty)
      .toList(growable: false);
  if (filtered.isEmpty) {
    return null;
  }
  return filtered.join(' · ');
}
