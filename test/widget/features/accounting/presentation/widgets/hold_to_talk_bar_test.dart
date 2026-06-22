// Widget test for HoldToTalkBar (quick task 260622-nhs Task 2).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/hold_to_talk_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('renders the localized hold-to-talk label', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: HoldToTalkBar(onHoldStart: () {}, onHoldEnd: () {}),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(tester.element(find.byType(HoldToTalkBar)));
    expect(find.text(l10n.holdToTalkBar), findsOneWidget);
    expect(find.byKey(const ValueKey('hold-to-talk-bar')), findsOneWidget);
  });

  testWidgets('fires onHoldStart on press-down and onHoldEnd on release',
      (tester) async {
    var started = false;
    var ended = false;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: HoldToTalkBar(
            onHoldStart: () => started = true,
            onHoldEnd: () => ended = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final barFinder = find.byKey(const ValueKey('hold-to-talk-bar'));
    final gesture = await tester.startGesture(tester.getCenter(barFinder));
    // LongPressGestureRecognizer(duration: Duration.zero) fires onLongPressStart
    // on the next tick.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(started, isTrue, reason: 'press-down must fire onHoldStart');
    expect(ended, isFalse);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(ended, isTrue, reason: 'release must fire onHoldEnd');
  });
}
