import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_metric_variant_chip.dart';
import 'package:home_pocket/generated/app_localizations.dart';

class _TestSelectedJoyMetricVariant extends SelectedJoyMetricVariant {
  static JoyMetricVariant initial = JoyMetricVariant.all;

  @override
  JoyMetricVariant build() => initial;
}

Widget _buildSubject(
  ProviderContainer container, {
  Locale locale = const Locale('en'),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        appBar: AppBar(actions: [JoyMetricVariantChip(locale: locale)]),
      ),
    ),
  );
}

ProviderContainer _container({
  JoyMetricVariant initial = JoyMetricVariant.all,
}) {
  _TestSelectedJoyMetricVariant.initial = initial;
  final container = ProviderContainer(
    overrides: [
      selectedJoyMetricVariantProvider.overrideWith(
        _TestSelectedJoyMetricVariant.new,
      ),
    ],
  );
  return container;
}

void main() {
  group('JoyMetricVariantChip', () {
    testWidgets('renders initial variant label (all)', (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildSubject(container));
      await tester.pumpAndSettle();

      expect(find.text('All entries'), findsOneWidget);
      expect(
        container.read(selectedJoyMetricVariantProvider),
        JoyMetricVariant.all,
      );
    });

    testWidgets('tapping chip opens bottom sheet', (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildSubject(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(JoyMetricVariantChip));
      await tester.pumpAndSettle();

      expect(find.text('Joy metric variant'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'All entries'), findsOneWidget);
      expect(
        find.widgetWithText(ListTile, 'Manual entries only'),
        findsOneWidget,
      );
    });

    testWidgets('selecting manualOnly updates provider and closes sheet', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildSubject(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(JoyMetricVariantChip));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Manual entries only'));
      await tester.pumpAndSettle();

      expect(
        container.read(selectedJoyMetricVariantProvider),
        JoyMetricVariant.manualOnly,
      );
      expect(find.text('Joy metric variant'), findsNothing);
      expect(find.text('Manual entries only'), findsOneWidget);
    });

    testWidgets('selecting all from manualOnly updates provider back to all', (
      tester,
    ) async {
      final container = _container(initial: JoyMetricVariant.manualOnly);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildSubject(container));
      await tester.pumpAndSettle();

      expect(find.text('Manual entries only'), findsOneWidget);

      await tester.tap(find.byType(JoyMetricVariantChip));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'All entries'));
      await tester.pumpAndSettle();

      expect(
        container.read(selectedJoyMetricVariantProvider),
        JoyMetricVariant.all,
      );
      expect(find.text('Joy metric variant'), findsNothing);
      expect(find.text('All entries'), findsOneWidget);
    });
  });
}
