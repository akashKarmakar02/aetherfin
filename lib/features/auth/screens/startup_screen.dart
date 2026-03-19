import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/platform/app_platform.dart';
import '../../../shared/widgets/auth_scene_frame.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthSceneFrame(
      eyebrow: '',
      title: 'Starting up',
      description: 'Restoring your Jellyfin session.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (currentAppPlatform) {
            AppPlatform.cupertino => const CupertinoActivityIndicator(
                radius: 18,
              ),
            _ => const SizedBox(
                height: 42,
                width: 42,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
          },
          const SizedBox(height: 16),
          Text(
            'Checking server and sign-in state',
            style: switch (currentAppPlatform) {
              AppPlatform.cupertino => CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle,
              _ => Theme.of(context).textTheme.titleLarge,
            },
          ),
        ],
      ),
    );
  }
}
