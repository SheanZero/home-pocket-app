import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_metric_variant_chip.dart';

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

void main() {
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
