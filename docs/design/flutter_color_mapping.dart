// Home Pocket — Wa-Modern Design Token Mapping
// Generated from untitled.pen design file (2026-04-01)
//
// This file maps design tokens to Flutter Color constants.
// Copy relevant values to lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// ========================================
/// LIGHT THEME
/// ========================================
abstract class WaModernLight {
  // Backgrounds
  static const background = Color(0xFFFCFBF9); // warm ivory
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFF5F4F2); // section divider lines
  static const subtle = Color(0xFFFCFBF9); // nested card (last month)
  static const divider = Color(0xFFF0F0F0); // inner card dividers

  // Text
  static const textPrimary = Color(0xFF1E2432);
  static const textSecondary = Color(0xFFABABAB);
  static const textTertiary = Color(0xFFC4C4C4); // inactive nav, chevrons

  // Borders
  static const borderDefault = Color(0xFFEFEFEF); // card strokes
  static const borderDivider = Color(0xFFF5F4F2); // section dividers
  static const borderList = Color(0xFFE8E8E8); // transaction list
  static const borderInputActive = Color(0xFFE85A4F);

  // Accent — Primary (Coral)
  static const accentPrimary = Color(0xFFE85A4F);
  static const accentPrimaryLight = Color(0xFFFEF5F4); // family badge bg, satisfaction bg
  static const accentPrimaryBorder = Color(0xFFF5D5D2); // satisfaction border
  static const accentGradientStart = Color(0xFFF08070); // FAB gradient
  static const accentGradientEnd = Color(0xFFE85A4F);

  // Accent — Survival (Blue)
  static const survival = Color(0xFF5A9CC8);
  static const survivalLight = Color(0xFFE8F0F8); // survival tag bg

  // Accent — Soul (Green)
  static const soul = Color(0xFF47B88A);
  static const soulLight = Color(0xFFE5F5ED); // soul tag bg

  // Accent — Olive (Trends)
  static const olive = Color(0xFF8A9178);
  static const oliveLight = Color(0xFFF0FAF4); // trend badge bg, ROI bg
  static const oliveBorder = Color(0xFFC8E6D5); // ROI border

  // Shared Ledger (Group mode)
  static const shared = Color(0xFFD4845A);
  static const sharedLight = Color(0xFFFFF0E0); // shared tag bg
  static const sharedBorder = Color(0xFFF0DCC8); // shared ledger border
  static const sharedChevron = Color(0xFFD4B89A);
}

/// ========================================
/// DARK THEME
/// ========================================
abstract class WaModernDark {
  // Backgrounds
  static const background = Color(0xFF1A1D27);
  static const card = Color(0xFF252836);
  static const muted = Color(0xFF353845); // dividers, borders
  static const subtle = Color(0xFF1E2130); // nested card (last month)

  // Text
  static const textPrimary = Color(0xFFF0F0F2);
  static const textSecondary = Color(0xFF6B6E7A);

  // Borders
  static const borderDefault = Color(0xFF353845);

  // Tag Tints (dark backgrounds for colored tags)
  static const tagBlue = Color(0xFF1E2D3D); // survival tag
  static const tagGreen = Color(0xFF1E3028); // soul tag
  static const tagOrange = Color(0xFF3D2D1E); // shared tag
  static const tagOlive = Color(0xFF2D3028); // olive tag

  // Soul Fullness Card
  static const soulSatisfactionBg = Color(0xFF3D2525);
  static const soulSatisfactionBorder = Color(0xFF5A3535);
  static const soulRoiBg = Color(0xFF1E3028);
  static const soulRoiBorder = Color(0xFF2D4D3A);

  // Shared Ledger (Group mode)
  static const sharedBorder = Color(0xFF4D3D2D);

  // Family Badge
  static const familyBadgeBg = Color(0xFF3D2525);

  // Trend Badge
  static const trendBadgeBg = Color(0xFF1E3028);
}

/// ========================================
/// COMPONENT TOKENS
/// ========================================
abstract class WaModernComponents {
  // Bottom Navigation
  static const navPillHeight = 62.0;
  static const navPillRadius = 32.0;
  static const fabSize = 62.0;
  static const fabRadius = 31.0;
  static const navGap = 12.0;
  static const navActiveTabRadius = 14.0;

  // Cards
  static const cardRadius = 14.0;
  static const cardPaddingLg = 18.0;
  static const cardPaddingMd = 16.0;
  static const cardBorderWidth = 1.0;

  // Ledger Rows
  static const ledgerRowRadius = 12.0;
  static const ledgerRowPaddingV = 10.0;
  static const ledgerRowPaddingH = 14.0;
  static const ledgerRowGap = 8.0;
  static const ledgerTagRadius = 3.0;

  // Transaction Rows
  static const txRowPaddingV = 10.0;
  static const txRowPaddingH = 14.0;
  static const txRowGap = 8.0;

  // Member Avatars
  static const avatarSize = 24.0;
  static const avatarRadius = 12.0;
  static const avatarStrokeWidth = 2.0;
  static const avatarOverlap = -6.0;

  // Family Badge
  static const familyBadgeRadius = 8.0;

  // Screen Layout
  static const screenWidth = 402.0;
  static const screenPadding = 28.0;
  static const contentTopPadding = 4.0;
  static const sectionGap = 16.0;
  static const statusBarHeight = 54.0;

  // Shadows
  static const navShadowLight = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 20,
    color: Color(0x08000000),
  );
  static const navShadowDark = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 20,
    color: Color(0x20000000),
  );
  static const fabShadow = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 14,
    color: Color(0x35E85A4F),
  );
}
