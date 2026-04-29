# Phase 8: Re-Audit + Exit Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 08-re-audit-exit-verification
**Areas discussed:** reaudit_diff contract + drift handling, AI semantic scan re-run scope, Coverage scope + guardrails permanence, Smoke test scope and artifact

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| reaudit_diff contract + drift handling | reaudit_diff.dart classification + exit-code semantics + report format | ✓ |
| AI semantic scan re-run scope | full re-run vs tooling-only re-run vs prompt-lock pre-validation | ✓ |
| Coverage scope + guardrails permanence | per-file gate input + 4 guardrails permanence mechanism | ✓ |
| Smoke test scope and artifact | golden-path checklist + golden tests vs informal verification | ✓ |

**User's choice:** All four areas selected (multi-select).
**Notes:** User added freeform note "后续用中文提问" — follow-up questions switched from English to Chinese with English preserved for technical terms.

---

## Area 1 — reaudit_diff contract + drift handling

### Question 1: Drift strictness when re-audit surfaces findings outside Phase-1 catalogue

| Option | Description | Selected |
|--------|-------------|----------|
| 零容忍：任何新 finding 都 exit 1 | Strictest reading of EXIT-02 — any non-baseline finding exit 1 immediately | |
| 分类报告 + 严格 exit | Three-counter output (resolved / regression / new); any non-zero in regression or new exits 1 | ✓ |
| 分类报告 + 分级 exit | regression exits 1, new finding warns but exits 0 (triage step) | |

**User's choice:** Classified report + strict exit.
**Notes:** Aligns with EXIT-02 literal wording while keeping CI logs / human triage usable. Counters always emitted regardless of exit code so failures are immediately diagnosable.

### Question 2: Baseline source for diff matching

| Option | Description | Selected |
|--------|-------------|----------|
| 当前 .planning/audit/issues.json | Live committed catalogue (50 findings, all closed, includes Phase 6 D-02 supplementary rows) | ✓ |
| Phase 1 close 时的 git snapshot | Strict Phase-1 baseline; treats Phase 6 D-02 supplementary rows as "new" | |
| 快照一份为 expected.json + 主仓库跳过 | Manual snapshot copy as audit-trail artifact | |

**User's choice:** Live `.planning/audit/issues.json`.
**Notes:** Single source of truth, no extra snapshot artifact. Phase 6 D-02 stable rows are legitimate baseline rows because they were committed with proper lifecycle fields.

---

## Area 2 — AI semantic scan re-run scope

### Question 1: Whether and how to re-run /gsd-audit-semantic agents

| Option | Description | Selected |
|--------|-------------|----------|
| 全部重跑 (全量 4 个 agent) | All 4 agents re-run end-to-end with locked Phase 1 prompts | ✓ |
| 只重跑 4 个自动化扫描器 | Skip AI scan; trust fix-phase scoping | |
| 重跑全部 + 需人工锁定 prompt 未变动 | Full re-run plus pre-flight grep verifying agent prompts unchanged since Phase 1 | |

**User's choice:** Full re-run of all 4 AI agents.
**Notes:** Literal reading of ROADMAP §Phase 8 "full audit pipeline." Output goes to `.planning/audit/re-audit/agent-shards/` to keep disjoint from the original Phase 1 set.

---

## Area 3 — Coverage scope + guardrails permanence

### Question 1: Per-file coverage gate scope post-Phase 8

| Option | Description | Selected |
|--------|-------------|----------|
| 扩大为 Phase 3-6 所有 touched files 并集 | New `cleanup-touched-files.txt` as union of Phase 3-6 plan-manifest files | ✓ |
| 广义化为所有 lib/ 非生成文件 | Glob lib/**/*.dart minus generated; broadest enforcement | |
| 保留 phase6-touched-files.txt + 文档说明 | No mechanism change; doc-note the historical scope | |

**User's choice:** Expand to Phase 3-6 union.
**Notes:** Literal "every file the refactor touches" reading from PROJECT.md. Old `phase6-touched-files.txt` retained on disk as historical record but unreferenced by `audit.yml`.

### Question 2: How to make 4 CI guardrails permanent

| Option | Description | Selected |
|--------|-------------|----------|
| 仅文档锁定 | ADR-011 + REPO-LOCK-POLICY.md note only; no audit.yml change | |
| 文档锁定 + audit.yml 代码上锁 | Warning comment + remove residual continue-on-error + lift `if: pull_request` | ✓ |
| 代码上锁 + branch protection 文档指引 | Same as option 2 plus admin-config note for required status checks | |

**User's choice:** Documentation lock + audit.yml code-side lock.
**Notes:** Lifting `if: pull_request` on the coverage job is the load-bearing change — prevents direct-to-main bypass of the 80% gate. Branch-protection configuration deferred (manual admin step, not Phase 8 deliverable).

---

## Area 4 — Smoke test scope and artifact

### Question 1: Test surface and delivery format

| Option | Description | Selected |
|--------|-------------|----------|
| 黄金路径 checklist + 你亲自跑 | SMOKE-TEST.md user-filled checklist; manual verification only | |
| 黄金路径 + 重点 widget golden test 补充 | Manual checklist + widget golden tests for high-risk surfaces | ✓ |
| 只跳领错误重现 + 你现堆口头确认 | Informal flutter run + verbal sign-off | |

**User's choice:** Golden-path checklist + key widget golden tests.
**Notes:** Goldens locked at post-cleanup state (pre-refactor cannot be recaptured since Phases 3-6 are on main). Goldens function as forward-locked regression baselines. Targeted at amount display, monthly report, transaction form, soul fullness card per Phase 5 D-17..D-20.

---

## Area 5 — Wrap-up

### Question 1: Additional considerations for CONTEXT.md

| Option | Description | Selected |
|--------|-------------|----------|
| 可以写 CONTEXT.md 了 | All decisions captured | |
| 补充 ADR-011 amendment 则 | Append rule for Phase 8 ADR-011 update | ✓ |
| 由 Phase 8 决定如何处理历史 phase6-touched-files.txt | Locked guidance on old artifact disposition | |

**User's choice:** Add ADR-011 amendment rule.
**Notes:** Phase 7 D-06 (ADR append-only) requires Phase 8 close to append `## Update YYYY-MM-DD: Re-audit Outcome` to ADR-011 with re-audit delta + smoke-test outcome + cleanup-touched-files.txt path + guardrails-permanence confirmation. Becomes Phase 8 D-08 in CONTEXT.md.

---

## Claude's Discretion

- Plan boundary / wave numbering inside Phase 8 (e.g., whether `reaudit_diff.dart` impl is its own plan).
- Format of the `cleanup-touched-files.txt` generator script (Bash + git log vs Dart subprocess).
- Specific list of 5-8 widget golden tests under D-07.
- Wording of ADR-011 `## Update` section (provided D-08 four required content items appear).
- Whether `08-SMOKE-TEST.md` checklist items are flat or nested.
- Naming of any helper scripts (match `audit_*.sh` precedent if added).
- Disposition of historical `phase6-touched-files.txt`: keep committed, optionally add header comment "Superseded by cleanup-touched-files.txt in Phase 8". No delete or rename.

## Deferred Ideas

- **GitHub branch-protection rule configuration** — documented in ADR-011 amendment as a manual admin step; not a Phase 8 deliverable.
- **markdown-link-check CI gate** — inherited deferral from Phase 7; out of cleanup initiative scope.
- **Pre-refactor visual reference capture** — unactionable since Phases 3-6 are already on main.
- **Module numbering drift D3** — already tracked in ADR-011 §"Out of Scope / Deferred" by Phase 7.
- **FUTURE-ARCH-01..04, FUTURE-TOOL-01..02** (REQUIREMENTS.md v2) — explicitly out of cleanup initiative scope.
