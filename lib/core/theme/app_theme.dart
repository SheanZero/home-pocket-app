import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.accentPrimary,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Outfit',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: AppColors.borderDefault),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.accentPrimary,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColorsDark.background,
        fontFamily: 'Outfit',
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorsDark.background,
          foregroundColor: AppColorsDark.textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorsDark.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: AppColorsDark.borderDefault),
          ),
        ),
      );
}
