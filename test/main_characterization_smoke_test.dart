// Smoke characterization test for lib/main.dart's _HomePocketApp shell.
//
// Per CRIT-05 D-15 strict + RESEARCH.md Q2 recommendation: even though
// main.dart is mostly UI scaffolding, write a smoke testWidgets covering
// the _initialized=true and _error != null observable branches in
// _HomePocketAppState._buildHome. Plan 03-02 Task 6's _InitFailureApp
// widget test complements this characterization (the InitFailureApp
// wrapper is the new failure-shell; HomePocketApp is the success-path shell).
//
// Approach: rather than call runApp() (which requires SQLCipher native +
// flutter_secure_storage), we pump HomePocketApp inside an
// UncontrolledProviderScope with overrides that bypass all real
// dependencies. Each use-case provider is replaced with an overrideWith()
// returning a hand-written stub that drives _initialize() to the desired
// terminal state.
//
// Branches covered:
//   (1) _error != null                → error Scaffold + AppBar
//   (2) !_initialized                 → CircularProgressIndicator
//   (3) _initialized + onboardingComplete=false → OnboardingFlowScreen
//   (4) _initialized + onboardingComplete=true  → MainShellScreen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/profile/get_user_profile_use_case.dart';
import 'package:home_pocket/core/initialization/app_initializer.dart';
import 'package:home_pocket/core/initialization/init_failure_screen.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show seedCategoriesUseCaseProvider, ensureDefaultBookUseCaseProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_notification_navigation.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/applock/presentation/screens/app_lock_screen.dart';
import 'package:home_pocket/features/applock/presentation/widgets/privacy_mask.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show getUserProfileUseCaseProvider;
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart'
    show settingsRepositoryProvider, sharedPreferencesProvider;
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/models/auth_result.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/main.dart' as app;
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Hand-written fake use cases (no Mockito codegen — CONTEXT.md deferred).

class _FakeSeedCategoriesUseCase extends Fake implements SeedCategoriesUseCase {
  @override
  Future<Result<void>> execute() async => Result.success(null);
}

class _ThrowingSeedCategoriesUseCase extends Fake
    implements SeedCategoriesUseCase {
  @override
  Future<Result<void>> execute() async => throw StateError('seed failed');
}

class _FakeEnsureDefaultBookUseCase extends Fake
    implements EnsureDefaultBookUseCase {
  final Book _book;
  _FakeEnsureDefaultBookUseCase(this._book);

  @override
  Future<Result<Book>> execute() async => Result.success(_book);
}

class _FailEnsureDefaultBookUseCase extends Fake
    implements EnsureDefaultBookUseCase {
  @override
  Future<Result<Book>> execute() async => Result.error('db init failed');
}

class _FakeSyncEngine extends Mock implements SyncEngine {
  @override
  void initialize() {}

  @override
  void connectPushNotifications(PushNotificationService pushService) {}

  @override
  void dispose() {}
}

class _FakePushNotificationService extends Mock
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

class _FakeMasterKeyRepository extends Mock implements MasterKeyRepository {}

class _FakeKeyRepository extends Mock implements KeyRepository {}

class _FakeGetUserProfileUseCase extends Fake implements GetUserProfileUseCase {
  final UserProfile? _profile;
  _FakeGetUserProfileUseCase(this._profile);

  @override
  Future<UserProfile?> execute() async => _profile;
}

/// Drives the onboarding + app-lock gates: `getSettings()` returns the fixed
/// `onboardingComplete` / `appLockEnabled` flags the gate reads after init settle.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({
    required this.onboardingComplete,
    this.appLockEnabled = false,
    this.biometricUnlockEnabled = false,
  });

  final bool onboardingComplete;
  final bool appLockEnabled;
  final bool biometricUnlockEnabled;

  @override
  Future<AppSettings> getSettings() async => AppSettings(
    onboardingComplete: onboardingComplete,
    appLockEnabled: appLockEnabled,
    biometricUnlockEnabled: biometricUnlockEnabled,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Drives the app-lock cold-start gate: `getPinHash()` returns the fixed hash
/// (null = no PIN configured → lock can never be effective, T-55-15).
class _FakeSecureStorageService extends Fake implements SecureStorageService {
  _FakeSecureStorageService({this.pinHash});

  final String? pinHash;

  @override
  Future<String?> getPinHash() async => pinHash;
}

/// Biometric stub whose first `authenticate` succeeds (auto-unlock at boot) and
/// every subsequent call drops to the PIN page — so after a lifecycle relock the
/// [AppLockScreen] stays visible instead of instantly re-unlocking.
class _OnceSuccessBiometricService extends Fake implements BiometricService {
  int _calls = 0;

  @override
  Future<AuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    _calls++;
    return _calls == 1
        ? const AuthResult.success()
        : const AuthResult.fallbackToPIN();
  }
}

/// Biometric stub that always drops to the PIN page (never auto-unlocks) — used
/// for the cold-start lock-on case so the [AppLockScreen] remains visible.
class _FallbackBiometricService extends Fake implements BiometricService {
  @override
  Future<AuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async => const AuthResult.fallbackToPIN();
}

/// Biometric spy that counts `authenticate` invocations (always dropping to the
/// PIN page) — proves whether the lock screen auto-triggered biometrics at boot.
/// Used by the G4 gate: with `biometricUnlockEnabled: false` the boot must NOT
/// auto-prompt Face ID, so `authenticateCalls` stays 0.
class _SpyBiometricService extends Fake implements BiometricService {
  int authenticateCalls = 0;

  @override
  Future<AuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    authenticateCalls++;
    return const AuthResult.fallbackToPIN();
  }
}

final _testBook = Book(
  id: 'book-test-1',
  name: 'Test Book',
  currency: 'JPY',
  deviceId: 'device-1',
  createdAt: DateTime(2026, 1, 1),
);

final _testProfile = UserProfile(
  id: 'profile-1',
  displayName: 'Tester',
  avatarEmoji: '🏠',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pumpApp(
  WidgetTester tester, {
  required List<Override> overrides,
  AppSettings appSettings = const AppSettings(),
  bool onboardingComplete = true,
  bool appLockEnabled = false,
  bool biometricUnlockEnabled = false,
  String? pinHash,
  BiometricService? biometric,
  // When true, DO NOT stub appSettings/settingsRepository — exercise the real
  // sharedPreferences → settingsRepository → appSettings chain so the boot path's
  // `.requireValue`-on-async-prefs race is actually reproduced (T-55 regression).
  // `prefsDelay` keeps sharedPreferences in AsyncLoading long enough that the
  // gate's `ref.read(settingsRepositoryProvider)` observes it mid-flight.
  bool realSettingsChain = false,
  Duration prefsDelay = Duration.zero,
}) async {
  // _initialize() now pre-warms sharedPreferences.future before the gate read,
  // so even fake-settings tests must stub the prefs plugin (the settingsRepository
  // fake used to short-circuit it). realSettingsChain tests seed their own values.
  if (!realSettingsChain) {
    SharedPreferences.setMockInitialValues(const {});
  }

  final db = AppDatabase.forTesting();
  addTearDown(db.close);

  final fakePushService = _FakePushNotificationService();
  final fakeListenUseCase = _FakeListenToPushNotificationsUseCase();

  final baseOverrides = [
    appDatabaseProvider.overrideWithValue(db),
    if (!realSettingsChain) ...[
      appSettingsProvider.overrideWith((ref) => Future.value(appSettings)),
      // The gate reads settingsRepositoryProvider.getSettings() directly (not
      // appSettingsProvider) after init settle — drive it explicitly.
      settingsRepositoryProvider.overrideWith(
        (ref) => _FakeSettingsRepository(
          onboardingComplete: onboardingComplete,
          appLockEnabled: appLockEnabled,
          biometricUnlockEnabled: biometricUnlockEnabled,
        ),
      ),
      // _initialize pre-warms sharedPreferences.future; hand it a resolved
      // instance so these tests never touch the real prefs plugin.
      sharedPreferencesProvider.overrideWith(
        (ref) => SharedPreferences.getInstance(),
      ),
    ],
    if (realSettingsChain)
      // Real settingsRepository reads this; delay it to simulate the slow
      // real-device cold-start getInstance() the boot race depends on.
      sharedPreferencesProvider.overrideWith((ref) async {
        if (prefsDelay > Duration.zero) {
          await Future<void>.delayed(prefsDelay);
        }
        return SharedPreferences.getInstance();
      }),
    // App-lock cold-start gate reads secureStorageServiceProvider.getPinHash()
    // and the lock screen auto-triggers biometricServiceProvider — stub both so
    // tests never hit a real keychain / platform channel.
    secureStorageServiceProvider.overrideWithValue(
      _FakeSecureStorageService(pinHash: pinHash),
    ),
    biometricServiceProvider.overrideWithValue(
      biometric ?? _FallbackBiometricService(),
    ),
    currentLocaleProvider.overrideWith(
      (ref) => Future.value(const Locale('ja')),
    ),
    pushNotificationServiceProvider.overrideWithValue(fakePushService),
    familySyncNotificationNavigationProvider.overrideWith(
      (ref) => FamilySyncNotificationNavigationController(fakeListenUseCase),
    ),
    ...overrides,
  ];

  final container = ProviderContainer(overrides: baseOverrides);
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
}

/// Pumps a bounded number of frames to let async app initialization resolve
/// without waiting on the List tab's loading [CircularProgressIndicator].
///
/// Phase 26 replaced the static List-tab placeholder with [ListScreen], whose
/// loading state shows a spinner that animates indefinitely while
/// `listTransactionsProvider` is unresolved. Because `MainShellScreen` builds
/// every tab eagerly inside an `IndexedStack`, that perpetual animation makes
/// [WidgetTester.pumpAndSettle] time out. These characterization tests only
/// assert structural facts (which screen renders, the theme mode), so a bounded
/// pump that flushes the initialization futures is sufficient and correct.
Future<void> _pumpInitNoSettle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  final fakeSyncEngine = _FakeSyncEngine();

  List<Override> buildSuccessOverrides({
    required UserProfile? profile,
    EnsureDefaultBookUseCase? bookUseCase,
  }) {
    return [
      seedCategoriesUseCaseProvider.overrideWithValue(
        _FakeSeedCategoriesUseCase(),
      ),
      ensureDefaultBookUseCaseProvider.overrideWithValue(
        bookUseCase ?? _FakeEnsureDefaultBookUseCase(_testBook),
      ),
      syncEngineProvider.overrideWithValue(fakeSyncEngine),
      getUserProfileUseCaseProvider.overrideWithValue(
        _FakeGetUserProfileUseCase(profile),
      ),
    ];
  }

  group('HomePocketApp smoke characterization (pre-Plan-03-02)', () {
    testWidgets(
      '_buildHome shows CircularProgressIndicator while initializing',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
        );
        // Before pumpAndSettle: _initialize() is async, loading state visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      '_buildHome shows MainShellScreen when initialized with existing profile',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
        );
        await _pumpInitNoSettle(tester);
        expect(find.byType(MainShellScreen), findsOneWidget);
      },
    );

    testWidgets(
      '_buildHome shows OnboardingFlowScreen when onboardingComplete is false',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: null),
          onboardingComplete: false,
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(OnboardingFlowScreen), findsOneWidget);
        expect(find.byType(MainShellScreen), findsNothing);
      },
    );

    testWidgets(
      '_buildHome shows MainShellScreen when onboardingComplete is true',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: null),
          onboardingComplete: true,
        );
        await _pumpInitNoSettle(tester);
        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(find.byType(OnboardingFlowScreen), findsNothing);
      },
    );

    testWidgets(
      '_buildHome shows error Scaffold when ensureDefaultBook returns error',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(
            profile: _testProfile,
            bookUseCase: _FailEnsureDefaultBookUseCase(),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        // Error path renders Scaffold with error AppBar
        expect(find.byType(Scaffold), findsWidgets);
        expect(find.byType(AppBar), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('_initialize catch branch shows initialization error', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        overrides: [
          seedCategoriesUseCaseProvider.overrideWithValue(
            _ThrowingSeedCategoriesUseCase(),
          ),
          ensureDefaultBookUseCaseProvider.overrideWithValue(
            _FakeEnsureDefaultBookUseCase(_testBook),
          ),
          syncEngineProvider.overrideWithValue(fakeSyncEngine),
          getUserProfileUseCaseProvider.overrideWithValue(
            _FakeGetUserProfileUseCase(_testProfile),
          ),
        ],
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(AppBar), findsAtLeastNWidgets(1));
      expect(find.textContaining('seed failed'), findsOneWidget);
    });

    testWidgets('uses explicit light Flutter theme mode', (tester) async {
      await _pumpApp(
        tester,
        appSettings: const AppSettings(themeMode: AppThemeMode.light),
        overrides: [...buildSuccessOverrides(profile: _testProfile)],
      );
      await _pumpInitNoSettle(tester);
      expect(
        tester.widgetList<MaterialApp>(find.byType(MaterialApp)).last.themeMode,
        ThemeMode.light,
      );
    });

    testWidgets('uses explicit dark Flutter theme mode', (tester) async {
      await _pumpApp(
        tester,
        appSettings: const AppSettings(themeMode: AppThemeMode.dark),
        overrides: [...buildSuccessOverrides(profile: _testProfile)],
      );
      await _pumpInitNoSettle(tester);
      expect(
        tester.widgetList<MaterialApp>(find.byType(MaterialApp)).last.themeMode,
        ThemeMode.dark,
      );
    });

    test('boot helper runs success and failure shells', () async {
      final fakeMasterKeyRepo = _FakeMasterKeyRepository();
      final fakeKeyRepo = _FakeKeyRepository();
      when(
        () => fakeMasterKeyRepo.hasMasterKey(),
      ).thenAnswer((_) async => true);
      when(
        () => fakeMasterKeyRepo.initializeMasterKey(),
      ).thenAnswer((_) async {});
      when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
      when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(() => fakeKeyRepo.generateKeyPair()).thenAnswer(
        (_) async => DeviceKeyPair(
          deviceId: 'device-1',
          publicKey: 'pubkey',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      ProviderContainer? finalContainer;
      addTearDown(() {
        finalContainer?.dispose();
      });

      AppInitializer makeInitializer({bool failDatabase = false}) {
        return AppInitializer(
          containerFactory: ({overrides = const []}) {
            final container = ProviderContainer(
              overrides: [
                masterKeyRepositoryProvider.overrideWithValue(
                  fakeMasterKeyRepo,
                ),
                keyRepositoryProvider.overrideWithValue(fakeKeyRepo),
                seedCategoriesUseCaseProvider.overrideWithValue(
                  _FakeSeedCategoriesUseCase(),
                ),
                ensureDefaultBookUseCaseProvider.overrideWithValue(
                  _FakeEnsureDefaultBookUseCase(_testBook),
                ),
                syncEngineProvider.overrideWithValue(fakeSyncEngine),
                getUserProfileUseCaseProvider.overrideWithValue(
                  _FakeGetUserProfileUseCase(_testProfile),
                ),
                pushNotificationServiceProvider.overrideWithValue(
                  _FakePushNotificationService(),
                ),
                appSettingsProvider.overrideWith(
                  (ref) => Future.value(const AppSettings()),
                ),
                settingsRepositoryProvider.overrideWith(
                  (ref) => _FakeSettingsRepository(onboardingComplete: true),
                ),
                currentLocaleProvider.overrideWith(
                  (ref) => Future.value(const Locale('ja')),
                ),
                ...overrides,
              ],
            );
            if (overrides.isNotEmpty) {
              finalContainer = container;
            }
            return container;
          },
          databaseFactory: (_) async {
            if (failDatabase) {
              throw StateError('database failed');
            }
            return AppDatabase.forTesting();
          },
          databaseExists: () async => false,
          seedRunner: (_) async {},
        );
      }

      final rendered = <Widget>[];
      await app.bootWithInitializerForTesting(
        makeInitializer(),
        appRunner: rendered.add,
      );
      expect(rendered.single, isA<UncontrolledProviderScope>());

      finalContainer?.dispose();
      finalContainer = null;
      await app.bootWithInitializerForTesting(
        makeInitializer(failDatabase: true),
        appRunner: rendered.add,
      );
      expect(rendered.last, isA<InitFailureApp>());
    });
  });

  group('HomePocketApp app-lock gate wiring (Plan 55-11)', () {
    testWidgets(
      'LOCK-01 no-op: lock disabled renders the shell with no lock screen or mask',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
          // appLockEnabled defaults false; even a stray pinHash must not lock.
          pinHash: 'argon2-phc-should-be-ignored',
        );
        await _pumpInitNoSettle(tester);
        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(find.byType(AppLockScreen), findsNothing);
        expect(find.byType(PrivacyMask), findsNothing);
      },
    );

    testWidgets(
      'LOCK-02 cold start: lockEffective shows AppLockScreen before the shell',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
          appLockEnabled: true,
          pinHash: 'argon2-phc',
          // Stays on the lock surface (never auto-unlocks) so the gate is observable.
          biometric: _FallbackBiometricService(),
        );
        await _pumpInitNoSettle(tester);
        expect(find.byType(AppLockScreen), findsOneWidget);
        expect(find.byType(MainShellScreen), findsNothing);
      },
    );

    testWidgets(
      'LOCK-03 relock: a true background round-trip re-shows the lock screen',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
          appLockEnabled: true,
          pinHash: 'argon2-phc',
          // Biometric unlock ON so the boot auto-prompt fires (G4 gate).
          biometricUnlockEnabled: true,
          // First biometric auto-unlocks (→ shell); after relock it drops to PIN
          // so the re-shown AppLockScreen stays visible.
          biometric: _OnceSuccessBiometricService(),
        );
        await _pumpInitNoSettle(tester);
        // Boot locked → auto-biometric success → shell.
        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(find.byType(AppLockScreen), findsNothing);

        // True background round-trip (inactive → paused → resumed).
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _pumpInitNoSettle(tester);

        expect(find.byType(AppLockScreen), findsOneWidget);
      },
    );

    testWidgets(
      'G4 biometric OFF: lock screen starts on PIN, never auto-prompts Face ID',
      (tester) async {
        final spy = _SpyBiometricService();
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
          appLockEnabled: true,
          pinHash: 'argon2-phc',
          // 生物识别解锁 OFF — the boot lock screen must go straight to the app's
          // OWN PIN keypad and must NOT invoke the biometric prompt.
          biometricUnlockEnabled: false,
          biometric: spy,
        );
        await _pumpInitNoSettle(tester);
        expect(find.byType(AppLockScreen), findsOneWidget);
        // PIN surface is showing (its 忘记PIN control is unique to the PIN page).
        expect(
          find.byKey(const ValueKey('app-lock-forgot-pin')),
          findsOneWidget,
        );
        // The critical invariant: no auto Face ID prompt when biometric is off.
        expect(spy.authenticateCalls, 0);
      },
    );

    testWidgets(
      'G4 biometric ON: boot lock screen auto-prompts Face ID once',
      (tester) async {
        final spy = _SpyBiometricService();
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
          appLockEnabled: true,
          pinHash: 'argon2-phc',
          biometricUnlockEnabled: true,
          biometric: spy,
        );
        await _pumpInitNoSettle(tester);
        expect(find.byType(AppLockScreen), findsOneWidget);
        // Biometric ON → the Face ID auto-prompt fires exactly once at boot.
        expect(spy.authenticateCalls, 1);
        // Still on the Face ID surface (spy fell back to PIN), so the PIN page's
        // 忘记PIN control is NOT yet shown.
        expect(
          find.byKey(const ValueKey('app-lock-forgot-pin')),
          findsNothing,
        );
      },
    );
  });

  group('HomePocketApp cold-start SharedPreferences race (T-55 UAT blocker)', () {
    testWidgets(
      'boot survives sharedPreferences still loading when the gate reads settings',
      (tester) async {
        // Real settingsRepository chain: getSettings() reads real prefs, so seed
        // onboarding_complete=true to route past onboarding to the shell.
        SharedPreferences.setMockInitialValues({'onboarding_complete': true});

        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: _testProfile),
          // Exercise the real sharedPreferences → settingsRepository chain, and
          // keep prefs in AsyncLoading past the point _initialize() reaches the
          // synchronous `ref.read(settingsRepositoryProvider)` gate read. Before
          // the fix this rethrows AsyncValueIsLoadingException as a fatal init
          // failure (「初期化に失敗」screen); after the fix _initialize pre-warms
          // sharedPreferences.future first, so the read is race-free.
          realSettingsChain: true,
          prefsDelay: const Duration(milliseconds: 120),
        );
        await _pumpInitNoSettle(tester);

        // Reaches the shell — no init-failure error screen.
        expect(find.byType(MainShellScreen), findsOneWidget);
        expect(find.byType(OnboardingFlowScreen), findsNothing);
      },
    );
  });
}
