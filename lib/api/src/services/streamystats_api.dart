import 'package:dio/dio.dart';

import '../models/streamystats_models.dart';
import '../transport/base_api_client.dart';

class StreamystatsApi {
  StreamystatsApi({
    required String baseUrl,
    required this.jellyfinToken,
    Dio? dio,
  }) : client = BaseApiClient(baseUrl: baseUrl, dio: dio);

  final BaseApiClient client;
  final String jellyfinToken;

  Options get _options => Options(
        headers: {
          'Authorization': 'MediaBrowser Token="$jellyfinToken"',
        },
      );

  Future<Object> search(
    StreamystatsSearchParams params, {
    CancelToken? cancelToken,
  }) {
    if ((params.format ?? 'full').toLowerCase() == 'ids') {
      return searchIds(
        params.query,
        type: params.type,
        limit: params.limit,
        cancelToken: cancelToken,
      );
    }
    return searchFull(
      params.query,
      type: params.type,
      limit: params.limit,
      cancelToken: cancelToken,
    );
  }

  Future<StreamystatsSearchIdsResponse> searchIds(
    String query, {
    String? type,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/search',
      queryParameters: {
        'q': query,
        'format': 'ids',
        'type': type,
        'limit': limit,
      },
      options: _options,
      cancelToken: cancelToken,
    );
    return StreamystatsSearchIdsResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsSearchFullResponse> searchFull(
    String query, {
    String? type,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/search',
      queryParameters: {
        'q': query,
        'format': 'full',
        'type': type,
        'limit': limit,
      },
      options: _options,
      cancelToken: cancelToken,
    );
    return StreamystatsSearchFullResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsRecommendationsFullResponse> getRecommendations(
    StreamystatsRecommendationsParams params,
  ) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/recommendations',
      queryParameters: {
        'serverId': params.serverId,
        'serverName': params.serverName,
        'jellyfinServerId': params.jellyfinServerId,
        'limit': params.limit,
        'type': params.type,
        'range': params.range,
        'format': params.format,
        'includeBasedOn': params.includeBasedOn,
        'includeReasons': params.includeReasons,
      },
      options: _options,
    );
    return StreamystatsRecommendationsFullResponse.fromJson(
      response.data ?? {},
    );
  }

  Future<Object> recommendations(StreamystatsRecommendationsParams params) {
    if ((params.format ?? 'full').toLowerCase() == 'ids') {
      return getRecommendationIds(
        jellyfinServerId: params.jellyfinServerId ?? '',
        type: params.type,
        limit: params.limit,
      );
    }
    return getRecommendations(params);
  }

  Future<StreamystatsRecommendationsIdsResponse> getRecommendationIds({
    required String jellyfinServerId,
    String? type,
    int? limit,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/recommendations',
      queryParameters: {
        'jellyfinServerId': jellyfinServerId,
        'format': 'ids',
        'type': type,
        'limit': limit,
        'includeBasedOn': false,
        'includeReasons': false,
      },
      options: _options,
    );
    return StreamystatsRecommendationsIdsResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsWatchlistsFullResponse> getPromotedWatchlists({
    int? serverId,
    String? serverName,
    String? serverUrl,
    String? jellyfinServerId,
    int? limit,
    String? format,
    bool? includePreview,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/watchlists/promoted',
      queryParameters: {
        'serverId': serverId,
        'serverName': serverName,
        'serverUrl': serverUrl,
        'jellyfinServerId': jellyfinServerId,
        'limit': limit,
        'format': format,
        'includePreview': includePreview,
      },
      options: _options,
    );
    return StreamystatsWatchlistsFullResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsWatchlistsFullResponse> promotedWatchlists({
    int? serverId,
    String? serverName,
    String? serverUrl,
    String? jellyfinServerId,
    int? limit,
    String? format,
    bool? includePreview,
  }) {
    return getPromotedWatchlists(
      serverId: serverId,
      serverName: serverName,
      serverUrl: serverUrl,
      jellyfinServerId: jellyfinServerId,
      limit: limit,
      format: format,
      includePreview: includePreview,
    );
  }

  Future<StreamystatsWatchlistDetailIdsResponse> getWatchlistItemIds({
    required int watchlistId,
    int? serverId,
    String? serverName,
    String? serverUrl,
    String? jellyfinServerId,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/watchlists/$watchlistId',
      queryParameters: {
        'format': 'ids',
        'serverId': serverId,
        'serverName': serverName,
        'serverUrl': serverUrl,
        'jellyfinServerId': jellyfinServerId,
      },
      options: _options,
    );
    return StreamystatsWatchlistDetailIdsResponse.fromJson(
      response.data ?? {},
    );
  }

  Future<StreamystatsWatchlistDetailIdsResponse> watchlistItemIds({
    required int watchlistId,
    int? serverId,
    String? serverName,
    String? serverUrl,
    String? jellyfinServerId,
  }) {
    return getWatchlistItemIds(
      watchlistId: watchlistId,
      serverId: serverId,
      serverName: serverName,
      serverUrl: serverUrl,
      jellyfinServerId: jellyfinServerId,
    );
  }

  Future<StreamystatsGetWatchlistsResponse> getWatchlists() async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/watchlists',
      options: _options,
    );
    return StreamystatsGetWatchlistsResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsGetWatchlistsResponse> watchlists() => getWatchlists();

  Future<StreamystatsCreateWatchlistResponse> createWatchlist(
    StreamystatsCreateWatchlistRequest request,
  ) async {
    final response = await client.post<Map<String, dynamic>>(
      '/api/watchlists',
      data: request.toJson(),
      options: _options,
    );
    return StreamystatsCreateWatchlistResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsWatchlistDetailFullResponse> getWatchlistDetail(
    int watchlistId, {
    String? type,
    String? sort,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/watchlists/$watchlistId',
      queryParameters: {
        'format': 'full',
        'type': type,
        'sort': sort,
      },
      options: _options,
    );
    return StreamystatsWatchlistDetailFullResponse.fromJson(
      response.data ?? {},
    );
  }

  Future<StreamystatsWatchlistDetailFullResponse> watchlistDetail(
    int watchlistId, {
    String? type,
    String? sort,
  }) {
    return getWatchlistDetail(watchlistId, type: type, sort: sort);
  }

  Future<StreamystatsUpdateWatchlistResponse> updateWatchlist(
    int watchlistId,
    StreamystatsUpdateWatchlistRequest request,
  ) async {
    final response = await client.patch<Map<String, dynamic>>(
      '/api/watchlists/$watchlistId',
      data: request.toJson(),
      options: _options,
    );
    return StreamystatsUpdateWatchlistResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsDeleteWatchlistResponse> deleteWatchlist(
    int watchlistId,
  ) async {
    final response = await client.delete<Map<String, dynamic>>(
      '/api/watchlists/$watchlistId',
      options: _options,
    );
    return StreamystatsDeleteWatchlistResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsWatchlistItemMutationResponse> addWatchlistItem(
    int watchlistId,
    String itemId,
  ) async {
    final response = await client.post<Map<String, dynamic>>(
      '/api/watchlists/$watchlistId/items',
      data: {'itemId': itemId},
      options: _options,
    );
    return StreamystatsWatchlistItemMutationResponse.fromJson(
      response.data ?? {},
    );
  }

  Future<StreamystatsWatchlistItemMutationResponse> addItemToWatchlist(
    int watchlistId,
    String itemId,
  ) {
    return addWatchlistItem(watchlistId, itemId);
  }

  Future<StreamystatsDeleteWatchlistResponse> removeWatchlistItem(
    int watchlistId,
    String itemId,
  ) async {
    final response = await client.delete<Map<String, dynamic>>(
      '/api/watchlists/$watchlistId/items/$itemId',
      options: _options,
    );
    return StreamystatsDeleteWatchlistResponse.fromJson(response.data ?? {});
  }

  Future<StreamystatsDeleteWatchlistResponse> removeItemFromWatchlist(
    int watchlistId,
    String itemId,
  ) {
    return removeWatchlistItem(watchlistId, itemId);
  }
}
