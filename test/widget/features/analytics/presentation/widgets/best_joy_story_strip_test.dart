import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/best_joy_story_strip.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  const locale = Locale('ja');

  testWidgets('renders empty state when MetricResult is Empty', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        BestJoyStoryStrip(
          bestJoy: Empty<BestJoyMomentRow>(),
          currencyCode: 'JPY',
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('今月の最大ハイライトはまだ見つからない'), findsOneWidget);
  });

  testWidgets('renders empty state when satisfaction is two or lower', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        BestJoyStoryStrip(
          bestJoy: Value<BestJoyMomentRow>(_lowRatedJoy, 1),
          currencyCode: 'JPY',
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('今月の最大ハイライトはまだ見つからない'), findsOneWidget);
    expect(find.textContaining('¥10'), findsNothing);
  });

  testWidgets(
    'renders category date and amount when satisfaction is above two',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          BestJoyStoryStrip(
            bestJoy: Value<BestJoyMomentRow>(_highRatedJoy, 1),
            currencyCode: 'JPY',
            locale: locale,
          ),
          locale: locale,
        ),
      );

      expect(find.text('食費 · 5月15日'), findsOneWidget);
      expect(find.text('¥3,000 · 満足 8/10 ✨'), findsOneWidget);
    },
  );

  testWidgets(
    'tap invokes callback with transaction id when value is rendered',
    (tester) async {
      String? tappedId;
      await tester.pumpWidget(
        createLocalizedWidget(
          BestJoyStoryStrip(
            bestJoy: Value<BestJoyMomentRow>(_highRatedJoy, 1),
            currencyCode: 'JPY',
            locale: locale,
            onTap: (transactionId) => tappedId = transactionId,
          ),
          locale: locale,
        ),
      );

      await tester.tap(find.text('食費 · 5月15日'));
      await tester.pump();

      expect(tappedId, 'joy-high');
    },
  );

  testWidgets('big and small lines use bodyMedium and caption text styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        BestJoyStoryStrip(
          bestJoy: Value<BestJoyMomentRow>(_highRatedJoy, 1),
          currencyCode: 'JPY',
          locale: locale,
        ),
        locale: locale,
      ),
    );

    final bigLine = tester.widget<Text>(find.text('食費 · 5月15日'));
    final smallLine = tester.widget<Text>(find.text('¥3,000 · 満足 8/10 ✨'));

    expect(bigLine.style?.fontSize, AppTextStyles.bodyMedium.fontSize);
    expect(bigLine.style?.fontWeight, AppTextStyles.bodyMedium.fontWeight);
    expect(smallLine.style?.fontSize, AppTextStyles.caption.fontSize);
    expect(smallLine.style?.fontWeight, AppTextStyles.caption.fontWeight);
  });
}

final _lowRatedJoy = BestJoyMomentRow(
  transactionId: 'joy-low',
  amount: 10,
  soulSatisfaction: 2,
  categoryId: 'cat_food',
  timestamp: DateTime(2026, 5, 15),
);

final _highRatedJoy = BestJoyMomentRow(
  transactionId: 'joy-high',
  amount: 3000,
  soulSatisfaction: 8,
  categoryId: 'cat_food',
  timestamp: DateTime(2026, 5, 15),
);
