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
      '260623-0cj R2: voice key is a centered 200×44 capsule, inset from BOTH '
      'edges (不顶边), gradient + font matching the 「记录」 button, on a white '
      'strip unified with the keypad', (tester) async {
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

    // Size: 200 dp wide (approved midpoint), 44 dp tall (R2).
    expect(pillRect.width, closeTo(200.0, 0.5),
        reason: '260623-0cj: the voice capsule is 200 dp wide');
    expect(pillRect.height, closeTo(44.0, 0.5),
        reason: '260623-0cj R2: the voice capsule is 44 dp tall');

    // Inset from BOTH edges (不顶边) and horizontally centered.
    final leftInset = pillRect.left - barRect.left;
    final rightInset = barRect.right - pillRect.right;
    expect(leftInset, greaterThan(20.0),
        reason: '不顶边: the capsule must not touch the left edge');
    expect(rightInset, greaterThan(20.0),
        reason: '不顶边: the capsule must not touch the right edge');
    expect((leftInset - rightInset).abs(), lessThan(1.0),
        reason: 'the capsule is horizontally centered');

    // White strip unified with the keypad (一体): the bar paints a card-colored
    // background with a top border.
    final bar = tester
        .widget<Container>(find.byKey(const ValueKey('voice-record-bar')));
    final barDeco = bar.decoration! as BoxDecoration;
    expect(barDeco.color, isNotNull,
        reason: '一体: the voice strip has a solid (white card) background');
    expect(barDeco.border, isNotNull,
        reason: '一体: the strip carries the assembly top border');

    // R3 spacing: 12 dp above the pill (matches the 12 dp digit inter-row gap);
    // 0 below — the keypad's own 12 dp top padding supplies the 12 dp below.
    expect(bar.padding, const EdgeInsets.only(top: 12),
        reason: 'R3: even 12 dp above/below the voice key, like a keypad row');

    // Color scheme matches the 「记录」 button: a gradient-filled capsule.
    final ink = tester.widget<Ink>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('voice-record-pill')),
            matching: find.byType(Ink),
          )
          .first,
    );
    final pillDeco = ink.decoration! as BoxDecoration;
    expect(pillDeco.gradient, isNotNull,
        reason: '配色: the voice key uses the FAB gradient like 「记录」');
    expect(pillDeco.borderRadius, BorderRadius.circular(22.0),
        reason: '椭圆: fully rounded (stadium) capsule, radius = height/2');

    // Font matches the 「记录」 button: white, w700, 16 dp.
    final l10n = S.of(tester.element(find.byType(VoiceRecordBar)));
    final label = tester.widget<Text>(find.text(l10n.voiceRecordBar));
    expect(label.style?.color, Colors.white, reason: '字体: white like 「记录」');
    expect(label.style?.fontWeight, FontWeight.w700);
    expect(label.style?.fontSize, 16.0);
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
