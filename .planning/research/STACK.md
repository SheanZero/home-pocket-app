# Stack Research

**Domain:** Flutter/Dart codebase audit and cleanup tooling
**Researched:** 2026-04-25
**Confidence:** MEDIUM-HIGH — versions verified against pub.dev search results and official tool changelogs; DCM pricing/tier status verified against dcm.dev directly.

---

## Context: What Is Already Installed

The project (`pubspec.yaml`, `analysis_options.yaml`) already has these audit-relevant tools:

| Already Installed | Version | Status |
|-------------------|---------|--------|
| `flutter_lints` | `^6.0.0` | Active — base lint ruleset |
| `custom_lint` | `^0.7.5` | Active — plugin host for riverpod_lint |
| `riverpod_lint` | `^2.6.4` | Active — Riverpod-specific rules |

These are dev dependencies that survive into the cleanup phase. The audit pipeline adds on top of them, not instead of them.

---

## Recommended Stack by Category

### Category 1 — Layer-Violation / Dependency-Direction Enforcement

**Primary: `import_guard` (pub.dev analyzer plugin)**

`import_guard` is an analyzer plugin that enforces import restrictions between folders using `import_guard.yaml` with glob patterns. It requires Dart 3.10+ (matching this project's `sdk: ^3.10.8`). Last updated January 4, 2026 on pub.dev. It integrates with the standard `dart analyze` flow — no separate CLI binary, no paid license, no build runner step.

Configuration lives in `import_guard.yaml` alongside `analysis_options.yaml`:

```yaml
# import_guard.yaml — enforces 5-layer Clean Architecture
rules:
  - path: "lib/features/**/domain/**"
    deny:
      - "lib/data/**"
      - "lib/infrastructure/**"
      - "lib/features/**/presentation/**"
    message: "Domain layer must not import Data, Infrastructure, or Presentation"

  - path: "lib/application/**"
    deny:
      - "lib/features/**/presentation/**"
      - "lib/data/daos/**"
      - "lib/data/tables/**"
    message: "Application layer must not import Presentation or raw Data internals"

  - path: "lib/features/**/presentation/**"
    deny:
      - "lib/data/tables/**"
      - "lib/data/daos/**"
      - "lib/infrastructure/crypto/services/**"
    message: "Presentation must not access crypto services or DB internals directly"
```

Add to `analysis_options.yaml`:
```yaml
analyzer:
  plugins:
    - import_guard
```

Add to `pubspec.yaml` dev_dependencies:
```yaml
import_guard: ^0.x.x  # verify current version on pub.dev
```

**Why `import_guard` over alternatives:**

| Tool | Verdict | Reason |
|------|---------|--------|
| `import_guard` | **USE** | Free, integrates with `dart analyze`, Dart 3.10+ compatible, Jan 2026 update |
| `architecture_linter` | Fallback | CLI-only (not analyzer plugin), requires manual runs, less CI-friendly |
| `clean_architecture_linter` (v1.0.8) | Avoid | Last seen at version 1.0.8, Dart 3 compatibility unverified, low adoption |
| `clean_architecture_kit` | Investigate | Newer entrant, opinionated Riverpod assumptions, maturity uncertain |
| DCM `avoid-banned-imports` rule | Use if DCM is licensed | Gold standard for precision; documented guide for layered architecture (dcm.dev/docs/guides/advanced-architecture-rules-guide); requires paid DCM license |

**Fallback (CI script approach):** If `import_guard` proves insufficient for a specific rule, a Dart script using the `analyzer` package to walk ASTs and assert import paths is ~50 lines and fully auditable. This is the escape hatch, not the primary tool.

**Confidence:** MEDIUM — `import_guard` is functional and maintained for Dart 3.10+, but it is a relatively niche package. The DCM `avoid-banned-imports` is the industry-grade solution; if the team acquires a DCM license, migrate to it.

---

### Category 2 — Dead Code and Unreachable Code Detection

**Primary: Built-in `dart analyze` diagnostics**

The Dart SDK analyzer already emits:
- `dead_code` — unreachable branches, dead catch clauses, unreachable switch arms
- `unused_element` — private declarations never referenced within the library
- `unused_import` — imports with no referencing symbol in the file
- `unused_local_variable` — local variables assigned but never read

These run as part of `flutter analyze` with zero additional setup. They catch the most common cases for unreachable branches and unused imports. The zero-analyzer-warnings policy already enforced by this project means these diagnostics are already gated.

**Secondary: `dart_code_linter` (free, open-source DCM fork)**

`dart_code_linter` is the open-source fork of Dart Code Metrics maintained by a separate team after the commercial DCM split in 2023. Version 1.2.1 (November 2025), Dart 3 compatible, 70+ pre-built rules, free. Provides:
- `check-unused-code` — finds unused class members, methods, and constructors across the whole project (not just within a file)
- `check-unused-files` — finds orphaned `.dart` files with no imports pointing to them

```bash
# One-off audit run
dart run dart_code_linter:metrics check-unused-code lib
dart run dart_code_linter:metrics check-unused-files lib
```

Add to `pubspec.yaml` dev_dependencies:
```yaml
dart_code_linter: ^1.2.1
```

Add to `analysis_options.yaml` to enable the analyzer plugin component:
```yaml
dart_code_linter:
  rules:
    - prefer-trailing-comma
    # ... add specific rules as needed
```

**Why `dart_code_linter` over alternatives:**

| Tool | Verdict | Reason |
|------|---------|--------|
| `dart_code_linter` | **USE** | Free, Dart 3 compatible, Nov 2025 update, fork of original DCM with stable CLI |
| DCM (`dcm`) | Use if licensed | Commercial product (dcm.dev/pricing). As of 2025-2026: paid Individual/Team licenses required. Free tier now includes 100 rules. `check-unused-code` and `check-unused-files` are the gold standard for exhaustiveness. Version 1.36.0 (March 2026). |
| `dead_code_analyzer` | Avoid | Solo-author package, only at v0.1.1, regex-based (not AST), known false positives with constructors |
| Built-in `unused_element` only | Insufficient | Misses project-level orphaned files and public API dead exports |

**DO NOT USE: `dart_code_metrics` (the original pub.dev package).** The `dart_code_metrics` package on pub.dev was sunset in 2023 when DCM went commercial. The `dart-code-checker/dart-code-metrics` GitHub repository is archived/inactive. Using it will get stale rules and no Dart 3 compatibility guarantees.

**Confidence:** HIGH for built-in diagnostics (they ship with the SDK). MEDIUM for `dart_code_linter` (active but smaller community than DCM). LOW for DCM without purchasing a license (cannot verify exact free-tier coverage of `check-unused-code`).

---

### Category 3 — Riverpod Provider Hygiene

**Primary: `riverpod_lint` (already installed at `^2.6.4`)**

Already wired via `custom_lint: ^0.7.5`. No new installation needed. The existing `riverpod_lint: ^2.6.4` in the project's `pubspec.yaml` is the correct version for `riverpod_annotation: ^2.6.1`.

**Do not upgrade to riverpod_lint 3.x** until the project upgrades to Riverpod 3.0. Riverpod 3.0 `riverpod_lint` 3.0.3 has known analyzer dependency conflicts with `json_serializable`'s requirement for `analyzer >=9.0.0`, which this project uses for its Freezed/JSON serialization code gen.

Rules that `riverpod_lint 2.6.x` catches and that are directly relevant to the audit goals:

| Rule | What It Catches | Audit Category |
|------|-----------------|----------------|
| `missing_provider_scope` | `runApp()` without `ProviderScope` | Provider hygiene |
| `avoid_public_notifier_properties` | Public state outside `state` on Notifiers | Provider hygiene |
| `provider_dependencies` | Incorrect `@Riverpod(dependencies: [...])` | Provider hygiene |
| `scoped_providers_should_specify_dependencies` | Overridden providers missing `dependencies:` | Provider hygiene |
| `unsupported_provider_value` | `StateNotifier` created via `riverpod_generator` | Provider hygiene |

**What `riverpod_lint` does NOT catch** (requires manual/AI audit):
- Duplicate `@riverpod` function names across feature `repository_providers.dart` files — riverpod_lint only validates semantics within a file, not cross-file uniqueness of logically equivalent providers
- Misplaced Use Case providers wired in `lib/application/` instead of `lib/features/.../presentation/providers/`
- `UnimplementedError` placeholders thrown from provider bodies (riverpod_lint does catch the scoped-provider override pattern, but not generic `throw UnimplementedError()` in non-scoped providers)

For the gaps above, the AI-agent semantic scan is the correct tool (per the hybrid audit approach in PROJECT.md).

**Enable `custom_lint` output in analysis:**

`custom_lint` is already a dev dependency. Ensure it runs in CI:
```bash
dart run custom_lint
```

This produces riverpod_lint output separately from `flutter analyze`. Both must pass.

**Confidence:** HIGH — `riverpod_lint` is maintained by the Riverpod author (rrousselGit), updated February 2026, and the 2.6.x series is a stable match for this project's Riverpod 2.6.x.

---

### Category 4 — Type and Code Duplication Detection

**There is no authoritative, maintained Dart-native duplicate-code detection tool with AST-level precision that is free and Dart 3 compatible as of April 2026.**

The options are:

**Option A: DCM `check-unused-code` + `avoid-banned-types` rule (paid)**

DCM provides the most precise duplicate-type and duplicate-implementation detection, but requires a license.

**Option B: `jscpd` (cross-language copy-paste detector, free, Node.js)**

`jscpd` (JavaScript Copy-Paste Detector) supports Dart files via its `--languages dart` flag. It does token-based similarity detection across files, not AST-level, but it is effective for finding copy-pasted blocks (e.g., duplicated Freezed model definitions, duplicated provider patterns).

```bash
npx jscpd lib/ --languages dart --min-lines 5 --min-tokens 50 --reporters console,html
```

No pub.dev dependency. Requires Node.js in CI (standard on GitHub Actions runners).

**Option C: AI-agent semantic scan (per PROJECT.md hybrid approach)**

For the specific case of duplicate Freezed models and duplicate domain types, an AI agent scanning the codebase with semantic understanding outperforms token-based tools. Two Freezed classes with different names but identical fields and semantics will not be caught by token-matching but will be caught by an AI reviewing `lib/features/*/domain/models/`.

**Recommendation:** Use `jscpd` for mechanical copy-paste blocks, AI-agent scan for semantic duplication (duplicate model concepts with different names). Do not purchase DCM solely for duplication detection if the rest of the audit can be done free.

**DO NOT USE:** `dart_code_metrics` cyclomatic detection (archived). No active Dart-native CPD tool beyond `jscpd` exists in the free tier.

**Confidence:** LOW — the duplicate-detection gap is real and acknowledged. No single free tool covers it well. The hybrid approach is the pragmatic solution for this project.

---

### Category 5 — Test Coverage Measurement and Enforcement

**Primary: `flutter test --coverage` + `very_good_coverage` GitHub Action**

`flutter test --coverage` generates `coverage/lcov.info` — this is the standard Flutter mechanism and requires no additional packages.

`very_good_coverage` is a GitHub Action (not a pub.dev package) at `VeryGoodOpenSource/very_good_coverage@v2` (current version). It reads the `lcov.info` file and fails the PR if the global coverage falls below `min_coverage`.

```yaml
# .github/workflows/ci.yml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Enforce coverage threshold
  uses: VeryGoodOpenSource/very_good_coverage@v2
  with:
    path: coverage/lcov.info
    min_coverage: 80
    exclude: |
      **/*.g.dart
      **/*.freezed.dart
      lib/generated/**
```

**Secondary: `coverde` (pub.dev, free, active)**

`coverde` is a Dart CLI tool that adds per-file coverage checking and human-readable coverage reports. It reads `lcov.info` and can fail if any individual file falls below a threshold. Updated January 11, 2026 on pub.dev.

```bash
# After flutter test --coverage
dart run coverde check --min-coverage 80 coverage/lcov.info
```

Add to `pubspec.yaml` dev_dependencies:
```yaml
coverde: ^0.x.x  # verify current version on pub.dev
```

**Recommendation for this project:**
- `very_good_coverage@v2` handles the CI gate (global 80% threshold)
- `coverde` handles per-file inspection locally during audit phases to identify which refactored files need tests

| Tool | Verdict | Reason |
|------|---------|--------|
| `very_good_coverage@v2` | **USE** | GitHub Action, zero pub.dev dependency, actively maintained by Very Good Ventures, supports exclude globs |
| `coverde` | **USE** | Free, Dart CLI, per-file checks, Jan 2026 update |
| `lcov` (system tool) | Optional | Raw LCOV processing; `coverde` wraps it more ergonomically |
| `flutter_ci_guard` | Skip | Combined format+analyze+coverage guard — less granular than individual tools |
| Codecov.io | Optional | Cloud coverage dashboard; adds upload step but provides diff coverage on PRs — good for tracking coverage trend over the cleanup |

**Confidence:** HIGH — `very_good_coverage@v2` is the de facto Flutter community standard for CI coverage gates. `coverde` is actively maintained and straightforward.

---

## Full Stack Summary Table

| Category | Primary Tool | Version | License | Setup Complexity |
|----------|-------------|---------|---------|-----------------|
| Layer enforcement | `import_guard` | verify pub.dev | Free | 1-line pubspec + yaml config |
| Dead code (file/member) | `dart_code_linter` | 1.2.1 | Free/OSS | 1-line pubspec + CLI command |
| Dead code (branch/import) | `dart analyze` built-ins | SDK | Free | Already running |
| Riverpod hygiene | `riverpod_lint` + `custom_lint` | 2.6.4 + 0.7.5 | Free | Already installed |
| Copy-paste duplication | `jscpd` | npm latest | Free | Node.js + CLI, no pubspec |
| Semantic duplication | AI-agent scan | N/A | N/A | Per audit phase |
| Coverage gate (CI) | `very_good_coverage@v2` | v2 | Free | GitHub Actions YAML only |
| Coverage per-file | `coverde` | verify pub.dev | Free | 1-line pubspec + CLI command |

---

## Installation Additions

Additions to `pubspec.yaml` `dev_dependencies` (nothing in `dependencies`):

```yaml
dev_dependencies:
  # Already installed — no change needed:
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.4
  flutter_lints: ^6.0.0

  # Add for audit pipeline:
  import_guard: ^0.x.x      # verify exact version on pub.dev before adding
  dart_code_linter: ^1.2.1   # free DCM fork; provides check-unused-code/files CLI
  coverde: ^0.x.x            # per-file coverage CLI; verify exact version on pub.dev
```

`analysis_options.yaml` additions:

```yaml
analyzer:
  plugins:
    - import_guard       # add this; keep existing custom_lint plugin
    - custom_lint        # already present via riverpod_lint
```

`jscpd` needs no pubspec entry — run via `npx jscpd` in CI.

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `dart_code_metrics` (pub.dev package) | Sunset June 2023 when DCM went commercial; archived GitHub repo; no Dart 3 updates | `dart_code_linter` (the free fork) |
| `dead_code_analyzer` | Solo-author, v0.1.1 only, regex-based (not AST), known false positives with constructors | `dart_code_linter check-unused-code` |
| `clean_architecture_linter` v1.0.8 | Last seen at 1.0.8, Dart 3 compatibility unclear, low pub.dev score | `import_guard` |
| `riverpod_lint` v3.x (upgrade) | Introduces `analyzer >=7.0.0 <9.0.0` conflict with `json_serializable >=9.0.0`; project uses Riverpod 2.6.x stack | Stay at `^2.6.4` until full Riverpod 3.0 migration |
| `flutter_clean_architecture` package | Framework/scaffolding package, not a lint tool; dead on Dart 3 | Enforce architecture via `import_guard` |

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `riverpod_lint ^2.6.4` | `riverpod_annotation ^2.6.1`, `custom_lint ^0.7.5`, Dart 3.x | Do not upgrade to 3.x without upgrading full Riverpod stack |
| `dart_code_linter ^1.2.1` | Dart 3+, Flutter 3+ | Free fork; verify it does not conflict with analyzer version used by other tools |
| `import_guard` | Dart 3.10+ required | Matches project's `sdk: ^3.10.8` — compatible |
| `coverde` | Dart 3+, reads standard lcov.info | No known conflicts |
| `very_good_coverage@v2` | GitHub Actions only | Not a Dart package; no pubspec conflict |
| `jscpd` | Node.js, any Dart version | Runs outside Dart toolchain entirely |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `import_guard` | DCM `avoid-banned-imports` | When team purchases DCM license — DCM is more precise and supports regex paths |
| `dart_code_linter` | DCM `check-unused-code` | When team purchases DCM license — DCM has Freezed-aware detection (v1.36 detects Freezed classes only referenced in generated code) |
| `jscpd` + AI scan | DCM duplication rules | When team purchases DCM license |
| `very_good_coverage@v2` | Codecov diff coverage | When per-PR diff coverage trend matters more than absolute threshold; Codecov adds cloud dependency |

**On DCM (dcm.dev):** DCM is the gold standard for Flutter code quality tooling. Version 1.36.0 (March 2026), 181+ rules in recommended preset, MCP server integration for AI-assisted audits, active development with 8+ releases in 2025. Free tier (100 rules) may not cover `check-unused-code`/`check-unused-files` as CLI commands — verify at dcm.dev/pricing before assuming free. For a private app (not OSS), the paid license applies. If the team budgets for DCM, replace `dart_code_linter` + `import_guard` with DCM entirely.

---

## Sources

- [pub.dev: import_guard](https://pub.dev/packages/import_guard) — last updated Jan 2026, Dart 3.10+ requirement confirmed
- [pub.dev: dart_code_linter](https://pub.dev/packages/dart_code_linter) — v1.2.1, Nov 2025, free OSS fork
- [pub.dev: riverpod_lint](https://pub.dev/packages/riverpod_lint) — Feb 2026 update, 2.6.x series
- [pub.dev: riverpod_lint changelog](https://pub.dev/packages/riverpod_lint/changelog) — rule list verified
- [pub.dev: custom_lint](https://pub.dev/packages/custom_lint) — Sep 2025 update
- [pub.dev: coverde](https://pub.dev/packages/coverde) — Jan 2026 update
- [dcm.dev: avoid-banned-imports guide](https://dcm.dev/docs/guides/advanced-architecture-rules-guide/) — layer enforcement configuration
- [dcm.dev: check-unused-code](https://dcm.dev/docs/cli/code-quality-checks/unused-code/) — CLI reference
- [dcm.dev: DCM 2025 Year in Review](https://dcm.dev/blog/2026/01/15/dcm-2025-year-in-review) — 181 rules, 8 releases, Jan 2026
- [dcm.dev: DCM 1.36.0 changelog](https://dcm.dev/blog/2026/03/19/whats-new-in-dcm-1-36-0/) — Freezed-aware unused-code detection
- [dcm.dev: sunset announcement](https://dcm.dev/blog/2023/06/06/announcing-dcm-free-version-sunset/) — confirms pub.dev `dart_code_metrics` is dead
- [GitHub: VeryGoodOpenSource/very_good_coverage](https://github.com/VeryGoodOpenSource/very_good_coverage) — @v2, actively maintained
- [Riverpod issues: analyzer conflict #4393](https://github.com/rrousselGit/riverpod/issues/4393) — riverpod_lint 3.x / json_serializable conflict warning
- [codewithandrea.com: riverpod_lint guide](https://codewithandrea.com/articles/flutter-riverpod-lint/) — rule explanations verified
- [dart.dev: unused_element diagnostic](https://dart.dev/tools/diagnostics/unused_element) — built-in dead code detection confirmed

---

*Stack research for: Flutter/Dart codebase audit and cleanup tooling*
*Researched: 2026-04-25*
