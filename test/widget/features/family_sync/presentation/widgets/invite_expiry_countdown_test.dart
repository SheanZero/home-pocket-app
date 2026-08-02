import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/invite_expiry_countdown.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('counts down every second then shows red expired copy', (
    tester,
  ) async {
    final start = DateTime(2026, 8, 2, 21);
    var now = start;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: FamilyInviteExpiryCountdown(
            expiresAt: start.add(const Duration(minutes: 1, seconds: 1)),
            now: () => now,
          ),
        ),
        locale: const Locale('zh'),
      ),
    );

    expect(find.text('01:01内有效'), findsOneWidget);

    now = start.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:00内有效'), findsOneWidget);

    now = start.add(const Duration(minutes: 1, seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    final expired = find.byKey(
      const Key('family-invite-expiry-countdown-label'),
    );
    expect(find.text('已失效'), findsOneWidget);
    expect(
      tester.widget<Text>(expired).style?.color,
      tester.element(expired).palette.error,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
