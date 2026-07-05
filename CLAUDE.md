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

- **State:** Riverpod 3.1+ with `@riverpod` code generation (generator 4.x)
- **Models:** Freezed with `@freezed` for immutability (always use `copyWith`)
- **Database:** Drift with SQLCipher (type-safe SQL + encryption)
- **Routing:** Built-in `Navigator` / `MaterialPageRoute` + an `IndexedStack` tab shell (`lib/features/home/presentation/screens/main_shell_screen.dart`). No `go_router` dependency — do not assume GoRouter.
- **Localization:** flutter_localizations with ARB files

### Riverpod Provider Rules

- ONE `repository_providers.dart` per feature (single source of truth)
- Use case providers reference repositories via `ref.watch()`
- NEVER duplicate repository provider definitions
- NEVER throw `UnimplementedError` in providers
- Use Cases classes live in `lib/application/`, but providers wiring them live in feature's `presentation/providers/`

### Riverpod 3 conventions (vs 2.x)

Public Riverpod 3 surface is split across three entry points. Pick the right one or symbols won't resolve:

| Need | Import |
|---|---|
| `Provider`, `FutureProvider`, `StreamProvider`, `Notifier`, `AsyncNotifier`, `AsyncValue`, `ProviderContainer`, `ConsumerWidget`, `WidgetRef`, `ProviderScope` | `package:flutter_riverpod/flutter_riverpod.dart` |
| `StateNotifier`, `StateNotifierProvider`, `StateProvider`, `StateController`, `ChangeNotifierProvider` (legacy/discouraged) | `package:flutter_riverpod/legacy.dart` |
| `Override`, `ProviderListenable`, `ProviderException`, `Family`, `Refreshable`, `ProviderBase` | `package:flutter_riverpod/misc.dart` |

Generator/API changes that bit us during the 2 → 3 migration — keep these in mind:

- **Provider names strip the `Notifier` suffix.** `class LocaleNotifier` (annotated with `@riverpod`) now generates `localeProvider`, not `localeNotifierProvider`.
- **`AsyncValue.valueOrNull` was renamed to `.value`.** The old throwing `value` is gone; `.value` is now nullable.
- **Errors thrown by providers are wrapped in `ProviderException`** (`implements Exception`). Inner exception is on `.exception`. Tests that do `throwsA(isA<StateError>())` now need `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`.
- **Side-effect listeners belong in `ref.listen`, not `ref.watch`.** Riverpod 3 dropped some `watch`-driven side-effect rebuilds for legacy `StateNotifierProvider`s — use `ref.listen` for navigation, snackbars, etc. (see `FamilySyncNotificationRouteListener`).
- **Async test pattern: do NOT do bare `await container.read(provider.future)` on auto-dispose providers.** Riverpod 3 disposes the orphan read before the build settles, masking real values/errors with `Bad state: disposed during loading`. Use `waitForFirstValue<T>(container, provider)` in `test/helpers/test_provider_scope.dart` — it holds a `container.listen(..., fireImmediately: true)` subscription via a `Completer`.
- **Use `ProviderContainer.test()` in tests** instead of `ProviderContainer() + addTearDown(container.dispose)`. It auto-disposes on test teardown.

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
**Spec:** `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md`

---

## Amount Display Style

Use `AppTextStyles.amountLarge/amountMedium/amountSmall` (`lib/core/theme/app_text_styles.dart`) for all monetary values. These include `FontFeature.tabularFigures()` for alignment. Never use generic text styles for amounts.

---

## App Color Scheme (v1.6 — ADR-019 桜餅×若葉)

**v1.6 palette DECIDED — ADR-019 "Sakura Mochi × Wakaba" (2026-06-03).** Supersedes ADR-018 Teal Clarity entirely.

- **Primary (nav/tab/CTA/borderInputActive):** leaf green `#6FA36F` (dark `#8DC68D`) — NOT teal/coral. Red reserved exclusively for `error`.
- **FAB / add-entry:** sakura pink `#D98CA0` (dark `#E09DB4`) — ONE place pink appears. Do NOT spread it.
- **日常 Daily:** `#5FAE72`, amount text `#2E6B3A` (WCAG AA ≈7.0:1 on white)
- **悦己 Joy:** warm amber `#C8841A`, amount text `#A15C00` (WCAG AA ≈5.9:1). Dark joy/joyText `#E0A040`. Mauve `#A586B0` is gone.
- **Shared:** steel-blue `#5B8AC4` (unchanged — keeps green+amber+blue three-ledger distinction)
- **Background:** warm cream `#FBF7F4`; borders/dividers warm-family `#E6DDD8`/`#EAE1DC`
- **Semantic (unchanged):** success `#2FA37A` / warning `#C98A00` / error `#E5484D` / info `#2A8FB8`
- **joyRoiBg/joyRoiBorder:** keep green (ROI/success semantic, not joy identity)
- **happiness_ring_palette.dart:** out of scope — separate Butter palette for 悦己充盈环

Full light+dark hex-per-role table: `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`

---

## Widget Parameter Pattern

Use nullable parameters with provider fallback — never hardcode defaults:
```dart
final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
```

---

## iOS Build

- Use `sqlcipher_flutter_libs` at `^0.6.x` — NEVER `sqlite3_flutter_libs` (conflicts). `0.7.0+eol` is intentionally a do-nothing package; the project hasn't migrated to `sqlite3` 3.x yet.
- Drift schema is at **v23** (`schemaVersion => 23` in `lib/data/app_database.dart`). v22→v23 backfilled every `customIndices`-declared index (the getter is decorative — see `_createAllDeclaredIndexes()`); v21→v22 added `merchants` + `merchant_match_keys` (Phase 49); v20→v21 in Phase 40-04 (`exchange_rates` table + transaction currency columns; commit `adb2311a`); v19→v20 in Phase 36 added `shopping_items`.
- `ios/Podfile` `post_install` strips `-l"sqlite3"` from every Pod xcconfig. **Do not remove this.** `FirebaseMessaging` (and any pod declaring `s.libraries = 'sqlite3'`) otherwise pulls in the system `libsqlite3.tbd`, which wins `dlsym(RTLD_DEFAULT, "sqlite3_open")` over SQLCipher at runtime — `PRAGMA cipher_version` then returns empty and `encrypted_database.dart` throws `Bad state: SQLCipher not loaded - encryption unavailable`. SQLCipher's symbols are ABI-compatible, so stripping `-lsqlite3` doesn't break those pods.
- `ios/Podfile` has `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` fix for ML Kit
- Clean rebuild: `flutter clean && cd ios && rm -rf Pods Podfile.lock .symlinks && cd .. && flutter pub get && cd ios && pod install`

### Dependency pins to leave alone

These versions are tied together via a transitive `win32` constraint. Bumping any one in isolation will fail `flutter pub get` or break the iOS native build:

- `file_picker: ^11.0.2` — `^12.0.0-beta.*` ships a broken iOS Swift module (`FilePickerPlugin` duplicate definition); needs `win32 ^6.x`.
- `package_info_plus: ^9.0.1` — `^10.x` requires `win32 ^6.0.1`, incompatible with `file_picker 11.x`.
- `share_plus: ^12.0.2` — `^13.x` requires `win32 ^6.0.1`, same conflict.

If you need to upgrade the trio, do them together AND verify `flutter build ios --debug --no-codesign` succeeds.

---

## Module Development Priority

See `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`:
1. **Infrastructure:** MOD-006 Security, BASIC-003 i18n
2. **Core Accounting:** MOD-001 Basic Accounting, MOD-003 Dual Ledger
3. **Sync & Analytics:** MOD-004 Family Sync, MOD-007 Analytics, MOD-008 Settings
4. **Enhanced:** MOD-005 OCR, MOD-013 Gamification

---

## Architecture Docs (`docs/arch/`)

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

- **Architecture:** `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- **Data:** `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **Security:** `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md`
- **State:** `docs/arch/01-core-architecture/ARCH-004_State_Management.md`
- **Dev Plan:** `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md`

---

## Common Pitfalls

1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
   *[Partially enforced — AUDIT-10 catches stale committed files; hand-edits matching generator output go undetected]*
2. Don't violate layer dependencies (Domain must not import Data)
   *[Structurally enforced — arch test layer_import_rules_test.dart scans REAL imports (relative-safe) for domain/application/infrastructure directions; domain_import_rules_test.dart guards the yaml text. CAVEAT: import_guard deny-mode yamls are inert for intra-project imports (the lint matches `package:` prefixes verbatim but this repo enforces prefer_relative_imports) — only allow-mode subdirectory yamls actually enforce via custom_lint. Do not treat a green `dart run custom_lint` as layer-compliance evidence]*
3. Don't skip code generation after modifying annotated classes
   *[Structurally enforced — AUDIT-10 CI guardrail blocks PRs with stale generated files]*
4. Don't mutate objects — always use `copyWith`
   *[Manually-checked only — freezed enforces it on @freezed classes; general mutation undetected]*
5. Don't use `intl` version other than 0.20.2 (pinned by flutter_localizations)
   *[Structurally enforced — exact pin in pubspec.yaml line 18]*
6. Don't add `sqlite3_flutter_libs` (use only `sqlcipher_flutter_libs`)
   *[Structurally enforced — import_guard deny rule + AUDIT-09 CI guardrail]*
7. Don't modify Podfile `post_install` without preserving EXCLUDED_ARCHS fix AND the `-lsqlite3` strip
   *[Manually-checked only — no Podfile lint; relies on reviewer + iOS runtime verification (PRAGMA cipher_version returns empty if strip is removed)]*
8. Don't commit with analyzer warnings
   *[Structurally enforced — flutter analyze CI step (audit.yml line 34)]*
9. Don't hardcode widget parameter defaults — use nullable + provider fallback
   *[Manually-checked only — no automated detection]*
10. Don't duplicate repository provider definitions
   *[Structurally enforced — arch test provider_graph_hygiene_test.dart + riverpod_lint]*
11. Don't use wrong Drift index syntax — use `TableIndex` with `{#column}`
   *[Manually-checked only — Drift compiler does not enforce naming or symbol-syntax conventions]*
12. Don't skip AppInitializer — initialize core services before `runApp()`
   *[Partially enforced — provider_graph_hygiene_test.dart catches UnimplementedError providers; "forgot to call initialize()" is manual]*
13. Don't forget to regenerate code after merge/pull
   *[Structurally enforced — AUDIT-10 CI guardrail catches stale generated files post-merge]*
