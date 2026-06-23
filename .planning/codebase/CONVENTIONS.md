# Coding Conventions

**Analysis Date:** 2026-06-23

This is a Flutter (Dart) application using Clean Architecture (5 layers), Riverpod 3, Freezed, and Drift + SQLCipher. Conventions are enforced by `analysis_options.yaml` (flutter_lints + custom_lint), per-directory `import_guard.yaml` files, and architecture tests under `test/architecture/`.

## Naming Patterns

**Files:**
- `snake_case.dart` for all source files (e.g., `create_transaction_use_case.dart`, `app_database.dart`)
- Generated files mirror the source name: `*.g.dart` (Riverpod/json/drift), `*.freezed.dart` (Freezed)
- Tests append `_test.dart` and mirror the source path under `test/`
- Golden tests append `_golden_test.dart` under `test/golden/`

**Classes / Types:**
- `PascalCase` (e.g., `CreateTransactionUseCase`, `Result<T>`, `AppDatabase`)
- Use-case classes named `{Verb}{Noun}UseCase` and live in `lib/application/{domain}/`
- Param objects named `{UseCase}Params` (e.g., `CreateTransactionParams`)
- Drift tables PascalCase; DAOs `{Name}Dao`; repository interfaces `{Name}Repository`
- Test doubles use leading underscore + `_Mock`/`_Fake` prefix (e.g., `_MockTransactionRepository`, `_FakeTransaction`)

**Functions / Variables:**
- `camelCase` for methods, locals, fields
- `lowerCamelCase` providers, suffix `Provider`. Riverpod generator strips the `Notifier` suffix — `class LocaleNotifier` → `localeProvider`, NOT `localeNotifierProvider`

**Drift Indices:**
- `idx_{table}_{columns}` (e.g., `idx_transactions_book_id`), declared with `TableIndex(name:..., columns: {#bookId})` Symbol syntax (NOT `Index()`, no `@override`)

## Code Style

**Formatting:**
- `dart format .` — but NEVER run on the whole `test/` tree (repo is not format-clean there; golden baselines are macOS-sensitive)
- 2-space indentation (Dart standard)

**Linting (`analysis_options.yaml`):**
- Base: `package:flutter_lints/flutter.yaml`
- Enforced extra rules:
  - `prefer_single_quotes: true` — use `'...'` not `"..."`
  - `prefer_relative_imports: true` — within `lib/`, use relative imports (`../../features/...`), not `package:home_pocket/...`
  - `avoid_print: true` — never use `print()`
- `invalid_annotation_target` suppressed (Freezed JSON annotation noise)
- Excludes from analysis: `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- **Zero analyzer warnings before commit.** Do NOT suppress with `// ignore:` — fix root cause. `stale_suppressions_scan_test.dart` flags dead suppressions.

**Import boundaries (custom_lint via `import_guard_custom_lint`):**
- Per-directory `lib/**/import_guard.yaml` files declare `deny:` lists with `inherit: true`
- Project-wide (`lib/import_guard.yaml`): denies `dart:mirrors`, `package:sqlite3_flutter_libs/**`
- `lib/features/import_guard.yaml`: enforces Thin Feature rule — features may NOT import `features/*/use_cases/**`, `application/**`, `infrastructure/**`, `data/**`
- `lib/data/import_guard.yaml`: data may NOT import `features/*/presentation/**` or `application/**`
- Also enforced by arch tests `domain_import_rules_test.dart` and `presentation_layer_rules_test.dart`

## Import Organization

**Within `lib/` use RELATIVE imports** (lint-enforced). Order observed:
1. `dart:` core libraries
2. `package:` third-party (alphabetical)
3. Relative project imports (`../../...`, `./...`)

**Riverpod 3 import split (pick the right entry point or symbols won't resolve):**
- `package:flutter_riverpod/flutter_riverpod.dart` — `Provider`, `Notifier`, `AsyncValue`, `ProviderContainer`, `ConsumerWidget`, `WidgetRef`, `ProviderScope`
- `package:flutter_riverpod/legacy.dart` — `StateNotifier`, `StateProvider` (discouraged)
- `package:flutter_riverpod/misc.dart` — `Override`, `ProviderListenable`, `ProviderException`, `Family`

## Error Handling

**Application layer: return `Result<T>`, do not throw** (`lib/shared/utils/result.dart`):
```dart
class Result<T> {
  factory Result.success(T? data) => ...;
  factory Result.error(String message) => ...;
  bool get isSuccess; bool get isError;
}
```
Use cases communicate outcomes via `Result.success(...)` / `Result.error(...)` instead of throwing.

**Provider errors:** Riverpod 3 wraps provider-thrown errors in `ProviderException` (`.exception` holds the inner). Never throw `UnimplementedError` in providers (`provider_graph_hygiene_test.dart` enforces).

**Validation at boundaries:** validate user input before processing; fail fast with clear messages.

## Logging

**Framework:** `AuditLogger` (`lib/infrastructure/security/audit_logger.dart`) and `dart:developer log` — NOT `print()` (`avoid_print` lint).

**Privacy rule:** never log sensitive data (amounts, keys, PII). Enforced by `production_logging_privacy_test.dart`.

## Immutability

- ALWAYS use Freezed `@freezed` models with `copyWith()` — never mutate
- Param objects use `const` constructors with `final` fields
- Create new objects; never mutate existing ones

## State Management (Riverpod 3)

- `@riverpod` code generation (riverpod_generator 4.x); run `build_runner` after changes
- ONE `repository_providers.dart` per feature (single source of truth); never duplicate (`provider_graph_hygiene_test.dart` + `riverpod_lint` enforce)
- Use-case classes live in `lib/application/`; their providers live in feature `presentation/providers/`
- `AsyncValue.value` is nullable (renamed from `.valueOrNull`)
- Side-effect listeners (navigation, snackbars) go in `ref.listen`, NOT `ref.watch`

## Function & Module Design

- Functions small (<50 lines); files focused (200-400 typical, 800 max)
- Many small files > few large files; organize by feature/domain, not type
- No deep nesting (>4 levels)
- No hardcoded widget parameter defaults — use nullable + provider fallback:
  ```dart
  final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
  ```

## i18n / Display Conventions

- All UI text via `S.of(context)` — never hardcode strings (`hardcoded_cjk_ui_scan_test.dart` scans for CJK literals)
- Dates via `DateFormatter`, currency via `NumberFormatter` (`lib/infrastructure/i18n/formatters/`)
- Update all 3 ARB files (ja/zh/en) together, then `flutter gen-l10n` (`arb_key_parity_test.dart` enforces parity)
- Monetary values use `AppTextStyles.amountLarge/Medium/Small` (tabular figures) — never generic text styles
- Colors via `context.palette` (`AppPalette`) — no hardcoded hex (`color_literal_scan_test.dart` enforces)

## Generated Code Rules

- Don't hand-edit `*.g.dart` / `*.freezed.dart`
- Don't remove imports needed by generated files
- Regenerate after modifying `@riverpod`/`@freezed`/Drift tables/ARB, and after merge/rebase/pull (AUDIT-10 CI gate catches stale committed generated files)
- `lib/generated/` is gitignored-yet-tracked — use `git add -f` when adding new S keys

---

*Convention analysis: 2026-06-23*
