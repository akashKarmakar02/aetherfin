import '../../../api/api.dart';

class LibraryOverviewEntry {
  const LibraryOverviewEntry({
    required this.item,
    required this.label,
    this.artworkUrl,
    this.subtitle,
  });

  final JellyfinBaseItem item;
  final String label;
  final String? artworkUrl;
  final String? subtitle;
}

class LibraryOverviewViewData {
  const LibraryOverviewViewData({
    this.entries = const [],
  });

  final List<LibraryOverviewEntry> entries;

  bool get hasContent => entries.isNotEmpty;
}

class LibraryCollectionEntry {
  const LibraryCollectionEntry({
    required this.item,
    this.artworkUrl,
    this.subtitle,
  });

  final JellyfinBaseItem item;
  final String? artworkUrl;
  final String? subtitle;
}

class LibraryCollectionPageViewData {
  const LibraryCollectionPageViewData({
    required this.library,
    this.entries = const [],
    this.totalCount,
    this.startIndex = 0,
  });

  final JellyfinBaseItem library;
  final List<LibraryCollectionEntry> entries;
  final int? totalCount;
  final int startIndex;
}
