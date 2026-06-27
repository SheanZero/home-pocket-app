# Coding Conventions

**Analysis Date:** 2026-06-27

This is a Flutter app (Dart) named **Home Pocket (まもる家計簿)**, built on Riverpod 3, Freezed, Drift + SQLCipher, with a 5-layer Clean Architecture. Conventions below are enforced by a mix of `flutter_lints`, `custom_lint` (import_guard + riverpod_lint), and architecture tests under `test/architecture/`.

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart source (`currency_conversion.dart`, `app_text_styles.dart`)
- Generated siblings: `*.g.dart` (riverpod/json), `*.freezed.dart` (freezed) — NEVER hand-edit
- Test files: `{subject}_test.dart`; golden tests `{subject}_golden_test.dart`; characterization tests `{subject}_characterization_test.dart`

**Functions / variables:**
- `camelCase` for functions, methods, locals, parameters
- Named parameters preferred for multi-arg functions (see `convertToJpy({required ...})` in `lib/shared/utils/currency_conversion.dart`)

**Types:**
- `PascalCase` for classes, enums, mixins (`AppPalette`, `InitFailureType`, `MasterKeyMissingWithExistingDataError`)
- Riverpod 3 generates provider names by **stripping the `Notifier` suffix**: `class LocaleNotifier` (`@riverpod`) → `localeProvider`, NOT `localeNotifierProvider`. Do not reintroduce the suffix.

**Providers:**
- One `repository_providers.dart` per feature (single source of truth); never duplicate repository provider definitions (enforced by `test/architecture/provider_graph_hygiene_test.dart` + `riverpod_lint`)
- `@Riverpod(keepAlive: true)` is a hard-listed set checked by the provider-graph hygiene test — adding/removing keepAlive providers requires updating that list

**Architecture docs / ADRs:** `ARCH-{NNN}_{Name}.md`, `MOD-{NNN}_{Name}.md`, `ADR-{NNN}_{Name}.md` under `docs/arch/` (sequential numbering, see `.claude/rules/arch.md`).

## Code Style

**Formatting:**
- `dart format .` (do NOT run `dart format` over the whole `test/` tree — the repo is not format-clean there; format only files you touch)
- Single quotes for strings — `prefer_single_quotes: true` (`analysis_options.yaml`)

**Linting:**
- Base ruleset: `package:flutter_lints/flutter.yaml` (`flutter_lints: ^6.0.0`)
- Extra enabled rules (`analysis_options.yaml`):
  - `prefer_single_quotes: true`
  - `prefer_relative_imports: true` — intra-package imports use relative paths
  - `avoid_print: true` — no `print()`; use the project logging path
- `custom_lint` plugin enabled, providing `import_guard_custom_lint` (layer boundaries) + `riverpod_lint` (provider hygiene)
- Generated files excluded from analysis: `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- `invalid_annotation_target: ignore` (needed for freezed/json annotations)
- **Zero analyzer warnings before commit.** CI runs `flutter analyze --no-fatal-infos` + `dart run custom_lint --no-fatal-infos` (`.github/workflows/audit.yml`). Don't suppress with `// ignore:` — fix the root cause. `stale_suppressions_scan_test.dart` polices leftover suppressions.

## Import Organization & Layer Boundaries

**Import style:**
- Package imports for external deps and cross-package (`package:flutter/...`, `package:home_pocket/...`)
- Relative imports preferred within the package (`prefer_relative_imports`)

**Riverpod 3 — split entry points (pick the right one or symbols won't resolve):**

| Need | Import |
|------|--------|
| `Provider`, `Notifier`, `AsyncValue`, `ProviderContainer`, `ConsumerWidget`, `WidgetRef`, `ProviderScope` | `package:flutter_riverpod/flutter_riverpod.dart` |
| `StateNotifier`, `StateProvider`, `ChangeNotifierProvider` (legacy) | `package:flutter_riverpod/legacy.dart` |
| `Override`, `ProviderListenable`, `ProviderException`, `Family`, `Refreshable` | `package:flutter_riverpod/misc.dart` |

**Layer dependency rules — enforced by per-directory `import_guard.yaml` files** (40+ of them, one per layer/feature subtree) + `test/architecture/domain_import_rules_test.dart`:
- `Presentation → Application → Domain ← Data ← Infrastructure`. Domain is leafmost.
- **Domain** (`lib/features/*/domain/`) denies `data/**`, `infrastructure/**`, `application/**`, `features/**/presentation/**`, and even `package:flutter/**`. Whitelists live in per-subdirectory yamls (`domain/models/`, `domain/repositories/`) because import_guard evaluates each config independently against its own `allow`.
- **Data** (`lib/data/`) denies `features/*/presentation/**` and `application/**`.
- **Project-wide** (`lib/import_guard.yaml`) denies `dart:mirrors` and `package:sqlite3_flutter_libs/**` (must use `sqlcipher_flutter_libs`).
- `inherit: true` chains parent rules into children.

## Immutability

- ALWAYS create new objects, never mutate. Models are `@freezed` classes — use `copyWith`, never field assignment.
- Freezed 3.x (`freezed: ^3.0.0`). Declare `part '{name}.freezed.dart';` and run build_runner after changes.

## Error Handling

- Validate at system boundaries; fail loud rather than silently corrupting state. Example: `MasterKeyMissingWithExistingDataError` (`lib/core/initialization/.../init_result.dart`) refuses to mint a fresh key when an encrypted DB exists, preventing silent data loss.
- Typed failure enums for domain outcomes (`InitFailureType { masterKey, masterKeyMissingWithData, database, seed, unknown }`).
- **Riverpod 3:** errors thrown inside providers are wrapped in `ProviderException` (`implements Exception`); the inner error is on `.exception`. Tests must assert `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`.
- **Never** throw `UnimplementedError` in providers (caught by provider-graph hygiene test).
- Crypto operations MUST route through `lib/infrastructure/crypto/`; never log sensitive data (`production_logging_privacy_test.dart` enforces).

## i18n (mandatory)

- All user-visible UI text via `S.of(context)` — never hardcode strings. `test/architecture/hardcoded_cjk_ui_scan_test.dart` fails the build on hardcoded CJK in UI, with an explicit `approvedWhitelist` for NLP lexicons / merchant seed data / formatter outputs (algorithm data, not UI text).
- ARB files in `lib/l10n/` (`app_en.arb` template + `ja`, `zh`); generated class `S` → `lib/generated/app_localizations.dart` (`l10n.yaml`, `nullable-getter: false`). `arb_key_parity_test.dart` enforces all 3 locales stay in sync.
- Update ALL 3 ARB files when adding a key, then `flutter gen-l10n`. `lib/generated/` is gitignored-yet-tracked — force-add (`git add -f`) regenerated Dart when adding keys.
- Dates via `DateFormatter`, currency via `NumberFormatter` (`lib/infrastructure/i18n/formatters/`); always pass locale from `currentLocaleProvider`.

## Theming & Visual Conventions

- **Colors:** resolve via `context.palette` (extension `AppPaletteContext on BuildContext`, `lib/core/theme/app_palette.dart`) → `AppPalette.light` / `AppPalette.dark` (ThemeExtension). Never hardcode hex literals in widgets — `test/architecture/color_literal_scan_test.dart` scans for them. Current palette is v1.6 ADR-019 "Sakura Mochi × Wakaba".
- **Amounts:** use `AppTextStyles.amountLarge/amountMedium/amountSmall` (`lib/core/theme/app_text_styles.dart`) — they carry `FontFeature.tabularFigures()` for column alignment. Apply ledger color at call site via `.copyWith(color: context.palette.dailyText)`. Never use generic text styles for monetary values.

## Function & File Design

- MANY SMALL FILES > few large files. 200–400 lines typical, 800 max. Functions < 50 lines.
- Widget parameters: nullable + provider fallback, never hardcoded defaults: `final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;`
- Side-effect listeners (navigation, snackbars) belong in `ref.listen`, not `ref.watch`.

## Comments

- Default: no comments. Add a one-line WHY only when non-obvious. The codebase favors dense header doc-comments on tricky files explaining rationale, decision IDs (`D-NN`), and gotchas (see `currency_conversion_test.dart`, `init_result.dart`).

---

*Convention analysis: 2026-06-27*
