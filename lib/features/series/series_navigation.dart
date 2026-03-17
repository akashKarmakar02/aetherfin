import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../app/router/app_routes.dart';

class SeriesNavigationTarget {
  const SeriesNavigationTarget({
    required this.seriesId,
    this.queryParameters = const {},
  });

  final String seriesId;
  final Map<String, String> queryParameters;
}

SeriesNavigationTarget? seriesNavigationTargetForItem(JellyfinBaseItem item) {
  if (item.isSeries && (item.id ?? '').isNotEmpty) {
    return SeriesNavigationTarget(seriesId: item.id!);
  }

  if (item.isEpisode) {
    final seriesId = item.seriesId ?? item.parentId;
    if ((seriesId ?? '').isEmpty) {
      return null;
    }
    return SeriesNavigationTarget(
      seriesId: seriesId!,
      queryParameters: {
        if (item.parentIndexNumber != null)
          'seasonIndex': '${item.parentIndexNumber}',
        if ((item.id ?? '').isNotEmpty) 'episodeId': item.id!,
      },
    );
  }

  return null;
}

Future<void> pushSeriesDetailsForItem(
  BuildContext context,
  JellyfinBaseItem item,
) async {
  final target = seriesNavigationTargetForItem(item);
  if (target == null) {
    return;
  }
  context.goNamed(
    AppRoutes.seriesName,
    pathParameters: {'id': target.seriesId},
    queryParameters: target.queryParameters,
  );
}
