import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';

import 'app.dart';
import 'platform/app_platform.dart';
import 'router/app_router.dart';
import 'session/app_session_controller.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    fvp.registerWith();
  }
  if (currentAppPlatform == AppPlatform.linux) {
    await YaruWindowTitleBar.ensureInitialized();
  }
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    this.enableLinuxTray = true,
  });

  final bool enableLinuxTray;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final AppSessionController _sessionController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _sessionController = AppSessionController();
    _router = createAppRouter(_sessionController);
    _sessionController.initialize();
  }

  @override
  void dispose() {
    _router.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AetherfinApp(
      router: _router,
      sessionController: _sessionController,
      enableLinuxTray: widget.enableLinuxTray,
    );
  }
}
