import 'package:dio/dio.dart';

import '../models/jellyfin_models.dart';
import 'jellyfin_api_base.dart';

String? _csv(List<String>? values) =>
    (values == null || values.isEmpty) ? null : values.join(',');

class JellyfinItemsQuery {
  JellyfinItemsQuery({
    this.userId,
    this.ids,
    this.fields,
    this.enableImageTypes,
    this.includeItemTypes,
    this.searchTerm,
    this.parentId,
    this.limit,
    this.recursive,
    this.hasOverview,
    this.isPlayed,
    this.enableUserData,
    this.sortBy,
    this.genres,
    this.filters,
    this.extra = const {},
  });

  final String? userId;
  final List<String>? ids;
  final List<String>? fields;
  final List<String>? enableImageTypes;
  final List<String>? includeItemTypes;
  final String? searchTerm;
  final String? parentId;
  final int? limit;
  final bool? recursive;
  final bool? hasOverview;
  final bool? isPlayed;
  final bool? enableUserData;
  final List<String>? sortBy;
  final List<String>? genres;
  final List<String>? filters;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toQueryParameters() {
    return {
      'UserId': userId,
      'Ids': _csv(ids),
      'Fields': _csv(fields),
      'EnableImageTypes': _csv(enableImageTypes),
      'IncludeItemTypes': _csv(includeItemTypes),
      'SearchTerm': searchTerm,
      'ParentId': parentId,
      'Limit': limit,
      'Recursive': recursive,
      'HasOverview': hasOverview,
      'IsPlayed': isPlayed,
      'EnableUserData': enableUserData,
      'SortBy': _csv(sortBy),
      'Genres': _csv(genres),
      'Filters': _csv(filters),
      ...extra,
    };
  }
}

class JellyfinLibraryApi extends JellyfinApiBase {
  JellyfinLibraryApi({
    required super.baseUrl,
    required super.clientInfo,
    required super.accessToken,
    super.dio,
  });

  Future<JellyfinBaseItemQueryResult> getItems(
    JellyfinItemsQuery query, {
    CancelToken? cancelToken,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/Items',
      queryParameters: query.toQueryParameters(),
      options: jellyfinOptions(),
      cancelToken: cancelToken,
    );
    return JellyfinBaseItemQueryResult.fromJson(response.data ?? {});
  }

  Future<JellyfinBaseItem?> getItemById({
    required String itemId,
    String? userId,
    List<String>? fields,
    List<String>? enableImageTypes,
    bool? enableUserData,
  }) async {
    final path = userId == null
        ? '/Items/$itemId'
        : '/Users/$userId/Items/$itemId';
    final response = await client.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        'Fields': _csv(fields),
        'EnableImageTypes': _csv(enableImageTypes),
        'EnableUserData': enableUserData,
      },
      options: jellyfinOptions(),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      return null;
    }
    return JellyfinBaseItem.fromJson(data);
  }

  Future<JellyfinBaseItem?> getUserItemData({
    required String itemId,
    required String userId,
  }) {
    return getItemById(itemId: itemId, userId: userId);
  }

  Future<List<JellyfinBaseItem>> getNextUp({
    required String userId,
    String? seriesId,
    List<String>? fields,
    List<String>? enableImageTypes,
    int? limit,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/Shows/NextUp',
      queryParameters: {
        'SeriesId': seriesId,
        'UserId': userId,
        'Fields': _csv(fields) ?? 'MediaSourceCount',
        'EnableImageTypes': _csv(enableImageTypes),
        'Limit': limit,
      },
      options: jellyfinOptions(),
    );
    return JellyfinBaseItemQueryResult.fromJson(response.data ?? {}).items;
  }

  Future<JellyfinBaseItemQueryResult> getSeriesSeasons({
    required String seriesId,
    required String userId,
    List<String>? fields,
    List<String>? enableImageTypes,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/Shows/$seriesId/Seasons',
      queryParameters: {
        'UserId': userId,
        'Fields': _csv(fields),
        'EnableImageTypes': _csv(enableImageTypes),
      },
      options: jellyfinOptions(),
    );
    return JellyfinBaseItemQueryResult.fromJson(response.data ?? {});
  }

  Future<JellyfinBaseItemQueryResult> getEpisodes({
    required String seriesId,
    required String userId,
    String? seasonId,
    List<String>? fields,
    List<String>? enableImageTypes,
    bool enableUserData = true,
    int? limit,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/Shows/$seriesId/Episodes',
      queryParameters: {
        'UserId': userId,
        'SeasonId': seasonId,
        'Fields': _csv(fields),
        'EnableImageTypes': _csv(enableImageTypes),
        'EnableUserData': enableUserData,
        'Limit': limit,
      },
      options: jellyfinOptions(),
    );
    return JellyfinBaseItemQueryResult.fromJson(response.data ?? {});
  }

  Future<JellyfinBaseItemQueryResult> getSimilarItems({
    required String itemId,
    required String userId,
    int limit = 12,
    List<String>? fields,
    List<String>? enableImageTypes,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/Items/$itemId/Similar',
      queryParameters: {
        'UserId': userId,
        'Limit': limit,
        'Fields': _csv(fields),
        'EnableImageTypes': _csv(enableImageTypes),
      },
      options: jellyfinOptions(),
    );
    return JellyfinBaseItemQueryResult.fromJson(response.data ?? {});
  }

  Future<void> updateFavoriteStatus({
    required String userId,
    required String itemId,
    required bool isFavorite,
  }) async {
    final path = '/Users/$userId/FavoriteItems/$itemId';
    if (isFavorite) {
      await client.post<Map<String, dynamic>>(
        path,
        options: jellyfinOptions(),
      );
      client.clearGetCache();
      return;
    }

    await client.delete<Map<String, dynamic>>(
      path,
      options: jellyfinOptions(),
    );

    client.clearGetCache();
  }

  Future<JellyfinBaseItemQueryResult> getResumeItems({
    required String userId,
    int startIndex = 0,
    int limit = 10,
    List<String>? fields,
    List<String>? enableImageTypes,
    List<String>? includeItemTypes,
    bool enableUserData = true,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/Users/$userId/Items/Resume',
      queryParameters: {
        'StartIndex': startIndex,
        'Limit': limit,
        'Fields': _csv(fields),
        'EnableImageTypes': _csv(enableImageTypes),
        'IncludeItemTypes': _csv(includeItemTypes),
        'EnableUserData': enableUserData,
      },
      options: jellyfinOptions(),
    );
    return JellyfinBaseItemQueryResult.fromJson(response.data ?? {});
  }
}
