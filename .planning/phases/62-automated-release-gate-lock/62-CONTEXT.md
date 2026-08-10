# Phase 62: Automated Release-Gate Lock - Context

**Gathered:** 2026-08-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock one exact, committed Happy Pocket compatibility candidate behind a repository-owned automated release gate. Phase 62 owns clean-state candidate identity, reproducible generation, analysis and architecture/privacy/dependency/whitespace contracts, targeted and full host tests, coverage, release-preflight hygiene, complete iOS Simulator and Android Emulator integration suites, CI alignment, and the final compatibility evidence report. It consumes the exact graphs and safety conclusions selected in Phases 58-61. It does not reopen dependency selections, change product behavior or schema, perform Android physical-device acceptance, install on the wired iPhone, exercise production identities or data, submit to an app store, or perform final legal review.

</domain>

<decisions>
## Implementation Decisions

### Canonical Gate Entrypoint
- **D-01:** Provide one version-controlled, repository-owned release-gate program as the sole authority for whether Phase 62 passes. Local execution and CI must call this same entrypoint; existing generation, release-preflight, coverage, and native-safety runners remain reusable lower-level capabilities rather than competing authorities.
- **D-02:** A formal candidate must be a clean, committed Git commit. Before execution, bind the evidence to the commit, `pubspec.lock`, and digests of the critical native/toolchain configuration. Source changes, lockfile changes, relevant untracked generated output, or unexplained tracked drift make the candidate ineligible.
- **D-03:** The authoritative execution is one macOS command on the current Apple Silicon host. It runs the required host, iOS Simulator, Android Emulator, and release-preflight gates as one orchestrated release-lock operation rather than exposing independently authoritative platform commands.
- **D-04:** Run directly in the current clean checkout, not a temporary clone. The program must perform strict pre-run cleanup/readiness checks and finish by proving there is no source, lockfile, configuration, or generated-output drift. It may create ignored/disposable build and evidence artifacts, but a dirty or mutated repository cannot pass.

### Failure, Retry, and Recovery
- **D-05:** Use hybrid failure handling. Candidate identity, locked dependency resolution, generation cleanliness, static analysis, and other prerequisite contract failures stop the operation immediately. Once the independent test/platform stages begin, run enough independent gates to return a useful aggregate of failures rather than hiding every later issue behind the first platform failure.
- **D-06:** Automatically retry only an explicitly classified infrastructure failure, at most once. Eligible classes include deterministic simulator/emulator startup or readiness failures, device transport failure, dependency-download/network failure, and recognized test-runner/subprocess timeout. Assertions, compilation, signing/hygiene, security/privacy contracts, coverage shortfall, candidate drift, and other product/repository failures are never auto-retried. Preserve the first result and the retry evidence in non-repository raw artifacts.
- **D-07:** If default-concurrency `flutter test` hits a recognized runner/subprocess timeout, first rerun the affected file(s) in isolation for diagnosis, then automatically run the complete suite with `flutter test --concurrency=1`. QA-02 passes only if that complete serial confirmation is green.
- **D-08:** Permit controlled resume only while commit, lockfile, relevant configuration digests, environment fingerprint, and repository cleanliness remain identical. Resume must revalidate candidate identity and all prerequisite invariants before restarting at the earliest invalidated gate. Any source, dependency, or configuration change invalidates every prior result and requires a complete new run.

### Simulator and Emulator Acceptance
- **D-09:** Run the complete discovered `integration_test/` suite on both an iOS Simulator and the local API 36 `google_apis` arm64-v8a Android Emulator for the exact Phase 62 candidate. Phase 60/61 runtime evidence is historical input and cannot substitute for this candidate-bound rerun.
- **D-10:** Each formal platform run begins from erased application/test data, deterministic cold boot, disabled snapshot restoration, explicit readiness checks, and isolated synthetic data. Normal app containers, real Keychain/secure-storage values, user backups, production credentials, and physical devices are prohibited.
- **D-11:** Every merge to `main` must trigger the full dual-platform device gate. Pull requests retain the faster generation, analysis, host-test, coverage, and contract gates. Entry to Phase 63 requires a green Phase 62 result whose commit and candidate digests exactly match the Phase 63 candidate.
- **D-12:** Only skips in an explicit allowlist may be accepted. Each allowed skip requires a reason, owning phase, and exit condition; any new/unregistered skip, undiscovered test, unexecuted file, or unavailable required journey blocks the gate. The API 36 x86_64 GitHub/Intel lane remains independently testable supplemental evidence: absence or failure is recorded as a limitation and never as a pass, but it does not block the local arm64 primary acceptance or claim Android physical-device coverage.

### Compatibility Report and Evidence
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, Requirements, and Repository Policy
- `AGENTS.md` — branch/worktree, generation, architecture, SQLCipher, privacy, iOS/Android floor, testing, and quality-gate rules.
- `.planning/ROADMAP.md` — Phase 62 goal, QA-01 through QA-04 success criteria, dependencies, and Phase 63 boundary.
- `.planning/REQUIREMENTS.md` — locked automated-quality/release requirements, supported platforms, explicit exclusions, and traceability.
- `.planning/PROJECT.md` — v2.1 goal, selected compatibility posture, security guarantees, and current validated Phase 58-61 outcomes.
- `.planning/STATE.md` — current Phase 62 position, inherited owner decisions, accepted Phase 61 limitations, and pending release-owner constraints.

### Inherited Compatibility Decisions and Evidence
- `.planning/phases/58-flutter-analyzer-code-generation-lane/58-CONTEXT.md` — Flutter/Dart, analyzer/codegen cohort, authoritative generation, and architecture-enforcement decisions.
- `.planning/phases/59-controlled-platform-plugin-cohorts/59-VERIFICATION.md` — final held plugin graph and attributable host/native regression evidence.
- `.planning/phases/60-sqlcipher-ios-native-safety-lane/60-CONTEXT.md` — exact SQLCipher Native Assets graph, iOS build/runtime boundary, and clean-state safety decisions.
- `.planning/phases/60-sqlcipher-ios-native-safety-lane/60-VERIFICATION.md` — verified current-schema encrypted lifecycle, current HPB-v2 scope, and compile/runtime distinctions.
- `.planning/phases/61-android-toolchain-emulator-lane/61-CONTEXT.md` — selected-or-hold Android policy, signing/hygiene boundary, primary arm64 and supplemental x86_64 decisions.
- `.planning/phases/61-android-toolchain-emulator-lane/61-VERIFICATION.md` — final Android graph, local Emulator evidence, accepted limitations, and no-physical-device claim.

### Compatibility Contracts and Release Runners
- `docs/testing/STABLE_BASELINE.json` — machine-readable selected versions, candidates, holds, exit conditions, and critical input digests.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` — human-readable coordinated compatibility and safe-hold policy.
- `docs/testing/DEVICE_E2E_MATRIX.md` — supported device journeys, platform evidence classes, and primary/supplemental Emulator matrix.
- `scripts/dependency_compatibility.dart` — fail-closed dependency, toolchain, floor, hold, and tracked-input validator.
- `scripts/verify_codegen_reproducibility.sh` — locked resolution, two-pass generation, analysis, architecture tests, and whitespace gate.
- `scripts/release_preflight.sh` — clean registrant regeneration, dev-plugin exclusion, release compilation/packaging, and artifact hygiene.
- `scripts/verify_ios_native_safety_lane.dart` — retained/from-zero native graph, iOS floor, build, and runtime-evidence runner patterns.
- `scripts/verify_android_safety_lane.dart` — Android graph, signed release, Emulator, redacted provenance, and supplemental-lane patterns.
- `scripts/coverage_gate.dart` — per-file 70% coverage contract with explicit, reasoned deferrals.

### CI and Executable Tests
- `.github/workflows/audit.yml` — current PR/main generation, analysis, guardrail, and coverage jobs pinned to Flutter Stable.
- `.github/workflows/device-e2e.yml` — current iOS Simulator and Android Emulator integration jobs and release-metadata cleanup.
- `test/architecture/codegen_reproducibility_contract_test.dart` — source contract for the authoritative two-pass generation wrapper.
- `test/architecture/dependency_compatibility_contract_test.dart` — positive and mutation tests for selected graph, holds, floors, and CI alignment.
- `test/architecture/device_e2e_contract_test.dart` — CI pin, device matrix, integration discovery, and critical-journey declaration contract.
- `test/architecture/production_logging_privacy_test.dart` — production log privacy gate relevant to evidence collection.
- `test/scripts/release_preflight_test.dart` — release-preflight behavior and dev-only registrant rejection contract.
- `test/scripts/coverage_gate_test.dart` — coverage threshold, missing-input, and deferral-discipline behavior.
- `integration_test/` — the complete device suite that must be discovered and executed on both primary platforms for the final candidate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/verify_codegen_reproducibility.sh` already owns locked dependency verification, two generation passes, analyzer/lint/import guards, architecture tests, and `git diff --check`; the aggregate gate should call or extend it rather than duplicate those rules.
- `scripts/release_preflight.sh` already performs Flutter clean/regeneration, excludes `integration_test` from production iOS dependency scope, inspects generated registrants, and scans Android/iOS release artifacts.
- `scripts/verify_ios_native_safety_lane.dart` and `scripts/verify_android_safety_lane.dart` already model redacted environment evidence, native graph verification, disposable artifacts, device readiness, and fail-closed result classification.
- `scripts/coverage_gate.dart`, `coverde`, and `.github/workflows/audit.yml` already implement the 70% global/per-configured-file coverage pipeline and explicit deferral discipline.
- `.github/workflows/device-e2e.yml` and the `integration_test/` directory already provide full-directory device execution and post-test release hygiene seams.

### Established Patterns
- Compatibility and security evidence is attributable to an exact graph; a partial graph, plaintext fallback, unjustified suppression, or unbound result is failure.
- Generated output is regenerated and inspected, never hand-edited. Clean-before/after Git diff checks are an existing reproducibility oracle.
- Compile, release packaging, Simulator/Emulator runtime, and physical-device acceptance are distinct evidence classes.
- Device tests use synthetic, isolated state; identifiers and sensitive data are redacted or excluded from evidence.
- Default-concurrency Flutter test timeouts are resolved by isolated diagnosis plus a complete `--concurrency=1` confirmation before declaring green.
- Current CI is split across `audit.yml` and `device-e2e.yml`; Phase 62 intentionally introduces one repository authority above those existing jobs.

### Integration Points
- The new authority must coordinate `pubspec.lock`, `.metadata`, `docs/testing/STABLE_BASELINE.json`, native project inputs, and the candidate Git commit as one identity.
- PR checks continue through `audit.yml`; every `main` merge must route through the same aggregate authority and include both local-primary device classes required by D-09 through D-12.
- Integration execution can contaminate generated registrants, so every device stage connects to the existing post-test release-preflight cleanup and artifact scan.
- The report generator consumes normalized results from host, coverage, release, iOS, and Android gates and emits one verdict without allowing a supplemental limitation to mask a mandatory failure.
- Phase 63 may consume Phase 62 only when its candidate identity exactly matches a `PASS` or valid `PASS_WITH_LIMITATIONS` report.

</code_context>

<specifics>
## Specific Ideas

- The maintainer wants one visible macOS command rather than a family of independently authoritative platform commands.
- The command deliberately operates in the current clean checkout, with strict cleanup and drift proof, instead of hiding work in a temporary clone.
- Full device suites run after every merge to `main`, not on every pull request and not only when a release candidate is manually labeled.
- The checked-in compatibility report should be concise and final-result oriented; detailed raw attempts belong in CI artifacts, while QA-04's actual failure/fix summary remains mandatory.
- `PASS_WITH_LIMITATIONS` is not an override. It communicates only named non-blocking limitations after every required gate has passed.

</specifics>

<deferred>
## Deferred Ideas

- Additive signed wired-iPhone identity, installation, SQLCipher/backup/app-lock/accounting acceptance, and same-device performance evidence remain Phase 63.
- Android physical-device validation remains unavailable and out of scope; Phase 62 must state that it was not performed or claimed.
- App Store/Google Play submission, hosted legal/support/operator-value completion, and final legal review remain release-owner gates outside this technical phase.
- Raw sketches exist under `.planning/sketches/` but have no packaged findings skill and do not affect this non-UI release-gate phase.

</deferred>

---

*Phase: 62-automated-release-gate-lock*
*Context gathered: 2026-08-10*
