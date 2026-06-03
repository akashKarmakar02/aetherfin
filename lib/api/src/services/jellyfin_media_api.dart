import 'package:dio/dio.dart';

import '../models/jellyfin_models.dart';
import 'jellyfin_api_base.dart';
import 'jellyfin_library_api.dart';

class JellyfinMediaApi extends JellyfinApiBase {
  JellyfinMediaApi({
    required super.baseUrl,
    required super.clientInfo,
    required super.accessToken,
    super.dio,
  });

  static const int _ticksPerSecond = 10000000;
  static const Set<String> _supportedMediaBarTypes = {
    'Movie',
    'Series',
    'Episode',
    'Program',
    'Video',
    'BoxSet',
  };

  Future<JellyfinPlaybackInfoResponse> getPlaybackInfo({
    required String itemId,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      '/Items/$itemId/PlaybackInfo',
      data: body,
      queryParameters: queryParameters,
      options: jellyfinOptions(),
    );
    return JellyfinPlaybackInfoResponse.fromJson(response.data ?? {});
  }

  Future<void> reportPlaybackStarted(JellyfinPlaybackReport report) async {
    await client.post<Map<String, dynamic>>(
      '/Sessions/Playing',
      data: report.toJson(),
      options: jellyfinOptions(),
    );
  }

  Future<void> reportPlaybackProgress(JellyfinPlaybackReport report) async {
    await client.post<Map<String, dynamic>>(
      '/Sessions/Playing/Progress',
      data: report.toJson(),
      options: jellyfinOptions(),
    );
  }

  Future<void> reportPlaybackStopped(JellyfinPlaybackReport report) async {
    await client.post<Map<String, dynamic>>(
      '/Sessions/Playing/Stopped',
      data: report.toJson(),
      options: jellyfinOptions(),
    );
    client.clearGetCache();
  }

  Future<JellyfinMediaSegments?> fetchMediaSegments(String itemId) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        '/MediaSegments/$itemId',
        queryParameters: {'includeSegmentTypes': 'Intro,Outro'},
        options: jellyfinOptions(),
      );

      final introSegments = <JellyfinMediaTimeSegment>[];
      final creditSegments = <JellyfinMediaTimeSegment>[];
      final items = (response.data?['Items'] as List<dynamic>? ?? const []);
      for (final item in items.whereType<Map>()) {
        final json = item.cast<String, dynamic>();
        final type = json['Type']?.toString();
        final segment = JellyfinMediaTimeSegment(
          startTime: (_toInt(json['StartTicks']) ?? 0) / _ticksPerSecond,
          endTime: (_toInt(json['EndTicks']) ?? 0) / _ticksPerSecond,
          text: type ?? 'Unknown',
        );
        if (type == 'Intro') {
          introSegments.add(segment);
        } else if (type == 'Outro') {
          creditSegments.add(segment);
        }
      }

      return JellyfinMediaSegments(
        introSegments: introSegments,
        creditSegments: creditSegments,
      );
    } catch (_) {
      return null;
    }
  }

  Future<JellyfinMediaSegments> fetchLegacySegments(String itemId) async {
    final introSegments = <JellyfinMediaTimeSegment>[];
    final creditSegments = <JellyfinMediaTimeSegment>[];

    try {
      final introResponse = await client.get<Map<String, dynamic>>(
        '/Episode/$itemId/IntroTimestamps',
        options: jellyfinOptions(),
      );
      final introJson = introResponse.data ?? const <String, dynamic>{};
      if (introJson['Valid'] == true) {
        introSegments.add(
          JellyfinMediaTimeSegment(
            startTime: _toDouble(introJson['IntroStart']) ?? 0,
            endTime: _toDouble(introJson['IntroEnd']) ?? 0,
            text: 'Intro',
          ),
        );
      }
    } catch (_) {}

    try {
      final creditsResponse = await client.get<Map<String, dynamic>>(
        '/Episode/$itemId/Timestamps',
        options: jellyfinOptions(),
      );
      final introduction = creditsResponse.data?['Introduction'];
      if (introSegments.isEmpty &&
          introduction is Map &&
          introduction['Valid'] == true) {
        introSegments.add(
          JellyfinMediaTimeSegment(
            startTime: _toDouble(introduction['Start']) ?? 0,
            endTime: _toDouble(introduction['End']) ?? 0,
            text: 'Intro',
          ),
        );
      }
      final credits = creditsResponse.data?['Credits'];
      if (credits is Map && credits['Valid'] == true) {
        creditSegments.add(
          JellyfinMediaTimeSegment(
            startTime: _toDouble(credits['Start']) ?? 0,
            endTime: _toDouble(credits['End']) ?? 0,
            text: 'Credits',
          ),
        );
      }
    } catch (_) {}

    return JellyfinMediaSegments(
      introSegments: introSegments,
      creditSegments: creditSegments,
    );
  }

  Future<JellyfinMediaSegments> fetchSegmentsWithFallback(String itemId) async {
    final current = await fetchMediaSegments(itemId);
    if (current == null ||
        current.introSegments.isEmpty ||
        current.creditSegments.isEmpty) {
      final legacy = await fetchLegacySegments(itemId);
      return JellyfinMediaSegments(
        introSegments: current?.introSegments.isNotEmpty == true
            ? current!.introSegments
            : legacy.introSegments,
        creditSegments: current?.creditSegments.isNotEmpty == true
            ? current!.creditSegments
            : legacy.creditSegments,
      );
    }
    return current;
  }

  Future<JellyfinMediaBarContent> fetchMediaBarContent({
    required String userId,
    int limit = 12,
  }) async {
    final libraryApi = JellyfinLibraryApi(
      baseUrl: client.baseUrl,
      clientInfo: clientInfo,
      accessToken: accessToken ?? '',
      dio: client.dio,
    );
    final safeLimit = limit < 1 ? 1 : limit;

    try {
      final listResponse = await client.get<String>(
        '/web/avatars/list.txt',
        queryParameters: {'userId': userId},
        options: jellyfinOptions(responseType: ResponseType.plain),
      );
      final text = listResponse.data ?? '';
      final ids = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .skip(1)
          .take(100)
          .toList(growable: false);

      if (ids.isNotEmpty) {
        final items = await libraryApi.getItems(
          JellyfinItemsQuery(
            userId: userId,
            ids: ids,
            fields: const [
              'Overview',
              'Genres',
              'RemoteTrailers',
              'DateCreated',
              'PrimaryImageAspectRatio',
            ],
            enableImageTypes: const ['Primary', 'Backdrop', 'Logo'],
          ),
        );
        final byId = <String, JellyfinBaseItem>{
          for (final item in items.items)
            if (item.id != null) item.id!: item,
        };
        final ordered = ids
            .map((id) => byId[id])
            .whereType<JellyfinBaseItem>()
            .where(_isSupportedMediaBarItem)
            .take(safeLimit)
            .toList(growable: false);

        return JellyfinMediaBarContent(
          source: JellyfinMediaBarSource.list,
          itemIds: ordered.map((item) => item.id!).toList(growable: false),
          items: ordered,
        );
      }
    } catch (_) {}

    try {
      final randomItems = await libraryApi.getItems(
        JellyfinItemsQuery(
          userId: userId,
          includeItemTypes: const ['Movie', 'Series'],
          recursive: true,
          hasOverview: true,
          sortBy: const ['Random'],
          isPlayed: false,
          enableUserData: true,
          limit: 500,
          fields: const [
            'Overview',
            'Genres',
            'RemoteTrailers',
            'DateCreated',
            'PrimaryImageAspectRatio',
          ],
          enableImageTypes: const ['Primary', 'Backdrop', 'Logo'],
        ),
      );
      final items = randomItems.items
          .where(_isSupportedMediaBarItem)
          .take(safeLimit)
          .toList(growable: false);
      return JellyfinMediaBarContent(
        source: JellyfinMediaBarSource.random,
        itemIds: items.map((item) => item.id!).toList(growable: false),
        items: items,
      );
    } catch (_) {
      return JellyfinMediaBarContent(source: JellyfinMediaBarSource.none);
    }
  }

  String? buildPrimaryImageUrl({
    required JellyfinBaseItem? item,
    int width = 400,
    int? height,
    int quality = 80,
  }) {
    return buildPrimaryImageUrlById(
      itemId: item?.id,
      imageTag:
          item?.imageTags?.primary ??
          item?.backdropImageTags.firstOrNull ??
          item?.parentBackdropImageTags.firstOrNull,
      width: width,
      height: height,
      quality: quality,
    );
  }

  String? buildPrimaryImageUrlById({
    required String? itemId,
    String? imageTag,
    int width = 400,
    int? height,
    int quality = 80,
  }) {
    if (itemId == null) return null;
    final params = <String, String>{
      'fillWidth': '$width',
      if (height != null) 'fillHeight': '$height',
      'quality': '$quality',
      ...?switch (imageTag) {
        final value? => <String, String>{'tag': value},
        null => null,
      },
    };
    return '${client.baseUrl}/Items/$itemId/Images/Primary?${Uri(queryParameters: params).query}';
  }

  String? buildThumbImageUrlById({
    required String? itemId,
    String? imageTag,
    int width = 640,
    int quality = 82,
  }) {
    if (itemId == null) return null;
    final params = <String, String>{
      'fillWidth': '$width',
      'quality': '$quality',
      ...?switch (imageTag) {
        final value? => <String, String>{'tag': value},
        null => null,
      },
    };
    return '${client.baseUrl}/Items/$itemId/Images/Thumb?${Uri(queryParameters: params).query}';
  }

  String? buildBackdropUrl({
    required String? itemId,
    String? imageTag,
    int width = 1280,
    int quality = 80,
  }) {
    if (itemId == null) return null;
    final params = <String, String>{
      'fillWidth': '$width',
      'quality': '$quality',
      ...?switch (imageTag) {
        final value? => <String, String>{'tag': value},
        null => null,
      },
    };
    return '${client.baseUrl}/Items/$itemId/Images/Backdrop?${Uri(queryParameters: params).query}';
  }

  String? buildParentBackdropImageUrl({
    required JellyfinBaseItem? item,
    int width = 1280,
    int quality = 80,
  }) {
    final tag = item?.parentBackdropImageTags.firstOrNull;
    if (item?.id == null || tag == null) return null;
    return buildBackdropUrl(
      itemId: item!.id,
      imageTag: tag,
      width: width,
      quality: quality,
    );
  }

  String? buildLogoImageUrlById({
    required String? itemId,
    String? imageTag,
    int width = 500,
    int quality = 90,
  }) {
    if (itemId == null) return null;
    final params = <String, String>{
      'maxWidth': '$width',
      'quality': '$quality',
      ...?switch (imageTag) {
        final value? => <String, String>{'tag': value},
        null => null,
      },
    };
    return '${client.baseUrl}/Items/$itemId/Images/Logo?${Uri(queryParameters: params).query}';
  }

  Future<JellyfinAudioStreamResult?> getAudioStreamUrl({
    required String userId,
    required String itemId,
    Map<String, dynamic>? deviceProfile,
  }) async {
    try {
      final playbackInfo = await getPlaybackInfo(
        itemId: itemId,
        body: {
          'userId': userId,
          'deviceProfile': deviceProfile,
          'startTimeTicks': 0,
          'isPlayback': true,
          'autoOpenLiveStream': true,
        },
      );
      final mediaSource = playbackInfo.mediaSources.isNotEmpty
          ? playbackInfo.mediaSources.first
          : null;
      if (mediaSource?.transcodingUrl != null) {
        return JellyfinAudioStreamResult(
          url: '${client.baseUrl}${mediaSource!.transcodingUrl}',
          sessionId: playbackInfo.playSessionId,
          mediaSource: mediaSource,
          isTranscoding: true,
        );
      }

      final params = Uri(
        queryParameters: {
          'static': 'true',
          'container': mediaSource?.container ?? 'mp3',
          'mediaSourceId': mediaSource?.id ?? '',
          'deviceId': clientInfo.deviceId,
          'api_key': accessToken ?? '',
          'userId': userId,
        },
      ).query;

      return JellyfinAudioStreamResult(
        url: '${client.baseUrl}/Audio/$itemId/stream?$params',
        sessionId: playbackInfo.playSessionId,
        mediaSource: mediaSource,
        isTranscoding: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<JellyfinPlaybackStreamResult?> getStreamUrl({
    required JellyfinBaseItem item,
    required String userId,
    required Map<String, dynamic> deviceProfile,
    int startTimeTicks = 0,
    int? maxStreamingBitrate,
    String? playSessionId,
    int audioStreamIndex = 0,
    int? subtitleStreamIndex,
    String? mediaSourceId,
    String? deviceId,
  }) async {
    if (item.id == null) return null;
    final playbackItemId = item.type == 'Program'
        ? item.channelId ?? item.id!
        : item.id!;

    final playbackInfo = await getPlaybackInfo(
      itemId: playbackItemId,
      body: {
        'UserId': userId,
        'DeviceProfile': deviceProfile,
        'SubtitleStreamIndex': subtitleStreamIndex,
        'StartTimeTicks': startTimeTicks,
        'IsPlayback': true,
        'AutoOpenLiveStream': true,
        'MaxStreamingBitrate': maxStreamingBitrate,
        'AudioStreamIndex': audioStreamIndex,
        'MediaSourceId': mediaSourceId,
      },
    );

    final mediaSource = playbackInfo.mediaSources.firstOrNull;
    final url = _buildPlaybackUrl(
      itemId: playbackItemId,
      mediaSource: mediaSource,
      subtitleStreamIndex: subtitleStreamIndex,
      audioStreamIndex: audioStreamIndex,
      deviceId: deviceId,
      startTimeTicks: startTimeTicks,
      maxStreamingBitrate: maxStreamingBitrate,
      userId: userId,
      playSessionId: playbackInfo.playSessionId ?? playSessionId,
    );
    return JellyfinPlaybackStreamResult(
      url: url,
      sessionId: playbackInfo.playSessionId,
      mediaSource: mediaSource,
    );
  }

  Future<JellyfinPlaybackStreamResult?> getDownloadStreamUrl({
    required JellyfinBaseItem item,
    required String userId,
    required Map<String, dynamic> deviceProfile,
    int? maxStreamingBitrate,
    int audioStreamIndex = 0,
    int? subtitleStreamIndex,
    String? mediaSourceId,
    String? deviceId,
  }) async {
    if (item.id == null) return null;
    final playbackInfo = await getPlaybackInfo(
      itemId: item.id!,
      body: {
        'UserId': userId,
        'DeviceProfile': deviceProfile,
        'SubtitleStreamIndex': subtitleStreamIndex,
        'StartTimeTicks': 0,
        'IsPlayback': true,
        'AutoOpenLiveStream': true,
        'MaxStreamingBitrate': maxStreamingBitrate,
        'AudioStreamIndex': audioStreamIndex,
        'MediaSourceId': mediaSourceId,
      },
    );

    final mediaSource = playbackInfo.mediaSources.firstOrNull;
    final url = _buildDownloadPlaybackUrl(
      itemId: item.id!,
      mediaSource: mediaSource,
      sessionId: playbackInfo.playSessionId,
      subtitleStreamIndex: subtitleStreamIndex,
      audioStreamIndex: audioStreamIndex,
      deviceId: deviceId,
      maxStreamingBitrate: maxStreamingBitrate,
      userId: userId,
    );
    return JellyfinPlaybackStreamResult(
      url: url,
      sessionId: playbackInfo.playSessionId,
      mediaSource: mediaSource,
    );
  }

  Future<JellyfinDownloadUrlResult?> getDownloadUrl({
    required JellyfinBaseItem item,
    required JellyfinMediaSourceInfo mediaSource,
    required String userId,
    required Map<String, dynamic> deviceProfile,
    required int? maxBitrate,
    int audioStreamIndex = 0,
    int? subtitleStreamIndex,
    String? deviceId,
  }) async {
    if (item.id == null) return null;
    final streamDetails = await getStreamUrl(
      item: item,
      userId: userId,
      deviceProfile: deviceProfile,
      startTimeTicks: 0,
      mediaSourceId: mediaSource.id,
      maxStreamingBitrate: maxBitrate,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      deviceId: deviceId,
    );

    if (maxBitrate == null &&
        streamDetails?.mediaSource?.transcodingUrl == null) {
      return JellyfinDownloadUrlResult(
        url:
            '${client.baseUrl}/Items/${item.id}/Download?api_key=${accessToken ?? ''}',
        mediaSource: streamDetails?.mediaSource,
      );
    }

    final downloadDetails = await getDownloadStreamUrl(
      item: item,
      userId: userId,
      deviceProfile: deviceProfile,
      mediaSourceId: mediaSource.id,
      deviceId: deviceId,
      maxStreamingBitrate: maxBitrate,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );

    return JellyfinDownloadUrlResult(
      url: downloadDetails?.url,
      mediaSource: downloadDetails?.mediaSource,
    );
  }

  bool _isSupportedMediaBarItem(JellyfinBaseItem item) {
    return item.id != null &&
        item.type != null &&
        _supportedMediaBarTypes.contains(item.type) &&
        item.hasAnyImage;
  }

  String _buildPlaybackUrl({
    required String itemId,
    required JellyfinMediaSourceInfo? mediaSource,
    int? subtitleStreamIndex,
    required int audioStreamIndex,
    String? deviceId,
    required int startTimeTicks,
    int? maxStreamingBitrate,
    required String userId,
    String? playSessionId,
  }) {
    var transcodingUrl = mediaSource?.transcodingUrl;
    if (transcodingUrl != null) {
      if (subtitleStreamIndex == -1) {
        transcodingUrl = transcodingUrl.replaceAll(
          'SubtitleMethod=Encode',
          'SubtitleMethod=Hls',
        );
      }
      return '${client.baseUrl}$transcodingUrl';
    }

    final params = <String, String>{
      'static': 'true',
      'container': 'mp4',
      'mediaSourceId': mediaSource?.id ?? '',
      'subtitleStreamIndex': subtitleStreamIndex?.toString() ?? '',
      'audioStreamIndex': '$audioStreamIndex',
      'deviceId': deviceId ?? clientInfo.deviceId,
      'api_key': accessToken ?? '',
      'startTimeTicks': '$startTimeTicks',
      'maxStreamingBitrate': maxStreamingBitrate?.toString() ?? '',
      'userId': userId,
      ...?switch (playSessionId) {
        final value? => <String, String>{'playSessionId': value},
        null => null,
      },
    };

    final query = Uri(queryParameters: params).query;

    return '${client.baseUrl}/Videos/$itemId/stream?$query';
  }

  String _buildDownloadPlaybackUrl({
    required String itemId,
    required JellyfinMediaSourceInfo? mediaSource,
    required String? sessionId,
    int? subtitleStreamIndex,
    required int audioStreamIndex,
    String? deviceId,
    int? maxStreamingBitrate,
    required String userId,
  }) {
    final modifiedMediaSource = mediaSource == null
        ? null
        : JellyfinMediaSourceInfo(
            id: mediaSource.id,
            eTag: mediaSource.eTag,
            container: mediaSource.container,
            transcodingUrl: mediaSource.transcodingUrl?.replaceAll(
              'master.m3u8',
              'stream',
            ),
            raw: mediaSource.raw,
          );

    final url = _buildPlaybackUrl(
      itemId: itemId,
      mediaSource: modifiedMediaSource,
      subtitleStreamIndex: subtitleStreamIndex,
      audioStreamIndex: audioStreamIndex,
      deviceId: deviceId,
      startTimeTicks: 0,
      maxStreamingBitrate: maxStreamingBitrate,
      userId: userId,
      playSessionId: sessionId,
    );

    if (mediaSource?.transcodingUrl != null) {
      return url;
    }

    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters)
      ..['subtitleMethod'] = 'Embed'
      ..['enableSubtitlesInManifest'] = 'true'
      ..['allowVideoStreamCopy'] = 'true'
      ..['allowAudioStreamCopy'] = 'true'
      ..['container'] = 'ts'
      ..['static'] = 'false';

    return uri.replace(queryParameters: params).toString();
  }

  String? buildSubtitleStreamUrl({
    required String itemId,
    required JellyfinMediaSourceInfo mediaSource,
    required JellyfinMediaStreamInfo subtitleStream,
    String format = 'ass',
  }) {
    final subtitleIndex = subtitleStream.index;
    final mediaSourceId = mediaSource.id;
    if (subtitleIndex == null ||
        mediaSourceId == null ||
        mediaSourceId.isEmpty) {
      return null;
    }

    final params = <String, String>{
      if (accessToken != null && accessToken!.isNotEmpty)
        'api_key': accessToken!,
    };
    final query = Uri(queryParameters: params).query;
    return buildUrl(
      '/Videos/$itemId/$mediaSourceId/Subtitles/$subtitleIndex/Stream.$format${query.isEmpty ? '' : '?$query'}',
    );
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
