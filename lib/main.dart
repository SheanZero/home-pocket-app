import 'dart:developer' as dev;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'features/accounting/presentation/providers/use_case_providers.dart';
import 'features/dual_ledger/presentation/screens/dual_ledger_screen.dart';
import 'infrastructure/crypto/database/encrypted_database.dart';
import 'infrastructure/crypto/providers.dart';
import 'infrastructure/security/providers.dart';

/// Set to `true` for in-memory database (dev/debugging, data lost on restart).
/// Set to `false` (default) for persistent encrypted SQLCipher database.
const _useInMemoryDatabase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize master key (first launch only)
  final initContainer = ProviderContainer();
  final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
  if (!await masterKeyRepo.hasMasterKey()) {
    await masterKeyRepo.initializeMasterKey();
    dev.log('Master key initialized', name: 'AppInit');
  } else {
    dev.log('Master key already exists', name: 'AppInit');
  }

  // 2. Create database
  final AppDatabase database;
  if (_useInMemoryDatabase) {
    database = AppDatabase(NativeDatabase.memory());
    dev.log('Using IN-MEMORY database (dev mode)', name: 'AppInit');
  } else {
    final executor = await createEncryptedExecutor(masterKeyRepo);
    database = AppDatabase(executor);
    dev.log('Encrypted database opened', name: 'AppInit');
  }

  // 3. Dispose init container, create final container with database
  initContainer.dispose();

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HomePocketApp(),
    ),
  );
}

class HomePocketApp extends ConsumerStatefulWidget {
  const HomePocketApp({super.key});

  @override
  ConsumerState<HomePocketApp> createState() => _HomePocketAppState();
}

class _HomePocketAppState extends ConsumerState<HomePocketApp> {
  String? _bookId;
  bool _initialized = false;
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
        setState(() {
          _bookId = bookResult.data!.id;
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
    return MaterialApp(
      title: 'Home Pocket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_error!)),
      );
    }

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DualLedgerScreen(bookId: _bookId!);
  }
}
