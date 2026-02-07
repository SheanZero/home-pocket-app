# Fix Database Persistence (In-Memory → SQLCipher File) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the in-memory database (`NativeDatabase.memory()`) in `main.dart` with a persistent encrypted SQLCipher file database so transactions survive app restarts.

**Architecture:** The encrypted database infrastructure already exists at `lib/infrastructure/crypto/database/encrypted_database.dart` — it creates a persistent SQLCipher-encrypted file at `<app_documents>/databases/home_pocket.db` using a key derived from the master key via HKDF. The only change needed is in `main.dart`: call `createEncryptedExecutor()` instead of `NativeDatabase.memory()`. Tests must remain working with in-memory databases.

**Tech Stack:** Flutter, Drift, SQLCipher (via `sqlcipher_flutter_libs`), `path_provider`, `flutter_secure_storage`.

**Spec:** `doc/arch/01-core-architecture/ARCH-003_Security_Architecture.md`

---

## Root Cause Analysis

**Problem:** Transactions disappear after app restart.

**Cause:** `lib/main.dart` line 18 uses `NativeDatabase.memory()`. An in-memory database is destroyed when the process exits.

**Evidence:**
```dart
// lib/main.dart:18 — THIS IS THE BUG
final database = AppDatabase(NativeDatabase.memory());
```

**Fix:** The project already has `createEncryptedExecutor()` in `lib/infrastructure/crypto/database/encrypted_database.dart` that creates a persistent file-backed encrypted database. It just needs to be wired into `main.dart`.

**Existing infrastructure (already implemented, untouched by this plan):**
- `lib/infrastructure/crypto/database/encrypted_database.dart` — `createEncryptedExecutor()` function
- `lib/infrastructure/crypto/repositories/master_key_repository.dart` — Interface
- `lib/infrastructure/crypto/repositories/master_key_repository_impl.dart` — FlutterSecureStorage-backed implementation
- `lib/infrastructure/crypto/providers.dart` — `masterKeyRepositoryProvider`

---

## Task 1: Switch main.dart to Persistent Encrypted Database

**Files:**
- Modify: `lib/main.dart`

**Context:** Replace `NativeDatabase.memory()` with `createEncryptedExecutor()`. The function is async and requires the master key to be initialized first (which is already done on line 27-31). The order must be: (1) init master key → (2) create encrypted executor → (3) create AppDatabase → (4) override provider.

**Step 1: Write the updated main.dart**

Replace the entire `main()` function. Key changes:
- Import `encrypted_database.dart` instead of `drift/native.dart`
- Call `createEncryptedExecutor(masterKeyRepo)` instead of `NativeDatabase.memory()`
- Remove the `drift/native.dart` import (no longer needed)

```dart
// lib/main.dart — updated main() function

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'features/accounting/presentation/providers/use_case_providers.dart';
import 'features/dual_ledger/presentation/screens/dual_ledger_screen.dart';
import 'infrastructure/crypto/database/encrypted_database.dart';
import 'infrastructure/crypto/providers.dart';
import 'infrastructure/security/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create a temporary container to access crypto providers
  final initContainer = ProviderContainer();

  // 2. Initialize master key (first launch only)
  final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
  if (!await masterKeyRepo.hasMasterKey()) {
    await masterKeyRepo.initializeMasterKey();
    dev.log('Master key initialized', name: 'AppInit');
  } else {
    dev.log('Master key already exists', name: 'AppInit');
  }

  // 3. Create persistent encrypted database
  final executor = await createEncryptedExecutor(masterKeyRepo);
  final database = AppDatabase(executor);
  dev.log('Encrypted database opened', name: 'AppInit');

  // 4. Dispose temporary container, create final container with database
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
```

**Step 2: Verify the app builds**

Run: `flutter analyze`
Expected: No issues found!

**Step 3: Run all tests**

Run: `flutter test`
Expected: ALL PASS (tests use their own in-memory database setup, not main.dart)

**Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "fix: use persistent encrypted SQLCipher database instead of in-memory

Transactions were lost on app restart because main.dart used
NativeDatabase.memory(). Now uses createEncryptedExecutor() which
creates a file-backed SQLCipher database at <app_docs>/databases/home_pocket.db."
```

---

## Task 2: Add Dev-Mode Toggle for In-Memory Database

**Files:**
- Modify: `lib/main.dart`

**Context:** During development/testing on simulator, encrypted database requires platform channels that may complicate debugging. Add a simple `const bool` flag at the top of main.dart that allows switching back to in-memory for development when needed, with the default being persistent (production-ready).

**Step 1: Add the flag and conditional logic**

```dart
// At top of main.dart, after imports:

/// Set to `true` to use an in-memory database (for development/debugging).
/// Set to `false` (default) for persistent encrypted SQLCipher database.
const _useInMemoryDatabase = false;
```

Then update the `main()` function to branch:

```dart
  // 3. Create database
  final AppDatabase database;
  if (_useInMemoryDatabase) {
    database = AppDatabase(NativeDatabase.memory());
    dev.log('Using IN-MEMORY database (dev mode)', name: 'AppInit');
  } else {
    final executor = await createEncryptedExecutor(masterKeyRepo);
    database = AppDatabase(executor);
    dev.log('Encrypted database opened', name: 'AppInit');
  }
```

Note: This requires keeping the `import 'package:drift/native.dart';` for the in-memory fallback path.

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

**Step 3: Run all tests**

Run: `flutter test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: add dev-mode toggle for in-memory database fallback"
```

---

## Task 3: Verify Persistence on Device

**Files:**
- None (manual verification)

**Step 1: Run app on device/simulator**

Run: `flutter run`

**Step 2: Create a test transaction**

- Tap + button
- Enter amount: 1000
- Select category: Food
- Tap Save

**Step 3: Kill and restart the app**

- Force-kill the app (swipe away from app switcher, or press Stop in IDE)
- Run: `flutter run` again

**Step 4: Verify transaction persists**

- The transaction created in Step 2 should still appear in the list
- If it appears: persistence is working
- If it does not appear: check `flutter run` console logs for errors

**Step 5: Document result**

If successful, no commit needed. If issues found, investigate and fix.

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Switch to persistent encrypted database | 1 modified (main.dart) |
| 2 | Add dev-mode in-memory toggle | 1 modified (main.dart) |
| 3 | Manual verification on device | 0 |

**Total changes:** 1 file modified (`lib/main.dart`)
**Root cause:** `NativeDatabase.memory()` → `createEncryptedExecutor()`
**Risk:** Low — all existing infrastructure is already built and tested
