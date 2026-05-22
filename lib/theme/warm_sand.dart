import 'package:flutter/material.dart';

const Color warmSandBackground  = Color(0xFFF5F0E8);
const Color warmSandSurface     = Color(0xFFE8DDD0);
const Color warmSandPrimary     = Color(0xFFC4A882);
const Color warmSandSecondary   = Color(0xFF9BAF9B);
const Color warmSandText        = Color(0xFF3D3028);
const Color warmSandTextMuted   = Color(0xFF6B5C4E);
const Color warmSandBorder      = Color(0xFFD5C8BA);
const Color warmSandPillFood    = Color(0xFFE8DDD0);
const Color warmSandPillFoodTxt = Color(0xFF6B5C4E);
const Color warmSandPillTag     = Color(0xFFD8E8D8);
const Color warmSandPillTagTxt  = Color(0xFF4A6B4A);
const Color warmSandAvatarBg    = Color(0xFFE8DDD0);
const Color warmSandAvatarTxt   = Color(0xFF6B5C4E);

ThemeData warmSandTheme() {
  return ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: warmSandPrimary,
      onPrimary: Colors.white,
      secondary: warmSandSecondary,
      onSecondary: Colors.white,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: warmSandSurface,
      onSurface: warmSandText,
    ),
    scaffoldBackgroundColor: warmSandBackground,
    cardColor: warmSandSurface,
    dividerColor: warmSandBorder,
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: warmSandText),
      bodyMedium: TextStyle(color: warmSandText),
      bodySmall:  TextStyle(color: warmSandTextMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: warmSandBackground,
      foregroundColor: warmSandText,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
