# Coding Conventions

**Analysis Date:** 2026-05-21

## Naming Patterns

**Files:**
- Dart source: `snake_case.dart` (e.g., `hash_chain_service.dart`, `app_text_styles.dart`)
- Generated files: `*.g.dart` (riverpod_generator / json_serializable), `*.freezed.dart` (freezed) — never hand-edit
- State providers: `state_{domain}.dart` (e.g., `state_joy_metric_variant.dart`, `state_locale.dart`)
- Repository wiring: exactly `repository_providers.dart` per feature presentation/providers/ directory

**Classes:**
- Freezed models: `PascalCase` with `abstract class Name with _$Name` (e.g., `class Book with _$Book`)
- Riverpod notifiers: `PascalCase` ending in `Notifier` or descriptive noun (e.g., `LocaleNotifier`, `SelectedJoyMetricVariant`)
- Use cases: `VerbNounUseCase` (e.g., `CreateTransactionUseCase`, `GetHappinessReportUseCase`)
- Repositories: `NounRepository` (interface), `NounRepositoryImpl` (implementation)
- DAOs: `NounDao` (e.g., `AnalyticsDao`)
- Table definitions: `PascalCase` plural noun (e.g., `Transactions`) with `@DataClassName('RowType')` annotation
- Infrastructure services: `NounService` (e.g., `KeyManager`, `FieldEncryptionService`, `HashChainService`)

**Functions/Methods:**
- `camelCase` for all Dart functions and methods
- Use case entry points always named `execute()`
- Riverpod generator functions: camelCase (e.g., `getMonthlyReportUseCase(Ref ref)`) — generator strips `Notifier` suffix automatically

**Variables:**
- `camelCase` for locals and fields
- Private fields/helpers prefixed with `_` (e.g., `_MockAnalyticsRepository`, `_fontFamily`, `_ptvfBaseByCurrency`)

**Providers (Riverpod generator convention):**
- `@riverpod class LocaleNotifier` → generates `localeProvider` (NOT `localeNotifierProvider`)
- `@riverpod FutureOr<X> currentLocale(Ref ref)` → generates `currentLocaleProvider`
- KeepaliveProviders: `syncEngineProvider`, `transactionChangeTrackerProvider`, `appMerchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`

## Immutability (CRITICAL)

Always use `copyWith` on Freezed models — never mutate fields directly. Freezed enforces this on `@freezed` classes. Plain Dart classes (e.g., `MerchantCategoryPreference`) implement manual `copyWith`.

```dart
// CORRECT
state = state.copyWith(l1: updated, isDirty: true);

// WRONG — mutation
state.l1 = updated; // compile error on @freezed; manual class: silent bug
```

## File Organization

- Typical source file: 200–400 lines. Hard cap: 800 lines.
- Organize by feature/domain, not by type:
  - `lib/features/{feature}/domain/` — only models/ and repositories/ (interfaces)
  - `lib/features/{feature}/presentation/` — screens/, widgets/, providers/
  - `lib/application/{domain}/` — Use Cases and business services (GLOBAL, not inside features)
  - `lib/infrastructure/{capability}/` — technology wrappers (crypto, ml, sync, i18n, security)
  - `lib/data/` — ALL tables, DAOs, repository implementations
- Exceptions currently over 800 lines (known, tracked): `home_hero_card.dart` (921), `voice_input_screen.dart` (771), `analytics_dao.dart` (746), `transaction_confirm_screen.dart` (743), `analytics_screen.dart` (739)

## Riverpod Provider Rules

**Single-source-of-truth per feature:**

Each feature has exactly one `repository_providers.dart` at `lib/features/{feature}/presentation/providers/repository_providers.dart`. All other provider files in that directory MUST be named `state_*.dart`. Repository/UseCase/Service providers live ONLY in `repository_providers.dart`. This is enforced by `test/architecture/provider_graph_hygiene_test.dart`.

```dart
// CORRECT — repository_providers.dart
@riverpod
GetMonthlyReportUseCase getMonthlyReportUseCase(Ref ref) {
  return GetMonthlyReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

// WRONG — in state_analytics.dart
@riverpod
GetMonthlyReportUseCase getMonthlyReportUseCase(Ref ref) { ... } // HIGH-04 violation
```

**NEVER throw `UnimplementedError` in production providers** — enforced by `test/architecture/provider_graph_hygiene_test.dart` HIGH-06.

**No duplicate provider names within `lib/features/`** — enforced by HIGH-04 global uniqueness test.

## Riverpod 3 Import Rules

Import from the correct entry point — wrong imports cause symbol-not-found compile errors:

| Need | Import |
|------|--------|
| `Provider`, `FutureProvider`, `StreamProvider`, `Notifier`, `AsyncNotifier`, `AsyncValue`, `ProviderContainer`, `ConsumerWidget`, `WidgetRef`, `ProviderScope` | `package:flutter_riverpod/flutter_riverpod.dart` |
| `StateNotifier`, `StateNotifierProvider`, `StateProvider` (legacy/discouraged) | `package:flutter_riverpod/legacy.dart` |
| `Override`, `ProviderListenable`, `ProviderException`, `Family`, `Refreshable`, `ProviderBase` | `package:flutter_riverpod/misc.dart` |

**Riverpod 3 API changes to remember:**
- `AsyncValue.valueOrNull` was removed; use `.value` (now nullable)
- Errors from providers are wrapped in `ProviderException`; `.exception` holds the inner error
- Side-effect listeners → `ref.listen(...)` not `ref.watch(...)` (navigation, snackbars, etc.)
- `currentLocaleProvider` name: generated from `class LocaleNotifier` → `localeProvider`; `currentLocale(Ref ref)` → `currentLocaleProvider`

## Widget Parameter Pattern

Use nullable constructor parameters with provider fallback — never hardcode defaults:

```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key, this.bookId});
  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
    // ...
  }
}
```

## Amount Display Style

Always use `AppTextStyles.amountLarge`, `amountMedium`, or `amountSmall` from `lib/core/theme/app_text_styles.dart` for monetary values. These embed `FontFeature.tabularFigures()` for numeric alignment. Never use generic text styles for amounts.

```dart
// CORRECT
Text(formatted, style: AppTextStyles.amountLarge)

// WRONG
Text(formatted, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700))
```

## Drift Table Conventions

Use `TableIndex` with Symbol syntax. Naming: `idx_{table_abbrev}_{columns}`.

```dart
// CORRECT
List<TableIndex> get customIndices => [
  TableIndex(name: 'idx_tx_book_id', columns: {#bookId}),
  TableIndex(name: 'idx_tx_book_timestamp', columns: {#bookId, #timestamp}),
];

// WRONG
@override  // no @override
List<Index> get customIndices => [  // Index → TableIndex
  Index('idx', 'book_id'),          // no string syntax
];
```

Custom constraints use `customConstraints` list with SQL string literals:
```dart
@override
List<String> get customConstraints => [
  'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
  "CHECK(entry_source IN ('manual', 'voice', 'ocr'))",
];
```

## i18n Rules

All UI text MUST go through `S.of(context)` (the generated `app_localizations` class). Never hardcode display strings.

```dart
// CORRECT
final l10n = S.of(context);
Text(l10n.appName)

// WRONG
Text('Home')  // triggers test/architecture/hardcoded_cjk_ui_scan_test.dart
```

**Formatters:**
- Currency → `NumberFormatter.formatCurrency(amount, currencyCode, locale)` (`lib/infrastructure/i18n/formatters/number_formatter.dart`)
- Dates → `DateFormatter.formatDate(date, locale)` (`lib/infrastructure/i18n/formatters/date_formatter.dart`)
- Always pass locale from `currentLocaleProvider` → `ref.watch(currentLocaleProvider).value ?? const Locale('ja')`

**Format rules:**
- JPY: 0 decimal places (`¥1,235`)
- USD / CNY / EUR / GBP: 2 decimal places
- Date ja: `yyyy/MM/dd` | en: `MM/dd/yyyy` | zh: `yyyy年MM月dd日`
- Compact numbers ja/zh: `123万` | en: `1.23M` (via `NumberFormatter.formatCompact`)

**ARB maintenance:** Update all three ARB files (`lib/l10n/app_en.arb`, `app_ja.arb`, `app_zh.arb`) when adding keys; run `flutter gen-l10n` and verify 0 warnings before commit. Enforced by `test/architecture/arb_key_parity_test.dart`.

## Crypto Rules

All cryptographic operations MUST route through `lib/infrastructure/crypto/`:

| Operation | Correct path |
|-----------|-------------|
| Key management | `lib/infrastructure/crypto/services/key_manager.dart` |
| Field encryption | `lib/infrastructure/crypto/services/field_encryption_service.dart` |
| Hash chain | `lib/infrastructure/crypto/services/hash_chain_service.dart` |
| DB encryption executor | `lib/infrastructure/crypto/database/encrypted_database.dart` |

**NEVER:**
- Implement custom crypto primitives (use `package:cryptography` via KeyManager)
- Access `flutter_secure_storage` directly outside `KeyManager`
- Log sensitive data (enforced by `test/architecture/production_logging_privacy_test.dart`)

Sensitive names forbidden in log calls: `body`, `token`, `signature`, `deviceId`, `groupId`, `inviteCode`, `transactionId`, `payload`, `encryptedPayload`, `publicKey`, `privateKey`. Logging must be guarded by `if (kDebugMode)`.

## Import Organization

Enforced by `analysis_options.yaml` rules:
1. `dart:` SDK imports
2. `package:flutter/...` and `package:flutter_riverpod/...`
3. Other `package:` imports
4. Relative imports (`../`, `./`) — `prefer_relative_imports: true` lint rule

All imports use single quotes (`prefer_single_quotes: true`). Generated files excluded from analyzer (`**/*.g.dart`, `**/*.freezed.dart`).

## Layer Dependency Rules (Thin Feature Pattern)

Dependency flow: `Presentation → Application → Domain ← Data ← Infrastructure`

**Features NEVER contain:** `application/`, `infrastructure/`, `data/tables/`, `data/daos/`.

**Import guard** (enforced via `import_guard_custom_lint` + arch tests):
- Domain models/repositories: deny `infrastructure/**`, `data/**`, `application/**`, `features/**/presentation/**`, `flutter/**`
- Presentation: deny `infrastructure/**`, `data/daos/**`, `data/tables/**`

Enforced by:
- `test/architecture/domain_import_rules_test.dart`
- `test/architecture/presentation_layer_rules_test.dart`
- `dart run custom_lint --no-fatal-infos` in CI

## EntrySource Pattern (Phase 17)

```dart
// lib/features/accounting/domain/models/entry_source.dart
enum EntrySource { manual, voice, ocr }
```

- `entrySource` is a **required, no-default** field in `CreateTransactionParams` — every push site MUST declare it explicitly (D-06)
- The 3 active push sites: `transaction_confirm_screen.dart` (manual), `voice_input_screen.dart` (voice), demo data (manual)
- `EntrySource.ocr` is reserved for MOD-005 OCR — accepted by schema CHECK constraint but no production writer yet

## Joy Formatter (Phase 13 rename)

Use `formatJoyCumulative` from `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart`.
`formatJoyDensity` was deleted in Phase 13 — do NOT reference it anywhere.

## Error Handling

```dart
// Application layer use cases return Result<T> or throw typed exceptions
// Presentation layer providers: catch and surface AsyncValue.error
// UI: handle AsyncError state explicitly — never silently ignore
```

Logging is conditional on `kDebugMode` — never use bare `print()` (`avoid_print: true` lint enforced).

## Code Quality Checklist

Before marking work complete:
- [ ] `flutter analyze` → 0 issues (CI hard-fails on any warning)
- [ ] `dart format .` applied
- [ ] `flutter test --coverage` passes
- [ ] `flutter pub run build_runner build --delete-conflicting-outputs` run after any `@riverpod`, `@freezed`, Drift table, or ARB change
- [ ] No `// ignore:` suppressions — fix root cause (stale suppressions caught by `test/architecture/stale_suppressions_scan_test.dart`)
- [ ] Functions < 50 lines, files < 800 lines
- [ ] No deep nesting (> 4 levels)
- [ ] All UI strings via `S.of(context)`
- [ ] No hardcoded monetary values — use `AppTextStyles.amountLarge/amountMedium/amountSmall`
- [ ] No `sqlite3_flutter_libs` in pubspec (AUDIT-09 blocks PR)

## Commit Message Format

```
<type>: <description>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

Branches: `main` (stable), `feature/MOD-XXX-description`

## Common Pitfalls (with enforcement status)

| Pitfall | Enforcement |
|---------|-------------|
| Modifying `.g.dart` / `.freezed.dart` | Structural (AUDIT-10 CI) |
| Domain importing Data/Infrastructure/Application | Structural (import_guard + arch test) |
| Skipping build_runner after annotated changes | Structural (AUDIT-10 CI) |
| Mutating `@freezed` objects | Structural (Freezed compiler) |
| Using `sqlite3_flutter_libs` | Structural (import_guard deny + AUDIT-09 CI) |
| Committing with analyzer warnings | Structural (flutter analyze CI step) |
| Duplicate repository provider definitions | Structural (provider_graph_hygiene_test.dart) |
| `UnimplementedError` in providers | Structural (provider_graph_hygiene_test.dart) |
| Wrong Drift index syntax | Manual — no automated detection |
| Hardcoding widget parameter defaults | Manual — no automated detection |
| Modifying Podfile post_install without preserving `-lsqlite3` strip | Manual — iOS runtime verification only |
| Skipping AppInitializer | Partially (provider_graph_hygiene_test catches UnimplementedError) |
| Regenerating after merge/pull | Structural (AUDIT-10 CI) |

---

*Convention analysis: 2026-05-21*
