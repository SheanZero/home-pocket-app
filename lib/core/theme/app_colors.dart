import 'dart:ui';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF8AB8DA);
  static const survival = Color(0xFF5A9CC8);
  static const soul = Color(0xFF47B88A);
  static const accentPrimary = Color(0xFFE85A4F);

  // Backgrounds
  static const background = Color(0xFFF1F7FD);
  static const card = Color(0xFFFFFFFF);
  static const backgroundWarm = Color(0xFFFCFBF9);
  static const backgroundMuted = Color(0xFFF5F4F2);
  static const heroBackground = Color(0xFF8AB8DA);
  static const tabBarBackground = Color(0xFFF7FBFF);
  static const familyInviteBackground = Color(0xFFF4F9FE);

  // Text
  static const textPrimary = Color(0xFF2C2C2C);
  static const textSecondary = Color(0xFF9A9A9A);
  static const textTertiary = Color(0xFFABABAB);
  static const textMuted = Color(0xFF6B6B6B);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Surfaces
  static const borderDefault = Color(0xFFEFEFEF);
  static const backgroundDivider = Color(0xFFF0F0F0);

  // Survival tints
  static const survivalLight = Color(0x155A9CC8);
  static const survivalBorder = Color(0xFFD8E8F5);
  static const survivalBarBg = Color(0xFFD0DEE8);

  // Soul tints
  static const soulLight = Color(0xFFE8F8EF);
  static const tagGreen = Color(0xFFE5F5ED);
  static const soulCardBg = Color(0xFFF4FCF8);
  static const soulMetricBg1 = Color(0xFFE5F5ED);
  static const soulMetricBg2 = Color(0xFFD9F0E5);
  static const soulProgressBg = Color(0xFFD4EDDF);
  static const soulBadgeBg = Color(0xFFD4F0E2);
  static const soulTextDark = Color(0xFF2D8E68);
  static const soulTextMuted = Color(0xFF5A7A64);
  static const soulQuoteText = Color(0xFF7A9A84);

  // Month comparison
  static const comparisonPositive = Color(0xFF6DB87A);
  static const previousBarSurvival = Color(0xFFB8CCDA);
  static const previousBarSoul = Color(0xFFA0B8C8);
  static const currentBarSoul = Color(0xFFB0D8F0);

  // Misc
  static const divider = Color(0xFFD0DEE8);
  static const fabGradientStart = Color(0xFF90C4E8);
  static const fabGradientEnd = Color(0xFF5A9CC8);
  static const fabShadow = Color(0x665A9CC8);
  static const actionGradientStart = Color(0xFFF08070);
  static const actionGradientEnd = Color(0xFFE85A4F);
  static const actionShadow = Color(0x4DE85A4F);
  static const ohtaniBackground = Color(0xFF2F5B78);
  static const ohtaniText = Color(0xFFEAF6FF);
  static const ohtaniClose = Color(0xFFB9CFDF);
  static const inactiveTab = Color(0xFFAAAAAA);
  static const modeBadgeBg = Color(0x205A9CC8);
}

abstract final class AppColorsDark {
  static const background = Color(0xFF1A1D27);
  static const card = Color(0xFF252836);
  static const backgroundMuted = Color(0xFF353845);
  static const textPrimary = Color(0xFFF0F0F2);
  static const textSecondary = Color(0xFF9DA3B0);
  static const textTertiary = Color(0xFF6B6E7A);
  static const borderDefault = Color(0xFF353845);
  static const backgroundDivider = Color(0xFF353845);
  static const tagGreen = Color(0xFF233A31);
}
