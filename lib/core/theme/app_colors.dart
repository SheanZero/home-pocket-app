import 'dart:ui';

abstract final class AppColors {
  // ── Backgrounds ──
  static const background = Color(0xFFFCFBF9); // warm ivory
  static const backgroundWarm = background; // accounting entry screens
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
  static const accentPrimaryLight = Color(
    0xFFFEF5F4,
  ); // family badge, satisfaction
  static const accentPrimaryBorder = Color(0xFFF5D5D2);
  static const fabGradientStart = Color(0xFFF08070);
  static const fabGradientEnd = Color(0xFFE85A4F);
  static const actionGradientStart = fabGradientStart;
  static const actionGradientEnd = fabGradientEnd;
  static const actionShadow = Color(0x4DE85A4F);

  // ── Recording — Phase 22 D-04 (mic button recording state) ──
  static const recordingGradientStart = Color(0xFFE05050);
  static const recordingGradientEnd = Color(0xFFC03030);

  // ── Accent — Daily (Blue) ──
  static const daily = Color(0xFF5A9CC8);
  static const dailyLight = Color(0xFFE8F0F8);

  // ── Accent — Joy (Green) ──
  static const joy = Color(0xFF47B88A);
  static const joyLight = Color(0xFFE5F5ED);
  static const tagGreen = joyLight;

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

  // ── Best Joy strip (Variant A — Pencil mock n6VVd) ──
  static const surfaceCream = Color(0xFFFFFDF8); // Best Joy card background
  static const surfaceCreamBorder = Color(0xFFF2E4C9); // Best Joy card border
  static const textMutedGold = Color(0xFFB39A71); // Merchant/date muted text
  static const satisfactionPillBg = Color(
    0xFFFFF1F1,
  ); // Pill background (light pink)
  static const satisfactionPillRose = Color(0xFFD45F65); // Pill icon + label

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

  // ── Joy card ──
  static const joyFullnessBg = Color(0xFF3D2525);
  static const joyFullnessBorder = Color(0xFF5A3535);
  static const joyRoiBg = Color(0xFF1E3028);
  static const joyRoiBorder = Color(0xFF2D4D3A);

  // ── Family badge ──
  static const familyBadgeBg = Color(0xFF3D2525);

  // ── Nav shadow ──
  static const navShadow = Color(0x20000000);

  // ── Recording — Phase 22 D-04 (dark-theme variant) ──
  static const recordingGradientStart = Color(0xFFE07070);
  static const recordingGradientEnd = Color(0xFFB04040);
}
