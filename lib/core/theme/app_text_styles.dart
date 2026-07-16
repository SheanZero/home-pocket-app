import 'package:flutter/material.dart';

/// Global typography geometry for Home Pocket.
///
/// The short semantic names are font sizes in logical pixels. Each has a
/// matching `*LineHeight` value so Flutter styles and the V15 mockup can share
/// the same physical line box. Font weights are limited to the native-friendly
/// 400–700 range used by the Japanese platform font stack.
abstract final class AppTypography {
  static const double pageTitle = 20;
  static const double pageTitleLineHeight = 28;
  static const FontWeight pageTitleWeight = FontWeight.w700;

  static const double sectionTitle = 16;
  static const double sectionTitleLineHeight = 22;
  static const FontWeight sectionTitleWeight = FontWeight.w700;

  static const double itemTitle = 15;
  static const double itemTitleLineHeight = 21;
  static const FontWeight itemTitleWeight = FontWeight.w600;

  static const double body = 14;
  static const double bodyLineHeight = 21;
  static const FontWeight bodyWeight = FontWeight.w500;

  static const double label = 13;
  static const double labelLineHeight = 18;
  static const FontWeight labelWeight = FontWeight.w600;

  static const double supporting = 12;
  static const double supportingLineHeight = 17;
  static const FontWeight supportingWeight = FontWeight.w500;

  /// Minimum size for semantic content such as compact controls and chart axes.
  static const double compact = 11;
  static const double compactLineHeight = 15;
  static const FontWeight compactWeight = FontWeight.w600;

  static const double navigation = 11;
  static const double navigationLineHeight = 14;
  static const FontWeight navigationWeight = FontWeight.w600;

  static const double button = 14;
  static const double buttonLineHeight = 20;
  static const FontWeight buttonWeight = FontWeight.w700;

  static const double amountHero = 34;
  static const double amountHeroLineHeight = 38;
  static const FontWeight amountHeroWeight = FontWeight.w700;

  static const double amountLarge = 24;
  static const double amountLargeLineHeight = 30;
  static const FontWeight amountLargeWeight = FontWeight.w700;

  static const double amountMedium = 18;
  static const double amountMediumLineHeight = 24;
  static const FontWeight amountMediumWeight = FontWeight.w700;

  static const double amountSmall = 15;
  static const double amountSmallLineHeight = 20;
  static const FontWeight amountSmallWeight = FontWeight.w700;

  /// Compatibility only; do not use for essential content on new surfaces.
  static const double micro = 10;
  static const double microLineHeight = 14;
  static const FontWeight microWeight = FontWeight.w600;
}

/// Color-neutral, platform-font text styles for Home Pocket.
///
/// Font families are intentionally omitted. Flutter resolves the native UI
/// stack (San Francisco/Hiragino on iOS, Roboto/Noto on Android). New UI should
/// use the semantic names at the top of this class; the Material-style names
/// below remain compatibility aliases while existing screens migrate.
abstract final class AppTextStyles {
  static const _tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  // ── Semantic styles ──

  static const pageTitle = TextStyle(
    fontSize: AppTypography.pageTitle,
    height: AppTypography.pageTitleLineHeight / AppTypography.pageTitle,
    fontWeight: AppTypography.pageTitleWeight,
  );

  static const sectionTitle = TextStyle(
    fontSize: AppTypography.sectionTitle,
    height: AppTypography.sectionTitleLineHeight / AppTypography.sectionTitle,
    fontWeight: AppTypography.sectionTitleWeight,
  );

  static const itemTitle = TextStyle(
    fontSize: AppTypography.itemTitle,
    height: AppTypography.itemTitleLineHeight / AppTypography.itemTitle,
    fontWeight: AppTypography.itemTitleWeight,
  );

  static const body = TextStyle(
    fontSize: AppTypography.body,
    height: AppTypography.bodyLineHeight / AppTypography.body,
    fontWeight: AppTypography.bodyWeight,
  );

  static const label = TextStyle(
    fontSize: AppTypography.label,
    height: AppTypography.labelLineHeight / AppTypography.label,
    fontWeight: AppTypography.labelWeight,
  );

  static const supporting = TextStyle(
    fontSize: AppTypography.supporting,
    height: AppTypography.supportingLineHeight / AppTypography.supporting,
    fontWeight: AppTypography.supportingWeight,
  );

  static const compact = TextStyle(
    fontSize: AppTypography.compact,
    height: AppTypography.compactLineHeight / AppTypography.compact,
    fontWeight: AppTypography.compactWeight,
  );

  static const navigation = TextStyle(
    fontSize: AppTypography.navigation,
    height: AppTypography.navigationLineHeight / AppTypography.navigation,
    fontWeight: AppTypography.navigationWeight,
  );

  static const button = TextStyle(
    fontSize: AppTypography.button,
    height: AppTypography.buttonLineHeight / AppTypography.button,
    fontWeight: AppTypography.buttonWeight,
  );

  static const amountHero = TextStyle(
    fontSize: AppTypography.amountHero,
    height: AppTypography.amountHeroLineHeight / AppTypography.amountHero,
    fontWeight: AppTypography.amountHeroWeight,
    fontFeatures: _tabularFigures,
  );

  static const amountLarge = TextStyle(
    fontSize: AppTypography.amountLarge,
    height: AppTypography.amountLargeLineHeight / AppTypography.amountLarge,
    fontWeight: AppTypography.amountLargeWeight,
    fontFeatures: _tabularFigures,
  );

  static const amountMedium = TextStyle(
    fontSize: AppTypography.amountMedium,
    height: AppTypography.amountMediumLineHeight / AppTypography.amountMedium,
    fontWeight: AppTypography.amountMediumWeight,
    fontFeatures: _tabularFigures,
  );

  static const amountSmall = TextStyle(
    fontSize: AppTypography.amountSmall,
    height: AppTypography.amountSmallLineHeight / AppTypography.amountSmall,
    fontWeight: AppTypography.amountSmallWeight,
    fontFeatures: _tabularFigures,
  );

  // ── Compatibility aliases ──

  static const headlineLarge = pageTitle;
  static const headlineMedium = pageTitle;
  static const headlineSmall = pageTitle;

  static const titleLarge = sectionTitle;
  static const titleMedium = itemTitle;
  static const titleSmall = itemTitle;

  static const bodyLarge = itemTitle;
  static const bodyMedium = body;
  static const bodySmall = label;

  static const caption = supporting;
  static const overline = compact;
  static const micro = TextStyle(
    fontSize: AppTypography.micro,
    height: AppTypography.microLineHeight / AppTypography.micro,
    fontWeight: AppTypography.microWeight,
  );

  static const dividerLabel = TextStyle(
    fontSize: AppTypography.label,
    height: AppTypography.labelLineHeight / AppTypography.label,
    fontWeight: AppTypography.labelWeight,
    letterSpacing: 2,
  );

  static const labelMedium = label;
  static const labelSmall = compact;

  static const navLabel = navigation;
  static const navLabelActive = navigation;
  static const tabLabel = navigation;

  static const comparisonDelta = TextStyle(
    fontSize: AppTypography.supporting,
    height: AppTypography.supportingLineHeight / AppTypography.supporting,
    fontWeight: FontWeight.w700,
  );

  static const legendLabel = TextStyle(
    fontSize: AppTypography.compact,
    height: AppTypography.compactLineHeight / AppTypography.compact,
    fontWeight: FontWeight.w500,
  );

  /// Builds a Material text theme for a concrete light or dark palette.
  ///
  /// Typography tokens stay color-neutral. Primary and secondary colors are
  /// injected here so direct TextTheme lookups cannot carry light-theme colors
  /// into dark mode.
  static TextTheme buildTextTheme({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    TextStyle primary(TextStyle style) => style.copyWith(color: textPrimary);
    TextStyle secondary(TextStyle style) =>
        style.copyWith(color: textSecondary);

    return TextTheme(
      displayLarge: primary(amountHero),
      displayMedium: primary(amountLarge),
      displaySmall: primary(amountMedium),
      headlineLarge: primary(pageTitle),
      headlineMedium: primary(pageTitle),
      headlineSmall: primary(sectionTitle),
      titleLarge: primary(sectionTitle),
      titleMedium: primary(itemTitle),
      titleSmall: primary(itemTitle),
      bodyLarge: primary(body),
      bodyMedium: primary(body),
      bodySmall: secondary(supporting),
      labelLarge: primary(button),
      labelMedium: secondary(label),
      labelSmall: secondary(compact),
    );
  }
}
