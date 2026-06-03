import 'package:flutter/material.dart';

/// Semantic color token system for Home Pocket — ADR-019 Sakura Mochi × Wakaba palette.
///
/// Use [AppPalette.light] and [AppPalette.dark] as the authoritative source
/// for all color tokens. Access via [BuildContext.palette] in widget trees.
///
/// Amount-text colors ([dailyText], [joyText], [sharedText]) are WCAG AA ≥4.5:1
/// on [card] (#FFFFFF). NEVER use [daily], [joy], or [shared] directly for
/// numeric amount text — use the *Text variants (CLAUDE.md Amount Display Style).
///
/// Example:
/// ```dart
/// Text(amount,
///   style: AppTextStyles.amountLarge.copyWith(
///     color: context.palette.dailyText,
///   ));
/// ```
final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    // ── Backgrounds ──
    required this.background,
    required this.card,
    required this.backgroundMuted,
    required this.backgroundSubtle,
    required this.backgroundDivider,
    // ── Text ──
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    // ── Borders ──
    required this.borderDefault,
    required this.borderDivider,
    required this.borderList,
    required this.borderInputActive,
    // ── Accent primary (Leaf Green) ──
    required this.accentPrimary,
    required this.accentPrimaryLight,
    required this.accentPrimaryBorder,
    required this.fabGradientStart,
    required this.fabGradientEnd,
    required this.actionShadow,
    // ── Recording ──
    required this.recordingGradientStart,
    required this.recordingGradientEnd,
    // ── Ledger — Daily ──
    required this.daily,
    required this.dailyText,
    required this.dailyLight,
    // ── Ledger — Joy ──
    required this.joy,
    required this.joyText,
    required this.joyLight,
    // ── Ledger — Shared ──
    required this.shared,
    required this.sharedText,
    required this.sharedLight,
    required this.sharedBorder,
    required this.sharedChevron,
    // ── Semantic ──
    required this.success,
    required this.successLight,
    required this.warning,
    required this.error,
    required this.info,
    // ── Error tints ──
    required this.errorSurface,
    required this.errorBorder,
    required this.errorShadow,
    // ── Shadows ──
    required this.fabShadow,
    required this.navShadow,
    // ── Joy card (satisfaction / ROI) ──
    required this.joyFullnessBg,
    required this.joyFullnessBorder,
    required this.joyRoiBg,
    required this.joyRoiBorder,
    // ── Family ──
    required this.familyBadgeBg,
    // ── Best Joy strip ──
    required this.surfaceCream,
    required this.surfaceCreamBorder,
    required this.textMutedGold,
    required this.satisfactionPillBg,
    required this.satisfactionPillRose,
    // ── Decorative — avatar (leaf-green family) ──
    required this.avatarGradientStart,
    required this.avatarGradientMid,
    required this.avatarGradientEnd,
    // ── Single brightness-resolved avatar border alpha ──
    // light = Color(0x80FFFFFF), dark = Color(0x26FFFFFF).
    // Call site uses palette.avatarBorderAlpha with NO isDark check (D-04).
    required this.avatarBorderAlpha,
    // ── Decorative — member tile (leaf-green family) ──
    required this.memberGradientA,
    required this.memberGradientB,
    required this.memberGradientC,
    // ── Alpha overlays ──
    required this.surfaceScrimLight,
    required this.surfaceScrimMedium,
  });

  // ── Backgrounds ──
  final Color background;
  final Color card;
  final Color backgroundMuted;
  final Color backgroundSubtle;
  final Color backgroundDivider;

  /// Alias for [background] — same value.
  Color get backgroundWarm => background;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ── Borders ──
  final Color borderDefault;
  final Color borderDivider;
  final Color borderList;
  final Color borderInputActive;

  // ── Accent primary (Leaf Green) ──
  final Color accentPrimary;
  final Color accentPrimaryLight;
  final Color accentPrimaryBorder;
  final Color fabGradientStart;
  final Color fabGradientEnd;
  final Color actionShadow;

  /// Alias for [fabGradientStart].
  Color get actionGradientStart => fabGradientStart;

  /// Alias for [fabGradientEnd].
  Color get actionGradientEnd => fabGradientEnd;

  // ── Recording ──
  final Color recordingGradientStart;
  final Color recordingGradientEnd;

  // ── Ledger — Daily ──
  final Color daily;

  /// WCAG AA ≥4.5:1 amount text on [card]. Use for monetary values.
  final Color dailyText;
  final Color dailyLight;

  // ── Ledger — Joy ──
  final Color joy;

  /// WCAG AA ≥4.5:1 amount text on [card]. Use for monetary values.
  final Color joyText;
  final Color joyLight;

  // ── Ledger — Shared ──
  final Color shared;

  /// WCAG AA ≥4.5:1 amount text on [card]. Use for monetary values.
  final Color sharedText;
  final Color sharedLight;
  final Color sharedBorder;
  final Color sharedChevron;

  // ── Semantic ──
  final Color success;
  final Color successLight;
  final Color warning;
  final Color error;
  final Color info;

  // ── Error tints ──
  final Color errorSurface;
  final Color errorBorder;
  final Color errorShadow;

  // ── Shadows ──
  final Color fabShadow;
  final Color navShadow;

  // ── Joy card ──
  final Color joyFullnessBg;
  final Color joyFullnessBorder;
  final Color joyRoiBg;
  final Color joyRoiBorder;

  // ── Family ──
  final Color familyBadgeBg;

  // ── Best Joy strip ──
  final Color surfaceCream;
  final Color surfaceCreamBorder;
  final Color textMutedGold;
  final Color satisfactionPillBg;
  final Color satisfactionPillRose;

  // ── Decorative — avatar (brightness-resolved single fields) ──
  final Color avatarGradientStart;
  final Color avatarGradientMid;
  final Color avatarGradientEnd;

  /// Single brightness-resolved avatar border alpha.
  /// light = Color(0x80FFFFFF), dark = Color(0x26FFFFFF).
  final Color avatarBorderAlpha;

  // ── Decorative — member tile ──
  final Color memberGradientA;
  final Color memberGradientB;
  final Color memberGradientC;

  // ── Alpha overlays ──
  final Color surfaceScrimLight;
  final Color surfaceScrimMedium;

  // ── Static instances ──

  /// ADR-019 Light palette — Sakura Mochi × Wakaba.
  static const light = AppPalette(
    // Backgrounds
    background: Color(0xFFFBF7F4),
    card: Color(0xFFFFFFFF),
    backgroundMuted: Color(0xFFF3EDE8),
    backgroundSubtle: Color(0xFFFBF7F4),
    backgroundDivider: Color(0xFFEAE1DC),
    // Text
    textPrimary: Color(0xFF20352B),
    textSecondary: Color(0xFF71877A),
    textTertiary: Color(0xFFA8BCB2),
    // Borders
    borderDefault: Color(0xFFE6DDD8),
    borderDivider: Color(0xFFEAE1DC),
    borderList: Color(0xFFDDD4CE),
    borderInputActive: Color(0xFF6FA36F),
    // Accent primary (leaf-green family)
    accentPrimary: Color(0xFF6FA36F),
    accentPrimaryLight: Color(0xFFEEF6EC),
    accentPrimaryBorder: Color(0xFFCFE6CF),
    fabGradientStart: Color(0xFFE09DB4),
    fabGradientEnd: Color(0xFFD98CA0),
    actionShadow: Color(0x33D98CA0),
    // Recording (error semantic family — red = live/active danger signal)
    recordingGradientStart: Color(0xFFE5484D),
    recordingGradientEnd: Color(0xFFC93040),
    // Ledger — Daily (leaf-green family)
    daily: Color(0xFF5FAE72),
    dailyText: Color(0xFF2E6B3A),
    dailyLight: Color(0xFFEEF6EC),
    // Ledger — Joy (桜餅 Amber — quick soqks, supersedes 丁香 Mauve)
    joy: Color(0xFFC8841A),
    joyText: Color(0xFFA15C00),
    joyLight: Color(0xFFFFF0D6),
    // Ledger — Shared
    shared: Color(0xFF5B8AC4),
    sharedText: Color(0xFF3A6396),
    sharedLight: Color(0xFFE8EFF7),
    sharedBorder: Color(0xFFCBDBEC),
    sharedChevron: Color(0xFFA8C2DD),
    // Semantic
    success: Color(0xFF2FA37A),
    successLight: Color(0xFFE4F4EE),
    warning: Color(0xFFC98A00),
    error: Color(0xFFE5484D),
    info: Color(0xFF2A8FB8),
    // Error tints
    errorSurface: Color(0xFFFEF2F2),
    errorBorder: Color(0xFFFECACA),
    errorShadow: Color(0x15E5484D),
    // Shadows
    fabShadow: Color(0x33D98CA0),
    navShadow: Color(0x08000000),
    // Joy card (amber tints — joyRoi* stays green = success/ROI semantic)
    joyFullnessBg: Color(0xFFFFF0D6),
    joyFullnessBorder: Color(0xFFE8C07A),
    joyRoiBg: Color(0xFFE4F4EE),
    joyRoiBorder: Color(0xFFB8E4D6),
    // Family
    familyBadgeBg: Color(0xFFEEF6EC),
    // Best Joy strip (warm cream surface)
    surfaceCream: Color(0xFFFFFAF6),
    surfaceCreamBorder: Color(0xFFE6DDD8),
    textMutedGold: Color(0xFFA15C00),
    satisfactionPillBg: Color(0xFFFFF0D6),
    satisfactionPillRose: Color(0xFFC8841A),
    // Decorative — avatar (wakaba/leaf-green family, D-04)
    avatarGradientStart: Color(0xFFCFE6CF),
    avatarGradientMid: Color(0xFFE2F0E2),
    avatarGradientEnd: Color(0xFFF0F7F0),
    // Single brightness-resolved alpha border
    avatarBorderAlpha: Color(0x80FFFFFF),
    // Decorative — member tile (leaf-green family, D-04)
    memberGradientA: Color(0xFFCFE6CF),
    memberGradientB: Color(0xFFE2F0E2),
    memberGradientC: Color(0xFFF0F7F0),
    // Alpha overlays
    surfaceScrimLight: Color(0x14000000),
    surfaceScrimMedium: Color(0x0A000000),
  );

  /// ADR-019 Dark palette — Sakura Mochi × Wakaba.
  static const dark = AppPalette(
    // Backgrounds (warm-dark)
    background: Color(0xFF171210),
    card: Color(0xFF231E1B),
    backgroundMuted: Color(0xFF2E2723),
    backgroundSubtle: Color(0xFF1E1916),
    backgroundDivider: Color(0xFF2E2723),
    // Text
    textPrimary: Color(0xFFF0EBE6),
    textSecondary: Color(0xFF9A8E87),
    textTertiary: Color(0xFF6B5F58),
    // Borders
    borderDefault: Color(0xFF2E2723),
    borderDivider: Color(0xFF2E2723),
    borderList: Color(0xFF2E2723),
    borderInputActive: Color(0xFF8DC68D),
    // Accent primary (bright leaf green on dark)
    accentPrimary: Color(0xFF8DC68D),
    accentPrimaryLight: Color(0xFF1A2E1A),
    accentPrimaryBorder: Color(0xFF283E28),
    fabGradientStart: Color(0xFFEDB8CA),
    fabGradientEnd: Color(0xFFE09DB4),
    actionShadow: Color(0x33E09DB4),
    // Recording (error semantic family — dark variant)
    recordingGradientStart: Color(0xFFF0676B),
    recordingGradientEnd: Color(0xFFD44050),
    // Ledger — Daily (bright leaf on dark)
    daily: Color(0xFF7DC88D),
    dailyText: Color(0xFF7DC88D),
    dailyLight: Color(0xFF1A2E1A),
    // Ledger — Joy (bright amber on dark — supersedes 丁香 Mauve dark)
    joy: Color(0xFFE0A040),
    joyText: Color(0xFFE0A040),
    joyLight: Color(0xFF2E2010),
    // Ledger — Shared
    shared: Color(0xFF7FA8D8),
    sharedText: Color(0xFF7FA8D8),
    sharedLight: Color(0xFF1E2A3A),
    sharedBorder: Color(0xFF2A3D55),
    sharedChevron: Color(0xFF4A6E8A),
    // Semantic
    success: Color(0xFF3FC78E),
    successLight: Color(0xFF1E3329),
    warning: Color(0xFFE5B53A),
    error: Color(0xFFF0676B),
    info: Color(0xFF5AA8E0),
    // Error tints
    errorSurface: Color(0xFF2D1515),
    errorBorder: Color(0xFF4D2020),
    errorShadow: Color(0x15F0676B),
    // Shadows
    fabShadow: Color(0x33E09DB4),
    navShadow: Color(0x20000000),
    // Joy card (amber dark tints — joyRoi* stays green = success/ROI semantic)
    joyFullnessBg: Color(0xFF2E2010),
    joyFullnessBorder: Color(0xFF4A3818),
    joyRoiBg: Color(0xFF173330),
    joyRoiBorder: Color(0xFF2D4D45),
    // Family
    familyBadgeBg: Color(0xFF1A2E1A),
    // Best Joy strip (warm-dark surface)
    surfaceCream: Color(0xFF1A1512),
    surfaceCreamBorder: Color(0xFF2E2723),
    textMutedGold: Color(0xFFC89050),
    satisfactionPillBg: Color(0xFF2E2010),
    satisfactionPillRose: Color(0xFFE0A040),
    // Decorative — avatar (leaf-green dark family, D-04)
    avatarGradientStart: Color(0xFF1F3020),
    avatarGradientMid: Color(0xFF1A2A1B),
    avatarGradientEnd: Color(0xFF162416),
    // Single brightness-resolved alpha border
    avatarBorderAlpha: Color(0x26FFFFFF),
    // Decorative — member tile (leaf-green dark family, D-04)
    memberGradientA: Color(0xFF1F3020),
    memberGradientB: Color(0xFF1A2A1B),
    memberGradientC: Color(0xFF162416),
    // Alpha overlays
    surfaceScrimLight: Color(0x14000000),
    surfaceScrimMedium: Color(0x0A000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? backgroundMuted,
    Color? backgroundSubtle,
    Color? backgroundDivider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? borderDefault,
    Color? borderDivider,
    Color? borderList,
    Color? borderInputActive,
    Color? accentPrimary,
    Color? accentPrimaryLight,
    Color? accentPrimaryBorder,
    Color? fabGradientStart,
    Color? fabGradientEnd,
    Color? actionShadow,
    Color? recordingGradientStart,
    Color? recordingGradientEnd,
    Color? daily,
    Color? dailyText,
    Color? dailyLight,
    Color? joy,
    Color? joyText,
    Color? joyLight,
    Color? shared,
    Color? sharedText,
    Color? sharedLight,
    Color? sharedBorder,
    Color? sharedChevron,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? error,
    Color? info,
    Color? errorSurface,
    Color? errorBorder,
    Color? errorShadow,
    Color? fabShadow,
    Color? navShadow,
    Color? joyFullnessBg,
    Color? joyFullnessBorder,
    Color? joyRoiBg,
    Color? joyRoiBorder,
    Color? familyBadgeBg,
    Color? surfaceCream,
    Color? surfaceCreamBorder,
    Color? textMutedGold,
    Color? satisfactionPillBg,
    Color? satisfactionPillRose,
    Color? avatarGradientStart,
    Color? avatarGradientMid,
    Color? avatarGradientEnd,
    Color? avatarBorderAlpha,
    Color? memberGradientA,
    Color? memberGradientB,
    Color? memberGradientC,
    Color? surfaceScrimLight,
    Color? surfaceScrimMedium,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      backgroundMuted: backgroundMuted ?? this.backgroundMuted,
      backgroundSubtle: backgroundSubtle ?? this.backgroundSubtle,
      backgroundDivider: backgroundDivider ?? this.backgroundDivider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      borderDefault: borderDefault ?? this.borderDefault,
      borderDivider: borderDivider ?? this.borderDivider,
      borderList: borderList ?? this.borderList,
      borderInputActive: borderInputActive ?? this.borderInputActive,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentPrimaryLight: accentPrimaryLight ?? this.accentPrimaryLight,
      accentPrimaryBorder: accentPrimaryBorder ?? this.accentPrimaryBorder,
      fabGradientStart: fabGradientStart ?? this.fabGradientStart,
      fabGradientEnd: fabGradientEnd ?? this.fabGradientEnd,
      actionShadow: actionShadow ?? this.actionShadow,
      recordingGradientStart:
          recordingGradientStart ?? this.recordingGradientStart,
      recordingGradientEnd: recordingGradientEnd ?? this.recordingGradientEnd,
      daily: daily ?? this.daily,
      dailyText: dailyText ?? this.dailyText,
      dailyLight: dailyLight ?? this.dailyLight,
      joy: joy ?? this.joy,
      joyText: joyText ?? this.joyText,
      joyLight: joyLight ?? this.joyLight,
      shared: shared ?? this.shared,
      sharedText: sharedText ?? this.sharedText,
      sharedLight: sharedLight ?? this.sharedLight,
      sharedBorder: sharedBorder ?? this.sharedBorder,
      sharedChevron: sharedChevron ?? this.sharedChevron,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      errorSurface: errorSurface ?? this.errorSurface,
      errorBorder: errorBorder ?? this.errorBorder,
      errorShadow: errorShadow ?? this.errorShadow,
      fabShadow: fabShadow ?? this.fabShadow,
      navShadow: navShadow ?? this.navShadow,
      joyFullnessBg: joyFullnessBg ?? this.joyFullnessBg,
      joyFullnessBorder: joyFullnessBorder ?? this.joyFullnessBorder,
      joyRoiBg: joyRoiBg ?? this.joyRoiBg,
      joyRoiBorder: joyRoiBorder ?? this.joyRoiBorder,
      familyBadgeBg: familyBadgeBg ?? this.familyBadgeBg,
      surfaceCream: surfaceCream ?? this.surfaceCream,
      surfaceCreamBorder: surfaceCreamBorder ?? this.surfaceCreamBorder,
      textMutedGold: textMutedGold ?? this.textMutedGold,
      satisfactionPillBg: satisfactionPillBg ?? this.satisfactionPillBg,
      satisfactionPillRose: satisfactionPillRose ?? this.satisfactionPillRose,
      avatarGradientStart: avatarGradientStart ?? this.avatarGradientStart,
      avatarGradientMid: avatarGradientMid ?? this.avatarGradientMid,
      avatarGradientEnd: avatarGradientEnd ?? this.avatarGradientEnd,
      avatarBorderAlpha: avatarBorderAlpha ?? this.avatarBorderAlpha,
      memberGradientA: memberGradientA ?? this.memberGradientA,
      memberGradientB: memberGradientB ?? this.memberGradientB,
      memberGradientC: memberGradientC ?? this.memberGradientC,
      surfaceScrimLight: surfaceScrimLight ?? this.surfaceScrimLight,
      surfaceScrimMedium: surfaceScrimMedium ?? this.surfaceScrimMedium,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      backgroundMuted: Color.lerp(backgroundMuted, other.backgroundMuted, t)!,
      backgroundSubtle:
          Color.lerp(backgroundSubtle, other.backgroundSubtle, t)!,
      backgroundDivider:
          Color.lerp(backgroundDivider, other.backgroundDivider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderDivider: Color.lerp(borderDivider, other.borderDivider, t)!,
      borderList: Color.lerp(borderList, other.borderList, t)!,
      borderInputActive:
          Color.lerp(borderInputActive, other.borderInputActive, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentPrimaryLight:
          Color.lerp(accentPrimaryLight, other.accentPrimaryLight, t)!,
      accentPrimaryBorder:
          Color.lerp(accentPrimaryBorder, other.accentPrimaryBorder, t)!,
      fabGradientStart:
          Color.lerp(fabGradientStart, other.fabGradientStart, t)!,
      fabGradientEnd: Color.lerp(fabGradientEnd, other.fabGradientEnd, t)!,
      actionShadow: Color.lerp(actionShadow, other.actionShadow, t)!,
      recordingGradientStart: Color.lerp(
        recordingGradientStart,
        other.recordingGradientStart,
        t,
      )!,
      recordingGradientEnd: Color.lerp(
        recordingGradientEnd,
        other.recordingGradientEnd,
        t,
      )!,
      daily: Color.lerp(daily, other.daily, t)!,
      dailyText: Color.lerp(dailyText, other.dailyText, t)!,
      dailyLight: Color.lerp(dailyLight, other.dailyLight, t)!,
      joy: Color.lerp(joy, other.joy, t)!,
      joyText: Color.lerp(joyText, other.joyText, t)!,
      joyLight: Color.lerp(joyLight, other.joyLight, t)!,
      shared: Color.lerp(shared, other.shared, t)!,
      sharedText: Color.lerp(sharedText, other.sharedText, t)!,
      sharedLight: Color.lerp(sharedLight, other.sharedLight, t)!,
      sharedBorder: Color.lerp(sharedBorder, other.sharedBorder, t)!,
      sharedChevron: Color.lerp(sharedChevron, other.sharedChevron, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      errorShadow: Color.lerp(errorShadow, other.errorShadow, t)!,
      fabShadow: Color.lerp(fabShadow, other.fabShadow, t)!,
      navShadow: Color.lerp(navShadow, other.navShadow, t)!,
      joyFullnessBg: Color.lerp(joyFullnessBg, other.joyFullnessBg, t)!,
      joyFullnessBorder:
          Color.lerp(joyFullnessBorder, other.joyFullnessBorder, t)!,
      joyRoiBg: Color.lerp(joyRoiBg, other.joyRoiBg, t)!,
      joyRoiBorder: Color.lerp(joyRoiBorder, other.joyRoiBorder, t)!,
      familyBadgeBg: Color.lerp(familyBadgeBg, other.familyBadgeBg, t)!,
      surfaceCream: Color.lerp(surfaceCream, other.surfaceCream, t)!,
      surfaceCreamBorder:
          Color.lerp(surfaceCreamBorder, other.surfaceCreamBorder, t)!,
      textMutedGold: Color.lerp(textMutedGold, other.textMutedGold, t)!,
      satisfactionPillBg:
          Color.lerp(satisfactionPillBg, other.satisfactionPillBg, t)!,
      satisfactionPillRose:
          Color.lerp(satisfactionPillRose, other.satisfactionPillRose, t)!,
      avatarGradientStart:
          Color.lerp(avatarGradientStart, other.avatarGradientStart, t)!,
      avatarGradientMid:
          Color.lerp(avatarGradientMid, other.avatarGradientMid, t)!,
      avatarGradientEnd:
          Color.lerp(avatarGradientEnd, other.avatarGradientEnd, t)!,
      avatarBorderAlpha:
          Color.lerp(avatarBorderAlpha, other.avatarBorderAlpha, t)!,
      memberGradientA:
          Color.lerp(memberGradientA, other.memberGradientA, t)!,
      memberGradientB:
          Color.lerp(memberGradientB, other.memberGradientB, t)!,
      memberGradientC:
          Color.lerp(memberGradientC, other.memberGradientC, t)!,
      surfaceScrimLight:
          Color.lerp(surfaceScrimLight, other.surfaceScrimLight, t)!,
      surfaceScrimMedium:
          Color.lerp(surfaceScrimMedium, other.surfaceScrimMedium, t)!,
    );
  }
}

/// Ergonomic BuildContext accessor — replaces all [context.wm*] getter patterns.
///
/// Usage: `context.palette.card` (replaces `context.wmCard`)
extension AppPaletteContext on BuildContext {
  /// Resolves the [AppPalette] ThemeExtension. [AppTheme] always registers it
  /// in production; the brightness-aware fallback keeps widgets renderable
  /// under any theme that omits the extension (e.g. lightweight test harnesses)
  /// instead of throwing on a null extension.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
