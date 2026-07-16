import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';

/// Keeps the four primary surfaces on the shared semantic typography scale.
///
/// Numeric `fontSize` declarations make device readability drift page by page.
/// Main-surface content should instead use `AppTextStyles`/`AppTypography`, so a
/// later global adjustment remains a one-file change. Emoji glyph sizing is a
/// visual asset concern and is intentionally exempt.
void main() {
  test('primary surfaces contain no numeric content font sizes', () {
    final hits = <String>[];
    final numericFontSize = RegExp(r'fontSize:\s*\d');

    for (final path in _primarySurfaceFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing contract file: $path');

      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (!numericFontSize.hasMatch(line) || _isEmojiSizing(line)) continue;
        hits.add('$path:${index + 1}: ${line.trim()}');
      }
    }

    expect(
      hits,
      isEmpty,
      reason:
          'Main-surface text must use AppTextStyles/AppTypography tokens:\n'
          '${hits.join("\n")}',
    );
  });

  test('canonical V16 HTML mockup mirrors the Flutter typography scale', () {
    for (final path in _mockupFiles) {
      final source = File(path).readAsStringSync();
      final missing = <String>[];

      for (final entry in _mockupTokens.entries) {
        final value = _cssNumber(entry.value);
        final declaration =
            '--${entry.key}: $value'
            'px;';
        if (!source.contains(declaration)) missing.add(declaration);
      }

      expect(
        missing,
        isEmpty,
        reason:
            '$path must mirror AppTypography exactly. Missing:\n'
            '${missing.join("\n")}',
      );
    }
  });

  test('canonical V16 mockup keeps the shared header and shopping filters', () {
    final source = File(_mockupFiles.single).readAsStringSync();
    const requiredFragments = <String>[
      '.app-header { min-height: 46px;',
      'font-size: var(--type-page-title);',
      'line-height: var(--line-page-title);',
      'font-weight: 700;',
      '.list-header-actions .icon-btn { width: 40px; height: 40px; }',
      '.list-header-actions .material-symbols-rounded { font-size: 24px; }',
      'data-action="shopping-private"',
      'data-action="shopping-category"',
      'function shoppingCategoryPicker()',
      "tabHeader('買い物リスト',settings)",
    ];

    for (final fragment in requiredFragments) {
      expect(
        source,
        contains(fragment),
        reason: '${_mockupFiles.single} is missing the V16 contract: $fragment',
      );
    }
  });
}

String _cssNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

bool _isEmojiSizing(String line) =>
    line.contains('leadingEmoji!') || line.contains('Text(emoji!');

const _primarySurfaceFiles = <String>[
  'lib/features/home/presentation/screens/home_screen.dart',
  'lib/features/home/presentation/widgets/hero_header.dart',
  'lib/features/home/presentation/widgets/home_hero_card.dart',
  'lib/features/home/presentation/widgets/home_metrics_region.dart',
  'lib/features/home/presentation/widgets/family_invite_banner.dart',
  'lib/features/home/presentation/widgets/home_transaction_tile.dart',
  'lib/features/home/presentation/widgets/home_bottom_nav_bar.dart',
  'lib/features/list/presentation/screens/list_screen.dart',
  'lib/features/list/presentation/widgets/list_calendar_header.dart',
  'lib/features/list/presentation/widgets/list_day_group_header.dart',
  'lib/features/list/presentation/widgets/list_ledger_segments.dart',
  'lib/features/list/presentation/widgets/list_sort_filter_bar.dart',
  'lib/features/list/presentation/widgets/list_transaction_tile.dart',
  'lib/features/analytics/presentation/widgets/analytics_section_header.dart',
  'lib/features/analytics/presentation/widgets/analytics_segmented_control.dart',
  'lib/features/analytics/presentation/widgets/cards/analytics_data_card.dart',
  'lib/features/analytics/presentation/widgets/cards/category_donut_card.dart',
  'lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart',
  'lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart',
  'lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart',
  'lib/features/analytics/presentation/widgets/donut_hero.dart',
  'lib/features/analytics/presentation/widgets/family_insight_card.dart',
  'lib/features/analytics/presentation/widgets/joy_calendar_heatmap.dart',
  'lib/features/analytics/presentation/widgets/joy_spend_drawer.dart',
  'lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart',
  'lib/features/analytics/presentation/widgets/satisfaction_distribution_histogram.dart',
  'lib/features/analytics/presentation/widgets/within_month_cumulative_line_chart.dart',
  'lib/features/shopping_list/presentation/screens/shopping_list_screen.dart',
  'lib/features/shopping_list/presentation/widgets/shopping_segmented_control.dart',
  'lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart',
  'lib/features/shopping_list/presentation/widgets/shopping_item_tile.dart',
];

const _mockupFiles = <String>['docs/mockup/v16/index.html'];

const _mockupTokens = <String, double>{
  'type-page-title': AppTypography.pageTitle,
  'line-page-title': AppTypography.pageTitleLineHeight,
  'type-section': AppTypography.sectionTitle,
  'line-section': AppTypography.sectionTitleLineHeight,
  'type-item': AppTypography.itemTitle,
  'line-item': AppTypography.itemTitleLineHeight,
  'type-body': AppTypography.body,
  'line-body': AppTypography.bodyLineHeight,
  'type-label': AppTypography.label,
  'line-label': AppTypography.labelLineHeight,
  'type-supporting': AppTypography.supporting,
  'line-supporting': AppTypography.supportingLineHeight,
  'type-compact': AppTypography.compact,
  'line-compact': AppTypography.compactLineHeight,
  'type-navigation': AppTypography.navigation,
  'line-navigation': AppTypography.navigationLineHeight,
  'type-button': AppTypography.button,
  'line-button': AppTypography.buttonLineHeight,
  'type-amount-hero': AppTypography.amountHero,
  'line-amount-hero': AppTypography.amountHeroLineHeight,
  'type-amount-large': AppTypography.amountLarge,
  'line-amount-large': AppTypography.amountLargeLineHeight,
  'type-amount-medium': AppTypography.amountMedium,
  'line-amount-medium': AppTypography.amountMediumLineHeight,
  'type-amount-small': AppTypography.amountSmall,
  'line-amount-small': AppTypography.amountSmallLineHeight,
  'type-micro': AppTypography.micro,
  'line-micro': AppTypography.microLineHeight,
};
