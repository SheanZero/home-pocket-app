---
phase: 58-flutter-analyzer-code-generation-lane
verified: 2026-08-08T11:18:47Z
status: gaps_found
score: 6/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/7
  gaps_closed:
    - "Direct qualified widgets.runApp(...) is now rejected by the provider-contract guard."
    - "The normal-concurrency coverage invocation completed and left no Phase-58 sentinel in lib/."
  gaps_remaining:
    - "Riverpod root protection is still incomplete because valid runApp.call syntax bypasses the owned guard."
  regressions:
    - "A genuine qualified Riverpod root is falsely rejected when an unrelated class member uses the import-prefix name."
    - "A lock-open failure can permanently block subsequent in-process guard transactions."
gaps:
  - truth: "Deliberately invalid imports and Riverpod roots still fail the active import_lint/Riverpod lint and repository-owned architecture guards after the analyzer decision."
    status: failed
    reason: "The provider contract only recognizes runApp immediately followed by '('. Dart's valid direct-function invocation runApp.call(...) is ignored, so an unscoped root passes the owned guard."
    artifacts:
      - path: "scripts/audit/provider_contract.dart"
        issue: "_findCalls at lines 591-617 excludes runApp.call(...), including the verified widgets.runApp.call(...) form."
      - path: "test/architecture/provider_contract_test.dart"
        issue: "No unscoped or scoped .call fixture exercises this syntax."
      - path: "test/architecture/tooling_guard_negative_fixture_test.dart"
        issue: "The live child-process harness has no .call negative fixture."
    missing:
      - "Recognize direct-function .call(...) for unqualified and verified Flutter-prefix runApp references without accepting arbitrary member chains."
      - "Add parser and live tooling-harness negative/control fixtures for unqualified and qualified .call roots."
  - truth: "A genuine qualified Riverpod root remains accepted when an unrelated sibling or later lexical scope declares the same alias, while a declaration that encloses the call remains a shadow and fails closed."
    status: failed
    reason: "The scope scanner does not classify class/mixin/extension bodies as non-library scopes. A class member named riverpod therefore becomes a library-wide shadow and rejects an unrelated top-level riverpod.ProviderScope root."
    artifacts:
      - path: "scripts/audit/provider_contract.dart"
        issue: "_isScopeBrace (lines 381-389) omits type bodies; _isAtLibraryScope then treats members as library-wide."
      - path: "test/architecture/provider_contract_test.dart"
        issue: "No control covers an unrelated class member, post-if binding, or later switch case."
    missing:
      - "Make lexical shadow ranges respect type/member, if-case, and switch-case boundaries."
      - "Add passing controls for unrelated class members and branch/case-local bindings, while retaining enclosing-shadow negatives."
  - truth: "Concurrent negative-tooling tests serialize every production-tree fixture mutation and recover safely from success or failure."
    status: failed
    reason: "withToolingGuardFixtureLock opens .dart_tool/phase58_tooling_guard.lock before its try/finally and never ensures the parent directory. If open fails, releaseQueue is never completed and all later same-process callers wait forever."
    artifacts:
      - path: "scripts/verify_tooling_guards.dart"
        issue: "Lines 21-28 queue callers before lock.open; a FileSystemException bypasses lines 29-38, poisoning the shared queue."
      - path: "test/architecture/tooling_guard_negative_fixture_test.dart"
        issue: "No missing-.dart_tool or injected-open-failure recovery test proves a later invocation remains usable."
    missing:
      - "Create the lock parent and put lock open/lock/unlock/close plus queue release in an outer finally."
      - "Add a failure-then-second-invocation regression test."
---

# Phase 58: Flutter, Analyzer & Code Generation Lane Verification Report

**Phase Goal:** The project uses a single production-stable Flutter/Dart and code-generation compatibility graph without losing Clean Architecture or lint protection.
**Verified:** 2026-08-08T11:18:47Z
**Status:** gaps_found
**Re-verification:** Yes — after gap-closure Plan 58-06

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Developers and CI use the declared Flutter 3.44.8 / Dart 3.12.2 identity. | ✓ VERIFIED | `flutter --version` reported Flutter 3.44.8 Stable / Dart 3.12.2; `pubspec.yaml`, the baseline validator, and all three Stable CI jobs use the same identity. |
| 2 | Invalid imports and unscoped Riverpod roots are rejected by active independent protections. | ✗ FAILED | An isolated repository-shaped probe containing `runApp.call(const Placeholder())` printed `PASS owned provider contract` and exited 0. `_findCalls` accepts only `runApp(`. |
| 3 | Riverpod, Freezed, JSON, Drift, build_runner, analyzer, and lints resolve as one exact compatible no-override graph. | ✓ VERIFIED | Live `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` passed; lock resolves analyzer 12.1.0, analyzer_plugin 0.14.8, import_lint 2.0.0, riverpod_lint 3.1.4, Drift 2.34.0, and no `dependency_overrides` exists. |
| 4 | A clean locked resolution plus two generation passes leave no unexpected tracked generated output before quality gates. | ✓ VERIFIED | The authoritative wrapper executed locked retrieval and both generation passes; afterwards `git status --short` and `git diff --check` were clean. Its source guards the generation scope after each pass before analyzer/lint/test gates. |
| 5 | Stable CI invokes one authoritative wrapper with no pre-generation generator/lint/architecture duplicate. | ✓ VERIFIED | `.github/workflows/audit.yml` calls `bash scripts/verify_codegen_reproducibility.sh` once in `static-analysis`; the wrapper owns lock retrieval, two generation passes, analyzer, import_lint, architecture tests, and the tooling harness. |
| 6 | Default-concurrency full coverage retains the selected graph and 70% filtered gate without fixture residue. | ✓ VERIFIED | One `flutter test --coverage` invocation completed; the post-run `coverde filter` and `coverage_gate.dart` reported 15 checked / 0 below threshold / 0 missing, and no `lib/phase58_*fixture.dart` remained. Console capture was truncated before its final summary, so this is based on process completion and the successful downstream gate rather than SUMMARY.md. |
| 7 | The phase remains in the Dart/analyzer/codegen boundary and does not claim D-10 native/plugin/device proof. | ✓ VERIFIED | Phase-58 commits and artifacts are Pub/configuration, tooling, tests, CI, and documentation only. No native/plugin/device acceptance is asserted. |
| 8 | Qualified Riverpod controls are accepted outside an actually enclosing lexical shadow. | ✗ FAILED | An isolated control with a top-level `riverpod.ProviderScope` root and an unrelated `Helper.riverpod()` member emitted `missing_provider_scope`; that member is incorrectly treated as library-wide. |
| 9 | The fixture lock releases future calls even if setup fails. | ✗ FAILED | Source inspection proves `lock.open()` occurs after queue ownership but before the only `finally`; a missing `.dart_tool` or open failure never completes `releaseQueue`. |

**Score:** 6/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `pubspec.yaml` / `pubspec.lock` | Exact no-override compatibility cohort | ✓ VERIFIED | Live validator passed against actual lock and running Flutter SDK. |
| `analysis_options.yaml` | Active `riverpod_lint` and error-level `import_lint` | ✓ VERIFIED | Both plugins are configured at 3.1.4 and 2.0.0; import-lint severity is `error`. |
| `scripts/dependency_compatibility.dart` | Fail-closed graph/identity validation | ✓ VERIFIED | Consumes live manifest, lock, baseline and SDK identity; baseline mode passed. |
| `scripts/verify_codegen_reproducibility.sh` | Locked two-pass generation followed by quality gates | ✓ VERIFIED | Substantive, invoked by CI, and source order is lock → two generation/diff checks → analyzer/import-lint/architecture/tooling gates. |
| `scripts/audit/provider_contract.dart` | Repository-owned Riverpod root guard | ✗ PARTIAL | Direct and qualified `runApp(...)` are wired, but `.call()` bypasses detection and lexical scope analysis creates false positives. |
| `scripts/verify_tooling_guards.dart` | Reversible, concurrency-safe negative fixtures | ✗ PARTIAL | Normal fixture transaction is wired; lock-open failure leaves the in-process queue poisoned. |
| `test/architecture/provider_contract_test.dart` / `tooling_guard_negative_fixture_test.dart` | Parser and live negative regressions | ✗ PARTIAL | Existing focused tests pass but omit `.call()`, class/member, branch/case, and lock-open-recovery cases. |
| `.github/workflows/audit.yml` | One Stable wrapper plus locked coverage retrieval | ✓ VERIFIED | Static analysis owns one wrapper; guardrails and coverage each run `flutter pub get --enforce-lockfile`. |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | Current Stable CI contract | ✓ VERIFIED | Present and scoped to wrapper/lock compatibility guidance. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `pubspec.yaml` | `pubspec.lock` | `flutter pub get --enforce-lockfile` | ✓ WIRED | Wrapper and independent Stable test jobs enforce the committed graph. |
| baseline manifest | `dependency_compatibility.dart` | exact baseline/lock/SDK checks | ✓ WIRED | Live baseline validation passed. |
| `.github/workflows/audit.yml` | `verify_codegen_reproducibility.sh` | single static-analysis Bash invocation | ✓ WIRED | Direct source inspection confirms the sole authoritative route. |
| wrapper | generation, analyzer, import_lint, architecture tests, tooling harness | ordered script commands | ✓ WIRED | Commands occur in the intended order and execute real tools. |
| tooling harness | provider contract | real child `dart run scripts/audit/provider_contract.dart` | ⚠️ PARTIAL | Connection exists, but it cannot detect `.call()` roots. |
| fixture lock | all `lib/phase58_*fixture.dart` sentinels | lock/open/action/finally lifecycle | ✗ PARTIAL | Normal path cleans; setup-failure path does not release the queue. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `dependency_compatibility.dart` | SDK, baseline, pubspec and lock cohort | current Flutter SDK and committed inputs | Yes | ✓ FLOWING |
| codegen wrapper | generated/localization scope | real `gen-l10n`, build_runner, and Git diff checks | Yes | ✓ FLOWING |
| provider contract | tokenized Dart source and import prefixes | actual `lib/**/*.dart` files | Partially | ✗ HOLLOW ON VALID `.call()` SYNTAX |
| tooling guards | live temporary fixture diagnostics | real child tools and production-tree sentinels | Partially | ✗ ERROR-RECOVERY GAP |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Selected Flutter/Dart graph is executable and locked | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | PASS: exact cohort and Flutter 3.44.8/Dart 3.12.2 | ✓ PASS |
| Unscoped direct-function app root is rejected | isolated `dart scripts/audit/provider_contract.dart` probe with `runApp.call(...)` | Exit 0, `PASS owned provider contract` | ✗ FAIL |
| Unrelated class member does not shadow a qualified Riverpod import | isolated provider-contract control | Exit 1 with `missing_provider_scope` | ✗ FAIL |
| Full default-concurrency test/coverage lane and per-file threshold | `flutter test --coverage`; `coverde filter`; `coverage_gate.dart` | Test process completed; post gate: 15 checked, 0 below threshold, 0 missing; no fixture residue | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GEN-01 | 58-02, 58-04, 58-05, 58-06 | One Flutter/Dart identity for developers and CI | ✓ SATISFIED | Live SDK, baseline validator, and all Stable jobs agree on Flutter 3.44.8/Dart 3.12.2. |
| GEN-02 | 58-01, 58-02, 58-04, 58-05, 58-06 | Analyzer/import/Riverpod protections remain active with negative proof | ✗ BLOCKED | `.call()` bypasses the repository-owned provider guard; lexical shadow logic rejects a valid qualified control; failure-recovery lacks a regression. |
| GEN-03 | 58-02, 58-04, 58-05, 58-06 | One exact compatible no-override graph | ✓ SATISFIED | Validator passed, lock-selected cohort is exact, active lint config remains enabled, and every Stable Flutter job locks dependency retrieval. |
| GEN-04 | 58-03, 58-04, 58-05, 58-06 | Clean locked resolution and deterministic generation without generated residue | ✓ SATISFIED | Two-pass wrapper checks, completed coverage run, post-run coverage gate, and clean fixture/generated state verify the required lane. |

All requirement IDs declared by Phase-58 plans are accounted for. No orphaned Phase-58 requirement was found in `REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line / Area | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/audit/provider_contract.dart` | `_findCalls`, lines 591-617 | Only direct parenthesized calls are recognized | 🛑 Blocker | A valid unscoped `.call()` root silently bypasses provider protection. |
| `scripts/audit/provider_contract.dart` | `_isScopeBrace` / `_isAtLibraryScope`, lines 353-389 | Type-member declarations treated as library-wide shadows | 🛑 Blocker | Valid qualified Riverpod roots can be rejected. |
| `scripts/verify_tooling_guards.dart` | `withToolingGuardFixtureLock`, lines 21-38 | Queue acquired before fallible lock open outside `finally` | 🛑 Blocker | One setup failure can hang all later guard transactions in the process. |

No unresolved `TBD`, `FIXME`, or `XXX` debt markers were found in the Phase-58 implementation artifacts.

### Prohibition Review

The Plan 58-06 prohibition entries are flagged `unverified` and have no wired test-tier enforcement. Static inspection found no Phase-58 native/plugin/device scope expansion and no deliberate lint/lock weakening, but these remain non-authoritative judgment checks. Human review is recommended before a green closure, especially that fixes do not weaken the existing import, provider, lockfile, or SQLCipher/local-first safeguards.

### Gaps Summary

The production-stable dependency lane itself is coherent: the selected Flutter/Dart identity, exact solver graph, lint configuration, wrapper routing, lock-enforced CI retrieval, generation checks, and coverage threshold all have codebase evidence. The phase goal is nevertheless not achieved because its critical Clean Architecture/Riverpod enforcement is not sound: it misses a valid unscoped root form and rejects a valid scoped root in an unrelated lexical context. In addition, the fixture lock’s setup-failure path can permanently block subsequent tooling checks. These are BLOCKER gaps for GEN-02 and the Phase-58 negative-proof contract.

---

_Verified: 2026-08-08T11:18:47Z_
_Verifier: the agent (gsd-verifier)_
