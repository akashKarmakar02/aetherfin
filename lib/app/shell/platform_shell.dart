import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:yaru/yaru.dart';

class LinuxWindowShell extends StatefulWidget {
  const LinuxWindowShell({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.extendBodyBehindTitleBar = false,
    this.onBackPressed,
    this.isHomeSelected = false,
    this.isLibrarySelected = false,
    this.isSearchSelected = false,
    this.isLoading = false,
    this.showTitlebarOption = false,
    this.onHomePressed,
    this.onLibraryPressed,
    this.onSearchPressed,
    this.enableTray = true,
  });

  final Widget child;
  final bool showBackButton;
  final bool extendBodyBehindTitleBar;
  final VoidCallback? onBackPressed;
  final bool isHomeSelected;
  final bool isLibrarySelected;
  final bool isSearchSelected;
  final bool showTitlebarOption;
  final bool isLoading;
  final VoidCallback? onHomePressed;
  final VoidCallback? onLibraryPressed;
  final VoidCallback? onSearchPressed;
  final bool enableTray;

  @override
  State<LinuxWindowShell> createState() => _LinuxWindowShellState();
}

class _LinuxWindowShellState extends State<LinuxWindowShell> with TrayListener {
  @override
  void initState() {
    super.initState();
    if (widget.enableTray) {
      trayManager.addListener(this);
      _initTray();
    }
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/ic_launcher.png');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: 'Show Window'),
          MenuItem(key: 'hide', label: 'Hide Window'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (widget.enableTray) {
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final window = YaruWindow.of(context);
    switch (menuItem.key) {
      case 'show':
        window.show();
        break;
      case 'hide':
        window.hide();
        break;
      case 'quit':
        trayManager.destroy();
        window.close();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleBar = YaruWindowTitleBar(
      backgroundColor: widget.extendBodyBehindTitleBar
          ? Colors.transparent
          : scheme.surface,
      border: BorderSide.none,
      centerTitle: true,
      leading: widget.showBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Center(
                child: Semantics(
                  label: 'Back',
                  button: true,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Material(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: widget.onBackPressed,
                        child: Icon(
                          YaruIcons.go_previous,
                          size: 18,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 3,
        children: widget.showTitlebarOption
            ? [
                SizedBox(width: 56),
                _LinuxTitleBarActionButton(
                  icon: YaruIcons.home_filled,
                  label: 'Home',
                  selected: widget.isHomeSelected,
                  onPressed: widget.onHomePressed,
                ),
                _LinuxTitleBarActionButton(
                  icon: YaruIcons.app_grid,
                  label: 'Library',
                  selected: widget.isLibrarySelected,
                  onPressed: widget.onLibraryPressed,
                ),
                _LinuxTitleBarActionButton(
                  icon: CupertinoIcons.search,
                  label: 'Search',
                  selected: widget.isSearchSelected,
                  onPressed: widget.onSearchPressed,
                ),
              ]
            : [],
      ),
    );
    final body = ColoredBox(color: scheme.surface, child: widget.child);

    return ColoredBox(
      color: scheme.surface,
      child: widget.extendBodyBehindTitleBar
          ? Stack(
              fit: StackFit.expand,
              children: [
                body,
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: kYaruTitleBarHeight,
                    child: titleBar,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  height: kYaruTitleBarHeight,
                  child: titleBar,
                ),
                Expanded(child: body),
              ],
            ),
    );
  }
}

class _LinuxTitleBarActionButton extends StatelessWidget {
  const _LinuxTitleBarActionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseColor = selected
        ? scheme.onSurface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
          )
        : Colors.transparent;
    const buttonHeight = 34.0;
    final borderRadius = BorderRadius.circular(10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        hoverColor: scheme.onSurface.withValues(alpha: 0.12),
        splashColor: scheme.onSurface.withValues(alpha: 0.06),
        highlightColor: scheme.onSurface.withValues(alpha: 0.18),
        child: Ink(
          height: buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: borderRadius,
          ),
          child: DefaultTextStyle(
            style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            child: IconTheme(
              data: IconThemeData(color: scheme.onSurface, size: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(icon), const SizedBox(width: 8), Text(label)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopMaterialShell extends StatelessWidget {
  const DesktopMaterialShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Aetherfin')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.12),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class CupertinoRootShell extends StatelessWidget {
  const CupertinoRootShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}
