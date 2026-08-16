# Audit Finding Schema

**Locked:** 2026-04-25
**Phase 1**

This document is the source-of-truth contract for every audit finding emitted in Phase 1 and consumed by every subsequent fix phase (Phases 3–6) and the Phase-8 re-audit. The Dart code mirror is [`scripts/audit/finding.dart`](../../scripts/audit/finding.dart) — field names match 1:1 between this doc and that file.

A finding is the unit record of architectural / quality violations surfaced by the four tooling scanners (Plan 04) and the four AI semantic-scan agents (Plan 06), merged into the unified catalogue (`issues.json` / `ISSUES.md`) by `scripts/merge_findings.dart` (Plan 05).

---

## 1. Required Fields (11)

Every finding MUST include all 11 fields below (with the exception of `id`, which is null on raw shards and stamped by the merger). All keys in JSON output are `snake_case`.

| Field | Type | Required | Valid Values / Notes | Example |
|-------|------|----------|----------------------|---------|
| `id` | string | optional (null pre-merge) | `LV-NNN` / `PH-NNN` / `DC-NNN` / `RD-NNN` (zero-padded 3-digit). Stamped by `merge_findings.dart` (Plan 05) in deterministic sort order. Permanent once assigned. | `LV-014` |
| `category` | string | required | `layer_violation` / `provider_hygiene` / `dead_code` / `redundant_code` | `layer_violation` |
| `severity` | string | required | `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` (see §3) | `CRITICAL` |
| `file_path` | string | required | Repo-relative path. NEVER absolute (T-1-03-02 mitigation). NEVER `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**` (see §7). | `lib/features/family_sync/use_cases/sync_now.dart` |
| `line_start` | int | required | 1-indexed line number where the violation begins | `1` |
| `line_end` | int | required | 1-indexed line number where the violation ends; ≥ `line_start` | `1` |
| `description` | string | required | One-sentence statement of what's wrong. Imperative-mood, no leading hedge ("Possibly…"). | `use_cases/ inside features/ violates Thin Feature rule` |
| `rationale` | string | required | Why it matters. References `AGENTS.md`, `CLAUDE.md`, or an architecture document when applicable. | `Thin Feature rule (CLAUDE.md): features must not contain application/use_cases.` |
| `suggested_fix` | string | required | Concrete remediation step. Names the destination file/dir and the target Phase by number. | `Move to lib/application/family_sync/. Phase 3 fix.` |
| `tool_source` | string | required | One of the approved producer values (see §6). Drives dedupe priority in the merger. | `import_lint` |
| `confidence` | string | required | `high` (tool-flagged + structural rule match) / `medium` (conservative structural detection or strong code-anchored evidence) / `low` (AI-agent inference / pattern-similarity). Drives planner auto-accept vs triage-batch behavior. | `high` |

**Notes on `file_path`:** Audit scope is `lib/` Dart code only. No secrets, API keys, or PII enter findings (T-1-A phase-level threat-model carry-over). The merger normalizes any absolute path to repo-relative before writing `issues.json` (T-1-03-02 mitigation).

---

## 2. Lifecycle Fields (3)

Every finding tracks open/closed status for Phase-8 re-audit reconciliation.

| Field | Type | Notes |
|-------|------|-------|
| `status` | string | `open` (active), `closed` (resolved), or `accepted` (reviewed intentional / false positive). Phase 1 emits `open` for every finding. |
| `closed_in_phase` | string? | null until `status` flips to `closed`; e.g., `"3"` when CRIT items are closed in Phase 3. |
| `closed_commit` | string? | null until `status` flips to `closed`; full git SHA of the commit that closed the finding. Enables drilldown from `issues.json` to the fix diff. |

Fix phases update these three fields on the existing finding entry — they NEVER re-issue IDs (D-07 permanence rule).

---

## 3. Severity Taxonomy (AUDIT-05)

Four-level taxonomy with explicit phase mapping. Severity drives the order in which fix phases tackle findings: Phase 3 = CRITICAL, Phase 4 = HIGH, Phase 5 = MEDIUM, Phase 6 = LOW.

- **CRITICAL** — Layer violations breaking dependency rules + runtime-crash providers (`UnimplementedError`). Examples: Domain importing Data, `features/*/use_cases/` (Thin Feature breach), `appDatabaseProvider` `UnimplementedError`. These break the architecture's safety guarantees. **Fixed in Phase 3.**
- **HIGH** — Provider hygiene + architectural rule violations + deprecated service wiring. Examples: Presentation imports Infrastructure directly, duplicate `repository_providers.dart`, `keepAlive` regressions, `ResolveLedgerTypeService` remnants. **Fixed in Phase 4.**
- **MEDIUM** — Dead code, redundancy, i18n violations, theme-token debt. Examples: Hardcoded CJK strings, `CategoryService` naming collision, MOD-009 references. **Fixed in Phase 5.**
- **LOW** — Unused private members, stale `// ignore:` directives, missing Drift indices, debug `print()`. **Fixed in Phase 6.**

Severity is set by the producing scanner (tooling or agent) based on the rule that fired; the merger does NOT re-classify severity. If a tool flags something as CRITICAL but it doesn't actually break dependency rules, the rule should be re-tuned in the scanner — not silently downgraded by the merger (D-08 explicitness rule).

---

## 4. Stable-ID Scheme (D-06)

Stable IDs are essential for the Phase-8 re-audit critical path: a fix phase closing `LV-014` must be idempotent across re-runs.

**Format:** `<category-prefix>-<3-digit-zero-padded-sequence>`

**Category prefixes:**
- `LV` — **Layer Violations** (category=`layer_violation`)
- `PH` — **Provider Hygiene** (category=`provider_hygiene`)
- `DC` — **Dead Code** (category=`dead_code`)
- `RD` — **Redundant Code** (category=`redundant_code`)

**Width:** 3 digits → 999 IDs per category; comfortable headroom over confirmed violation volumes (~100–200 total per CONCERNS.md).

**Sequence assignment:** `merge_findings.dart` (Plan 05) sorts findings deterministically before stamping IDs:
1. `file_path` ascending (string compare)
2. `line_start` ascending (numeric compare)
3. Category-prefix priority for same `file_path` + `line_start`: `LV` < `PH` < `DC` < `RD`

This guarantees `LV-001`..`LV-NNN` are always assigned in the same order across re-runs given the same input shards.

**Permanence (D-07):** IDs are PERMANENT once assigned. Fix phases update the `status` / `closed_in_phase` / `closed_commit` fields on the existing entry; they do NOT re-issue IDs. Phase-8 re-audit produces a fresh shard set; `scripts/reaudit_diff.dart` matches new findings against Phase-1 IDs by the `(category, normalized_file_path, description)` triple, NOT by ID. A re-audit finding without a Phase-1 match = a regression / new finding.

### 4.1 Current observation and lifecycle reconciliation (HP-08)

`shards/` contains the authoritative current scanner observations. `agent-shards/`
is a historical semantic baseline and is never treated as a current observation.
The merger retains every historical finding: a closed finding remains auditable when
absent, and an open finding is changed to `closed` only when its owning
authoritative scanner completed successfully and no longer reports it. An incomplete
scanner run never changes lifecycle state. If a closed finding reappears in an
authoritative shard, it is reopened as `open` and stale closure metadata is removed.

`ISSUES.md` renders three separate catalogues: Active (`open`), Resolved
(`closed`), and Accepted (`accepted`), with counts at the top. Only the Active
catalogue is the remediation queue.

### 4.2 Duplication acceptance fingerprints (HP-08)

`duplication_allowlist.json` is a reviewable, narrow exception list for structural
clone findings. Each entry has exactly two repo-relative `files`, a detector-emitted
64-bit normalized clone `fingerprint`, and a human review `rationale`. A match marks
only that exact pair and content as `accepted`; changing either clone's normalized
source produces a new fingerprint and re-reports the finding as `open`. Directory or
path-wide ignores are prohibited.

### 4.3 Catalogue-pair transaction, recovery, and forensic repair (HP-32 / HP-33 / HP-36 / HP-38)

`issues.json` and `ISSUES.md` are one catalogue generation. The merger prepares
both exact byte streams plus old-output backups and SHA-256 digests in uniquely named
sibling temporary files. A restart with no journal may discard only those recognised
temporary names, so an interruption during preparation cannot strand a fixed-name
artifact or block the next audit. Before replacing either destination, the merger
publishes a flushed transaction journal by writing a separate temporary journal and
atomically renaming it; every journal state update uses the same protocol.

On every start, the merger recovers a valid journal before reading lifecycle history:
it completes the new pair only when every remaining new byte stream is verified,
otherwise restores the old pair from verified backups. A malformed journal, unknown
output digest, or bad backup fails closed without overwriting either catalogue. Once
the pair is verified, the merger atomically records the terminal `committed_new` or
`committed_old` state before deleting any recovery material. Terminal recovery first
verifies the committed pair and can therefore finish a cleanup interrupted after any
staged file or backup was deleted. Normal invocations leave no transaction artifacts
behind. The journal is deliberately ephemeral, so stable output byte determinism
remains limited to the two catalogue files.

Every merger invocation first opens the permanent root-local
`.merge-findings.lock`, obtains an OS kernel-held exclusive `RandomAccessFile`
lock, and keeps that file handle through recovery, transient cleanup, history
reading, validation, and publication. The lock path is never unlinked or
renamed: replacing it could split waiters across two inodes. The PID/token JSON
is diagnostic-only and is written after the kernel lock is acquired; it is
never used for lease expiry, PID reuse, `EPERM`, or stale-lock takeover.
Release only unlocks and closes the held handle. A crash releases the kernel
lock while leaving the ignored path/inode available for later waiters.

Malformed or otherwise untrusted journals still fail closed by default. An
operator may opt in once to `dart run scripts/merge_findings.dart
--repair-pair-transaction`. Before moving any root artifact, the merger writes
an atomically replaced (temp + flush + rename) forensic manifest in
`.merge-findings-forensics/` with a whitelist basename and SHA-256 for every
artifact. `isolating` resumes deterministically after a crash: an artifact is
either still at root and verified before moving, or is already in the
quarantine destination and verified there. Missing, duplicate, digest-mismatched,
path-traversing, malformed, or multiple pending manifests fail closed; unknown
root files are never moved.

Repair candidate discovery is keyed by the whitelisted artifact basename, rather
than a raw filesystem path string. The preselected pair journal is skipped while
enumerating the root, and manifest construction rejects a repeated basename as a
defense in depth. Therefore equivalent `--root` spellings (including a trailing
slash, `/.`, relative path, or symlink) cannot add a second record for the same
root artifact and leave a self-invalidating repair manifest.

After all verified moves, the manifest atomically transitions to
`isolated_pending_rebuild`. Ordinary later starts resume that pending repair
without a second opt-in. Before every rebuild attempt, each manifest entry must
exist only at its quarantine destination with its recorded SHA-256; the same
basename must be absent from the audit root. A missing, modified, or duplicate
entry fails closed and leaves the manifest pending. The merger then validates
existing lifecycle history and every canonical shard before rebuilding. Only
after the durable catalogue pair commit does the manifest atomically become
`complete`. Thus a crash before or after any move, manifest transition, or
rebuild cannot silently discard repair intent; catalogue outputs and unrelated
files remain untouched on failure.

For compatibility with HP-36 repair runs, schema version 1 manifests are read
only when they use the original `isolating` or `isolated` states, nonempty
reason, and a nonempty, unique list of whitelisted basename/SHA-256 entries.
An optional ISO-8601 `repaired_at` is accepted. Version-1 `isolating` resumes
the verified move state machine. Version-1 `isolated` is not treated as a
completed repair: the merger first proves the same quarantine-exclusive
invariant, then atomically rewrites it as version 2
`isolated_pending_rebuild`. Unknown, malformed, duplicate, or tampered version
1 intent fails closed.

---

## 5. Splits & Merges (D-08)

Splits and merges of findings are MANUAL planner bookkeeping — the merger script does NOT auto-detect them. Heuristics (e.g., textual similarity) could silently lose findings; D-08 is explicit on this.

**Split** — One Phase-1 finding becomes multiple findings during fix scoping:
- The original ID stays `open` until all children close.
- New IDs are added with a `split_from: <parent_id>` field.
- Example: `LV-014` covers a multi-file Thin-Feature breach. While planning Phase 3, the planner files `LV-201` (file A), `LV-202` (file B) with `split_from: LV-014`. `LV-014` closes only when both children close.

**Merge** — Multiple Phase-1 findings turn out to be the same root cause:
- Child IDs close with a `closed_as_duplicate_of: <parent_id>` field.
- The parent's `status` continues to be tracked normally.
- Example: `PH-014` and `PH-019` both arise from the same duplicated `repository_providers.dart`. After fix-scoping, `PH-019` closes with `closed_as_duplicate_of: PH-014`.

Both `split_from` and `closed_as_duplicate_of` are OPTIONAL fields on the finding record — the canonical Dart model in `scripts/audit/finding.dart` does not include them as typed fields because they are written by humans during planning, not by tooling. They appear in `issues.json` as additional keys when present.

---

## 6. Tool-Source Inventory

`tool_source` is the producer that emitted the finding. The merger uses `tool_source` for dedupe priority: when the same `(category, file_path, line_start)` triple is reported by both tooling and an agent, the tooling entry wins (higher confidence).

| `tool_source` | Producer | Confidence default | Phase / Plan |
|---------------|----------|--------------------|--------------|
| `import_lint` | `dart run import_lint` (analysis-server plugin plus CLI) → `audit_layer.sh` | `high` | 2026-08-06 Native Assets/toolchain upgrade |
| `owned_provider_contract` | Repository-owned provider app-root and held-lint contract (`scripts/audit/providers.dart` / `provider_contract.dart`) → `audit_providers.sh` | `high` | Phase 58 HP-06 |
| `dart_code_linter` | `dart_code_linter:metrics check-unused-{code,files}` → `audit_dead_code.sh` | `high` | Phase 1 Plan 04 |
| `owned_duplication_detector` | Repository-owned exact 16-line cross-file Dart clone detector → `audit_duplication.sh` | `medium` | HP-07 |
| `agent:layer` | AI subagent for indirect layer violations (transitive imports, type-alias smuggling) | `medium` | Phase 1 Plan 06 |
| `agent:duplication` | AI subagent for semantic duplication / parallel implementations | `low` | Phase 1 Plan 06 |
| `agent:transitive` | AI subagent for transitive imports across boundary layers | `medium` | Phase 1 Plan 06 |
| `agent:drift_col` | AI subagent for Drift unused-column detection | `low` | Phase 1 Plan 06 |

Each repository-owned scanner emits its identity only after its contract runs. In particular, `scripts/audit/providers.dart` emits `owned_provider_contract` with `scan_state: ran`; an exception writes `scan_state: not_run` with `scan_failed: true` and exits non-zero. HP-19 makes the merger fail closed: it accepts `providers.json` as lifecycle evidence only when its source is `owned_provider_contract`, its `scan_state` is `ran`, and it has not failed; any other state is incomplete, never a clean empty scan or a basis for closing findings.

**Current clarification (2026-08-06, HP-24):** `riverpod_lint` 3.1.0 is a locked, inactive compatibility hold for the Flutter 3.44.8/analyzer-8 graph, not the provider scanner. The owned contract guards both the inactive plugin configuration and its held lockfile version while protecting the app-root scope invariant. Do not activate or restore `riverpod_lint` as the scanner until the selected graph passes the real analysis-server bad-fixture versus `ProviderScope`/`UncontrolledProviderScope` control probe and the corresponding plugin/configuration guard; then update this inventory and the canonical merger source together.

---

## 7. Generated-File Exclusion

Defense-in-depth. The merger MUST drop any finding whose `file_path` matches one of the four patterns below. Scanners SHOULD also pre-filter, but defense-in-depth at the merger layer guarantees no generated-file finding ever reaches `issues.json` (T-1-03-03 mitigation; matches `analysis_options.yaml` `analyzer.exclude` plus `.mocks.dart` for the HIGH-07 mock-file regime).

- `**/*.g.dart` (build_runner code-gen)
- `**/*.freezed.dart` (Freezed code-gen)
- `**/*.mocks.dart` (mockito code-gen — currently 14 committed files; HIGH-07 territory)
- `lib/generated/**` (flutter_gen + ARB-generated `app_localizations.dart`)

Findings filed against generated files would be no-ops — fix phases cannot edit those files (Pitfall #1 in `CLAUDE.md`).

---

## 8. JSON Example

A representative pair of findings — one CRITICAL `LV-001` for the live `lib/features/family_sync/use_cases/` Thin-Feature breach, one MEDIUM `DC-001` for a hypothetical orphaned utility — demonstrating all 11 required fields plus the 3 lifecycle fields:

```json
[
  {
    "id": "LV-001",
    "category": "layer_violation",
    "severity": "CRITICAL",
    "file_path": "lib/features/family_sync/use_cases/sync_now_use_case.dart",
    "line_start": 1,
    "line_end": 1,
    "description": "use_cases/ inside features/ violates Thin Feature rule",
    "rationale": "Thin Feature rule (CLAUDE.md): features must not contain application/use_cases. Use cases live at lib/application/{domain}/.",
    "suggested_fix": "Move to lib/application/family_sync/sync_now_use_case.dart and rewire wiring provider in features/family_sync/presentation/providers/. Phase 3 fix.",
    "tool_source": "import_lint",
    "confidence": "high",
    "status": "open",
    "closed_in_phase": null,
    "closed_commit": null
  },
  {
    "id": "DC-001",
    "category": "dead_code",
    "severity": "MEDIUM",
    "file_path": "lib/shared/utils/legacy_color_helpers.dart",
    "line_start": 12,
    "line_end": 38,
    "description": "Public function `legacyHexToColor` has no remaining call sites",
    "rationale": "dart_code_linter:check-unused-code reports zero references after MOD-014 i18n migration superseded the legacy theme path.",
    "suggested_fix": "Delete `legacyHexToColor` and any helpers it transitively depended on; ensure no test under test/unit/shared/ still imports it. Phase 5 fix.",
    "tool_source": "dart_code_linter",
    "confidence": "high",
    "status": "open",
    "closed_in_phase": null,
    "closed_commit": null
  }
]
```

When `id` is null on a raw shard (pre-merge), the `toJson()` serialization in `scripts/audit/finding.dart` OMITS the key entirely (rather than emitting `"id": null`). The merger stamps a value before writing `issues.json`. Lifecycle fields `closed_in_phase` and `closed_commit` similarly omit when null.

---

## 9. Coverage Baseline Schema

**Locked:** 2026-04-25
**Phase 2**

This section is the source-of-truth contract for the four `tool/audit/coverage-*` artifacts consumed by the repository audit and release gates. The Dart code mirrors are [`scripts/coverage_baseline.dart`](../../scripts/coverage_baseline.dart) (producer) and [`scripts/coverage_gate.dart`](../../scripts/coverage_gate.dart) (consumer) — field names match 1:1 between this doc and those files.

The four artifacts are emitted in a single pass by `coverage_baseline.dart` reading `coverage/lcov_clean.info` (the `coverde filter`-stripped output of `flutter test --coverage`). Phase 2 is decoupled from Phase 1's `issues.json` (no `issue_ids` cross-link, per D-12). Fix-phase planners join on `file_path` lazily.

### 9.1 Common metadata block

The two JSON artifacts (`coverage-baseline.json`, `files-needing-tests.json`) share a top-level metadata block. All keys are `snake_case`.

| Field | Type | Required | Valid Values / Notes | Example |
|-------|------|----------|----------------------|---------|
| `generated_at` | string | required | ISO 8601 UTC timestamp. **Normalized by Phase-8 byte-compare** (D-12 idempotency carve-out). | `2026-04-25T15:30:00.000Z` |
| `flutter_test_command` | string | required | The exact `flutter test` invocation used to produce the input lcov. | `flutter test --coverage` |
| `lcov_source` | string | required | Repo-relative path to the input lcov consumed (default `coverage/lcov_clean.info`). | `coverage/lcov_clean.info` |
| `threshold` | int | required | The percentage threshold below which a file enters `files-needing-tests`. Default 80; parameterized via `coverage_gate.dart --threshold N` (D-02). | `80` |
| `total_files` | int | required | Count of non-generated source files in the input lcov (post-defense-in-depth filter). | `268` |
| `files_below_threshold` | int | required | Count of records where `percentage < threshold`. | `87` |

### 9.2 `coverage-baseline.txt`

TSV. No header. One record per line. Columns separated by literal `\t` (tab). Trailing newline.

Format: `<file_path>\t<lines_covered>/<lines_total>\t<percentage>`

- `percentage` formatted via `.toStringAsFixed(2)` (e.g., `44.44`)
- Records lex-sorted by `file_path` ASCENDING (D-10)
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`) excluded — defense-in-depth even though `coverde filter` strips them upstream

Example:
```
lib/core/theme/app_theme.dart	4/9	44.44
lib/features/accounting/domain/models/category.dart	2/2	100.00
lib/features/accounting/domain/models/transaction.dart	2/2	100.00
```

### 9.3 `coverage-baseline.json`

2-space-indented JSON. `snake_case` keys throughout.

Top-level shape: `{ ...metadata (§9.1), entries: [...] }`

Per-entry shape:

| Field | Type | Required | Valid Values / Notes | Example |
|-------|------|----------|----------------------|---------|
| `file_path` | string | required | Repo-relative source path. NEVER absolute. NEVER a generated-file pattern. | `lib/core/theme/app_theme.dart` |
| `lines_covered` | int | required | Lines hit (LH from lcov, or count of `DA:line,hits` where hits > 0 in fallback path). | `4` |
| `lines_total` | int | required | Lines instrumented (LF from lcov, or count of `DA:` lines in fallback path). | `9` |
| `percentage` | number | required | `(lines_covered / lines_total) * 100`. Held as double internally; not pre-rounded. JSON serializer emits with default precision. | `44.44444444444444` |
| `threshold_met` | bool | required | `percentage >= threshold` from metadata. | `false` |

`entries` array lex-sorted by `file_path` ASCENDING.

### 9.4 `files-needing-tests.txt`

Filtered view of `coverage-baseline.txt`: bare `<file_path>` per line, only records where `percentage < threshold`. No header. Trailing newline. Lex-sorted.

Example:
```
lib/core/initialization/app_initializer.dart
lib/features/accounting/data/repositories/transaction_repository_impl.dart
lib/features/family_sync/use_cases/sync_now_use_case.dart
```

Read directly by fix-phase planners during touched-files intersection (D-09).

### 9.5 `files-needing-tests.json`

Same top-level metadata as §9.1. Filtered `entries` array.

Per-entry shape:

| Field | Type | Required | Valid Values / Notes | Example |
|-------|------|----------|----------------------|---------|
| `file_path` | string | required | Repo-relative source path. | `lib/core/initialization/app_initializer.dart` |
| `percentage` | number | required | Same as §9.3. | `42.10` |
| `lines_below_threshold` | int | required | `lines_total - lines_covered`. The number of additional lines that must be hit to reach threshold (rough characterization-test sizing signal). | `19` |

`entries` lex-sorted by `file_path` ASCENDING. Note that `lines_below_threshold` is a derived sizing signal — fix-phase planners use it to bucket characterization-test effort (small-N → quick wins; large-N → likely needs decomposition before tests can be written).

### 9.6 Idempotency invariant (D-12)

Re-running `scripts/coverage_baseline.dart` against the same `coverage/lcov_clean.info` produces byte-identical artifacts EXCEPT the `generated_at` metadata field in the two JSON outputs. Phase 8's re-audit byte-compares the new baseline against the Phase-2 baseline to prove the cleanup raised coverage; the byte-compare normalizes `generated_at` first.

### 9.7 Decoupling from `issues.json` (D-12)

The Phase-2 JSON artifacts do NOT carry `issue_ids` cross-references to `issues.json`. Phase 2 is concerned with coverage; Phase 1 is concerned with violations. Fix-phase planners join the two lazily on `file_path` — a one-line operation against existing artifacts. This decouples Phase 2's lifecycle from Phase 1's catalogue evolution.

### 9.8 Frozen baseline (D-08)

`coverage-baseline.{txt,json}` and `files-needing-tests.{txt,json}` are FROZEN at Phase 2 and regenerated only at Phase 8 (re-audit). No mid-initiative refresh. The Phase 2 lists are the canonical "before" image; the Phase 8 lists are the canonical "after" image; the diff is the empirical evidence that the cleanup raised coverage.

---

## Files Referenced

- `scripts/audit/finding.dart` — Dart code mirror; field names match this doc 1:1
- `AGENTS.md` — Current architecture boundaries and repository rules
- `docs/arch/` — Architecture specifications and decisions
- `analysis_options.yaml` — `analyzer.exclude` baseline that §7 extends with `.mocks.dart`
- `CLAUDE.md` — "Common Pitfalls" list whose 13 categories the audit pipeline catches
- `scripts/coverage_baseline.dart` — Producer of the four §9 artifacts (Phase 2)
- `scripts/coverage_gate.dart` — Consumer of `lcov_clean.info` + `files-needing-tests.txt` (Phase 2; CI integration deferred to Phase 7/8 per D-06)
- `scripts/coverage/lcov_parser.dart` — Shared lcov parser used by both
