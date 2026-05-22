import 'package:flutter/material.dart';
import 'warm_sand.dart';
import 'mist_blue.dart';

enum AppThemeMode { warmSand, mistBlue }

ThemeData getTheme(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.warmSand:
      return warmSandTheme();
    case AppThemeMode.mistBlue:
      return mistBlueTheme();
  }
}
