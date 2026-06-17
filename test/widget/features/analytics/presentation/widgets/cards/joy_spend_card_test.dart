import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_spend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
final _start = DateTime(2026, 5);
final _end = DateTime(2026, 5, 31, 23, 59, 59);

List<JoyCategoryAmount> _amounts() => const [
  JoyCategoryAmount(categoryId: 'cat_hobbies', amount: 5000),
  JoyCategoryAmount(categoryId: 'cat_education', amount: 3000),
  JoyCategoryAmount(categoryId: 'cat_social', amount: 1200),
];

Widget _subject({
  AsyncValue<List<JoyCategoryAmount>>? override,
}) {
  final value = override ?? AsyncValue.data(_amounts());
  return createLocalizedWidget(
    JoySpendCard(
      bookId: _bookId,
      startDate: _start,
      endDate: _end,
      joyMetricVariant: JoyMetricVariant.all,
    ),
    locale: const Locale('zh'),
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('zh'),
      ),
      joyCategoryAmountsProvider(
        bookId: _bookId,
        startDate: _start,
        endDate: _end,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith(
        (_) => value.when(
          data: (d) async => d,
          loading: () => Completer<List<JoyCategoryAmount>>().future,
          error: (e, _) async => throw StateError(e.toString()),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'Test 1: renders one segment per category as Flexible Row children, '
    'largest→smallest, segment count == legend-row count',
    (tester) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      expect(find.byType(JoySpendStackedBar), findsOneWidget);

      // Three segments rendered, ordered largest→smallest.
      final segments = find.byKey(const ValueKey('joy_spend_segment_0'));
      expect(segments, findsOneWidget);
      expect(find.byKey(const ValueKey('joy_spend_segment_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_spend_segment_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_spend_segment_3')), findsNothing);

      // Flexible flex must equal the amount weight (largest first).
      final flex0 = tester.widget<Flexible>(
        find.byKey(const ValueKey('joy_spend_segment_0')),
      );
      final flex1 = tester.widget<Flexible>(
        find.byKey(const ValueKey('joy_spend_segment_1')),
      );
      expect(flex0.flex, 5000);
      expect(flex1.flex, 3000);

      // segment count == legend-row count.
      expect(find.byKey(const ValueKey('joy_spend_legend_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_spend_legend_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_spend_legend_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_spend_legend_3')), findsNothing);
    },
  );

  testWidgets(
    'Test 2: tap a segment → that segment + matching legend row highlight; '
    'tapping another moves the highlight; local-only (no navigation)',
    (tester) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      final bar = tester.state<JoySpendStackedBarState>(
        find.byType(JoySpendStackedBar),
      );
      expect(bar.selectedIndex, isNull);

      // Tap via the legend row (full-width affordance routing to the same
      // _onSegmentTap as the segment) — narrow segments are too thin to hit.
      await tester.tap(find.byKey(const ValueKey('joy_spend_legend_1')));
      await tester.pumpAndSettle();
      expect(bar.selectedIndex, 1);

      // Tapping a different row moves the highlight.
      await tester.tap(find.byKey(const ValueKey('joy_spend_legend_2')));
      await tester.pumpAndSettle();
      expect(bar.selectedIndex, 2);

      // No route was pushed — the card stayed in place (D-C2 no drill).
      expect(find.byType(JoySpendCard), findsOneWidget);
    },
  );

  testWidgets(
    'Test 3: the header joy ¥total uses a TweenAnimationBuilder that lands on '
    'the true total (D-D2 anchor #2)',
    (tester) async {
      await tester.pumpWidget(_subject());
      // Pump partway: the count-up is mid-flight (value < total).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const ValueKey('joy_spend_total_countup')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      // After settle, the animated total lands on 5000+3000+1200 = 9200.
      final totalText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('joy_spend_total_countup')),
          matching: find.byType(Text),
        ),
      );
      expect(totalText.data, contains('9,200'));
    },
  );

  testWidgets(
    'Test 4: ADR-012/ADR-016 — no streak/target/ranking copy; segments are '
    'amounts only (GUARD-02 readiness)',
    (tester) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      final forbidden = ['排名', '连续', '目标', '超支', '达成', 'streak', 'rank'];
      for (final token in forbidden) {
        expect(
          find.textContaining(token, findRichText: true),
          findsNothing,
          reason: 'forbidden token "$token" must not appear',
        );
      }
    },
  );

  testWidgets('Test 5: empty joy amounts → graceful empty copy, no throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(override: const AsyncValue.data([])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(JoySpendStackedBar), findsNothing);
    expect(find.byKey(const ValueKey('joy_spend_empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test 6a: loading → SizedBox (no bar)', (tester) async {
    await tester.pumpWidget(_subject(override: const AsyncValue.loading()));
    await tester.pump();
    expect(find.byType(JoySpendStackedBar), findsNothing);
  });

  testWidgets('Test 6b: error → AnalyticsCardErrorState with a retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(override: AsyncValue.error('boom', StackTrace.empty)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
