import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/input_mode_tabs.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/ledger_type_selector.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';

void main() {
  Widget buildDark(Widget child) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: child),
    );
  }

  testWidgets('smart keyboard uses dark surface colors', (tester) async {
    await tester.pumpWidget(
      buildDark(SmartKeyboard(onDigit: (_) {}, onDelete: () {}, onNext: () {})),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('smart_keyboard_root')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColorsDark.card);
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
    expect(decoration.color, AppColorsDark.backgroundMuted);
  });

  testWidgets('ledger type selector uses dark inactive surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDark(
        LedgerTypeSelector(
          selected: LedgerType.survival,
          onChanged: (_) {},
          survivalLabel: '生存支出',
          soulLabel: '魂支出',
        ),
      ),
    );

    final inactiveChip = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('ledger_type_soul_chip')),
    );
    final decoration = inactiveChip.decoration! as BoxDecoration;
    expect(decoration.color, AppColorsDark.backgroundMuted);
  });
}
