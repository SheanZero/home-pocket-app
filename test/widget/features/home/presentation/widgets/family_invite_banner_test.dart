import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildSubject({
    VoidCallback? onTap,
    VoidCallback? onSettingsTap,
    VoidCallback? onDismiss,
    Locale locale = const Locale('ja'),
  }) {
    return MaterialApp(
      locale: locale,
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

  group('FamilyInviteBanner (v15 horizontal layout)', () {
    testWidgets('displays title, subtitle and CTA text (ja locale)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // ja: homeFamilyBannerTitle
      expect(find.text('家族と家計を共有'), findsOneWidget);
      // ja: homeFamilyBannerSubtitle
      expect(find.text('設定からいつでも追加できます'), findsOneWidget);
      // ja: homeFamilyInviteTitle
      expect(find.text('家族を追加'), findsOneWidget);
      // ja: homeFamilyInviteSettingsPath
      expect(find.text('設定 › 家庭'), findsOneWidget);
    });

    testWidgets('triggers onTap callback via CTA button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('家族を追加'));
      expect(tapped, isTrue);
    });

    testWidgets('triggers onSettingsTap via settings-path button', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onSettingsTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('設定 › 家庭'));
      expect(tapped, isTrue);
    });

    testWidgets('triggers onDismiss via close button', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(buildSubject(onDismiss: () => dismissed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('shows two avatar circles + group_add CTA icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byIcon(Icons.face_2), findsOneWidget);
      expect(find.byIcon(Icons.group_add), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders Chinese text in zh locale', (tester) async {
      await tester.pumpWidget(buildSubject(locale: const Locale('zh')));
      await tester.pumpAndSettle();

      // zh: homeFamilyBannerTitle
      expect(find.text('与家人共享家计'), findsOneWidget);
      // zh: homeFamilyInviteTitle
      expect(find.text('添加家人'), findsOneWidget);
    });
  });
}
