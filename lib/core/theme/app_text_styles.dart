import 'package:flutter/material.dart';

// app_colors.dart import removed (D-06 — olive merged into success token).
// Static const text styles use ADR-018 hex literals for textPrimary (#112025) and
// textSecondary (#5A7176). Apply ledger-color overrides at call site:
//   AppTextStyles.amountLarge.copyWith(color: context.palette.dailyText)

abstract final class AppTextStyles {
  static const _fontFamily = 'Outfit';
  static const _tabularFigures = [FontFeature.tabularFigures()];

  // ADR-018 Light hex constants (static const TextStyles cannot reference context.palette)
  static const _textPrimary = Color(0xFF112025); // ADR-018 light textPrimary
  static const _textSecondary = Color(0xFF5A7176); // ADR-018 light textSecondary

  // ── Headlines ──

  static const headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 0.9,
    color: _textPrimary,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
  );

  static const headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
  );

  // ── Titles ──

  static const titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
  );

  static const titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _textPrimary,
  );

  static const titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _textPrimary,
  );

  // ── Body ──

  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _textSecondary,
  );

  // ── Captions & Labels ──

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _textSecondary,
  );

  static const overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: _textSecondary,
  );

  static const micro = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
  );

  // ── Section divider label ──

  static const dividerLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
    color: _textSecondary,
  );

  // ── Labels (compat) ──

  static const labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _textSecondary,
  );

  static const labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: _textSecondary,
  );

  // ── Nav ──

  static const navLabel = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  static const navLabelActive = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── Amount styles (tabular figures for numeric alignment) ──
  // Apply ledger color via .copyWith(color: context.palette.dailyText) at call site.
  // NEVER use palette.joy directly for amount text — use palette.joyText (#9A6500 light).

  static const amountLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 0.9,
    color: _textPrimary,
    fontFeatures: _tabularFigures,
  );

  static const amountMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
    fontFeatures: _tabularFigures,
  );

  static const amountSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
    fontFeatures: _tabularFigures,
  );

  // ── Compatibility aliases ──
  // TODO: Remove after all screens are migrated to Wa-Modern

  static const tabLabel = navLabel;

  // olive reference removed (D-06 — merged into success token).
  // Apply color at call site: .copyWith(color: context.palette.success)
  static const comparisonDelta = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const legendLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: _textSecondary,
  );
}
