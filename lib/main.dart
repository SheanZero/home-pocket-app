import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/initialization/app_initializer.dart';
import 'core/initialization/init_failure_screen.dart';
import 'core/initialization/init_result.dart';
import 'core/state/data_reset_signal.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_scale_clamp.dart';
import 'data/app_database.dart';
import 'application/seed/seed_providers.dart';
import 'features/accounting/presentation/providers/repository_providers.dart'
    show ensureDefaultBookUseCaseProvider;
import 'features/family_sync/presentation/providers/repository_providers.dart';
import 'features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'features/family_sync/presentation/providers/state_sync.dart'
    show syncEngineProvider;
import 'features/applock/presentation/screens/app_lock_screen.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'features/settings/domain/models/app_settings.dart';
import 'features/settings/presentation/providers/repository_providers.dart'
    show settingsRepositoryProvider;
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/providers/state_locale.dart';
import 'features/settings/presentation/providers/state_settings.dart';
import 'generated/app_localizations.dart';
import 'infrastructure/crypto/database/encrypted_database.dart';
import 'infrastructure/security/providers.dart' show secureStorageServiceProvider;
import 'shared/utils/invalidate_all_data_providers.dart';
import 'shared/utils/result.dart';

typedef AppRunner = void Function(Widget app);

/// Set to `true` for in-memory database (dev/debugging, data lost on restart).
/// Set to `false` (default) for persistent encrypted SQLCipher database.
const _useInMemoryDatabase = false;

// coverage:ignore-start
// Platform bootstrap loads native database libraries and encrypted storage.
// Tests exercise the branch logic through bootWithInitializerForTesting below.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureNativeLibrary();
  await _boot();
}

Future<void> _boot() async {
  await bootWithInitializerForTesting(_createAppInitializer());
}

AppInitializer _createAppInitializer() {
  return AppInitializer(
    containerFactory: ({overrides = const []}) =>
        ProviderContainer(overrides: overrides),
    databaseFactory: (masterKeyRepo) async {
      if (_useInMemoryDatabase) {
        return AppDatabase(NativeDatabase.memory());
      }
      final executor = await createEncryptedExecutor(masterKeyRepo);
      return AppDatabase(executor);
    },
    // Data-loss guard: never mint a new master key when an encrypted DB
    // already exists on disk (see AppInitializer / encryptedDatabaseExists).
    databaseExists: () =>
        _useInMemoryDatabase ? Future.value(false) : encryptedDatabaseExists(),
    // Seeding (categories, default book) runs inside HomePocketApp._initialize().
    seedRunner: (_) async {},
  );
}
// coverage:ignore-end

@visibleForTesting
Future<void> bootWithInitializerForTesting(
  AppInitializer initializer, {
  AppRunner appRunner = runApp,
}) async {
  final result = await initializer.initialize();

  switch (result) {
    case InitSuccess(:final container):
      appRunner(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );
    case InitFailure():
      appRunner(InitFailureApp(onRetry: _boot));
  }
}

class HomePocketApp extends ConsumerStatefulWidget {
  const HomePocketApp({super.key});

  @override
  ConsumerState<HomePocketApp> createState() => _HomePocketAppState();
}

class _HomePocketAppState extends ConsumerState<HomePocketApp> {
  /// Root navigator key — lets the gate push the post-onboarding security
  /// deep-link (D-13) on top of the live shell without the onboarding flow
  /// having to grab a `rootNavigator` itself (HI-01).
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  String? _bookId;
  bool _initialized = false;
  bool _needsOnboarding = false;
  bool _isLocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Shared seed + ensure-default-book step. Returns the active book id on
  /// success, or an error [Result] otherwise.
  ///
  /// `SeedAllUseCase` is count-guarded idempotent (Phase 23 D-14 — it owns the
  /// ordering contract), so this is safe to run both at first boot AND after a
  /// destructive data reset: it re-seeds wiped categories on the clear path and
  /// no-ops on the import path (categories already restored). `ensureDefaultBook`
  /// mints a fresh book after a wipe, or returns the imported `books.first`.
  Future<Result<String>> _seedAndEnsureDefaultBook() async {
    final seedAll = ref.read(seedAllUseCaseProvider);
    await seedAll.execute();

    final ensureBook = ref.read(ensureDefaultBookUseCaseProvider);
    final bookResult = await ensureBook.execute();
    if (bookResult.isSuccess && bookResult.data != null) {
      return Result.success(bookResult.data!.id);
    }
    return Result.error(bookResult.error ?? 'Failed to initialize');
  }

  Future<void> _initialize() async {
    try {
      final bookIdResult = await _seedAndEnsureDefaultBook();

      if (bookIdResult.isSuccess && bookIdResult.data != null) {
        // Initialize SyncEngine (lifecycle observer + status stream)
        final syncEngine = ref.read(syncEngineProvider);
        syncEngine.initialize();

        // Wire push notifications → sync engine
        final pushService = ref.read(pushNotificationServiceProvider);
        syncEngine.connectPushNotifications(pushService);

        // Onboarding gate (ONBOARD-01 / D-04): read the persisted flag AFTER
        // init has settled. Captured into a field here — NEVER ref.watch in
        // build() (avoids the loading-null race at branch 3) and NEVER inferred
        // from the profile/currency.
        final settings = await ref.read(settingsRepositoryProvider).getSettings();

        // App-lock cold-start gate (LOCK-02 / D-01): the lock is effective ONLY
        // when the master toggle is on AND a PIN hash exists. A half-configured
        // state (toggle on, no PIN) must never strand the user (T-55-15), so we
        // require both before showing the lock screen at boot.
        final pinHash = await ref.read(secureStorageServiceProvider).getPinHash();
        final lockConfigured = settings.appLockEnabled && pinHash != null;

        setState(() {
          _bookId = bookIdResult.data!;
          _needsOnboarding = !settings.onboardingComplete;
          _isLocked = lockConfigured;
          _initialized = true;
        });
      } else {
        setState(() => _error = bookIdResult.error ?? 'Failed to initialize');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Re-bootstrap after a whole-app data reset (delete-all-data / import-backup),
  /// fired via [dataResetSignalProvider]. Re-runs the shared seed+ensure-book
  /// step to obtain the NEW active book id, invalidates every data-provider
  /// family, and rebuilds the shell with the fresh bookId — all without an app
  /// restart. The sync engine is intentionally NOT re-initialized (its lifecycle
  /// observer is already registered from first boot).
  Future<void> _reinitializeAfterDataReset() async {
    if (!mounted) return;
    // Show the existing spinner while the database is re-bootstrapped.
    setState(() => _initialized = false);
    try {
      final bookIdResult = await _seedAndEnsureDefaultBook();
      if (!mounted) return;

      if (bookIdResult.isSuccess && bookIdResult.data != null) {
        invalidateAllDataProviders(ref);
        // Re-read the onboarding gate after a destructive reset (D-05/D-06):
        // delete-all clears the flag (→ onboarding) while import-backup may
        // restore it (→ shell), and both must re-evaluate without an app
        // restart. settingsRepository is plaintext SharedPreferences (not wiped
        // by the Drift data reset), so this reflects the post-reset flag.
        final settings = await ref
            .read(settingsRepositoryProvider)
            .getSettings();
        // Re-evaluate the lock gate after a destructive reset for parity with
        // cold start (LOCK-02): a wipe may have cleared the PIN hash, so recompute
        // from post-reset settings + pinHash rather than carrying a stale flag.
        final pinHash = await ref.read(secureStorageServiceProvider).getPinHash();
        final lockConfigured = settings.appLockEnabled && pinHash != null;
        if (!mounted) return;
        setState(() {
          _bookId = bookIdResult.data!;
          _needsOnboarding = !settings.onboardingComplete;
          _isLocked = lockConfigured;
          _initialized = true;
        });
      } else {
        setState(() => _error = bookIdResult.error ?? 'Failed to initialize');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-bootstrap when a destructive Settings action (clear-all / import) fires
    // the global reset signal. Side-effect → ref.listen, never ref.watch.
    ref.listen(dataResetSignalProvider, (prev, next) {
      _reinitializeAfterDataReset();
    });

    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode =
        settingsAsync.whenOrNull(
          data: (s) => _toFlutterThemeMode(s.themeMode),
        ) ??
        ThemeMode.system;
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.value ?? const Locale('ja');

    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      onGenerateTitle: (context) => S.of(context).appName,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Cap iOS/Android Dynamic Type so large accessibility font sizes don't
      // overflow fixed horizontal Rows (quick 260604-fyd — ceiling 1.2).
      builder: clampTextScaling,
      home: Builder(builder: (context) => _buildHome(context)),
    );
  }

  ThemeMode _toFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Widget _buildHome(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).error)),
        body: Center(child: Text(S.of(context).initializationError(_error!))),
      );
    }

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsOnboarding) {
      return OnboardingFlowScreen(
        bookId: _bookId!,
        onCompleted: _completeOnboarding,
      );
    }

    // App-lock gate (LOCK-02): sits AFTER onboarding and BEFORE the shell so a
    // locked cold start (or a lifecycle relock) hard-stops entry to the ledger.
    // Unlock reports back via [_completeUnlock] (a setState flag flip, never
    // pushReplacement) so the live '/' Builder keeps rendering this gate and
    // the _reinitializeAfterDataReset refresh path stays attached
    // ([[boot-gate-completion-must-flip-flag-not-pushreplacement]]).
    if (_isLocked) {
      return AppLockScreen(onUnlocked: _completeUnlock);
    }

    return MainShellScreen(bookId: _bookId!);
  }

  /// Completion handoff from [OnboardingFlowScreen] (HI-01). Flips the gate to
  /// the shell via `setState` so the live `'/'` Builder renders MainShellScreen
  /// itself — keeping the gate attached for later `_reinitializeAfterDataReset`
  /// resets. On 现在设置 (`setupSecurity: true`) deep-links to the
  /// SecuritySection on top of the freshly-rendered shell (D-13).
  /// Unlock handoff from [AppLockScreen] (LOCK-03). Mirrors [_completeOnboarding]:
  /// flips the gate flag via `setState` so the live '/' Builder renders the shell
  /// itself — NEVER `_rootNavigatorKey...pushReplacement`, which would detach the
  /// gate and break `_reinitializeAfterDataReset`
  /// ([[boot-gate-completion-must-flip-flag-not-pushreplacement]]).
  void _completeUnlock() => setState(() => _isLocked = false);

  void _completeOnboarding({required bool setupSecurity}) {
    setState(() => _needsOnboarding = false);
    if (setupSecurity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rootNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                SettingsScreen(bookId: _bookId!, scrollToSecurity: true),
          ),
        );
      });
    }
  }
}
