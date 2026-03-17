import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../app/router/app_routes.dart';

Future<void> pushPlayerForItem(
  BuildContext context,
  JellyfinBaseItem item,
) async {
  final itemId = item.id;
  if (itemId == null || itemId.isEmpty) {
    return;
  }

  await context.pushNamed(
    AppRoutes.playerName,
    pathParameters: {'itemId': itemId},
  );
}
