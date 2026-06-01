import 'package:flutter/material.dart';

import 'app_palette.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF0E9AA7), // accentPrimary teal (ADR-018)
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FCFD), // background (ADR-018)
    fontFamily: 'Outfit',
    extensions: const [AppPalette.light],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FCFD), // background (ADR-018)
      foregroundColor: Color(0xFF112025), // textPrimary (ADR-018)
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF), // card (ADR-018)
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: const BorderSide(color: Color(0xFFE5F0F1)), // borderDefault (ADR-018)
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF0E9AA7), // same seed, brightness drives M3
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0C1719), // background dark (ADR-018)
    fontFamily: 'Outfit',
    extensions: const [AppPalette.dark],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0C1719), // background dark (ADR-018)
      foregroundColor: Color(0xFFE8F2F3), // textPrimary dark (ADR-018)
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF162527), // card dark (ADR-018)
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: const BorderSide(color: Color(0xFF213537)), // borderDefault dark (ADR-018)
      ),
    ),
  );
}
