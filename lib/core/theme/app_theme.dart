import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6FA36F), // accentPrimary leaf green (ADR-019)
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.light.background, // #FBF7F4 warm cream (ADR-019)
    fontFamily: 'Outfit',
    extensions: const [AppPalette.light],
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.light.background, // #FBF7F4 (ADR-019)
      foregroundColor: AppPalette.light.textPrimary, // #20352B (ADR-019)
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppPalette.light.card, // #FFFFFF (unchanged)
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppPalette.light.borderDefault), // #E6DDD8 (ADR-019)
      ),
    ),
    // Soft rounded warm dialog chrome — every AlertDialog (input/picker/info
    // dialogs) inherits this so they match the soft-confirm / soft-toast family
    // without per-dialog rewrites (260603-nr1 global-feedback sweep).
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.light.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppPalette.light.borderDefault),
      ),
      titleTextStyle: AppTextStyles.titleSmall.copyWith(
        color: AppPalette.light.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppPalette.light.textSecondary,
        height: 1.5,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6FA36F), // same seed, brightness drives M3
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPalette.dark.background, // #171210 warm-dark (ADR-019)
    fontFamily: 'Outfit',
    extensions: const [AppPalette.dark],
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.dark.background, // #171210 (ADR-019)
      foregroundColor: AppPalette.dark.textPrimary, // #F0EBE6 (ADR-019)
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppPalette.dark.card, // #231E1B (ADR-019)
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppPalette.dark.borderDefault), // #2E2723 (ADR-019)
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.dark.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppPalette.dark.borderDefault),
      ),
      titleTextStyle: AppTextStyles.titleSmall.copyWith(
        color: AppPalette.dark.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppPalette.dark.textSecondary,
        height: 1.5,
      ),
    ),
  );
}
