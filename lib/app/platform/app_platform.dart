import 'package:flutter/foundation.dart';

enum AppPlatform { linux, cupertino, windows, material }

AppPlatform get currentAppPlatform {
  final override = debugAppPlatformOverride;
  if (override != null) {
    return override;
  }
  if (kIsWeb) return AppPlatform.material;
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
      return AppPlatform.linux;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return AppPlatform.cupertino;
    case TargetPlatform.windows:
      return AppPlatform.windows;
    case TargetPlatform.fuchsia:
      return AppPlatform.material;
  }
}

AppPlatform? debugAppPlatformOverride;
