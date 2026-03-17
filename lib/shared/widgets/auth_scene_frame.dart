import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../../app/platform/app_platform.dart';

class AuthSceneFrame extends StatelessWidget {
  const AuthSceneFrame({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    this.errorMessage,
    this.secondaryChildren = const [],
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final String? errorMessage;
  final List<Widget> secondaryChildren;

  @override
  Widget build(BuildContext context) {
    return switch (currentAppPlatform) {
      AppPlatform.linux => _LinuxAuthSceneFrame(
          eyebrow: eyebrow,
          title: title,
          description: description,
          errorMessage: errorMessage,
          secondaryChildren: secondaryChildren,
          child: child,
        ),
      AppPlatform.cupertino => _CupertinoAuthSceneFrame(
          eyebrow: eyebrow,
          title: title,
          description: description,
          errorMessage: errorMessage,
          secondaryChildren: secondaryChildren,
          child: child,
        ),
      AppPlatform.windows || AppPlatform.material => _MaterialAuthSceneFrame(
          eyebrow: eyebrow,
          title: title,
          description: description,
          errorMessage: errorMessage,
          secondaryChildren: secondaryChildren,
          child: child,
        ),
    };
  }
}

class _LinuxAuthSceneFrame extends StatelessWidget {
  const _LinuxAuthSceneFrame({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    required this.secondaryChildren,
    this.errorMessage,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final String? errorMessage;
  final List<Widget> secondaryChildren;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, viewport) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 36),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 760,
                minHeight: viewport.maxHeight - 64,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Text(
                        description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 18),
                      _LinuxErrorBanner(message: errorMessage!),
                    ],
                    const SizedBox(height: 28),
                    _LinuxSection(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaterialAuthSceneFrame extends StatelessWidget {
  const _MaterialAuthSceneFrame({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    required this.secondaryChildren,
    this.errorMessage,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final String? errorMessage;
  final List<Widget> secondaryChildren;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 20),
                  _MaterialErrorBanner(message: errorMessage!),
                ],
                const SizedBox(height: 28),
                child,
                for (final panel in secondaryChildren) ...[
                  const SizedBox(height: 16),
                  panel,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CupertinoAuthSceneFrame extends StatelessWidget {
  const _CupertinoAuthSceneFrame({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    required this.secondaryChildren,
    this.errorMessage,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final String? errorMessage;
  final List<Widget> secondaryChildren;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final secondaryColor = CupertinoColors.systemGrey.resolveFrom(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _CupertinoAppleTvBadge(),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.textStyle.copyWith(
                  color: secondaryColor,
                  fontSize: 17,
                  height: 1.4,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 18),
                _CupertinoErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: 24),
              child,
              const SizedBox(height: 34),
              const _CupertinoAuthFooter(),
              for (final panel in secondaryChildren) ...[
                const SizedBox(height: 14),
                panel,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CupertinoAppleTvBadge extends StatelessWidget {
  const _CupertinoAppleTvBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A2A2D),
            Color(0xFF0D0D10),
          ],
        ),
        border: Border.all(color: const Color(0xFF49494F)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
            children: const [
              TextSpan(text: 'tv'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CupertinoAuthFooter extends StatelessWidget {
  const _CupertinoAuthFooter();

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final secondaryColor = CupertinoColors.systemGrey.resolveFrom(context);

    return Column(
      children: [
        const Icon(
          CupertinoIcons.person_2_fill,
          color: CupertinoColors.activeBlue,
          size: 28,
        ),
        const SizedBox(height: 14),
        Text(
          'Your Jellyfin account information is used only to sign in securely and connect this app to your server.',
          textAlign: TextAlign.center,
          style: theme.textTheme.textStyle.copyWith(
            color: secondaryColor,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class SupportPanel extends StatelessWidget {
  const SupportPanel({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return switch (currentAppPlatform) {
      AppPlatform.linux => _LinuxSupportPanel(title: title, body: body),
      AppPlatform.cupertino => _CupertinoSupportPanel(title: title, body: body),
      AppPlatform.windows || AppPlatform.material => _MaterialSupportPanel(
          title: title,
          body: body,
        ),
    };
  }
}

class _LinuxSection extends StatelessWidget {
  const _LinuxSection({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return YaruBorderContainer(
      padding: padding,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
      child: child,
    );
  }
}

class _LinuxErrorBanner extends StatelessWidget {
  const _LinuxErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return YaruInfoBox(
      yaruInfoType: YaruInfoType.danger,
      title: const Text('Something went wrong'),
      subtitle: Text(message),
    );
  }
}

class _MaterialErrorBanner extends StatelessWidget {
  const _MaterialErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}

class _CupertinoErrorBanner extends StatelessWidget {
  const _CupertinoErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4D2428),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoColors.white,
            ),
      ),
    );
  }
}

class _LinuxSupportPanel extends StatelessWidget {
  const _LinuxSupportPanel({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _MaterialSupportPanel extends StatelessWidget {
  const _MaterialSupportPanel({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CupertinoSupportPanel extends StatelessWidget {
  const _CupertinoSupportPanel({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10141B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.systemGrey.resolveFrom(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
