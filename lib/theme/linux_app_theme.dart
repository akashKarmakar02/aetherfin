import 'package:flutter/material.dart';

class LinuxAppTheme {
  static ThemeData resolve(ThemeData base) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        surfaceContainerLowest: const Color(0xFF343437),
      ),
    );
  }
}
