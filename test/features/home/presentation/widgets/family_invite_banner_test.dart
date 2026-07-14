import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildSubject({
    VoidCallback? onTap,
    VoidCallback? onSettingsTap,
    VoidCallback? onDismiss,
  }) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: FamilyInviteBanner(
          onTap: onTap ?? () {},
          onSettingsTap: onSettingsTap ?? () {},
          onDismiss: onDismiss ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows CTA button text', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    // ja: homeFamilyInviteTitle = "家族を追加"
    expect(find.text('家族を追加'), findsOneWidget);
  });

  testWidgets('shows title', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    // ja: homeFamilyBannerTitle = "家族と家計を共有"
    expect(find.text('家族と家計を共有'), findsOneWidget);
  });

  testWidgets('shows subtitle', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    // ja: homeFamilyBannerSubtitle = "設定からいつでも追加できます"
    expect(find.text('設定からいつでも追加できます'), findsOneWidget);
  });

  testWidgets('onTap triggers when CTA button is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildSubject(onTap: () => tapped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('家族を追加'));
    expect(tapped, isTrue);
  });

  testWidgets('onDismiss triggers when close button is tapped', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(buildSubject(onDismiss: () => dismissed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  testWidgets('displays two avatar circles with material icons', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.face), findsOneWidget);
    expect(find.byIcon(Icons.face_2), findsOneWidget);
  });

  testWidgets('CTA button includes group_add icon', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.group_add), findsOneWidget);
  });
}
