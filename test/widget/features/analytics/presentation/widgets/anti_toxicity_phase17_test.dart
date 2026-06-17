import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_calendar_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_spend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/within_month_trend_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_metric_variant_chip.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/test_localizations.dart';

const forbiddenEnPhase17 = <String>[
  'less accurate',
  'invalid',
  'unreliable',
  'less valid',
  'inaccurate',
  'wrong',
];

const forbiddenJaPhase17 = <String>['不正確', '信頼できない', '不完全', '精度が低い', '誤り'];

const forbiddenZhPhase17 = <String>['不准', '不可靠', '不完整', '质量差', '估算不准', '错误'];

const locales = <Locale>[Locale('en'), Locale('ja'), Locale('zh')];

class _TestSelectedJoyMetricVariant extends SelectedJoyMetricVariant {
  static JoyMetricVariant initial = JoyMetricVariant.all;

  @override
  JoyMetricVariant build() => initial;
}

List<String> _forbiddenFor(Locale locale) {
  return switch (locale.languageCode) {
    'en' => forbiddenEnPhase17,
    'ja' => forbiddenJaPhase17,
    'zh' => forbiddenZhPhase17,
    _ => throw StateError('Unsupported locale: ${locale.languageCode}'),
  };
}

Widget _buildSubject({
  required Locale locale,
  required JoyMetricVariant variant,
}) {
  _TestSelectedJoyMetricVariant.initial = variant;
  return createLocalizedWidget(
    Scaffold(
      appBar: AppBar(actions: [JoyMetricVariantChip(locale: locale)]),
    ),
    locale: locale,
    overrides: <Override>[
      selectedJoyMetricVariantProvider.overrideWith(
        _TestSelectedJoyMetricVariant.new,
      ),
    ],
  );
}

String _visibleTextBlob(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .join('\n');
}

const _bookId = 'book_001';
final _start = DateTime(2026, 1, 1);
final _end = DateTime(2026, 1, 31);
final _anchor = DateTime(2026, 1);

const _emptyTrend = WithinMonthCumulativeTrend(
  currentMonthTotal: [],
  currentMonthDaily: [],
  currentMonthJoy: [],
  previousMonthTotal: [],
  previousMonthDaily: [],
);

/// Builds a localized scaffold hosting [card], overriding the named card
/// provider with [providerOverride] so the card renders its (empty/data) copy
/// for the forbidden-substring sweep. The card's own error-retry/loading paths
/// are not exercised — data path only.
Widget _buildCardSubject({
  required Locale locale,
  required Widget card,
  required Override providerOverride,
}) {
  return createLocalizedWidget(
    Scaffold(body: SingleChildScrollView(child: card)),
    locale: locale,
    overrides: <Override>[
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => locale,
      ),
      providerOverride,
    ],
  );
}

void main() {
  group('Phase 17 — new round-5 B card copy is scan-ready (GUARD-02)', () {
    Widget trendCard() => WithinMonthTrendCard(
      bookId: _bookId,
      startDate: _start,
      endDate: _end,
      joyMetricVariant: JoyMetricVariant.all,
    );
    Widget joySpendCard() => JoySpendCard(
      bookId: _bookId,
      startDate: _start,
      endDate: _end,
      joyMetricVariant: JoyMetricVariant.all,
    );
    Widget joyCalendarCard() => JoyCalendarCard(
      bookId: _bookId,
      startDate: _start,
      endDate: _end,
      joyMetricVariant: JoyMetricVariant.all,
    );

    for (final locale in locales) {
      final subjects = <String, Widget Function()>{
        'WithinMonthTrendCard': () => _buildCardSubject(
          locale: locale,
          card: trendCard(),
          providerOverride: withinMonthCumulativeTrendProvider(
            bookId: _bookId,
            anchor: _anchor,
          ).overrideWith((_) async => _emptyTrend),
        ),
        'JoySpendCard': () => _buildCardSubject(
          locale: locale,
          card: joySpendCard(),
          providerOverride: joyCategoryAmountsProvider(
            bookId: _bookId,
            startDate: _start,
            endDate: _end,
          ).overrideWith((_) async => const <JoyCategoryAmount>[]),
        ),
        'JoyCalendarCard': () => _buildCardSubject(
          locale: locale,
          card: joyCalendarCard(),
          providerOverride: perDayJoyCountsProvider(
            bookId: _bookId,
            anchor: _anchor,
          ).overrideWith((_) async => const <PerDayJoyCount>[]),
        ),
      };

      for (final entry in subjects.entries) {
        testWidgets(
          '${entry.key} has no forbidden copy for ${locale.languageCode}',
          (tester) async {
            await tester.pumpWidget(entry.value());
            await tester.pumpAndSettle();

            final blob = _visibleTextBlob(tester);
            final searchable = locale.languageCode == 'en'
                ? blob.toLowerCase()
                : blob;
            for (final forbidden in _forbiddenFor(locale)) {
              expect(
                searchable.contains(forbidden.toLowerCase()),
                isFalse,
                reason:
                    'Forbidden Phase 17 substring "$forbidden" appeared in '
                    '${entry.key} / ${locale.languageCode}: $blob',
              );
            }
          },
        );
      }
    }
  });

  group('Phase 17 Joy metric variant copy', () {
    for (final locale in locales) {
      for (final variant in JoyMetricVariant.values) {
        testWidgets(
          'has no forbidden copy for ${locale.languageCode} / ${variant.name}',
          (tester) async {
            await tester.pumpWidget(
              _buildSubject(locale: locale, variant: variant),
            );
            await tester.pumpAndSettle();

            await tester.tap(find.byType(JoyMetricVariantChip));
            await tester.pumpAndSettle();

            final blob = _visibleTextBlob(tester);
            final searchable = locale.languageCode == 'en'
                ? blob.toLowerCase()
                : blob;
            for (final forbidden in _forbiddenFor(locale)) {
              expect(
                searchable.contains(forbidden.toLowerCase()),
                isFalse,
                reason:
                    'Forbidden Phase 17 substring "$forbidden" appeared in '
                    '${locale.languageCode} / ${variant.name}: $blob',
              );
            }
          },
        );
      }
    }
  });
}
