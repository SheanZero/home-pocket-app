# Phase 62: Automated Release-Gate Lock - Research

**Researched:** 2026-08-10
**Domain:** Repository-owned Flutter release-gate orchestration, reproducibility evidence, and dual-emulator CI
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Canonical Gate Entrypoint
- **D-01:** Provide one version-controlled, repository-owned release-gate program as the sole authority for whether Phase 62 passes. Local execution and CI must call this same entrypoint; existing generation, release-preflight, coverage, and native-safety runners remain reusable lower-level capabilities rather than competing authorities.
- **D-02:** A formal candidate must be a clean, committed Git commit. Before execution, bind the evidence to the commit, `pubspec.lock`, and digests of the critical native/toolchain configuration. Source changes, lockfile changes, relevant untracked generated output, or unexplained tracked drift make the candidate ineligible.
- **D-03:** The authoritative execution is one macOS command on the current Apple Silicon host. It runs the required host, iOS Simulator, Android Emulator, and release-preflight gates as one orchestrated release-lock operation rather than exposing independently authoritative platform commands.
- **D-04:** Run directly in the current clean checkout, not a temporary clone. The program must perform strict pre-run cleanup/readiness checks and finish by proving there is no source, lockfile, configuration, or generated-output drift. It may create ignored/disposable build and evidence artifacts, but a dirty or mutated repository cannot pass.

#### Failure, Retry, and Recovery
- **D-05:** Use hybrid failure handling. Candidate identity, locked dependency resolution, generation cleanliness, static analysis, and other prerequisite contract failures stop the operation immediately. Once the independent test/platform stages begin, run enough independent gates to return a useful aggregate of failures rather than hiding every later issue behind the first platform failure.
- **D-06:** Automatically retry only an explicitly classified infrastructure failure, at most once. Eligible classes include deterministic simulator/emulator startup or readiness failures, device transport failure, dependency-download/network failure, and recognized test-runner/subprocess timeout. Assertions, compilation, signing/hygiene, security/privacy contracts, coverage shortfall, candidate drift, and other product/repository failures are never auto-retried. Preserve the first result and the retry evidence in non-repository raw artifacts.
- **D-07:** If default-concurrency `flutter test` hits a recognized runner/subprocess timeout, first rerun the affected file(s) in isolation for diagnosis, then automatically run the complete suite with `flutter test --concurrency=1`. QA-02 passes only if that complete serial confirmation is green.
- **D-08:** Permit controlled resume only while commit, lockfile, relevant configuration digests, environment fingerprint, and repository cleanliness remain identical. Resume must revalidate candidate identity and all prerequisite invariants before restarting at the earliest invalidated gate. Any source, dependency, or configuration change invalidates every prior result and requires a complete new run.

#### Simulator and Emulator Acceptance
- **D-09:** Run the complete discovered `integration_test/` suite on both an iOS Simulator and the local API 36 `google_apis` arm64-v8a Android Emulator for the exact Phase 62 candidate. Phase 60/61 runtime evidence is historical input and cannot substitute for this candidate-bound rerun.
- **D-10:** Each formal platform run begins from erased application/test data, deterministic cold boot, disabled snapshot restoration, explicit readiness checks, and isolated synthetic data. Normal app containers, real Keychain/secure-storage values, user backups, production credentials, and physical devices are prohibited.
- **D-11:** Every merge to `main` must trigger the full dual-platform device gate. Pull requests retain the faster generation, analysis, host-test, coverage, and contract gates. Entry to Phase 63 requires a green Phase 62 result whose commit and candidate digests exactly match the Phase 63 candidate.
- **D-12:** Only skips in an explicit allowlist may be accepted. Each allowed skip requires a reason, owning phase, and exit condition; any new/unregistered skip, undiscovered test, unexecuted file, or unavailable required journey blocks the gate. The API 36 x86_64 GitHub/Intel lane remains independently testable supplemental evidence: absence or failure is recorded as a limitation and never as a pass, but it does not block the local arm64 primary acceptance or claim Android physical-device coverage.

#### Compatibility Report and Evidence
- **D-13:** Generate a machine-readable JSON result as the evidence authority and render a checked-in Markdown compatibility report from that JSON. Both outputs bind to the same candidate commit and lockfile/configuration digests. CI retains complete raw logs and large artifacts outside the repository.
- **D-14:** Keep the checked-in report centered on the final result rather than an attempt-by-attempt history. To satisfy QA-04, include a concise summary of actual Phase 62 failures encountered, the final fix for each, whether the candidate identity changed, and the complete rerun outcome. Do not check full failed-run logs into the repository.
- **D-15:** The runner may collect broad non-sensitive diagnostic environment data, but every persisted report and CI artifact must be scrubbed and pass a privacy scan. Known sensitive categories are excluded at collection time, not collected then sanitized: signing material, keys, tokens, credentials, UDID/serial values, usernames/home paths where identifying, financial fields, notes, backup contents, and sync payloads. Retained reproducibility data includes exact commands, UTC timestamps, commit and candidate digests, tool versions, host OS/architecture, redacted simulator/emulator profiles, result/exit classifications, version deltas, intentional holds, artifact hashes, fixes, and residual debt.
- **D-16:** The final verdict model is `PASS`, `PASS_WITH_LIMITATIONS`, or `BLOCKED`. `PASS` and `PASS_WITH_LIMITATIONS` both require every mandatory gate to be green; the latter is reserved for preclassified non-blocking limitations such as unavailable supplemental x86_64 evidence or explicitly accepted historical debt. A manual override may not convert a mandatory failure into either passing state.

### the agent's Discretion
- Choose the release-gate program's language, file names, internal module boundaries, command-line spelling, and exact ordering within the locked prerequisite/test/platform dependency graph.
- Choose the checkpoint schema and storage, infrastructure-failure classifier implementation, retry diagnostics, and earliest-invalidated-gate calculation while preserving D-05 through D-08.
- Choose the JSON schema, Markdown location/layout, raw artifact naming/retention, privacy scrubber implementation, candidate/config digest set, and expected-skip manifest format while preserving the required data and redaction boundaries.
- Choose exact Simulator/AVD names, boot/readiness tools, and cleanup commands. The observable contract is erased deterministic state, complete discovery/execution, redacted evidence, post-integration release hygiene, and no repository drift.
- Add or strengthen focused mutation/architecture tests for the orchestrator, CI invocation, verdict computation, resume invalidation, skip allowlist, report rendering, and privacy filtering. Do not weaken an existing gate or add an unjustified ignore to make the aggregate command pass.

### Deferred Ideas (OUT OF SCOPE)
- Additive signed wired-iPhone identity, installation, SQLCipher/backup/app-lock/accounting acceptance, and same-device performance evidence remain Phase 63.
- Android physical-device validation remains unavailable and out of scope; Phase 62 must state that it was not performed or claimed.
- App Store/Google Play submission, hosted legal/support/operator-value completion, and final legal review remain release-owner gates outside this technical phase.
- Raw sketches exist under `.planning/sketches/` but have no packaged findings skill and do not affect this non-UI release-gate phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| QA-01 | Final graph passes analysis, import/lint, architecture, privacy, dependency, and whitespace contracts with no unjustified ignore. | Reuse the locked two-pass wrapper; add the aggregate gate's candidate/drift and privacy-evidence contracts. [VERIFIED: scripts/verify_codegen_reproducibility.sh:53-77] |
| QA-02 | Target regressions, complete suite, coverage, and required serial confirmation pass. | Add classifier/retry and checkpoint tests; retain the current coverage command and its missing-LCOV failure behavior. [VERIFIED: scripts/coverage_gate.dart:245-273] |
| QA-03 | Clean preflight regenerates registrants, excludes development plugins, and CI shares the exact stable/lock/generation path. | Reuse release preflight; make CI invoke the single aggregate entrypoint rather than independently authoring equivalent commands. [VERIFIED: scripts/release_preflight.sh:333-365; .github/workflows/audit.yml:24-114] |
| QA-04 | Both emulated platforms pass before physical phone work and final evidence contains reproducibility/fix/debt data. | Reuse both safety lanes' clean-state machinery but replace their historical evidence binding with the Phase 62 candidate ledger, full recursive test discovery, skip allowlist, and privacy-filtered renderer. [VERIFIED: scripts/verify_android_safety_lane.dart:1149-1165,1243-1288,1406-1644; .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-38] |
</phase_requirements>

## Summary

Implement one Dart-based release-lock program under `scripts/` with a thin checked-in shell launcher only if the project needs a convenient macOS spelling. The runner should compose—not reimplement—the existing locked generation wrapper, coverage gate, release preflight, iOS safety runner, and Android safety runner. This matches the repository's existing runner style: both native safety lanes already use Dart process orchestration, status snapshots, SHA-256 provenance, bounded/redacted output, and machine-readable evidence. [VERIFIED: scripts/verify_ios_native_safety_lane.dart:89-170,813-851; scripts/verify_android_safety_lane.dart:1198-1239,1750-1790]

The new authority must first establish a candidate fingerprint, then run prerequisite checks fail-fast. After prerequisites pass, it can aggregate independent host, coverage, preflight, Simulator, and Emulator failures in one normalized result. The final verdict must be computed from mandatory-gate results plus an explicit, schema-validated limitations list; a supplemental x86_64 outcome can annotate a pass but can never turn a mandatory failure into a passing verdict. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-38]

Phase 61 explicitly left two items for this phase: its evidence was not bound to the current source tree, and the x86_64 CI job was still blocking by default. Treat the Phase 61 ledger as historical input only; do not simply wrap its `--mode=verify` result. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:103-112,129-150]

**Primary recommendation:** Build a fail-closed Dart release-lock orchestrator with a stable JSON schema, ignored raw artifacts/checkpoints, a separately tested Markdown renderer, and CI jobs that call it as their only Phase 62 pass authority. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:16-45]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Candidate identity, graph/config digests, and resume invalidation | Repository automation | Git | The authority owns repeatable checkout-state proof, while Git supplies the immutable commit identity. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-26] |
| Generation, static, architecture, dependency, and whitespace contract | Repository automation | Flutter/Dart tooling | The existing wrapper owns the ordered lower-level checks. [VERIFIED: scripts/verify_codegen_reproducibility.sh:53-77] |
| Host regressions and coverage | Repository automation | Flutter test runner | The runner dispatches tests and interprets timeout/retry classification; Flutter executes them. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-26; .github/workflows/audit.yml:85-126] |
| Production registrant and artifact hygiene | Repository automation | iOS/Android build tools | `release_preflight.sh` already cleans, regenerates, builds, and scans generated registrants/artifacts. [VERIFIED: scripts/release_preflight.sh:333-365] |
| iOS Simulator integration acceptance | iOS Simulator | Repository automation | The runner must erase/boot/readiness-check an isolated Simulator then execute the discovered suite. Flutter integration tests run on an OS emulator rather than replacing it with host tests. [CITED: https://docs.flutter.dev/testing/overview] |
| Android Emulator integration acceptance | Android Emulator | Repository automation | The established primary lane creates a runner-owned API 36 arm64-v8a AVD with `-wipe-data`, `-no-snapshot`, and cleanup proof. [VERIFIED: scripts/verify_android_safety_lane.dart:1009-1029,1406-1644] |
| Evidence, privacy filtering, report rendering, and CI artifact retention | Repository automation | GitHub Actions artifacts | JSON is the authority, Markdown is a concise rendering, and raw logs stay outside Git. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:34-38] |

## Project Constraints (from AGENTS.md)

- Work on `main` unless the user requests another branch; inspect `git status -sb` before editing and preserve unrelated changes. [VERIFIED: AGENTS.md]
- Preserve Clean Architecture boundaries; this phase belongs in repository automation, not the Flutter runtime layers. [VERIFIED: AGENTS.md]
- Do not hand-edit generated files; generation changes require the project generators and tracked-output verification. [VERIFIED: AGENTS.md]
- Do not log or persist sensitive financial data, keys, tokens, recovery material, or sync-payload details. Use existing security services for crypto and never reintroduce either retired SQLCipher Flutter library. [VERIFIED: AGENTS.md]
- Maintain the selected SQLCipher Native Assets posture and startup checks; this phase may verify those contracts but must not weaken them. [VERIFIED: AGENTS.md]
- Use TDD for behavior changes. Run `flutter analyze` with zero issues and relevant tests; broad behavior work requires `flutter test` or a justified equivalent. If default concurrency times out, isolate the affected file and use `flutter test --concurrency=1` for a full confirmation. [VERIFIED: AGENTS.md]
- The coverage gate remains 70%; i18n and Drift rules remain applicable if a change unexpectedly crosses into those areas. [VERIFIED: AGENTS.md]
- Do not commit generated/formatter churn unrelated to the task; do not push `main` without a user request. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Dart standalone script using `dart:io` / `dart:convert` | Dart 3.12.2 | Candidate fingerprint, process orchestration, JSON evidence, retry/resume logic | Existing native-safety programs use this model, so it avoids a second orchestration runtime. [VERIFIED: local `dart --version`; scripts/verify_ios_native_safety_lane.dart:17-21,89-97] |
| Existing `package:crypto` | Existing direct dependency | SHA-256 for candidate/config/status binding | It is already a direct project dependency and is used by both native-safety scripts; Phase 62 needs no dependency installation. [VERIFIED: pubspec.yaml:27-30; scripts/verify_android_safety_lane.dart:6-10] |
| `scripts/verify_codegen_reproducibility.sh` | Repository-owned | Locked resolution, two generation passes, analysis, import lint, architecture tests, tooling guards, whitespace | It is already the sole Stable-CI owner for this lower-level contract. [VERIFIED: scripts/verify_codegen_reproducibility.sh:53-77; .github/workflows/audit.yml:38-42] |
| `scripts/release_preflight.sh` | Repository-owned | Clean native registrants, dev-plugin exclusion, release smoke/package hygiene | It has explicit clean → regenerate → compile → scan ordering and restores its temporary iOS dependency scope. [VERIFIED: scripts/release_preflight.sh:106-149,333-365] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---|---:|---|---|
| `scripts/coverage_gate.dart` plus existing `coverde` lane | Existing 70% contract | Per-file and global cleaned-LCOV gate | After full host tests produce coverage; missing LCOV entries are failures. [VERIFIED: .github/workflows/audit.yml:85-126; scripts/coverage_gate.dart:245-273] |
| `scripts/verify_ios_native_safety_lane.dart` | Repository-owned | iOS clean/build/runtime patterns, status preservation, redaction | Extract/reuse mechanics only; Phase 62 must execute the full discovered device suite, not its two-test allowlist. [VERIFIED: scripts/verify_ios_native_safety_lane.dart:35-45,608-736,813-851] |
| `scripts/verify_android_safety_lane.dart` | Repository-owned | API 36 arm64 cold boot, recursive device test discovery, runner-owned cleanup, release rescan | Reuse its concrete local-primary AVD mechanics and rebind results to the Phase 62 candidate. [VERIFIED: scripts/verify_android_safety_lane.dart:1014-1029,1149-1165,1198-1288,1406-1644] |
| GitHub Actions workflow YAML | Existing CI | PR fast gate and `main` full dual-platform gate | Workflows can restrict `push` and `pull_request` by branch/path; make the supplemental lane explicit rather than silently conflating it with required acceptance. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| One Dart release-lock authority | A shell meta-script | Shell can launch commands, but structured schemas, classification, digest maps, resume checkpoints, and privacy-safe rendering would duplicate the robust Dart patterns already present. [VERIFIED: scripts/verify_ios_native_safety_lane.dart:813-851; scripts/verify_android_safety_lane.dart:850-861] |
| Directly invoking existing CI commands | A separate local and CI implementation | This contradicts D-01 because two equivalent command graphs can drift; the current workflows already duplicate lower-level calls. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:16-20; .github/workflows/audit.yml:24-114; .github/workflows/device-e2e.yml:36-108] |
| Current candidate-bound rerun | Accepting Phase 60/61 evidence | Historical Phase 61 evidence has an explicit stale-provenance limitation, so it cannot attest to the exact Phase 62 candidate. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:103-112] |

**Installation:** No new external package is warranted or authorized; use the committed project graph. [VERIFIED: pubspec.yaml:1-126]

## Architecture Patterns

### System Architecture Diagram

```text
clean, committed checkout
          |
          v
candidate snapshot ──> commit + lock + critical-config digests + environment fingerprint
          |
          +── mismatch / dirty state ──> BLOCKED (no retry)
          v
fail-fast prerequisites
  locked pub + dependency + two-pass generation + static/architecture/privacy/whitespace
          |
          +── failure ──> BLOCKED (no downstream stages)
          v
independent aggregate stages ──┬── target/full host tests + timeout protocol
                               ├── cleaned-LCOV coverage gate
                               ├── release preflight + dev-plugin hygiene
                               ├── erased iOS Simulator full integration suite
                               └── erased API-36 arm64 Android Emulator full suite
                                          |
                           optional, explicit x86_64 supplemental result
                                          v
privacy filter + schema validation + post-run identity/drift proof
          |
          v
raw JSON/checkpoints outside Git ──> concise Markdown renderer ──> candidate verdict
```

The ordering is prescribed by D-05 through D-08, while the existing generator wrapper and Android lane demonstrate the lower-level preparation and full recursive discovery mechanisms. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-38; scripts/verify_codegen_reproducibility.sh:53-77; scripts/verify_android_safety_lane.dart:1149-1165]

### Recommended Project Structure

```text
scripts/
├── release_gate.dart                 # sole candidate-bound authority [ASSUMED]
└── release_gate/                     # pure models, process adapter, sanitizer, renderer [ASSUMED]
test/scripts/
└── release_gate_test.dart            # command-free behavior and mutation tests [ASSUMED]
test/architecture/
└── release_gate_ci_contract_test.dart # workflow and single-entrypoint contract [ASSUMED]
docs/testing/
└── RELEASE_COMPATIBILITY.md          # concise rendered report [ASSUMED]
build/release_gate/                   # ignored raw attempt JSON/logs/checkpoints [ASSUMED]
```

### Pattern 1: Snapshot once; verify before every irreversible stage

**What:** Create an immutable candidate record before cleanup/generation, compare it before each resume/stage boundary, and compare it again after all stages. It must include the Git commit, `pubspec.lock`, the critical native/toolchain input set, clean Git status, and non-sensitive environment fingerprint. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-26,111-116; docs/testing/STABLE_BASELINE.json:185-195]

**When to use:** Every normal run and every resume. A mismatch invalidates the checkpoint rather than selecting a later restart point. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:24-26]

### Pattern 2: Fail-fast prerequisites, aggregate independent proof

**What:** Stop immediately for identity/resolution/generation/static-contract failures. Once prerequisites pass, collect all independent host/platform outcomes and return one normalized report. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-25]

**When to use:** Do not run native/device workloads against an untrusted graph; do run the remaining independent stages after a test, coverage, preflight, or one-platform failure so the maintainer receives actionable closure information. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-25]

### Pattern 3: Result classes are data, not ad-hoc exit-code handling

**What:** Model each stage with its command, start/end UTC timestamps, exit classification, attempt count, candidate fingerprint, and scrubbed bounded diagnostic. Compute the final verdict only after schema validation. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:34-38; scripts/verify_android_safety_lane.dart:850-861,1284-1299]

**When to use:** The retry classifier may retry a recognized infrastructure class once; assertions, build/signing/hygiene, privacy, coverage, and identity failures stay terminal. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:23-26]

### Pattern 4: Discover tests recursively and reject coverage gaps

**What:** Derive the complete device set from `integration_test/`, canonicalize relative paths, reject an empty discovery, and compare discovery against executed records and the skip allowlist. The existing Android runner already recursively finds files ending `_test.dart`. [VERIFIED: scripts/verify_android_safety_lane.dart:1149-1165,1243-1288]

**When to use:** Both platforms must consume the same discovered set; an iOS allowlist of only SQLCipher tests is insufficient for D-09. [VERIFIED: scripts/verify_ios_native_safety_lane.dart:35-45; .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-32]

### Example: Pure verdict computation skeleton

```dart
// Keep this pure and exhaustively unit-test it.
ReleaseVerdict computeVerdict(GateResult result) {
  if (result.hasMandatoryFailure || !result.identityIsCurrent) {
    return ReleaseVerdict.blocked;
  }
  return result.hasAcceptedLimitation
      ? ReleaseVerdict.passWithLimitations
      : ReleaseVerdict.pass;
}
```

This is a design skeleton, not copied production code; the exact types/enum spelling remain discretionary. [ASSUMED]

### Anti-Patterns to Avoid

- **A report that merely wraps Phase 61 evidence:** It preserves the stale-provenance hole accepted in Phase 61. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:103-112,143-150]
- **A local command graph and separate CI graph:** It violates the one-authority decision and creates drift. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:16-20]
- **A broad retry on any nonzero exit:** It can hide product or security regressions; retry only the listed infrastructure classes once. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:23-26]
- **Trusting a workflow declaration as device evidence:** Flutter documents that integration tests run on target devices/emulators, while host tests remain a different class. [CITED: https://docs.flutter.dev/testing/overview]
- **Writing raw logs into a tracked report:** D-14/D-15 require concise checked-in evidence and exclude sensitive categories at collection time. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:34-38]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Dependency/generation/static/whitespace validation | A second sequence of Flutter commands | `scripts/verify_codegen_reproducibility.sh` | It already performs locked resolution, dependency validation, two generation passes, analyzer/import/architecture checks, tooling guards, and `git diff --check`. [VERIFIED: scripts/verify_codegen_reproducibility.sh:53-77] |
| Coverage parsing and per-file threshold logic | A new LCOV parser | `scripts/coverage_gate.dart` plus the current cleaned-LCOV CI pipeline | It emits structured results and fails both below-threshold and missing coverage records. [VERIFIED: .github/workflows/audit.yml:96-126; scripts/coverage_gate.dart:245-273] |
| Release registrant/artifact hygiene | A new native registrar scanner | `scripts/release_preflight.sh` | It cleans and regenerates before compile, excludes iOS `integration_test`, and scans registrants/artifacts. [VERIFIED: scripts/release_preflight.sh:76-149,152-216,333-365] |
| Android AVD provisioning/cleanup | A custom ad hoc emulator command | Existing Android safety runner mechanics | It enforces API 36 arm64-v8a identity, cold boot, readiness, redacted serial, and runner-owned cleanup. [VERIFIED: scripts/verify_android_safety_lane.dart:1014-1029,1058-1112,1406-1644] |
| Sensitive-data encryption or a bespoke secret scrubber | New crypto or collect-then-sanitize logging | Existing `package:crypto` hash use and allowlisted/non-sensitive evidence fields | Evidence must exclude secrets and sensitive business data before persistence; no new crypto belongs in this phase. [VERIFIED: pubspec.yaml:27-30; .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:34-38] |

**Key insight:** The new code should own orchestration semantics—identity, stage graph, retry, resume, verdict, and rendering—not duplicate the specialized proof implemented by lower-level runners. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:16-20,96-116]

## Common Pitfalls

### Pitfall 1: Candidate provenance changes after a supposedly passing run

**What goes wrong:** Existing Phase 61 verification identifies that historical evidence can still be accepted after current source changes. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:103-112]

**How to avoid:** Snapshot commit/status/lock/config digests at the start and prove the same snapshot before resume, before each device launch, and on exit. A mismatch is a new candidate, not a retry. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-26]

### Pitfall 2: Device tests contaminate the next release build

**What goes wrong:** Integration execution can generate a dev-only registrant; the current preflight was created specifically because that contamination can break a later Android release compile. [VERIFIED: scripts/release_preflight.sh:3-8]

**How to avoid:** Always run release preflight after each platform integration stage and require its final cleanup/status proof. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:111-116; .github/workflows/device-e2e.yml:71-75,102-108]

### Pitfall 3: A timeout is mistaken for a product failure or a pass

**What goes wrong:** A default-concurrency timeout can leave the actual failing file unknown; treating it as green or retrying every failure violates D-06/D-07. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:23-26]

**How to avoid:** Capture the affected file(s), run isolated diagnosis, then require a full `flutter test --concurrency=1` success before QA-02 can pass. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:24-25]

### Pitfall 4: A supplemental x86 CI result becomes a hidden mandatory status check

**What goes wrong:** Phase 61 recorded that the current supplemental job has default blocking behavior despite being described as non-blocking. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:129-150]

**How to avoid:** Encode supplemental classification and its effect on the aggregate verdict in both workflow and mutation tests. Preserve its result as a named limitation; never use it as a substitute for local arm64 evidence. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-38]

### Pitfall 5: Privacy filtering happens too late

**What goes wrong:** Redacting a stored full log risks exposing device IDs, home paths, signing values, or financial/sync data in artifacts. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:34-38]

**How to avoid:** Use an allowlist of report fields, redact command/device/path output before it enters an evidence object, cap diagnostic length, and scan both raw-report candidates and Markdown output in tests. Existing Android evidence code already bounds and scrubs output. [VERIFIED: scripts/verify_android_safety_lane.dart:420-429,850-861]

### Pitfall 6: “Full integration suite” silently excludes nested tests

**What goes wrong:** The repository has a nested performance test alongside top-level tests; a shallow glob can omit it. [VERIFIED: integration_test/performance/performance_baseline_test.dart]

**How to avoid:** Use the existing recursive discovery behavior and assert discovered == executed + explicit allowed skips for each platform. [VERIFIED: scripts/verify_android_safety_lane.dart:1149-1165,1243-1288]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Separate lower-level generation/audit/device workflow commands | One repository-owned Phase 62 authority above reusable lower-level runners | Phase 62 locked decision | Eliminates competing local/CI pass definitions. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:16-20,96-116] |
| Historical Android evidence accepted by a verifier that does not compare current checkout inputs | Candidate-bound execution and final drift proof | Phase 62 scope | Closes the exact stale-provenance debt recorded at Phase 61. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:103-112; .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-26] |
| Device workflow on relevant PR changes | PR fast gates plus full dual-device run after every `main` merge | Phase 62 locked decision | Moves mandatory candidate-bound platform acceptance to the merge boundary. [VERIFIED: .github/workflows/device-e2e.yml:6-31; .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-32] |

**Deprecated/outdated:** Treat a workflow file, host suite, Phase 60 runtime result, Phase 61 runtime result, or x86 supplemental run as a substitute for the exact Phase 62 iOS-and-local-arm64 rerun. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-32]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `scripts/release_gate.dart` plus a `scripts/release_gate/` module directory is the best exact file layout. | Recommended Project Structure | Low; D-01 permits file naming and module boundaries to change. |
| A2 | `docs/testing/RELEASE_COMPATIBILITY.md` is the best Markdown report location. | Recommended Project Structure | Medium; the checked-in-report/candidate-identity lifecycle needs an explicit implementation decision. |
| A3 | `build/release_gate/` is the best ignored location for raw JSON/log/checkpoint artifacts. | Recommended Project Structure | Low; any ignored, privacy-filtered location satisfying D-04/D-06/D-13 is acceptable. |
| A4 | The exact `ReleaseVerdict` type names in the code skeleton. | Code Examples | Low; the required external values are locked by D-16, but implementation symbols remain discretionary. |

## Decision-Gated Research Resolutions

> **Status:** RESOLVED IN THE EXECUTABLE PLAN CONTRACT. The research evidence does not claim that the release owner already selected an option. Plan 62-02 contains three blocking `checkpoint:decision` tasks; its SUMMARY must record one RPT-*, CI-*, and SIGN-* code before any dependent implementation runs. A `*-HOLD` selection remains an honest phase blocker rather than an inferred default.

1. **Checked-in Markdown lifecycle — RESOLVED BY Plan 62-02 Task 1 (RPT-A / RPT-B / RPT-HOLD).**
   - What we know: D-02/D-04 require a clean committed candidate and no final repository mutation; D-13 simultaneously requires a checked-in Markdown rendering bound to that candidate. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-20,34-36]
   - What's unclear: Whether the report is committed as a metadata-only successor that explicitly references the tested parent candidate, or whether the final candidate definition must exclude a permitted generated report change.
   - Recommendation: Add a planner checkpoint for the release owner to lock this evidence-publication lifecycle before implementation; do not create a loophole that lets source/config drift be mistaken for report-only drift. [ASSUMED]

2. **Apple-Silicon every-main topology — RESOLVED BY Plan 62-02 Task 2 (CI-A / CI-B / CI-HOLD).**
   - What we know: the current GitHub Android job is Ubuntu x86_64 supplemental, whereas D-11 makes the local arm64 lane mandatory for the aggregate authority. [VERIFIED: .github/workflows/device-e2e.yml:37-76; .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-32]
   - What's unclear: Whether a self-hosted Apple-Silicon runner is available/authorized or whether CI should trigger/verify a local runner-owned invocation through an approved mechanism.
   - Recommendation: Plan a `checkpoint:decision` before altering CI because runner ownership/availability changes the executable architecture and cannot be assumed. [ASSUMED]

3. **Phase 61 JDK/signing-path ownership — RESOLVED BY Plan 62-02 Task 3 (SIGN-A / SIGN-B / SIGN-HOLD).**
   - What we know: Phase 61 documents this path as a warning because it adds `-Pphase61SigningEvidence=true`; the Phase 62 scope forbids weakening signing/hygiene but does not explicitly lock a repair choice. [VERIFIED: .planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md:129-150]
   - Recommendation: Treat it as a required release-gate test/repair if the Phase 62 authority invokes the signed Android evidence path; otherwise record a precise limitation and do not claim its package proof. [ASSUMED]

**Resolution record contract:** 62-02-SUMMARY is the sole durable record of these owner selections. Plans 62-03, 62-05, 62-08, and 62-09 read that record and stop on a missing or HOLD code. JDK 17 and ordinary signing/release-hygiene failures remain blocking under every SIGN option.

## Environment Availability

| Dependency | Required By | Available | Version / State | Fallback |
|---|---|---|---|---|
| Flutter SDK | Generation, host tests, device suites | ✓ | Flutter 3.44.8 / Dart 3.12.2 on macOS arm64. [VERIFIED: local `flutter --version`; local `dart --version`] | — |
| Xcode and iOS Simulator service | iOS Simulator gate | ✓ | Xcode 26.2; an available iPhone Simulator was observed. Device ID must not be persisted. [VERIFIED: local `xcodebuild -version`; local `xcrun simctl list devices available`] | — |
| CocoaPods | iOS lower-level runner/preflight | ✓ | 1.16.2. [VERIFIED: local `pod --version`] | — |
| Android SDK | Android primary Emulator/release gate | △ | SDK directory and `adb` exist, but the exact command-line-tool availability must be rechecked by the gate. The existing runner requires SDK-manager, AVD-manager, emulator, and adb under the SDK root. [VERIFIED: local filesystem probe; scripts/verify_android_safety_lane.dart:1406-1429] | No fallback for mandatory local arm64 acceptance. |
| JDK 17 | Android primary Emulator/release gate | ✗ | No Java runtime is currently discoverable; the existing runner requires a verified JDK 17. [VERIFIED: local `java -version`; scripts/verify_android_safety_lane.dart:1247-1263,2619-2626] | No fallback. Install/provide JDK 17 before executing platform stages. |
| Local API 36 `google_apis` arm64-v8a image | Android primary Emulator gate | Unknown / blocked by JDK readiness | The runner checks/installs the exact image and fails if it cannot obtain it. [VERIFIED: scripts/verify_android_safety_lane.dart:1437-1452] | No fallback. |
| GitHub-hosted x86_64 lane | Supplemental limitation evidence | ✓ in workflow definition | Existing job pins JDK 17, API 36, x86_64, and the Flutter SDK; it must be explicitly non-blocking in the Phase 62 aggregate model. [VERIFIED: .github/workflows/device-e2e.yml:37-75] | Local arm64 remains mandatory. |

**Missing dependencies with no fallback:** verified JDK 17; complete Android command-line SDK/toolchain/image readiness for the local primary gate. [VERIFIED: local `java -version`; scripts/verify_android_safety_lane.dart:1406-1452]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | `flutter_test` and SDK `integration_test`; Flutter 3.44.8 / Dart 3.12.2. [VERIFIED: pubspec.yaml:86-94; local `flutter --version`] |
| Config file | none — Flutter project defaults. [VERIFIED: repository file inventory] |
| Quick run command | `flutter test test/scripts/release_gate_test.dart test/architecture/release_gate_ci_contract_test.dart -r expanded` [ASSUMED] |
| Full suite command | `flutter test --concurrency=1 -r expanded` when timeout recovery is required; otherwise `flutter test -r expanded`. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:24-25] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| QA-01 | Candidate identity rejects dirty/current-input mismatch; prerequisite ordering delegates to existing wrapper; report privacy scan rejects forbidden fields. | unit + architecture | `flutter test test/scripts/release_gate_test.dart test/architecture/release_gate_ci_contract_test.dart -r expanded` [ASSUMED] | ❌ Wave 0 |
| QA-02 | Timeout classifier permits exactly one infrastructure retry; serial full-suite confirmation is required; coverage failure remains terminal. | unit | `flutter test test/scripts/release_gate_test.dart test/scripts/coverage_gate_test.dart -r expanded` [ASSUMED] | ❌ Wave 0 / ✅ existing coverage test |
| QA-03 | CI calls the one entrypoint with locked Flutter graph; release preflight remains ordered and rejects dev registrants. | architecture + script | `flutter test test/architecture/release_gate_ci_contract_test.dart test/scripts/release_preflight_test.dart -r expanded` [ASSUMED] | ❌ Wave 0 / ✅ existing preflight test |
| QA-04 | Recursive discovery equals execution plus allowlisted skips on both platforms; verdict/limitations/rendering/redaction/resume invalidation are fail-closed. | unit + architecture | `flutter test test/scripts/release_gate_test.dart test/architecture/device_e2e_contract_test.dart -r expanded` [ASSUMED] | ❌ Wave 0 / ✅ existing device contract |

### Sampling Rate

- **Per task commit:** the targeted orchestration/CI contract command above. [ASSUMED]
- **Per wave merge:** `flutter analyze` plus `flutter test -r expanded`. [VERIFIED: AGENTS.md]
- **Phase gate:** the single release-lock entrypoint green on the candidate, followed by its candidate/drift proof. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:16-26]

### Wave 0 Gaps

- [ ] `test/scripts/release_gate_test.dart` — candidate fingerprint, stage ordering, retry eligibility/limit, resume invalidation, discovered-vs-executed coverage, skip allowlist, verdict, JSON schema, and privacy-filter mutations. [ASSUMED]
- [ ] `test/architecture/release_gate_ci_contract_test.dart` — one entrypoint invoked by local/CI jobs, PR vs `main` routing, exact Flutter/lock path alignment, and explicit supplemental-lane classification. [ASSUMED]
- [ ] Test fixture helpers for a temporary Git repository and synthetic normalized command results; do not boot emulators from unit tests. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Phase 62 must not introduce identities or credentials; physical-phone identity remains Phase 63. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:9,131-137] |
| V3 Session Management | No | No application session behavior changes are in scope. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:9] |
| V4 Access Control | Yes | Reject a dirty/uncommitted candidate and require the repository-owned entrypoint; no manual override can convert a mandatory failure to pass. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-20,34-38] |
| V5 Input Validation | Yes | Strict CLI/schema/allowlist validation for gate options, checkpoint JSON, discovered files, environment fingerprints, and classified failures. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-32] |
| V6 Cryptography | Yes | Use existing SHA-256 provenance pattern only; do not hand-roll encryption or store secret material. [VERIFIED: pubspec.yaml:27-30; scripts/verify_ios_native_safety_lane.dart:830-851] |

### Known Threat Patterns for release-gate automation

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Stale or mismatched evidence | Tampering | Bind and repeatedly compare commit, lock, config digests, environment fingerprint, and clean status; invalidate checkpoints on mismatch. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:17-26] |
| Secret/device/financial data reaches reports or CI artifacts | Information disclosure | Exclude sensitive categories at collection; redact before persistence; schema/architecture tests scan raw normalized evidence and rendered Markdown. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:34-38] |
| Unregistered skip or incomplete device discovery | Elevation of privilege | Require an explicit reason/owner/exit-condition allowlist and fail on unexplained discovered-but-unexecuted tests. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:28-32] |
| Product failure misclassified as infrastructure retry | Tampering | Closed infrastructure classifier and one-attempt limit; tests mutate assertion/build/privacy/coverage failures to prove no retry. [VERIFIED: .planning/phases/62-automated-release-gate-lock/62-CONTEXT.md:22-26] |
| Integration residue contaminates release artifacts | Tampering | Post-device release preflight regenerates and scans registrants/artifacts. [VERIFIED: scripts/release_preflight.sh:3-8,333-365] |

## Sources

### Primary (HIGH confidence)

- [Flutter integration-test overview](https://docs.flutter.dev/testing/overview) — target-device/emulator role and host-test distinction. [CITED: https://docs.flutter.dev/testing/overview]
- [Flutter integration-test guide](https://docs.flutter.dev/testing/integration-tests) — SDK `integration_test` usage and mobile test execution. [CITED: https://docs.flutter.dev/testing/integration-tests]
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — event filters and job/step semantics. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- Local source-of-truth scripts and workflows listed throughout this document. [VERIFIED: scripts/verify_codegen_reproducibility.sh:53-77; scripts/release_preflight.sh:333-365; .github/workflows/audit.yml:24-126; .github/workflows/device-e2e.yml:36-108]

### Secondary (MEDIUM confidence)

- Current local tool probes for Flutter/Dart, Xcode, Simulator, CocoaPods, Java, and Android availability. [VERIFIED: local commands run 2026-08-10]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — composed from existing checked-in runners and no new third-party packages.
- Architecture: HIGH — locked Context decisions plus direct source inspection identify both required reuse seams and Phase 61 gaps.
- Pitfalls: HIGH — stale provenance, x86 workflow semantics, device residue, and timeout protocol are directly documented in Phase 61 and Context.

**Research date:** 2026-08-10
**Valid until:** 2026-09-09 for repository structure; recheck local Simulator/Android/JDK readiness immediately before execution.
