import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum MobileCupertinoDestination { home, search }

class MobileCupertinoMediaHeader extends StatelessWidget {
  const MobileCupertinoMediaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 4),
      child: Row(
        children: [
          Text(
            'tv',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                'DR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileCupertinoMediaNavBar extends StatelessWidget {
  const MobileCupertinoMediaNavBar({
    super.key,
    required this.selectedDestination,
    this.onHomePressed,
    this.onSearchPressed,
  });

  final MobileCupertinoDestination selectedDestination;
  final VoidCallback? onHomePressed;
  final VoidCallback? onSearchPressed;

  static const _items = [
    ('Apple TV', CupertinoIcons.tv, MobileCupertinoDestination.home),
    ('MLS', CupertinoIcons.sportscourt, null),
    ('Downloads', CupertinoIcons.arrow_down_to_line, null),
    ('Search', CupertinoIcons.search, MobileCupertinoDestination.search),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in _items)
              _MobileNavItem(
                title: item.$1,
                icon: item.$2,
                selected: item.$3 == selectedDestination,
                onTap: switch (item.$3) {
                  MobileCupertinoDestination.home => onHomePressed,
                  MobileCupertinoDestination.search => onSearchPressed,
                  null => null,
                },
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : Colors.white.withValues(alpha: onTap == null ? 0.28 : 0.52);

    final body = SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 28 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return body;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }
}
