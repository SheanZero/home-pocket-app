import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildSubject({VoidCallback? onTap}) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: FamilyInviteBanner(onTap: onTap ?? () {})),
    );
  }

  testWidgets('shows CTA button text', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    // ja: homeFamilyInviteTitle = "家族を招待する"
    expect(find.text('家族を招待する'), findsOneWidget);
  });

  testWidgets('shows title', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    // ja: homeFamilyBannerTitle = "家族と一緒に管理しよう"
    expect(find.text('家族と一緒に管理しよう'), findsOneWidget);
  });

  testWidgets('shows subtitle', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    // ja: homeFamilyBannerSubtitle (note: newline removed; text widget wraps naturally)
    expect(find.text('パートナーを招待して、家計簿をリアルタイムで共有しよう'), findsOneWidget);
  });

  testWidgets('onTap triggers when CTA button is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildSubject(onTap: () => tapped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('家族を招待する'));
    expect(tapped, isTrue);
  });

  testWidgets('displays two avatar circles with material icons', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.face), findsOneWidget);
    expect(find.byIcon(Icons.face_2), findsOneWidget);
  });

  testWidgets('CTA button includes heart icon', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('uses vertical Column layout', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final columnFinder = find.descendant(
      of: find.byType(FamilyInviteBanner),
      matching: find.byType(Column),
    );
    expect(columnFinder, findsWidgets);
  });
}
