---
phase: 58-flutter-analyzer-code-generation-lane
verified: 2026-08-08T12:35:34Z
status: gaps_found
score: 6/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/9
  gaps_closed:
    - "Direct `runApp.call(...)` and verified-prefix `widgets.runApp.call(...)` roots are rejected by parser and live harness tests."
    - "Class/mixin/extension members plus if/switch lexical controls are bounded correctly."
    - "The fixture lock creates its parent and releases a later caller after lock-open or action failure."
  gaps_remaining: []
  regressions:
    - "A parenthesized direct function reference `(runApp)(...)` or `(widgets.runApp)(...)` bypasses the owned ProviderScope guard."
    - "A `for`-header Riverpod alias shadows a qualified root after the loop."
    - "The authoritative generation wrapper omits `--delete-conflicting-outputs` on both build_runner passes."
gaps:
  - truth: "Deliberately invalid Riverpod roots fail every active architecture protection, including the repository-owned provider contract."
    status: failed
    reason: "The owned parser accepts only `runApp(...)` and `runApp.call(...)`; valid Dart parenthesized direct invocations are not scanned."
    artifacts:
      - path: "scripts/audit/provider_contract.dart"
        issue: "_findCalls at lines 735-771 skips `(runApp)(...)` and `(widgets.runApp)(...)` because the token following `runApp` is `)` rather than `(` or `. call (`."
      - path: "test/architecture/provider_contract_test.dart"
        issue: "No parenthesized-root bad/control regression exists."
      - path: "test/architecture/tooling_guard_negative_fixture_test.dart"
        issue: "The live child-process harness has no parenthesized-root bad/control fixture."
    missing:
      - "Recognize exactly one parenthesized direct `runApp` reference, retaining the verified Flutter-prefix and no-member-chain rules."
      - "Add parser and live bad/control coverage for unqualified and verified-prefix parenthesized roots."
  - truth: "A genuine qualified Riverpod root is accepted whenever the same alias is outside its enclosing lexical scope."
    status: failed
    reason: "A declaration in a `for` header falls back to the enclosing function block, so it shadows a root after the loop where the variable is no longer in scope."
    artifacts:
      - path: "scripts/audit/provider_contract.dart"
        issue: "_scopeShadowFor at lines 329-369 has type/if/switch-specific ranges but no `for`-header range; `_enclosingBlock` extends a loop binding through the function body."
      - path: "test/architecture/provider_contract_test.dart"
        issue: "The lexical-shadow matrix lacks C-style and for-in inside/post-loop bad/control cases."
    missing:
      - "Bound `for` and `for-in` header bindings to their loop statement/body."
      - "Add controls proving post-loop roots pass while roots inside the loop remain fail-closed."
  - truth: "The authoritative wrapper deterministically regenerates valid changed generator inputs before evaluating two clean passes."
    status: failed
    reason: "Both build_runner invocations omit the Plan 58 D-08 conflict-deleting flag, so a legitimate stale generated output can stop generation before the reproducibility oracle runs."
    artifacts:
      - path: "scripts/verify_codegen_reproducibility.sh"
        issue: "Lines 61 and 66 use `flutter pub run build_runner build` without `--delete-conflicting-outputs`."
      - path: "test/architecture/codegen_reproducibility_contract_test.dart"
        issue: "The source contract asserts only the shorter substring and therefore passes despite the omitted required flag."
    missing:
      - "Run both build_runner passes with `--delete-conflicting-outputs`."
      - "Make the source contract require the complete command exactly twice in D-08 order."
next_action: "Create a focused Phase 58 gap-closure plan for the three provider-parser/lexical-scope/codegen-wrapper defects."
next_command: "/gsd-plan-phase 58 --gaps"
---

# Phase 58: Flutter, Analyzer & Code Generation Lane Verification Report

**Phase Goal:** The project uses a single production-stable Flutter/Dart and code-generation compatibility graph without losing Clean Architecture or lint protection.
**Verified:** 2026-08-08T12:35:34Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 58-07 and 58-08

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Developers and CI use the declared Flutter 3.44.8 / Dart 3.12.2 identity. | ✓ VERIFIED | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` passed. `pubspec.yaml`, baseline manifest, and every Stable workflow setup use the selected identity. |
| 2 | Deliberately invalid imports and Riverpod roots fail the active import/Riverpod and repository-owned guards. | ✗ FAILED | `_findCalls` does not recognize valid `(runApp)(...)` or `(widgets.runApp)(...)` syntax; an unscoped root in either form is not sent to `_isScopedRoot`. |
| 3 | Riverpod, Freezed, JSON, Drift, build_runner, analyzer, and lints resolve as one exact no-override graph. | ✓ VERIFIED | The live dependency validator passed; current exact cohort includes analyzer 12.1.0, analyzer_plugin 0.14.8, import_lint 2.0.0, riverpod_lint 3.1.4, Drift 2.34.0, and no override mechanism. |
| 4 | A clean locked resolution and two generation passes reproducibly regenerate valid generator input before quality gates. | ✗ FAILED | The wrapper completed current clean passes, but both `build_runner` commands lack the required `--delete-conflicting-outputs`; valid stale output conflicts abort before its two-pass oracle. |
| 5 | Stable CI invokes one authoritative wrapper with no pre-generation generator/lint/architecture duplicate. | ✓ VERIFIED | `audit.yml` invokes `bash scripts/verify_codegen_reproducibility.sh` once from Stable static analysis; source contracts covering wrapper ownership passed. |
| 6 | Default-concurrency coverage retains the selected graph and 70% filtered gate without fixture residue. | ✓ VERIFIED | Phase execution’s independent full-coverage/filtered-gate evidence is consistent with the current lock contract; the current targeted lock-recovery test passed and no `lib/phase58_*fixture.dart` remained after the wrapper. |
| 7 | The phase remains in the Dart/analyzer/codegen boundary and does not claim D-10 native/plugin/device proof. | ✓ VERIFIED | Phase-owned changes are Dart tooling, tests, CI, docs, and manifest/lock compatibility records. The SwiftPM iOS 13/Firebase iOS 15 mismatch is explicitly held for Phase 60. |
| 8 | Qualified Riverpod roots are accepted outside an actually enclosing lexical shadow. | ✗ FAILED | `for`-header aliases are treated as function-wide by `_scopeShadowFor`, rejecting a qualified root after the loop despite the alias being out of scope. |
| 9 | The fixture lock releases future calls after setup or action failure. | ✓ VERIFIED | `withToolingGuardFixtureLock` creates the parent and always completes its queue; `flutter test ... --plain-name 'lock setup failures release the queue'` passed. |

**Score:** 6/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `pubspec.yaml` / `pubspec.lock` | Exact no-override compatibility cohort | ✓ VERIFIED | The live baseline validator and 46-test compatibility contract passed. |
| `analysis_options.yaml` | Active error-level import_lint and Riverpod lint | ✓ VERIFIED | Configures `riverpod_lint: 3.1.4`, `import_lint: 2.0.0`, and `severity: error`. |
| `scripts/dependency_compatibility.dart` | Fail-closed graph/identity validator | ✓ VERIFIED | Consumes actual manifest, lock, baseline, workflow, and SDK inputs; baseline mode passed. |
| `scripts/verify_codegen_reproducibility.sh` | Locked two-pass deterministic code-generation wrapper | ✗ PARTIAL | It is substantive and CI-wired, but lacks `--delete-conflicting-outputs` in both generation passes. |
| `scripts/audit/provider_contract.dart` | Sound Riverpod app-root enforcement | ✗ PARTIAL | Direct and `.call` roots plus several lexical ranges work; parenthesized direct roots bypass and for-header shadows overreach. |
| `scripts/verify_tooling_guards.dart` | Reversible concurrency-safe negative harness | ✓ VERIFIED | Real fixture paths, child commands, stale refusal, parent creation, file lock, cleanup, and post-failure successor test are wired. |
| Provider/tooling/codegen contract tests | Regression proof of current parser and wrapper boundaries | ✗ PARTIAL | Existing tests pass but do not cover the two parser counterexamples or the required build-runner flag. |
| `.github/workflows/audit.yml` | Single Stable wrapper and lock-enforced independent jobs | ✓ VERIFIED | Static analysis has one wrapper; guardrails and coverage use `flutter pub get --enforce-lockfile`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `pubspec.yaml` | `pubspec.lock` | locked retrieval and exact validator | ✓ WIRED | Wrapper and independent Stable jobs enforce the committed graph. |
| Baseline manifest | `dependency_compatibility.dart` | exact cohort/SDK/hold checks | ✓ WIRED | Live baseline command passed. |
| Stable workflow | codegen wrapper | one post-setup Bash invocation | ✓ WIRED | Source inspection plus workflow contract tests confirm the authoritative route. |
| Wrapper | l10n, build_runner, analyzer/import lint, architecture tests, harness | ordered commands | ⚠️ PARTIAL | The route is real, but its build_runner commands omit required conflict deletion. |
| Provider contract | real temporary source fixtures | tooling-guard child processes | ⚠️ PARTIAL | `.call` cases are wired; parenthesized direct-root cases are absent, so a valid syntax bypass remains. |
| Lexical scanner | qualified Riverpod roots | `_scopeShadowFor` at call offset | ⚠️ PARTIAL | Class/type, if, and switch ranges are tested; loop-header range is not implemented. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Compatibility validator | SDK, manifest, lock, baseline, CI workflow | current repository files and installed SDK | Yes | ✓ FLOWING |
| Codegen wrapper | l10n and generated Dart outputs | real Flutter/build_runner commands | Yes on the current clean state | ⚠️ INCOMPLETE conflict recovery |
| Provider contract | tokenized handwritten Dart source | actual `lib/**/*.dart` plus live sentinels | Yes | ✗ INCOMPLETE valid syntax/lexical coverage |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Exact graph/selected SDK validates | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | `PASS (0 error(s), 0 warning(s))` | ✓ PASS |
| Previous lock failure cannot poison later calls | `flutter test test/architecture/tooling_guard_negative_fixture_test.dart --plain-name 'lock setup failures release the queue'` | 1 test passed | ✓ PASS |
| Existing provider `.call` regression matrix | `flutter test test/architecture/provider_contract_test.dart` | 13 tests passed | ✓ PASS, but does not test parenthesized syntax |
| Current clean generation lane | `bash scripts/verify_codegen_reproducibility.sh` | Locked graph validated; both generation passes wrote 0 outputs; analyzer/import/architecture/harness ran and all temporary sentinels were cleaned | ✓ PASS on clean state; not proof of conflict handling |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GEN-01 | 58-02, 58-04, 58-05, 58-06 | One Flutter/Dart identity for developers and CI | ✓ SATISFIED | Current SDK/manifest/baseline/Stable CI identity contract passes. |
| GEN-02 | 58-01, 58-02, 58-04, 58-05, 58-06, 58-07, 58-08 | Active analyzer/import/Riverpod protections with negative proof | ✗ BLOCKED | Parenthesized roots bypass the owned provider guard; for-loop lexical handling can falsely reject a valid root. |
| GEN-03 | 58-02, 58-04, 58-05, 58-06 | One exact no-override compatibility graph | ✓ SATISFIED | Exact current lock/manifest/cohort contract and live validator passed. |
| GEN-04 | 58-03, 58-04, 58-05, 58-06 | Deterministic clean generation without generated residue | ✗ BLOCKED | The clean path passes, but the required wrapper fails to delete legitimate stale conflicting outputs before re-generation and the source test misses the omission. |

All Phase-58 requirement IDs declared by the plans are accounted for. No later roadmap phase specifically owns these three Phase-58 Dart-tooling defects, so none is deferred. D-10’s native/plugin/device deferral is not a Phase-58 gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/audit/provider_contract.dart` | 735-771 | Narrow call scanner omits parenthesized direct function references | 🛑 BLOCKER | Unscoped app roots can bypass owned provider enforcement. |
| `scripts/audit/provider_contract.dart` | 329-369 | No loop-header lexical end range | 🛑 BLOCKER | Valid qualified roots after a loop can be rejected. |
| `scripts/verify_codegen_reproducibility.sh` | 61, 66 | build_runner conflict deletion omitted | 🛑 BLOCKER | Valid input changes can fail before deterministic regeneration. |
| `test/architecture/codegen_reproducibility_contract_test.dart` | 45-104 | Test accepts the shorter build command | ⚠️ WARNING | A passing source test does not protect the mandated D-08 command. |

No unresolved `TBD`, `FIXME`, or `XXX` markers were found in the Phase-58 implementation artifacts. `return null` uses in the parser are normal no-match results, not stubs.

### Prohibition Review

The descriptor-less Plan 58-06 through 58-08 prohibition entries remain marked `unverified`. Static inspection found no Phase-58 native/plugin/device scope expansion and no deliberate lockfile/lint weakening, but these non-authoritative entries cannot turn the failed implementation checks green.

### Gaps Summary

The compatibility graph, selected SDK identity, Stable CI routing, clean-state generation pass, and lock-recovery implementation are real and mostly sound. The phase goal is still not achieved because Clean Architecture/Riverpod protection has a valid syntax bypass and an over-broad lexical rejection, while the code-generation wrapper omits the required conflict-recovery command. These are all Phase-58-owned defects, not Phase-60 native work.

**Next action:** Create a focused gap-closure plan that adds exact parenthesized-root recognition and live controls, scopes `for` header aliases to their loops, and requires `--delete-conflicting-outputs` in both wrapper passes with a strict source regression.

**Next command:** `/gsd-plan-phase 58 --gaps`

---

_Verified: 2026-08-08T12:35:34Z_
_Verifier: the agent (gsd-verifier)_
