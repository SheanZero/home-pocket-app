# Phase 62: Automated Release-Gate Lock - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-10
**Phase:** 62-automated-release-gate-lock
**Areas discussed:** 统一门禁入口, 失败与重试规则, 模拟器验收范围, 兼容性报告与证据

---

## 统一门禁入口

### Authority

| Option | Description | Selected |
|--------|-------------|----------|
| 仓库内统一门禁程序 | One version-controlled repository authority reused by local execution and CI; existing runners remain lower-level capabilities. | ✓ |
| GitHub Actions 工作流作为权威 | CI job composition is authoritative; local scripts are preflight only. | |
| 保留多个独立权威入口 | Existing scripts and jobs remain separately authoritative and are reconciled by a checklist. | |

**User's choice:** 仓库内统一门禁程序

### Candidate state

| Option | Description | Selected |
|--------|-------------|----------|
| 仅接受干净且已提交的 commit | Bind evidence to one clean commit, lockfile, and critical native configuration digests. | ✓ |
| 自动快照当前工作区 | Copy committed and uncommitted state to a temporary snapshot and hash it. | |
| 允许脏工作区并仅警告 | Run against dirty state without making it ineligible. | |

**User's choice:** 仅接受干净且已提交的 commit

### Cross-platform execution shape

| Option | Description | Selected |
|--------|-------------|----------|
| 显式执行档位并统一汇总 | One entrypoint exposes host, iOS, Android, release, and aggregate profiles. | |
| 一条 macOS 单体命令完成全部门禁 | One Apple Silicon macOS operation runs every required host and platform gate. | ✓ |
| 各平台独立命令，没有统一汇总档位 | Platform commands remain separate and require external reconciliation. | |

**User's choice:** 一条 macOS 单体命令完成全部门禁

### Workspace isolation

| Option | Description | Selected |
|--------|-------------|----------|
| 临时干净 checkout，复用外部下载缓存 | Regenerate project artifacts in a temporary checkout while reusing external downloads. | |
| 直接在当前干净工作区运行 | Strictly clean and validate the current checkout before and after execution. | ✓ |
| 完全从零的临时环境 | Use a temporary checkout and empty all dependency/build caches. | |

**User's choice:** 直接在当前干净工作区运行
**Notes:** The final contract therefore needs strong pre-run cleanliness, failure cleanup, and post-run repository-drift checks.

---

## 失败与重试规则

### Stop versus continue

| Option | Description | Selected |
|--------|-------------|----------|
| 混合策略 | Fail fast on candidate/prerequisite invalidity, then collect independent test/platform failures. | ✓ |
| 任何失败都立即停止 | Return only the first failure from every run. | |
| 无论失败都执行完整矩阵 | Continue even when prerequisite state is invalid. | |

**User's choice:** 混合策略

### Automatic retry eligibility

| Option | Description | Selected |
|--------|-------------|----------|
| 只重试明确识别的基础设施失败一次 | Retry one classified infrastructure failure once and preserve both results. | ✓ |
| 所有失败都自动重试一次 | Retry assertions, compilation, coverage, and infrastructure failures alike. | |
| 完全不自动重试 | Require manual intervention for every failure. | |

**User's choice:** 只重试明确识别的基础设施失败一次

### Flutter serial confirmation

| Option | Description | Selected |
|--------|-------------|----------|
| 自动进入受控降级流程 | Isolate affected tests, then run the complete suite with `--concurrency=1`. | ✓ |
| 立即完整单并发重跑 | Skip isolation and immediately run the full serial suite. | |
| 暂停并要求人工确认 | Stop automation and ask a maintainer to decide. | |

**User's choice:** 自动进入受控降级流程

### Resume behavior

| Option | Description | Selected |
|--------|-------------|----------|
| 同一候选可受控恢复 | Revalidate identity/environment/cleanliness and resume at the earliest invalidated gate. | ✓ |
| 任何失败后都完整从头运行 | Restart every gate even after an infrastructure-only failure. | |
| 直接从失败步骤继续 | Resume without revalidating prerequisite state. | |

**User's choice:** 同一候选可受控恢复
**Notes:** Any source, dependency, or configuration change invalidates all prior results and forces a complete rerun.

---

## 模拟器验收范围

### Integration-suite breadth

| Option | Description | Selected |
|--------|-------------|----------|
| 两个平台都运行完整 `integration_test/` | Execute complete discovery and suite coverage on iOS Simulator and local Android arm64 Emulator. | ✓ |
| Android 完整、iOS 仅关键旅程 | Keep complete Android coverage and reduce iOS to critical journeys. | |
| 两个平台都只跑关键旅程 | Reuse Phase 60/61 history and run only a final critical matrix. | |

**User's choice:** 两个平台都运行完整 `integration_test/`

### Device starting state

| Option | Description | Selected |
|--------|-------------|----------|
| 擦除数据、冷启动、禁用快照恢复 | Use deterministic readiness and isolated synthetic state on both platforms. | ✓ |
| 保留设备系统状态，仅清除应用数据 | Keep OS/cache state while clearing only the app. | |
| 复用已启动设备和现有应用状态 | Reuse the current boot and installed state. | |

**User's choice:** 擦除数据、冷启动、禁用快照恢复

### Trigger policy

| Option | Description | Selected |
|--------|-------------|----------|
| 仅对明确标记的发布候选强制运行 | Run device gates only before Phase 63/release-candidate promotion. | |
| 每个 PR 都强制运行 | Block every pull request on both complete device suites. | |
| 每次合并到 `main` 后强制运行 | Keep faster PR gates and run the complete dual-platform gate after every main merge. | ✓ |

**User's choice:** 每次合并到 `main` 后强制运行

### Skip and supplemental evidence

| Option | Description | Selected |
|--------|-------------|----------|
| 仅允许已登记的预期 skip | Fail on new skips/unexecuted tests; require reason, owner, and exit condition for each allowlisted skip. | ✓ |
| 只要整体命令退出码为 0 就通过 | Accept every skip reported by the test runner. | |
| 由维护者逐次人工判断 | Decide skip acceptability manually for every run. | |

**User's choice:** 仅允许已登记的预期 skip
**Notes:** The API 36 x86_64 GitHub/Intel lane stays supplemental and non-blocking; it can only be reported as evidence or a limitation, never as the local arm64 pass.

---

## 兼容性报告与证据

### Report authority

| Option | Description | Selected |
|--------|-------------|----------|
| 机器 JSON + 纳入版本控制的 Markdown | JSON is authoritative; checked-in Markdown is rendered from it; CI retains raw artifacts. | ✓ |
| 只保留机器可读 JSON | No checked-in human-readable compatibility summary. | |
| 只保留人工 Markdown 报告 | No machine-verifiable result schema. | |

**User's choice:** 机器 JSON + 纳入版本控制的 Markdown

### Failure-history retention

| Option | Description | Selected |
|--------|-------------|----------|
| 保留结构化失败时间线 | Record every effective attempt, classification, fix, and rerun relationship. | |
| 只记录最终绿色结果 | Keep the report focused on the final green state. | ✓ (initial) |
| 把所有完整运行日志纳入仓库 | Commit every raw gate log. | |

**Scope clarification:** QA-04 requires the final report to record failures and fixes. The user selected the closest compliant form: final-green-focused reporting with only a concise actual failure/fix summary and full rerun result, without an attempt-by-attempt timeline or committed raw failed-run logs.

### Environment capture and redaction

| Option | Description | Selected |
|--------|-------------|----------|
| 严格白名单式元数据 | Collect only explicitly approved reproducibility fields. | |
| 先采集完整环境，再做事后脱敏 | Collect broader diagnostic environment data and scrub before persistence. | ✓ |
| 只记录最少版本号 | Keep only minimal version fields. | |

**User's choice:** 先采集完整环境，再做事后脱敏
**Mandatory privacy clarification:** Known sensitive categories are excluded at collection time rather than collected and later sanitized. Persisted reports and CI artifacts must pass a privacy scan.

### Verdict model

| Option | Description | Selected |
|--------|-------------|----------|
| 二元结论：`PASS` 或 `BLOCKED` | Limitations are listed separately without a third state. | |
| 三级结论：`PASS`、`PASS_WITH_LIMITATIONS`、`BLOCKED` | Express preclassified non-blocking limitations after all mandatory gates pass. | ✓ |
| 允许负责人覆盖为通过 | Permit manual override of mandatory gate failures. | |

**User's choice:** 三级结论：`PASS`、`PASS_WITH_LIMITATIONS`、`BLOCKED`
**Notes:** `PASS_WITH_LIMITATIONS` never overrides a mandatory failure; both passing states require every mandatory gate to be green.

---

## the agent's Discretion

- Release-gate implementation language, file names, internal structure, and precise command spelling.
- Detailed gate ordering within the locked prerequisite/test/platform dependency graph.
- Checkpoint/result schema, infrastructure classifier, privacy scrubber, expected-skip manifest format, and report layout.
- Simulator/AVD names and concrete cleanup/readiness tooling, provided the locked state and evidence contracts hold.

## Deferred Ideas

- Signed wired-iPhone acceptance remains Phase 63.
- Android physical-device validation remains out of scope and unclaimed.
- App-store submission, hosted legal/operator values, and final legal review remain release-owner gates.
- Unpackaged historical sketches were detected but are unrelated to this non-UI phase.
