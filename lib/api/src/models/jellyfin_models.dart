String? _asString(Object? value) => value?.toString();

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
  return const [];
}

DateTime? _asDateTime(Object? value) {
  final raw = _asString(value);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

class JellyfinUser {
  JellyfinUser({
    this.id,
    this.name,
    this.serverId,
    this.policy,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? serverId;
  final Map<String, dynamic>? policy;
  final Map<String, dynamic> raw;

  factory JellyfinUser.fromJson(Map<String, dynamic> json) {
    return JellyfinUser(
      id: _asString(json['Id']),
      name: _asString(json['Name']),
      serverId: _asString(json['ServerId']),
      policy: json['Policy'] is Map
          ? (json['Policy'] as Map).cast<String, dynamic>()
          : null,
      raw: json,
    );
  }
}

class JellyfinSessionInfo {
  JellyfinSessionInfo({
    this.id,
    this.userId,
    this.deviceId,
    this.raw = const {},
  });

  final String? id;
  final String? userId;
  final String? deviceId;
  final Map<String, dynamic> raw;

  factory JellyfinSessionInfo.fromJson(Map<String, dynamic> json) {
    return JellyfinSessionInfo(
      id: _asString(json['Id']),
      userId: _asString(json['UserId']),
      deviceId: _asString(json['DeviceId']),
      raw: json,
    );
  }
}

class JellyfinAuthenticationResult {
  JellyfinAuthenticationResult({
    this.accessToken,
    this.user,
    this.sessionInfo,
    this.raw = const {},
  });

  final String? accessToken;
  final JellyfinUser? user;
  final JellyfinSessionInfo? sessionInfo;
  final Map<String, dynamic> raw;

  factory JellyfinAuthenticationResult.fromJson(Map<String, dynamic> json) {
    return JellyfinAuthenticationResult(
      accessToken: _asString(json['AccessToken']),
      user: json['User'] is Map
          ? JellyfinUser.fromJson((json['User'] as Map).cast<String, dynamic>())
          : null,
      sessionInfo: json['SessionInfo'] is Map
          ? JellyfinSessionInfo.fromJson(
              (json['SessionInfo'] as Map).cast<String, dynamic>(),
            )
          : null,
      raw: json,
    );
  }
}

class JellyfinQuickConnectResult {
  JellyfinQuickConnectResult({
    this.secret,
    this.code,
    this.authenticated,
    this.isAuthorized,
    this.expDate,
    this.raw = const {},
  });

  final String? secret;
  final String? code;
  final bool? authenticated;
  final bool? isAuthorized;
  final DateTime? expDate;
  final Map<String, dynamic> raw;

  factory JellyfinQuickConnectResult.fromJson(Map<String, dynamic> json) {
    return JellyfinQuickConnectResult(
      secret: _asString(json['Secret']),
      code: _asString(json['Code']),
      authenticated: _asBool(json['Authenticated']),
      isAuthorized: _asBool(json['IsAuthorized']),
      expDate: DateTime.tryParse(_asString(json['ExpirationDate']) ?? ''),
      raw: json,
    );
  }
}

class JellyfinPublicSystemInfo {
  JellyfinPublicSystemInfo({
    this.id,
    this.name,
    this.serverName,
    this.version,
    this.localAddress,
    this.productName,
    this.operatingSystem,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? serverName;
  final String? version;
  final String? localAddress;
  final String? productName;
  final String? operatingSystem;
  final Map<String, dynamic> raw;

  factory JellyfinPublicSystemInfo.fromJson(Map<String, dynamic> json) {
    return JellyfinPublicSystemInfo(
      id: _asString(json['Id']),
      name: _asString(json['Name']),
      serverName: _asString(json['ServerName']),
      version: _asString(json['Version']),
      localAddress: _asString(json['LocalAddress']),
      productName: _asString(json['ProductName']),
      operatingSystem: _asString(json['OperatingSystem']),
      raw: json,
    );
  }
}

class JellyfinServerCandidate {
  JellyfinServerCandidate({
    required this.address,
    this.systemInfo,
  });

  final String address;
  final JellyfinPublicSystemInfo? systemInfo;
}

class JellyfinImageTags {
  JellyfinImageTags({
    this.primary,
    this.backdrop,
    this.thumb,
    this.logo,
    this.raw = const {},
  });

  final String? primary;
  final String? backdrop;
  final String? thumb;
  final String? logo;
  final Map<String, dynamic> raw;

  factory JellyfinImageTags.fromJson(Map<String, dynamic> json) {
    return JellyfinImageTags(
      primary: _asString(json['Primary']),
      backdrop: _asString(json['Backdrop']),
      thumb: _asString(json['Thumb']),
      logo: _asString(json['Logo']),
      raw: json,
    );
  }
}

class JellyfinRemoteTrailer {
  JellyfinRemoteTrailer({
    this.name,
    this.url,
    this.thumbnailUrl,
    this.raw = const {},
  });

  final String? name;
  final String? url;
  final String? thumbnailUrl;
  final Map<String, dynamic> raw;

  factory JellyfinRemoteTrailer.fromJson(Map<String, dynamic> json) {
    return JellyfinRemoteTrailer(
      name: _asString(json['Name']),
      url: _asString(json['Url']),
      thumbnailUrl: _asString(json['ThumbnailUrl']),
      raw: json,
    );
  }
}

class JellyfinPerson {
  JellyfinPerson({
    this.id,
    this.name,
    this.role,
    this.type,
    this.primaryImageTag,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? role;
  final String? type;
  final String? primaryImageTag;
  final Map<String, dynamic> raw;

  factory JellyfinPerson.fromJson(Map<String, dynamic> json) {
    return JellyfinPerson(
      id: _asString(json['Id']),
      name: _asString(json['Name']),
      role: _asString(json['Role']),
      type: _asString(json['Type']),
      primaryImageTag: _asString(json['PrimaryImageTag']),
      raw: json,
    );
  }
}

class JellyfinUserData {
  JellyfinUserData({
    this.isFavorite,
    this.played,
    this.playedPercentage,
    this.playbackPositionTicks,
    this.unplayedItemCount,
    this.raw = const {},
  });

  final bool? isFavorite;
  final bool? played;
  final double? playedPercentage;
  final int? playbackPositionTicks;
  final int? unplayedItemCount;
  final Map<String, dynamic> raw;

  factory JellyfinUserData.fromJson(Map<String, dynamic> json) {
    return JellyfinUserData(
      isFavorite: _asBool(json['IsFavorite']),
      played: _asBool(json['Played']),
      playedPercentage: _asDouble(json['PlayedPercentage']),
      playbackPositionTicks: _asInt(json['PlaybackPositionTicks']),
      unplayedItemCount: _asInt(json['UnplayedItemCount']),
      raw: json,
    );
  }
}

class JellyfinBaseItem {
  JellyfinBaseItem({
    this.id,
    this.type,
    this.collectionType,
    this.name,
    this.channelId,
    this.parentId,
    this.seriesId,
    this.seriesName,
    this.seasonId,
    this.overview,
    this.imageTags,
    this.backdropImageTags = const [],
    this.parentBackdropImageTags = const [],
    this.parentBackdropItemId,
    this.parentThumbImageTag,
    this.parentLogoImageTag,
    this.primaryImageAspectRatio,
    this.genres = const [],
    this.communityRating,
    this.productionYear,
    this.officialRating,
    this.indexNumber,
    this.parentIndexNumber,
    this.runTimeTicks,
    this.startDate,
    this.endDate,
    this.mediaSourceCount,
    this.childCount,
    this.people = const [],
    this.remoteTrailers = const [],
    this.userData,
    this.raw = const {},
  });

  final String? id;
  final String? type;
  final String? collectionType;
  final String? name;
  final String? channelId;
  final String? parentId;
  final String? seriesId;
  final String? seriesName;
  final String? seasonId;
  final String? overview;
  final JellyfinImageTags? imageTags;
  final List<String> backdropImageTags;
  final List<String> parentBackdropImageTags;
  final String? parentBackdropItemId;
  final String? parentThumbImageTag;
  final String? parentLogoImageTag;
  final double? primaryImageAspectRatio;
  final List<String> genres;
  final double? communityRating;
  final int? productionYear;
  final String? officialRating;
  final int? indexNumber;
  final int? parentIndexNumber;
  final int? runTimeTicks;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? mediaSourceCount;
  final int? childCount;
  final List<JellyfinPerson> people;
  final List<JellyfinRemoteTrailer> remoteTrailers;
  final JellyfinUserData? userData;
  final Map<String, dynamic> raw;

  bool get isSeries => type == 'Series';
  bool get isEpisode => type == 'Episode';
  bool get isMovie => type == 'Movie';

  bool get hasAnyImage {
    return backdropImageTags.isNotEmpty ||
        parentBackdropImageTags.isNotEmpty ||
        imageTags?.backdrop != null ||
        imageTags?.primary != null ||
        imageTags?.thumb != null ||
        imageTags?.logo != null ||
        parentThumbImageTag != null ||
        parentLogoImageTag != null;
  }

  factory JellyfinBaseItem.fromJson(Map<String, dynamic> json) {
    return JellyfinBaseItem(
      id: _asString(json['Id']),
      type: _asString(json['Type']),
      collectionType: _asString(json['CollectionType']),
      name: _asString(json['Name']),
      channelId: _asString(json['ChannelId']),
      parentId: _asString(json['ParentId']),
      seriesId: _asString(json['SeriesId']),
      seriesName: _asString(json['SeriesName']),
      seasonId: _asString(json['SeasonId']),
      overview: _asString(json['Overview']),
      imageTags: json['ImageTags'] is Map
          ? JellyfinImageTags.fromJson(
              (json['ImageTags'] as Map).cast<String, dynamic>(),
            )
          : null,
      backdropImageTags: _asStringList(json['BackdropImageTags']),
      parentBackdropImageTags: _asStringList(json['ParentBackdropImageTags']),
      parentBackdropItemId: _asString(json['ParentBackdropItemId']),
      parentThumbImageTag: _asString(json['ParentThumbImageTag']),
      parentLogoImageTag: _asString(json['ParentLogoImageTag']),
      primaryImageAspectRatio: _asDouble(json['PrimaryImageAspectRatio']),
      genres: _asStringList(json['Genres']),
      communityRating: _asDouble(json['CommunityRating']),
      productionYear: _asInt(json['ProductionYear']),
      officialRating: _asString(json['OfficialRating']),
      indexNumber: _asInt(json['IndexNumber']),
      parentIndexNumber: _asInt(json['ParentIndexNumber']),
      runTimeTicks: _asInt(json['RunTimeTicks']),
      startDate: _asDateTime(json['StartDate']),
      endDate: _asDateTime(json['EndDate']),
      mediaSourceCount: _asInt(json['MediaSourceCount']),
      childCount: _asInt(json['ChildCount']),
      people: _asMapList(json['People'])
          .map(JellyfinPerson.fromJson)
          .toList(growable: false),
      remoteTrailers: _asMapList(json['RemoteTrailers'])
          .map(JellyfinRemoteTrailer.fromJson)
          .toList(growable: false),
      userData: json['UserData'] is Map
          ? JellyfinUserData.fromJson(
              (json['UserData'] as Map).cast<String, dynamic>(),
            )
          : null,
      raw: json,
    );
  }
}

class JellyfinBaseItemQueryResult {
  JellyfinBaseItemQueryResult({
    this.items = const [],
    this.totalRecordCount,
    this.startIndex,
    this.raw = const {},
  });

  final List<JellyfinBaseItem> items;
  final int? totalRecordCount;
  final int? startIndex;
  final Map<String, dynamic> raw;

  factory JellyfinBaseItemQueryResult.fromJson(Map<String, dynamic> json) {
    return JellyfinBaseItemQueryResult(
      items: _asMapList(json['Items'])
          .map(JellyfinBaseItem.fromJson)
          .toList(growable: false),
      totalRecordCount: _asInt(json['TotalRecordCount']),
      startIndex: _asInt(json['StartIndex']),
      raw: json,
    );
  }
}

class JellyfinMediaSourceInfo {
  JellyfinMediaSourceInfo({
    this.id,
    this.eTag,
    this.container,
    this.transcodingUrl,
    this.defaultAudioStreamIndex,
    this.defaultSubtitleStreamIndex,
    this.mediaStreams = const [],
    this.raw = const {},
  });

  final String? id;
  final String? eTag;
  final String? container;
  final String? transcodingUrl;
  final int? defaultAudioStreamIndex;
  final int? defaultSubtitleStreamIndex;
  final List<JellyfinMediaStreamInfo> mediaStreams;
  final Map<String, dynamic> raw;

  bool get isTranscoding =>
      transcodingUrl != null && transcodingUrl!.isNotEmpty;

  List<JellyfinMediaStreamInfo> get audioStreams => mediaStreams
      .where((stream) => stream.type == JellyfinMediaStreamType.audio)
      .toList(growable: false);

  List<JellyfinMediaStreamInfo> get subtitleStreams => mediaStreams
      .where((stream) => stream.type == JellyfinMediaStreamType.subtitle)
      .toList(growable: false);

  factory JellyfinMediaSourceInfo.fromJson(Map<String, dynamic> json) {
    return JellyfinMediaSourceInfo(
      id: _asString(json['Id']),
      eTag: _asString(json['ETag']),
      container: _asString(json['Container']),
      transcodingUrl: _asString(json['TranscodingUrl']),
      defaultAudioStreamIndex: _asInt(json['DefaultAudioStreamIndex']),
      defaultSubtitleStreamIndex: _asInt(json['DefaultSubtitleStreamIndex']),
      mediaStreams: _asMapList(json['MediaStreams'])
          .map(JellyfinMediaStreamInfo.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }
}

enum JellyfinMediaStreamType {
  audio,
  subtitle,
  video,
  unknown;

  static JellyfinMediaStreamType fromJson(Object? value) {
    return switch (_asString(value)?.toLowerCase()) {
      'audio' => JellyfinMediaStreamType.audio,
      'subtitle' => JellyfinMediaStreamType.subtitle,
      'video' => JellyfinMediaStreamType.video,
      _ => JellyfinMediaStreamType.unknown,
    };
  }
}

class JellyfinMediaStreamInfo {
  JellyfinMediaStreamInfo({
    this.index,
    this.codec,
    this.title,
    this.displayTitle,
    this.language,
    this.deliveryMethod,
    this.channelLayout,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
    this.type = JellyfinMediaStreamType.unknown,
    this.raw = const {},
  });

  final int? index;
  final String? codec;
  final String? title;
  final String? displayTitle;
  final String? language;
  final String? deliveryMethod;
  final String? channelLayout;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;
  final JellyfinMediaStreamType type;
  final Map<String, dynamic> raw;

  factory JellyfinMediaStreamInfo.fromJson(Map<String, dynamic> json) {
    return JellyfinMediaStreamInfo(
      index: _asInt(json['Index']),
      codec: _asString(json['Codec']),
      title: _asString(json['Title']),
      displayTitle: _asString(json['DisplayTitle']),
      language: _asString(json['Language']),
      deliveryMethod: _asString(json['DeliveryMethod']),
      channelLayout: _asString(json['ChannelLayout']),
      isDefault: _asBool(json['IsDefault']) ?? false,
      isForced: _asBool(json['IsForced']) ?? false,
      isExternal: _asBool(json['IsExternal']) ?? false,
      type: JellyfinMediaStreamType.fromJson(json['Type']),
      raw: json,
    );
  }
}

class JellyfinPlaybackInfoResponse {
  JellyfinPlaybackInfoResponse({
    this.playSessionId,
    this.mediaSources = const [],
    this.raw = const {},
  });

  final String? playSessionId;
  final List<JellyfinMediaSourceInfo> mediaSources;
  final Map<String, dynamic> raw;

  factory JellyfinPlaybackInfoResponse.fromJson(Map<String, dynamic> json) {
    return JellyfinPlaybackInfoResponse(
      playSessionId: _asString(json['PlaySessionId']),
      mediaSources: _asMapList(json['MediaSources'])
          .map(JellyfinMediaSourceInfo.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }
}

class JellyfinPluginInfo {
  JellyfinPluginInfo({
    this.id,
    this.name,
    this.configurationFileName,
    this.version,
    this.raw = const {},
  });

  final String? id;
  final String? name;
  final String? configurationFileName;
  final String? version;
  final Map<String, dynamic> raw;

  factory JellyfinPluginInfo.fromJson(Map<String, dynamic> json) {
    return JellyfinPluginInfo(
      id: _asString(json['Id']),
      name: _asString(json['Name']),
      configurationFileName: _asString(json['ConfigurationFileName']),
      version: _asString(json['Version']),
      raw: json,
    );
  }
}

class JellyfinMediaTimeSegment {
  JellyfinMediaTimeSegment({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  final double startTime;
  final double endTime;
  final String text;
}

class JellyfinMediaSegments {
  JellyfinMediaSegments({
    this.introSegments = const [],
    this.creditSegments = const [],
  });

  final List<JellyfinMediaTimeSegment> introSegments;
  final List<JellyfinMediaTimeSegment> creditSegments;
}

enum JellyfinMediaBarSource { list, random, none }

class JellyfinMediaBarContent {
  JellyfinMediaBarContent({
    required this.source,
    this.itemIds = const [],
    this.items = const [],
  });

  final JellyfinMediaBarSource source;
  final List<String> itemIds;
  final List<JellyfinBaseItem> items;
}

class JellyfinPlaybackStreamResult {
  JellyfinPlaybackStreamResult({
    required this.url,
    this.sessionId,
    this.mediaSource,
  });

  final String? url;
  final String? sessionId;
  final JellyfinMediaSourceInfo? mediaSource;
}

class JellyfinAudioStreamResult extends JellyfinPlaybackStreamResult {
  JellyfinAudioStreamResult({
    required super.url,
    super.sessionId,
    super.mediaSource,
    required this.isTranscoding,
  });

  final bool isTranscoding;
}

class JellyfinDownloadUrlResult {
  JellyfinDownloadUrlResult({
    required this.url,
    this.mediaSource,
  });

  final String? url;
  final JellyfinMediaSourceInfo? mediaSource;
}

class JellyfinPlaybackReport {
  JellyfinPlaybackReport({
    required this.itemId,
    required this.mediaSourceId,
    required this.playSessionId,
    required this.positionTicks,
    required this.playMethod,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.canSeek = true,
    this.isPaused = false,
    this.isMuted = false,
    this.playbackStartTimeTicks,
    this.sessionId,
  });

  final String itemId;
  final String? mediaSourceId;
  final String? playSessionId;
  final int positionTicks;
  final String playMethod;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final bool canSeek;
  final bool isPaused;
  final bool isMuted;
  final int? playbackStartTimeTicks;
  final String? sessionId;

  Map<String, dynamic> toJson() {
    return {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'PlaySessionId': playSessionId,
      'PositionTicks': positionTicks,
      'PlayMethod': playMethod,
      'AudioStreamIndex': audioStreamIndex,
      'SubtitleStreamIndex': subtitleStreamIndex,
      'CanSeek': canSeek,
      'IsPaused': isPaused,
      'IsMuted': isMuted,
      'PlaybackStartTimeTicks': playbackStartTimeTicks,
      'SessionId': sessionId,
    };
  }
}
