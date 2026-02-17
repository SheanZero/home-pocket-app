import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';

import '../../helpers/test_localizations.dart';

void main() {
  group('FamilyInviteBanner', () {
    testWidgets('displays invite title and description', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(body: FamilyInviteBanner(onTap: () {})),
        ),
      );

      // ja locale
      expect(find.text('家族を招待する'), findsOneWidget);
      expect(find.text('パートナーと家計簿を共有しよう'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(body: FamilyInviteBanner(onTap: () => tapped = true)),
        ),
      );

      await tester.tap(find.byType(FamilyInviteBanner));
      expect(tapped, isTrue);
    });

    testWidgets('shows chevron right icon', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(body: FamilyInviteBanner(onTap: () {})),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows people icon', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(body: FamilyInviteBanner(onTap: () {})),
        ),
      );

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });
  });
}
