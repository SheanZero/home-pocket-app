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
  static const divider = borderDivider;
  static const tabBarBackground = card;
}

/// Dark theme colors (Wa-Modern)
abstract final class AppColorsDark {
  // ── Backgrounds ──
  static const background = Color(0xFF1A1D27);
  static const card = Color(0xFF252836);
  static const backgroundMuted = Color(0xFF353845);
  static const backgroundSubtle = Color(0xFF1E2130);
  static const backgroundDivider = Color(0xFF353845);

  // ── Text ──
  static const textPrimary = Color(0xFFF0F0F2);
  static const textSecondary = Color(0xFF6B6E7A);
  static const textTertiary = Color(0xFF6B6E7A);

  // ── Borders ──
  static const borderDefault = Color(0xFF353845);
  static const borderDivider = Color(0xFF353845);
  static const borderList = Color(0xFF353845);

  // ── Tag tints ──
  static const tagBlue = Color(0xFF1E2D3D);
  static const tagGreen = Color(0xFF1E3028);
  static const tagOrange = Color(0xFF3D2D1E);

  // ── Soul card ──
  static const soulSatisfactionBg = Color(0xFF3D2525);
  static const soulSatisfactionBorder = Color(0xFF5A3535);
  static const soulRoiBg = Color(0xFF1E3028);
  static const soulRoiBorder = Color(0xFF2D4D3A);

  // ── Family badge ──
  static const familyBadgeBg = Color(0xFF3D2525);

  // ── Nav shadow ──
  static const navShadow = Color(0x20000000);
}
