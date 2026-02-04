# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Home Pocket (まもる家計簿)** is a local-first, privacy-focused family accounting app with a dual-ledger system. The app uses zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design.

**Current Phase:** Phase 1 - Infrastructure Layer (v0.1.0)
**Target:** iOS 14+ / Android 7+ (API 24+)

---

## Essential Commands

### Development Setup
```bash
# Install dependencies
flutter pub get

# Code generation (Riverpod, Freezed, Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Watch mode for continuous code generation
flutter pub run build_runner watch
```

### Development
```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Code Quality
```bash
# Static analysis
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

**Coverage Requirement:** ≥80%

---

## Architecture

### Clean Architecture (5 Layers)

The codebase follows strict Clean Architecture with dependency rules:

```
lib/
├── infrastructure/       # Project-wide infrastructure
│   └── crypto/          # Cryptographic primitives (MANDATORY)
│       ├── services/    # Key management, encryption, hash chain
│       ├── repositories/ # Crypto repository interfaces & implementations
│       ├── models/      # Crypto domain models
│       └── database/    # Database encryption setup
│
├── data/                 # Shared data layer (CROSS-FEATURE)
│   ├── app_database.dart # Main Drift database definition
│   ├── tables/          # Drift table definitions (all features)
│   └── daos/            # Drift data access objects (all features)
│
├── features/              # Feature modules (domain-driven)
│   └── {feature}/
│       ├── presentation/  # UI layer (screens, widgets, providers)
│       ├── application/   # Business logic (use cases, services)
│       ├── domain/        # Core entities & repository interfaces
│       └── data/          # Data access (repositories only - use lib/data/ DAOs)
│
├── core/                  # Cross-cutting concerns
│   ├── config/           # App configuration
│   ├── constants/        # Global constants
│   ├── router/           # GoRouter navigation
│   └── theme/            # Material 3 theme
│
├── shared/               # Reusable components
│   ├── widgets/         # Common UI components
│   ├── extensions/      # Dart extensions
│   └── utils/           # Utility functions
│
└── l10n/                # Internationalization (ja, zh, en)
```

### Capability Classification Rule (CRITICAL)

**Before creating any new functionality, MUST classify it as:**

#### 🔵 Feature-Specific Capability (Feature Closure)
**Characteristics:**
- Used ONLY by the current feature
- No other features need access
- Feature-specific business logic

**Placement:** `lib/features/{feature}/`

**Examples:**
- Feature-specific UI screens/widgets
- Feature-specific use cases
- Feature-specific domain models (if truly isolated)
- Feature-specific repository implementations

#### 🟢 Shared Capability (Cross-Feature)
**Characteristics:**
- Used by MULTIPLE features
- Infrastructure or foundation for other features
- System-level concerns

**Placement:** `lib/` (infrastructure, data, core, shared)

**Examples:**
- ✅ **Database (lib/data/)**: All features need data access
- ✅ **Crypto (lib/infrastructure/crypto/)**: Encryption used everywhere
- ✅ **Router (lib/core/router/)**: Navigation shared across features
- ✅ **Common widgets (lib/shared/widgets/)**: Reusable UI components

#### Decision Rule

**Ask yourself:**
1. "Will other features need this?" → YES → `lib/`
2. "Is this feature-specific only?" → YES → `lib/features/{feature}/`
3. "Not sure?" → Default to `lib/` (safer, easier to refactor later)

**Common Mistakes:**
- ❌ Putting database in feature folder (blocks other features)
- ❌ Putting shared models in feature folder
- ❌ Creating feature-specific versions of infrastructure

**When in doubt:** Place in `lib/` at appropriate level (infrastructure, data, core, shared)

### Dependency Rules

**CRITICAL:** Outer layers depend on inner layers, never the reverse:

```
Presentation → Application → Domain ← Data
                                      ↓
                              Infrastructure
```

- **Domain layer** is completely independent (no external dependencies)
- **Data layer** implements domain repository interfaces
- **Application layer** orchestrates business logic using domain entities
- **Presentation layer** consumes application providers, no direct data access

### Key Architectural Patterns

1. **State Management:** Riverpod 2.4+ with code generation (`@riverpod`)
2. **Data Models:** Freezed for immutability (`@freezed`)
3. **Database:** Drift with SQLCipher (type-safe SQL with encryption)
4. **Routing:** GoRouter with declarative routes
5. **Localization:** flutter_localizations with ARB files

### Riverpod Provider Organization Rules (CRITICAL)

**Repository Provider Management:**

**MUST follow Single Source of Truth pattern:**

1. **Repository Providers** MUST be defined in `repository_providers.dart`:
   ```dart
   // lib/features/{feature}/presentation/providers/repository_providers.dart

   @riverpod
   TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
     final database = ref.watch(appDatabaseProvider);
     final dao = TransactionDao(database);
     // ... dependencies
     return TransactionRepositoryImpl(...);
   }
   ```

2. **Use Case Providers** MUST reference repository providers via `ref.watch()`:
   ```dart
   // lib/features/{feature}/presentation/providers/transaction_providers.dart

   import 'repository_providers.dart';  // Import from single source

   @riverpod
   CreateTransactionUseCase createTransactionUseCase(CreateTransactionUseCaseRef ref) {
     return CreateTransactionUseCase(
       transactionRepository: ref.watch(transactionRepositoryProvider),  // Reuse!
       categoryRepository: ref.watch(categoryRepositoryProvider),
     );
   }
   ```

**Rules:**
- ✅ **ONE** repository_providers.dart file per feature
- ✅ ALL repository providers defined in repository_providers.dart
- ✅ Use case providers reference via `ref.watch()`
- ❌ NEVER duplicate repository provider definitions
- ❌ NEVER define repository providers in use case provider files
- ❌ NEVER throw `UnimplementedError` in provider definitions

**File Structure:**
```
lib/features/accounting/presentation/providers/
├── repository_providers.dart     # Single source for all repository providers
├── transaction_providers.dart    # Use case providers (reference repository_providers)
├── category_providers.dart       # Use case providers
└── book_providers.dart           # Use case providers
```

---

## Code Generation

This project heavily uses code generation. **Always run build_runner after:**
- Creating/modifying `@riverpod` providers
- Creating/modifying `@freezed` models
- Creating/modifying Drift tables
- Adding new ARB localization strings

Generated files (`.g.dart`, `.freezed.dart`) are gitignored.

**Critical Workflow:**
```bash
# After modifying annotated code
flutter pub run build_runner build --delete-conflicting-outputs

# After merging branches (regenerate to sync with main)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous development
flutter pub run build_runner watch
```

**Common Issues:**
- ❌ **Type not found errors** after merge → Run build_runner to regenerate
- ❌ **Tests fail with compilation errors** → Generated files out of sync
- ✅ **Always regenerate after:**
  - Git merge/rebase
  - Switching branches
  - Pulling from remote

---

## Drift Database Index Guidelines (MANDATORY)

**CRITICAL:** Use correct Drift TableIndex syntax for database performance optimization.

### Index Syntax Rules

**CORRECT Syntax:**
```dart
import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  // ✅ CORRECT: Use TableIndex with Symbol syntax
  List<TableIndex> get customIndices => [
    // Single column index
    TableIndex(name: 'idx_transactions_book_id', columns: {#bookId}),

    // Compound index
    TableIndex(
      name: 'idx_transactions_book_timestamp',
      columns: {#bookId, #timestamp},
    ),
  ];
}
```

**WRONG Syntax:**
```dart
// ❌ WRONG: Using Index() constructor
List<Index> get customIndices => [
  Index('idx_name', [bookId]),  // Compilation error!
];

// ❌ WRONG: Using @override on customIndices
@override  // customIndices is NOT overriding a parent method
List<TableIndex> get customIndices => [...];

// ❌ WRONG: Using column references instead of Symbols
List<TableIndex> get customIndices => [
  TableIndex(name: 'idx_name', columns: {bookId}),  // Error!
];
```

**Key Points:**
- ✅ Use `TableIndex` class (not `Index`)
- ✅ Use Symbol syntax: `{#columnName}` (with `#` prefix)
- ✅ DO NOT add `@override` annotation to `customIndices`
- ✅ Return `List<TableIndex>` (not `List<Index>`)
- ✅ Use `Set<Symbol>` for columns parameter

### Index Naming Convention

```dart
// Pattern: idx_{table}_{columns}
TableIndex(name: 'idx_transactions_book_id', columns: {#bookId})
TableIndex(name: 'idx_transactions_timestamp', columns: {#timestamp})
TableIndex(name: 'idx_transactions_book_timestamp', columns: {#bookId, #timestamp})
TableIndex(name: 'idx_books_archived', columns: {#isArchived})
TableIndex(name: 'idx_categories_type', columns: {#type})
```

### Performance Optimization Strategy

**Query Patterns → Index Strategy:**

1. **Single column filters** (WHERE bookId = ?)
   ```dart
   TableIndex(name: 'idx_transactions_book_id', columns: {#bookId})
   ```

2. **Compound queries** (WHERE bookId = ? ORDER BY timestamp)
   ```dart
   TableIndex(
     name: 'idx_transactions_book_timestamp',
     columns: {#bookId, #timestamp},  // Order matters!
   )
   ```

3. **Boolean flags** (WHERE isArchived = false)
   ```dart
   TableIndex(name: 'idx_books_archived', columns: {#isArchived})
   ```

4. **Text search** (WHERE name LIKE ?)
   ```dart
   TableIndex(name: 'idx_books_name', columns: {#name})
   ```

**Index Selection Guidelines:**
- ✅ Index columns used in WHERE clauses
- ✅ Index columns used in JOIN conditions
- ✅ Index columns used in ORDER BY
- ✅ Use compound indexes for multi-column queries (most selective column first)
- ❌ Don't over-index (impacts write performance)
- ❌ Don't duplicate coverage (single-column index redundant if compound index exists)

---

## Security Architecture

**4-Layer Encryption:**
1. **Layer 1:** Database encryption (SQLCipher AES-256-CBC, 256k PBKDF2)
2. **Layer 2:** Field encryption (ChaCha20-Poly1305 AEAD)
3. **Layer 3:** File encryption (AES-256-GCM for photos)
4. **Layer 4:** Transport encryption (TLS 1.3 + E2EE for P2P sync)

**Key Management:**
- Ed25519 device key pairs
- BIP39 24-word recovery phrase
- HKDF key derivation with caching
- Biometric lock (Face ID/Touch ID/Fingerprint)

**Integrity Protection:**
- Blockchain-style hash chain
- Incremental verification (100-2000x performance improvement)
- Tamper detection

---

## Application Initialization Pattern (MANDATORY)

**CRITICAL:** Core services MUST be initialized before `runApp()` using the `AppInitializer` pattern.

### Architecture

**File Location:** `lib/core/initialization/app_initializer.dart`

**Pattern:**
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create provider container for initialization
  final container = ProviderContainer();

  try {
    // Initialize core services BEFORE runApp
    await AppInitializer.initialize(container);

    // Run app with initialized container
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const HomePocketApp(),
      ),
    );
  } catch (e) {
    // Show error screen if initialization fails
    runApp(_buildErrorScreen(e));
  }
}
```

### AppInitializer Implementation

```dart
// lib/core/initialization/app_initializer.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';

class AppInitializer {
  /// Initialize all required services
  ///
  /// This must be called before runApp() to ensure:
  /// - Database is ready
  /// - Encryption keys are loaded
  /// - Secure storage is initialized
  static Future<void> initialize(ProviderContainer container) async {
    try {
      // 1. Initialize key manager (loads or generates device keys)
      final keyManager = container.read(keyManagerProvider);
      final hasKeys = await keyManager.hasKeyPair();

      if (!hasKeys) {
        await keyManager.generateDeviceKeyPair();
      }

      // 2. Initialize database (ensures schema is up to date)
      final database = container.read(appDatabaseProvider);
      await database.customSelect('SELECT 1').get();

      print('✅ App initialization complete');
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      print(stackTrace);
      rethrow;
    }
  }
}
```

### Initialization Order (CRITICAL)

**MUST follow this order:**
1. **Key Manager** - Load or generate device encryption keys
2. **Database** - Initialize database with encryption
3. **Other Services** - Additional services as needed

**Why this order matters:**
- Database initialization requires encryption keys
- Many services depend on database being ready
- Key manager has no dependencies (can be initialized first)

### Error Handling

**Graceful Degradation:**
```dart
try {
  await AppInitializer.initialize(container);
  runApp(UncontrolledProviderScope(
    container: container,
    child: const HomePocketApp(),
  ));
} catch (e) {
  // Show user-friendly error screen
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Initialization Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to initialize app'),
            SizedBox(height: 8),
            // Don't expose raw exception to user in production
            if (kDebugMode) Text(e.toString()),
          ],
        ),
      ),
    ),
  ));
}
```

### Testing Considerations

**Unit Testing AppInitializer:**
- ❌ **DON'T** test in pure unit tests (requires platform channels)
- ✅ **DO** test via integration tests
- ✅ **DO** verify initialization via app runtime testing

**Reason:** KeyManager uses `flutter_secure_storage` which requires platform channels, unavailable in unit test environment.

### Rules

- ✅ MUST call `WidgetsFlutterBinding.ensureInitialized()` first
- ✅ MUST create `ProviderContainer` before initialization
- ✅ MUST initialize services in correct order (KeyManager → Database → Others)
- ✅ MUST use `UncontrolledProviderScope` to provide container
- ✅ MUST provide error screen fallback
- ❌ NEVER skip initialization and hope services lazy-load correctly
- ❌ NEVER initialize inside widgets (too late!)
- ❌ NEVER expose raw exceptions to users in production

---

## Crypto Infrastructure Usage Rules (MANDATORY)

**CRITICAL:** All cryptographic operations MUST use the centralized infrastructure in `lib/infrastructure/crypto/`. DO NOT implement custom crypto solutions.

### Mandatory Usage Rules

1. **Key Management:**
   - ✅ MUST use `lib/infrastructure/crypto/services/key_manager.dart`
   - ❌ NEVER implement custom key generation or storage
   - ❌ NEVER access flutter_secure_storage directly for keys

2. **Field Encryption:**
   - ✅ MUST use `lib/infrastructure/crypto/services/field_encryption_service.dart`
   - ❌ NEVER use cryptography packages directly
   - ✅ MUST encrypt all sensitive fields: amounts, notes, merchant names

3. **Transaction Integrity:**
   - ✅ MUST use `lib/infrastructure/crypto/services/hash_chain_service.dart`
   - ❌ NEVER implement custom hash chain logic
   - ✅ MUST include hash in all transaction records

4. **Database Encryption:**
   - ✅ MUST use `lib/infrastructure/crypto/database/createEncryptedExecutor`
   - ❌ NEVER create database connections without encryption

5. **Security Principles:**
   - ❌ NEVER store encryption keys in plain text
   - ❌ NEVER log sensitive data (keys, plaintext amounts)
   - ❌ NEVER bypass encryption for "convenience"
   - ✅ ALWAYS clear crypto caches on logout

### Usage Examples

**Key Management:**
```dart
@riverpod
Future<void> initializeApp(InitializeAppRef ref) async {
  final keyManager = ref.read(keyManagerProvider);

  if (!await keyManager.hasKeyPair()) {
    await keyManager.generateDeviceKeyPair();
  }
}
```

**Field Encryption:**
```dart
@riverpod
class TransactionRepository {
  Future<void> saveTransaction(Transaction tx) async {
    final encryptionService = ref.read(fieldEncryptionServiceProvider);

    final encryptedAmount = await encryptionService.encryptAmount(tx.amount);
    final encryptedNote = await encryptionService.encryptField(tx.note);

    // Save encrypted data...
  }
}
```

**Hash Chain:**
```dart
@riverpod
class TransactionService {
  Future<String> calculateHash(Transaction tx, String prevHash) async {
    final hashChain = ref.read(hashChainServiceProvider);

    return hashChain.calculateTransactionHash(
      transactionId: tx.id,
      amount: tx.amount,
      timestamp: tx.timestamp,
      previousHash: prevHash,
    );
  }
}
```

**Database Encryption:**
```dart
@riverpod
Future<AppDatabase> appDatabase(AppDatabaseRef ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  final executor = await createEncryptedExecutor(keyManager);
  return AppDatabase(executor);
}
```

---

## Module Development Priority

Follow the development plan in `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`:

**Phase 1 (Weeks 1-2): Infrastructure**
- MOD-006: Security & Privacy (10 days) - **START HERE**
- MOD-014: Internationalization (4 days)

**Phase 2 (Weeks 3-5): Core Accounting**
- MOD-001: Basic Accounting (13 days)
- MOD-003: Dual Ledger (8 days)

**Phase 3 (Weeks 6-9): Sync & Analytics**
- MOD-004: Family Sync (12 days)
- MOD-007: Analytics & Reports (8 days)
- MOD-008: Settings Management (6 days)

**Phase 4 (Weeks 10-12): Enhanced Features**
- MOD-005: OCR Scanning (7 days)
- MOD-013: Gamification (optional)

---

## Architecture Documentation

**IMPORTANT:** All architecture decisions are documented in `doc/arch/`:

### Directory Structure
```
doc/arch/
├── 01-core-architecture/    # ARCH-000 to ARCH-009 (10 docs)
├── 02-module-specs/          # MOD-001 to MOD-009 (9 module specs)
└── 03-adr/                   # Architecture Decision Records
```

### Adding New Architecture Docs

**MUST follow this workflow:**

1. **Check existing files** to find max number:
   ```bash
   ls -1 doc/arch/01-core-architecture/ARCH-*.md | sort | tail -1
   ls -1 doc/arch/02-module-specs/MOD-*.md | sort | tail -1
   ls -1 doc/arch/03-adr/ADR-*.md | sort | tail -1
   ```

2. **Use next sequential number** (e.g., if max is ARCH-009, use ARCH-010)

3. **Naming conventions:**
   - Architecture: `ARCH-{NNN}_{PascalCase_Name}.md`
   - Modules: `MOD-{NNN}_{PascalCase_Name}.md`
   - ADRs: `ADR-{NNN}_{PascalCase_Name}.md`

4. **Update corresponding INDEX.md** file

**Never:** Skip numbers, reuse numbers, or create files without checking existing numbers.

---

## Dual Ledger System

The core concept that differentiates this app:

**Survival Ledger (生存账本):**
- Daily necessities (food, housing, transport)
- Category: "Survival"
- Visual: Green theme

**Soul Ledger (灵魂账本):**
- Self-investment and enjoyment (hobbies, entertainment, education)
- Category: "Soul"
- Visual: Purple theme with celebration animation

**3-Layer Classification Engine:**
1. Rule Engine (keyword matching)
2. Merchant Database (500+ Japanese merchants)
3. ML Classifier (TensorFlow Lite, 85%+ accuracy)

---

## Testing Strategy

**TDD Methodology (MANDATORY):**
1. Write test first (RED)
2. Run test - should fail
3. Write minimal implementation (GREEN)
4. Run test - should pass
5. Refactor (IMPROVE)
6. Verify 80%+ coverage

**Test Types:**
- Unit tests: Business logic, utilities, repositories
- Widget tests: UI components
- Integration tests: E2E user flows, database operations, encryption

**Test Location:**
```
test/
├── unit/           # Business logic tests
├── widget/         # UI component tests
└── integration/    # Integration tests

integration_test/   # E2E tests
```

---

## Internationalization (i18n) Guidelines (MANDATORY)

**CRITICAL:** All user-facing text and formatting MUST use the centralized i18n infrastructure. DO NOT hardcode strings or use raw formatters.

### Supported Languages

- **Japanese (ja)** - Default locale
- **Chinese (zh)** - Simplified Chinese
- **English (en)** - International English

### Mandatory i18n Rules

1. **Localized Strings:**
   - ✅ MUST use `S.of(context)` for all user-facing text
   - ❌ NEVER hardcode UI strings in widgets
   - ❌ NEVER use string literals for labels, messages, or error text
   - ✅ ALWAYS add translations to all 3 ARB files (ja, zh, en)

2. **Date Formatting:**
   - ✅ MUST use `DateFormatter` from `lib/shared/utils/formatters/date_formatter.dart`
   - ❌ NEVER use raw `DateFormat` or `toString()` on DateTime objects
   - ✅ ALWAYS pass current locale from `currentLocaleProvider`
   - Formats: `formatDate()`, `formatDateTime()`, `formatRelative()`, `formatMonthYear()`

3. **Number & Currency Formatting:**
   - ✅ MUST use `NumberFormatter` from `lib/shared/utils/formatters/number_formatter.dart`
   - ❌ NEVER display raw numbers for amounts or currencies
   - ✅ ALWAYS use `formatCurrency()` for transaction amounts
   - ✅ MUST pass correct currency code (JPY, USD, CNY, EUR, GBP)

4. **Locale Management:**
   - ✅ MUST use `LocaleNotifierProvider` for runtime locale switching
   - ✅ MUST watch `currentLocaleProvider` when formatting dates/numbers
   - ❌ NEVER assume a specific locale in business logic
   - ✅ ALWAYS respect user's locale preference

5. **ARB File Management:**
   - ✅ MUST update ALL 3 ARB files when adding new translations
   - ✅ MUST add @metadata for each translation key
   - ✅ MUST run `flutter gen-l10n` after ARB changes
   - ❌ NEVER commit without regenerating localization files

### Usage Examples

**Localized Strings:**
```dart
import 'package:home_pocket/generated/app_localizations.dart';

@override
Widget build(BuildContext context) {
  final l10n = S.of(context);

  return AppBar(
    title: Text(l10n.appName),
    actions: [
      IconButton(
        icon: Icon(Icons.settings),
        tooltip: l10n.settings,
        onPressed: () {},
      ),
    ],
  );
}
```

**Date Formatting:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/shared/utils/formatters/date_formatter.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  final locale = ref.watch(currentLocaleProvider);
  final transaction = ref.watch(transactionProvider);

  return Column(
    children: [
      Text(DateFormatter.formatDate(transaction.timestamp, locale)),
      Text(DateFormatter.formatRelative(transaction.timestamp, locale)),
    ],
  );
}
```

**Currency Formatting:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/shared/utils/formatters/number_formatter.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  final locale = ref.watch(currentLocaleProvider);
  final amount = transaction.amount;

  return Text(
    NumberFormatter.formatCurrency(amount, 'JPY', locale),
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  );
}
```

**Runtime Locale Switching:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  final localeNotifier = ref.read(localeNotifierProvider.notifier);
  final currentLocale = ref.watch(currentLocaleProvider);

  return DropdownButton<Locale>(
    value: currentLocale,
    items: [
      DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
      DropdownMenuItem(value: Locale('en'), child: Text('English')),
      DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
    ],
    onChanged: (locale) {
      if (locale != null) {
        localeNotifier.setLocale(locale);
      }
    },
  );
}
```

**Parameterized Error Messages:**
```dart
import 'package:home_pocket/generated/app_localizations.dart';

String validateAmount(double amount, BuildContext context) {
  final l10n = S.of(context);

  if (amount < 0.01) {
    return l10n.errorMinAmount(0.01);
  }

  if (amount > 999999.99) {
    return l10n.errorMaxAmount(999999.99);
  }

  return '';
}
```

### Adding New Translations

**Workflow:**
1. Add key to **all 3 ARB files**: `lib/l10n/app_{ja,zh,en}.arb`
2. Add @metadata entry for each key
3. Run: `flutter gen-l10n`
4. Use via: `S.of(context).yourNewKey`
5. Write unit test to verify translations exist

**Example:**
```json
// app_ja.arb
{
  "newFeature": "新機能",
  "@newFeature": {
    "description": "新機能のラベル"
  }
}

// app_en.arb
{
  "newFeature": "New Feature",
  "@newFeature": {
    "description": "Label for new feature"
  }
}

// app_zh.arb
{
  "newFeature": "新功能",
  "@newFeature": {
    "description": "新功能的标签"
  }
}
```

### Locale-Specific Formatting Rules

**Date Formats:**
- Japanese: `2026/02/04` (YYYY/MM/DD)
- English: `02/04/2026` (MM/DD/YYYY)
- Chinese: `2026年02月04日` (YYYY年MM月DD日)

**Currency Rules:**
- JPY: ¥1,235 (0 decimals)
- USD/CNY/EUR/GBP: $1,234.56 (2 decimals)

**Compact Numbers:**
- Japanese/Chinese: 123万 (uses 万 for 10,000)
- English: 1.23M (uses K/M/B)

### Common Pitfalls

❌ **WRONG: Hardcoded strings**
```dart
Text('Settings')  // NEVER do this
```

✅ **CORRECT: Localized strings**
```dart
Text(S.of(context).settings)
```

❌ **WRONG: Raw DateTime toString()**
```dart
Text(transaction.timestamp.toString())
```

✅ **CORRECT: DateFormatter with locale**
```dart
final locale = ref.watch(currentLocaleProvider);
Text(DateFormatter.formatDate(transaction.timestamp, locale))
```

❌ **WRONG: Hardcoded currency symbol**
```dart
Text('¥${amount.toStringAsFixed(0)}')
```

✅ **CORRECT: NumberFormatter with currency code**
```dart
final locale = ref.watch(currentLocaleProvider);
Text(NumberFormatter.formatCurrency(amount, 'JPY', locale))
```

❌ **WRONG: Adding translation to only one ARB file**
```dart
// Only added to app_ja.arb - WRONG!
```

✅ **CORRECT: Add to all 3 ARB files**
```dart
// Added to app_ja.arb, app_en.arb, app_zh.arb
```

### Testing Requirements

When adding i18n features, you MUST:
- [ ] Add unit tests for all 3 locales
- [ ] Test date formatting across all locales
- [ ] Test currency formatting for all supported currencies
- [ ] Test locale switching doesn't break UI
- [ ] Verify ARB files have no missing keys
- [ ] Run `flutter gen-l10n` and commit generated files to gitignore check

### Configuration Files

**l10n.yaml:**
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
```

**After ARB changes, always run:**
```bash
flutter gen-l10n
```

### References

- **MOD-014 Specification:** `doc/arch/02-module-specs/MOD-014_i18n.md`
- **ARB Files:** `lib/l10n/app_{ja,zh,en}.arb`
- **DateFormatter:** `lib/shared/utils/formatters/date_formatter.dart`
- **NumberFormatter:** `lib/shared/utils/formatters/number_formatter.dart`
- **LocaleProvider:** `lib/features/settings/presentation/providers/locale_provider.dart`

---

## Performance Optimizations

Critical performance targets from architecture decisions:

1. **Incremental Balance Updates:** 40-400x improvement vs full recalculation (ADR-008)
2. **Incremental Hash Chain Verification:** 100-2000x improvement vs full chain (ADR-009)
3. **Pagination:** 50-100 items per page
4. **Fast Entry:** <3 seconds to complete transaction entry
5. **UI Smoothness:** 60 FPS scrolling

---

## Immutability Requirement

**CRITICAL:** All data operations must use immutable patterns.

**WRONG:**
```dart
void updateUser(User user, String name) {
  user.name = name;  // MUTATION!
}
```

**CORRECT:**
```dart
User updateUser(User user, String name) {
  return user.copyWith(name: name);  // Freezed copyWith
}
```

Use Freezed's `copyWith` for all state updates.

---

## Widget Parameter Patterns (BEST PRACTICES)

### Nullable Parameters with Provider Fallback

**Pattern:** Use nullable widget parameters with runtime provider fallback for dynamic values.

**Problem:** Hardcoded values prevent runtime configuration
```dart
// ❌ WRONG: Hardcoded default value
class TransactionListScreen extends ConsumerWidget {
  final String bookId;

  const TransactionListScreen({
    super.key,
    this.bookId = 'book_001',  // HARDCODED!
  });
}
```

**Solution:** Nullable parameter + provider fallback
```dart
// ✅ CORRECT: Nullable with runtime fallback
class TransactionListScreen extends ConsumerWidget {
  final String? bookId;  // Nullable

  const TransactionListScreen({
    super.key,
    this.bookId,  // No default value
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fallback to provider if not provided
    final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;

    if (effectiveBookId == null) {
      // Handle case where no book is available
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).appName)),
        body: Center(child: Text(S.of(context).pleaseCreateBookFirst)),
      );
    }

    // Use effectiveBookId throughout the widget
    return _buildContent(effectiveBookId);
  }
}
```

**Benefits:**
- ✅ Allows explicit passing for testing
- ✅ Falls back to runtime provider for normal use
- ✅ No hardcoded values
- ✅ Single source of truth (provider)

### Provider Selection Pattern

**Multiple Provider Options:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Priority: explicit parameter > current selection > user's default > null
  final value = widget.explicitValue
    ?? ref.watch(currentSelectionProvider).value
    ?? ref.watch(userDefaultProvider).value;

  if (value == null) {
    return _buildEmptyState();
  }

  return _buildContent(value);
}
```

### Common Patterns

**1. Optional ID Parameter (Most Common):**
```dart
class DetailScreen extends ConsumerWidget {
  final String? itemId;

  const DetailScreen({super.key, this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = itemId ?? ref.watch(currentItemIdProvider).value;
    if (id == null) return EmptyState();
    return Content(id);
  }
}
```

**2. Optional Configuration:**
```dart
class CustomWidget extends ConsumerWidget {
  final ThemeMode? themeMode;

  const CustomWidget({super.key, this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = themeMode ?? ref.watch(themeModeProvider);
    return ThemedContent(mode: mode);
  }
}
```

**3. Optional Data with Fetch:**
```dart
class DataDisplay extends ConsumerWidget {
  final Data? data;

  const DataDisplay({super.key, this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveData = data ?? ref.watch(dataProvider).value;
    if (effectiveData == null) {
      return LoadingIndicator();
    }
    return DataView(effectiveData);
  }
}
```

### Rules

- ✅ Use nullable parameters for values that can be provided OR derived
- ✅ Provide fallback via provider for runtime configuration
- ✅ Always handle null case explicitly
- ✅ Use descriptive variable names (e.g., `effectiveBookId`)
- ❌ NEVER hardcode default values in widget parameters
- ❌ NEVER assume parameter is always provided
- ❌ NEVER use magic strings or numbers as defaults

---

## Git Workflow

**Commit Format:**
```
<type>: <description>

<optional body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Types:** feat, fix, refactor, docs, test, chore

**Branches:**
- `main`: Stable branch
- `feature/MOD-XXX-description`: Feature branches

---

## Key References

- **Architecture Guide:** `doc/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- **Data Architecture:** `doc/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **Security Architecture:** `doc/arch/01-core-architecture/ARCH-003_Security_Architecture.md`
- **State Management:** `doc/arch/01-core-architecture/ARCH-004_State_Management.md`
- **Development Plan:** `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`
- **Project Structure:** `FLUTTER_PROJECT_STRUCTURE.md`
- **Quick Start:** `QUICKSTART.md`

---

## iOS Build Configuration

**IMPORTANT:** The project uses SQLCipher for encryption, not regular SQLite3.

**Dependencies:**
- ✅ `sqlcipher_flutter_libs` (for encrypted database)
- ❌ `sqlite3_flutter_libs` (DO NOT use - conflicts with SQLCipher)

**Podfile Configuration:**
The `ios/Podfile` includes a fix for ML Kit simulator builds:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Fix for ML Kit simulator build issue
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

**Troubleshooting iOS Build:**

If you encounter "different definitions in different modules" error:
```bash
flutter clean
cd ios && rm -rf Pods Podfile.lock .symlinks
cd .. && flutter pub get
cd ios && pod install
```

If you encounter "linking in object file built for iOS" (simulator issue):
- Verify `ios/Podfile` has EXCLUDED_ARCHS fix (see above)
- Run `cd ios && pod install && cd ..`

---

## Code Quality Standards (MANDATORY)

### Analyzer Warnings - Zero Tolerance Policy

**CRITICAL:** All code MUST pass `flutter analyze` with ZERO warnings before commit.

**Common Warnings to Fix:**

1. **Unused Imports:**
   ```dart
   // ❌ WRONG: Unused import
   import 'package:home_pocket/domain/repositories/transaction_repository.dart';

   // ✅ CORRECT: Remove if not used
   // (delete the import line)
   ```

2. **Unused Variables:**
   ```dart
   // ❌ WRONG: Declared but never used
   test('should work', () {
     final unused = 'value';
     expect(true, true);
   });

   // ✅ CORRECT: Remove unused variable
   test('should work', () {
     expect(true, true);
   });
   ```

3. **Incorrect @override Annotations:**
   ```dart
   // ❌ WRONG: Not actually overriding
   class MyTable extends Table {
     @override
     List<TableIndex> get customIndices => [...];  // Not overriding parent!
   }

   // ✅ CORRECT: Remove @override when not overriding
   class MyTable extends Table {
     List<TableIndex> get customIndices => [...];
   }
   ```

4. **Unused Local Variables in Tests:**
   ```dart
   // ❌ WRONG: Mock created but never verified
   test('test case', () {
     final mockRepo = MockRepository();
     // ... test code that doesn't use mockRepo
   });

   // ✅ CORRECT: Remove or use the mock
   test('test case', () {
     // Just remove it if not needed
   });
   ```

### Pre-Commit Checklist

**Before every commit, MUST verify:**

```bash
# 1. Run analyzer (MUST be 0 issues)
flutter analyze

# 2. Run formatter
dart format .

# 3. Run all tests
flutter test

# 4. Check for uncommitted generated files
git status
```

**Expected Output:**
```bash
# flutter analyze should show:
Analyzing home_pocket...
No issues found!

# flutter test should show:
00:XX +NNN: All tests passed!
```

### Automated Cleanup Rules

**When cleaning up warnings:**
1. ✅ Remove unused imports at the top of files
2. ✅ Remove unused variables in function bodies
3. ✅ Remove incorrect @override annotations
4. ✅ Keep necessary imports even if analyzer suggests removal (may be used in generated code)
5. ❌ Don't remove imports needed by generated `.g.dart` files
6. ❌ Don't suppress warnings with `// ignore:` comments (fix the root cause)

### Production Code vs Test Code

**Both must be clean:**
- Production code: `lib/`
- Test code: `test/`
- Integration tests: `integration_test/`

**No exceptions for test code** - tests are first-class code.

---

## Common Pitfalls

1. **Don't modify generated files** (`.g.dart`, `.freezed.dart`)
2. **Don't violate layer dependencies** (e.g., Domain importing Data)
3. **Don't skip code generation** after modifying annotated classes
4. **Don't mutate objects** - always use `copyWith`
5. **Don't add architecture docs without checking max number first**
6. **Don't forget to update INDEX.md** when adding new architecture docs
7. **Don't use `intl` version other than 0.20.2** (pinned by flutter_localizations)
8. **Don't add `sqlite3_flutter_libs`** - use only `sqlcipher_flutter_libs` (conflicts!)
9. **Don't modify `ios/Podfile` post_install** without preserving EXCLUDED_ARCHS fix
10. **Don't commit code with analyzer warnings** - fix ALL warnings before commit
11. **Don't hardcode widget parameter defaults** - use nullable + provider fallback pattern
12. **Don't duplicate repository provider definitions** - use single source in repository_providers.dart
13. **Don't use wrong Drift index syntax** - use `TableIndex` with Symbol syntax `{#columnName}`
14. **Don't skip AppInitializer** - initialize core services before runApp()
15. **Don't forget to regenerate code after merge** - run build_runner after git operations

---

**Project Status:** 🟢 Ready for Development (Phase 1: MOD-006 Security Module)
