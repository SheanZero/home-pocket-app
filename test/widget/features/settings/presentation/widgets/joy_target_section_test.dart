import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/widgets/joy_target_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _buildSubject({
  int? configuredTarget,
  int? recommendedTarget = 64,
  int fallbackTarget = 50,
  Future<void> Function(int? value)? onSave,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: JoyTargetSection(
        configuredTarget: configuredTarget,
        recommendedTarget: recommendedTarget,
        fallbackTarget: fallbackTarget,
        onSave: onSave ?? (_) async {},
      ),
    ),
  );
}

void main() {
  group('JoyTargetSection', () {
    testWidgets('renders configured and recommendation as neutral facts', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(configuredTarget: 80));
      await tester.pumpAndSettle();

      expect(find.text('Joy target'), findsOneWidget);
      expect(find.text('Current target: 80'), findsOneWidget);
      expect(
        find.text('Reference from recent Joy patterns: 64'),
        findsOneWidget,
      );
    });

    testWidgets('unconfigured state renders recommendation as active target', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Active reference: 64'), findsOneWidget);
    });

    testWidgets('empty recommendation renders fallback copy and active target', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(recommendedTarget: null));
      await tester.pumpAndSettle();

      expect(find.text('Active reference: 50'), findsOneWidget);
      expect(
        find.text(
          'Reference target is available after more Joy entries. Using the starter reference for now.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('valid integer input saves configured target', (tester) async {
      final saved = <int?>[];
      await tester.pumpWidget(
        _buildSubject(onSave: (value) async => saved.add(value)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '72');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, [72]);
    });

    testWidgets('clear action saves null to use recommendation', (
      tester,
    ) async {
      final saved = <int?>[];
      await tester.pumpWidget(
        _buildSubject(
          configuredTarget: 80,
          onSave: (value) async => saved.add(value),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use reference'));
      await tester.pumpAndSettle();

      expect(saved, [null]);
    });

    testWidgets('invalid inputs do not save and show validation copy', (
      tester,
    ) async {
      for (final input in ['0', '-1', '12.5', 'abc']) {
        final saved = <int?>[];
        await tester.pumpWidget(
          _buildSubject(onSave: (value) async => saved.add(value)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), input);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(saved, isEmpty);
        expect(
          find.text('Enter a whole number greater than zero.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('rendered copy avoids comparative and achievement framing', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(configuredTarget: 80));
      await tester.pumpAndSettle();

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ');
      for (final forbidden in [
        'higher',
        'lower',
        'above',
        'below',
        '+',
        'achievement',
        'milestone',
        'beat',
        '前月',
        '先月',
        '高于',
        '低于',
      ]) {
        expect(rendered, isNot(contains(forbidden)));
      }
    });
  });
}
