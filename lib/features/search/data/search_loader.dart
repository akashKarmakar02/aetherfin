import 'package:dio/dio.dart';

import '../../../api/api.dart';
import '../../../app/session/app_session_controller.dart';
import '../models/search_view_data.dart';

class AppSearchLoader {
  const AppSearchLoader({this.dio});

  final Dio? dio;

  static const _resultLimit = 10;
  static const _imageTypes = ['Primary', 'Backdrop', 'Thumb'];
  static const _fields = ['Overview'];
  static const _sections = <_SearchSectionSpec>[
    _SearchSectionSpec(
      title: 'Movies',
      jellyfinType: 'Movie',
      artworkKind: SearchArtworkKind.poster,
      streamyStatsType: 'movies',
      supportsStreamyStats: true,
    ),
    _SearchSectionSpec(
      title: 'Series',
      jellyfinType: 'Series',
      artworkKind: SearchArtworkKind.poster,
      streamyStatsType: 'series',
      supportsStreamyStats: true,
    ),
    _SearchSectionSpec(
      title: 'Episodes',
      jellyfinType: 'Episode',
      artworkKind: SearchArtworkKind.landscape,
      streamyStatsType: 'episodes',
      supportsStreamyStats: true,
    ),
    _SearchSectionSpec(
      title: 'Collections',
      jellyfinType: 'BoxSet',
      artworkKind: SearchArtworkKind.poster,
      supportsStreamyStats: false,
    ),
    _SearchSectionSpec(
      title: 'Actors',
      jellyfinType: 'Person',
      artworkKind: SearchArtworkKind.circle,
      streamyStatsType: 'actors',
      supportsStreamyStats: true,
    ),
  ];

  Future<SearchViewData> load(
    AppSessionController session,
    String rawQuery,
  ) async {
    final query = rawQuery.trim();
    final baseUrl = session.serverUrl;
    final accessToken = session.accessToken;
    final clientInfo = session.clientInfo;
    final userId = session.user?.id;

    if (query.isEmpty ||
        baseUrl == null ||
        accessToken == null ||
        accessToken.isEmpty ||
        clientInfo == null ||
        userId == null ||
        userId.isEmpty) {
      return const SearchViewData(
        query: '',
        backend: SearchBackend.jellyfin,
      );
    }

    final pluginApi = JellyfinPluginApi(
      baseUrl: baseUrl,
      clientInfo: clientInfo,
      accessToken: accessToken,
      dio: dio,
    );
    final libraryApi = JellyfinLibraryApi(
      baseUrl: baseUrl,
      clientInfo: clientInfo,
      accessToken: accessToken,
      dio: dio,
    );
    final mediaApi = JellyfinMediaApi(
      baseUrl: baseUrl,
      clientInfo: clientInfo,
      accessToken: accessToken,
      dio: dio,
    );

    final pluginConfig = await _loadPluginConfig(pluginApi);
    final backend = _resolveBackend(
      pluginConfig: pluginConfig,
      hasAccessToken: accessToken.isNotEmpty,
    );

    final sections = await Future.wait(
      _sections.map(
        (section) => _loadSection(
          section,
          query: query,
          userId: userId,
          backend: backend,
          config: pluginConfig,
          libraryApi: libraryApi,
          mediaApi: mediaApi,
          accessToken: accessToken,
        ),
      ),
    );

    return SearchViewData(
      query: query,
      backend: backend,
      sections: sections.whereType<SearchSectionViewData>().toList(growable: false),
    );
  }

  Future<StreamyfinPluginConfig?> _loadPluginConfig(
    JellyfinPluginApi pluginApi,
  ) async {
    try {
      return await pluginApi.getStreamyfinPluginConfig();
    } catch (_) {
      return null;
    }
  }

  SearchBackend _resolveBackend({
    required StreamyfinPluginConfig? pluginConfig,
    required bool hasAccessToken,
  }) {
    final engine = pluginConfig?.searchEngine?.value.trim().toLowerCase();
    return switch (engine) {
      'marlin'
          when (pluginConfig?.marlinServerUrl?.value.trim().isNotEmpty ??
              false) =>
        SearchBackend.marlin,
      'streamystats'
          when hasAccessToken &&
              (pluginConfig?.streamyStatsServerUrl?.value.trim().isNotEmpty ??
                  false) =>
        SearchBackend.streamystats,
      _ => SearchBackend.jellyfin,
    };
  }

  Future<SearchSectionViewData?> _loadSection(
    _SearchSectionSpec section, {
    required String query,
    required String userId,
    required SearchBackend backend,
    required StreamyfinPluginConfig? config,
    required JellyfinLibraryApi libraryApi,
    required JellyfinMediaApi mediaApi,
    required String accessToken,
  }) async {
    if (backend == SearchBackend.streamystats &&
        !section.supportsStreamyStats) {
      return null;
    }

    final items = switch (backend) {
      SearchBackend.jellyfin => await _searchJellyfin(
          libraryApi,
          userId: userId,
          query: query,
          section: section,
        ),
      SearchBackend.marlin => await _searchMarlin(
          libraryApi,
          userId: userId,
          query: query,
          section: section,
          serverUrl: config?.marlinServerUrl?.value,
        ),
      SearchBackend.streamystats => await _searchStreamyStats(
          libraryApi,
          userId: userId,
          query: query,
          section: section,
          serverUrl: config?.streamyStatsServerUrl?.value,
          accessToken: accessToken,
        ),
    };

    if (items.isEmpty) {
      return null;
    }

    return SearchSectionViewData(
      title: section.title,
      entries: items
          .map((item) => _buildEntry(mediaApi, item, section.artworkKind))
          .toList(growable: false),
    );
  }

  Future<List<JellyfinBaseItem>> _searchJellyfin(
    JellyfinLibraryApi libraryApi, {
    required String userId,
    required String query,
    required _SearchSectionSpec section,
  }) async {
    final response = await libraryApi.getItems(
      JellyfinItemsQuery(
        userId: userId,
        searchTerm: query,
        limit: _resultLimit,
        recursive: true,
        includeItemTypes: [section.jellyfinType],
        enableUserData: true,
        fields: _fields,
        enableImageTypes: _imageTypes,
      ),
    );
    return response.items;
  }

  Future<List<JellyfinBaseItem>> _searchMarlin(
    JellyfinLibraryApi libraryApi, {
    required String userId,
    required String query,
    required _SearchSectionSpec section,
    required String? serverUrl,
  }) async {
    final normalizedUrl = serverUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return _searchJellyfin(
        libraryApi,
        userId: userId,
        query: query,
        section: section,
      );
    }

    final marlinApi = MarlinSearchApi(baseUrl: normalizedUrl, dio: dio);
    try {
      final response = await marlinApi.search(
        query: query,
        includeItemTypes: [section.jellyfinType],
      );
      return _lookupItemsByIds(
        libraryApi,
        userId: userId,
        ids: response.ids,
      );
    } catch (_) {
      return _searchJellyfin(
        libraryApi,
        userId: userId,
        query: query,
        section: section,
      );
    }
  }

  Future<List<JellyfinBaseItem>> _searchStreamyStats(
    JellyfinLibraryApi libraryApi, {
    required String userId,
    required String query,
    required _SearchSectionSpec section,
    required String? serverUrl,
    required String accessToken,
  }) async {
    final normalizedUrl = serverUrl?.trim();
    if (normalizedUrl == null ||
        normalizedUrl.isEmpty ||
        section.streamyStatsType == null) {
      return _searchJellyfin(
        libraryApi,
        userId: userId,
        query: query,
        section: section,
      );
    }

    final streamyStatsApi = StreamystatsApi(
      baseUrl: normalizedUrl,
      jellyfinToken: accessToken,
      dio: dio,
    );

    try {
      final response = await streamyStatsApi.searchIds(
        query,
        type: section.streamyStatsType,
        limit: _resultLimit,
      );
      final ids = switch (section.jellyfinType) {
        'Movie' => response.movies,
        'Series' => response.series,
        'Episode' => response.episodes,
        'Person' => response.actors,
        _ => const <String>[],
      };
      return _lookupItemsByIds(
        libraryApi,
        userId: userId,
        ids: ids,
      );
    } catch (_) {
      return _searchJellyfin(
        libraryApi,
        userId: userId,
        query: query,
        section: section,
      );
    }
  }

  Future<List<JellyfinBaseItem>> _lookupItemsByIds(
    JellyfinLibraryApi libraryApi, {
    required String userId,
    required List<String> ids,
  }) async {
    final orderedIds = ids
        .where((id) => id.trim().isNotEmpty)
        .take(_resultLimit)
        .toList(growable: false);
    if (orderedIds.isEmpty) {
      return const [];
    }

    final response = await libraryApi.getItems(
      JellyfinItemsQuery(
        userId: userId,
        ids: orderedIds,
        fields: _fields,
        enableUserData: true,
        enableImageTypes: _imageTypes,
      ),
    );
    final itemsById = <String, JellyfinBaseItem>{
      for (final item in response.items)
        if ((item.id ?? '').isNotEmpty) item.id!: item,
    };
    return orderedIds
        .map((id) => itemsById[id])
        .whereType<JellyfinBaseItem>()
        .toList(growable: false);
  }

  SearchResultEntry _buildEntry(
    JellyfinMediaApi mediaApi,
    JellyfinBaseItem item,
    SearchArtworkKind artworkKind,
  ) {
    final artworkUrl = switch (artworkKind) {
      SearchArtworkKind.poster => mediaApi.buildPrimaryImageUrl(
          item: item,
          width: 280,
          height: 420,
          quality: 84,
        ),
      SearchArtworkKind.landscape => _buildLandscapeArtworkUrl(mediaApi, item),
      SearchArtworkKind.circle => mediaApi.buildPrimaryImageUrl(
          item: item,
          width: 200,
          height: 200,
          quality: 84,
        ),
    };

    return SearchResultEntry(
      item: item,
      artworkKind: artworkKind,
      artworkUrl: artworkUrl,
      subtitle: _buildSubtitle(item),
    );
  }
}

String? _buildLandscapeArtworkUrl(
  JellyfinMediaApi mediaApi,
  JellyfinBaseItem item,
) {
  final webPrimary = mediaApi.buildPrimaryImageUrlById(
    itemId: item.id,
    imageTag: item.imageTags?.primary,
    width: 480,
    height: 270,
    quality: 84,
  );
  if (webPrimary != null) {
    return webPrimary;
  }

  final episodeThumb = mediaApi.buildThumbImageUrlById(
    itemId: item.id,
    imageTag: item.imageTags?.thumb,
    width: 480,
    quality: 84,
  );
  if (episodeThumb != null) {
    return episodeThumb;
  }

  if (item.parentBackdropItemId != null && item.parentThumbImageTag != null) {
    final parentThumb = mediaApi.buildThumbImageUrlById(
      itemId: item.parentBackdropItemId,
      imageTag: item.parentThumbImageTag,
      width: 480,
      quality: 84,
    );
    if (parentThumb != null) {
      return parentThumb;
    }
  }

  final backdrop = mediaApi.buildBackdropUrl(
    itemId: item.id,
    imageTag: item.backdropImageTags.firstOrNull ?? item.imageTags?.backdrop,
    width: 640,
    quality: 84,
  );
  if (backdrop != null) {
    return backdrop;
  }

  return mediaApi.buildPrimaryImageUrl(
    item: item,
    width: 420,
    quality: 84,
  );
}

class _SearchSectionSpec {
  const _SearchSectionSpec({
    required this.title,
    required this.jellyfinType,
    required this.artworkKind,
    required this.supportsStreamyStats,
    this.streamyStatsType,
  });

  final String title;
  final String jellyfinType;
  final SearchArtworkKind artworkKind;
  final bool supportsStreamyStats;
  final String? streamyStatsType;
}

String? _buildSubtitle(JellyfinBaseItem item) {
  return switch (item.type) {
    'Episode' => _joinLabels([
        item.seriesName,
        _episodeCode(
          seasonNumber: item.parentIndexNumber,
          episodeNumber: item.indexNumber,
        ),
      ]),
    'Series' => _joinLabels(['Series', _yearLabel(item.productionYear)]),
    'Movie' => _joinLabels(['Movie', _yearLabel(item.productionYear)]),
    'BoxSet' => 'Collection',
    'Person' => 'Actor',
    _ => _yearLabel(item.productionYear),
  };
}

String? _yearLabel(int? year) {
  if (year == null || year <= 0) {
    return null;
  }
  return '$year';
}

String? _episodeCode({
  required int? seasonNumber,
  required int? episodeNumber,
}) {
  final parts = [
    if (seasonNumber != null) 'S$seasonNumber',
    if (episodeNumber != null) 'E$episodeNumber',
  ];
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' ');
}

String? _joinLabels(List<String?> labels) {
  final values = labels
      .whereType<String>()
      .where((label) => label.isNotEmpty)
      .toList(growable: false);
  if (values.isEmpty) {
    return null;
  }
  return values.join(' • ');
}
