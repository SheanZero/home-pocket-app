import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final textTheme = AppTextStyles.buildTextTheme(
      textPrimary: AppPalette.light.textPrimary,
      textSecondary: AppPalette.light.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppPalette.light.accentPrimary,
      brightness: Brightness.light,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
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
  }

  static ThemeData get dark {
    final textTheme = AppTextStyles.buildTextTheme(
      textPrimary: AppPalette.dark.textPrimary,
      textSecondary: AppPalette.dark.textSecondary,
    );
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.dark.accentPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppPalette.dark.accentPrimary,
          onPrimary: AppPalette.dark.card,
          primaryContainer: AppPalette.dark.accentPrimaryLight,
          onPrimaryContainer: AppPalette.dark.accentPrimaryText,
          secondary: AppPalette.dark.joy,
          onSecondary: AppPalette.dark.card,
          secondaryContainer: AppPalette.dark.joyLight,
          onSecondaryContainer: AppPalette.dark.joyText,
          tertiary: AppPalette.dark.shared,
          onTertiary: AppPalette.dark.background,
          tertiaryContainer: AppPalette.dark.sharedLight,
          onTertiaryContainer: AppPalette.dark.sharedText,
          error: AppPalette.dark.error,
          onError: AppPalette.dark.card,
          errorContainer: AppPalette.dark.errorSurface,
          onErrorContainer: AppPalette.dark.error,
          surface: AppPalette.dark.card,
          onSurface: AppPalette.dark.textPrimary,
          surfaceContainerLowest: AppPalette.dark.background,
          surfaceContainerLow: AppPalette.dark.backgroundSubtle,
          surfaceContainer: AppPalette.dark.card,
          surfaceContainerHigh: AppPalette.dark.backgroundMuted,
          surfaceContainerHighest: AppPalette.dark.backgroundMuted,
          onSurfaceVariant: AppPalette.dark.textSecondary,
          outline: AppPalette.dark.borderList,
          outlineVariant: AppPalette.dark.borderDefault,
          shadow: Colors.black,
          scrim: Colors.black,
          surfaceTint: Colors.transparent,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor:
          AppPalette.dark.background, // #171C19 A3 ink-green dark
      extensions: const [AppPalette.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.dark.background, // #171C19 (Mockup A3)
        foregroundColor: AppPalette.dark.textPrimary, // #EEF1EB (Mockup A3)
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
          ), // #354038 (Mockup A3)
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
}
