# ADR-011: Codebase Cleanup Initiative Outcome

**文档编号:** ADR-011
**文档版本:** 1.1
**创建日期:** 2026-04-27
**最后更新:** 2026-04-28 (append-only Update 章节; 见文末)
**状态:** ✅ 已接受
**决策者:** Architecture Team
**影响范围:** 全局重构（Phases 3–6）, CI 守门, 测试基础设施
**相关 ADR:** ADR-002 (Database Solution), ADR-007 (Layer Responsibilities), ADR-008/009/010 (实施推迟)

---

## 📋 状态

**当前状态:** ✅ 已接受
**决策日期:** 2026-04-27
**实施状态:** 已完成 (Phases 3–6 已落地)

---

## 🎯 背景 (Context)

2026年初，项目审计发现代码库积累了大量架构债务：层职责混乱、死代码、Riverpod卫生问题，以及测试覆盖率不足。为系统清理这些问题，项目启动了一个6阶段的清理计划（Phase 3–6），在零行为变更（no-behavior-change）的约束下专注于结构修正。

Phase 7（本文档所在阶段）完成了配套的文档扫描，将 `docs/arch/` 中的架构文档与清理后的 `lib/` 目录树对齐。Phase 8 将做最终的重审计验证。

本 ADR 记录三项在 Phases 3–6 中产生的**持久决策**：

1. **`*.mocks.dart` 策略** — 在 Phase 4-04 中做出的 Mocktail 大爆炸迁移选择
2. **常驻 CI 守门** — 8 个 CI 门禁，在 Phase 8 及以后持续执行
3. **清理结果** — 按阶段的发现关闭统计

未来的贡献者应能通过本 ADR 理解：(a) 清理做了什么，(b) CI 现在永久执行什么，(c) 还有什么遗留在积压中。

---

## 🔍 考虑的方案 (Considered Options)

### 清理方案

**采用方案（已实施）：** 按严重程度分阶段清理（CRITICAL → HIGH → MEDIUM → LOW → 文档扫描 → 重审计），每阶段设退出门禁（exit gate）。

**拒绝的备选方案：**
- **合并阶段**：一次性处理所有问题 — 拒绝，因为混合严重程度使得审查困难，且无法形成稳定的中间快照
- **逐阶段更新文档**：每修复一个阶段就更新一次文档 — 拒绝，文档更新开销高且会分散修复工作的注意力；推迟到 Phase 7 集中处理
- **不写集中 ADR**：分散在各阶段 SUMMARY 中记录 — 拒绝，未来贡献者无法从单一入口点理解 CI 守门机制的全貌

### `*.mocks.dart` 策略

**采用方案（Phase 4-04）：** Mocktail 大爆炸迁移——移除所有 `*.mocks.dart` 文件和 mockito，改用 `mocktail` 包（`pubspec.yaml`: `mocktail: ^1.0.4`）。

**拒绝的备选方案：**
- **CI 生成 mockito mocks**：继续用 `@GenerateMocks` 但在 CI 中重新生成 — 拒绝，因为 `*.mocks.dart` 提交到仓库会使 AUDIT-10（stale-diff 门禁）永远触发警告，且阅读生成的 mock 类比 mocktail 的 inline stub 难度更高
- **保持 mockito 现状**：不迁移 — 拒绝，mockito 生成文件是技术债务的来源之一（HIGH-07）

---

## ✅ 决策 (Decision)

### A. `*.mocks.dart` 策略

**决策：** 选择 Mocktail 大爆炸迁移（Phase 4-04）。

在 Phase 4-04 中，所有 13 个 `*.mocks.dart` fixture 文件被删除，`mockito` 依赖被移除，所有测试改用 `mocktail ^1.0.4`（见 `pubspec.yaml`）。

来自 `.planning/STATE.md`（Blockers/Concerns 节）的决策记录：

> `*.mocks.dart` strategy (CI-generated vs Mocktail migration) must be decided before Phase 4
> (interface changes happen there) — SUMMARY.md recommends Mocktail

**计划路径：** `.planning/phases/04-high-fixes/04-04-mocktail-bigbang-migration-PLAN.md`

**关键理由：**
- Mocktail 消除了生成噪声（无 `*.mocks.dart` 提交，AUDIT-10 不再发出警告）
- 测试代码更易读（inline stub 替代 `@GenerateMocks` + 生成类）
- 与 import_guard 和 riverpod_lint 无冲突

### B. Ongoing CI Enforcement

以下 8 个 CI 门禁在 `.github/workflows/audit.yml` 中常驻，作用于每个 PR 和 main 分支推送：

| Gate | File:Line | Purpose |
|------|-----------|---------|
| flutter analyze | `.github/workflows/audit.yml:38` | 类型检查 + lint（`--no-fatal-infos`） |
| dart run custom_lint | `.github/workflows/audit.yml:41` | import_guard 层违规 + riverpod_lint |
| AUDIT-09 SQLCipher 拒绝 | `.github/workflows/audit.yml:70-75` | 阻止 `sqlite3_flutter_libs` 进入 `pubspec.lock` |
| AUDIT-10 build_runner 差异 | `.github/workflows/audit.yml:79-84` | 阻止带过期生成文件的 PR 合并 |
| coverde filter | `.github/workflows/audit.yml:100-105` | 从 `lcov.info` 中剥离生成文件，生成 `lcov_clean.info` |
| very_good_coverage ≥80% | `.github/workflows/audit.yml:108` | 全局覆盖率门禁，针对 `lcov_clean.info`，`min_coverage: 80` |
| 架构测试 test/architecture/ | `flutter test test/architecture/`（CI coverage step） | domain_import_rules + provider_graph_hygiene + service_name_collision + production_logging_privacy 等 |
| 每文件覆盖率门禁 | `scripts/coverage_gate.dart`（CI coverage step） | 对 `phase6-touched-files.txt` 中的文件强制 ≥80% 覆盖率 |

**import_guard.yaml 5层规则**（`dart run custom_lint` 门禁的子集）：
- `lib/import_guard.yaml`
- `lib/application/import_guard.yaml`
- `lib/data/import_guard.yaml`
- `lib/features/import_guard.yaml`
- `lib/infrastructure/import_guard.yaml`

### C. Cleanup Outcome

**发现统计（按阶段关闭）：**

| 阶段 | 严重程度 | 关闭数量 | 主要修复内容 |
|------|----------|----------|-------------|
| Phase 3 | CRITICAL | 24 | 层集中化（use_cases/repositories 迁移到 lib/application/ 和 lib/data/）、analyzer 警告清零、CategoryService 重命名、ResolveLedgerTypeService 删除 |
| Phase 4 | HIGH | (见下注) | Mocktail 大爆炸（HIGH-07）、schema 版本迁移测试、覆盖率基线 |
| Phase 5 | MEDIUM | 8（MED-01..MED-08） | ARB 覆盖率对等、硬编码 CJK 标签本地化、CategoryService 重命名执行 |
| Phase 6 | LOW | 24（DC-001..DC-024） | 死代码删除（未使用文件、未使用 import）、日志隐私清理 |

> **注：** `.planning/audit/issues.json` 跟踪了 50 项自动发现（CRITICAL 24 + MEDIUM 2 + LOW 24）。Phase 4 的 HIGH 发现通过 `.planning/ROADMAP.md` 的 `HIGH-01..HIGH-NN` 条目追踪，未全部包含在 issues.json 中。总体 87 项 finding 的统计来自 ROADMAP 计划条目（含手动分类的 HIGH 条目）。

**文件级变更（Phases 3-6 汇总）：**
- 层集中化：`lib/application/` 新增 Use Case 文件；`lib/data/repositories/` 汇聚所有 Repository 实现
- 重命名：`category_service.dart` → `category_locale_service.dart`（`lib/infrastructure/category/`）
- 删除：`ResolveLedgerTypeService`、13 个 `*.mocks.dart` 文件、多个未使用的 dead-code 文件
- 数据库 schema：v14 → v15（Phase 6-02，添加索引）

详细变更见 `.planning/phases/03-critical-fixes/`、`04-high-fixes/`、`05-medium-fixes/`、`06-low-fixes/` 目录下各计划的 SUMMARY.md。

---

## 🤔 决策理由 (Rationale)

### 为什么选 Mocktail 而非 mockito

1. **无生成噪声：** Mocktail 的 stub 在测试代码中内联定义，不需要 `@GenerateMocks` 注解和生成的 `*.mocks.dart` 文件。AUDIT-10 stale-diff 门禁在提交后无需担忧。
2. **可读性：** 阅读 `MockTransactionRepository` 的 inline stub 比理解 `GeneratedMockTransactionRepository` 的生成类更直观。
3. **维护成本低：** 删除一个接口方法后，编译器会立即报错指向 stub；不需要重新运行 code generation。

### 为什么集中在一个 ADR 中

三个子主题（清理结果 + `*.mocks.dart` 策略 + CI 守门）是强相关的：CI 守门的动机来自清理发现的问题，`*.mocks.dart` 决策是 CI AUDIT-10 的直接输入。拆分成三份 ADR 会使未来的贡献者需要跨多个文件才能理解完整上下文。

### 为什么审计驱动而非功能驱动

Phases 3–6 的核心约束是"零行为变更"——每个 commit 只能改善结构/测试/工具，不能改变应用逻辑。审计驱动的发现目录（`issues.json`）提供了可追溯的退出标准：当所有 CRITICAL/HIGH/MEDIUM/LOW 发现都关闭时，该阶段结束。功能驱动的方式无法提供同等清晰的完成信号。

---

## 🔄 后果 (Consequences)

**Positive:**
- CI 守门将以前的手动检查机械化：analyzer 0 警告、import 层规则、SQLCipher 强制、build_runner 同步、≥80% 覆盖率
- 未来的 PR 在到达人工 review 之前就能在 CI 中被自动拦截
- `*.mocks.dart` 的删除减少了仓库中的生成文件噪声

**Negative:**
- CI 门禁数量增加（8个）意味着绿色 CI 所需时间略长
- Pitfall 4（mutation）、7（Podfile EXCLUDED_ARCHS）、9（widget 硬编码默认值）、11（Drift 索引语法）仍然是手动检查项，没有机械执行——见 `CLAUDE.md` Common Pitfalls 注释

**Neutral:**
- ADR 数量增加到 11 个；ADR-000_INDEX.md 维护负担 +1 条目
- ADR-008/009/010 在清理期间没有被实施（仍为"已接受但待实施"状态）

---

## 📋 实施计划 (Implementation Plan)

实施已完成。各阶段详情见以下计划目录：

- Phase 3（CRITICAL）：`.planning/phases/03-critical-fixes/`
- Phase 4（HIGH）：`.planning/phases/04-high-fixes/`（含 `04-04-mocktail-bigbang-migration-PLAN.md`）
- Phase 5（MEDIUM）：`.planning/phases/05-medium-fixes/`
- Phase 6（LOW）：`.planning/phases/06-low-fixes/`
- Phase 7（文档扫描）：`.planning/phases/07-documentation-sweep/`（本计划）

Phase 8（重审计验证）：待执行——将重新运行完整审计脚本，确认 `issues.json` 中零活跃发现。

---

## 📝 Out of Scope / Deferred

以下条目在 Phases 3–6 清理范围之外，已记录到 `.planning/STATE.md` 的 "Deferred Items" 一节：

- **FUTURE-ARCH-01：** ARB 驱动的 CategoryLocaleService（消除 735 行静态映射表）
- **FUTURE-ARCH-03：** DCM 升级（付费审计工具）
- **FUTURE-ARCH-04：** `recoverFromSeed()` 密钥覆写 bug 修复
- **FUTURE-TOOL-01：** riverpod_lint 3.x 升级（受 json_serializable analyzer 冲突阻塞）
- **FUTURE-TOOL-02：** Drift 未使用列检测自定义脚本
- **ADR-008/009/010 实施状态：** 这三份 ADR 在清理期间未被实施；它们仍然是"已接受 / Phase N 后评估"的设计决策，不是 v1 代码
- **MOD 编号漂移（D-02）：** `02-module-specs/` 目录中文件名编号与内部标题编号不一致的问题是预先存在的；Phase 7 不修改 MOD 文件名（会破坏所有外部书签），已提升到 FUTURE-DOC 积压
- **markdown-link-check CI 门禁：** 自动检测 docs/ 中的断链——推迟到 Phase 8（重审计）或 FUTURE-TOOL 积压

---

## Update 2026-04-28 — Re-audit Outcome

**Cross-reference:**
- Re-audit catalogue: [`.planning/audit/re-audit/issues.json`](../../../.planning/audit/re-audit/issues.json)
- Re-audit diff: [`.planning/audit/re-audit/REAUDIT-DIFF.md`](../../../.planning/audit/re-audit/REAUDIT-DIFF.md) ([`REAUDIT-DIFF.json`](../../../.planning/audit/re-audit/REAUDIT-DIFF.json))
- Smoke test artifact: [`.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md`](../../../.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md)
- Gate verification log: [`.planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md`](../../../.planning/phases/08-re-audit-exit-verification/08-06-GATES-LOG.md)
- Per-file gate input: [`.planning/audit/cleanup-touched-files.txt`](../../../.planning/audit/cleanup-touched-files.txt)
- Per-file gate deferrals: [`.planning/audit/coverage-gate-deferred.txt`](../../../.planning/audit/coverage-gate-deferred.txt)
- Repo-lock policy: [`.planning/audit/REPO-LOCK-POLICY.md`](../../../.planning/audit/REPO-LOCK-POLICY.md)

The Codebase Cleanup Initiative reached its terminal gate on 2026-04-28. The 1.0 decision body above is preserved verbatim per ADR append-only convention (`.claude/rules/arch.md:162`); the metadata header was bumped 1.0 → 1.1 and given a 最后更新 line (frontmatter-only edit, decision content untouched).

This Update section documents the close honestly. The cleanup did NOT land exactly the way Plan 08 Wave-1 planning anticipated — Phase 8 close required two amendments (coverage-threshold and gate-deferral) plus an intentional deferral of human-driven smoke testing to v1 release. All four layers below are recorded so future maintainers see the original intent AND the runtime adaptations.

### Layer 1 — Original 8-plan flow (Plans 08-01 through 08-06 + 08-08)

| Plan | Output | Status |
|------|--------|--------|
| 08-01 | `scripts/reaudit_diff.dart` strict-exit gate + 9-test subprocess suite | landed (commit lineage `dc9394b` and prior) |
| 08-02 | `cleanup-touched-files.txt` (170 entries — Phase 3-6 PLAN.md `files_modified` frontmatter union) replaces `phase6-touched-files.txt` (19 entries) as per-file gate input | landed |
| 08-03 | `audit.yml` hardening — top-of-file warning header, removed `if: pull_request` from coverage job, zero `continue-on-error` flags; REPO-LOCK-POLICY.md "Phase 8 Close — Permanent Gates" section appended | landed |
| 08-04 | 6 widget golden tests in `test/golden/` (forward-lock per Phase 8 D-07) | landed |
| 08-05 | Full re-audit (4 automated scanners + 4 AI semantic-scan agents) re-run end-to-end on the post-cleanup tree per Phase 1 D-01 + Phase 8 D-03 | **GREEN** |
| 08-06 | Local execution of all 8 EXIT-04 gates (commit `2f206ba`, 80% threshold) | **4 of 8 FAIL** — surfaced for user review |
| 08-08 | This Update section | landing now |

**Re-audit delta (08-05 output, gate GREEN at commit `c1b3052…2f206ba` window):**

| Counter | Value |
|---------|-------|
| Resolved | 50 |
| Regression | 0 |
| New | 0 |
| Open in baseline | 0 |

`reaudit_diff.dart` exits 0. EXIT-01 + EXIT-02 satisfied. The 50 resolved findings break down as 24 CRITICAL (layer violations + use_cases misplacements), 2 MEDIUM (RD-001/002 dual-CategoryService), and 24 LOW (DC-001..024 dead code). HIGH-tier findings are tracked separately in ROADMAP.md (HIGH-01..NN) per the note in §C of the original 1.0 decision.

**08-06 first-run failure — surfaced honestly:** Gate 2 (`dart run custom_lint`) failed on 28 riverpod_lint INFO findings; Gate 3 + Gate 4 failed because global coverage on `lcov_clean.info` came in at 74.6336% — ~5pp short of the 80% target inherited from Phase 2 (BASE-06 / D-05); Gate 8 (`coverage_gate.dart` per-file ≥80%) failed on 11 real <80% files plus 96 missing-from-lcov entries. The original Plan 08-08 cited a gate-pass world. The actual world surfaced four gate failures that needed user adjudication before this Update could be written truthfully.

### Layer 2 — Coverage threshold amendment (commits `03b1a06` + `95b8aa6`)

User decision after the 4-gate failure (option 3 from the Wave-2 review): lower the active threshold 80% → 70% to match post-cleanup reality (74.6336%). Revisit either a uniform raise back toward 80% OR a per-area split (infrastructure/data ≥80%, presentation ≥70%, generated/glue exempt) after v1 feature work completes. Tracked as **FUTURE-TOOL-03** (`coverage-baseline-review`) in `.planning/REQUIREMENTS.md`.

**Concrete edits applied (commit `03b1a06`):**
- `.github/workflows/audit.yml`: `min_coverage: 80 → 70` (very_good_coverage step) and `coverage_gate.dart --threshold 80 → 70` (per-file gate step). Top-of-file warning comment updated to record threshold history.
- `scripts/coverage_baseline.dart`: const `_threshold = 80 → 70`.
- `scripts/coverage_gate.dart`: default `threshold = 80 → 70` (CI passes `--threshold` explicitly; default only governs local runs).
- `test/scripts/coverage_baseline_test.dart`: assertion updated `j['threshold'] == 80` → `== 70`.

**Governance edits:**
- `.planning/REQUIREMENTS.md`: "Amendments" section added at the top recording the change; EXIT-03/EXIT-04 reworded to 70%; EXIT-04 reset to Pending pending re-run.
- `.planning/audit/REPO-LOCK-POLICY.md`: "Update 2026-04-28 — Coverage threshold 80% → 70%" appended.
- `.planning/ROADMAP.md`: Phase 8 success criteria threshold updated 80 → 70.

**Historical wording deliberately preserved at 80%:** Phase 2 BASE-04..06 and per-phase fix-phase wording (CRIT-05, HIGH-08, MED-08, LOW-07) describe what those phases delivered against at the time. The amendment governs *forward*, not retroactively — the audit trail of "Phase 4 closed at ≥80% on touched files" is intentionally not rewritten.

**Re-run at 70% (commit `95b8aa6`):** Gates 3 + 4 flipped FAIL → PASS at 74.6336%. Gates 1, 5, 6, 7 unchanged (threshold-independent). **Gate 2 + Gate 8 still red** — both threshold-independent. 6 of 8 gates pass.

### Layer 3 — Gate 2 + Gate 8 close (commits `436ccab` + `36dfacd`)

After the threshold amendment, two EXIT-04 gates were still red. User-directed surgical fixes per Wave-2 review option 1 + option B:

**Gate 2 (`dart run custom_lint`) — close via `--no-fatal-infos` flag (`436ccab`):**
- `.github/workflows/audit.yml:55` switched from `dart run custom_lint` to `dart run custom_lint --no-fatal-infos`. Parity with `scripts/audit/{layer,providers}.dart` which already used the flag in Wave-1 plans.
- The load-bearing `import_guard` rule (one of the four guardrails, applied via `custom_lint`) still **hard-fails on errors** regardless. INFO-severity findings from `riverpod_lint` (28 of them, all `avoid_manual_providers_as_generated_provider_dependency` or `scoped_providers_should_specify_dependencies`) now surface but no longer block CI.
- The 28 INFO findings are tracked under FUTURE-TOOL-03 alongside the threshold review — they reflect Phase-4 provider-graph patterns that were intentionally not refactored during the cleanup (scope-discipline call), not a new regression.

**Gate 8 (`coverage_gate.dart` per-file ≥70%) — close via two changes (`36dfacd`):**

Part A — missing-from-lcov files reclassified WARN-only:
- `scripts/coverage_gate.dart` no longer treats files supplied to the gate but absent from `coverage/lcov_clean.info` as 0% / FAIL. They surface on stderr as `WARNING:` lines and contribute a `missing` count to the JSON output but do not affect exit code.
- Rationale: the 96 missing-from-lcov entries are correctly filtered by `coverde` (`*.g.dart`, `*.freezed.dart`, `*.arb`, `import_guard.yaml`, files no test exercises) — these are scope-boundary issues, not coverage failures. Plan 08-02 D-04 explicitly chose to keep `cleanup-touched-files.txt` as a literal mirror of plan `files_modified` frontmatter and let downstream tooling filter; that choice's runtime cost is the WARNING noise, which is now silent in exit code.

Part B — new `--deferred <path>` flag:
- File format: `<relative_path>  # <rationale>`. Rationale is **REQUIRED** — entries without one cause `coverage_gate.dart` to exit 2 (CLI-level error, not gate failure).
- Deferred entries skip the threshold check, surface on stderr as `DEFERRED:` lines, and appear under a `deferred` key in JSON output.
- `.planning/audit/coverage-gate-deferred.txt` initial population: 10 entries.
  - 3 application provider-wrappers (`lib/application/{ml,profile,voice}/repository_providers.dart`) — `.g.dart` half is filtered by coverde; the hand-written half is plumbing with minimal branching. Tests would mock the providers, adding noise without catching real bugs.
  - 4 large UI screens (`transaction_entry_screen` 46%, `transaction_confirm_screen` 63%, `analytics_screen` 53%, `create_group_screen` 18%) — real test gaps; need widget/integration tests beyond the cleanup's refactor scope.
  - 3 state notifiers / widget sections (`state_sync` 62%, `state_shadow_books` 35%, `appearance_section` 60%) — moderate coverage gaps in widget-adjacent state code.

**Discipline preservation:** The deferral mechanism is NOT a soft-fail flag. CI still hard-fails on:
- Any `lib/` file in `cleanup-touched-files.txt` that is in `lcov_clean.info` AND below 70% AND NOT in `coverage-gate-deferred.txt`.
- Any deferred-list entry without a written rationale.

Each deferred entry is tied to FUTURE-TOOL-03. The contract: at the post-feature-work review, each entry is either retired (tests added) or formalized into a per-area threshold split that subsumes it.

**Final 8-gate verdict (commit `36dfacd`, threshold 70):**

| Gate | Verdict | Output |
|------|---------|--------|
| 1 — `flutter analyze --no-fatal-infos` | PASS | 0 errors |
| 2 — `dart run custom_lint --no-fatal-infos` | PASS | 28 INFOs surface, non-blocking |
| 3 — global ≥70% on `lcov_clean.info` | PASS | 74.6336% |
| 4 — `very_good_coverage@v2 min_coverage: 70` | PASS | same arithmetic as Gate 3 |
| 5 — `import_guard` via custom_lint | PASS | 0 violations (hard-failing rule) |
| 6 — `dart_code_linter:metrics check-unused-code lib` | PASS | 0 findings across 324 files |
| 7 — `build_runner build && git diff --exit-code lib/` | PASS | clean diff |
| 8 — `coverage_gate.dart --deferred ... --threshold 70` | PASS | `64 checked / 0 failed / 96 missing-from-lcov (skipped) / 10 deferred (skipped)` |

**ALL 8 GATES PASS SIMULTANEOUSLY.** EXIT-03 + EXIT-04 marked complete in REQUIREMENTS.md.

### Layer 4 — Smoke test deferral (commit `d040c12`)

Plan 08-07 produced `.planning/phases/08-re-audit-exit-verification/08-SMOKE-TEST.md` — an 8-section × 34-checkbox owner-driven checklist covering transaction CRUD on both ledgers, ledger switch, monthly report currency formatting, settings backup/import, family sync push/pull, voice input, locale switch (ja → zh → en), and ARB-driven UI text spot-check; plus a Sign-off block (tester / ISO date / commit hash / build platform / verdict).

The checklist file lives in the repo with **34 empty checkboxes and an empty Sign-off block** by design. User directive after Plan 08-07 Task 1 produced the artifact: skip the human-execution side at Phase 8 close, move it to v1 release gate as the project owner's responsibility. Tracked as **FUTURE-QA-01** (`smoke-test-owner-driven`) in REQUIREMENTS.md v2 backlog.

ROADMAP success criterion 4 was amended on 2026-04-28: the artifact (the checklist) is the Phase 8 deliverable; behavior verification on a real build is the v1 release gate. The cleanup initiative closes on the discovery+remediation contract evidenced by Layers 1-3, not on perfect-as-released proof.

**At v1 release** the owner runs `flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs && flutter run`, walks the 8-section checklist, ticks boxes, records any SMOKE-NN findings in `.planning/audit/re-audit/issues.json`, re-runs `dart run scripts/reaudit_diff.dart` to confirm the gate stays GREEN, fills the Sign-off block, and commits the completed file. If smoke uncovers a regression, that becomes a follow-up bug-fix phase — it does not retroactively reopen the cleanup initiative.

### Permanent CI guardrails (4)

Per Phase 8 D-05, these are now permanent and blocking on every PR and direct push to `main` (no `if: pull_request` guard, no `continue-on-error: true` flags). Weakening any one requires an ADR-011 amendment per `.claude/rules/arch.md:162`:

1. **`import_guard`** (custom_lint plugin host) — `.github/workflows/audit.yml:55` `dart run custom_lint --no-fatal-infos`. Hard-fails on errors regardless of `--no-fatal-infos`; only INFO-severity findings (riverpod_lint) are non-blocking.
2. **`riverpod_lint` / `custom_lint`** (same step as `import_guard`) — provider hygiene gate; INFO-only findings surface but do not block.
3. **`coverde` per-file ≥70%** — `.github/workflows/audit.yml:123` runs `coverage_gate.dart --list cleanup-touched-files.txt --deferred coverage-gate-deferred.txt --threshold 70 --lcov coverage/lcov_clean.info` in the `coverage` job. `if: pull_request` was lifted (push-to-main also gated). 10 file-scoped deferrals carry written rationales (FUTURE-TOOL-03).
4. **`sqlite3_flutter_libs` reject** — `guardrails` job greps `pubspec.lock` and exits 1 on detection; the SQLCipher conflict described in §C of the 1.0 decision body is now an active CI gate rather than reviewer discretion.

`audit.yml` carries a top-of-file warning comment block (lines 1-9) recording these as permanent and noting the 80% → 70% threshold history.

### Forward-looking review triggers

- **FUTURE-TOOL-03** (`coverage-baseline-review`) — after v1 feature work completes, review the active 70% coverage threshold and decide: raise uniformly back toward 80%, OR split per-area thresholds. Inputs: latest `coverage-baseline.json`, distribution of per-area coverage, area-specific risk profile. Output: ADR amendment + matching `audit.yml` / `coverage_*.dart` edits + retirement of deferred-list entries.
- **FUTURE-QA-01** (`smoke-test-owner-driven`) — owner runs `08-SMOKE-TEST.md` checklist on a fresh build before v1 release; signs the Sign-off block; commits the completed file. Any SMOKE-NN findings become follow-up plans.

The original decision body above is preserved verbatim per ADR append-only convention (`.claude/rules/arch.md:162`).
