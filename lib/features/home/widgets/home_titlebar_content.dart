import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeTitlebarTabs extends StatelessWidget {
  const HomeTitlebarTabs({super.key});

  static const _tabs = [
    ('Watch Now', true),
    ('Movies', false),
    ('TV Shows', false),
    ('Kids', false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCupertino = Theme.of(context).platform == TargetPlatform.macOS;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tab in _tabs) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tab.$2
                  ? (isCupertino
                        ? CupertinoColors.white.withValues(alpha: 0.12)
                        : scheme.surfaceContainerHighest)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tab.$1,
              style: (isCupertino
                      ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
                      : theme.textTheme.labelLarge)
                  ?.copyWith(
                    fontSize: isCupertino ? 13 : null,
                    fontWeight: tab.$2 ? FontWeight.w700 : FontWeight.w500,
                    color: isCupertino && !tab.$2
                        ? CupertinoColors.systemGrey.resolveFrom(context)
                        : null,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class HomeTitlebarActions extends StatelessWidget {
  const HomeTitlebarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCupertino = Theme.of(context).platform == TargetPlatform.macOS;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCupertino ? CupertinoIcons.search : Icons.search_rounded,
          size: 18,
        ),
        const SizedBox(width: 10),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            isCupertino ? CupertinoIcons.person_fill : Icons.person_rounded,
            size: 13,
          ),
        ),
      ],
    );
  }
}
