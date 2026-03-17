String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _doubleOrNull(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

Map<String, dynamic> _mapOrEmpty(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

class StreamystatsSearchParams {
  StreamystatsSearchParams({
    required this.query,
    this.limit,
    this.format,
    this.type,
  });

  final String query;
  final int? limit;
  final String? format;
  final String? type;
}

class StreamystatsSearchResultItem {
  StreamystatsSearchResultItem({
    this.id,
    this.type,
    this.subtype,
    this.title,
    this.subtitle,
    this.imageId,
    this.imageTag,
    this.href,
    this.rank,
    this.metadata = const {},
    this.raw = const {},
  });

  final String? id;
  final String? type;
  final String? subtype;
  final String? title;
  final String? subtitle;
  final String? imageId;
  final String? imageTag;
  final String? href;
  final int? rank;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> raw;

  factory StreamystatsSearchResultItem.fromJson(Map<String, dynamic> json) {
    return StreamystatsSearchResultItem(
      id: _stringOrNull(json['id']),
      type: _stringOrNull(json['type']),
      subtype: _stringOrNull(json['subtype']),
      title: _stringOrNull(json['title']),
      subtitle: _stringOrNull(json['subtitle']),
      imageId: _stringOrNull(json['imageId']),
      imageTag: _stringOrNull(json['imageTag']),
      href: _stringOrNull(json['href']),
      rank: _intOrNull(json['rank']),
      metadata: _mapOrEmpty(json['metadata']),
      raw: json,
    );
  }
}

class StreamystatsSearchFullResponse {
  StreamystatsSearchFullResponse({
    this.items = const [],
    this.users = const [],
    this.watchlists = const [],
    this.activities = const [],
    this.sessions = const [],
    this.actors = const [],
    this.total = 0,
    this.error,
    this.raw = const {},
  });

  final List<StreamystatsSearchResultItem> items;
  final List<StreamystatsSearchResultItem> users;
  final List<StreamystatsSearchResultItem> watchlists;
  final List<StreamystatsSearchResultItem> activities;
  final List<StreamystatsSearchResultItem> sessions;
  final List<StreamystatsSearchResultItem> actors;
  final int total;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsSearchFullResponse.fromJson(Map<String, dynamic> json) {
    final data = _mapOrEmpty(json['data']);
    List<StreamystatsSearchResultItem> parse(String key) => _mapList(data[key])
        .map(StreamystatsSearchResultItem.fromJson)
        .toList(growable: false);
    return StreamystatsSearchFullResponse(
      items: parse('items'),
      users: parse('users'),
      watchlists: parse('watchlists'),
      activities: parse('activities'),
      sessions: parse('sessions'),
      actors: parse('actors'),
      total: _intOrNull(data['total']) ?? 0,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsSearchIdsResponse {
  StreamystatsSearchIdsResponse({
    this.movies = const [],
    this.series = const [],
    this.episodes = const [],
    this.seasons = const [],
    this.audio = const [],
    this.actors = const [],
    this.directors = const [],
    this.writers = const [],
    this.total = 0,
    this.error,
    this.raw = const {},
  });

  final List<String> movies;
  final List<String> series;
  final List<String> episodes;
  final List<String> seasons;
  final List<String> audio;
  final List<String> actors;
  final List<String> directors;
  final List<String> writers;
  final int total;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsSearchIdsResponse.fromJson(Map<String, dynamic> json) {
    final data = _mapOrEmpty(json['data']);
    List<String> parse(String key) =>
        (data[key] is List) ? (data[key] as List).map((e) => e.toString()).toList() : const [];
    return StreamystatsSearchIdsResponse(
      movies: parse('movies'),
      series: parse('series'),
      episodes: parse('episodes'),
      seasons: parse('seasons'),
      audio: parse('audio'),
      actors: parse('actors'),
      directors: parse('directors'),
      writers: parse('writers'),
      total: _intOrNull(data['total']) ?? 0,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsRecommendationsParams {
  StreamystatsRecommendationsParams({
    this.serverId,
    this.serverName,
    this.jellyfinServerId,
    this.limit,
    this.type,
    this.range,
    this.format,
    this.includeBasedOn,
    this.includeReasons,
  });

  final int? serverId;
  final String? serverName;
  final String? jellyfinServerId;
  final int? limit;
  final String? type;
  final String? range;
  final String? format;
  final bool? includeBasedOn;
  final bool? includeReasons;
}

class StreamystatsRecommendationItem {
  StreamystatsRecommendationItem({
    this.id,
    this.name,
    this.type,
    this.primaryImageTag,
    this.backdropImageTag,
    this.overview,
    this.year,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? type;
  final String? primaryImageTag;
  final String? backdropImageTag;
  final String? overview;
  final int? year;
  final Map<String, dynamic> raw;

  factory StreamystatsRecommendationItem.fromJson(Map<String, dynamic> json) {
    return StreamystatsRecommendationItem(
      id: _stringOrNull(json['id']),
      name: _stringOrNull(json['name']),
      type: _stringOrNull(json['type']),
      primaryImageTag: _stringOrNull(json['primaryImageTag']),
      backdropImageTag: _stringOrNull(json['backdropImageTag']),
      overview: _stringOrNull(json['overview']),
      year: _intOrNull(json['year']),
      raw: json,
    );
  }
}

class StreamystatsRecommendation {
  StreamystatsRecommendation({
    this.item,
    this.similarity,
    this.basedOn = const [],
    this.reason,
    this.raw = const {},
  });

  final StreamystatsRecommendationItem? item;
  final double? similarity;
  final List<StreamystatsRecommendationItem> basedOn;
  final String? reason;
  final Map<String, dynamic> raw;

  factory StreamystatsRecommendation.fromJson(Map<String, dynamic> json) {
    return StreamystatsRecommendation(
      item: json['item'] is Map
          ? StreamystatsRecommendationItem.fromJson(
              (json['item'] as Map).cast<String, dynamic>(),
            )
          : null,
      similarity: _doubleOrNull(json['similarity']),
      basedOn: _mapList(json['basedOn'])
          .map(StreamystatsRecommendationItem.fromJson)
          .toList(growable: false),
      reason: _stringOrNull(json['reason']),
      raw: json,
    );
  }
}

class StreamystatsRecommendationsFullResponse {
  StreamystatsRecommendationsFullResponse({
    this.data = const [],
    this.error,
    this.raw = const {},
  });

  final List<StreamystatsRecommendation> data;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsRecommendationsFullResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StreamystatsRecommendationsFullResponse(
      data: _mapList(json['data'])
          .map(StreamystatsRecommendation.fromJson)
          .toList(growable: false),
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsRecommendationsIdsResponse {
  StreamystatsRecommendationsIdsResponse({
    this.movies = const [],
    this.series = const [],
    this.total = 0,
    this.error,
    this.raw = const {},
  });

  final List<String> movies;
  final List<String> series;
  final int total;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsRecommendationsIdsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = _mapOrEmpty(json['data']);
    List<String> parse(String key) =>
        (data[key] is List) ? (data[key] as List).map((e) => e.toString()).toList() : const [];
    return StreamystatsRecommendationsIdsResponse(
      movies: parse('movies'),
      series: parse('series'),
      total: _intOrNull(data['total']) ?? 0,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsServerInfo {
  StreamystatsServerInfo({this.id, this.name, this.raw = const {}});

  final int? id;
  final String? name;
  final Map<String, dynamic> raw;

  factory StreamystatsServerInfo.fromJson(Map<String, dynamic> json) {
    return StreamystatsServerInfo(
      id: _intOrNull(json['id']),
      name: _stringOrNull(json['name']),
      raw: json,
    );
  }
}

class StreamystatsWatchlistPreviewItem {
  StreamystatsWatchlistPreviewItem({
    this.id,
    this.name,
    this.type,
    this.primaryImageTag,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? type;
  final String? primaryImageTag;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistPreviewItem.fromJson(Map<String, dynamic> json) {
    return StreamystatsWatchlistPreviewItem(
      id: _stringOrNull(json['id']),
      name: _stringOrNull(json['name']),
      type: _stringOrNull(json['type']),
      primaryImageTag: _stringOrNull(json['primaryImageTag']),
      raw: json,
    );
  }
}

class StreamystatsWatchlistItem {
  StreamystatsWatchlistItem({
    this.id,
    this.name,
    this.type,
    this.productionYear,
    this.runtimeTicks,
    this.genres = const [],
    this.primaryImageTag,
    this.seriesId,
    this.seriesName,
    this.communityRating,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? type;
  final int? productionYear;
  final int? runtimeTicks;
  final List<String> genres;
  final String? primaryImageTag;
  final String? seriesId;
  final String? seriesName;
  final double? communityRating;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistItem.fromJson(Map<String, dynamic> json) {
    return StreamystatsWatchlistItem(
      id: _stringOrNull(json['id']),
      name: _stringOrNull(json['name']),
      type: _stringOrNull(json['type']),
      productionYear: _intOrNull(json['productionYear']),
      runtimeTicks: _intOrNull(json['runtimeTicks']),
      genres: (json['genres'] is List)
          ? (json['genres'] as List).map((e) => e.toString()).toList()
          : const [],
      primaryImageTag: _stringOrNull(json['primaryImageTag']),
      seriesId: _stringOrNull(json['seriesId']),
      seriesName: _stringOrNull(json['seriesName']),
      communityRating: _doubleOrNull(json['communityRating']),
      raw: json,
    );
  }
}

class StreamystatsWatchlistItemEntry {
  StreamystatsWatchlistItemEntry({
    this.id,
    this.watchlistId,
    this.itemId,
    this.position,
    this.addedAt,
    this.item,
    this.raw = const {},
  });

  final int? id;
  final int? watchlistId;
  final String? itemId;
  final int? position;
  final DateTime? addedAt;
  final StreamystatsWatchlistItem? item;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistItemEntry.fromJson(Map<String, dynamic> json) {
    return StreamystatsWatchlistItemEntry(
      id: _intOrNull(json['id']),
      watchlistId: _intOrNull(json['watchlistId']),
      itemId: _stringOrNull(json['itemId']),
      position: _intOrNull(json['position']),
      addedAt: DateTime.tryParse(_stringOrNull(json['addedAt']) ?? ''),
      item: json['item'] is Map
          ? StreamystatsWatchlistItem.fromJson(
              (json['item'] as Map).cast<String, dynamic>(),
            )
          : null,
      raw: json,
    );
  }
}

class StreamystatsWatchlist {
  StreamystatsWatchlist({
    this.id,
    this.serverId,
    this.userId,
    this.name,
    this.description,
    this.isPublic,
    this.isPromoted,
    this.allowedItemType,
    this.defaultSortOrder,
    this.createdAt,
    this.updatedAt,
    this.itemCount,
    this.previewItems = const [],
    this.items = const [],
    this.raw = const {},
  });

  final int? id;
  final int? serverId;
  final String? userId;
  final String? name;
  final String? description;
  final bool? isPublic;
  final bool? isPromoted;
  final String? allowedItemType;
  final String? defaultSortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? itemCount;
  final List<StreamystatsWatchlistPreviewItem> previewItems;
  final List<StreamystatsWatchlistItemEntry> items;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlist.fromJson(Map<String, dynamic> json) {
    return StreamystatsWatchlist(
      id: _intOrNull(json['id']),
      serverId: _intOrNull(json['serverId']),
      userId: _stringOrNull(json['userId']),
      name: _stringOrNull(json['name']),
      description: _stringOrNull(json['description']),
      isPublic: json['isPublic'] == true,
      isPromoted: json['isPromoted'] == true,
      allowedItemType: _stringOrNull(json['allowedItemType']),
      defaultSortOrder: _stringOrNull(json['defaultSortOrder']),
      createdAt: DateTime.tryParse(_stringOrNull(json['createdAt']) ?? ''),
      updatedAt: DateTime.tryParse(_stringOrNull(json['updatedAt']) ?? ''),
      itemCount: _intOrNull(json['itemCount']),
      previewItems: _mapList(json['previewItems'])
          .map(StreamystatsWatchlistPreviewItem.fromJson)
          .toList(growable: false),
      items: _mapList(json['items'])
          .map(StreamystatsWatchlistItemEntry.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }
}

class StreamystatsWatchlistsFullResponse {
  StreamystatsWatchlistsFullResponse({
    this.server,
    this.data = const [],
    this.total = 0,
    this.error,
    this.raw = const {},
  });

  final StreamystatsServerInfo? server;
  final List<StreamystatsWatchlist> data;
  final int total;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistsFullResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StreamystatsWatchlistsFullResponse(
      server: json['server'] is Map
          ? StreamystatsServerInfo.fromJson(
              (json['server'] as Map).cast<String, dynamic>(),
            )
          : null,
      data: _mapList(json['data'])
          .map(StreamystatsWatchlist.fromJson)
          .toList(growable: false),
      total: _intOrNull(json['total']) ?? 0,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsWatchlistDetailIdsResponse {
  StreamystatsWatchlistDetailIdsResponse({
    this.server,
    this.id,
    this.name,
    this.items = const [],
    this.error,
    this.raw = const {},
  });

  final StreamystatsServerInfo? server;
  final int? id;
  final String? name;
  final List<String> items;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistDetailIdsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = _mapOrEmpty(json['data']);
    return StreamystatsWatchlistDetailIdsResponse(
      server: json['server'] is Map
          ? StreamystatsServerInfo.fromJson(
              (json['server'] as Map).cast<String, dynamic>(),
            )
          : null,
      id: _intOrNull(data['id']),
      name: _stringOrNull(data['name']),
      items: (data['items'] is List)
          ? (data['items'] as List).map((e) => e.toString()).toList()
          : const [],
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsWatchlistDetailFullResponse {
  StreamystatsWatchlistDetailFullResponse({
    this.server,
    this.data,
    this.error,
    this.raw = const {},
  });

  final StreamystatsServerInfo? server;
  final StreamystatsWatchlist? data;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistDetailFullResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StreamystatsWatchlistDetailFullResponse(
      server: json['server'] is Map
          ? StreamystatsServerInfo.fromJson(
              (json['server'] as Map).cast<String, dynamic>(),
            )
          : null,
      data: json['data'] is Map
          ? StreamystatsWatchlist.fromJson(
              (json['data'] as Map).cast<String, dynamic>(),
            )
          : null,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsCreateWatchlistRequest {
  StreamystatsCreateWatchlistRequest({
    required this.name,
    this.description,
    this.isPublic,
    this.allowedItemType,
    this.defaultSortOrder,
  });

  final String name;
  final String? description;
  final bool? isPublic;
  final String? allowedItemType;
  final String? defaultSortOrder;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'isPublic': isPublic,
        if (allowedItemType != null) 'allowedItemType': allowedItemType,
        if (defaultSortOrder != null) 'defaultSortOrder': defaultSortOrder,
      };
}

class StreamystatsUpdateWatchlistRequest {
  StreamystatsUpdateWatchlistRequest({
    this.name,
    this.description,
    this.isPublic,
    this.allowedItemType,
    this.defaultSortOrder,
  });

  final String? name;
  final String? description;
  final bool? isPublic;
  final String? allowedItemType;
  final String? defaultSortOrder;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'isPublic': isPublic,
        if (allowedItemType != null) 'allowedItemType': allowedItemType,
        if (defaultSortOrder != null) 'defaultSortOrder': defaultSortOrder,
      };
}

class StreamystatsCreateWatchlistResponse {
  StreamystatsCreateWatchlistResponse({
    this.data,
    this.error,
    this.raw = const {},
  });

  final StreamystatsWatchlist? data;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsCreateWatchlistResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StreamystatsCreateWatchlistResponse(
      data: json['data'] is Map
          ? StreamystatsWatchlist.fromJson(
              (json['data'] as Map).cast<String, dynamic>(),
            )
          : null,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsUpdateWatchlistResponse
    extends StreamystatsCreateWatchlistResponse {
  StreamystatsUpdateWatchlistResponse({
    super.data,
    super.error,
    super.raw,
  });

  factory StreamystatsUpdateWatchlistResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final parsed = StreamystatsCreateWatchlistResponse.fromJson(json);
    return StreamystatsUpdateWatchlistResponse(
      data: parsed.data,
      error: parsed.error,
      raw: parsed.raw,
    );
  }
}

class StreamystatsDeleteWatchlistResponse {
  StreamystatsDeleteWatchlistResponse({
    required this.success,
    this.error,
    this.raw = const {},
  });

  final bool success;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsDeleteWatchlistResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StreamystatsDeleteWatchlistResponse(
      success: json['success'] == true,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsWatchlistItemMutationResponse {
  StreamystatsWatchlistItemMutationResponse({
    this.id,
    this.watchlistId,
    this.itemId,
    this.position,
    this.addedAt,
    this.success,
    this.error,
    this.raw = const {},
  });

  final int? id;
  final int? watchlistId;
  final String? itemId;
  final int? position;
  final DateTime? addedAt;
  final bool? success;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsWatchlistItemMutationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = _mapOrEmpty(json['data']);
    return StreamystatsWatchlistItemMutationResponse(
      id: _intOrNull(data['id']),
      watchlistId: _intOrNull(data['watchlistId']),
      itemId: _stringOrNull(data['itemId']),
      position: _intOrNull(data['position']),
      addedAt: DateTime.tryParse(_stringOrNull(data['addedAt']) ?? ''),
      success: json['success'] as bool?,
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}

class StreamystatsGetWatchlistsResponse {
  StreamystatsGetWatchlistsResponse({
    this.data = const [],
    this.error,
    this.raw = const {},
  });

  final List<StreamystatsWatchlist> data;
  final String? error;
  final Map<String, dynamic> raw;

  factory StreamystatsGetWatchlistsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StreamystatsGetWatchlistsResponse(
      data: _mapList(json['data'])
          .map(StreamystatsWatchlist.fromJson)
          .toList(growable: false),
      error: _stringOrNull(json['error']),
      raw: json,
    );
  }
}
