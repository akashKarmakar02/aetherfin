import 'package:flutter/material.dart';

class LinuxAppTheme {
  static ThemeData resolve(ThemeData base) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        surfaceContainerLowest: const Color(0xFF343437),
        surfaceContainerLow: const Color(0xFF242426),
        surfaceContainerHigh: const Color(0xFF38383B),
        surfaceContainerHighest: const Color(0xFF3C3C40),
      ),
    );
  }
}
