import '../../../api/api.dart';

class SeriesDetailsSeasonData {
  const SeriesDetailsSeasonData({
    required this.item,
    required this.title,
    required this.episodeCount,
  });

  final JellyfinBaseItem item;
  final String title;
  final int episodeCount;

  int? get indexNumber => item.indexNumber;
  String? get id => item.id;
}

class SeriesDetailsMediaEntry {
  const SeriesDetailsMediaEntry({
    required this.item,
    this.imageUrl,
    this.posterUrl,
    this.title,
    this.subtitle,
    this.description,
    this.eyebrow,
  });

  final JellyfinBaseItem item;
  final String? imageUrl;
  final String? posterUrl;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? eyebrow;
}

class SeriesDetailsEpisodeEntry extends SeriesDetailsMediaEntry {
  const SeriesDetailsEpisodeEntry({
    required super.item,
    super.imageUrl,
    super.posterUrl,
    super.title,
    super.subtitle,
    super.description,
    super.eyebrow,
    this.runtimeLabel,
    this.isHighlighted = false,
  });

  final String? runtimeLabel;
  final bool isHighlighted;
}

class SeriesDetailsPersonEntry {
  const SeriesDetailsPersonEntry({
    required this.person,
    this.imageUrl,
  });

  final JellyfinPerson person;
  final String? imageUrl;
}

class SeriesDetailsViewData {
  const SeriesDetailsViewData({
    required this.series,
    required this.selectedSeasonIndex,
    required this.seriesPosterUrl,
    required this.seriesBackdropUrl,
    required this.seriesLogoUrl,
    this.highlightedEpisodeId,
    this.starringText,
    this.selectedSeason,
    this.seasons = const [],
    this.episodes = const [],
    this.nextUpEntries = const [],
    this.extraEntries = const [],
    this.relatedEntries = const [],
    this.castEntries = const [],
  });

  final JellyfinBaseItem series;
  final int selectedSeasonIndex;
  final String? highlightedEpisodeId;
  final String? starringText;
  final String? seriesPosterUrl;
  final String? seriesBackdropUrl;
  final String? seriesLogoUrl;
  final SeriesDetailsSeasonData? selectedSeason;
  final List<SeriesDetailsSeasonData> seasons;
  final List<SeriesDetailsEpisodeEntry> episodes;
  final List<SeriesDetailsMediaEntry> nextUpEntries;
  final List<SeriesDetailsMediaEntry> extraEntries;
  final List<SeriesDetailsMediaEntry> relatedEntries;
  final List<SeriesDetailsPersonEntry> castEntries;

  bool get hasNextUp => nextUpEntries.isNotEmpty;
  bool get hasExtras => extraEntries.isNotEmpty;
  bool get hasRelated => relatedEntries.isNotEmpty;
  bool get hasCast => castEntries.isNotEmpty;
  bool get hasTrailerAction => series.remoteTrailers.isNotEmpty || hasExtras;
}
