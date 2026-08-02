import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../helpers/test_localizations.dart';

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
}
