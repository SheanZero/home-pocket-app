---
phase: 03-critical-fixes
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/domain/import_guard.yaml
  - lib/features/analytics/domain/import_guard.yaml
  - lib/features/family_sync/domain/import_guard.yaml
  - lib/features/home/domain/import_guard.yaml
  - lib/features/profile/domain/import_guard.yaml
  - lib/features/settings/domain/import_guard.yaml
  - lib/features/accounting/domain/models/import_guard.yaml
  - lib/features/accounting/domain/repositories/import_guard.yaml
  - lib/features/analytics/domain/models/import_guard.yaml
  - lib/features/analytics/domain/repositories/import_guard.yaml
  - lib/features/family_sync/domain/models/import_guard.yaml
  - lib/features/family_sync/domain/repositories/import_guard.yaml
  - lib/features/profile/domain/repositories/import_guard.yaml
  - lib/features/settings/domain/repositories/import_guard.yaml
  - test/architecture/domain_import_rules_test.dart
  - pubspec.yaml
  - .github/workflows/audit.yml
autonomous: true
requirements:
  - CRIT-01
  - CRIT-04
  - CRIT-06
tags:
  - import_guard
  - domain_layer
  - architecture_test
  - critical_fixes
must_haves:
  truths:
    - "Domain-layer files import only Dart core, freezed_annotation, json_annotation, meta, and same-feature intra-domain leaves"
    - "Each lib/features/<f>/domain/import_guard.yaml is deny-only — the allow whitelist has been moved to per-subdirectory yamls per the CORRECTED D-01 strategy verified in 03-RESEARCH.md (import_guard_custom_lint evaluates each config in the chain INDEPENDENTLY against its own allow whitelist; literal D-01 wording would not fix the LV findings)"
    - "Each lib/features/<f>/domain/{models,repositories}/import_guard.yaml exists where needed and declares an allow list of dart:core + 3 annotation packages + intra-domain leaves only"
    - "test/architecture/domain_import_rules_test.dart loads every domain import_guard.yaml and asserts deny set + allow shape — fails CI if the deny list weakens or allow leaves expand outside intra-domain composition"
    - "D-02: ship test/architecture/domain_import_rules_test.dart — Dart unit test that loads each features/<f>/domain/import_guard.yaml (and subdirectory descendants), parses YAML, and asserts deny list still contains data/**, infrastructure/**, application/**, presentation/**, flutter/**; fails CI if anyone weakens the rule"
    - "D-03: establish test/architecture/ directory as the convention for meta-tests about codebase shape — future phases (provider-graph hygiene in Phase 4) extend this directory"
    - "dart run custom_lint exits 0 with zero LV-001..LV-016, LV-023, LV-024 findings (19 layer-violations closed)"
    - "All 19 LV findings closed in issues.json (status flipped open → closed with closed_in_phase: 3)"
    - "Operational repo lock per Phase 2 D-07 / D-16 active throughout: only Phase 3 plan PRs merge to main"
    - ".github/workflows/audit.yml import_guard step has 'continue-on-error: true' REMOVED (D-17 blocking flip is the LAST commit of Phase 3 after all other plans complete)"
  artifacts:
    - path: "lib/features/accounting/domain/import_guard.yaml"
      provides: "Feature-level domain deny-only yaml — allow stripped per RESEARCH.md correction"
      contains: "deny:"
      excludes: "allow:"
    - path: "lib/features/accounting/domain/models/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for accounting/domain/models/"
      contains: "transaction.dart"
    - path: "lib/features/accounting/domain/repositories/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for accounting/domain/repositories/"
      contains: "../models/transaction.dart"
    - path: "lib/features/analytics/domain/models/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for analytics/domain/models/"
      contains: "daily_expense.dart"
    - path: "lib/features/analytics/domain/repositories/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for analytics/domain/repositories/"
      contains: "../models/analytics_aggregate.dart"
    - path: "lib/features/family_sync/domain/models/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for family_sync/domain/models/"
      contains: "group_member.dart"
    - path: "lib/features/family_sync/domain/repositories/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for family_sync/domain/repositories/"
      contains: "../models/group_info.dart"
    - path: "lib/features/profile/domain/repositories/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for profile/domain/repositories/"
      contains: "../models/user_profile.dart"
    - path: "lib/features/settings/domain/repositories/import_guard.yaml"
      provides: "Per-subdirectory allow whitelist for settings/domain/repositories/"
      contains: "../models/app_settings.dart"
    - path: "test/architecture/domain_import_rules_test.dart"
      provides: "Meta-test asserting deny list contents + allow shape across all domain yamls"
      contains: "containsAll(requiredDeny)"
      min_lines: 40
    - path: ".github/workflows/audit.yml"
      provides: "import_guard CI step blocking (continue-on-error stripped) — LAST commit of Phase 3"
      excludes: "continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)"
  key_links:
    - from: "lib/features/<f>/domain/import_guard.yaml"
      to: "lib/features/<f>/domain/{models,repositories}/import_guard.yaml"
      via: "inherit: true (parent deny + child allow chain — each evaluated independently)"
      pattern: "inherit:\\s*true"
    - from: "test/architecture/domain_import_rules_test.dart"
      to: "lib/features/*/domain/**/import_guard.yaml"
      via: "loadYaml(File(path).readAsStringSync())"
      pattern: "loadYaml"
    - from: ".github/workflows/audit.yml"
      to: "dart run custom_lint"
      via: "blocking step (no continue-on-error)"
      pattern: "dart run custom_lint"
---

<objective>
Eliminate 19 of the 24 CRITICAL layer-violation findings (LV-001..LV-016, LV-023, LV-024) by applying the **CORRECTED D-01 strategy** documented in 03-RESEARCH.md §"Pattern 1": strip the `allow:` block from each `lib/features/<f>/domain/import_guard.yaml` (parent becomes deny-only) and create per-subdirectory `import_guard.yaml` files under `models/` and `repositories/` whose allow lists declare only the intra-domain leaves they compose. Ship `test/architecture/domain_import_rules_test.dart` as the convention-establishing arch test for D-02/D-03. Flip `import_guard` to **blocking** in `.github/workflows/audit.yml` as the LAST commit of Phase 3 (D-17) after Plans 03-02..05 close.

**Why the correction matters:** RESEARCH.md verified at `~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/lib/src/import_guard_lint.dart:71-94` that each config in the inheritance chain is evaluated INDEPENDENTLY against its own `allow` whitelist. If the parent feature-level yaml retains `allow: [dart:core, freezed_annotation/**, json_annotation/**, meta/**]`, intra-domain imports still fail because they are not in the parent's allow list. The literal D-01 wording therefore does NOT close LV-001..LV-016/023/024. Stripping the parent allow + pushing it to per-subdir yamls is the only working strategy.

Purpose: Restore CRIT-04 (Domain-layer purity) with surgical precision and ship the architecture test that prevents future regression. Close the 19 in-scope LV findings; flip CI to blocking so Phase 4 inherits a guaranteed-clean Domain layer.

Output:
- 6 feature-level domain yamls (REVISED — allow stripped)
- ~9 per-subdirectory yamls (NEW — allow leaves declared per the inventory below)
- 1 architecture test (NEW)
- 1 audit.yml flip (LAST COMMIT of Phase 3 — gated on Plans 03-02..05 completion)
- 19 issues.json findings flipped open → closed
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/03-critical-fixes/03-CONTEXT.md
@.planning/phases/03-critical-fixes/03-RESEARCH.md
@.planning/phases/03-critical-fixes/03-PATTERNS.md
@.planning/phases/03-critical-fixes/03-VALIDATION.md
@.planning/audit/issues.json
@.planning/audit/SCHEMA.md
@.planning/audit/REPO-LOCK-POLICY.md
@CLAUDE.md

<interfaces>
<!-- Key contracts the executor needs. Embedded so no codebase exploration is required. -->

## Current state of `lib/features/accounting/domain/import_guard.yaml` (representative — all 6 feature-level yamls are byte-identical)

```yaml
# Domain layer — leafmost in the dependency graph (CRIT-04 territory).
# Whitelist mode: deny everything except dart:core + the immutability/serialization annotations.
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**

inherit: true
```

## Required NEW state for each `lib/features/<f>/domain/import_guard.yaml` (deny-only, allow STRIPPED)

```yaml
# Domain layer — leafmost in the dependency graph (CRIT-04 territory).
# Per Phase 3 D-01 (corrected per 03-RESEARCH.md): allow whitelist moved to per-subdirectory
# yamls because import_guard_custom_lint evaluates each config in the chain
# independently against its own allow whitelist. Parent owns deny only.
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
# NOTE: no `allow:` block — children own the whitelist (see models/, repositories/ subdirs)
```

## Per-subdirectory allow lists (RESEARCH.md "Per-feature inventory" §"Pattern 1")

| Feature | `models/` allow leaves (closes findings) | `repositories/` allow leaves (closes findings) |
|---------|------------------------------------------|------------------------------------------------|
| accounting | `transaction.dart` (LV-001 line 3 of category_ledger_config.dart, LV-003 line 1 of transaction_sync_mapper.dart, LV-004 line 3 of voice_parse_result.dart), `category.dart` (LV-002 line 3 of category_reorder_state.dart) | `../models/book.dart` (LV-005), `../models/category_keyword_preference.dart` (LV-006), `../models/category_ledger_config.dart` (LV-007), `../models/category.dart` (LV-008), `../models/merchant_category_preference.dart` (LV-009), `../models/transaction.dart` (LV-010) |
| analytics | `daily_expense.dart` (LV-011), `month_comparison.dart` (LV-012) | `../models/analytics_aggregate.dart` (LV-013) |
| family_sync | `group_member.dart` (LV-014) | `../models/group_info.dart` (LV-015), `../models/group_member.dart` (LV-016) |
| home | (no models/ yaml needed — `ledger_row_data.dart` MOVES OUT in Plan 03-04 → LV-022 closes there) | (no repositories/ yaml needed — directory has no files) |
| profile | (no models/ yaml — directory has only models with no intra-domain imports) | `../models/user_profile.dart` (LV-023) |
| settings | (no models/ yaml — directory has only models with no intra-domain imports) | `../models/app_settings.dart` (LV-024) |

## Ground truth — current `lib/features/family_sync/domain/models/`

```
group_info.dart, group_info.freezed.dart, group_info.g.dart,
group_member.dart, group_member.freezed.dart, group_member.g.dart,
sync_message.dart, sync_message.freezed.dart, sync_message.g.dart,
sync_status_model.dart, sync_status_model.freezed.dart, sync_trigger_event.dart
```

## `.github/workflows/audit.yml` lines 40-42 (CURRENT)

```yaml
      - name: dart run custom_lint
        continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)
        run: dart run custom_lint
```

## `.github/workflows/audit.yml` lines 40-42 (REQUIRED at Phase 3 close — D-17)

```yaml
      - name: dart run custom_lint
        # Made blocking at Phase 3 close per D-17 (was: continue-on-error: true).
        # Phase 4 still relies on import_guard remaining 0-violation.
        run: dart run custom_lint
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Strip parent feature-level domain `allow` blocks (6 yamls) + write all per-subdirectory yamls (~9 new yamls) per the corrected D-01 strategy</name>
  <files>
    lib/features/accounting/domain/import_guard.yaml,
    lib/features/analytics/domain/import_guard.yaml,
    lib/features/family_sync/domain/import_guard.yaml,
    lib/features/home/domain/import_guard.yaml,
    lib/features/profile/domain/import_guard.yaml,
    lib/features/settings/domain/import_guard.yaml,
    lib/features/accounting/domain/models/import_guard.yaml,
    lib/features/accounting/domain/repositories/import_guard.yaml,
    lib/features/analytics/domain/models/import_guard.yaml,
    lib/features/analytics/domain/repositories/import_guard.yaml,
    lib/features/family_sync/domain/models/import_guard.yaml,
    lib/features/family_sync/domain/repositories/import_guard.yaml,
    lib/features/profile/domain/repositories/import_guard.yaml,
    lib/features/settings/domain/repositories/import_guard.yaml
  </files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Pattern 1: Per-subdirectory `import_guard.yaml` with corrected D-01 strategy" lines 267-341 — read in full; this is the SOURCE OF TRUTH for why parent `allow` must be stripped)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`lib/features/*/domain/import_guard.yaml`" + §"`lib/features/*/domain/{models,repositories}/import_guard.yaml`")
    - lib/features/accounting/domain/import_guard.yaml (current state, before edit)
    - lib/features/analytics/domain/import_guard.yaml
    - lib/features/family_sync/domain/import_guard.yaml
    - lib/features/home/domain/import_guard.yaml
    - lib/features/profile/domain/import_guard.yaml
    - lib/features/settings/domain/import_guard.yaml
    - lib/features/import_guard.yaml (root deny — already denies use_cases/, application/, infrastructure/, data/ under features; do NOT touch in this plan)
  </read_first>
  <action>
    Apply the CORRECTED D-01 strategy per 03-RESEARCH.md §"Pattern 1".

    **Step 1 — REVISE all 6 feature-level domain yamls (strip `allow:` block).** Replace the contents of each of these files with EXACTLY:

    ```yaml
    # Domain layer — leafmost in the dependency graph (CRIT-04 territory).
    # Per Phase 3 D-01 (corrected per 03-RESEARCH.md §"Pattern 1"):
    # allow whitelist moved to per-subdirectory yamls because import_guard_custom_lint
    # evaluates each config in the chain independently against its own allow whitelist
    # (verified at ~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/lib/src/import_guard_lint.dart:71-94).
    # Parent owns deny only; children own the whitelist.
    deny:
      - package:home_pocket/data/**
      - package:home_pocket/infrastructure/**
      - package:home_pocket/application/**
      - package:home_pocket/features/**/presentation/**
      - package:flutter/**

    inherit: true
    # NOTE: no `allow:` block — see models/import_guard.yaml and repositories/import_guard.yaml
    ```

    Apply byte-identically to all 6 features: accounting, analytics, family_sync, home, profile, settings.

    **Step 2 — CREATE per-subdirectory yamls.** Use the inventory in `<interfaces>` above. Each per-subdirectory yaml uses **relative path patterns** (e.g., `transaction.dart`, `../models/book.dart`) per RESEARCH.md §"Pattern 1" (verified pattern resolution at `import_guard_lint.dart:128-136`).

    Write `lib/features/accounting/domain/models/import_guard.yaml`:
    ```yaml
    # Per-subdirectory whitelist (Phase 3 D-01 corrected). Inherits parent feature-level deny.
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - transaction.dart                 # closes LV-001 (category_ledger_config.dart), LV-003 (transaction_sync_mapper.dart), LV-004 (voice_parse_result.dart)
      - category.dart                    # closes LV-002 (category_reorder_state.dart)

    inherit: true
    ```

    Write `lib/features/accounting/domain/repositories/import_guard.yaml`:
    ```yaml
    # Per-subdirectory whitelist (Phase 3 D-01 corrected). Inherits parent feature-level deny.
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - ../models/book.dart                          # closes LV-005
      - ../models/category_keyword_preference.dart   # closes LV-006
      - ../models/category_ledger_config.dart        # closes LV-007
      - ../models/category.dart                      # closes LV-008
      - ../models/merchant_category_preference.dart  # closes LV-009
      - ../models/transaction.dart                   # closes LV-010

    inherit: true
    ```

    Write `lib/features/analytics/domain/models/import_guard.yaml`:
    ```yaml
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - daily_expense.dart                # closes LV-011 (monthly_report.dart line 3)
      - month_comparison.dart             # closes LV-012 (monthly_report.dart line 4)

    inherit: true
    ```

    Write `lib/features/analytics/domain/repositories/import_guard.yaml`:
    ```yaml
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - ../models/analytics_aggregate.dart   # closes LV-013

    inherit: true
    ```

    Write `lib/features/family_sync/domain/models/import_guard.yaml`:
    ```yaml
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - group_member.dart                 # closes LV-014 (group_info.dart line 3)

    inherit: true
    ```

    Write `lib/features/family_sync/domain/repositories/import_guard.yaml`:
    ```yaml
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - ../models/group_info.dart         # closes LV-015 (group_repository.dart line 1)
      - ../models/group_member.dart       # closes LV-016 (group_repository.dart line 2)

    inherit: true
    ```

    Write `lib/features/profile/domain/repositories/import_guard.yaml`:
    ```yaml
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - ../models/user_profile.dart       # closes LV-023

    inherit: true
    ```

    Write `lib/features/settings/domain/repositories/import_guard.yaml`:
    ```yaml
    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**
      - ../models/app_settings.dart       # closes LV-024

    inherit: true
    ```

    **Do NOT create:** `lib/features/home/domain/models/import_guard.yaml` (the only file in home/domain/models/ is `ledger_row_data.dart` which MOVES OUT in Plan 03-04, closing LV-022 there). `lib/features/home/domain/repositories/import_guard.yaml` (directory empty). `lib/features/profile/domain/models/import_guard.yaml` (no intra-domain LV finding). `lib/features/settings/domain/models/import_guard.yaml` (no intra-domain LV finding).

    **CRITICAL — verify the lint passes BEFORE proceeding to Task 2:** run `rm -rf .dart_tool && flutter pub get && dart run custom_lint 2>&1 | grep -E 'LV-|layer_violation' || echo CLEAN`. The output MUST be `CLEAN` or empty. If it still flags LV-001..016/023/024, the parent yaml `allow:` block was not stripped — re-read RESEARCH.md §"Pitfall 1: D-01 strategy as literally written breaks the lint" and fix.
  </action>
  <verify>
    <automated>! grep -l "^allow:" lib/features/*/domain/import_guard.yaml &amp;&amp; rm -rf .dart_tool &amp;&amp; flutter pub get &amp;&amp; dart run custom_lint</automated>
  </verify>
  <acceptance_criteria>
    - `grep -L "^allow:" lib/features/accounting/domain/import_guard.yaml lib/features/analytics/domain/import_guard.yaml lib/features/family_sync/domain/import_guard.yaml lib/features/home/domain/import_guard.yaml lib/features/profile/domain/import_guard.yaml lib/features/settings/domain/import_guard.yaml | wc -l` returns `6` (all 6 feature-level yamls have `allow:` STRIPPED)
    - `grep -c "^deny:" lib/features/accounting/domain/import_guard.yaml lib/features/analytics/domain/import_guard.yaml lib/features/family_sync/domain/import_guard.yaml lib/features/home/domain/import_guard.yaml lib/features/profile/domain/import_guard.yaml lib/features/settings/domain/import_guard.yaml` returns `1` for each (deny block preserved)
    - `test -f lib/features/accounting/domain/models/import_guard.yaml && grep -q "transaction.dart" lib/features/accounting/domain/models/import_guard.yaml` exits 0
    - `test -f lib/features/accounting/domain/repositories/import_guard.yaml && grep -q "../models/book.dart" lib/features/accounting/domain/repositories/import_guard.yaml` exits 0
    - `test -f lib/features/analytics/domain/models/import_guard.yaml && grep -q "daily_expense.dart" lib/features/analytics/domain/models/import_guard.yaml` exits 0
    - `test -f lib/features/analytics/domain/repositories/import_guard.yaml && grep -q "../models/analytics_aggregate.dart" lib/features/analytics/domain/repositories/import_guard.yaml` exits 0
    - `test -f lib/features/family_sync/domain/models/import_guard.yaml && grep -q "group_member.dart" lib/features/family_sync/domain/models/import_guard.yaml` exits 0
    - `test -f lib/features/family_sync/domain/repositories/import_guard.yaml && grep -q "../models/group_info.dart" lib/features/family_sync/domain/repositories/import_guard.yaml && grep -q "../models/group_member.dart" lib/features/family_sync/domain/repositories/import_guard.yaml` exits 0
    - `test -f lib/features/profile/domain/repositories/import_guard.yaml && grep -q "../models/user_profile.dart" lib/features/profile/domain/repositories/import_guard.yaml` exits 0
    - `test -f lib/features/settings/domain/repositories/import_guard.yaml && grep -q "../models/app_settings.dart" lib/features/settings/domain/repositories/import_guard.yaml` exits 0
    - `! test -f lib/features/home/domain/models/import_guard.yaml` (NOT created in this plan; LV-022 closes via Plan 03-04 file move)
    - `rm -rf .dart_tool && flutter pub get && dart run custom_lint` exits 0 with NO `layer_violation` mentions for LV-001..016, LV-023, LV-024
  </acceptance_criteria>
  <done>All 6 feature-level domain yamls are deny-only; ~8 per-subdirectory allow yamls exist and declare only intra-domain leaves; cold-start `dart run custom_lint` exits 0 with zero LV findings.</done>
</task>

<task type="auto">
  <name>Task 2: Promote `package:yaml` to dev_dependencies (if needed) and write `test/architecture/domain_import_rules_test.dart`</name>
  <files>
    pubspec.yaml,
    test/architecture/domain_import_rules_test.dart
  </files>
  <read_first>
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Pattern 4: Architecture deny-list test" lines 648-720, §"Open Questions" Q1 about package:yaml promotion)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"`test/architecture/domain_import_rules_test.dart`" — full skeleton at lines 614-664)
    - pubspec.yaml (current `dev_dependencies` block — to confirm whether `yaml` is already declared or transitive only)
  </read_first>
  <action>
    **Step 1 — package:yaml promotion check.**
    Run `dart pub deps --no-dev | grep -E '^\s*yaml '` first. If `yaml` is reported only as transitive (not direct), open `pubspec.yaml` and add to `dev_dependencies` (alphabetic order):
    ```yaml
      yaml: ^3.1.0
    ```
    Then run `flutter pub get`.

    If `dart pub deps` reports `yaml` as a direct dependency already, skip the pubspec edit.

    **Step 2 — write the architecture test.** Create `test/architecture/domain_import_rules_test.dart` with EXACTLY this body (per RESEARCH.md §"Pattern 4" + PATTERNS.md skeleton):

    ```dart
    // Architecture meta-test: enforces Domain layer import rules across all features.
    //
    // Per Phase 3 D-02/D-03 (CONTEXT.md): asserts that every
    // `lib/features/<f>/domain/import_guard.yaml` retains the deny set and
    // does NOT carry an `allow:` block (corrected D-01 strategy moves the
    // whitelist to per-subdirectory yamls). Asserts each
    // `lib/features/<f>/domain/{models,repositories}/import_guard.yaml`
    // (where present) declares only annotation packages + same-feature
    // intra-domain leaves.
    //
    // Failing this test means someone weakened the architectural commitment;
    // fix the yaml or have an explicit conversation about why it should change.

    import 'dart:io';

    import 'package:flutter_test/flutter_test.dart';
    import 'package:yaml/yaml.dart';

    void main() {
      group('Domain layer import_guard rules', () {
        const features = [
          'accounting',
          'analytics',
          'family_sync',
          'home',
          'profile',
          'settings',
        ];
        const requiredDeny = [
          'package:home_pocket/data/**',
          'package:home_pocket/infrastructure/**',
          'package:home_pocket/application/**',
          'package:home_pocket/features/**/presentation/**',
          'package:flutter/**',
        ];

        for (final feature in features) {
          group('feature: $feature', () {
            test('feature-level domain yaml has full deny set + no allow', () {
              final path = 'lib/features/$feature/domain/import_guard.yaml';
              final yaml =
                  loadYaml(File(path).readAsStringSync()) as YamlMap;
              final deny = (yaml['deny'] as YamlList)
                  .map((e) => e.toString())
                  .toList();
              expect(deny, containsAll(requiredDeny),
                  reason: 'Feature $feature: deny list weakened');
              expect(yaml['allow'], isNull,
                  reason:
                      'Phase 3 D-01 (corrected): feature-level allow moved to per-subdirectory yamls. '
                      'Feature $feature has parent allow — strip it; put leaves in models/ or repositories/ yaml.');
              expect(yaml['inherit'], isTrue,
                  reason: 'Feature $feature: inherit must remain true');
            });

            test('models/ subdir yaml allow is intra-domain only', () {
              final path =
                  'lib/features/$feature/domain/models/import_guard.yaml';
              if (!File(path).existsSync()) return; // not all features need this
              final yaml =
                  loadYaml(File(path).readAsStringSync()) as YamlMap;
              final allow = (yaml['allow'] as YamlList)
                  .map((e) => e.toString())
                  .toList();
              for (final entry in allow) {
                final isAnnotation = entry == 'dart:core' ||
                    entry.startsWith('package:freezed_annotation') ||
                    entry.startsWith('package:json_annotation') ||
                    entry.startsWith('package:meta');
                final isIntraDomainLeaf =
                    entry.endsWith('.dart') && !entry.contains('/');
                expect(isAnnotation || isIntraDomainLeaf, isTrue,
                    reason:
                        'Feature $feature models/: allow leaf "$entry" is neither annotation nor intra-domain leaf');
              }
              expect(yaml['inherit'], isTrue);
            });

            test('repositories/ subdir yaml allow is intra-domain only', () {
              final path =
                  'lib/features/$feature/domain/repositories/import_guard.yaml';
              if (!File(path).existsSync()) return;
              final yaml =
                  loadYaml(File(path).readAsStringSync()) as YamlMap;
              final allow = (yaml['allow'] as YamlList)
                  .map((e) => e.toString())
                  .toList();
              for (final entry in allow) {
                final isAnnotation = entry == 'dart:core' ||
                    entry.startsWith('package:freezed_annotation') ||
                    entry.startsWith('package:json_annotation') ||
                    entry.startsWith('package:meta');
                final isIntraDomainLeaf = entry.startsWith('../models/') &&
                    entry.endsWith('.dart');
                expect(isAnnotation || isIntraDomainLeaf, isTrue,
                    reason:
                        'Feature $feature repositories/: allow leaf "$entry" is neither annotation nor ../models/*.dart');
              }
              expect(yaml['inherit'], isTrue);
            });
          });
        }
      });
    }
    ```

    Run `flutter test test/architecture/domain_import_rules_test.dart`. All groups must be GREEN.
  </action>
  <verify>
    <automated>flutter pub get &amp;&amp; flutter test test/architecture/domain_import_rules_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `dart pub deps --no-dev | grep -E '^\s*yaml '` reports `yaml` as either direct dependency OR (if transitive only) `pubspec.yaml` `dev_dependencies` block now contains a `yaml:` entry
    - `test -f test/architecture/domain_import_rules_test.dart` exits 0
    - `grep -q "loadYaml" test/architecture/domain_import_rules_test.dart` exits 0
    - `grep -q "containsAll(requiredDeny)" test/architecture/domain_import_rules_test.dart` exits 0
    - `grep -q "Phase 3 D-01 (corrected)" test/architecture/domain_import_rules_test.dart` exits 0
    - `flutter test test/architecture/domain_import_rules_test.dart --no-pub --reporter compact` exits 0 with all expectations passing
  </acceptance_criteria>
  <done>`test/architecture/` directory exists with the new arch test; the test passes against the post-Task-1 yaml configuration.</done>
</task>

<task type="auto">
  <name>Task 3: Close 19 LV findings in issues.json + run plan-level coverage_gate against touched test/yaml files</name>
  <files>
    .planning/audit/issues.json
  </files>
  <read_first>
    - .planning/audit/issues.json (current state — 19 LV findings to flip from open → closed)
    - .planning/audit/SCHEMA.md (§2 closure mechanic — status flip + closed_in_phase + closed_commit)
    - .planning/audit/REPO-LOCK-POLICY.md (operational lock active throughout Phase 3 per D-16)
    - scripts/coverage_gate.dart (per-plan exit gate — invocation pattern from RESEARCH.md §"Coverage-gate invocation pattern")
  </read_first>
  <action>
    **Step 1 — close the 19 LV findings.** For each of LV-001, LV-002, LV-003, LV-004, LV-005, LV-006, LV-007, LV-008, LV-009, LV-010, LV-011, LV-012, LV-013, LV-014, LV-015, LV-016, LV-023, LV-024 in `.planning/audit/issues.json`:
    1. Flip `"status": "open"` → `"status": "closed"`
    2. Add `"closed_in_phase": 3`
    3. Add `"closed_commit": "<short-sha-of-Task-1-commit>"` (placeholder OK during plan execution; populate via `git log -1 --pretty=%h` after commit lands)

    Use `dart run scripts/merge_findings.dart` if it supports `--close <id> --phase 3 --commit <sha>` flags; otherwise hand-edit the JSON deterministically and re-run the merger to validate idempotency.

    Confirm: `jq '[.findings[] | select(.severity=="CRITICAL" and .status=="open" and (.id | startswith("LV-")))] | length' .planning/audit/issues.json` returns `5` (only LV-017..LV-021 + LV-022 = 5 remaining open after this plan; Plans 03-03 and 03-04 close them).

    **Step 2 — run plan-level coverage_gate.** This plan touches yaml + a new test file; the test file itself does not have ≥80% coverage gating semantics (it IS a test, not source). Build a touched-source-files list (empty for this plan because no production `lib/` source files are modified) and confirm the gate is a no-op:
    ```bash
    cat > /tmp/phase3-plan01-touched.txt <<'EOF'
    EOF
    flutter test --coverage
    coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
    dart run scripts/coverage_gate.dart --list /tmp/phase3-plan01-touched.txt --threshold 80 --lcov coverage/lcov_clean.info
    ```
    Empty list means the gate exits 0 trivially (per Phase 2 D-09 contract). If `coverage_gate.dart` requires non-empty list (treat empty as exit 2), document the no-op rationale in the plan summary and skip — Plan 03-01 modifies only YAML and test infra.

    **Step 3 — full-suite gate.** Run `flutter analyze && dart run custom_lint && flutter test` and confirm all three exit 0. This is the per-plan exit gate per Phase 3 CONTEXT D-15 + REPO-LOCK-POLICY.md.
  </action>
  <verify>
    <automated>jq -e '[.findings[] | select(.severity=="CRITICAL" and .status=="open" and (.id | startswith("LV-")))] | length == 5' .planning/audit/issues.json &amp;&amp; flutter analyze --no-fatal-infos &amp;&amp; dart run custom_lint &amp;&amp; flutter test test/architecture/</automated>
  </verify>
  <acceptance_criteria>
    - `jq '.findings[] | select(.id == "LV-001") | .status' .planning/audit/issues.json` returns `"closed"`
    - `jq '.findings[] | select(.id == "LV-016") | .status' .planning/audit/issues.json` returns `"closed"`
    - `jq '.findings[] | select(.id == "LV-023") | .status' .planning/audit/issues.json` returns `"closed"`
    - `jq '.findings[] | select(.id == "LV-024") | .status' .planning/audit/issues.json` returns `"closed"`
    - `jq '[.findings[] | select(.severity=="CRITICAL" and .status=="open" and (.id | startswith("LV-")))] | length' .planning/audit/issues.json` returns `5` (LV-017..LV-021 + LV-022 still open — closed by Plans 03-03/03-04)
    - All 19 closed findings have `closed_in_phase: 3`
    - `flutter analyze --no-fatal-infos` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test test/architecture/` exits 0
  </acceptance_criteria>
  <done>Issues.json reflects 19 LV closures; per-plan exit gates (analyze + custom_lint + arch test) all GREEN.</done>
</task>

<task type="auto">
  <name>Task 4: PHASE 3 CLOSE — Flip `import_guard` to blocking in `.github/workflows/audit.yml` (LAST commit of Phase 3)</name>
  <files>
    .github/workflows/audit.yml
  </files>
  <read_first>
    - .github/workflows/audit.yml (current state — line 40-42 carries the `continue-on-error: true` flag to be removed)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md (D-04 — staged enablement contract)
    - .planning/phases/03-critical-fixes/03-CONTEXT.md (D-17 — flip is the last commit of Phase 3)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Common Pitfalls" #6 — cold-start cache invalidation pitfall; #8 — irreversibility)
  </read_first>
  <action>
    **GATING CONDITION — DO NOT RUN until ALL of the following are merged to main:**
    - Plan 03-02 (AppInitializer + appDatabaseProvider) — Wave 2 alone
    - Plan 03-03 (5 use_case migrations) — Wave 1 parallel
    - Plan 03-04 (ledger_row_data move) — Wave 1 parallel
    - Plan 03-05 (characterization tests) — Wave 1 parallel

    Verify via:
    ```bash
    jq -e '[.findings[] | select(.severity=="CRITICAL" and .status=="open")] | length == 0' .planning/audit/issues.json || { echo "Open CRITICALs still exist — wait for other plans"; exit 1; }
    ```

    If that exits non-zero, STOP and surface the gating failure to the orchestrator. Do NOT proceed.

    **Step 1 — cold-start dry-run** (per RESEARCH.md Pitfall 6):
    ```bash
    rm -rf .dart_tool
    flutter pub get
    dart run custom_lint
    ```
    Must exit 0. If it fails, fix the underlying violation in the offending plan; do not flip yet.

    **Step 2 — flip the audit.yml step.** Edit `.github/workflows/audit.yml`. Find lines 40-42:
    ```yaml
          - name: dart run custom_lint
            continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)
            run: dart run custom_lint
    ```
    Replace with EXACTLY:
    ```yaml
          - name: dart run custom_lint
            # Made blocking at Phase 3 close per D-17. Was: continue-on-error: true.
            # Phase 4+ relies on import_guard remaining at 0 violations.
            run: dart run custom_lint
    ```

    Do NOT touch the `continue-on-error: true` on line 38 (`flutter analyze` — Phase 6 flips that) or line 44 (audit scanners — Phases 4/6 flip those individually).

    **Step 3 — commit with message:** `feat(03): flip import_guard to blocking — Phase 3 close (D-17)`. This MUST be a separate, standalone commit (do not bundle with other Task 4 work).

    **Step 4 — open the close-out PR with this single commit.** Run a fresh CI cycle and confirm:
    - `dart run custom_lint` step exits 0 (now blocking)
    - All other audit jobs continue passing
    - No unrelated regressions
  </action>
  <verify>
    <automated>! grep -q "continue-on-error: true   # Phase 4 exit gate flips this blocking" .github/workflows/audit.yml &amp;&amp; rm -rf .dart_tool &amp;&amp; flutter pub get &amp;&amp; dart run custom_lint</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -F "continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)" .github/workflows/audit.yml` exits 0 (line removed)
    - `grep -F "Made blocking at Phase 3 close per D-17" .github/workflows/audit.yml` exits 0 (replacement comment present)
    - `grep -c "continue-on-error: true" .github/workflows/audit.yml` returns `2` (only `flutter analyze` step on line 38 + audit scanners step retain `continue-on-error`)
    - `jq -e '[.findings[] | select(.severity=="CRITICAL" and .status=="open")] | length == 0' .planning/audit/issues.json` exits 0 (zero open CRITICALs at flip time)
    - `rm -rf .dart_tool && flutter pub get && dart run custom_lint` exits 0 from cold start (Pitfall 6)
    - GitHub Actions `audit.yml` workflow run on the flip commit exits 0 with `dart run custom_lint` step now blocking
  </acceptance_criteria>
  <done>`.github/workflows/audit.yml` enforces `import_guard` blocking; cold-start lint exits 0; Phase 3 is closed; Phase 4 inherits a clean Domain layer.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| YAML config → custom_lint runtime | YAML is read by import_guard_custom_lint and applied as architectural enforcement; weakening yaml weakens the deny rule |
| arch test → CI gate | Test asserts deny set + allow shape; failing test means future contributor weakened the architectural commitment |
| audit.yml continue-on-error flag → CI block | Removing the flag is functionally irreversible (no `[skip-import-guard]` label per REPO-LOCK-POLICY.md) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-01-01 | Tampering | `lib/features/<f>/domain/import_guard.yaml` (parent or per-subdir) | mitigate | `test/architecture/domain_import_rules_test.dart` asserts deny set + allow shape; CI fails on weakening. D-17 also makes `dart run custom_lint` blocking so any new layer violation is rejected at PR. |
| T-03-01-02 | Repudiation | "Architecture decision was changed without traceability" | mitigate | Comments in revised yamls explicitly cite "Phase 3 D-01 (corrected per 03-RESEARCH.md)" — discoverable via `git blame`; arch test reason strings reference the same |
| T-03-01-03 | Tampering | `.github/workflows/audit.yml` flip commit | mitigate | The flip is the LAST commit of Phase 3 with explicit gating: zero open CRITICALs in issues.json; cold-start `dart run custom_lint` must pass on a clean `.dart_tool/` before commit |
| T-03-01-04 | DoS | CI grinds on a stale-cache regression after flip | mitigate | RESEARCH.md Pitfall 6 — Task 4 mandates `rm -rf .dart_tool && flutter pub get && dart run custom_lint` cold-start before flip lands |
| T-03-01-05 | Information Disclosure | None — no secrets in this plan's surfaces | accept | YAML files contain only architectural rules; the arch test reads files via stdlib I/O |

**Security block on:** HIGH (per security_threat_model_gate). All threats above are MITIGATED.
</threat_model>

<verification>
**Per-plan exit gates** (each MUST exit 0 before merge):
1. `! grep -l "^allow:" lib/features/*/domain/import_guard.yaml` (zero parent-allow blocks remain)
2. `rm -rf .dart_tool && flutter pub get && dart run custom_lint` (cold-start clean)
3. `flutter test test/architecture/domain_import_rules_test.dart` (arch test green)
4. `flutter analyze --no-fatal-infos` (analyzer clean)
5. `flutter test` (full suite green)
6. `jq '[.findings[] | select(.severity=="CRITICAL" and .status=="open" and (.id | startswith("LV-")))] | length' .planning/audit/issues.json` returns `5` (only LV-017..021 + LV-022 remain open — Plans 03-03/03-04 close them)
7. **Phase-close gate (Task 4 only):** `jq '[.findings[] | select(.severity=="CRITICAL" and .status=="open")] | length' .planning/audit/issues.json` returns `0`

**Coverage gate:** This plan modifies only `.yaml`, `.dart` test file, `.yml` CI config, and `pubspec.yaml`. No `lib/` production source is touched. Coverage_gate.dart runs against an empty touched-source list → trivial pass.
</verification>

<success_criteria>
- 6 feature-level domain yamls are deny-only (parent `allow:` block stripped)
- ~8 per-subdirectory yamls (3 `models/` + 5 `repositories/`) declare allow leaves with intra-domain composition
- `test/architecture/domain_import_rules_test.dart` exists and is GREEN
- `dart run custom_lint` exits 0 from cold start
- 19 LV findings (LV-001..016, LV-023, LV-024) closed in `issues.json`
- `.github/workflows/audit.yml` flips `import_guard` to blocking ONLY after all other Phase 3 plans complete (Task 4 gates on zero open CRITICALs)
- All commits land under the operational repo lock (D-16) — only Phase 3 plan PRs merge to main
</success_criteria>

<output>
After completion, create `.planning/phases/03-critical-fixes/03-01-SUMMARY.md` summarizing yaml diffs, the arch test contract, the 19 LV closures, and the audit.yml flip commit hash.

Generate `doc/worklog/YYYYMMDD_HHMM_phase3_plan01_domain_import_guard_rules.md` per `.claude/rules/worklog.md`.
</output>
