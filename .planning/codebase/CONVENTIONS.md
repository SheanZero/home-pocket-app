# Coding Conventions

**Analysis Date:** 2026-08-08

## Naming Patterns

**Files:**
- Dart files use lowercase `snake_case.dart`; generated companions use the source basename with `.g.dart` or `.freezed.dart`, for example `lib/data/app_database.dart` and `lib/data/app_database.g.dart`.
- Tests mirror the subject and append `_test.dart`, grouped under `test/unit/`, `test/data/`, `test/infrastructure/`, `test/widget/`, `test/golden/`, or `test/architecture/`.

**Functions:**
- Functions and methods use lower camel case (`getCurrentGroup`, `validateCurrencyTriple`). Private implementation members are prefixed with `_`.
- Constructors are named constructors where a distinct setup is needed (`AppDatabase.forTesting()`); otherwise use required named parameters.

**Variables:**
- Locals and fields use lower camel case. Immutable fields are `final`; constants use lower camel case private names or descriptive `static const` names.
- Boolean names read as predicates (`isPrivate`, `isSuccess`, `animationsEnabled`).

**Types:**
- Classes, enums, extensions, and typedefs use UpperCamelCase (`CreateTransactionUseCase`, `GroupStatus`). Acronyms remain readable (`ULID` appears through package APIs rather than custom names).
- Domain models are immutable Freezed classes; repository contracts live in feature domain folders and implementations end in `_impl`.

## Code Style

**Formatting:**
- `dart format` style is enforced; source uses trailing commas in multiline calls and declarations. Single quotes are preferred by the linter.
- `analysis_options.yaml` includes `flutter_lints`, excludes generated files, and enables `prefer_single_quotes`, `prefer_relative_imports`, and `avoid_print`.

**Linting:**
- `flutter analyze` is the primary gate. Riverpod and import-lint plugins run through `analysis_options.yaml`; import-lint rules reject forbidden layer dependencies and plaintext SQLite packages.
- Do not hand-edit generated files excluded by analyzer (`*.g.dart`, `*.freezed.dart`); change annotations/source and run build generation.

## Import Organization

**Order:**
1. Dart SDK imports.
2. Flutter/package imports.
3. Project package or relative imports, with relative imports preferred by lint configuration.

Imports are generally separated by blank lines between groups, as in `lib/application/accounting/create_transaction_use_case.dart`.

**Path Aliases:**
- No custom import alias is configured. `package:home_pocket/...` is common for cross-layer imports; relative imports are preferred where practical.

## Error Handling

**Patterns:**
- Application use cases return `Result<T>` for expected validation/business failures (`lib/shared/utils/result.dart`), using `Result.error(...)` rather than throwing.
- Infrastructure boundaries catch platform/network exceptions and fail closed or return nullable/error results (`lib/infrastructure/security/secure_storage_service.dart`, `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`).
- Invalid state and invariant violations use typed exceptions such as `StateError`, and tests assert them with `throwsA(isA<StateError>())` (`test/data/repositories/group_repository_impl_test.dart`).
- Preserve stack traces when logging initialization failures; `lib/core/initialization/app_initializer.dart` catches `(e, st)` and reports structured failures.

## Logging

**Framework:** `AuditLogger` is the application logging abstraction (`lib/infrastructure/security/audit_logger.dart`); `avoid_print` is enforced.

**Patterns:**
- Log operational events through the injected logger/provider, not ad-hoc prints. Sensitive amounts, notes, merchants, keys, tokens, and sync payloads must not be logged.
- Catch-and-ignore (`catch (_)`) is used only for deliberately best-effort cleanup/availability probes; meaningful failures preserve an error result or typed exception.

## Comments

**When to Comment:**
- Comment invariants, security assumptions, migration decisions, and non-obvious sequencing. `CreateTransactionUseCase` documents validation stages and foreign-currency/hash-chain invariants inline.
- Avoid comments that restate straightforward Dart; prefer a short rationale tied to an ADR or compatibility constraint.

**JSDoc/TSDoc:**
- Dart doc comments (`///`) are used on public classes, use cases, helpers, and test bootstrap behavior. Include parameter/return rationale when behavior is security- or state-sensitive.

## Function Design

**Size:** Keep orchestration readable and split validation, mapping, persistence, and side effects into helpers/services when a method becomes lengthy. Use cases commonly expose one `execute` method.

**Parameters:** Prefer required named parameters for dependencies and operation inputs; optional behavior is nullable and resolved explicitly (see `CreateTransactionParams`).

**Return Values:** Use typed domain values, `Future<T>` for async boundaries, nullable values for absence, and `Result<T>` for expected application outcomes. Avoid mutation-style updates for Freezed models.

## Module Design

**Exports:** Files generally export their concrete type directly; providers are defined beside the module and generated provider names are consumed from generated files.

**Barrel Files:** No broad barrel-file convention is evident; import the owning module/provider directly and avoid duplicate repository provider definitions.

---

*Convention analysis: 2026-08-08*
