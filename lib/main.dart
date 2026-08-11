import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_gate_transition.dart';
import 'core/initialization/app_initializer.dart';
import 'core/initialization/init_failure_screen.dart';
import 'core/initialization/init_result.dart';
import 'core/licenses/app_license_registry.dart';
import 'core/state/data_reset_signal.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_scale_clamp.dart';
import 'data/app_database.dart';
import 'features/accounting/presentation/providers/repository_providers.dart'
    show
        deviceIdentityRepositoryProvider,
        ensureDefaultBookUseCaseProvider,
        seedAllUseCaseProvider;
import 'features/family_sync/presentation/providers/repository_providers.dart';
import 'features/family_sync/presentation/providers/state_sync.dart'
    show syncEngineProvider;
import 'features/applock/presentation/screens/app_lock_screen.dart';
import 'features/applock/presentation/widgets/privacy_mask.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'features/settings/domain/models/app_settings.dart';
import 'features/settings/presentation/providers/repository_providers.dart'
    show
        clearAllDataUseCaseProvider,
        settingsRepositoryProvider,
        sharedPreferencesProvider;
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/providers/state_locale.dart';
import 'features/settings/presentation/providers/state_settings.dart';
import 'generated/app_localizations.dart';
import 'infrastructure/crypto/database/encrypted_database.dart';
import 'infrastructure/crypto/providers.dart' as crypto;
import 'infrastructure/security/app_lock_lifecycle_observer.dart';
import 'infrastructure/security/providers.dart'
    show secureStorageServiceProvider;
import 'shared/utils/invalidate_all_data_providers.dart';
import 'shared/utils/result.dart';

typedef AppRunner = void Function(Widget app);
typedef InitFailureReporter = void Function(InitFailure failure);

void _reportInitFailure(InitFailure failure) {
  if (kDebugMode) {
    debugPrint(
      '[AppInitializer] ${failure.type.name} failed '
      '(${failure.error.runtimeType})',
    );
    final stackTrace = failure.stackTrace;
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

/// Set to `true` for in-memory database (dev/debugging, data lost on restart).
/// Set to `false` (default) for persistent encrypted SQLCipher database.
const _useInMemoryDatabase = false;

// coverage:ignore-start
// Native Assets load the SQLCipher library selected by pubspec build hooks.
// Tests exercise the branch logic through bootWithInitializerForTesting below.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledThirdPartyLicenses();
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
    ensureNativeLibrary: ensureNativeLibrary,
    // Seeding (categories, default book) runs inside HomePocketApp._initialize().
    seedRunner: (_) async {},
    pendingPrivacyWipeResumer: (container) async {
      // The settings repository synchronously requires the async preferences
      // provider, so pre-warm it before constructing the wipe use case.
      await container.read(sharedPreferencesProvider.future);
      final result = await container
          .read(clearAllDataUseCaseProvider)
          .resumePending();
      if (result.isError) {
        throw StateError('Pending local privacy wipe could not be resumed.');
      }
    },
  );
}
// coverage:ignore-end

@visibleForTesting
Future<void> bootWithInitializerForTesting(
  AppInitializer initializer, {
  AppRunner appRunner = runApp,
  InitFailureReporter failureReporter = _reportInitFailure,
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
    case final InitFailure failure:
      failureReporter(failure);
      appRunner(InitFailureApp(onRetry: _boot));
  }
}

class HomePocketApp extends ConsumerStatefulWidget {
  const HomePocketApp({super.key});

  @override
  ConsumerState<HomePocketApp> createState() => _HomePocketAppState();
}

class _HomePocketAppState extends ConsumerState<HomePocketApp>
    with WidgetsBindingObserver {
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

  /// Rejects stale async PIN-presence checks when the user toggles app lock
  /// again before secure storage responds.
  int _liveLockSettingsRevision = 0;

  @override
  void initState() {
    super.initState();
    // Register before the descendant MaterialApp/Navigator so a system-back
    // event can be consumed before it mutates routes hidden behind the lock.
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockObserver?.dispose();
    _maskVisible.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    // Android back (and equivalent platform pop requests) is dispatched to the
    // root Navigator even while our security Navigator is painted above it.
    // Consume it while locked/masked so add-entry drafts and other underlying
    // routes cannot be popped invisibly behind the unlock screen.
    return _isLocked || (_lockConfigured && _maskVisible.value);
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
        // Install every membership lifecycle callback before push bootstrap:
        // initialize() consumes a possible cold-start message immediately.
        final syncEngine = ref.read(syncEngineProvider);
        syncEngine.configureLifecycleHandlers(
          onJoinRequest: (_) async {
            await ref.read(checkGroupUseCaseProvider).execute();
          },
          onMemberLeft: (groupId, deviceId, reason, keyEpoch) async {
            await ref
                .read(handleMemberLeftUseCaseProvider)
                .execute(
                  groupId: groupId,
                  deviceId: deviceId,
                  reason: reason,
                  keyEpoch: keyEpoch,
                );
          },
          onGroupDissolved: (groupId) async {
            await ref
                .read(handleGroupDissolvedUseCaseProvider)
                .execute(groupId: groupId);
          },
        );

        await syncEngine.initialize();

        // Register the app-lock lifecycle observer alongside the sync engine's
        // own observer. `isLockEffective` reads the synchronous [_lockConfigured]
        // cache so the mask paints before the OS snapshot (RESEARCH §5); relock
        // flips the [_isLocked] gate flag via setState (never pushReplacement),
        // and the mask is driven by the synchronous [_maskVisible] notifier.
        _lockObserver ??= AppLockLifecycleObserver(
          isLockEffective: () => _lockConfigured,
          onRelock: () {
            if (!mounted) return;
            // A focused notes/merchant field can otherwise leave the platform
            // keyboard floating above the unlock surface after resume.
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _isLocked = true);
          },
          onMask: () => _maskVisible.value = true,
          onUnmask: () => _maskVisible.value = false,
        )..start();

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
      // A local privacy wipe removes the old device identity. Import-backup
      // leaves it intact, so this is an idempotent no-op on that path. Mint the
      // fresh identity before ensuring a default book, whose ownership requires
      // a device id; the wiped identity is never reused.
      final identity = ref.read(deviceIdentityRepositoryProvider);
      final currentDeviceId = await identity.getDeviceId();
      if (currentDeviceId == null || currentDeviceId.isEmpty) {
        final keyManager = ref.read(crypto.keyManagerProvider);
        if (!await keyManager.hasKeyPair()) {
          await keyManager.generateDeviceKeyPair();
        }
      }
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

    // Keep the lifecycle observer's synchronous lock cache aligned when the
    // user enables/disables app lock without restarting the app. The cold-start
    // path cannot cover this: Settings persists the change later in the same
    // process. Enabling is applied synchronously (the Settings flow writes the
    // PIN before the toggle), then defensively verified against secure storage;
    // disabling clears both the cache and any active barrier immediately.
    ref.listen(appSettingsProvider, (previous, next) {
      next.whenData(_applyLiveSecuritySettings);
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
      //
      // The unlock surface lives HERE, above the root Navigator, rather than in
      // its home route. Entry forms, settings, dialogs, and bottom sheets are
      // all routes/overlays above `home`; putting the lock in `_buildHome`
      // allowed those surfaces to remain visible until they were popped. The
      // top-level security barrier preserves the live navigation stack behind
      // it while blocking pointer and accessibility access to every route.
      // The privacy mask remains last so it covers both app and unlock UI before
      // the OS app-switcher snapshot (LOCK-04 / T-55-28).
      builder: (context, child) {
        final showLockBarrier =
            _initialized && _error == null && !_needsOnboarding && _isLocked;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: showLockBarrier,
              child: TickerMode(
                enabled: !showLockBarrier,
                child: clampTextScaling(context, child),
              ),
            ),
            if (showLockBarrier)
              HeroControllerScope.none(
                child: Navigator(
                  key: const ValueKey('app-lock-barrier-navigator'),
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => PopScope(
                      canPop: false,
                      child: AppLockScreen(
                        key: const ValueKey('app-gate-locked'),
                        onUnlocked: _completeUnlock,
                        onBeginAuth: _lockObserver?.beginAuth,
                        onEndAuth: _lockObserver?.endAuth,
                        // Skip the Face ID auto-prompt when biometric unlock is
                        // disabled; open directly on the PIN keypad (LOCK-07).
                        startOnPinPage: !_biometricUnlockEnabled,
                      ),
                    ),
                  ),
                ),
              ),
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

  void _applyLiveSecuritySettings(AppSettings settings) {
    if (!_initialized || !mounted) return;

    if (!settings.appLockEnabled) {
      // Invalidate any in-flight PIN check from an earlier enable.
      _liveLockSettingsRevision++;
      if (_lockConfigured ||
          _isLocked ||
          _biometricUnlockEnabled != settings.biometricUnlockEnabled) {
        setState(() {
          _lockConfigured = false;
          _isLocked = false;
          _biometricUnlockEnabled = settings.biometricUnlockEnabled;
        });
      }
      return;
    }

    final newlyEnabled = !_lockConfigured;
    final revision = newlyEnabled ? ++_liveLockSettingsRevision : null;
    if (newlyEnabled ||
        _biometricUnlockEnabled != settings.biometricUnlockEnabled) {
      setState(() {
        // Safe to arm immediately: every in-app enable path persists a PIN
        // before appLockEnabled=true. The async check below protects against a
        // corrupted/imported half-configured state without leaving a privacy
        // window after the user turns the feature on.
        _lockConfigured = true;
        _biometricUnlockEnabled = settings.biometricUnlockEnabled;
      });
    }
    if (newlyEnabled) {
      unawaited(_verifyLiveLockHasPin(revision!));
    }
  }

  Future<void> _verifyLiveLockHasPin(int revision) async {
    String? pinHash;
    try {
      pinHash = await ref.read(secureStorageServiceProvider).getPinHash();
    } catch (_) {
      // Fail closed: the setting was enabled only after PIN persistence. A
      // transient keychain read failure must not open a privacy window.
      return;
    }
    if (!mounted || revision != _liveLockSettingsRevision || pinHash != null) {
      return;
    }
    setState(() {
      _lockConfigured = false;
      _isLocked = false;
    });
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
    final Widget gateChild;
    if (_error != null) {
      gateChild = Scaffold(
        key: const ValueKey('app-gate-error'),
        appBar: AppBar(title: Text(S.of(context).error)),
        body: Center(child: Text(S.of(context).initializationError(_error!))),
      );
    } else if (!_initialized) {
      gateChild = const Scaffold(
        key: ValueKey('app-gate-initializing'),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_needsOnboarding) {
      gateChild = OnboardingFlowScreen(
        key: const ValueKey('app-gate-onboarding'),
        bookId: _bookId!,
        onCompleted: _completeOnboarding,
      );
    } else {
      gateChild = MainShellScreen(
        key: ValueKey('app-gate-shell-${_bookId!}'),
        bookId: _bookId!,
      );
    }

    return AppGateTransition(child: gateChild);
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
