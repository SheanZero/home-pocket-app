import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/hold_to_talk_bar.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('v16 keypad uses 48 dp rows, 7 dp gaps, and a solid action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: SmartKeyboard(
            onDigit: (_) {},
            onDelete: () {},
            onNext: () {},
            actionLabel: 'Record',
            useV16Layout: true,
          ),
        ),
      ),
    );

    final one = find
        .ancestor(of: find.text('1'), matching: find.byType(InkWell))
        .first;
    final record = find
        .ancestor(of: find.text('Record'), matching: find.byType(InkWell))
        .first;
    expect(tester.getSize(one).height, closeTo(48, 0.1));
    expect(tester.getSize(record).height, closeTo(48, 0.1));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('smart_keyboard_root')),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 7,
        ),
      ),
      findsNWidgets(4),
    );

    final ink = tester.widget<Ink>(
      find.descendant(of: record, matching: find.byType(Ink)).first,
    );
    final decoration = ink.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.gradient, isNull);
  });

  testWidgets('v16 voice launcher is a neutral 304 by 46 control', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(body: VoiceRecordBar(onTap: () {}, useV16Layout: true)),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('voice-record-pill'))),
      const Size(304, 46),
    );
    final ink = tester.widget<Ink>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('voice-record-pill')),
            matching: find.byType(Ink),
          )
          .first,
    );
    final decoration = ink.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, isNotNull);
  });
}
