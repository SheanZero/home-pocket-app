---
phase: 57-stable-baseline-compatibility-contract
verified: 2026-08-05T15:47:48Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "Every intentional hold has official evidence, a compatibility reason, and an exit condition while iOS 15 and Android API 24 remain supported."
  gaps_remaining: []
  regressions: []
---

# Phase 57: Stable Baseline & Compatibility Contract Verification Report

**Phase Goal:** Maintainers have one auditable, official-source production-stable baseline that prevents unsafe or partial dependency upgrades before any compatibility lane changes.
**Verified:** 2026-08-05T15:47:48Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A reviewer can see query date, official source, current value, and production-stable candidate for every required SDK, native tool, and direct dependency. | ✓ VERIFIED | `STABLE_BASELINE.json` has eight required toolchain rows and 56 direct-dependency rows, with selected/resolved value, candidate, official source, query date, decision, and owner. |
| 2 | A clean checkout resolves the reviewed Dart, Flutter, native-project, and lockfile combination reproducibly. | ✓ VERIFIED | The prior independent enforced-lock retrieval left no tracked diff; the re-run live baseline command passed against Flutter 3.44.8/Dart 3.12.2 and effective Android API 24. Stable CI has the same lock retrieval and validation wiring. |
| 3 | The executable compatibility contract rejects beta/RC/dev, EOL SQLCipher packaging, unapproved overrides, and a partially upgraded dependency lane. | ✓ VERIFIED | The independent targeted contract suite passed 41 tests, including prerelease/EOL, override, plaintext SQLite, linker-strip, partial-lane, and future-probe boundary fixtures. |
| 4 | Every intentional hold has official evidence, compatibility reason, and exit condition while iOS 15 and Android API 24 remain supported. | ✓ VERIFIED | Commit `594d9a1c` completes all 4 toolchain and 16 direct-dependency `decision: hold` rows. Independent JSON checks found no blank evidence fields, and the validator now rejects incomplete direct-dependency and toolchain holds. iOS 15/API 24 remain verified by the live contract. |

**Score:** 4/4 roadmap truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docs/testing/STABLE_BASELINE.json` | Canonical dated decision, inventory, hold evidence, lanes, floors, prohibitions, and input digests | ✓ VERIFIED | Valid JSON with 4 toolchain and 16 direct-dependency holds; each now has non-empty `compatibility_reason` and `exit_condition`. |
| `scripts/dependency_compatibility.dart` | Fail-closed parser, report model, CLI modes, and repository validation | ✓ VERIFIED | `StableBaselineManifest.parse` requires both evidence fields whenever a toolchain or direct dependency has `decision: hold`; live baseline/future-probe execution passed. |
| `test/architecture/dependency_compatibility_contract_test.dart` | Positive fixture plus negative coverage of the contract | ✓ VERIFIED | 41 tests pass, including mutations that remove `flutter_riverpod`’s reason and blank Xcode’s exit condition. |
| `.github/workflows/audit.yml` | Stable, pinned, blocking compatibility execution | ✓ VERIFIED | Static analysis pins Flutter 3.44.8, uses enforced lock retrieval, and invokes running-SDK baseline validation before analysis. |
| `.github/workflows/flutter-future-compat.yml` | Explicit beta future probe | ✓ VERIFIED | Both beta jobs make one active future-probe call and retain real Android/iOS builds. |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | Human-readable, canonical-manifest-linked matrix | ✓ VERIFIED | Linked canonical matrix now includes the missing Xcode and Local Lucide icon-subset evidence chains. |
| `57-VALIDATION.md` | Six-task validation map | ✓ VERIFIED | The phase’s executable checks remain documented and the relevant current commands passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `STABLE_BASELINE.json` | validator | `StableBaselineManifest.parse(baselineJson)` | ✓ WIRED | CLI loads the committed manifest before evaluating repository inputs. |
| validator | Pub/native/CI/Xcode inputs | actual file reads plus SHA-256 comparison | ✓ WIRED | Live baseline command reads the ten tracked inputs and passed. |
| contract test | validator | in-process import and current-input fixtures | ✓ WIRED | Tests call the real validator and passed both new negative hold-evidence cases. |
| Stable CI | validator | enforced lock retrieval then `--mode=baseline --verify-running-flutter-sdk` | ✓ WIRED | Workflow source retains the ordered hard-failing commands. |
| Beta CI | validator | one `--mode=future-probe` call in each beta job | ✓ WIRED | Workflow source and contract tests confirm two active calls. |
| human matrix | canonical manifest | Markdown link to `STABLE_BASELINE.json` | ✓ WIRED | Documentation designates the JSON as the single source of truth. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `dependency_compatibility.dart` | baseline JSON, tracked inputs, running-SDK identity | committed files plus `flutter --version --machine` and resolved `FlutterExtension.kt` | Yes; both live modes returned 0 errors/0 warnings | ✓ FLOWING |
| compatibility contract test | `currentInputs()` | checked-in Pub/native/workflow files | Yes; in-memory copies are mutated to prove rejection paths | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Hold-evidence and fail-closed fixtures | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | 41 passed | ✓ PASS |
| Live Stable baseline | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | PASS, 0 errors/0 warnings | ✓ PASS |
| Live future probe | `dart run scripts/dependency_compatibility.dart --mode=future-probe --verify-running-flutter-sdk` | PASS, 0 errors/0 warnings | ✓ PASS |
| Static analysis | `flutter analyze` | No issues found | ✓ PASS |
| Whitespace | `git diff --check` | exited 0 | ✓ PASS |

The initial verification had already independently passed enforced lock retrieval, the iOS minimum-version contract (19/19), and the full `flutter test --concurrency=1` suite. Re-verification regression-checked the changed hold-evidence path and its consumers rather than re-running previously green unrelated tests.

### Probe Execution

Step 7c: SKIPPED — Phase 57 declares no `probe-*.sh` probe.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| BASE-01 | 57-01 | Dated official-source inventory for all required tools and direct dependencies | ✓ SATISFIED | Eight toolchains and 56 direct dependencies have source/date/current/candidate evidence. |
| BASE-02 | 57-01, 57-03 | Reproducible reviewed Pub/native/lockfile graph | ✓ SATISFIED | Enforced retrieval, input digests, live running-SDK verification, and Stable CI wiring are in place. |
| BASE-03 | 57-02, 57-03 | Synchronized docs/script/tests reject forbidden or partial lanes | ✓ SATISFIED | 41 tests and both live CLI modes pass; workflows consume the exact contract. |
| BASE-04 | 57-02, 57-03 | Evidence-backed holds; no prerelease/EOL/override/floor regression | ✓ SATISFIED | Every `decision: hold` now requires and supplies reason/exit evidence; new direct/toolchain negative tests pass while iOS 15/API 24 remain enforced. |

### Anti-Patterns Found

None in the Phase-57 implementation artifacts. No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or console-only stub marker was found.

### Gaps Summary

None. The only initial gap was closed by requiring evidence on every hold row and proving both direct-dependency and toolchain failure paths.

---

_Verified: 2026-08-05T15:47:48Z_
_Verifier: the agent (gsd-verifier)_
