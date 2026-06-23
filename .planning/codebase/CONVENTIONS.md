# Coding Conventions

**Analysis Date:** 2026-06-23

This is a Flutter/Dart project using Clean Architecture (5 layers), Riverpod 3, Freezed, and Drift+SQLCipher. Conventions are enforced via `analysis_options.yaml` (`flutter_lints` + `custom_lint`), architecture tests under `test/architecture/`, and CI guardrails in `.github/workflows/audit.yml`.

## Naming Patterns

**Files:**
- `snake_case.dart` for all source files (`create_transaction_use_case.dart`, `app_palette.dart`)
- Use-case files end in `_use_case.dart`; repository impls end in `_repository_impl.dart`; DAOs end in `_dao.dart`
- Riverpod provider files: `repository_providers.dart` (one per feature), `state_*.dart` for state notifiers
- Generated siblings: `*.g.dart` (Riverpod/json/drift), `*.freezed.dart` (Freezed) — NEVER hand-edit

**Classes/Types:**
- `PascalCase` — `CreateTransactionUseCase`, `Transaction`, `AppPalette`
- Use-case params as a dedicated immutable class: `CreateTransactionParams` (see `lib/application/accounting/create_transaction_use_case.dart:17`)
- Mock classes in tests: `_MockX`/`_FakeX` (private, underscore-prefixed)

**Functions/Variables:**
- `camelCase` — `execute`, `resolvedLedgerType`, `joyFullness`
- Private members underscore-prefixed: `_transactionRepo`, `_genesisHash`, `_wrap`
- Enums: `PascalCase` type, `camelCase` values — `enum LedgerType { daily, joy }`

**Drift indices:** `idx_{table}_{columns}` with `TableIndex(name: ..., columns: {#columnName})` Symbol syntax (NOT `Index()`).

## Code Style

**Formatting:**
- `dart format .` — standard Dart formatter, 2-space indent
- NOTE: the repo is NOT fully format-clean across `test/`; never run `dart format` over the whole `test/` tree (golden baselines / scaffolds depend on stability)

**Linting (`analysis_options.yaml`):**
- Base: `package:flutter_lints/flutter.yaml`
- Custom rules ENFORCED:
  - `prefer_single_quotes: true` — always single quotes
  - `prefer_relative_imports: true` — relative imports within `lib/` (`../../shared/utils/result.dart`)
  - `avoid_print: true` — no `print()` in production code
- `invalid_annotation_target: ignore` (Freezed/json compatibility)
- Excludes: `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- `custom_lint` plugins: `import_guard` (layer + `sqlite3_flutter_libs` deny), `riverpod_lint`
- **Zero analyzer warnings required before commit** (CI: `flutter analyze` in audit.yml). Do NOT suppress with `// ignore:` — fix root cause.

## Import Organization

**Order (observed):**
1. Dart SDK (`dart:async`, `dart:io`)
2. External packages (`package:flutter/...`, `package:flutter_riverpod/...`, `package:ulid/...`)
3. Relative project imports (`../../shared/utils/result.dart`)

**Riverpod 3 import split (CRITICAL — symbols won't resolve otherwise):**
- Core (`Provider`, `Notifier`, `AsyncValue`, `ConsumerWidget`, `WidgetRef`): `package:flutter_riverpod/flutter_riverpod.dart`
- Legacy (`StateNotifier`, `StateProvider`): `package:flutter_riverpod/legacy.dart`
- Misc (`Override`, `ProviderListenable`, `Family`): `package:flutter_riverpod/misc.dart`

**Path aliases:** import aliasing used to disambiguate cross-feature provider sources, e.g. `import '.../application/accounting/repository_providers.dart' as app_accounting;` then `ref.watch(app_accounting.appAppDatabaseProvider)`.

## Error Handling

**Use-case layer — Result type, no throwing:**
- Application use cases return `Result<T>` (`lib/shared/utils/result.dart`) instead of throwing
- `Result.success(data)` / `Result.error('message')`; check via `.isSuccess` / `.isError` / `.error`
- Validate at the top of `execute()` and early-return `Result.error(...)`:
  ```dart
  if (params.amount <= 0) {
    return Result.error('amount must be greater than 0');
  }
  ```
- Shared validators are centralized so two call sites never drift (e.g. `validateCurrencyTriple` in `lib/shared/utils/currency_conversion.dart` used by both Create and Update use cases)

**Crypto/security:** operations throw on hard failure (e.g. `Bad state: SQLCipher not loaded`); never log sensitive data.

**Immutability:** ALWAYS use `copyWith` on `@freezed` models. Never mutate. Params classes are `const` constructors with `final` fields.

## Logging

**Framework:** No `print()` (lint-blocked). Production logging routed through the audit/security logger; a `production_logging_privacy_test.dart` architecture test guards against privacy leaks.

**Patterns:**
- Never log sensitive data (keys, amounts tied to identity, recovery phrases)
- Use `lib/infrastructure/security/audit_logger.dart` for audit events

## Comments

**When to Comment:**
- Default: no comments. Comment only when WHY is non-obvious.
- Heavy use of decision-traceability comments referencing ADRs/phase IDs: `// D-06: required, no default`, `// ADR-020 .round()`, `// STORE-04 partial-triple invariant`. These tie code to `docs/arch/03-adr/` decisions — preserve them.
- Dartdoc `///` on public classes/use cases describing responsibility (see `CreateTransactionUseCase` header)

## Function Design

**Size:** Functions small (<50 lines target). Long `execute()` methods are numbered-step structured (`// 1. Validate`, `// 2. Verify category`).

**Parameters:** Named + `required` for all constructor/factory params. Dependencies injected via constructor (`required TransactionRepository transactionRepository`), assigned to private finals in initializer list. Optional collaborators are nullable (`SyncEngine? syncEngine`) and called fire-and-forget (`_syncEngine?.onTransactionChanged()`).

**Return Values:** `Future<Result<T>>` from use cases. Nullable returns from repositories (`findById` → `T?`).

## Module Design

**Exports:** Relative imports, no barrel files generally. `show` clauses used to narrow cross-feature imports (`... show shoppingItemChangeTrackerProvider, syncEngineProvider`).

**Layer rules (structurally enforced via `import_guard` + arch tests):**
- Domain (`features/{f}/domain/`) must NOT import Data layer (`domain_import_rules_test.dart`)
- Features NEVER contain `application/`, `infrastructure/`, `data/tables/`, `data/daos/` ("Thin Feature")
- Dependency flow: Presentation → Application → Domain ← Data ← Infrastructure

**Riverpod provider rules:**
- ONE `repository_providers.dart` per feature (single source of truth); no duplicate repo provider definitions (enforced by `provider_graph_hygiene_test.dart` + `riverpod_lint`)
- Use `@riverpod` codegen. Provider names strip `Notifier` suffix (`LocaleNotifier` → `localeProvider`)
- NEVER throw `UnimplementedError` in providers
- Side-effect listeners (navigation, snackbars) belong in `ref.listen`, not `ref.watch`
- Widget params: nullable + provider fallback, never hardcoded defaults: `bookId ?? ref.watch(currentBookIdProvider).value`

---

*Convention analysis: 2026-06-23*
