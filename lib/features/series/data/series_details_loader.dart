import '../../../api/api.dart';
import '../../../app/session/app_session_controller.dart';
import '../models/series_details_view_data.dart';

class SeriesDetailsRequest {
  const SeriesDetailsRequest({
    required this.seriesId,
    this.seasonIndex,
    this.highlightedEpisodeId,
  });

  final String seriesId;
  final int? seasonIndex;
  final String? highlightedEpisodeId;

  SeriesDetailsRequest copyWith({
    String? seriesId,
    Object? seasonIndex = _requestNoChange,
    Object? highlightedEpisodeId = _requestNoChange,
  }) {
    return SeriesDetailsRequest(
      seriesId: seriesId ?? this.seriesId,
      seasonIndex: identical(seasonIndex, _requestNoChange)
          ? this.seasonIndex
          : seasonIndex as int?,
      highlightedEpisodeId:
          identical(highlightedEpisodeId, _requestNoChange)
          ? this.highlightedEpisodeId
          : highlightedEpisodeId as String?,
    );
  }
}

const Object _requestNoChange = Object();

typedef SeriesDetailsLoader =
    Future<SeriesDetailsViewData> Function(
      AppSessionController session,
      SeriesDetailsRequest request,
    );

Future<SeriesDetailsViewData> loadSeriesDetails(
  AppSessionController session,
  SeriesDetailsRequest request,
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
    throw StateError('No authenticated Jellyfin session is available.');
  }

  final libraryApi = JellyfinLibraryApi(
    baseUrl: baseUrl,
    clientInfo: clientInfo,
    accessToken: accessToken,
  );
  final mediaApi = JellyfinMediaApi(
    baseUrl: baseUrl,
    clientInfo: clientInfo,
    accessToken: accessToken,
  );

  return loadSeriesDetailsWithApis(
    libraryApi: libraryApi,
    mediaApi: mediaApi,
    userId: userId,
    request: request,
  );
}

Future<SeriesDetailsViewData> loadSeriesDetailsWithApis({
  required JellyfinLibraryApi libraryApi,
  required JellyfinMediaApi mediaApi,
  required String userId,
  required SeriesDetailsRequest request,
}) async {
  final seriesFuture = libraryApi.getItemById(
    itemId: request.seriesId,
    userId: userId,
    fields: const [
      'Overview',
      'Genres',
      'People',
      'RemoteTrailers',
      'PrimaryImageAspectRatio',
      'MediaSourceCount',
      'DateCreated',
    ],
    enableImageTypes: const ['Primary', 'Backdrop', 'Thumb', 'Logo'],
    enableUserData: true,
  );
  final nextUpFuture = libraryApi.getNextUp(
    userId: userId,
    seriesId: request.seriesId,
    fields: const ['Overview', 'MediaSourceCount'],
    enableImageTypes: const ['Primary', 'Backdrop', 'Thumb', 'Logo'],
    limit: 10,
  );
  final seasonsFuture = libraryApi.getSeriesSeasons(
    seriesId: request.seriesId,
    userId: userId,
    fields: const ['Overview', 'ItemCounts', 'PrimaryImageAspectRatio'],
    enableImageTypes: const ['Primary', 'Backdrop', 'Thumb'],
  );
  final extrasFuture = libraryApi.getItems(
    JellyfinItemsQuery(
      userId: userId,
      parentId: request.seriesId,
      recursive: true,
      limit: 18,
      includeItemTypes: const ['Trailer', 'Video'],
      enableUserData: true,
      fields: const ['Overview', 'MediaSourceCount'],
      enableImageTypes: const ['Primary', 'Backdrop', 'Thumb'],
    ),
  );
  final relatedFuture = libraryApi.getSimilarItems(
    itemId: request.seriesId,
    userId: userId,
    limit: 12,
    fields: const ['Overview', 'PrimaryImageAspectRatio'],
    enableImageTypes: const ['Primary', 'Backdrop', 'Thumb'],
  );

  final series = await seriesFuture;
  if (series == null || !series.isSeries) {
    throw StateError('Series not found for id ${request.seriesId}.');
  }

  final nextUp = await nextUpFuture;
  final seasons = (await seasonsFuture).items;
  final extras = (await extrasFuture).items;
  final related = (await relatedFuture).items
      .where((item) => item.isSeries && item.id != series.id)
      .toList(growable: false);

  final selectedSeasonItem = _resolveSelectedSeason(
    seasons: seasons,
    requestedSeasonIndex: request.seasonIndex,
  );
  final selectedSeasonIndex =
      selectedSeasonItem?.indexNumber ?? request.seasonIndex ?? 1;

  final episodes = selectedSeasonItem?.id == null
      ? const <JellyfinBaseItem>[]
      : (await libraryApi.getEpisodes(
              seriesId: request.seriesId,
              userId: userId,
              seasonId: selectedSeasonItem!.id,
              fields: const ['Overview', 'MediaSourceCount'],
              enableImageTypes: const ['Primary', 'Backdrop', 'Thumb'],
              enableUserData: true,
            ))
          .items;

  final starring = series.people
      .where((person) => (person.name ?? '').isNotEmpty)
      .map((person) => person.name!)
      .take(3)
      .join(', ');

  return SeriesDetailsViewData(
    series: series,
    selectedSeasonIndex: selectedSeasonIndex,
    highlightedEpisodeId: request.highlightedEpisodeId,
    starringText: starring.isEmpty ? null : 'Starring $starring',
    seriesPosterUrl: mediaApi.buildPrimaryImageUrl(
      item: series,
      width: 520,
      quality: 86,
    ),
    seriesBackdropUrl: _buildBackdropUrl(mediaApi, series),
    seriesLogoUrl: mediaApi.buildLogoImageUrlById(
      itemId: series.id,
      imageTag: series.imageTags?.logo ?? series.parentLogoImageTag,
      width: 920,
    ),
    selectedSeason: selectedSeasonItem == null
        ? null
        : SeriesDetailsSeasonData(
            item: selectedSeasonItem,
            title: _seasonTitle(selectedSeasonItem),
            episodeCount: selectedSeasonItem.childCount ?? 0,
          ),
    seasons: seasons
        .map(
          (item) => SeriesDetailsSeasonData(
            item: item,
            title: _seasonTitle(item),
            episodeCount: item.childCount ?? 0,
          ),
        )
        .toList(growable: false),
    episodes: episodes
        .map(
          (item) => SeriesDetailsEpisodeEntry(
            item: item,
            imageUrl: _buildLandscapeImageUrl(mediaApi, item),
            posterUrl: mediaApi.buildPrimaryImageUrl(
              item: item,
              width: 360,
              quality: 84,
            ),
            title: item.name ?? 'Untitled',
            subtitle: _episodeCode(item),
            description: item.overview,
            eyebrow: item.indexNumber == null
                ? 'Episode'
                : 'Episode ${item.indexNumber}',
            runtimeLabel: _runtimeLabel(item.runTimeTicks),
            isHighlighted: item.id == request.highlightedEpisodeId,
          ),
        )
        .toList(growable: false),
    nextUpEntries: nextUp
        .map(
          (item) => SeriesDetailsMediaEntry(
            item: item,
            imageUrl: _buildLandscapeImageUrl(mediaApi, item),
            posterUrl: mediaApi.buildPrimaryImageUrl(
              item: item,
              width: 320,
              quality: 84,
            ),
            title: item.name ?? 'Untitled',
            subtitle: _episodeCode(item),
            description: item.overview,
            eyebrow: 'Next Up',
          ),
        )
        .toList(growable: false),
    extraEntries: extras
        .where((item) => item.id != null)
        .map(
          (item) => SeriesDetailsMediaEntry(
            item: item,
            imageUrl: _buildLandscapeImageUrl(mediaApi, item),
            posterUrl: mediaApi.buildPrimaryImageUrl(
              item: item,
              width: 320,
              quality: 84,
            ),
            title: item.name ?? 'Untitled',
            subtitle: _runtimeLabel(item.runTimeTicks),
            description: item.overview,
            eyebrow: item.type == 'Trailer' ? 'Trailer' : 'Extra',
          ),
        )
        .toList(growable: false),
    relatedEntries: related
        .map(
          (item) => SeriesDetailsMediaEntry(
            item: item,
            imageUrl: mediaApi.buildPrimaryImageUrl(
              item: item,
              width: 420,
              quality: 84,
            ),
            posterUrl: mediaApi.buildPrimaryImageUrl(
              item: item,
              width: 420,
              quality: 84,
            ),
            title: item.name ?? 'Untitled',
            subtitle: item.productionYear?.toString(),
            description: item.overview,
            eyebrow: 'Related',
          ),
        )
        .toList(growable: false),
    castEntries: _dedupePeople(series.people)
        .take(12)
        .map(
          (person) => SeriesDetailsPersonEntry(
            person: person,
            imageUrl: mediaApi.buildPrimaryImageUrlById(
              itemId: person.id,
              imageTag: person.primaryImageTag,
              width: 240,
              quality: 82,
            ),
          ),
        )
        .toList(growable: false),
  );
}

JellyfinBaseItem? _resolveSelectedSeason({
  required List<JellyfinBaseItem> seasons,
  required int? requestedSeasonIndex,
}) {
  if (seasons.isEmpty) {
    return null;
  }
  if (requestedSeasonIndex != null) {
    for (final season in seasons) {
      if (season.indexNumber == requestedSeasonIndex) {
        return season;
      }
    }
  }
  return seasons.first;
}

String _seasonTitle(JellyfinBaseItem item) {
  if ((item.name ?? '').isNotEmpty) {
    return item.name!;
  }
  final seasonNumber = item.indexNumber;
  if (seasonNumber != null) {
    return 'Season $seasonNumber';
  }
  return 'Season';
}

String? _episodeCode(JellyfinBaseItem item) {
  final seasonNumber = item.parentIndexNumber;
  final episodeNumber = item.indexNumber;
  if (seasonNumber == null && episodeNumber == null) {
    return null;
  }
  final seasonLabel = seasonNumber == null ? '' : 'S$seasonNumber';
  final episodeLabel = episodeNumber == null ? '' : 'E$episodeNumber';
  return '$seasonLabel$episodeLabel';
}

String? _runtimeLabel(int? ticks) {
  if (ticks == null || ticks <= 0) {
    return null;
  }
  final totalMinutes = (ticks / 10000000 / 60).round();
  if (totalMinutes <= 0) {
    return null;
  }
  return '$totalMinutes min';
}

Iterable<JellyfinPerson> _dedupePeople(List<JellyfinPerson> people) sync* {
  final byId = <String, JellyfinPerson>{};
  for (final person in people) {
    final id = person.id;
    if (id == null || id.isEmpty) {
      continue;
    }
    byId.putIfAbsent(id, () => person);
  }
  yield* byId.values;
}

String? _buildBackdropUrl(JellyfinMediaApi mediaApi, JellyfinBaseItem item) {
  final directBackdropTag =
      item.backdropImageTags.firstOrNull ?? item.imageTags?.backdrop;
  if (directBackdropTag != null) {
    final directBackdrop = mediaApi.buildBackdropUrl(
      itemId: item.id,
      imageTag: directBackdropTag,
      width: 1920,
      quality: 88,
    );
    if (directBackdrop != null) {
      return directBackdrop;
    }
  }

  if (item.parentBackdropItemId != null && item.parentThumbImageTag != null) {
    return mediaApi.buildThumbImageUrlById(
      itemId: item.parentBackdropItemId,
      imageTag: item.parentThumbImageTag,
      width: 1920,
      quality: 88,
    );
  }

  return mediaApi.buildPrimaryImageUrl(
    item: item,
    width: 1440,
    quality: 86,
  );
}

String? _buildLandscapeImageUrl(JellyfinMediaApi mediaApi, JellyfinBaseItem item) {
  final webPrimary = mediaApi.buildPrimaryImageUrlById(
    itemId: item.id,
    imageTag: item.imageTags?.primary,
    width: 500,
    height: 500,
    quality: 90,
  );
  if (webPrimary != null) {
    return webPrimary;
  }

  final episodeThumb = mediaApi.buildThumbImageUrlById(
    itemId: item.id,
    imageTag: item.imageTags?.thumb,
    width: 720,
    quality: 84,
  );
  if (episodeThumb != null) {
    return episodeThumb;
  }

  if (item.parentBackdropItemId != null && item.parentThumbImageTag != null) {
    return mediaApi.buildThumbImageUrlById(
      itemId: item.parentBackdropItemId,
      imageTag: item.parentThumbImageTag,
      width: 720,
      quality: 84,
    );
  }

  return mediaApi.buildPrimaryImageUrl(
    item: item,
    width: 720,
    quality: 84,
  );
}
