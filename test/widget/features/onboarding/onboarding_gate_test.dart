// VALIDATION ONBOARD-01: the main.dart boot gate reads the persisted
// `onboardingComplete` flag (captured AFTER init settle, never ref.watch in
// build, never inferred from profile/currency) to decide between the
// onboarding flow and the shell.
//
//   onboardingComplete == true  → MainShellScreen (no onboarding)
//   onboardingComplete == false → OnboardingFlowScreen
//
// Mirrors main_characterization_smoke_test's override harness but drives the
// decision purely through settingsRepositoryProvider.getSettings().

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show seedCategoriesUseCaseProvider, ensureDefaultBookUseCaseProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_notification_navigation.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/main.dart' as app;
import 'package:home_pocket/shared/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSeedCategoriesUseCase extends Fake implements SeedCategoriesUseCase {
  @override
  Future<Result<void>> execute() async => Result.success(null);
}

class _FakeEnsureDefaultBookUseCase extends Fake
    implements EnsureDefaultBookUseCase {
  final Book _book;
  _FakeEnsureDefaultBookUseCase(this._book);

  @override
  Future<Result<Book>> execute() async => Result.success(_book);
}

class _FakeSyncEngine implements SyncEngine {
  @override
  void initialize() {}

  @override
  void connectPushNotifications(PushNotificationService pushService) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePushNotificationService implements PushNotificationService {
  final _navController = StreamController<PushNavigationIntent>.broadcast();

  @override
  PushNavigationIntent? takePendingNavigationIntent() => null;

  @override
  Stream<PushNavigationIntent> get navigationIntents => _navController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeListenToPushNotificationsUseCase extends Fake
    implements ListenToPushNotificationsUseCase {
  final _navController = StreamController<PushNavigationIntent>.broadcast();

  @override
  Stream<PushNavigationIntent> execute() => _navController.stream;

  @override
  PushNavigationIntent? takePendingIntent() => null;
}

/// Settings repo whose `getSettings()` returns a fixed onboardingComplete flag.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({required this.onboardingComplete});

  final bool onboardingComplete;

  @override
  Future<AppSettings> getSettings() async =>
      AppSettings(onboardingComplete: onboardingComplete);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Drives the app-lock cold-start gate: `getPinHash()` returns null (no PIN
/// configured) so `lockConfigured` is always false and the lock gate is inert.
class _FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<String?> getPinHash() async => null;
}

final _testBook = Book(
  id: 'book-test-1',
  name: 'Test Book',
  currency: 'JPY',
  deviceId: 'device-1',
  createdAt: DateTime(2026, 1, 1),
);

Future<AppDatabase> _pumpGate(
  WidgetTester tester, {
  required bool onboardingComplete,
}) async {
  // _initialize() pre-warms sharedPreferences.future before reading the gate; the
  // settingsRepository override supplies the flag, but the prefs plugin must still
  // resolve so the pre-warm doesn't fail.
  SharedPreferences.setMockInitialValues(const {});

  final db = AppDatabase.forTesting();
  addTearDown(db.close);
  final fakePushService = _FakePushNotificationService();
  final fakeListenUseCase = _FakeListenToPushNotificationsUseCase();

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      seedCategoriesUseCaseProvider.overrideWithValue(
        _FakeSeedCategoriesUseCase(),
      ),
      ensureDefaultBookUseCaseProvider.overrideWithValue(
        _FakeEnsureDefaultBookUseCase(_testBook),
      ),
      syncEngineProvider.overrideWithValue(_FakeSyncEngine()),
      syncStatusStreamProvider.overrideWith((_) => const Stream.empty()),
      activeGroupProvider.overrideWith((_) => Stream.value(null)),
      settingsRepositoryProvider.overrideWith(
        (_) => _FakeSettingsRepository(onboardingComplete: onboardingComplete),
      ),
      currentLocaleProvider.overrideWith(
        (ref) => Future.value(const Locale('ja')),
      ),
      pushNotificationServiceProvider.overrideWithValue(fakePushService),
      familySyncNotificationNavigationProvider.overrideWith(
        (ref) => FamilySyncNotificationNavigationController(fakeListenUseCase),
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
  return db;
}

Future<void> _pumpInitNoSettle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('main.dart onboarding gate — ONBOARD-01 / D-04', () {
    testWidgets(
      'onboardingComplete == false → OnboardingFlowScreen (not the shell)',
      (tester) async {
        await _pumpGate(tester, onboardingComplete: false);
        await _pumpInitNoSettle(tester);

        expect(find.byType(OnboardingFlowScreen), findsOneWidget);
        expect(find.byType(MainShellScreen), findsNothing);
      },
    );

    testWidgets(
      'onboardingComplete == true → MainShellScreen (no onboarding)',
      (tester) async {
        await _pumpGate(tester, onboardingComplete: true);
        await _pumpInitNoSettle(tester);

        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(find.byType(OnboardingFlowScreen), findsNothing);

        // Flush MainShellScreen's Drift stream dispose-timers before teardown.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
