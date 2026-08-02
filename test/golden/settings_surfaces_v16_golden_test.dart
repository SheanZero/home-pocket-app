@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show bookByIdProvider;
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/providers/state_user_profile.dart';
import 'package:home_pocket/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:home_pocket/features/settings/presentation/screens/legal_sponsor_screen.dart';
import 'package:home_pocket/features/settings/presentation/screens/settings_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart'
    show appDatabaseProvider;
import 'package:shared_preferences/shared_preferences.dart';

const _bookId = 'settings-golden-book';
final _profile = UserProfile(
  id: 'profile-golden',
  displayName: 'あおい',
  avatarEmoji: '🌿',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget _wrap(Widget home, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: AppTheme.light,
      initialRoute: '/surface',
      routes: {'/': (_) => const SizedBox.shrink(), '/surface': (_) => home},
    ),
  );
}

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('settings hierarchy — light ja', (tester) async {
    await _setPhoneViewport(tester);
    SharedPreferences.setMockInitialValues({'language': 'ja'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(
      _wrap(
        const SettingsScreen(bookId: _bookId),
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          settingsRepositoryProvider.overrideWith(
            (_) => SettingsRepositoryImpl(prefs: prefs),
          ),
          appSettingsProvider.overrideWith(
            (_) async => const AppSettings(
              language: 'ja',
              appLockEnabled: false,
              monthlyJoyTarget: 80,
            ),
          ),
          bookByIdProvider(bookId: _bookId).overrideWith((_) async => null),
          monthlyJoyTargetRecommendationProvider(
            bookId: _bookId,
            currencyCode: 'JPY',
          ).overrideWith((_) async => const Empty<int>()),
          syncStatusStreamProvider.overrideWith((_) => const Stream.empty()),
          activeGroupProvider.overrideWith((_) => Stream.value(null)),
          userProfileProvider.overrideWith((_) async => _profile),
        ],
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/settings_v16_light_ja.png'),
    );
  });

  testWidgets('profile edit — light ja', (tester) async {
    await _setPhoneViewport(tester);
    await tester.pumpWidget(_wrap(ProfileEditScreen(profile: _profile)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/profile_edit_v16_light_ja.png'),
    );
  });

  testWidgets('backup and restore — light ja', (tester) async {
    await _setPhoneViewport(tester);
    await tester.pumpWidget(_wrap(const BackupRestoreScreen(bookId: _bookId)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/backup_restore_v16_light_ja.png'),
    );
  });

  testWidgets('legal and support — light ja', (tester) async {
    await _setPhoneViewport(tester);
    await tester.pumpWidget(_wrap(const LegalSponsorScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/legal_sponsor_v16_light_ja.png'),
    );
  });
}
