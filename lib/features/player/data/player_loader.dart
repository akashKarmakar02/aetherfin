import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../api/api.dart';
import '../../../app/platform/app_platform.dart';
import '../../../app/session/app_session_controller.dart';
import '../models/player_view_data.dart';
import 'jellyfin_player_device_profile.dart';
import 'player_data_source.dart';

class PlayerLoader implements PlayerDataSource {
  PlayerLoader({
    required String baseUrl,
    required String accessToken,
    required JellyfinClientInfo clientInfo,
    required String userId,
    Dio? dio,
  }) : _userId = userId,
       _libraryApi = JellyfinLibraryApi(
         baseUrl: baseUrl,
         accessToken: accessToken,
         clientInfo: clientInfo,
         dio: dio,
       ),
       _mediaApi = JellyfinMediaApi(
         baseUrl: baseUrl,
         accessToken: accessToken,
         clientInfo: clientInfo,
         dio: dio,
       );

  factory PlayerLoader.fromSession(AppSessionController session) {
    final baseUrl = session.serverUrl;
    final accessToken = session.accessToken;
    final clientInfo = session.clientInfo;
    final userId = session.user?.id;
    if (baseUrl == null ||
        accessToken == null ||
        clientInfo == null ||
        userId == null) {
      throw StateError('Playback requires an authenticated Jellyfin session.');
    }
    return PlayerLoader(
      baseUrl: baseUrl,
      accessToken: accessToken,
      clientInfo: clientInfo,
      userId: userId,
    );
  }

  final JellyfinLibraryApi _libraryApi;
  final JellyfinMediaApi _mediaApi;
  final String _userId;

  @override
  Future<PlayerViewData> load(String itemId) async {
    final playableItem = await _resolvePlayableItem(itemId);
    final startPositionTicks =
        playableItem.userData?.playbackPositionTicks ?? 0;
    final segments = await _loadSegments(playableItem.id);

    return _loadStream(
      requestedItemId: itemId,
      item: playableItem,
      startPositionTicks: startPositionTicks,
      audioStreamIndex: null,
      subtitleStreamIndex: null,
      mediaSourceId: null,
      segments: segments,
    );
  }

  @override
  Future<PlayerViewData> reloadStream({
    required PlayerViewData current,
    required int startPositionTicks,
    required int audioStreamIndex,
    required int subtitleStreamIndex,
  }) {
    return _loadStream(
      requestedItemId: current.requestedItemId,
      item: current.item,
      startPositionTicks: startPositionTicks,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      mediaSourceId: current.mediaSource.id,
      segments: JellyfinMediaSegments(
        introSegments: current.introSegments,
        creditSegments: current.creditSegments,
      ),
    );
  }

  @override
  Future<void> reportPlaybackStarted(JellyfinPlaybackReport report) {
    return _mediaApi.reportPlaybackStarted(report);
  }

  @override
  Future<void> reportPlaybackProgress(JellyfinPlaybackReport report) {
    return _mediaApi.reportPlaybackProgress(report);
  }

  @override
  Future<void> reportPlaybackStopped(JellyfinPlaybackReport report) {
    return _mediaApi.reportPlaybackStopped(report);
  }

  Future<PlayerViewData> _loadStream({
    required String requestedItemId,
    required JellyfinBaseItem item,
    required int startPositionTicks,
    required int? audioStreamIndex,
    required int? subtitleStreamIndex,
    required String? mediaSourceId,
    required JellyfinMediaSegments segments,
  }) async {
    final requestedAudioStreamIndex = audioStreamIndex ?? 0;
    final requestedSubtitleStreamIndex = subtitleStreamIndex;

    final playbackInfo = await _mediaApi.getPlaybackInfo(
      itemId: item.id!,
      body: {
        'UserId': _userId,
        'DeviceProfile': jellyfinPlayerDeviceProfile,
        'StartTimeTicks': startPositionTicks,
        'IsPlayback': true,
        'AutoOpenLiveStream': true,
        'AudioStreamIndex': requestedAudioStreamIndex,
        'SubtitleStreamIndex': requestedSubtitleStreamIndex,
        'MediaSourceId': mediaSourceId,
      },
    );

    final mediaSource = playbackInfo.mediaSources.firstOrNull;
    if (mediaSource == null) {
      throw StateError('Jellyfin did not return any playable media sources.');
    }

    final resolvedAudioIndex =
        audioStreamIndex ?? _resolveInitialAudioStreamIndex(mediaSource);
    final resolvedSubtitleIndex =
        subtitleStreamIndex ?? _resolveInitialSubtitleStreamIndex(mediaSource);

    final stream = await _mediaApi.getStreamUrl(
      item: item,
      userId: _userId,
      deviceProfile: jellyfinPlayerDeviceProfile,
      startTimeTicks: startPositionTicks,
      mediaSourceId: mediaSourceId,
      audioStreamIndex: requestedAudioStreamIndex,
      subtitleStreamIndex: requestedSubtitleStreamIndex,
    );

    final streamUrl = stream?.url;
    if (streamUrl == null || streamUrl.isEmpty) {
      throw StateError('Jellyfin did not return a playback URL.');
    }

    final resolvedMediaSource = stream?.mediaSource ?? mediaSource;
    final externalSubtitleUrl = _resolveExternalSubtitleUrl(
      itemId: item.id!,
      mediaSource: resolvedMediaSource,
      subtitleStreamIndex: resolvedSubtitleIndex,
    );

    return PlayerViewData(
      requestedItemId: requestedItemId,
      item: item,
      streamUrl: streamUrl,
      externalSubtitleUrl: externalSubtitleUrl,
      mediaSource: resolvedMediaSource,
      playSessionId: stream?.sessionId ?? playbackInfo.playSessionId,
      startPositionTicks: startPositionTicks,
      selectedAudioStreamIndex: resolvedAudioIndex,
      selectedSubtitleStreamIndex: resolvedSubtitleIndex,
      introSegments: segments.introSegments,
      creditSegments: segments.creditSegments,
    );
  }

  Future<JellyfinMediaSegments> _loadSegments(String? itemId) async {
    if (itemId == null || itemId.isEmpty) {
      return JellyfinMediaSegments();
    }

    try {
      final segments = await _mediaApi.fetchSegmentsWithFallback(itemId);
      if (kDebugMode) {
        debugPrint(
          'Player segments for $itemId: '
          'intro=${_describeSegments(segments.introSegments)}, '
          'credits=${_describeSegments(segments.creditSegments)}',
        );
      }
      return segments;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Player segments for $itemId: unavailable');
      }
      return JellyfinMediaSegments();
    }
  }

  String _describeSegments(List<JellyfinMediaTimeSegment> segments) {
    if (segments.isEmpty) {
      return '0';
    }
    return segments
        .map(
          (segment) =>
              '${segment.startTime.toStringAsFixed(1)}-${segment.endTime.toStringAsFixed(1)}',
        )
        .join(',');
  }

  Future<JellyfinBaseItem> _resolvePlayableItem(String itemId) async {
    final requestedItem = await _libraryApi.getItemById(
      itemId: itemId,
      userId: _userId,
      enableUserData: true,
      fields: const [
        'Overview',
        'Genres',
        'MediaSources',
        'MediaStreams',
        'Chapters',
        'PrimaryImageAspectRatio',
      ],
      enableImageTypes: const ['Primary', 'Backdrop', 'Thumb', 'Logo'],
    );

    if (requestedItem == null) {
      throw StateError('The requested item could not be found.');
    }

    if (!requestedItem.isSeries) {
      return requestedItem;
    }

    final nextUp = await _libraryApi.getNextUp(
      userId: _userId,
      seriesId: requestedItem.id,
      limit: 1,
      fields: const [
        'Overview',
        'Genres',
        'MediaSources',
        'MediaStreams',
        'Chapters',
        'PrimaryImageAspectRatio',
      ],
      enableImageTypes: const ['Primary', 'Backdrop', 'Thumb', 'Logo'],
    );
    final nextUpItem = nextUp.firstOrNull;
    if (nextUpItem == null || nextUpItem.id == null) {
      throw StateError('This series has no playable episode to resume.');
    }

    return await _libraryApi.getItemById(
          itemId: nextUpItem.id!,
          userId: _userId,
          enableUserData: true,
          fields: const [
            'Overview',
            'Genres',
            'MediaSources',
            'MediaStreams',
            'Chapters',
            'PrimaryImageAspectRatio',
          ],
          enableImageTypes: const ['Primary', 'Backdrop', 'Thumb', 'Logo'],
        ) ??
        nextUpItem;
  }

  int _resolveInitialAudioStreamIndex(JellyfinMediaSourceInfo mediaSource) {
    return mediaSource.defaultAudioStreamIndex ??
        mediaSource.audioStreams
            .firstWhere(
              (stream) => stream.isDefault,
              orElse: () =>
                  mediaSource.audioStreams.firstOrNull ??
                  JellyfinMediaStreamInfo(),
            )
            .index ??
        0;
  }

  int _resolveInitialSubtitleStreamIndex(JellyfinMediaSourceInfo mediaSource) {
    return mediaSource.defaultSubtitleStreamIndex ??
        mediaSource.subtitleStreams
            .firstWhere(
              (stream) => stream.isDefault,
              orElse: () => JellyfinMediaStreamInfo(index: -1),
            )
            .index ??
        -1;
  }

  String? _resolveExternalSubtitleUrl({
    required String itemId,
    required JellyfinMediaSourceInfo mediaSource,
    required int subtitleStreamIndex,
  }) {
    if (currentAppPlatform != AppPlatform.linux || subtitleStreamIndex < 0) {
      return null;
    }

    final subtitleStream = mediaSource.subtitleStreams.firstWhere(
      (stream) => stream.index == subtitleStreamIndex,
      orElse: () => JellyfinMediaStreamInfo(index: subtitleStreamIndex),
    );
    final codec = subtitleStream.codec?.toLowerCase();
    if (codec != 'ass' && codec != 'ssa') {
      return null;
    }

    return _mediaApi.buildSubtitleStreamUrl(
      itemId: itemId,
      mediaSource: mediaSource,
      subtitleStream: subtitleStream,
      format: 'ass',
    );
  }
}
