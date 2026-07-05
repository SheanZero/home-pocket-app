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
import 'features/accounting/presentation/providers/repository_providers.dart'
    show ensureDefaultBookUseCaseProvider, seedAllUseCaseProvider;
import 'features/family_sync/presentation/providers/repository_providers.dart';
import 'features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'features/family_sync/presentation/providers/state_sync.dart'
    show syncEngineProvider;
import 'features/applock/presentation/screens/app_lock_screen.dart';
import 'features/applock/presentation/widgets/privacy_mask.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'features/settings/domain/models/app_settings.dart';
import 'features/settings/presentation/providers/repository_providers.dart'
    show settingsRepositoryProvider, sharedPreferencesProvider;
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/providers/state_locale.dart';
import 'features/settings/presentation/providers/state_settings.dart';
import 'generated/app_localizations.dart';
import 'infrastructure/crypto/database/encrypted_database.dart';
import 'infrastructure/security/app_lock_lifecycle_observer.dart';
import 'infrastructure/security/providers.dart'
    show secureStorageServiceProvider;
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

  /// Synchronous best-effort cache of `appLockEnabled && pinHash != null`,
  /// refreshed on every (re)initialize. The lifecycle observer's
  /// `isLockEffective` predicate must be synchronous so the privacy mask can
  /// paint in the SAME frame the app goes inactive (before the OS snapshot,
  /// RESEARCH §5) — an async provider hop would miss that frame.
  bool _lockConfigured = false;

  /// Whether biometric (Face ID / fingerprint) unlock is enabled for app-lock.
  /// Drives [AppLockScreen.startOnPinPage]: when false, the lock screen opens
  /// directly on the PIN keypad and never auto-prompts biometrics (LOCK-07) —
  /// otherwise the OS Face ID sheet would appear even though the user disabled
  /// biometric unlock. Captured on every (re)initialize alongside [_isLocked].
  bool _biometricUnlockEnabled = false;

  /// Drives the opaque [PrivacyMask] overlay. Flipped synchronously by the
  /// observer's `onMask`/`onUnmask` so the cover lands before the app-switcher
  /// snapshot (LOCK-04 / T-55-28).
  final ValueNotifier<bool> _maskVisible = ValueNotifier<bool>(false);

  /// Root lifecycle observer driving relock (LOCK-03) + mask (LOCK-04).
  /// Registered in [_initialize], torn down in [dispose].
  AppLockLifecycleObserver? _lockObserver;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _lockObserver?.dispose();
    _maskVisible.dispose();
    super.dispose();
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

        // Register the app-lock lifecycle observer alongside the sync engine's
        // own observer. `isLockEffective` reads the synchronous [_lockConfigured]
        // cache so the mask paints before the OS snapshot (RESEARCH §5); relock
        // flips the [_isLocked] gate flag via setState (never pushReplacement),
        // and the mask is driven by the synchronous [_maskVisible] notifier.
        _lockObserver ??= AppLockLifecycleObserver(
          isLockEffective: () => _lockConfigured,
          onRelock: () {
            if (mounted) setState(() => _isLocked = true);
          },
          onMask: () => _maskVisible.value = true,
          onUnmask: () => _maskVisible.value = false,
        )..start();

        // Wire push notifications → sync engine
        final pushService = ref.read(pushNotificationServiceProvider);
        syncEngine.connectPushNotifications(pushService);

        // Onboarding gate (ONBOARD-01 / D-04): read the persisted flag AFTER
        // init has settled. Captured into a field here — NEVER ref.watch in
        // build() (avoids the loading-null race at branch 3) and NEVER inferred
        // from the profile/currency.
        //
        // Pre-warm SharedPreferences before reading the *synchronous*
        // settingsRepository: it calls `.requireValue` on the async
        // sharedPreferencesProvider, so a `ref.read` here while
        // `SharedPreferences.getInstance()` is still in flight rethrows the
        // provider's transient AsyncValueIsLoadingException as a FATAL init
        // failure. On a real-device cold start getInstance() can still be loading
        // when `_seedAndEnsureDefaultBook()` returns (T-55 UAT blocker), so await
        // the future first to make the read race-free. `sharedPreferences` is a
        // clean async provider (never synchronously throws), so awaiting its
        // `.future` is safe here — unlike `appSettingsProvider.future`, which can
        // complete with the transient error.
        await ref.read(sharedPreferencesProvider.future);
        final settings = await ref
            .read(settingsRepositoryProvider)
            .getSettings();

        // App-lock cold-start gate (LOCK-02 / D-01): the lock is effective ONLY
        // when the master toggle is on AND a PIN hash exists. A half-configured
        // state (toggle on, no PIN) must never strand the user (T-55-15), so we
        // require both before showing the lock screen at boot.
        final pinHash = await ref
            .read(secureStorageServiceProvider)
            .getPinHash();
        final lockConfigured = settings.appLockEnabled && pinHash != null;

        setState(() {
          _bookId = bookIdResult.data!;
          _needsOnboarding = !settings.onboardingComplete;
          _lockConfigured = lockConfigured;
          _isLocked = lockConfigured;
          _biometricUnlockEnabled = settings.biometricUnlockEnabled;
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
        // Pre-warm sharedPreferences first for the same reason as _initialize:
        // the synchronous settingsRepository calls `.requireValue` on the async
        // prefs provider, so a bare `ref.read` could rethrow a transient loading
        // error as a fatal failure.
        await ref.read(sharedPreferencesProvider.future);
        final settings = await ref
            .read(settingsRepositoryProvider)
            .getSettings();
        // Re-evaluate the lock gate after a destructive reset for parity with
        // cold start (LOCK-02): a wipe may have cleared the PIN hash, so recompute
        // from post-reset settings + pinHash rather than carrying a stale flag.
        final pinHash = await ref
            .read(secureStorageServiceProvider)
            .getPinHash();
        final lockConfigured = settings.appLockEnabled && pinHash != null;
        if (!mounted) return;
        setState(() {
          _bookId = bookIdResult.data!;
          _needsOnboarding = !settings.onboardingComplete;
          _lockConfigured = lockConfigured;
          _isLocked = lockConfigured;
          _biometricUnlockEnabled = settings.biometricUnlockEnabled;
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
      // overflow fixed horizontal Rows (quick 260604-fyd — ceiling 1.2), then
      // host the opaque privacy mask ABOVE everything (LOCK-04). The mask is
      // driven by the synchronous [_maskVisible] notifier so it paints before
      // the OS app-switcher snapshot (RESEARCH §5 / T-55-28).
      builder: (context, child) {
        return Stack(
          children: [
            clampTextScaling(context, child),
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _maskVisible,
                builder: (context, masked, _) =>
                    masked ? const PrivacyMask() : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
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
      return AppLockScreen(
        onUnlocked: _completeUnlock,
        onBeginAuth: _lockObserver?.beginAuth,
        onEndAuth: _lockObserver?.endAuth,
        // Skip the Face ID auto-prompt when biometric unlock is disabled — open
        // straight on the PIN keypad instead of surfacing the OS sheet (LOCK-07).
        startOnPinPage: !_biometricUnlockEnabled,
      );
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
