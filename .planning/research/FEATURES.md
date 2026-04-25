# Feature Research — Audit Pipeline for Flutter/Dart Codebase Cleanup

**Domain:** Audit pipeline for audit-driven, multi-phase technical-debt cleanup of a Flutter/Dart codebase
**Researched:** 2026-04-25
**Confidence:** HIGH (verified against actual codebase findings; tooling verified via pub.dev and official docs)

---

## Context

This document is about what an *audit pipeline* must produce — not what the Home Pocket app's features are. The pipeline's sole purpose is to surface every violation across four debt categories (layer violations, redundant code, dead code, Riverpod provider hygiene) so that severity-ordered phases can eliminate them one by one. Success criterion: re-run the pipeline at the end, find zero findings.

The codebase has 268 hand-written Dart source files and 183 test files. Known actual violations confirmed by direct inspection include: screens directly importing `infrastructure/category/category_service.dart`, `features/family_sync/use_cases/` importing `infrastructure/sync/relay_api_client.dart` and `infrastructure/crypto/` directly (use cases inside a feature that should live in `lib/application/`), `infrastructure/security/providers.dart` containing an `appDatabaseProvider` that throws `UnimplementedError`, a deprecated `ResolveLedgerTypeService` still wired in provider graph, ~169 hardcoded CJK strings violating i18n rules, and a 735-line `category_service.dart` with parallel static translation maps. The pipeline must enumerate all of these, not just the ones already known.

---

## Feature Landscape

### Table Stakes — Must Have (audit is incomplete without these)

| Feature | Why Required | Complexity | Notes |
|---------|-------------|------------|-------|
| **Finding record schema** — structured per-finding data model with: `id`, `category`, `severity`, `file_path`, `line_start`, `line_end`, `description`, `rationale`, `suggested_fix`, `tool_source`, `confidence` | Downstream phases consume findings by severity; cannot sort or filter without this schema | LOW | Schema must be agreed before any scan runs; every scanner emits into it |
| **Four-level severity taxonomy** — CRITICAL / HIGH / MEDIUM / LOW | Phases are ordered by severity (CRITICAL first); taxonomy is the gating mechanism between phases | LOW | See severity definitions below. Four levels is industry standard (CodeHawks, Veracode, OpenZeppelin audit reports all use this scheme). Five levels adds ambiguity; three levels loses the CRITICAL/HIGH distinction needed for architectural vs polish ordering. |
| **Layer-violation scanner** — detect imports that cross the defined dependency direction | Primary debt category; 5-layer Clean Architecture means specific crossing rules. Already confirmed violations present | HIGH | Automated: grep/AST-based import path analysis. AI-agent: semantic review for indirect violations |
| **Dead-code scanner** — unused Dart symbols (functions, classes, variables, private members) | Dart analyzer's built-in `dead_code` rule only catches unreachable branches, not unreferenced symbols. A dedicated tool is required | HIGH | `dead_code_analyzer` (pub.dev) or DCM `check-unused-code`; neither replaces the other entirely |
| **Unused-file scanner** — files with no import graph entry points | Orphaned files (e.g. a service extracted and renamed but original left behind) | MEDIUM | DCM `check-unused-files`; excludes `main.dart` and test entry points |
| **Deprecated-code scanner** — symbols annotated `@Deprecated` still referenced by non-deprecated code | `ResolveLedgerTypeService` confirmed deprecated but still wired via `ignore: deprecated_member_use_from_same_package`. Multiple fields in `SyncRepository` deprecated but still present | LOW | `flutter analyze` catches `deprecated_member_use` when `// ignore:` suppression is absent; supplement with grep for `// ignore: deprecated_member_use_from_same_package` |
| **Duplicate-provider scanner** — multiple `@riverpod` providers for the same repository across feature files | Confirmed CLAUDE.md pitfall #10; causes stale/inconsistent DI graph | MEDIUM | AST grep for `@riverpod` + matching function signatures returning same repository type |
| **UnimplementedError-in-provider detector** — providers that throw instead of returning a value | Confirmed: `appDatabaseProvider` in `lib/infrastructure/security/providers.dart:96-102` | LOW | grep `UnimplementedError` inside `@riverpod`-annotated functions |
| **Misplaced-provider detector** — repository providers defined outside `repository_providers.dart` | CLAUDE.md rule: ONE `repository_providers.dart` per feature | LOW | grep: `@riverpod` annotating a repository-return function in any file not named `repository_providers.dart` |
| **ARB unused-key scanner** — ARB keys defined in all 3 locale files but never referenced via `S.of(context)` | 3 confirmed stubs (`ocrScan`, `ocrScanTitle`, `ocrHint`) in generated localizations with no implementing screen | MEDIUM | `remove_unused_localizations` (pub.dev) or custom Dart script; must handle `S.of(context).keyName` call pattern |
| **Hardcoded-string scanner** — CJK or user-visible string literals in non-ARB, non-generated Dart files | ~169 occurrences confirmed by CONCERNS.md; violates i18n rule | LOW | grep for CJK Unicode ranges `\p{Han}` in Dart source outside `lib/l10n/`, `lib/generated/`, `lib/shared/constants/` |
| **Findings file output** — machine-readable output (JSON or YAML) + human-readable Markdown catalogue | Downstream phases read the machine-readable form; engineers read the Markdown | MEDIUM | Two formats: `ISSUES.json` (structured, machine-readable) and `ISSUES.md` (human-readable, severity-sorted) |
| **Severity-ordered findings presentation** — CRITICAL findings listed first in ISSUES.md | Phases work CRITICAL → HIGH → MEDIUM → LOW; presentation must reinforce this | LOW | Sort during report generation; trivial once schema exists |
| **Re-audit / zero-finding verification** — re-run full pipeline after fixes; confirm finding count drops to zero | Audit completeness is the exit criterion for the entire initiative | MEDIUM | Same scan scripts, same schema, compare before/after counts; CI can gate on finding count = 0 |

### Differentiators — High Value but Optional for THIS Initiative

| Feature | Value Proposition | Complexity | Notes |
|---------|------------------|------------|-------|
| **Confidence scoring on dead-code findings** — "definitely dead" vs "appears unused but may be reached via dynamic dispatch, reflection, or code-gen" | Prevents false positives from deleting code that is actually alive | MEDIUM | Mark as `confidence: HIGH` for private members with no Dart references; `confidence: LOW` for public symbols (could be exposed to tests or external callers); Drift-generated `*.g.dart` references excluded by convention |
| **Feature-to-application layer mapping audit** — verify each `features/*/use_cases/` directory should be in `lib/application/` instead | `lib/features/family_sync/use_cases/` confirmed to exist with direct infrastructure imports — these use cases belong in `lib/application/family_sync/` | MEDIUM | AI-agent review; grep for `use_cases/` directories inside `lib/features/` |
| **Semantic duplication detection** — two implementations of the same concern with different code | `CategoryService` static translation maps vs ARB-generated content; `ResolveLedgerTypeService` duplicates subset of `CategoryService` | HIGH | AI-agent review required; no automated Dart tool detects semantic clones reliably. DCM `check-code-duplication` catches exact and near-match token clones only |
| **Theme token duplication audit** — old `AppColors` aliases retained alongside Wa-Modern tokens | Confirmed: `lib/core/theme/app_colors.dart:60` and `lib/core/theme/app_text_styles.dart:171` have TODO markers for removal | LOW | grep for `// TODO: Remove after all screens are migrated` pattern; enumerate usage of legacy token names |
| **Drift unused-column detection** — table columns with no DAO getter/query reference | No automated Dart tool for this; requires AST cross-reference | HIGH | AI-agent review: cross-reference table column definitions with DAO query methods and repository usages |
| **Diff-based re-audit** — after a phase, re-scan only files touched by that phase's changes | Reduces re-audit time proportionally to phase scope | HIGH | Requires git diff integration; useful for large codebases; lower priority here (268 files is small enough for full rescan in < 30s) |
| **CI gate on finding count** — fail `flutter analyze`-style CI step if any CRITICAL or HIGH findings remain | Prevents regressions after the initiative is complete | MEDIUM | Wrap scan scripts in a shell script that exits non-zero if ISSUES.json contains severity=CRITICAL or severity=HIGH entries |
| **Test-coverage gap scanner** — identify source files touched by refactor with < 80% line coverage | Ensures every refactored file meets the ≥80% coverage mandate before the phase is closed | MEDIUM | `flutter test --coverage` → lcov.info → parse per-file coverage; compare against list of files modified in the phase's git diff |

### Anti-Features — Deliberately Excluded

| Anti-Feature | Why Tempting | Why to Exclude | What to Do Instead |
|--------------|-------------|----------------|-------------------|
| **Auto-fix at audit time** — automatically rewrite imports, move files, delete symbols during scan | Audit phase is discovery; auto-fix skips human review of each finding | Auto-fix conflates audit with remediation; a wrong auto-fix silently breaks behavior; behaviors must be verified by tests after each change | Log the suggested fix in the finding record; human (or separate fix agent) applies it with test verification |
| **Behavior-change suggestions** — "refactor this algorithm", "consolidate these two functions into a smarter one" | Sounds productive | Out of scope per PROJECT.md: pure structural refactor, zero behavior change. Behavior-change suggestions introduce risk without the audit pipeline having any way to verify correctness | Defer to a future "enhancement" initiative after cleanup is complete |
| **Performance profiling as an audit output** — flag slow queries, large widget rebuilds | CONCERNS.md has known performance issues | Out of scope: performance is not a target for this initiative. Mixing performance findings into the severity-ordered cleanup phases dilutes focus and invites scope creep | Capture performance concerns in CONCERNS.md; address in a separate performance initiative |
| **Security redesign suggestions** — "switch to X crypto primitive" | Security is always important | Out of scope per PROJECT.md: security cleanup is limited to enforcing existing rules (e.g., no direct `flutter_secure_storage` access), not redesigning crypto. The 4-layer stack is fixed | Enforce the existing crypto rules (boundary checks); surface violations as HIGH layer-violation findings |
| **Style linting beyond what `dart format` + `flutter analyze` enforce** — "rename this variable", "extract this magic number" | Useful for general code quality | Not part of the four debt categories this initiative targets; running style lints generates noise that obscures architectural findings | Keep `prefer_single_quotes` and other existing lint rules; do not add opinionated style rules as part of this pipeline |
| **Cross-feature dependency graph visualization** — generate a visual diagram of import relationships | Useful for documentation | Visualization is output, not a finding. It cannot be acted upon or counted toward zero-violations | If a diagram is wanted for docs, generate it separately; it is not part of the audit pipeline |
| **Incremental auto-deletion of deprecated files** | Tempting as a "safe" cleanup | Deletion of files must be preceded by confirming no runtime references exist (reflection, platform channels, build scripts); auto-deletion skips this verification | Dead-code scanner flags deprecated files as findings; human verifies and deletes per finding |

---

## Feature Dependencies

```
Severity Taxonomy (4 levels defined)
    └──required by──> Finding Record Schema
                          └──required by──> All Scanners (layer, dead code, provider, i18n, duplication)
                                                └──required by──> Findings Output (ISSUES.json + ISSUES.md)
                                                                      └──required by──> Severity-Ordered Presentation
                                                                                            └──required by──> Re-Audit / Zero-Finding Verification
                                                                                                                  └──enables──> CI Gate

Layer-Violation Scanner
    └──enhances──> Feature-to-Application Mapping Audit (catch use_cases/ inside features/)

Dead-Code Scanner (symbol level)
    └──complements──> Unused-File Scanner (file level)
    └──both feed──> Confidence Scoring (differentiator)

Duplicate-Provider Scanner
    └──depends on──> Finding Record Schema (to emit structured findings)

UnimplementedError Detector
    └──depends on──> Finding Record Schema

Misplaced-Provider Detector
    └──depends on──> Finding Record Schema

ARB Unused-Key Scanner
    └──independent of other scanners (i18n-specific toolchain)

Hardcoded-String Scanner
    └──independent (grep-based, no schema dependency for discovery; schema needed for output)

Test-Coverage Gap Scanner (differentiator)
    └──depends on──> git diff of each phase (which files were touched)
    └──depends on──> flutter test --coverage output
```

### Dependency Notes

- **Severity Taxonomy must be defined first:** Every scanner emits severity for each finding. If taxonomy is not agreed before scanning, findings cannot be merged or sorted. This is the only true blocking dependency.
- **Finding Record Schema must exist before any scanner outputs:** All scanners must emit into the same schema so ISSUES.json can aggregate across tools and AI-agent reviews.
- **Dead-code scanner and unused-file scanner are complementary, not redundant:** Symbol-level dead code (an exported class with no callers) and file-level dead code (an entire file with no importers) are separate axes. Both are needed.
- **Confidence scoring enhances dead-code findings but does not block them:** Can be added to the schema from day one as an optional field, defaulting to HIGH for private symbols, LOW for public symbols.
- **CI gate depends on re-audit:** The gate logic is trivial (exit non-zero on CRITICAL/HIGH count > 0), but only makes sense after the initiative proves the zero-finding state is achievable.
- **Test-coverage gap scanner depends on knowing which files changed:** It requires a git diff from the start of the phase, not a standalone scan. Integrate at phase-close, not at audit-open.

---

## Severity Taxonomy — Justified

Four levels (CRITICAL / HIGH / MEDIUM / LOW) are the industry standard used by Veracode, CodeHawks, OpenZeppelin, and Google's internal code review tooling. The justification for four (not three or five) in this context:

**Why not three (HIGH / MEDIUM / LOW):**
Architectural violations that would cause a rewrite if not addressed (domain importing data, use cases inside feature folders with direct infrastructure access) are categorically different from "this function is unused." Losing the CRITICAL tier means these get treated the same as polish items.

**Why not five (CRITICAL / HIGH / MEDIUM / LOW / INFO):**
Info-level findings (style notes, documentation gaps) are out of scope for this initiative. Adding an INFO tier creates noise in the findings file and tempts the initiative to address items outside the four target categories.

**Per-category severity assignments for this initiative:**

| Severity | Definition for This Initiative | Examples |
|----------|-------------------------------|---------|
| CRITICAL | Violates the fundamental architectural contract in a way that could silently break behavior during refactor; or creates a runtime failure risk if the finding is not addressed before the next phase | Domain layer importing Data layer; Use cases inside `features/` with direct infrastructure access (`lib/features/family_sync/use_cases/` confirmed); `appDatabaseProvider` throwing `UnimplementedError` without guaranteed override |
| HIGH | Violates a declared architectural rule that will cause copy-paste propagation or DI graph corruption, but does not immediately break runtime behavior | Presentation screen directly importing `infrastructure/` layer (bypassing application layer); deprecated service still wired into provider graph with `// ignore:` suppressions; duplicate repository provider definitions |
| MEDIUM | Accumulates technical debt that degrades maintainability or creates drift between code and documentation | Hardcoded CJK strings (~169 occurrences, violating i18n rule); unused ARB keys; parallel translation maps in `CategoryService`; legacy theme token aliases; test-coverage below 80% on refactored files |
| LOW | Isolated, non-propagating issues with no architectural impact | Unused private helper methods; unreachable code branches; orphaned test mock files (`*.mocks.dart` needing regeneration); single-site TODO markers for deferred UI stubs |

---

## MVP Definition — For the Audit Pipeline

The "launch" of the pipeline is Phase 1 of the initiative. The minimum it must produce before any fix work begins:

### Launch With — Phase 1 Audit Deliverables

- [x] Severity taxonomy documented (done above) — required before scanning
- [x] Finding record schema defined (JSON fields: `id`, `category`, `severity`, `file_path`, `line_start`, `line_end`, `description`, `rationale`, `suggested_fix`, `tool_source`, `confidence`) — required before scanning
- [ ] Layer-violation scan complete — automated (import path analysis) + AI-agent semantic review
- [ ] Dead-code scan complete — `dead_code_analyzer` or DCM `check-unused-code`
- [ ] Unused-file scan complete — DCM `check-unused-files`
- [ ] Deprecated-code scan complete — `flutter analyze` + grep for suppression directives
- [ ] Duplicate-provider scan complete — grep + AST analysis
- [ ] UnimplementedError-in-provider scan complete — grep
- [ ] Misplaced-provider scan complete — grep
- [ ] ARB unused-key scan complete — `remove_unused_localizations` or equivalent
- [ ] Hardcoded-string scan complete — grep for CJK Unicode ranges
- [ ] ISSUES.json produced (machine-readable, all findings)
- [ ] ISSUES.md produced (human-readable, severity-sorted, with suggested fix per finding)
- [ ] Finding count by severity established as baseline (zero-finding target set)

### Add After First Phase Completes (Phase 2+)

- [ ] Confidence scoring on dead-code findings — add as the dead-code scan is refined based on false positives discovered in Phase 1
- [ ] Test-coverage gap scanner — integrate at phase-close of each subsequent phase
- [ ] Feature-to-application layer mapping audit — AI-agent supplement after automated scan; catches the `features/family_sync/use_cases/` case

### Future (Post-Initiative)

- [ ] CI gate (CRITICAL/HIGH count = 0) — set up after the initiative proves zero findings is achievable
- [ ] Semantic duplication detection — AI-agent deep review; too expensive for the initial scan, useful for a post-initiative code quality review
- [ ] Diff-based re-audit — not needed for 268 files; revisit if codebase grows beyond ~1,000 files

---

## Feature Prioritization Matrix

| Feature | Value to Initiative | Implementation Cost | Priority |
|---------|--------------------|--------------------|----------|
| Severity Taxonomy + Schema | HIGH | LOW | P1 — unblocks everything |
| Layer-Violation Scanner | HIGH | HIGH | P1 — largest debt category |
| Dead-Code Scanner (symbols) | HIGH | MEDIUM | P1 — needed before any deletion |
| Unused-File Scanner | HIGH | LOW | P1 — trivial with DCM |
| Deprecated-Code Scanner | HIGH | LOW | P1 — grep + analyzer |
| Duplicate-Provider Scanner | HIGH | MEDIUM | P1 — confirmed violation exists |
| UnimplementedError Detector | HIGH | LOW | P1 — confirmed violation exists |
| Misplaced-Provider Detector | HIGH | LOW | P1 — architectural rule |
| ARB Unused-Key Scanner | MEDIUM | MEDIUM | P1 — ~3 confirmed dead keys + more likely |
| Hardcoded-String Scanner | MEDIUM | LOW | P1 — ~169 confirmed violations |
| ISSUES.json + ISSUES.md Output | HIGH | MEDIUM | P1 — required for all downstream phases |
| Severity-Ordered Presentation | HIGH | LOW | P1 — trivial once schema exists |
| Re-Audit Verification | HIGH | MEDIUM | P1 — the exit criterion |
| Confidence Scoring | MEDIUM | MEDIUM | P2 — add after first-pass false positives known |
| Feature-to-App Mapping Audit | HIGH | MEDIUM | P2 — supplement automated layer scan |
| Theme Token Duplication Audit | LOW | LOW | P2 — confirmed but bounded scope |
| Semantic Duplication Detection | MEDIUM | HIGH | P3 — AI-agent heavy, deferred |
| Drift Unused-Column Detection | MEDIUM | HIGH | P3 — no automated tool exists |
| CI Gate | HIGH | LOW | P3 — post-initiative, after zero-findings proved |
| Diff-Based Re-Audit | LOW | HIGH | P3 — 268 files too small to need this |
| Test-Coverage Gap Scanner | HIGH | MEDIUM | P2 — integrate at each phase close |

---

## Concrete Finding Examples

### Layer Violation (CRITICAL)

```json
{
  "id": "LV-001",
  "category": "layer_violation",
  "severity": "CRITICAL",
  "file_path": "lib/features/family_sync/use_cases/check_group_use_case.dart",
  "line_start": 3,
  "line_end": 5,
  "description": "Use case class lives inside lib/features/ and directly imports lib/infrastructure/. Use cases belong in lib/application/{domain}/, not in features/.",
  "rationale": "Thin Feature rule: features must not contain application/ or infrastructure/. This file also directly accesses infrastructure/crypto/services/key_manager.dart, bypassing the application layer.",
  "suggested_fix": "Move lib/features/family_sync/use_cases/check_group_use_case.dart to lib/application/family_sync/check_group_use_case.dart. Remove direct infrastructure imports; inject dependencies via constructor.",
  "tool_source": "ai_agent_semantic_review",
  "confidence": "HIGH"
}
```

### Layer Violation (HIGH)

```json
{
  "id": "LV-008",
  "category": "layer_violation",
  "severity": "HIGH",
  "file_path": "lib/features/accounting/presentation/screens/category_selection_screen.dart",
  "line_start": 7,
  "line_end": 7,
  "description": "Presentation screen imports lib/infrastructure/category/category_service.dart directly, bypassing the application layer.",
  "rationale": "Dependency flow must be: Presentation -> Application -> Domain <- Data <- Infrastructure. Screens must not import infrastructure directly.",
  "suggested_fix": "Expose CategoryService functionality through a use case in lib/application/accounting/ and inject via a Riverpod provider in use_case_providers.dart.",
  "tool_source": "import_path_analyzer",
  "confidence": "HIGH"
}
```

### Dead Code (MEDIUM)

```json
{
  "id": "DC-012",
  "category": "dead_code",
  "severity": "MEDIUM",
  "file_path": "lib/application/dual_ledger/resolve_ledger_type_service.dart",
  "line_start": 1,
  "line_end": 95,
  "description": "ResolveLedgerTypeService is annotated @Deprecated('Use CategoryService instead') and referenced only with // ignore: deprecated_member_use_from_same_package suppressions.",
  "rationale": "Deprecated code with active ignore suppressions is a dead-code signal that has not been completed. CategoryService already covers this functionality.",
  "suggested_fix": "Migrate all call sites in use_case_providers.dart to CategoryService.resolveLedgerType / resolveL1. Delete resolve_ledger_type_service.dart. Remove the ignore suppressions.",
  "tool_source": "deprecated_code_scanner",
  "confidence": "HIGH"
}
```

### Provider Hygiene (CRITICAL)

```json
{
  "id": "PH-001",
  "category": "provider_hygiene",
  "severity": "CRITICAL",
  "file_path": "lib/infrastructure/security/providers.dart",
  "line_start": 96,
  "line_end": 102,
  "description": "appDatabaseProvider is defined as @riverpod and throws UnimplementedError. Any code path that reaches this provider without the manual ProviderContainer override from main.dart will crash at runtime.",
  "rationale": "Providers must not throw UnimplementedError. The override pattern in main.dart is implicit and non-enforced by static analysis. A test or widget instantiating its own ProviderScope without the override will crash silently.",
  "suggested_fix": "Replace with a concrete provider that fails fast with a descriptive error, or restructure so the database is always provided through the override with a static assertion that the override is in place (integration test).",
  "tool_source": "unimplemented_error_detector",
  "confidence": "HIGH"
}
```

### Dead i18n Key (LOW)

```json
{
  "id": "I18N-003",
  "category": "dead_code",
  "severity": "LOW",
  "file_path": "lib/l10n/app_en.arb",
  "line_start": 1,
  "line_end": 1,
  "description": "ARB key 'ocrScan' is defined in all three locale files (app_en.arb, app_ja.arb, app_zh.arb) and generated into S class, but no Dart file calls S.of(context).ocrScan.",
  "rationale": "OCR module (MOD-004) is confirmed absent from the codebase. The key was added speculatively. Dead keys create translation maintenance overhead.",
  "suggested_fix": "Remove 'ocrScan', 'ocrScanTitle', 'ocrHint' from all three ARB files. Run flutter gen-l10n after removal. Re-add when the OCR screen is implemented.",
  "tool_source": "arb_unused_key_scanner",
  "confidence": "HIGH"
}
```

---

## Tooling Map

This initiative uses a hybrid pipeline: automated tools for exhaustive, fast pattern matching; AI-agent review for semantic/structural issues that text patterns cannot catch.

| Scan Type | Automated Tool | AI-Agent Supplement | Confidence Without AI |
|-----------|---------------|--------------------|-----------------------|
| Layer violations (import direction) | grep + AST import path analysis | YES — indirect violations, misclassified layers | MEDIUM (automated misses indirect) |
| Feature-vs-application misplacement | grep for `features/*/use_cases/` | YES — primary detector | LOW (needs semantic understanding) |
| Dead code (symbols) | `dead_code_analyzer` or DCM `check-unused-code` | MEDIUM — verify public symbols | HIGH for private; LOW for public |
| Unused files | DCM `check-unused-files` | NO — file-level is mechanical | HIGH |
| Deprecated symbols | `flutter analyze` + grep for `// ignore: deprecated_member_use` | NO | HIGH |
| Duplicate providers | grep for `@riverpod` + same return type | MEDIUM — catches non-obvious duplicates | MEDIUM |
| UnimplementedError in providers | grep | NO | HIGH |
| Misplaced providers | grep | MEDIUM — catches providers in unexpected files | HIGH |
| ARB unused keys | `remove_unused_localizations` or custom script | NO | HIGH |
| Hardcoded strings | grep for CJK Unicode + string literals | NO | HIGH |
| Semantic duplication | NONE | YES — primary detector | N/A |
| Drift unused columns | NONE | YES — primary detector | N/A |
| Theme token duplication | grep for TODO markers + legacy token names | NO | HIGH |

---

## Sources

- [riverpod_lint — Dart package](https://pub.dev/packages/riverpod_lint) — confirmed `riverpod_lint: ^2.6.4` already in this project's `dev_dependencies`
- [custom_lint — Dart package](https://pub.dev/packages/custom_lint) — base framework for Riverpod lint rules
- [clean_architecture_linter 1.0.8 — Dart package](https://pub.dev/packages/clean_architecture_linter/versions/1.0.8) — 33 rules for Clean Architecture enforcement; MEDIUM confidence on fit for this project's custom layer structure
- [dead_code_analyzer — Dart package](https://pub.dev/packages/dead_code_analyzer) — CLI tool for unused classes, functions, variables
- [DCM Check Unused Code](https://dcm.dev/docs/cli/code-quality-checks/unused-code/) — `check-unused-code`, `check-unused-files`, `check-code-duplication`; outputs JSON/checkstyle/codeclimate
- [remove_unused_localizations — Dart package](https://pub.dev/packages/remove_unused_localizations) — ARB unused-key detection
- [Dart Static Analysis Customization](https://dart.dev/tools/analysis) — official `analysis_options.yaml` reference
- [CodeHawks Severity Taxonomy](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) — CRITICAL/HIGH/MEDIUM/LOW four-level standard
- [NVD CVSS Vulnerability Metrics](https://nvd.nist.gov/vuln-metrics/cvss) — industry-standard severity framing
- Direct codebase inspection — `/Users/xinz/Development/home-pocket-app/lib/features/family_sync/use_cases/` confirmed with direct infrastructure imports; `lib/infrastructure/security/providers.dart:96-102` confirmed `UnimplementedError`; import analysis of `lib/features/*/presentation/` confirmed infrastructure direct-import violations

---

*Feature research for: Audit pipeline for Flutter/Dart codebase technical-debt cleanup*
*Researched: 2026-04-25*
