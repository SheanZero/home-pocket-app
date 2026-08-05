# Coding Conventions

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

## Naming Patterns

- Dart files use `snake_case.dart`; tests append `_test.dart`; characterization tests append `_characterization_test.dart`.
- Generated outputs use `.g.dart`/`.freezed.dart` and are never hand-edited. Drift indexes use `idx_{table}_{columns}`.
- Classes, enums, typedefs, and Freezed models use `PascalCase`; functions, locals, and parameters use `lowerCamelCase`; private members begin `_`.
- Riverpod generator names omit `Notifier` (`LocaleNotifier` produces `localeProvider`).

## Code Style

Use `dart format` (two-space indentation, trailing commas). `analysis_options.yaml` enables Flutter lints, custom lint, Riverpod/import-guard lint, `prefer_single_quotes`, `prefer_relative_imports`, and `avoid_print`; generated files and `build/**` are excluded. Fix root causes instead of adding `// ignore:` suppressions.

## Import Organization

Order imports as `dart:` libraries, third-party `package:` dependencies, then relative project imports. Production `lib/` code uses relative self-imports. Preserve Clean Architecture boundaries; `test/architecture/layer_import_rules_test.dart` and `domain_import_rules_test.dart` enforce them. Riverpod 3 core, legacy, and miscellaneous symbols come from `flutter_riverpod.dart`, `legacy.dart`, and `misc.dart` respectively.

## Error Handling and Logging

Validate boundaries with typed `ArgumentError.value` and `FormatException`. Initialization errors use the fallback UI; provider errors are `ProviderException` (inspect `.exception`). Use structured logging only and never log sensitive amounts, notes, keys, tokens, recovery material, or sync payloads (`test/architecture/production_logging_privacy_test.dart`).

## Comments and Module Design

Comment rationale and invariants with ADR/decision/phase references. Public utilities use `///` docs. Prefer focused, single-responsibility functions (typically under 50 lines), named required parameters, and feature/domain organization.

## Domain Conventions

- UI text comes from `S.of(context)`; update all `lib/l10n/app_{ja,zh,en}.arb` files and regenerate (`test/architecture/arb_key_parity_test.dart`).
- Resolve colors via `context.palette`/`AppPalette`, amounts via `AppTextStyles.amount*`, and dates/currency via `lib/infrastructure/i18n/formatters/`; avoid literals.
- Widget overrides are nullable and follow explicit parameter > current selection > user default > null.

---

*Convention analysis: 2026-08-05*
