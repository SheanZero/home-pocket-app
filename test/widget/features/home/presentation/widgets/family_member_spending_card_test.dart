import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_member_spending_card.dart';
import 'package:home_pocket/features/profile/presentation/widgets/avatar_display.dart';

import '../../helpers/test_localizations.dart';

const _items = [
  FamilyMemberSpendingItem(
    deviceId: 'self',
    displayName: 'あおい',
    avatarEmoji: '🌿',
    totalExpenses: 84200,
    joyTotal: 18400,
    dailyTotal: 65800,
  ),
  FamilyMemberSpendingItem(
    deviceId: 'hanako',
    displayName: '花子',
    avatarEmoji: '🌸',
    totalExpenses: 62600,
    joyTotal: 16420,
    dailyTotal: 46180,
  ),
];

void main() {
  testWidgets('matches the mockup member spending hierarchy', (tester) async {
    String? tappedDeviceId;
    await tester.pumpWidget(
      testLocalizedApp(
        child: Scaffold(
          body: FamilyMemberSpendingCard(
            items: _items,
            currencyCode: 'JPY',
            locale: const Locale('ja'),
            onMemberTap: (item) => tappedDeviceId = item.deviceId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    expect(find.text('メンバーの支出'), findsOneWidget);
    expect(find.byType(AvatarDisplay), findsNWidgets(2));
    expect(find.text('あおい'), findsOneWidget);
    expect(find.text('¥84,200'), findsOneWidget);
    expect(find.text('¥18,400'), findsOneWidget);
    expect(find.text('¥65,800'), findsOneWidget);
    expect(find.byKey(const Key('family-member-split-self')), findsOneWidget);

    await tester.tap(find.byKey(const Key('family-member-row-self')));
    expect(tappedDeviceId, 'self');
  });

  testWidgets('fits a narrow phone without horizontal overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(350, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      testLocalizedApp(
        child: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: FamilyMemberSpendingCard(
                items: _items,
                currencyCode: 'JPY',
                locale: Locale('ja'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('family-member-row-hanako')), findsOneWidget);
  });
}
