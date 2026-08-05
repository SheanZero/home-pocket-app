import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:home_pocket/features/profile/presentation/screens/avatar_picker_screen.dart';
import 'package:home_pocket/features/profile/presentation/widgets/avatar_display.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../helpers/test_localizations.dart';

class _CapturingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

void main() {
  testWidgets('shows avatar and display name without a family-display field', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 1);
    final profile = UserProfile(
      id: 'profile-test',
      displayName: 'Shean',
      avatarEmoji: 'local_cafe',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        ProfileEditScreen(profile: profile),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(tester.element(find.byType(ProfileEditScreen)));
    expect(find.text(l10n.profileEdit), findsOneWidget);
    expect(find.text(l10n.profileDisplayName), findsOneWidget);
    expect(find.text(l10n.profileChangeAvatar), findsOneWidget);
    expect(find.text(l10n.profileSave), findsOneWidget);
    expect(find.text(l10n.familySync), findsNothing);
    expect(find.text('Shean'), findsOneWidget);
  });

  testWidgets('applies an avatar picker selection including the image path', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 1);
    final profile = UserProfile(
      id: 'profile-test',
      displayName: 'Shean',
      avatarEmoji: 'local_cafe',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        ProfileEditScreen(profile: profile),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = S.of(tester.element(find.byType(ProfileEditScreen)));
    await tester.tap(find.text(l10n.profileChangeAvatar));
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byType(AvatarPickerScreen)),
    ).pop(const AvatarPickerResult(emoji: '🌻', imagePath: '/avatars/new.jpg'));
    await tester.pumpAndSettle();

    final avatar = tester.widget<AvatarDisplay>(find.byType(AvatarDisplay));
    expect(avatar.emoji, '🌻');
    expect(avatar.imagePath, '/avatars/new.jpg');
  });

  testWidgets('ignores an avatar result after the profile host is disposed', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 1);
    final observer = _CapturingNavigatorObserver();
    final profile = UserProfile(
      id: 'profile-test',
      displayName: 'Shean',
      avatarEmoji: 'local_cafe',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ja'),
          navigatorObservers: [observer],
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: ProfileEditScreen(profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final profileRoute = observer.pushed.single;
    final l10n = S.of(tester.element(find.byType(ProfileEditScreen)));
    await tester.tap(find.text(l10n.profileChangeAvatar));
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(profileRoute);
    await tester.pump();
    navigator.pop(const AvatarPickerResult(emoji: '🌻'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
