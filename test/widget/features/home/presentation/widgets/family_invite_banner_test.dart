import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildSubject({
    VoidCallback? onTap,
    Locale locale = const Locale('ja'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: FamilyInviteBanner(onTap: onTap ?? () {})),
    );
  }

  group('FamilyInviteBanner', () {
    testWidgets('displays invite title and CTA text (ja locale)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // ja: homeFamilyBannerTitle
      expect(find.text('家族と一緒に管理しよう'), findsOneWidget);
      // ja: homeFamilyInviteTitle
      expect(find.text('家族を招待する'), findsOneWidget);
    });

    testWidgets('triggers onTap callback via CTA button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('家族を招待する'));
      expect(tapped, isTrue);
    });

    testWidgets('shows two avatar circles with icons', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byIcon(Icons.face_2), findsOneWidget);
    });

    testWidgets('displays subtitle text (ja locale)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // ja: homeFamilyBannerSubtitle
      expect(find.text('パートナーを招待して、家計簿をリアルタイムで共有しよう'), findsOneWidget);
    });

    testWidgets('CTA button includes heart icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('renders Chinese text in zh locale', (tester) async {
      await tester.pumpWidget(buildSubject(locale: const Locale('zh')));
      await tester.pumpAndSettle();

      // zh: homeFamilyBannerTitle = "一起管理家庭账本"
      expect(find.text('一起管理家庭账本'), findsOneWidget);
      // zh: homeFamilyInviteTitle = "邀请家人"
      expect(find.text('邀请家人'), findsOneWidget);
    });
  });
}
