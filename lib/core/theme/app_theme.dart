import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppPalette.light.accentPrimary,
    brightness: Brightness.light,
    textTheme: AppTextStyles.buildTextTheme(
      textPrimary: AppPalette.light.textPrimary,
      textSecondary: AppPalette.light.textSecondary,
    ),
    scaffoldBackgroundColor: AppPalette.light.background,
    extensions: const [AppPalette.light],
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.light.background,
      foregroundColor: AppPalette.light.textPrimary,
      titleTextStyle: AppTextStyles.pageTitle.copyWith(
        color: AppPalette.light.textPrimary,
      ),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppPalette.light.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppPalette.light.borderDefault),
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
    colorSchemeSeed: AppPalette.dark.accentPrimary,
    brightness: Brightness.dark,
    textTheme: AppTextStyles.buildTextTheme(
      textPrimary: AppPalette.dark.textPrimary,
      textSecondary: AppPalette.dark.textSecondary,
    ),
    scaffoldBackgroundColor:
        AppPalette.dark.background, // #171210 warm-dark (ADR-019)
    extensions: const [AppPalette.dark],
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.dark.background, // #171210 (ADR-019)
      foregroundColor: AppPalette.dark.textPrimary, // #F0EBE6 (ADR-019)
      titleTextStyle: AppTextStyles.pageTitle.copyWith(
        color: AppPalette.dark.textPrimary,
      ),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppPalette.dark.card, // #231E1B (ADR-019)
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(
          color: AppPalette.dark.borderDefault,
        ), // #2E2723 (ADR-019)
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
