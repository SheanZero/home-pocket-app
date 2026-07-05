# Coding Conventions

**Analysis Date:** 2026-07-05

This is a Flutter app (Dart) named **Home Pocket (まもる家計簿)**, built on Riverpod 3, Freezed 3, Drift + SQLCipher, with a 5-layer Clean Architecture. Conventions below are enforced by a mix of `flutter_lints`, `custom_lint` (import_guard + riverpod_lint), and 17 architecture tests under `test/architecture/`. All claims re-verified against current HEAD.

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart source (`currency_conversion.dart`, `app_text_styles.dart`, `rate_result.dart`)
- Generated siblings: `*.g.dart` (riverpod/json), `*.freezed.dart` (freezed) — NEVER hand-edit
- Test files: `{subject}_test.dart`; golden tests `{subject}_golden_test.dart`; characterization tests `{subject}_characterization_test.dart`

**Functions / variables:**
- `camelCase` for functions, methods, locals, parameters
- Named parameters preferred for multi-arg functions — see `convertToJpy({required int originalMinorUnits, required String appliedRate, required int subunitToUnit})` in `lib/shared/utils/currency_conversion.dart`

**Types:**
- `PascalCase` for classes, enums, mixins (`AppPalette`, `InitFailureType`, `CurrencyTripleResult`, `RateResult`)
- Sealed / union value types use named constructors for mutually-exclusive cases: `CurrencyTripleResult.native()` / `.invalid(msg)` / `.foreign(amount)` (`lib/shared/utils/currency_conversion.dart:139`), and `RateResult` → `RateFetched` / `RateUnavailable` (`lib/features/currency/domain/models/rate_result.dart`).
- Riverpod 3 generates provider names by **stripping the `Notifier` suffix**: `class LocaleNotifier` (`@riverpod`) → `localeProvider`, NOT `localeNotifierProvider`. Do not reintroduce the suffix.

**Providers:**
- One `repository_providers.dart` per feature (single source of truth); never duplicate repository provider definitions (enforced by `test/architecture/provider_graph_hygiene_test.dart` + `riverpod_lint`)
- `@Riverpod(keepAlive: true)` is a hard-listed set checked by the provider-graph hygiene test — adding/removing keepAlive providers requires updating that list
- **Composition roots own cross-layer provider wiring.** A use-case provider that would force one layer to import another's presentation/wiring belongs in the consuming feature's composition root, not the producing layer. Precedent (commit `e811a219`): `seedAllUseCase` moved out of `lib/application/seed/` (deleted) into the accounting composition root; `appLockService` moved out of `lib/infrastructure/security/providers` into an applock composition root.

**Architecture docs / ADRs:** `ARCH-{NNN}_{Name}.md`, `MOD-{NNN}_{Name}.md`, `ADR-{NNN}_{Name}.md` under `docs/arch/` (sequential numbering, see `.claude/rules/arch.md`).

## Code Style

**Formatting:**
- `dart format .` (do NOT run `dart format` over the whole `test/` tree — the repo is not format-clean there; format only files you touch)
- Single quotes for strings — `prefer_single_quotes: true` (`analysis_options.yaml`)
- Trailing commas on multi-line arg lists (drives dartfmt's vertical layout)

**Linting (`analysis_options.yaml`):**
- Base ruleset: `package:flutter_lints/flutter.yaml` (`flutter_lints: ^6.0.0`)
- Extra enabled rules:
  - `prefer_single_quotes: true`
  - `prefer_relative_imports: true` — intra-package imports use relative paths
  - `avoid_print: true` — no `print()`; use the project logging path
- `custom_lint` plugin enabled, providing `import_guard_custom_lint` (layer boundaries) + `riverpod_lint` (provider hygiene)
- Generated files excluded from analysis: `**/*.g.dart`, `**/*.freezed.dart`, `build/**`
- `invalid_annotation_target: ignore` (needed for freezed/json annotations)
- **Zero analyzer warnings before commit.** CI runs `flutter analyze --no-fatal-infos` + `dart run custom_lint --no-fatal-infos` (`.github/workflows/audit.yml`). Don't suppress with `// ignore:` — fix the root cause. `stale_suppressions_scan_test.dart` polices leftover suppressions.
- CI smoke-checks the `analyzer` pin stays on 7.x (`audit.yml` — FUTURE-TOOL-01 readiness warning).

## Import Organization & Layer Boundaries

**Import style:**
- Package imports for external deps (`package:flutter/...`, `package:drift/...`)
- Relative imports preferred within the package (`prefer_relative_imports`) — this is load-bearing for how layer enforcement works (see below)

**Riverpod 3 — split entry points (pick the right one or symbols won't resolve):**

| Need | Import |
|------|--------|
| `Provider`, `Notifier`, `AsyncValue`, `ProviderContainer`, `ConsumerWidget`, `WidgetRef`, `ProviderScope` | `package:flutter_riverpod/flutter_riverpod.dart` |
| `StateNotifier`, `StateProvider`, `ChangeNotifierProvider` (legacy) | `package:flutter_riverpod/legacy.dart` |
| `Override`, `ProviderListenable`, `ProviderException`, `Family`, `Refreshable` | `package:flutter_riverpod/misc.dart` |

**Layer dependency rules — `Presentation → Application → Domain ← Data ← Infrastructure`. Domain is the innermost circle (any layer may import `lib/features/*/domain/**`).**

Two DIFFERENT mechanisms exist; know which one actually enforces:

- **`import_guard.yaml` files (40+, one per layer/feature subtree) + `test/architecture/domain_import_rules_test.dart`** — these validate that the deny-mode yaml *config* is present and well-formed (retains its deny set, no stray `allow:` block). They do NOT catch real violations: import_guard deny rules match `package:home_pocket/...` URIs verbatim, but this repo enforces `prefer_relative_imports`, so every deny-mode guard is inert for intra-project imports. **A green `custom_lint` is NOT layer-compliance evidence** (CLAUDE.md pitfall #2 was corrected in `e811a219`).
- **`test/architecture/layer_import_rules_test.dart` (the REAL enforcement, added `e811a219`)** — scans every hand-written file under `lib/`, resolves relative imports to lib-rooted paths, and asserts the actual dependency directions. Deliberate exceptions go in its in-file `_allowlist` with a justification (currently empty). This is the test that fails the build on a reverse dependency. When adding code that crosses layers, this is the gate you must satisfy.
- **Project-wide** (`lib/import_guard.yaml`) also denies `dart:mirrors` and `package:sqlite3_flutter_libs/**` (must use `sqlcipher_flutter_libs`) — these DO fire because they match `package:`/`dart:` URIs.

## Immutability

- ALWAYS create new objects, never mutate. Models are `@freezed` classes — use `copyWith`, never field assignment.
- Freezed 3.x (`freezed: ^3.0.0`). Declare `part '{name}.freezed.dart';` and run `build_runner` after changes.
- Hand-written value types (non-freezed) use `const` constructors + `final` fields throughout (`CurrencyTripleResult`, `Result<T>`).

## Error Handling

Three complementary patterns, chosen by layer:

1. **`Result<T>` envelope for use-case outcomes** (`lib/shared/utils/result.dart`) — `Result.success(data)` / `Result.error(message)` with `isSuccess` / `isError`. Application-layer use cases return this to communicate outcomes *without throwing*.
2. **Fail-fast validation at system boundaries** — throw typed errors rather than silently corrupting state. `convertToJpy` throws `ArgumentError` / `FormatException` on bad input (`lib/shared/utils/currency_conversion.dart`); `MasterKeyMissingWithExistingDataError` refuses to mint a fresh key when an encrypted DB exists, preventing silent data loss.
3. **Typed failure enums for domain outcomes** — `InitFailureType { masterKey, masterKeyMissingWithData, database, seed, unknown }`.

Cross-cutting rules:
- **Single validation+conversion sites.** Currency math lives ONLY in `lib/shared/utils/currency_conversion.dart` (`convertToJpy`, `validateAppliedRate`, `validateCurrencyTriple`); callers MUST NOT re-parse `appliedRate` or duplicate the triple check inline (ADR-020 single-parse-site guarantee — inline divergence is undetectable once persisted because the triple is excluded from the hash chain).
- **Riverpod 3:** errors thrown inside providers are wrapped in `ProviderException` (`implements Exception`); the inner error is on `.exception`. Tests must assert `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`.
- **Never** throw `UnimplementedError` in providers (caught by provider-graph hygiene test).
- Crypto operations MUST route through `lib/infrastructure/crypto/`; never log sensitive data (`production_logging_privacy_test.dart` enforces).

## i18n (mandatory)

- All user-visible UI text via `S.of(context)` — never hardcode strings. `test/architecture/hardcoded_cjk_ui_scan_test.dart` fails the build on hardcoded CJK in UI, with an explicit `approvedWhitelist` for NLP lexicons / merchant seed data / formatter outputs (algorithm data, not UI text).
- ARB files in `lib/l10n/` (`app_en.arb` template + `ja`, `zh`); generated class `S` → `lib/generated/app_localizations.dart` (`l10n.yaml`, `output-class: S`, `nullable-getter: false`). `arb_key_parity_test.dart` enforces all 3 locales stay in sync.
- Update ALL 3 ARB files when adding a key, then `flutter gen-l10n`. `lib/generated/` is gitignored-yet-tracked — force-add (`git add -f`) regenerated Dart when adding keys.
- Dates via `DateFormatter`, currency via `NumberFormatter` (`lib/infrastructure/i18n/formatters/`); always pass locale from `currentLocaleProvider`. ISO 4217 minor-unit decimals come from the single source `currencyFractionDigitsFor` (`lib/shared/utils/currency_conversion.dart`), never re-derived.

## Theming & Visual Conventions

- **Colors:** resolve via `context.palette` (extension `AppPaletteContext on BuildContext`, `lib/core/theme/app_palette.dart`) → `AppPalette.light` / `AppPalette.dark` (ThemeExtension). Never hardcode hex literals in widgets — `test/architecture/color_literal_scan_test.dart` scans for them. Current palette is v1.6 ADR-019 "Sakura Mochi × Wakaba" (leaf green primary, sakura-pink FAB/joy, amber joy-text).
- **Amounts:** use `AppTextStyles.amountLarge/amountMedium/amountSmall` (`lib/core/theme/app_text_styles.dart`) — they carry `FontFeature.tabularFigures()` for column alignment. Apply ledger color at call site via `.copyWith(color: context.palette.dailyText)`. Never use generic text styles for monetary values.

## Function & File Design

- MANY SMALL FILES > few large files. 200–400 lines typical, 800 max. Functions < 50 lines.
- Widget parameters: nullable + provider fallback, never hardcoded defaults: `final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;`
- Side-effect listeners (navigation, snackbars) belong in `ref.listen`, not `ref.watch`.
- Extract one canonical helper for any logic that would otherwise be duplicated across call sites; annotate it as the single site in its doc-comment.

## Comments

- Default: no comments. Add a one-line WHY only when non-obvious.
- The codebase favors **dense header doc-comments** on tricky files that encode: the single-site / invariant contract, decision IDs (`D-NN`, `ADR-NNN`, `STORE-NN`, `WR-NN`, phase/plan IDs), rounding/edge-case rationale, and explicit "do NOT do X" warnings (see `lib/shared/utils/currency_conversion.dart`, `lib/core/initialization/.../init_result.dart`).
- **Superseded-decision comment pattern:** when a locked decision is later reversed, the header keeps the original decision AND appends a dated `NNNNNN BUG-N — <D-ID>'s <branch> SUPERSEDED:` block explaining the reversal, rather than deleting the old rationale (see `test/infrastructure/voice/currency_detection_test.dart` — bare 「元」 CNY→native reversal, 2026-07-03). Preserves the decision timeline.

---

*Convention analysis: 2026-07-05*
