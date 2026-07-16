import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_segmented_control.dart'
    as analytics;
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_segmented_control.dart'
    as shopping;

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );

  BoxDecoration decorationOf(Container container) =>
      container.decoration! as BoxDecoration;

  testWidgets('analytics segmented control matches V15 shared state', (
    tester,
  ) async {
    const controlKey = Key('analytics-control');
    await tester.pumpWidget(
      host(
        analytics.AnalyticsSegmentedControl<String>(
          key: controlKey,
          selected: 'member',
          segments: const [
            analytics.AnalyticsSegment(value: 'category', label: 'Category'),
            analytics.AnalyticsSegment(
              value: 'member',
              label: 'Member',
              tone: analytics.SegmentTone.shared,
            ),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    final containers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(controlKey),
            matching: find.byType(Container),
          ),
        )
        .toList();
    final palette = AppPalette.light;
    final track = decorationOf(containers.first);
    expect(
      track.color,
      Color.alphaBlend(
        palette.backgroundMuted.withValues(alpha: 0.54),
        palette.card,
      ),
    );
    expect(track.boxShadow, isNotEmpty);

    expect(
      tester.widget<Text>(find.text('Category')).style?.color,
      palette.textPrimary,
    );

    final selected = containers
        .map(decorationOf)
        .singleWhere(
          (decoration) =>
              decoration.color != Colors.transparent &&
              decoration.color != track.color,
        );
    expect(selected.color, Color.lerp(palette.joy, palette.shared, 0.58));
    expect(selected.boxShadow, isNotEmpty);
  });

  testWidgets('shopping segmented control uses V15 track and active shadow', (
    tester,
  ) async {
    const controlKey = Key('shopping-control');
    await tester.pumpWidget(
      host(
        shopping.ShoppingSegmentedControl<String>(
          key: controlKey,
          selected: 'all',
          segments: const [
            shopping.ShoppingSegment(value: 'all', label: 'All'),
            shopping.ShoppingSegment(value: 'daily', label: 'Daily'),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    final containers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(controlKey),
            matching: find.byType(Container),
          ),
        )
        .toList();
    final palette = AppPalette.light;
    final track = decorationOf(containers.first);
    expect(
      track.color,
      Color.alphaBlend(
        palette.backgroundMuted.withValues(alpha: 0.54),
        palette.card,
      ),
    );
    expect(track.boxShadow, isNotEmpty);
    expect(
      tester.widget<Text>(find.text('Daily')).style?.color,
      palette.textPrimary,
    );

    final active = containers
        .map(decorationOf)
        .singleWhere((decoration) => decoration.color == palette.accentPrimary);
    expect(active.boxShadow, isNotEmpty);
    expect(
      tester.widget<Text>(find.text('All')).style?.fontSize,
      AppTypography.label,
    );
  });
}
