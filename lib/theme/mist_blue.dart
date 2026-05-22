import 'package:flutter/material.dart';

const Color mistBlueBackground  = Color(0xFFF0F2F5);
const Color mistBlueSurface     = Color(0xFFDDE3EC);
const Color mistBluePrimary     = Color(0xFF8AA5C2);
const Color mistBlueSecondary   = Color(0xFFA8BAA8);
const Color mistBlueText        = Color(0xFF1E2D3D);
const Color mistBlueTextMuted   = Color(0xFF3D4E5E);
const Color mistBlueBorder      = Color(0xFFC8D0DC);
const Color mistBluePillFood    = Color(0xFFDDE3EC);
const Color mistBluePillFoodTxt = Color(0xFF3D4E5E);
const Color mistBluePillTag     = Color(0xFFC8D8C8);
const Color mistBluePillTagTxt  = Color(0xFF3A5A3A);
const Color mistBlueAvatarBg    = Color(0xFFDDE3EC);
const Color mistBlueAvatarTxt   = Color(0xFF3D4E5E);

ThemeData mistBlueTheme() {
  return ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: mistBluePrimary,
      onPrimary: Colors.white,
      secondary: mistBlueSecondary,
      onSecondary: Colors.white,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: mistBlueSurface,
      onSurface: mistBlueText,
    ),
    scaffoldBackgroundColor: mistBlueBackground,
    cardColor: mistBlueSurface,
    dividerColor: mistBlueBorder,
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: mistBlueText),
      bodyMedium: TextStyle(color: mistBlueText),
      bodySmall:  TextStyle(color: mistBlueTextMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: mistBlueBackground,
      foregroundColor: mistBlueText,
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
