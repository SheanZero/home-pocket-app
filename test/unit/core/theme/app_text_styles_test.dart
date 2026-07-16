import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';

void main() {
  void expectGeometry(
    TextStyle style, {
    required double size,
    required double lineHeight,
    required FontWeight weight,
  }) {
    expect(style.fontSize, size);
    expect(style.fontSize! * style.height!, closeTo(lineHeight, 0.000001));
    expect(style.fontWeight, weight);
  }

  group('AppTypography', () {
    test('defines the global semantic font-size scale', () {
      expect(
        [
          AppTypography.pageTitle,
          AppTypography.sectionTitle,
          AppTypography.itemTitle,
          AppTypography.body,
          AppTypography.label,
          AppTypography.supporting,
          AppTypography.compact,
          AppTypography.navigation,
          AppTypography.button,
          AppTypography.amountHero,
          AppTypography.amountLarge,
          AppTypography.amountMedium,
          AppTypography.amountSmall,
          AppTypography.micro,
        ],
        [20, 16, 15, 14, 13, 12, 11, 11, 14, 34, 24, 18, 15, 10],
      );
    });

    test('defines the matching physical line-height scale', () {
      expect(
        [
          AppTypography.pageTitleLineHeight,
          AppTypography.sectionTitleLineHeight,
          AppTypography.itemTitleLineHeight,
          AppTypography.bodyLineHeight,
          AppTypography.labelLineHeight,
          AppTypography.supportingLineHeight,
          AppTypography.compactLineHeight,
          AppTypography.navigationLineHeight,
          AppTypography.buttonLineHeight,
          AppTypography.amountHeroLineHeight,
          AppTypography.amountLargeLineHeight,
          AppTypography.amountMediumLineHeight,
          AppTypography.amountSmallLineHeight,
          AppTypography.microLineHeight,
        ],
        [28, 22, 21, 21, 18, 17, 15, 14, 20, 38, 30, 24, 20, 14],
      );
    });
  });

  group('AppTextStyles semantic styles', () {
    test('use the platform Japanese font stack', () {
      for (final style in [
        AppTextStyles.pageTitle,
        AppTextStyles.body,
        AppTextStyles.navigation,
        AppTextStyles.amountHero,
      ]) {
        expect(style.fontFamily, isNull);
        expect(style.fontFamilyFallback, isNull);
      }
    });

    test('map content roles to size, line height and weight', () {
      expectGeometry(
        AppTextStyles.pageTitle,
        size: AppTypography.pageTitle,
        lineHeight: AppTypography.pageTitleLineHeight,
        weight: FontWeight.w700,
      );
      expectGeometry(
        AppTextStyles.sectionTitle,
        size: AppTypography.sectionTitle,
        lineHeight: AppTypography.sectionTitleLineHeight,
        weight: FontWeight.w700,
      );
      expectGeometry(
        AppTextStyles.itemTitle,
        size: AppTypography.itemTitle,
        lineHeight: AppTypography.itemTitleLineHeight,
        weight: FontWeight.w600,
      );
      expectGeometry(
        AppTextStyles.body,
        size: AppTypography.body,
        lineHeight: AppTypography.bodyLineHeight,
        weight: FontWeight.w500,
      );
      expectGeometry(
        AppTextStyles.label,
        size: AppTypography.label,
        lineHeight: AppTypography.labelLineHeight,
        weight: FontWeight.w600,
      );
      expectGeometry(
        AppTextStyles.supporting,
        size: AppTypography.supporting,
        lineHeight: AppTypography.supportingLineHeight,
        weight: FontWeight.w500,
      );
      expectGeometry(
        AppTextStyles.compact,
        size: AppTypography.compact,
        lineHeight: AppTypography.compactLineHeight,
        weight: FontWeight.w600,
      );
      expectGeometry(
        AppTextStyles.navigation,
        size: AppTypography.navigation,
        lineHeight: AppTypography.navigationLineHeight,
        weight: FontWeight.w600,
      );
      expectGeometry(
        AppTextStyles.button,
        size: AppTypography.button,
        lineHeight: AppTypography.buttonLineHeight,
        weight: FontWeight.w700,
      );
    });

    test('define the complete tabular amount scale', () {
      final amountCases = [
        (
          AppTextStyles.amountHero,
          AppTypography.amountHero,
          AppTypography.amountHeroLineHeight,
        ),
        (
          AppTextStyles.amountLarge,
          AppTypography.amountLarge,
          AppTypography.amountLargeLineHeight,
        ),
        (
          AppTextStyles.amountMedium,
          AppTypography.amountMedium,
          AppTypography.amountMediumLineHeight,
        ),
        (
          AppTextStyles.amountSmall,
          AppTypography.amountSmall,
          AppTypography.amountSmallLineHeight,
        ),
      ];

      for (final (style, size, lineHeight) in amountCases) {
        expectGeometry(
          style,
          size: size,
          lineHeight: lineHeight,
          weight: FontWeight.w700,
        );
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });

    test('keep micro as a 10px compatibility style', () {
      expectGeometry(
        AppTextStyles.micro,
        size: AppTypography.micro,
        lineHeight: AppTypography.microLineHeight,
        weight: FontWeight.w600,
      );
    });
  });

  group('AppTextStyles compatibility aliases', () {
    test('map legacy roles to the closest semantic style', () {
      expect(AppTextStyles.headlineLarge, AppTextStyles.pageTitle);
      expect(AppTextStyles.headlineSmall, AppTextStyles.pageTitle);
      expect(AppTextStyles.titleLarge, AppTextStyles.sectionTitle);
      expect(AppTextStyles.titleMedium, AppTextStyles.itemTitle);
      expect(AppTextStyles.bodyMedium, AppTextStyles.body);
      expect(AppTextStyles.caption, AppTextStyles.supporting);
      expect(AppTextStyles.labelMedium, AppTextStyles.label);
      expect(AppTextStyles.labelSmall, AppTextStyles.compact);
    });

    test('nav aliases use the 11px navigation token', () {
      expect(AppTextStyles.navLabel, AppTextStyles.navigation);
      expect(AppTextStyles.navLabelActive, AppTextStyles.navigation);
      expect(AppTextStyles.navLabel.fontSize, 11);
      expect(
        AppTextStyles.navLabel.fontSize! * AppTextStyles.navLabel.height!,
        closeTo(14, 0.000001),
      );
    });
  });
}
