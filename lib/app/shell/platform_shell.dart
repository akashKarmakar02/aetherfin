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
    this.onBackPressed,
    this.enableTray = true,
  });

  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
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
    await trayManager.setIcon('web/favicon.png');
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
        print("Hola");
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

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: YaruWindowTitleBar(
        backgroundColor: scheme.surface,
        border: BorderSide.none,
        leading: widget.showBackButton
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Semantics(
                  label: 'Back',
                  button: true,
                  child: YaruIconButton(
                    onPressed: widget.onBackPressed,
                    icon: const Icon(YaruIcons.go_previous),
                  ),
                ),
              )
            : null,
        title: const Text('Aetherfin'),
      ),
      body: ColoredBox(color: scheme.surface, child: widget.child),
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
