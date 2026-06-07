import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/input_mode_tabs.dart';
import 'package:home_pocket/shared/widgets/ledger_type_selector.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildDark(Widget child) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: child),
    );
  }

  Widget buildLocalizedDark(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  Widget buildLocalizedLight(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('smart keyboard uses dark surface colors', (tester) async {
    await tester.pumpWidget(
      buildDark(
        SmartKeyboard(
          onDigit: (_) {},
          onDelete: () {},
          onNext: () {},
          actionLabel: '記録',
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('smart_keyboard_root')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppPalette.dark.card);
  });

  testWidgets('amount display renders a currency badge in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(buildDark(const AmountDisplay(amount: '3280')));

    expect(find.byKey(const ValueKey('amount_currency_badge')), findsOneWidget);
  });

  testWidgets('input mode tabs use dark background', (tester) async {
    await tester.pumpWidget(
      buildDark(
        InputModeTabs(
          selected: InputMode.voice,
          onChanged: (_) {},
          manualLabel: '手動',
          ocrLabel: 'OCR',
          voiceLabel: '音声',
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('input_mode_tabs_root')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppPalette.dark.backgroundMuted);
  });

  testWidgets('ledger type selector uses dark inactive surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDark(
        LedgerTypeSelector(
          selected: LedgerType.daily,
          onChanged: (_) {},
          dailyLabel: '日常支出',
          joyLabel: 'ときめき支出',
        ),
      ),
    );

    final inactiveChip = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('ledger_type_joy_chip')),
    );
    final decoration = inactiveChip.decoration! as BoxDecoration;
    expect(decoration.color, AppPalette.dark.backgroundMuted);
  });

  // ── CR-02: AmountEditBottomSheet dark-mode color regression ───────────────

  testWidgets('CR-02: AmountEditBottomSheet uses dark card color in dark mode',
      (tester) async {
    await tester.pumpWidget(
      buildLocalizedDark(
        AmountEditBottomSheet(
          initialAmount: 1000,
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pump();

    // The outermost Container has a BoxDecoration with a borderRadius — that
    // is the sheet background. Search all Containers for the one with a
    // vertical-top BorderRadius (the sheet's rounded top corners).
    final containers = tester.widgetList<Container>(find.byType(Container));
    final sheetContainer = containers.firstWhere(
      (c) =>
          c.decoration is BoxDecoration &&
          (c.decoration! as BoxDecoration).borderRadius ==
              const BorderRadius.vertical(top: Radius.circular(20)),
      orElse: () => throw TestFailure(
          'Could not find AmountEditBottomSheet root Container'),
    );
    final decoration = sheetContainer.decoration! as BoxDecoration;
    expect(
      decoration.color,
      AppPalette.dark.card,
      reason:
          'AmountEditBottomSheet background must use AppPalette.dark.card in dark mode (CR-02)',
    );
  });

  testWidgets('CR-02: AmountEditBottomSheet uses light card color in light mode',
      (tester) async {
    await tester.pumpWidget(
      buildLocalizedLight(
        AmountEditBottomSheet(
          initialAmount: 1000,
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pump();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final sheetContainer = containers.firstWhere(
      (c) =>
          c.decoration is BoxDecoration &&
          (c.decoration! as BoxDecoration).borderRadius ==
              const BorderRadius.vertical(top: Radius.circular(20)),
      orElse: () => throw TestFailure(
          'Could not find AmountEditBottomSheet root Container'),
    );
    final decoration = sheetContainer.decoration! as BoxDecoration;
    expect(
      decoration.color,
      AppPalette.light.card,
      reason:
          'AmountEditBottomSheet background must use AppPalette.light.card in light mode (CR-02)',
    );
  });
}
