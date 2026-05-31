---
phase: 30-i18n-empty-states-golden-polish
plan: "05"
subsystem: ci-gate
tags: [ci, analyze, custom_lint, coverage, golden, arb, phase-close, domain-purity]
dependency_graph:
  requires: ["30-01", "30-02", "30-03", "30-04"]
  provides:
    - "Documented CI green-gate evidence for Phase 30 close (D-10/D-11)"
  affects: []
tech_stack:
  added: []
  patterns:
    - "CI-equivalent coverage measured on generated-stripped lcov (matches audit.yml coverde filter)"
    - "Pre-existing failure triage: prove at phase base (aa1b028b) before attributing to phase"
key_files:
  created: []
  modified:
    - lib/features/analytics/domain/models/import_guard.yaml
    - lib/features/analytics/domain/repositories/import_guard.yaml
    - lib/features/accounting/domain/models/import_guard.yaml
    - lib/features/accounting/domain/repositories/import_guard.yaml
    - lib/features/accounting/domain/models/transaction_details_form_config.dart
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/features/accounting/presentation/screens/voice_input_screen.dart
    - test/architecture/domain_import_rules_test.dart
    - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
    - test/widget/features/list/list_sort_filter_bar_member_test.dart
    - test/golden/goldens/home_hero_card_*_ja.png (7 regenerated)
decisions:
  - "D-10 satisfied: coverage 79.45% (CI-cleaned lcov, ≥70% threshold)"
  - "D-11 satisfied: analyze 0 (lib+test), custom_lint 0, build_runner clean diff, full suite green"
  - "Human-verify checkpoint resolved as test-backed (user elected to trust passing golden + widget tests over manual app run)"
  - "User elected fix-all-now for pre-existing repo issues uncovered by the gate"
metrics:
  duration: "~75 minutes (gate + fix-all scope)"
  completed: "2026-05-31"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 11
---

# Plan 30-05 — CI Green Gate + Phase Close

## Objective

Run the full CI gate and confirm all Phase 30 quality criteria (LIST-03, D-01–D-13, D-10/D-11) are satisfied before phase close. Validation-only plan — no new feature code.

## Task 1 — CI Gate Results (final, HEAD 89b277fc)

| Check | Result |
|-------|--------|
| `flutter analyze --no-fatal-infos` (lib + test) | ✅ exit 0 |
| `dart run custom_lint --no-fatal-infos` | ✅ 0 issues |
| `build_runner build` + `git diff --exit-code` | ✅ clean |
| `flutter test` (full suite) | ✅ **2239 passed, 0 failed** |
| Coverage (CI-cleaned lcov, generated stripped) | ✅ **79.45%** ≥ 70% (D-10) |
| Per-file coverage gate (`coverage_gate.dart`) | ✅ 64 checked, 0 failed |
| 6 list golden files (24 baselines) | ✅ pass |
| `arb_key_parity_test` (3-locale parity) | ✅ pass |
| `domain_import_rules_test` (arch) | ✅ pass |

Note on local analyze: `flutter analyze` over the full tree returns exit 1 only because of a `build/ios/SourcePackages/firebase_messaging/.../example` artifact warning. `build/` is gitignored and absent in CI's fresh checkout; `flutter analyze lib test` (CI-equivalent scope) is exit 0. Two `onReorder` deprecation INFOs remain in `category_selection_screen.dart` (accounting, pre-existing, non-fatal under `--no-fatal-infos`).

## Task 2 — Human-Verify Checkpoint

The blocking `checkpoint:human-verify` (6 manual List-tab behaviors) was resolved per user decision as **test-backed**: the 3-state empty-state variants, their copy/actions, and the `自分のみ` (D-07) chip are all asserted by passing golden + widget tests (`list_empty_state_golden_test`, `list_empty_state_test`, `list_sort_filter_bar_member_test`). No manual device run was performed.

## Fix-All Scope (user-authorized)

The gate surfaced **pre-existing** repo issues outside LIST-03. All were proven pre-existing at the phase base `aa1b028b`, then fixed per the user's "fix all now" decision:

1. **home_hero_card goldens (7)** — baselines predated the 2026-05-22 ring-polish/layer-swap widget changes (64168f81 / c54e06fc). Regenerated.
2. **home_hero_card_test (4)** — same root cause: the target reference moved from visible Text to a Semantics label (`homeJoyTargetSemantics`). Test assertions updated to `find.bySemanticsLabel(RegExp('目標 50'))`.
3. **custom_lint import_guard (13→0)** — stale per-directory whitelists. 12 were legitimate intra-/cross-domain imports added to the allowlists. The 13th was a real **domain-purity violation**: `TransactionDetailsFormConfig` (domain) imported `package:flutter/widgets` for `FocusNode`/`VoidCallback`. **Refactored** those off the domain config onto the `TransactionDetailsForm` widget (presentation); consumers updated; 66 form/screen tests green.
4. **domain_import_rules_test (arch) ↔ custom_lint contradiction** — the arch test restricted repo allowlists to `../models/*.dart`, conflicting with two legitimate cross-boundary domain imports (`shared/constants/sort_config`, cross-feature `entry_source`). Per user decision, **relaxed the arch test** to also accept `shared/constants/*.dart` and cross-feature `domain/models/*.dart`.
5. **list_sort_filter_bar_member_test (2)** — Phase 30 test-update gap (LIST-03/D-07): the ja-locale test asserted the old English placeholder `Mine only`; 30-01 fixed ja `listMineOnly` → `自分のみ`. Updated 4 assertions. (Passed in the full suite only via a locale-leak from a prior test; failed in isolation even at the phase base — now isolation-robust.)

## Verification

```
flutter test                          → 2239 passed, 0 failed
coverage (cleaned)                    → 79.45% (≥70%)
dart run custom_lint --no-fatal-infos → 0 issues
flutter analyze lib test              → exit 0
build_runner + git diff --exit-code   → clean
```

## Follow-ups

- The two `onReorder` deprecation INFOs in `category_selection_screen.dart` remain (non-fatal, accounting, out of scope) — candidate for a future lint-cleanup task.
- Cross-feature domain coupling (`analytics_repository → accounting EntrySource`) is now permitted by the relaxed arch rule; if a stricter domain-isolation policy is desired later, extract a shared domain vocabulary.

Phase 30 is ready for `/gsd-verify-work`.
