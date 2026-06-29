import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No-op sync engine so booting MainShellScreen after completion doesn't start
/// the real periodic status timer (mirrors main_characterization_smoke_test).
class _FakeSyncEngine implements SyncEngine {
  @override
  void initialize() {}

  @override
  void connectPushNotifications(PushNotificationService pushService) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// In-memory book repo (currency write-through during settings confirm).
class _FakeBookRepository implements BookRepository {
  _FakeBookRepository(this._book);

  Book _book;

  @override
  Future<Book?> findById(String id) async => _book.id == id ? _book : null;

  @override
  Future<void> update(Book book) async => _book = book;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// In-memory profile repo (save during settings confirm).
class _FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? saved;

  @override
  Future<UserProfile?> find() async => saved;

  @override
  Future<void> save(UserProfile profile) async => saved = profile;

  @override
  Future<void> delete(String id) async {}
}

Book _testBook() => Book(
  id: 'book-1',
  name: 'Home',
  currency: 'JPY',
  deviceId: 'device-1',
  createdAt: DateTime(2026, 1, 1),
);

/// Full override set so the real intro → settings → lock-entry flow composes
/// (settings confirm writes through real providers; MainShellScreen renders
/// against an in-memory DB after completion).
Future<({List<Override> overrides, SharedPreferences prefs})> _buildOverrides({
  Map<String, Object> prefsSeed = const {'language': 'system'},
}) async {
  SharedPreferences.setMockInitialValues(prefsSeed);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting();
  addTearDown(db.close);
  return (
    prefs: prefs,
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: prefs),
      ),
      bookRepositoryProvider.overrideWith((_) => _FakeBookRepository(_testBook())),
      saveUserProfileUseCaseProvider.overrideWith(
        (_) => SaveUserProfileUseCase(_FakeUserProfileRepository()),
      ),
      // Bypass the real SyncEngine (periodic status timer) so booting
      // MainShellScreen after completion doesn't leak a pending timer.
      syncEngineProvider.overrideWithValue(_FakeSyncEngine()),
      syncStatusStreamProvider.overrideWith((_) => const Stream.empty()),
      activeGroupProvider.overrideWith((_) => Stream.value(null)),
    ],
  );
}

Widget _host(
  List<Override> overrides, {
  void Function({required bool setupSecurity})? onCompleted,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja'), Locale('en'), Locale('zh')],
      home: OnboardingFlowScreen(
        bookId: 'book-1',
        onCompleted: onCompleted ?? ({required bool setupSecurity}) {},
      ),
    ),
  );
}

/// Bounded pump that flushes async futures without waiting on the List tab's
/// perpetual loading spinner (mirrors main_characterization_smoke_test).
Future<void> _pumpNoSettle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _setNickname(WidgetTester tester, String name) async {
  await tester.tap(find.text('未設定'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, name);
  await tester.pumpAndSettle();
  await tester.tap(find.text('変更').last);
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingFlowScreen — ONBOARD-07 / D-12 nested-Navigator host', () {
    testWidgets('initial route is the skippable intro', (tester) async {
      final h = await _buildOverrides();
      await tester.pumpWidget(_host(h.overrides));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingIntroScreen), findsOneWidget);
      expect(find.byType(OnboardingSettingsScreen), findsNothing);
    });

    testWidgets(
      'onContinue advances to settings; system back returns to intro '
      '(re-entrant, ONBOARD-07)',
      (tester) async {
        final h = await _buildOverrides();
        await tester.pumpWidget(_host(h.overrides));
        await tester.pumpAndSettle();

        // Advance: intro → settings.
        await tester.tap(find.widgetWithText(TextButton, 'はじめる'));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingSettingsScreen), findsOneWidget);
        expect(find.byType(OnboardingIntroScreen), findsNothing);

        // System back pops the nested route settings → intro (the root
        // PopScope guard delegates to the nested Navigator). It must NOT pop
        // out of the flow.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingIntroScreen), findsOneWidget);
        expect(find.byType(OnboardingSettingsScreen), findsNothing);
      },
    );

    testWidgets(
      'root cannot be popped out of the flow (PopScope guard) — system back '
      'on the intro is a no-op, the flow stays mounted',
      (tester) async {
        final h = await _buildOverrides();
        await tester.pumpWidget(_host(h.overrides));
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Still on the intro — the flow did not pop out (cannot dead-lock).
        expect(find.byType(OnboardingFlowScreen), findsOneWidget);
        expect(find.byType(OnboardingIntroScreen), findsOneWidget);
      },
    );

    testWidgets(
      'completing lock-entry (skip) writes onboardingComplete=true LAST and '
      'fires onCompleted(setupSecurity: false) without self-navigating',
      (tester) async {
        bool? recordedSetupSecurity;
        final h = await _buildOverrides();
        await tester.pumpWidget(
          _host(
            h.overrides,
            onCompleted: ({required bool setupSecurity}) =>
                recordedSetupSecurity = setupSecurity,
          ),
        );
        await tester.pumpAndSettle();

        // intro → settings
        await tester.tap(find.widgetWithText(TextButton, 'はじめる'));
        await tester.pumpAndSettle();

        // settings: nickname required, then confirm → lock-entry
        await _setNickname(tester, 'たけし');
        await tester.tap(find.widgetWithText(TextButton, 'この設定で始める'));
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingLockEntryScreen), findsOneWidget);

        // The flag is NOT set before lock-entry completion (lands LAST).
        expect(h.prefs.getBool('onboarding_complete'), isNot(true));

        // lock-entry skip → completion writes the flag LAST, then hands off to
        // the gate-owned callback (the flow host no longer self-navigates, so
        // the gate route stays live — HI-01). setupSecurity is false on skip.
        await tester.tap(find.widgetWithText(TextButton, 'スキップ'));
        await _pumpNoSettle(tester);

        expect(h.prefs.getBool('onboarding_complete'), true);
        expect(recordedSetupSecurity, false);
      },
    );
  });
}
