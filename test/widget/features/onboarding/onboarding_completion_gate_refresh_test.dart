// HI-01 regression (Phase 54 code review): onboarding completion must NOT
// detach the boot gate. Before the fix, `_complete` did a root-navigator
// `pushReplacement` that replaced the live `'/'` home Builder (the gate) with a
// standalone MainShellScreen, so a SAME-SESSION delete-all / import-backup reset
// could no longer re-render `'/'` via `_reinitializeAfterDataReset`'s setState.
//
// These tests boot the FULL `HomePocketApp` gate with a REAL
// `SettingsRepositoryImpl` over mocked SharedPreferences (so completion can
// actually flip `onboarding_complete`), drive the real intro → settings →
// lock-entry flow to completion, then fire `dataResetSignalProvider` for both
// reset shapes:
//
//   - import   (flag stays true)  → expect the shell re-points to the NEW
//                                    post-reset bookId (not the stale boot id).
//   - delete-all (flag → false)   → expect the gate returns to OnboardingFlow.
//
// On the pre-fix `pushReplacement` code both assertions fail (the displayed
// route is the detached shell bound to the boot bookId). After routing
// completion through a gate-owned callback they pass.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/profile/get_user_profile_use_case.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/application/seed/seed_all_use_case.dart';
import 'package:home_pocket/core/state/data_reset_signal.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        bookRepositoryProvider,
        deviceIdentityRepositoryProvider,
        seedAllUseCaseProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_notification_navigation.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show getUserProfileUseCaseProvider, saveUserProfileUseCaseProvider;
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart'
    show settingsRepositoryProvider, sharedPreferencesProvider;
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/main.dart' as app;
import 'package:home_pocket/shared/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _NoopSeedAllUseCase implements SeedAllUseCase {
  @override
  Future<Result<void>> execute() async => Result.success(null);
}

class _FakeDeviceIdentityRepository implements DeviceIdentityRepository {
  @override
  Future<String?> getDeviceId() async => 'device-test';
}

class _FakeSyncEngine extends Fake implements SyncEngine {
  @override
  void initialize() {}

  @override
  void connectPushNotifications(PushNotificationService pushService) {}

  @override
  void dispose() {}
}

class _FakePushNotificationService extends Fake
    implements PushNotificationService {
  final _navController = StreamController<PushNavigationIntent>.broadcast();

  @override
  PushNavigationIntent? takePendingNavigationIntent() => null;

  @override
  Stream<PushNavigationIntent> get navigationIntents => _navController.stream;
}

class _FakeListenToPushNotificationsUseCase extends Fake
    implements ListenToPushNotificationsUseCase {
  final _navController = StreamController<PushNavigationIntent>.broadcast();

  @override
  Stream<PushNavigationIntent> execute() => _navController.stream;

  @override
  PushNavigationIntent? takePendingIntent() => null;
}

class _FakeGetUserProfileUseCase implements GetUserProfileUseCase {
  @override
  Future<UserProfile?> execute() async => _testProfile;
}

/// In-memory profile repo for the real SaveUserProfileUseCase during confirm.
class _FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? _saved;

  @override
  Future<UserProfile?> find() async => _saved;

  @override
  Future<void> save(UserProfile profile) async => _saved = profile;

  @override
  Future<void> delete(String id) async {}
}

/// Drives the app-lock cold-start gate: `getPinHash()` returns null (no PIN
/// configured) so `lockConfigured` is always false and the lock gate is inert.
class _FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<String?> getPinHash() async => null;
}

final _testProfile = UserProfile(
  id: 'profile-1',
  displayName: 'たけし',
  avatarEmoji: '🏠',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

// ── Harness ──────────────────────────────────────────────────────────────────

/// Boots the full `HomePocketApp` gate with a REAL `SettingsRepositoryImpl`
/// (so onboarding completion actually persists `onboarding_complete`) and a
/// REAL `bookRepository`/`ensureDefaultBookUseCase` over an in-memory DB (so the
/// post-reset book invariants are genuinely exercised, mirroring
/// data_reset_refresh_test.dart).
Future<({SharedPreferences prefs, ProviderContainer container})> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefsSeed = const {'language': 'system'},
}) async {
  SharedPreferences.setMockInitialValues(prefsSeed);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.forTesting();
  addTearDown(db.close);

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: prefs),
      ),
      seedAllUseCaseProvider.overrideWithValue(_NoopSeedAllUseCase()),
      deviceIdentityRepositoryProvider.overrideWithValue(
        _FakeDeviceIdentityRepository(),
      ),
      syncEngineProvider.overrideWithValue(_FakeSyncEngine()),
      syncStatusStreamProvider.overrideWith((_) => const Stream.empty()),
      activeGroupProvider.overrideWith((_) => Stream.value(null)),
      pushNotificationServiceProvider.overrideWithValue(
        _FakePushNotificationService(),
      ),
      familySyncNotificationNavigationProvider.overrideWith(
        (ref) => FamilySyncNotificationNavigationController(
          _FakeListenToPushNotificationsUseCase(),
        ),
      ),
      getUserProfileUseCaseProvider.overrideWithValue(
        _FakeGetUserProfileUseCase(),
      ),
      saveUserProfileUseCaseProvider.overrideWith(
        (_) => SaveUserProfileUseCase(_FakeUserProfileRepository()),
      ),
      currentLocaleProvider.overrideWith(
        (ref) => Future.value(const Locale('ja')),
      ),
      secureStorageServiceProvider.overrideWithValue(
        _FakeSecureStorageService(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ja'), Locale('en'), Locale('zh')],
        home: app.HomePocketApp(),
      ),
    ),
  );
  await _pumpBounded(tester);
  return (prefs: prefs, container: container);
}

/// Bounded pump that flushes async futures without waiting on the List tab's
/// perpetual loading spinner (IndexedStack builds every tab eagerly).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _shellBookId(WidgetTester tester) =>
    tester.widget<MainShellScreen>(find.byType(MainShellScreen)).bookId;

/// Drives the real intro → settings → (nickname) → confirm → lock-entry → skip
/// path to completion. Returns the boot bookId captured from the gate.
Future<String> _completeOnboarding(WidgetTester tester) async {
  expect(find.byType(OnboardingFlowScreen), findsOneWidget);
  final bootBookId = tester
      .widget<OnboardingFlowScreen>(find.byType(OnboardingFlowScreen))
      .bookId;

  // intro → settings (スキップ collapses to onContinue, D-02)
  await tester.tap(find.widgetWithText(TextButton, 'スキップ').first);
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingSettingsScreen), findsOneWidget);

  // settings: nickname required (inline TextField), then confirm → lock-entry
  await tester.enterText(find.byType(TextField).first, 'たけし');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'この設定ではじめる'));
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingLockEntryScreen), findsOneWidget);

  // lock-entry skip → completion (writes onboarding_complete LAST).
  await tester.tap(find.widgetWithText(TextButton, 'スキップ'));
  await _pumpBounded(tester);

  return bootBookId;
}

Future<void> _flushAndUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('HI-01: onboarding completion keeps the boot gate live', () {
    testWidgets(
      'import-backup after same-session onboarding re-points the shell to the '
      'NEW bookId (gate not detached)',
      (tester) async {
        final h = await _pumpApp(tester);

        final bootBookId = await _completeOnboarding(tester);

        // Onboarding finished onto the shell, still bound to the boot book.
        expect(h.prefs.getBool('onboarding_complete'), true);
        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(_shellBookId(tester), bootBookId);

        // Simulate _restoreData at the repo level: delete the boot book, insert
        // the backup's book (a different id). The flag stays true (D-06).
        final bookRepo = h.container.read(bookRepositoryProvider);
        await bookRepo.deleteAll();
        await bookRepo.insert(
          Book(
            id: 'imported-book-id',
            name: 'Imported Book',
            currency: 'JPY',
            deviceId: 'device-test',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        // Fire the global reset signal — exactly what import-backup does.
        h.container.read(dataResetSignalProvider.notifier).fire();
        await _pumpBounded(tester);

        // The displayed shell followed the imported book WITHOUT a restart.
        // On the pre-fix pushReplacement code the displayed route is the
        // detached shell still bound to `bootBookId`, so this fails.
        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(_shellBookId(tester), 'imported-book-id');
        expect(_shellBookId(tester), isNot(bootBookId));

        await _flushAndUnmount(tester);
      },
    );

    testWidgets('delete-all after same-session onboarding returns the gate to '
        'OnboardingFlowScreen (D-05, gate not detached)', (tester) async {
      final h = await _pumpApp(tester);

      await _completeOnboarding(tester);
      expect(h.prefs.getBool('onboarding_complete'), true);
      expect(find.byType(MainShellScreen), findsOneWidget);

      // Simulate clear-all: clears identity + flag and wipes the books.
      await h.prefs.setBool('onboarding_complete', false);
      final bookRepo = h.container.read(bookRepositoryProvider);
      await bookRepo.deleteAll();

      // Fire the global reset signal — exactly what clear-all does.
      h.container.read(dataResetSignalProvider.notifier).fire();
      await _pumpBounded(tester);

      // D-05: the gate re-evaluates to onboarding WITHOUT a restart. On the
      // pre-fix code the detached shell stays displayed, so OnboardingFlow
      // is never re-rendered.
      expect(find.byType(OnboardingFlowScreen), findsOneWidget);
      expect(find.byType(MainShellScreen), findsNothing);

      await _flushAndUnmount(tester);
    });
  });
}
