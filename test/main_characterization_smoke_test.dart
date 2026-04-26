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
//   (3) _initialized + needs onboarding → ProfileOnboardingScreen
//   (4) _initialized + no onboarding → MainShellScreen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/profile/get_user_profile_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show seedCategoriesUseCaseProvider, ensureDefaultBookUseCaseProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_notification_navigation.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:home_pocket/features/profile/presentation/screens/profile_onboarding_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/features/settings/presentation/providers/settings_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/main.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

// Hand-written fake use cases (no Mockito codegen — CONTEXT.md deferred).

class _FakeSeedCategoriesUseCase extends Fake
    implements SeedCategoriesUseCase {
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
  Stream<PushNavigationIntent> get navigationIntents =>
      _navController.stream;
}

class _FakeListenToPushNotificationsUseCase extends Fake
    implements ListenToPushNotificationsUseCase {
  final _navController = StreamController<PushNavigationIntent>.broadcast();

  @override
  Stream<PushNavigationIntent> execute() => _navController.stream;

  @override
  PushNavigationIntent? takePendingIntent() => null;
}

class _FakeGetUserProfileUseCase extends Fake
    implements GetUserProfileUseCase {
  final UserProfile? _profile;
  _FakeGetUserProfileUseCase(this._profile);

  @override
  Future<UserProfile?> execute() async => _profile;
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
}) async {
  final db = AppDatabase.forTesting();
  addTearDown(db.close);

  final fakePushService = _FakePushNotificationService();
  final fakeListenUseCase = _FakeListenToPushNotificationsUseCase();

  final baseOverrides = [
    appDatabaseProvider.overrideWithValue(db),
    appSettingsProvider.overrideWith(
      (ref) => Future.value(const AppSettings()),
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
        home: HomePocketApp(),
      ),
    ),
  );
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
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(MainShellScreen), findsOneWidget);
      },
    );

    testWidgets(
      '_buildHome shows ProfileOnboardingScreen when profile is null',
      (tester) async {
        await _pumpApp(
          tester,
          overrides: buildSuccessOverrides(profile: null),
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(ProfileOnboardingScreen), findsOneWidget);
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
  });
}
