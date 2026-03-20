import '../../../api/api.dart';

enum SearchBackend {
  jellyfin('Jellyfin'),
  marlin('Marlin'),
  streamystats('Streamystats');

  const SearchBackend(this.label);

  final String label;
}

enum SearchArtworkKind {
  poster,
  landscape,
  circle,
}

class SearchResultEntry {
  const SearchResultEntry({
    required this.item,
    required this.artworkKind,
    this.artworkUrl,
    this.subtitle,
  });

  final JellyfinBaseItem item;
  final SearchArtworkKind artworkKind;
  final String? artworkUrl;
  final String? subtitle;
}

class SearchSectionViewData {
  const SearchSectionViewData({
    required this.title,
    this.entries = const [],
  });

  final String title;
  final List<SearchResultEntry> entries;

  bool get hasContent => entries.isNotEmpty;
}

class SearchViewData {
  const SearchViewData({
    required this.query,
    required this.backend,
    this.sections = const [],
  });

  final String query;
  final SearchBackend backend;
  final List<SearchSectionViewData> sections;

  bool get hasResults => sections.any((section) => section.entries.isNotEmpty);
}
