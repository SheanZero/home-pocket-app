# Coding Conventions

**Analysis Date:** 2026-06-23

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart files (e.g., `create_transaction_use_case.dart`, `app_palette.dart`)
- Generated companions: `*.g.dart` (riverpod/json/drift), `*.freezed.dart` (freezed) — never hand-edit
- Tables: `{name}_table.dart` in `lib/data/tables/`; DAOs: `{name}_dao.dart` in `lib/data/daos/`
- Use cases: `{verb}_{noun}_use_case.dart` (e.g., `delete_transaction_use_case.dart`)
- Tests: `{subject}_test.dart`; characterization tests use `_characterization_test.dart` suffix

**Functions:**
- `lowerCamelCase` for functions, methods, local variables
- Riverpod 3 generator strips the `Notifier` suffix: `class LocaleNotifier` → `localeProvider` (NOT `localeNotifierProvider`)

**Variables:**
- `lowerCamelCase` for instances/locals; `_leadingUnderscore` for private members
- Drift index columns use Symbol syntax: `{#bookId}`

**Types:**
- `PascalCase` for classes, enums, typedefs (e.g., `AppDatabase`, `AppRunner`)
- Freezed models are immutable; mutate only via `copyWith`

## Code Style

**Formatting:**
- `dart format .` — standard Dart formatter, 2-space indent
- NOTE: repo is NOT format-clean across all of `test/`; never run `dart format` over the whole `test/` tree (golden baselines / placeholder-font widgets break). Format only files you touch.

**Linting:**
- Base: `package:flutter_lints/flutter.yaml` (`flutter_lints: ^6.0.0`)
- Plugins: `custom_lint` (with `import_guard_custom_lint`, `riverpod_lint`)
- Enforced rules: `prefer_single_quotes`, `prefer_relative_imports`, `avoid_print`
- Excluded from analysis: `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- `invalid_annotation_target` set to `ignore` (freezed/json annotation noise)
- **Zero analyzer warnings before commit** (CI-enforced via `audit.yml`). Fix root cause — do NOT suppress with `// ignore:`.

## Import Organization

**Order (observed):**
1. `dart:*` core libraries
2. `package:*` third-party (flutter, riverpod, drift)
3. Relative project imports (`../../domain/models/...`) — `prefer_relative_imports` is enforced for intra-lib references

**Riverpod 3 import split (critical — symbols won't resolve otherwise):**
| Need | Import |
|---|---|
| `Provider`, `Notifier`, `AsyncValue`, `ConsumerWidget`, `WidgetRef`, `ProviderScope`, `ProviderContainer` | `package:flutter_riverpod/flutter_riverpod.dart` |
| `StateNotifier`, `StateProvider`, `ChangeNotifierProvider` (legacy) | `package:flutter_riverpod/legacy.dart` |
| `Override`, `ProviderListenable`, `ProviderException`, `Family` | `package:flutter_riverpod/misc.dart` |

**Path Aliases:**
- Use `as` prefixes to disambiguate same-named providers across layers (e.g., `import '.../ml/repository_providers.dart' as app_ml;`)

## Error Handling

**Patterns:**
- Explicit `try { } catch (e) { }` at boundaries (~73 try blocks in `lib/`)
- Never silently swallow errors; provide user-friendly messages in UI-facing code
- App init failures surface a dedicated fallback screen (`lib/core/initialization/init_failure_screen.dart`) rather than crashing
- Riverpod 3: provider-thrown errors are wrapped in `ProviderException`; inner exception on `.exception`. Tests must use `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`

## Logging

**Framework:** `debugPrint` (Flutter) for diagnostics; dedicated `lib/infrastructure/security/audit_logger.dart` for audit events.

**Patterns:**
- Prefix logs with component tag: `debugPrint('[SyncOrchestrator] ...')`
- `avoid_print` lint forbids raw `print()` — use `debugPrint`
- NEVER log sensitive/crypto data (privacy enforced by `test/architecture/production_logging_privacy_test.dart`)

## Comments

**When to Comment:**
- Default: no comments. Add a one-line WHY only when non-obvious.
- File-header docstrings are common and valuable — they cite the spec/decision driving the file (e.g., `// STORE-02 specification:`, `// Per CRIT-05 D-15 ...`). Preserve this convention: link code to its planning decision.

**DartDoc (`///`):**
- Used on shared helpers and public test utilities to explain rationale and Riverpod-3 gotchas

## Function Design

**Size:** Small — functions <50 lines, files 200–400 typical, 800 max ("many small files > few large files").

**Parameters:** Named parameters preferred, especially for widgets. Use nullable param + provider fallback, never hardcoded defaults:
```dart
final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
```

**Return Values:** Immutable returns; new objects via `copyWith`, never in-place mutation.

## Module Design

**Layering (5-layer Clean Architecture):** `Presentation → Application → Domain ← Data ← Infrastructure`. Domain never imports Data (enforced by `import_guard` + `domain_import_rules_test.dart`).

**Providers:**
- ONE `repository_providers.dart` per feature (single source of truth) — never duplicate repository provider definitions (enforced by `provider_graph_hygiene_test.dart` + `riverpod_lint`)
- Never throw `UnimplementedError` in providers
- Side-effect listeners (navigation, snackbars) belong in `ref.listen`, NOT `ref.watch`

**i18n:**
- All UI text via `S.of(context)` — never hardcode strings (enforced by `hardcoded_cjk_ui_scan_test.dart`)
- Dates via `DateFormatter`, currency via `NumberFormatter`; pass locale from `currentLocaleProvider`
- Update all 3 ARB files (ja/zh/en) then `flutter gen-l10n`

**Colors:** Resolve via `context.palette` (`AppPalette`); no hardcoded color literals (enforced by `color_literal_scan_test.dart`).

---

*Convention analysis: 2026-06-23*
