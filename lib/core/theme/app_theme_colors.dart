import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extension to resolve Wa-Modern colors based on current theme brightness.
///
/// Use `context.wmCard` instead of `AppColors.card` for theme-dependent colors.
/// Keep using `AppColors.*` directly for accent colors that stay the same in
/// both themes (e.g. `AppColors.accentPrimary`, `AppColors.survival`).
extension AppThemeColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Backgrounds ──
  Color get wmBackground =>
      _isDark ? AppColorsDark.background : AppColors.background;
  Color get wmCard => _isDark ? AppColorsDark.card : AppColors.card;
  Color get wmBackgroundMuted =>
      _isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted;
  Color get wmBackgroundSubtle =>
      _isDark ? AppColorsDark.backgroundSubtle : AppColors.backgroundSubtle;
  Color get wmBackgroundDivider =>
      _isDark ? AppColorsDark.backgroundDivider : AppColors.backgroundDivider;

  // ── Text ──
  Color get wmTextPrimary =>
      _isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
  Color get wmTextSecondary =>
      _isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
  Color get wmTextTertiary =>
      _isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;

  // ── Borders ──
  Color get wmBorderDefault =>
      _isDark ? AppColorsDark.borderDefault : AppColors.borderDefault;
  Color get wmBorderDivider =>
      _isDark ? AppColorsDark.borderDivider : AppColors.borderDivider;
  Color get wmBorderList =>
      _isDark ? AppColorsDark.borderList : AppColors.borderList;

  // ── Shadows ──
  Color get wmNavShadow =>
      _isDark ? AppColorsDark.navShadow : AppColors.navShadow;

  // ── Soul card (satisfaction / ROI) ──
  Color get wmSatisfactionBg =>
      _isDark ? AppColorsDark.soulSatisfactionBg : AppColors.accentPrimaryLight;
  Color get wmSatisfactionBorder => _isDark
      ? AppColorsDark.soulSatisfactionBorder
      : AppColors.accentPrimaryBorder;
  Color get wmRoiBg =>
      _isDark ? AppColorsDark.soulRoiBg : AppColors.oliveLight;
  Color get wmRoiBorder =>
      _isDark ? AppColorsDark.soulRoiBorder : AppColors.oliveBorder;

  // ── Family badge ──
  Color get wmFamilyBadgeBg =>
      _isDark ? AppColorsDark.familyBadgeBg : AppColors.accentPrimaryLight;

  // ── Ledger tag tints ──
  Color get wmSurvivalTagBg =>
      _isDark ? AppColorsDark.tagBlue : AppColors.survivalLight;
  Color get wmSoulTagBg =>
      _isDark ? AppColorsDark.tagGreen : AppColors.soulLight;
  Color get wmSharedTagBg =>
      _isDark ? AppColorsDark.tagOrange : AppColors.sharedLight;
}
