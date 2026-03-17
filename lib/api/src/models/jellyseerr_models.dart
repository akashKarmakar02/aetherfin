String? _string(Object? value) => value?.toString();

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _number(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _jsonMapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

class JellyseerrTestResult {
  const JellyseerrTestResult({
    required this.isValid,
    required this.requiresPassword,
  });

  final bool isValid;
  final bool requiresPassword;
}

class JellyseerrUser {
  JellyseerrUser({
    this.id,
    this.email,
    this.displayName,
    this.username,
    this.settings = const {},
    this.raw = const {},
  });

  final int? id;
  final String? email;
  final String? displayName;
  final String? username;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> raw;

  factory JellyseerrUser.fromJson(Map<String, dynamic> json) {
    return JellyseerrUser(
      id: _integer(json['id']),
      email: _string(json['email']),
      displayName: _string(json['displayName']),
      username: _string(json['username']),
      settings: _jsonMap(json['settings']),
      raw: json,
    );
  }
}

class JellyseerrDiscoverSlider {
  JellyseerrDiscoverSlider({
    this.id,
    this.title,
    this.raw = const {},
  });

  final int? id;
  final String? title;
  final Map<String, dynamic> raw;

  factory JellyseerrDiscoverSlider.fromJson(Map<String, dynamic> json) {
    return JellyseerrDiscoverSlider(
      id: _integer(json['id']),
      title: _string(json['title']) ?? _string(json['name']),
      raw: json,
    );
  }
}

class JellyseerrGenreSliderItem {
  JellyseerrGenreSliderItem({
    this.id,
    this.name,
    this.slug,
    this.raw = const {},
  });

  final int? id;
  final String? name;
  final String? slug;
  final Map<String, dynamic> raw;

  factory JellyseerrGenreSliderItem.fromJson(Map<String, dynamic> json) {
    return JellyseerrGenreSliderItem(
      id: _integer(json['id']),
      name: _string(json['name']),
      slug: _string(json['slug']),
      raw: json,
    );
  }
}

class JellyseerrMediaResult {
  JellyseerrMediaResult({
    this.id,
    this.mediaType,
    this.title,
    this.name,
    this.posterPath,
    this.backdropPath,
    this.popularity,
    this.raw = const {},
  });

  final int? id;
  final String? mediaType;
  final String? title;
  final String? name;
  final String? posterPath;
  final String? backdropPath;
  final double? popularity;
  final Map<String, dynamic> raw;

  factory JellyseerrMediaResult.fromJson(Map<String, dynamic> json) {
    return JellyseerrMediaResult(
      id: _integer(json['id']),
      mediaType: _string(json['mediaType']),
      title: _string(json['title']),
      name: _string(json['name']),
      posterPath: _string(json['posterPath']),
      backdropPath: _string(json['backdropPath']),
      popularity: _number(json['popularity']),
      raw: json,
    );
  }
}

class JellyseerrSearchResults {
  JellyseerrSearchResults({
    this.page = 1,
    this.totalPages = 1,
    this.totalResults = 0,
    this.results = const [],
    this.raw = const {},
  });

  final int page;
  final int totalPages;
  final int totalResults;
  final List<JellyseerrMediaResult> results;
  final Map<String, dynamic> raw;

  factory JellyseerrSearchResults.fromJson(Map<String, dynamic> json) {
    return JellyseerrSearchResults(
      page: _integer(json['page']) ?? 1,
      totalPages: _integer(json['totalPages']) ?? 1,
      totalResults: _integer(json['totalResults']) ?? 0,
      results: _jsonMapList(json['results'])
          .map(JellyseerrMediaResult.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }
}

class JellyseerrMediaRequestBody {
  JellyseerrMediaRequestBody({
    required this.mediaType,
    required this.mediaId,
    this.seasons = const [],
    this.serverId,
    this.profileId,
    this.rootFolder,
    this.languageProfileId,
    this.userId,
    this.extra = const {},
  });

  final String mediaType;
  final int mediaId;
  final List<int> seasons;
  final int? serverId;
  final int? profileId;
  final String? rootFolder;
  final int? languageProfileId;
  final int? userId;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => {
        'mediaType': mediaType,
        'mediaId': mediaId,
        if (seasons.isNotEmpty) 'seasons': seasons,
        if (serverId != null) 'serverId': serverId,
        if (profileId != null) 'profileId': profileId,
        if (rootFolder != null) 'rootFolder': rootFolder,
        if (languageProfileId != null) 'languageProfileId': languageProfileId,
        if (userId != null) 'userId': userId,
        ...extra,
      };
}

class JellyseerrMediaRequest {
  JellyseerrMediaRequest({
    this.id,
    this.status,
    this.mediaType,
    this.raw = const {},
  });

  final int? id;
  final int? status;
  final String? mediaType;
  final Map<String, dynamic> raw;

  factory JellyseerrMediaRequest.fromJson(Map<String, dynamic> json) {
    return JellyseerrMediaRequest(
      id: _integer(json['id']),
      status: _integer(json['status']),
      mediaType: _string(json['mediaType']),
      raw: json,
    );
  }
}

class JellyseerrRequestResults {
  JellyseerrRequestResults({
    this.page = 1,
    this.totalPages = 1,
    this.totalResults = 0,
    this.results = const [],
    this.raw = const {},
  });

  final int page;
  final int totalPages;
  final int totalResults;
  final List<JellyseerrMediaRequest> results;
  final Map<String, dynamic> raw;

  factory JellyseerrRequestResults.fromJson(Map<String, dynamic> json) {
    return JellyseerrRequestResults(
      page: _integer(json['page']) ?? 1,
      totalPages: _integer(json['totalPages']) ?? 1,
      totalResults: _integer(json['totalResults']) ?? 0,
      results: _jsonMapList(json['results'])
          .map(JellyseerrMediaRequest.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }
}

class JellyseerrMovieDetails {
  JellyseerrMovieDetails({
    this.id,
    this.title,
    this.overview,
    this.mediaInfo = const {},
    this.raw = const {},
  });

  final int? id;
  final String? title;
  final String? overview;
  final Map<String, dynamic> mediaInfo;
  final Map<String, dynamic> raw;

  factory JellyseerrMovieDetails.fromJson(Map<String, dynamic> json) {
    return JellyseerrMovieDetails(
      id: _integer(json['id']),
      title: _string(json['title']),
      overview: _string(json['overview']),
      mediaInfo: _jsonMap(json['mediaInfo']),
      raw: json,
    );
  }
}

class JellyseerrTvDetails {
  JellyseerrTvDetails({
    this.id,
    this.name,
    this.overview,
    this.mediaInfo = const {},
    this.raw = const {},
  });

  final int? id;
  final String? name;
  final String? overview;
  final Map<String, dynamic> mediaInfo;
  final Map<String, dynamic> raw;

  factory JellyseerrTvDetails.fromJson(Map<String, dynamic> json) {
    return JellyseerrTvDetails(
      id: _integer(json['id']),
      name: _string(json['name']),
      overview: _string(json['overview']),
      mediaInfo: _jsonMap(json['mediaInfo']),
      raw: json,
    );
  }
}

class JellyseerrSeasonDetails {
  JellyseerrSeasonDetails({
    this.id,
    this.name,
    this.episodes = const [],
    this.raw = const {},
  });

  final int? id;
  final String? name;
  final List<Map<String, dynamic>> episodes;
  final Map<String, dynamic> raw;

  factory JellyseerrSeasonDetails.fromJson(Map<String, dynamic> json) {
    return JellyseerrSeasonDetails(
      id: _integer(json['id']),
      name: _string(json['name']),
      episodes: _jsonMapList(json['episodes']),
      raw: json,
    );
  }
}

class JellyseerrPersonDetails {
  JellyseerrPersonDetails({
    this.id,
    this.name,
    this.biography,
    this.raw = const {},
  });

  final int? id;
  final String? name;
  final String? biography;
  final Map<String, dynamic> raw;

  factory JellyseerrPersonDetails.fromJson(Map<String, dynamic> json) {
    return JellyseerrPersonDetails(
      id: _integer(json['id']),
      name: _string(json['name']),
      biography: _string(json['biography']),
      raw: json,
    );
  }
}

class JellyseerrCombinedCredit {
  JellyseerrCombinedCredit({
    this.cast = const [],
    this.crew = const [],
    this.raw = const {},
  });

  final List<Map<String, dynamic>> cast;
  final List<Map<String, dynamic>> crew;
  final Map<String, dynamic> raw;

  factory JellyseerrCombinedCredit.fromJson(Map<String, dynamic> json) {
    return JellyseerrCombinedCredit(
      cast: _jsonMapList(json['cast']),
      crew: _jsonMapList(json['crew']),
      raw: json,
    );
  }
}

class JellyseerrRating {
  JellyseerrRating({
    this.criticsScore,
    this.audienceScore,
    this.raw = const {},
  });

  final int? criticsScore;
  final int? audienceScore;
  final Map<String, dynamic> raw;

  factory JellyseerrRating.fromJson(Map<String, dynamic> json) {
    return JellyseerrRating(
      criticsScore: _integer(json['criticsScore']),
      audienceScore: _integer(json['audienceScore']),
      raw: json,
    );
  }
}

class JellyseerrIssue {
  JellyseerrIssue({
    this.id,
    this.status,
    this.message,
    this.raw = const {},
  });

  final int? id;
  final int? status;
  final String? message;
  final Map<String, dynamic> raw;

  factory JellyseerrIssue.fromJson(Map<String, dynamic> json) {
    return JellyseerrIssue(
      id: _integer(json['id']),
      status: _integer(json['status']),
      message: _string(json['message']),
      raw: json,
    );
  }
}

class JellyseerrServiceServer {
  JellyseerrServiceServer({
    this.id,
    this.name,
    this.isDefault,
    this.raw = const {},
  });

  final int? id;
  final String? name;
  final bool? isDefault;
  final Map<String, dynamic> raw;

  factory JellyseerrServiceServer.fromJson(Map<String, dynamic> json) {
    return JellyseerrServiceServer(
      id: _integer(json['id']),
      name: _string(json['name']),
      isDefault: json['isDefault'] as bool?,
      raw: json,
    );
  }
}

class JellyseerrServiceServerDetails extends JellyseerrServiceServer {
  JellyseerrServiceServerDetails({
    super.id,
    super.name,
    super.isDefault,
    super.raw,
  });

  factory JellyseerrServiceServerDetails.fromJson(Map<String, dynamic> json) {
    final base = JellyseerrServiceServer.fromJson(json);
    return JellyseerrServiceServerDetails(
      id: base.id,
      name: base.name,
      isDefault: base.isDefault,
      raw: base.raw,
    );
  }
}

class JellyseerrUserResults {
  JellyseerrUserResults({
    this.page = 1,
    this.totalPages = 1,
    this.totalResults = 0,
    this.results = const [],
    this.raw = const {},
  });

  final int page;
  final int totalPages;
  final int totalResults;
  final List<JellyseerrUser> results;
  final Map<String, dynamic> raw;

  factory JellyseerrUserResults.fromJson(Map<String, dynamic> json) {
    return JellyseerrUserResults(
      page: _integer(json['page']) ?? 1,
      totalPages: _integer(json['totalPages']) ?? 1,
      totalResults: _integer(json['totalResults']) ?? 0,
      results: _jsonMapList(json['results'])
          .map(JellyseerrUser.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }
}
