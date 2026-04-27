import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/initialization/app_initializer.dart';
import 'core/initialization/init_failure_screen.dart';
import 'core/initialization/init_result.dart';
import 'core/theme/app_theme.dart';
import 'data/app_database.dart';
import 'features/accounting/presentation/providers/repository_providers.dart'
    show seedCategoriesUseCaseProvider, ensureDefaultBookUseCaseProvider;
import 'features/family_sync/presentation/providers/repository_providers.dart';
import 'features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'features/family_sync/presentation/providers/state_sync.dart'
    show syncEngineProvider;
import 'features/home/presentation/screens/main_shell_screen.dart';
import 'features/profile/presentation/providers/repository_providers.dart'
    show getUserProfileUseCaseProvider;
import 'features/profile/presentation/screens/profile_onboarding_screen.dart';
import 'features/settings/domain/models/app_settings.dart';
import 'features/settings/presentation/providers/state_locale.dart';
import 'features/settings/presentation/providers/state_settings.dart';
import 'generated/app_localizations.dart';
import 'infrastructure/crypto/database/encrypted_database.dart';

/// Set to `true` for in-memory database (dev/debugging, data lost on restart).
/// Set to `false` (default) for persistent encrypted SQLCipher database.
const _useInMemoryDatabase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureNativeLibrary();
  await _boot();
}

Future<void> _boot() async {
  final initializer = AppInitializer(
    containerFactory: ({overrides = const []}) =>
        ProviderContainer(overrides: overrides),
    databaseFactory: (masterKeyRepo) async {
      if (_useInMemoryDatabase) {
        return AppDatabase(NativeDatabase.memory());
      }
      final executor = await createEncryptedExecutor(masterKeyRepo);
      return AppDatabase(executor);
    },
    // Seeding (categories, default book) runs inside HomePocketApp._initialize().
    seedRunner: (_) async {},
  );

  final result = await initializer.initialize();

  switch (result) {
    case InitSuccess(:final container):
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const HomePocketApp(),
        ),
      );
    case InitFailure():
      runApp(InitFailureApp(onRetry: _boot));
  }
}

class HomePocketApp extends ConsumerStatefulWidget {
  const HomePocketApp({super.key});

  @override
  ConsumerState<HomePocketApp> createState() => _HomePocketAppState();
}

class _HomePocketAppState extends ConsumerState<HomePocketApp> {
  String? _bookId;
  bool _initialized = false;
  bool _needsProfileOnboarding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Seed categories
      final seedCategories = ref.read(seedCategoriesUseCaseProvider);
      await seedCategories.execute();

      // Ensure default book
      final ensureBook = ref.read(ensureDefaultBookUseCaseProvider);
      final bookResult = await ensureBook.execute();

      if (bookResult.isSuccess && bookResult.data != null) {
        // Initialize SyncEngine (lifecycle observer + status stream)
        final syncEngine = ref.read(syncEngineProvider);
        syncEngine.initialize();

        // Wire push notifications → sync engine
        final pushService = ref.read(pushNotificationServiceProvider);
        syncEngine.connectPushNotifications(pushService);
        final existingProfile = await ref
            .read(getUserProfileUseCaseProvider)
            .execute();

        setState(() {
          _bookId = bookResult.data!.id;
          _needsProfileOnboarding = existingProfile == null;
          _initialized = true;
        });
      } else {
        setState(() => _error = bookResult.error ?? 'Failed to initialize');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode =
        settingsAsync.whenOrNull(
          data: (s) => _toFlutterThemeMode(s.themeMode),
        ) ??
        ThemeMode.system;
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('ja');

    return MaterialApp(
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

    if (_needsProfileOnboarding) {
      return ProfileOnboardingScreen(bookId: _bookId!);
    }

    return MainShellScreen(bookId: _bookId!);
  }
}
