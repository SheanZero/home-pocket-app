# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

---

## Project Overview

**Home Pocket (まもる家計簿)** is a local-first, privacy-focused family accounting app with a dual-ledger system. Zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design.

**Current Phase:** Phase 1 - Infrastructure Layer (v0.1.0)
**Target:** iOS 14+ / Android 7+ (API 24+)

---

## Essential Commands

```bash
# Setup & code generation
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Development
flutter run                        # Run app
flutter pub run build_runner watch  # Watch mode

# Quality checks (ALL must pass before commit)
flutter analyze    # MUST be 0 issues
dart format .
flutter test
flutter test --coverage            # ≥80% required
```

**Always run build_runner after:** modifying `@riverpod`, `@freezed`, Drift tables, or ARB files. Also after git merge/rebase/pull.

---

## Architecture

### Clean Architecture (5 Layers)

```
lib/
├── infrastructure/       # Project-wide infrastructure (NEVER in features/)
│   ├── crypto/          # Encryption (key_manager, field_encryption, hash_chain)
│   ├── ml/              # ML/OCR (mlkit, tflite, merchant_database)
│   ├── i18n/            # Formatters (date_formatter, number_formatter)
│   ├── sync/            # Sync technology (crdt, bluetooth, nfc, wifi)
│   ├── security/        # biometric_service, secure_storage, audit_logger
│   └── platform/        # Platform-specific wrappers
├── application/          # Global business logic (Use Cases + Services)
│   ├── accounting/      # Transaction CRUD use cases
│   ├── dual_ledger/     # Classification service, rule engine
│   ├── ocr/             # Receipt scanning & parsing
│   ├── security/        # Hash chain verification, recovery kit
│   ├── analytics/       # Reports, budget calculation
│   └── settings/        # Backup export/import
├── data/                 # Shared data layer (CROSS-FEATURE)
│   ├── app_database.dart
│   ├── tables/          # ALL Drift table definitions
│   ├── daos/            # ALL data access objects
│   └── repositories/    # ALL repository implementations
├── features/             # Feature modules ("Thin Feature" pattern)
│   └── {feature}/
│       ├── domain/       # ONLY: models/ + repositories/ (interfaces)
│       └── presentation/ # screens/, widgets/, providers/
├── core/                 # config/, constants/, initialization/, router/, theme/
├── shared/               # widgets/, extensions/, utils/
└── l10n/                # Internationalization (ja, zh, en)
```

### Thin Feature Rule

Features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`.

### Placement Decision Rule

1. Technology/platform capability → `lib/infrastructure/`
2. Business logic / Use Case → `lib/application/{domain}/`
3. Data access (tables, DAOs, repo impl) → `lib/data/`
4. Domain model or repo interface → `lib/features/{feature}/domain/`
5. UI → `lib/features/{feature}/presentation/`
6. Not sure → Default to `lib/` (safer, easier to refactor)

### Dependency Flow

```
Presentation → Application → Domain ← Data ← Infrastructure
```

Domain is independent. Outer layers depend on inner, never reverse.

### Key Patterns

- **State:** Riverpod 2.4+ with `@riverpod` code generation
- **Models:** Freezed with `@freezed` for immutability (always use `copyWith`)
- **Database:** Drift with SQLCipher (type-safe SQL + encryption)
- **Routing:** GoRouter
- **Localization:** flutter_localizations with ARB files

### Riverpod Provider Rules

- ONE `repository_providers.dart` per feature (single source of truth)
- Use case providers reference repositories via `ref.watch()`
- NEVER duplicate repository provider definitions
- NEVER throw `UnimplementedError` in providers
- Use Cases classes live in `lib/application/`, but providers wiring them live in feature's `presentation/providers/`

---

## Drift TableIndex Syntax

Use `TableIndex` with Symbol syntax. Common mistakes to avoid:

```dart
// ✅ CORRECT
List<TableIndex> get customIndices => [
  TableIndex(name: 'idx_transactions_book_id', columns: {#bookId}),
  TableIndex(name: 'idx_transactions_book_timestamp', columns: {#bookId, #timestamp}),
];

// ❌ WRONG: Index() constructor, @override annotation, column refs without #
```

- Use `TableIndex` (not `Index`), `{#columnName}` (Symbol syntax), no `@override`
- Naming: `idx_{table}_{columns}`

---

## Security Architecture

**4-Layer Encryption:**
1. Database: SQLCipher AES-256-CBC (256k PBKDF2)
2. Field: ChaCha20-Poly1305 AEAD
3. File: AES-256-GCM (photos)
4. Transport: TLS 1.3 + E2EE (P2P sync)

**Key Management:** Ed25519 device keys, BIP39 recovery phrase, HKDF derivation, biometric lock

**Integrity:** Blockchain-style hash chain with incremental verification

### Crypto Rules

All crypto operations MUST use `lib/infrastructure/crypto/`:
- Key management: `services/key_manager.dart`
- Field encryption: `services/field_encryption_service.dart`
- Hash chain: `services/hash_chain_service.dart`
- DB encryption: `database/createEncryptedExecutor`
- NEVER implement custom crypto, access flutter_secure_storage directly, or log sensitive data

---

## App Initialization

Core services MUST be initialized before `runApp()` via `AppInitializer` (`lib/core/initialization/app_initializer.dart`).

**Order:** KeyManager → Database → Other services (database requires keys)

**Pattern:** `WidgetsFlutterBinding.ensureInitialized()` → `ProviderContainer()` → `AppInitializer.initialize(container)` → `UncontrolledProviderScope` with error fallback screen

---

## Dual Ledger System

**Survival Ledger (生存账本):** Daily necessities (food, housing, transport) - Green theme
**Soul Ledger (灵魂账本):** Self-investment (hobbies, education) - Purple theme + celebration

**3-Layer Classification:** Rule Engine → Merchant Database (500+ merchants) → ML Classifier (TFLite, 85%+)

---

## i18n Rules

**Languages:** Japanese (ja, default), Chinese (zh), English (en)

**Mandatory:**
- All UI text via `S.of(context)` — never hardcode strings
- Dates via `DateFormatter` (`lib/infrastructure/i18n/formatters/date_formatter.dart`)
- Currency via `NumberFormatter` (`lib/infrastructure/i18n/formatters/number_formatter.dart`)
- Always pass locale from `currentLocaleProvider`
- Update ALL 3 ARB files when adding translations, then run `flutter gen-l10n`

**Formatting:**
- JPY: ¥1,235 (0 decimals) | USD/CNY/EUR/GBP: 2 decimals
- Date: ja `2026/02/04` | en `02/04/2026` | zh `2026年02月04日`
- Compact: ja/zh `123万` | en `1.23M`

**Config:** `l10n.yaml` → output class `S`, dir `lib/generated`
**Spec:** `doc/arch/02-module-specs/MOD-014_i18n.md`

---

## Amount Display Style

Use `AppTextStyles.amountLarge/amountMedium/amountSmall` (`lib/core/theme/app_text_styles.dart`) for all monetary values. These include `FontFeature.tabularFigures()` for alignment. Never use generic text styles for amounts.

---

## Widget Parameter Pattern

Use nullable parameters with provider fallback — never hardcode defaults:
```dart
final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
```

---

## iOS Build

- Use `sqlcipher_flutter_libs` — NEVER `sqlite3_flutter_libs` (conflicts)
- `ios/Podfile` has `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` fix for ML Kit
- Clean rebuild: `flutter clean && cd ios && rm -rf Pods Podfile.lock .symlinks && cd .. && flutter pub get && cd ios && pod install`

---

## Module Development Priority

See `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`:
1. **Infrastructure:** MOD-006 Security, MOD-014 i18n
2. **Core Accounting:** MOD-001 Basic Accounting, MOD-003 Dual Ledger
3. **Sync & Analytics:** MOD-004 Family Sync, MOD-007 Analytics, MOD-008 Settings
4. **Enhanced:** MOD-005 OCR, MOD-013 Gamification

---

## Architecture Docs (`doc/arch/`)

- `01-core-architecture/ARCH-{NNN}_{Name}.md`
- `02-module-specs/MOD-{NNN}_{Name}.md`
- `03-adr/ADR-{NNN}_{Name}.md`

Always check max number before creating, use next sequential, update INDEX.md. See `.claude/rules/arch.md` for full workflow.

---

## Code Quality

- Zero analyzer warnings before commit
- Don't suppress with `// ignore:` — fix root cause
- Don't remove imports needed by `.g.dart` files
- Tests are first-class code (same standards as production)

---

## Git Workflow

**Format:** `<type>: <description>` (feat, fix, refactor, docs, test, chore)
**Branches:** `main` (stable), `feature/MOD-XXX-description`

---

## Key References

- **Architecture:** `doc/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- **Data:** `doc/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **Security:** `doc/arch/01-core-architecture/ARCH-003_Security_Architecture.md`
- **State:** `doc/arch/01-core-architecture/ARCH-004_State_Management.md`
- **Dev Plan:** `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`

---

## Common Pitfalls

1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
2. Don't violate layer dependencies (Domain must not import Data)
3. Don't skip code generation after modifying annotated classes
4. Don't mutate objects — always use `copyWith`
5. Don't use `intl` version other than 0.20.2 (pinned by flutter_localizations)
6. Don't add `sqlite3_flutter_libs` (use only `sqlcipher_flutter_libs`)
7. Don't modify Podfile `post_install` without preserving EXCLUDED_ARCHS fix
8. Don't commit with analyzer warnings
9. Don't hardcode widget parameter defaults — use nullable + provider fallback
10. Don't duplicate repository provider definitions
11. Don't use wrong Drift index syntax — use `TableIndex` with `{#column}`
12. Don't skip AppInitializer — initialize core services before `runApp()`
13. Don't forget to regenerate code after merge/pull
