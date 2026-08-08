---
phase: 58
slug: flutter-analyzer-code-generation-lane
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on.
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-08
---

# Phase 58 — Security

> Per-phase security contract for the Flutter, analyzer, and code-generation lane.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Dart source → owned provider scanner | Source tokens, import aliases, lexical declarations, and supported call shapes determine whether an app root is protected. | Repository source; no runtime user data |
| Owned scanner → lint/architecture decision | Scanner records and diagnostics determine whether CI accepts or rejects the source tree. | Diagnostic codes, paths, and pass/fail state |
| Test harness/processes → production-scanned `lib/` | Negative tests temporarily place deliberately invalid, exactly owned sentinel files in a production-scanned path. | Synthetic Dart fixtures only |
| In-process callers/processes → fixture queue and filesystem lock | Concurrent tests coordinate stale preflight, mutation, child checks, and cleanup. | Lock ownership, local paths, and process status |
| Official package metadata → compatibility policy | Time-sensitive Flutter and Pub metadata is recorded as the selected or held toolchain policy. | Public version and compatibility metadata |
| Manifest/lockfile → compatibility validator | Solver selections and override state determine whether the analyzer/generator/lint cohort is accepted. | Dependency names, versions, SDK identity, and digests |
| Generator inputs → tracked generated output | ARBs, annotations, schema declarations, and generator configuration produce committed Dart. | Repository source and generated code |
| Wrapper/workflow source → Stable CI runner | Checked-in commands and their order define the authoritative acceptance lane. | Repository source, command status, and CI logs |
| Tool/test results → validation and phase completion | Observed exits, diffs, coverage, and residue checks determine whether the phase is declared complete. | Test results, coverage, paths, and Git diff state |
| Phase 58 scope → later native/runtime lanes | Dart tooling decisions must not silently claim SQLCipher, plugin, native, simulator, or device acceptance. | Scope declarations only |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-58-01 | Tampering | Temporary invalid fixtures | high | mitigate | Exact sentinel ownership, stale-file refusal, serialized writes, and `finally` cleanup are implemented in `scripts/verify_tooling_guards.dart` and covered by `tooling_guard_negative_fixture_test.dart`. | closed |
| T-58-02 | Repudiation | Diagnostic matching | medium | mitigate | Negative cases require nonzero status, stable diagnostic code, exact fixture attribution, and cleanup evidence. | closed |
| T-58-03 | Denial of Service | Nested tooling commands | medium | mitigate | The harness runs bounded, sequential, non-watch child commands and releases cleanup paths before returning. | closed |
| T-58-04 | Elevation of Privilege | Architecture/lint policy | high | mitigate | Active analyzer/import/Riverpod enforcement plus repository-owned provider guards have independent bad/control proofs; no ignore, demotion, or rule removal was introduced. | closed |
| T-58-05 | Spoofing | Execution-date candidate evidence | high | mitigate | `STABLE_BASELINE.json`, `DEPENDENCY_COMPATIBILITY.md`, and the live compatibility validator preserve exact selected/held versions, query dates, and exit conditions. | closed |
| T-58-06 | Tampering | Analyzer/codegen lock graph | high | mitigate | Exact manifest/lock assertions and mutation-tested dependency contracts reject partial analyzer, plugin, generator, and lint drift. | closed |
| T-58-07 | Elevation of Privilege | Overrides or lint removal | high | mitigate | Dependency contracts prohibit overrides and require the selected import and Riverpod lint members. | closed |
| T-58-08 | Information Disclosure | Drift/native boundary | high | mitigate | The exact cohort holds Drift at the selected version and Phase 58 made no SQLite, SQLCipher, plugin, or native change or acceptance claim. | closed |
| T-58-09 | Tampering | Generated output | high | mitigate | Only official localization/build_runner commands write generated output; independent HEAD-scoped clean-diff checks follow both passes. | closed |
| T-58-10 | Repudiation | First/second pass evidence | medium | mitigate | Unrolled pass markers and hard failures distinguish stale first-pass output from second-pass nondeterminism. | closed |
| T-58-11 | Denial of Service | Code-generation process | medium | mitigate | Strict sequential non-watch commands fail immediately and exclude native/device work from the gate. | closed |
| T-58-12 | Information Disclosure | Command output | low | accept | Accepted as R-58-01: the commands process repository source/configuration only and must not receive secrets or user data. | closed |
| T-58-12A | Tampering | D-08 command order | high | mitigate | Mutation tests prove analyzer, lint, architecture tests, and tooling guards cannot move before the second clean generation diff or be omitted/duplicated. | closed |
| T-58-13 | Tampering | Stable CI command order | high | mitigate | Workflow source contracts require active exact commands, uniqueness, enforced lock retrieval, and post-generation ordering. | closed |
| T-58-14 | Elevation of Privilege | Soft-failed lint/generation | high | mitigate | Source contracts reject `continue-on-error` and shell fallback paths; wrapper and CI propagate nonzero exits. | closed |
| T-58-15 | Repudiation | Duplicate local/CI generation or lint logic | high | mitigate | Stable CI invokes the tested shared wrapper once; tests reject inline or alternate generator/analyzer/lint routes. | closed |
| T-58-16 | Information Disclosure | CI logs | low | accept | Accepted as R-58-02: the tooling lane processes source/configuration and excludes financial/runtime secrets from its inputs. | closed |
| T-58-17 | Repudiation | `58-VALIDATION.md` | high | mitigate | The validation record names exact observed commands and retains green status only for successful execution evidence. | closed |
| T-58-18 | Tampering | Generated/coverage artifacts | high | mitigate | The authoritative wrapper repeats clean generated-output checks; coverage artifacts are ignored and tracked residue checks passed. | closed |
| T-58-19 | Denial of Service | Full Flutter suite | medium | mitigate | The documented isolated/serial diagnostic path does not replace the required final suite; Phase 58 ultimately passed default-concurrency coverage. | closed |
| T-58-20 | Elevation of Privilege | Scope claims | high | mitigate | Validation and verification explicitly limit evidence to Dart/analyzer/codegen and defer native/plugin/device acceptance. | closed |
| T-58G-01 | Tampering / Elevation of Privilege | Qualified `runApp` detection | high | mitigate | Qualified roots are accepted only from verified Flutter UI-library import prefixes and are covered by parser plus live bad/control fixtures. | closed |
| T-58G-02 | Denial of Service / Tampering | Alias-shadow resolution | medium | mitigate | Call-site-aware lexical ranges preserve enclosing shadows and exclude sibling/later declarations for supported syntax. | closed |
| T-58G-03 | Tampering / Denial of Service | Temporary invalid fixtures | high | mitigate | An invocation queue and blocking cross-process lock cover stale preflight, child checks, exact ownership, and cleanup. | closed |
| T-58G-04 | Tampering | Coverage dependency resolution | high | mitigate | Every independent Stable Flutter CI job uses lock-enforced dependency retrieval, protected by workflow mutation tests. | closed |
| T-58G-05 | Repudiation | CI compatibility guide | low | mitigate | Documentation source contracts preserve the sole-wrapper rule and distinguish diagnostics/future probes from acceptance. | closed |
| T-58G-06 | Information Disclosure | Test and CI output | low | accept | Accepted as R-58-03: in-scope fixtures contain repository tooling syntax and no financial, credential, sync, native-runtime, or device data. | closed |
| T-58G2-01 | Tampering / Elevation of Privilege | `_findCalls` direct-function syntax | high | mitigate | Only immediate invocation and exact direct-function `.call` forms use scope validation; verified-prefix and no-long-chain restrictions are regression-tested. | closed |
| T-58G2-02 | Denial of Service / Tampering | Type/member shadow classification | medium | mitigate | Type bodies are non-library scopes; inside/outside and unrelated-member matrices passed. | closed |
| T-58G2-03 | Denial of Service / Tampering | If/switch pattern scope | medium | mitigate | If-case shadows are bounded to the then statement and switch shadows to one case for the supported parser contract. | closed |
| T-58G2-04 | Repudiation | Live negative/control fixtures | high | mitigate | The real provider-contract CLI requires diagnostic code, exact attribution, opposite-polarity controls, and final cleanup. | closed |
| T-58G2-05 | Information Disclosure | Fixture and test output | low | accept | Accepted as R-58-04: the fixtures contain repository-local source syntax only and no sensitive runtime data. | closed |
| T-58G3-01 | Denial of Service | `_toolingGuardFixtureQueue` | high | mitigate | Queue completion runs in an outermost `finally`; real setup/action failure tests prove bounded same-process successors execute. | closed |
| T-58G3-02 | Tampering / Denial of Service | `.dart_tool/phase58_tooling_guard.lock` | high | mitigate | The implementation creates only the parent, uses a blocking exclusive lock, conditionally unlocks, always attempts close, and retains the shared coordinate. | closed |
| T-58G3-03 | Tampering | Test-owned `lib/` sentinels | high | mitigate | Whole-transaction locking, stale refusal, exact ownership, per-case deletion, live harness reruns, and zero-residue checks passed. | closed |
| T-58G3-04 | Repudiation | Failure-recovery evidence | medium | mitigate | A real filesystem obstruction, explicit first failure, bounded successor/action-failure cases, and the overlap test passed. | closed |
| T-58G3-05 | Information Disclosure | Lock/test diagnostics | low | accept | Accepted as R-58-05: diagnostics contain repository-local tooling paths/status only and exclude sensitive app data. | closed |
| T-58G4-01 | Tampering / Elevation of Privilege | Parenthesized app-root matching | high | mitigate | Only exact one-group unqualified or verified-prefix roots are accepted; parser and live bad/control evidence passed. | closed |
| T-58G4-02 | Tampering / Denial of Service | Receiver and grouping exclusions | medium | mitigate | Adversarial prefix, chain, grouping, comment, and string controls prevent broad false-positive matching for the supported contract. | closed |
| T-58G4-03 | Denial of Service / Tampering | Loop-header alias shadow range | medium | mitigate | C-style/for-in inside/post-loop matrices pass for supported statement forms; the nested-unbraced limitation is separately accepted as R-58-08. | closed |
| T-58G4-04 | Tampering | Temporary source fixtures | high | mitigate | Exact sentinel ownership, stale refusal, whole-transaction locking, attribution, and `finally` deletion are retained. | closed |
| T-58G4-05 | Information Disclosure | Parser/test diagnostics | low | accept | Accepted as R-58-06: diagnostics contain repository-local source and no financial, credential, payload, database, or device data. | closed |
| T-58G5-01 | Tampering / Elevation of Privilege | Build command source contract | high | mitigate | Tests count full trimmed executable-line equality twice and mutation-test shortening, spelling, duplication, and order. | closed |
| T-58G5-02 | Tampering | Generated output recovery | high | mitigate | Both official generator passes use conflict deletion and retain independent HEAD-scoped clean assertions. | closed |
| T-58G5-03 | Repudiation | D-08 execution order | medium | mitigate | Unrolled pass markers and source mutations enforce l10n → exact build → clean diff before downstream gates. | closed |
| T-58G5-04 | Denial of Service | Full default-concurrency verification | medium | mitigate | The required default-concurrency coverage suite passed with 4,554 tests and 12 expected skips before phase completion. | closed |
| T-58G5-05 | Information Disclosure | Build/test logs | low | accept | Accepted as R-58-07: commands process repository source/configuration only and exclude sensitive application data. | closed |
| T-58-V-01 | Tampering / Elevation of Privilege | Nested unbraced alias-shadow boundary | high | accept | Owner accepted R-58-08 after verification found no production exposure; active analyzer/import/Riverpod protections remain, and the token scanner is defense in depth. | closed |
| T-58-V-02 | Denial of Service | Locally shadowed unqualified `runApp` | medium | accept | Owner accepted R-58-09 after verification found no production use; supported project syntax avoids local `runApp` naming. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-58-01 | T-58-12 | Code-generation commands receive source/configuration only; sensitive runtime data is outside the lane. | Phase 58 Plan 03 | 2026-08-08 |
| R-58-02 | T-58-16 | CI tooling logs are limited to public repository/configuration evidence and must not receive runtime secrets. | Phase 58 Plan 04 | 2026-08-08 |
| R-58-03 | T-58G-06 | Test and CI fixtures contain tooling syntax only; sensitive application and device data is excluded. | Phase 58 Plan 06 | 2026-08-08 |
| R-58-04 | T-58G2-05 | Provider fixtures and diagnostics contain only repository-local source syntax and paths. | Phase 58 Plan 07 | 2026-08-08 |
| R-58-05 | T-58G3-05 | Lock diagnostics expose only repository-local coordination paths and process status. | Phase 58 Plan 08 | 2026-08-08 |
| R-58-06 | T-58G4-05 | Parser diagnostics contain only synthetic repository source; user data never enters the fixtures. | Phase 58 Plan 09 | 2026-08-08 |
| R-58-07 | T-58G5-05 | Build and test logs process source/configuration only and exclude sensitive application data. | Phase 58 Plan 10 | 2026-08-08 |
| R-58-08 | T-58-V-01 | The token scanner can truncate a local alias shadow in nested unbraced control flow. No affected production entrypoint exists; layered analyzer/import/Riverpod protection remains. An analyzer-AST rewrite is optional future debt. | Project owner, recorded in `58-VERIFICATION.md` | 2026-08-08 |
| R-58-09 | T-58-V-02 | A locally shadowed unqualified helper named `runApp` can be mistaken for Flutter's global app root. No production exposure exists; supported project syntax avoids this naming. | Project owner, recorded in `58-VERIFICATION.md` | 2026-08-08 |

*Accepted risks do not resurface as open threats unless their scope or exposure changes.*

---

## Security Audit 2026-08-08

| Metric | Count |
|--------|-------|
| Threats found | 49 |
| Closed | 49 |
| Open | 0 |

- Register origin: ten parseable plan-time `<threat_model>` blocks, supplemented by two owner-accepted risks already recorded in the final verification artifact.
- Summary threat flags: none.
- Audit depth: ASVS Level 1 grep/evidence verification.
- Short-circuit: all blocking high-severity threats had mitigation or recorded acceptance evidence, so the configured Level 1 workflow did not require a deeper security-auditor pass.
- Primary evidence: `58-VALIDATION.md`, Plans 01–10 summaries, `58-VERIFICATION.md`, implementation contracts, and their recorded passing commands.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-08 | 49 | 49 | 0 | Codex / `gsd-secure-phase` |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-08
