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
      '260623-0cj: voice key is a centered ~200dp capsule, inset from BOTH '
      'edges (不顶边), with a Stadium (pill) shape', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 390,
              child: VoiceRecordBar(onTap: () {}),
            ),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    final barRect =
        tester.getRect(find.byKey(const ValueKey('voice-record-bar')));
    final pillRect =
        tester.getRect(find.byKey(const ValueKey('voice-record-pill')));

    // Width ≈ 200 dp — the approved A/B midpoint width.
    expect(pillRect.width, closeTo(200.0, 0.5),
        reason: '260623-0cj: the voice capsule is 200 dp wide');

    // Inset from BOTH edges (不顶边) and horizontally centered.
    final leftInset = pillRect.left - barRect.left;
    final rightInset = barRect.right - pillRect.right;
    expect(leftInset, greaterThan(20.0),
        reason: '不顶边: the capsule must not touch the left edge');
    expect(rightInset, greaterThan(20.0),
        reason: '不顶边: the capsule must not touch the right edge');
    expect((leftInset - rightInset).abs(), lessThan(1.0),
        reason: 'the capsule is horizontally centered');

    // Pill (Stadium) shape — fully rounded ends, not a rectangular strip.
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('voice-record-pill')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.shape, isA<StadiumBorder>(),
        reason: '椭圆: the voice key is a Stadium-shaped capsule');
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
