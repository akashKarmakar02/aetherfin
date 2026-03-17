import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/platform/app_platform.dart';
import '../../../shared/widgets/auth_scene_frame.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthSceneFrame(
      eyebrow: 'Session',
      title: 'Restoring your session',
      description:
          'Checking the saved Jellyfin server and validating the stored access token before routing into the app.',
      secondaryChildren: const [
        SupportPanel(
          title: 'What happens here',
          body:
              'Aetherfin restores the last server URL, validates the token against Jellyfin, and decides whether to continue to home, login, or server setup.',
        ),
      ],
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
          const SizedBox(height: 18),
          Text(
            'Preparing the app',
            style: switch (currentAppPlatform) {
              AppPlatform.cupertino => CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle,
              _ => Theme.of(context).textTheme.titleLarge,
            },
          ),
          const SizedBox(height: 8),
          Text(
            'This usually completes in a moment unless the saved server is unreachable.',
            textAlign: TextAlign.center,
            style: switch (currentAppPlatform) {
              AppPlatform.cupertino => CupertinoTheme.of(context)
                  .textTheme
                  .textStyle
                  .copyWith(
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
              _ => Theme.of(context).textTheme.bodyMedium,
            },
          ),
        ],
      ),
    );
  }
}
