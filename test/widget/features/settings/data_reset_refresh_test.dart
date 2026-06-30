// Integration test for the refresh-without-restart fix (260627-v0w).
//
// Reproduces the end-to-end wiring: a destructive Settings action fires
// `dataResetSignalProvider`, `_HomePocketAppState` listens and re-bootstraps a
// fresh default book + invalidates every data-provider family + setStates the
// new bookId — all WITHOUT an app restart.
//
// To keep the test deterministic and free of crypto / shared-prefs / asset
// infra, the wipe + import are simulated at the repository level (the REAL
// in-memory `bookRepository`), while the REAL `ensureDefaultBookUseCase` runs
// so the "exactly one default book, new id, no dangling reference" invariant is
// genuinely exercised. `seedAllUseCase` is stubbed to a no-op (it is
// count-guarded idempotent in production and only seeds categories/merchants,
// which this test does not assert).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/profile/get_user_profile_use_case.dart';
import 'package:home_pocket/application/seed/seed_all_use_case.dart';
import 'package:home_pocket/application/seed/seed_providers.dart';
import 'package:home_pocket/core/state/data_reset_signal.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        bookByIdProvider,
        bookRepositoryProvider,
        deviceIdentityRepositoryProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_notification_navigation.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show getUserProfileUseCaseProvider;
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart'
    show settingsRepositoryProvider;
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/main.dart' as app;
import 'package:home_pocket/shared/utils/result.dart';

import '../../../helpers/test_provider_scope.dart' show waitForFirstValue;

// ── Fakes (no codegen — plain implements / Fake) ─────────────────────────────

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

/// Settings repo whose `getSettings()` returns a fixed onboardingComplete flag.
/// This test exercises the data-reset refresh path with the app already past
/// the onboarding gate, so the flag is forced true (the boot gate reads
/// `settingsRepositoryProvider.getSettings()` directly — 54-07).
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({required this.onboardingComplete});

  final bool onboardingComplete;

  @override
  Future<AppSettings> getSettings() async =>
      AppSettings(onboardingComplete: onboardingComplete);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Drives the app-lock cold-start gate: `getPinHash()` returns null (no PIN
/// configured) so `lockConfigured` is always false and the lock gate is inert.
class _FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<String?> getPinHash() async => null;
}

final _testProfile = UserProfile(
  id: 'profile-1',
  displayName: 'Tester',
  avatarEmoji: '🏠',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

/// Pumps a bounded number of frames so async init / re-bootstrap resolves
/// without waiting on the perpetual List-tab spinner (IndexedStack eagerly
/// builds every tab, so `pumpAndSettle` would time out — see
/// main_characterization_smoke_test.dart).
Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _shellBookId(WidgetTester tester) =>
    tester.widget<MainShellScreen>(find.byType(MainShellScreen)).bookId;

void main() {
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appSettingsProvider.overrideWith(
          (ref) => Future.value(const AppSettings()),
        ),
        currentLocaleProvider.overrideWith(
          (ref) => Future.value(const Locale('ja')),
        ),
        seedAllUseCaseProvider.overrideWithValue(_NoopSeedAllUseCase()),
        deviceIdentityRepositoryProvider.overrideWithValue(
          _FakeDeviceIdentityRepository(),
        ),
        syncEngineProvider.overrideWithValue(_FakeSyncEngine()),
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
        settingsRepositoryProvider.overrideWith(
          (ref) => _FakeSettingsRepository(onboardingComplete: true),
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
  }

  testWidgets(
    'delete-all: fires signal → fresh default book, new bookId, empty data, '
    'no dangling reference, without restart',
    (tester) async {
      await pumpApp(tester);

      // Booted onto the shell with the initial default book (book-A).
      expect(find.byType(MainShellScreen), findsOneWidget);
      final bookRepo = container.read(bookRepositoryProvider);
      var books = await bookRepo.findAll();
      expect(books, hasLength(1));
      final bookA = books.first.id;
      expect(_shellBookId(tester), bookA);

      // Cache bookByIdProvider(book-A) so we can prove the stale cache is
      // released after the reset (this family is NOT re-keyed by a new bookId).
      final cachedA = await waitForFirstValue(
        container,
        bookByIdProvider(bookId: bookA),
      );
      expect(cachedA.value?.id, bookA);

      // Simulate the clear-all wipe at the repository level (deletes only — no
      // crypto / shared-prefs infra needed).
      await bookRepo.deleteAll();
      expect(await bookRepo.findAll(), isEmpty);

      // Fire the global reset signal — exactly what DataManagementSection does
      // on clear-all success.
      container.read(dataResetSignalProvider.notifier).fire();
      await _pumpBounded(tester);

      // Re-bootstrap minted exactly one fresh default book with a NEW id.
      books = await bookRepo.findAll();
      expect(books, hasLength(1), reason: 'exactly one default book post-wipe');
      final bookB = books.first.id;
      expect(bookB, isNot(bookA), reason: 'a fresh book id is minted');

      // The threaded bookId followed the new book (no dangling reference).
      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(_shellBookId(tester), bookB);

      // Whole-family invalidation released the stale book-A cache.
      final afterA = await waitForFirstValue(
        container,
        bookByIdProvider(bookId: bookA),
      );
      expect(afterA.value, isNull, reason: 'stale book-A cache released');

      // The re-keyed today family fetches empty for the new book.
      final todayB = await waitForFirstValue(
        container,
        todayTransactionsProvider(bookId: bookB),
      );
      expect(todayB.value, isEmpty);
    },
  );

  testWidgets(
    'import: fires signal → imported book becomes active, no duplicate default '
    'book, bookId re-pointed, without restart',
    (tester) async {
      await pumpApp(tester);

      final bookRepo = container.read(bookRepositoryProvider);
      final bookA = (await bookRepo.findAll()).first.id;
      expect(_shellBookId(tester), bookA);

      // Simulate _restoreData: delete existing books then insert the backup's
      // book (a different id), mirroring import-backup.
      await bookRepo.deleteAll();
      final importedBook = Book(
        id: 'imported-book-id',
        name: 'Imported Book',
        currency: 'JPY',
        deviceId: 'device-test',
        createdAt: DateTime(2026, 1, 1),
      );
      await bookRepo.insert(importedBook);

      // Fire the signal — exactly what DataManagementSection does on import
      // success.
      container.read(dataResetSignalProvider.notifier).fire();
      await _pumpBounded(tester);

      // ensureDefaultBook saw a non-empty table → returned the imported book;
      // NO duplicate default book was created.
      final books = await bookRepo.findAll();
      expect(books, hasLength(1), reason: 'no duplicate default book');
      expect(books.first.id, 'imported-book-id');

      // The shell now points at the imported book (≠ the pre-import book-A).
      expect(_shellBookId(tester), 'imported-book-id');
      expect(_shellBookId(tester), isNot(bookA));
    },
  );
}
