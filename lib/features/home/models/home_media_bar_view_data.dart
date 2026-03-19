import '../../../api/api.dart';

class HomeMediaBarEntry {
  const HomeMediaBarEntry({
    required this.item,
    this.backdropUrl,
    this.primaryUrl,
    this.logoUrl,
    this.posterUrl,
  });

  final JellyfinBaseItem item;
  final String? backdropUrl;
  final String? primaryUrl;
  final String? logoUrl;
  final String? posterUrl;
}

class HomeMediaBarViewData {
  const HomeMediaBarViewData({
    required this.hasPlugin,
    required this.source,
    this.entries = const [],
    this.continueWatchingEntries = const [],
    this.nextUpEntries = const [],
    this.recentlyAddedEntries = const [],
  });

  final bool hasPlugin;
  final JellyfinMediaBarSource source;
  final List<HomeMediaBarEntry> entries;
  final List<HomeMediaBarEntry> continueWatchingEntries;
  final List<HomeMediaBarEntry> nextUpEntries;
  final List<HomeMediaBarEntry> recentlyAddedEntries;

  bool get hasContent =>
      entries.isNotEmpty ||
      continueWatchingEntries.isNotEmpty ||
      nextUpEntries.isNotEmpty ||
      recentlyAddedEntries.isNotEmpty;
}
