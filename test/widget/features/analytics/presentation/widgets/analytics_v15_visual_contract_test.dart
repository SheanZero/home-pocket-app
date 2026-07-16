import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/analytics_category_palette.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_section_header.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_segmented_control.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/analytics_data_card.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Center(child: SizedBox(width: 350, child: child)),
  ),
);

void main() {
  testWidgets(
    'A1 analytics cards use the V15 radius, padding and light shadow',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsDataCard(
            title: 'Title',
            caption: 'Caption',
            showHeader: false,
            child: SizedBox(height: 20),
          ),
        ),
      );

      final shell = tester.widget<Container>(
        find.byKey(const ValueKey('analytics_data_card')),
      );
      final decoration = shell.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.boxShadow, isNotEmpty);

      final padding = tester.widget<Padding>(
        find.byKey(const ValueKey('analytics_data_card_padding')),
      );
      expect(padding.padding, const EdgeInsets.all(14));
    },
  );

  testWidgets('A2 section title uses the readable semantic section style', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AnalyticsSectionHeader(
          title: 'Category spend',
          tone: SectionTone.practical,
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Category spend'));
    expect(title.style?.fontSize, AppTypography.sectionTitle);
    expect(title.style?.fontWeight, AppTypography.sectionTitleWeight);
  });

  testWidgets('A3 analytics segment uses the semantic label size and height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AnalyticsSegmentedControl<String>(
          selected: 'total',
          segments: const [
            AnalyticsSegment(value: 'total', label: 'Total'),
            AnalyticsSegment(value: 'joy', label: 'Joy'),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AnalyticsSegmentedControl<String>)).height,
      AnalyticsSegmentedControl.controlHeight,
    );
    expect(
      tester.widget<Text>(find.text('Total')).style?.fontSize,
      AppTypography.label,
    );
  });

  test('A5 category sequence starts with the V15 green and blue', () {
    expect(AnalyticsCategoryPalette.survivalSequence.take(3), const [
      Color(0xFF69A873),
      Color(0xFF5F8DCA),
      Color(0xFF86C994),
    ]);
    expect(AnalyticsCategoryPalette.joy, AppPalette.light.joy);
  });
}
