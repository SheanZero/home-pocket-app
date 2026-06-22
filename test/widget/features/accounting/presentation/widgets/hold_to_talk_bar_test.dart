// Widget test for VoiceRecordBar (quick task 260622-nhs R2 — tap-to-record).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/hold_to_talk_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('renders the localized voice-record label and a line mic icon',
      (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordBar(onTap: () {}),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(tester.element(find.byType(VoiceRecordBar)));
    expect(find.text(l10n.voiceRecordBar), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-record-bar')), findsOneWidget);
    // Line-style mic (not filled Icons.mic).
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);
  });

  testWidgets(
      'R3 BUG 1: slim bar (<=40dp) with no outer margin so it integrates '
      'into the keypad top', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: VoiceRecordBar(onTap: () {}),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('voice-record-bar')),
        matching: find.byType(Container),
      ),
    );
    expect(container.constraints?.maxHeight ?? double.infinity, lessThanOrEqualTo(40.0),
        reason: 'R3: the bar must be a slim top strip (<=40dp), not a 52dp card');
    // R3: no outer margin — it sits flush against the keypad below it.
    expect(container.margin, anyOf(isNull, EdgeInsets.zero),
        reason: 'R3: no gap/margin between the bar and the keypad');
  });

  testWidgets('fires onTap on a single tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordBar(onTap: () => tapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('voice-record-bar')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue, reason: 'a single tap must fire onTap');
  });
}
