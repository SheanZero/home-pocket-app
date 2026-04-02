import 'dart:ui';

abstract final class AppColors {
  // ── Backgrounds ──
  static const background = Color(0xFFFCFBF9); // warm ivory
  static const card = Color(0xFFFFFFFF);
  static const backgroundMuted = Color(0xFFF5F4F2); // section divider lines
  static const backgroundSubtle = Color(0xFFFCFBF9); // nested card (last month)
  static const backgroundDivider = Color(0xFFF0F0F0); // inner card dividers

  // ── Text ──
  static const textPrimary = Color(0xFF1E2432);
  static const textSecondary = Color(0xFFABABAB);
  static const textTertiary = Color(0xFFC4C4C4); // inactive nav, chevrons

  // ── Borders ──
  static const borderDefault = Color(0xFFEFEFEF); // card strokes
  static const borderDivider = Color(0xFFF5F4F2); // section dividers
  static const borderList = Color(0xFFE8E8E8); // transaction list
  static const borderInputActive = Color(0xFFE85A4F);

  // ── Accent — Primary (Coral) ──
  static const accentPrimary = Color(0xFFE85A4F);
  static const accentPrimaryLight = Color(0xFFFEF5F4); // family badge, satisfaction
  static const accentPrimaryBorder = Color(0xFFF5D5D2);
  static const fabGradientStart = Color(0xFFF08070);
  static const fabGradientEnd = Color(0xFFE85A4F);

  // ── Accent — Survival (Blue) ──
  static const survival = Color(0xFF5A9CC8);
  static const survivalLight = Color(0xFFE8F0F8);

  // ── Accent — Soul (Green) ──
  static const soul = Color(0xFF47B88A);
  static const soulLight = Color(0xFFE5F5ED);

  // ── Accent — Olive (Trends) ──
  static const olive = Color(0xFF8A9178);
  static const oliveLight = Color(0xFFF0FAF4);
  static const oliveBorder = Color(0xFFC8E6D5);

  // ── Shared Ledger (Group mode) ──
  static const shared = Color(0xFFD4845A);
  static const sharedLight = Color(0xFFFFF0E0);
  static const sharedBorder = Color(0xFFF0DCC8);
  static const sharedChevron = Color(0xFFD4B89A);

  // ── Shadows ──
  static const fabShadow = Color(0x35E85A4F);
  static const navShadow = Color(0x08000000);

  // ── Compatibility aliases ──
  // TODO: Remove after all screens are migrated to Wa-Modern
  static const primary = accentPrimary;
  static const divider = borderDivider;
  static const tabBarBackground = card;
  static const textMuted = textSecondary;
  static const inactiveTab = textTertiary;
  static const comparisonPositive = olive;
  static const survivalBorder = borderDefault;

  // Home feature compat (hero_header, home_screen)
  static const heroBackground = background;
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Home feature compat (month_overview_card)
  static const modeBadgeBg = accentPrimaryLight;
  static const survivalBarBg = Color(0xFFD0DEE8);
  static const previousBarSurvival = Color(0xFFB8CCDA);
  static const previousBarSoul = Color(0xFFA0B8C8);
  static const currentBarSoul = Color(0xFFB0D8F0);

  // Home feature compat (family_invite_banner)
  static const familyInviteBackground = card;

  // Home feature compat (soul_fullness_card)
  static const soulCardBg = Color(0xFFF4FCF8);
  static const soulMetricBg1 = Color(0xFFE5F5ED);
  static const soulMetricBg2 = Color(0xFFD9F0E5);
  static const soulProgressBg = Color(0xFFD4EDDF);
  static const soulBadgeBg = Color(0xFFD4F0E2);
  static const soulTextDark = Color(0xFF2D8E68);
  static const soulTextMuted = Color(0xFF5A7A64);
  static const soulQuoteText = Color(0xFF7A9A84);

  // Home feature compat (ohtani_converter)
  static const ohtaniBackground = Color(0xFF2F5B78);
  static const ohtaniText = Color(0xFFEAF6FF);
  static const ohtaniClose = Color(0xFFB9CFDF);
}
