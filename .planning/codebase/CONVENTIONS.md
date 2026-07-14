# Coding Conventions

**Analysis Date:** 2026-07-14

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart source (e.g. `currency_conversion.dart`, `main_shell_screen.dart`)
- Generated files carry double extensions: `*.g.dart` (riverpod/json/drift), `*.freezed.dart` (freezed) — NEVER hand-edit
- Feature repository wiring: exactly ONE `repository_providers.dart` per feature/application domain (single source of truth)
- Drift indices named `idx_{table}_{columns}`
- Architecture docs: `ARCH-{NNN}_Name.md`, `MOD-{NNN}_Name.md`, `ADR-{NNN}_Name.md` (PascalCase name, sequential numbering)

**Classes / Types:**
- `PascalCase` for classes, enums, typedefs, Freezed models (e.g. `AppDatabase`, `AppPalette`, `TransactionType`)
- `@freezed` for immutable domain models — always mutate via `copyWith`, never in place

**Functions / Variables:**
- `lowerCamelCase` for functions, methods, locals, named parameters
- Private members prefixed `_` (e.g. `_bookId`, `_createAllDeclaredIndexes()`)
- Riverpod 3 generator strips the `Notifier` suffix: `class LocaleNotifier` annotated `@riverpod` generates `localeProvider` (NOT `localeNotifierProvider`)

## Code Style

**Formatting:**
- `dart format .` (2-space indent, trailing commas drive multi-line layout)
- Enforced in CI via `flutter analyze` (must be 0 issues before commit)
- CAVEAT: the repo is NOT globally format-clean — do NOT run `dart format` over the whole `test/` tree (see TESTING.md golden note)

**Linting:**
- Base: `package:flutter_lints/flutter.yaml` (`analysis_options.yaml`)
- Custom enabled rules:
  - `prefer_single_quotes: true` — use `'...'` not `"..."`
  - `prefer_relative_imports: true` — intra-project imports MUST be relative, NOT `package:home_pocket/...`
  - `avoid_print: true` — never `print()`; use structured logging
- `invalid_annotation_target: ignore` (freezed/json annotation noise)
- `custom_lint` plugin active → `riverpod_lint` + `import_guard_custom_lint`
- Generated files excluded from analysis: `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- Never suppress with `// ignore:` — fix root cause (a `stale_suppressions_scan_test.dart` arch test guards this)

## Import Organization

**Order (dart convention):**
1. `dart:` core libraries
2. `package:` third-party (flutter, riverpod, drift, intl, etc.)
3. Relative project imports (`../`, `./`)

**Path Rules:**
- Intra-project imports are ALWAYS relative (`prefer_relative_imports`). `package:home_pocket/...` self-imports are disallowed for lib code (test code does import via `package:home_pocket/...` since it lives outside `lib/`).
- IMPORTANT: because the repo uses relative imports, `import_guard` deny-mode yamls (which match `package:` prefixes) are INERT for lib code. The real layer-boundary enforcement lives in `test/architecture/layer_import_rules_test.dart` (scans real imports, relative-normalized).

**Riverpod 3 split entry points** (pick the right one or symbols won't resolve):
- Core (`Provider`, `Notifier`, `AsyncValue`, `ConsumerWidget`, `WidgetRef`, `ProviderScope`, `ProviderContainer`) → `package:flutter_riverpod/flutter_riverpod.dart`
- Legacy (`StateNotifier`, `StateProvider`, `ChangeNotifierProvider`) → `package:flutter_riverpod/legacy.dart`
- Misc (`Override`, `ProviderListenable`, `ProviderException`, `Family`, `Refreshable`) → `package:flutter_riverpod/misc.dart`

## Error Handling

**Patterns:**
- Fail fast at boundaries with typed exceptions: `ArgumentError.value(...)` for invalid args, `FormatException(...)` for unparseable input (see `lib/shared/utils/currency_conversion.dart`)
- Validate all inputs before use; never trust external/user data
- App-init failures surface a dedicated error fallback screen (see `AppInitializer`), never a silent swallow
- Riverpod 3 wraps provider-thrown errors in `ProviderException` (`implements Exception`); the inner cause is on `.exception`
- Crypto errors bubble as `Bad state:` from `encrypted_database.dart` when SQLCipher isn't loaded — do not catch-and-hide

## Logging

**Framework:** Structured logging only — `avoid_print` lint forbids `print()`.

**Rules:**
- NEVER log sensitive/crypto data (keys, plaintext amounts, recovery phrase) — enforced by `test/architecture/production_logging_privacy_test.dart`
- No `console.log`-style debug prints left in committed code

## Comments

**When to Comment:**
- Explain WHY, not WHAT; one-liners only when non-obvious
- Load-bearing invariants get doc comments citing the spec/ADR/decision (e.g. "Single canonical JPY conversion site per STORE-02 and ADR-020", "WR-01, Phase 40 review")
- Reference decision IDs (`D-NN`), phase numbers, ADRs so future readers can trace rationale

**DartDoc:**
- Public utility functions carry `///` docs describing params, formula, failure modes, and caller contracts (see `convertToJpy`)

## Function & Module Design

**Functions:** small (<50 lines), single-responsibility, prefer named required parameters for multi-arg APIs (`convertToJpy({required ...})`).

**Files:** many small files > few large (200–400 lines typical, 800 max). Organize by feature/domain, not by type.

## Immutability (CRITICAL)

- ALWAYS return new objects; NEVER mutate in place
- `@freezed` models: use `copyWith`
- Enforced for `@freezed` classes by the generator; general mutation is manually reviewed

## Domain-Specific Conventions

**i18n (mandatory):**
- All UI text via `S.of(context)` — never hardcode strings (guarded by `test/architecture/hardcoded_cjk_ui_scan_test.dart`)
- Dates via `DateFormatter`, currency via `NumberFormatter` (`lib/infrastructure/i18n/formatters/`)
- Always thread locale from `currentLocaleProvider`
- Update ALL 3 ARB files (`app_ja.arb`, `app_zh.arb`, `app_en.arb`), then `flutter gen-l10n` (guarded by `arb_key_parity_test.dart`)

**Colors:** resolve via `context.palette` / `AppPalette.light`/`.dark` — never hardcode hex literals (guarded by `color_literal_scan_test.dart`). Current palette = ADR-019 桜餅×若葉.

**Amounts:** use `AppTextStyles.amountLarge/amountMedium/amountSmall` (`lib/core/theme/app_text_styles.dart`) — they carry `FontFeature.tabularFigures()`. Never generic text styles for money.

**Widget parameters:** nullable + provider fallback, never hardcoded defaults:
```dart
final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
```

**Layer boundaries (5-layer Clean Architecture):** Presentation → Application → Domain ← Data ← Infrastructure. Domain never imports Data. Only composition-root `*_providers.dart` may import `lib/data/`. Enforced by `layer_import_rules_test.dart` + `domain_import_rules_test.dart`.

---

*Convention analysis: 2026-07-14*
