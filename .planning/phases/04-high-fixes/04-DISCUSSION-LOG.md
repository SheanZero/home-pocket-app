# Phase 4: HIGH Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 04-high-fixes
**Areas discussed:** HIGH-02 routing strategy, HIGH-07 *.mocks.dart strategy, HIGH-03 ResolveLedgerTypeService deletion, Plan structure / arch-test scope / HIGH-04 interpretation

---

## Phase 4 source-of-truth calibration (presented as context, no question)

Important data point shared with the user before any discussion:
- `issues.json` has zero HIGH entries. The CRITICAL findings closed in Phase 3 came from `import_guard` directly. The HIGH scope (HIGH-01..HIGH-08) was derived from `CONCERNS.md` + `SUMMARY.md` and lives in `REQUIREMENTS.md` only. So "close every HIGH finding in `issues.json`" (HIGH-01) is trivially true today — the substantive work is HIGH-02..HIGH-07 plus the ≥80% coverage gate.
- HIGH-02 surface measured locally: ~33 presentation files import infrastructure.
- HIGH-03: `ResolveLedgerTypeService` has 6 reference sites; zero production reads (only deprecated provider def + tests).
- HIGH-04: 4 features each have a `repository_providers.dart`; each also has 1+ other provider files.
- HIGH-05: 10 `keepAlive: true` providers found locally; the 6 named in REQUIREMENTS.md are a subset.
- HIGH-06: After Phase 3, no production provider throws `UnimplementedError`.
- HIGH-07: 14 `*.mocks.dart` files committed.

User confirmed selection of all 4 gray areas to discuss.

---

## HIGH-02 routing strategy

### Sub-question 1: 封锁范围

| Option | Description | Selected |
|--------|-------------|----------|
| 严格：零例外 | All 33 imports route through Application; new facade files in `application/i18n/`, `application/dual_ledger/`, `application/family_sync/`, etc. +30% workload, 5–7 new transit layers, but cleanest. | ✓ |
| 务实：只禁止"胖"导入 | Forbid services / sync clients / crypto providers (~17–20 violations); explicitly allow formatters, LocaleSettings model, `repository_providers.dart` DI glue. Allowlist required. | |
| 近似策略：只禁 service 与 screen 中的 sync/crypto | Forbid only (1) screens/widgets/utils importing infrastructure services, (2) screens importing crypto providers. ~13–15 violations. Provider wiring, formatters, models all allowed. | |

**User's choice:** 严格：零例外
**Notes:** None — clear preference for the cleanest architecture even at higher work cost.

### Sub-question 2: 路由形态

| Option | Description | Selected |
|--------|-------------|----------|
| Use Case 为主，轻量型 Service 补充 | Wrap business actions as `*_use_case.dart`; pure helpers as `application/i18n/formatter_service.dart`. + Symmetrical with existing application/ skeleton; — Surface bloat: small helpers also wrapped. | |
| 纯 re-export Facade 文件 | `lib/application/<domain>/<concept>_facade.dart` re-exports infrastructure paths and providers. + Minimal change; — Just a path swap, no real "routing." | |
| 混合：Repository Provider 为躯干、业务走 Use Case、Helper 保留为 Application Service | Three categories with distinct boundaries: (a) wiring deps hoisted to `application/<feature>/repository_providers.dart`, (b) business actions wrapped as `*_use_case.dart`, (c) helpers wrapped as `application/i18n/formatter_service.dart`. + Strict but practical, value-cost match per category; — Three categories must be carefully recorded. | ✓ |

**User's choice:** 混合：Repository Provider 为躯干、业务走 Use Case、Helper 保留为 Application Service
**Notes:** None — accepts the tri-category trade-off.

### Sub-question 3: CI 拦截形式

| Option | Description | Selected |
|--------|-------------|----------|
| 只加 import_guard.yaml，CI 机械拦截 | New `lib/features/*/presentation/import_guard.yaml` deny `infrastructure/**`. import_guard already blocking; violations fail CI immediately. | |
| import_guard.yaml + 架构测试（对齐 Phase 3 约定） | Two layers: (1) yaml deny, (2) `test/architecture/presentation_layer_rules_test.dart` parses each yaml and asserts `infrastructure/**` deny entry intact. Mirrors Phase 3 D-02. Recommended. | ✓ |
| 只写架构测试，不动 import_guard | Architecture test scans for offending imports. Flexible but doesn't leverage import_guard's design intent. | |

**User's choice:** import_guard.yaml + 架构测试（对齐 Phase 3 约定）
**Notes:** None — alignment with Phase 3 explicitly preferred.

---

## HIGH-07 *.mocks.dart strategy

### Sub-question 1: 14 个 *.mocks.dart 怎么处理

| Option | Description | Selected |
|--------|-------------|----------|
| 迁移到 Mocktail 手写 fake（SUMMARY.md 推荐，与 Phase 3 一致） | Delete all `*.mocks.dart` + Mockito annotations; write `class _Fake/Mock<X>` manually. Aligns with Phase 3 AppInitializer. | ✓ |
| Mockito CI 生成 + .gitignore | Keep `@GenerateMocks` but git-ignore mocks; CI regenerates. Locally unchanged. CI cost +30–60s; AUDIT-10 must extend to test/. | |
| 状态漫保持（仅修复已过期的 fixture） | Keep current 14 committed Mockito mocks; only regenerate when an interface change breaks one. Anti-recommendation per SUMMARY.md and Phase 3 convention. | |

**User's choice:** 迁移到 Mocktail 手写 fake
**Notes:** None — explicit alignment with SUMMARY.md and Phase 3.

### Sub-question 2: 迁移节奏

| Option | Description | Selected |
|--------|-------------|----------|
| 独立 plan 一次性全迁（推荐） | Plan 04-mocks-migration; 14 fixtures all in one plan / one PR. Mocktail convention lands cohesively. + bisect-friendly; — file dependency on RLS-test fixture. | ✓ |
| 随 HIGH-02/03 重构逐文件迁 | No standalone plan; touched-interface fixtures get migrated as part of the touching plan. + scope match; — non-touched fixtures lag, HIGH-07 may be unsatisfiable. | |
| 混合：有改动的随重构走，未触及的独立 plan 扫尾 | Touched-interface fixtures with refactor; rest in standalone scan plan. + minimum cross-plan dependency; — most complex, intersection logic error-prone. | |

**User's choice:** 独立 plan 一次性全迁
**Notes:** None.

### Sub-question 3: Fake 物理位置

| Option | Description | Selected |
|--------|-------------|----------|
| Inline 在各测试文件内（延续 Phase 3 约定） | Each `_test.dart` declares its own `class _FakeX extends Fake implements X`. + Phase-3 consistent; grep-friendly. — Same interface mocked in multiple tests = duplication. | ✓ |
| 抽到 `test/_fakes/<concept>_fake.dart`，DRY 共享 | New shared directory; multi-use fakes one-file-per-concept. + DRY; — new convention requires CLAUDE.md update. | |
| 按 feature/按仓路镜像 `test/<source-relative-path>/_fakes.dart` | Co-located in test mirror tree. + matches existing convention; — cross-layer reuse path-crossing awkward. | |

**User's choice:** Inline 在各测试文件内
**Notes:** None — explicit Phase 3 continuity.

---

## HIGH-03 ResolveLedgerTypeService deletion

### Pre-question: codebase verification

Claude verified the service has zero production reads — `transaction_confirm_screen.dart` already uses `categoryServiceProvider`. The `ResolveLedgerTypeService` class is `@Deprecated` and only delegates to `CategoryService`. The user accepted this finding without comment.

### Sub-question 1: 删除节奏

| Option | Description | Selected |
|--------|-------------|----------|
| 单 PR / 单 commit 一次性删 | One Plan 04-resolve-ledger-type-deletion, one commit deletes source / provider entry / .g.dart / test / mocks. Modern code review supports it. | |
| 拆为 6 个原子 commit（对齐 Phase 3 use_cases 迁移模式） | Phase 3 D-09/D-10 atomic-commit pattern: 1 source / 2 provider / 3 .g.dart regen / 4 test / 5 mocks / 6 cleanup. + bisect-friendly; — possibly over-engineered for pure dead code. | ✓ |
| 合并进 HIGH-07 mocks-migration plan | No standalone plan; 04-mocks-migration handles RLS deletion when its fixture comes up. + plan count -1; — mixed intent in PR. | |

**User's choice:** 拆为 6 个原子 commit（对齐 Phase 3 use_cases 迁移模式）
**Notes:** None — explicit Phase 3 pattern continuity.

---

## Plan structure / arch-test scope / HIGH-04 interpretation

### Sub-question 1: HIGH-04 解读

| Option | Description | Selected |
|--------|-------------|----------|
| 严格：feature 下只保留 `repository_providers.dart` | All 10+ existing other-provider files (voice_providers, sync_providers, group_providers, use_case_providers, settings_providers, home_providers, analytics_providers) merge into repository_providers.dart or migrate out of feature to application/<feature>/. Largest surface; clean structural rule. | ✓ |
| 字面：不出现同一依赖的重复 provider 定义 | Forbid only "same repository defined by multiple providers" (literal duplicates). Voice / sync / state providers may coexist as separate files. + Minimum refactor; — does not match REQUIREMENTS.md's "exactly one" wording. | |
| 混合：Repository 与 Use Case 提供者必须在 `repository_providers.dart` / `use_case_providers.dart`；他者可独立 | Strict rereading: DI providers (repos, use cases, services) in named DI files; feature-specific notifier/state providers may stay in own files but no duplicates. Compromise. | |

**User's choice:** 严格：feature 下只保留 `repository_providers.dart`
**Notes:** None — accepts aggressive structural unification.

### Sub-question 2: State provider 去哪

| Option | Description | Selected |
|--------|-------------|----------|
| 新建 `features/<f>/presentation/state/` 目录 | New subdirectory; `presentation/providers/` holds only `repository_providers.dart`; state moves to `presentation/state/<concept>_notifier.dart`. + Clean structure; — +10 file renames + import shifts. | |
| 依然在 `presentation/providers/` 下，但架构测试只检 `repository_providers.dart` 存在唯一性 | `presentation/providers/` keeps multiple files but arch-test asserts (a) one repository_providers.dart, (b) DI providers there, (c) global uniqueness. + Minimal restructure; — Conflicts with strict choice from sub-q 1. | |
| 所有 state 仍住在 `presentation/providers/`，但文件名加前缀 `state_*` 源代码约定 | Rename non-DI files to `state_<concept>.dart`. Architecture test asserts: `presentation/providers/` contains exactly `repository_providers.dart` + `state_*.dart` files, no others. Middle ground: same directory, naming convention enforces semantics. | ✓ |

**User's choice:** 所有 state 仍住在 `presentation/providers/`，但文件名加前缀 `state_*` 源代码约定
**Notes:** None — accepts naming convention as the structural enforcement mechanism.

### Sub-question 3: Plan 划分与架构测试断言范围

Claude proposed 6 plans / 4 waves and a unified architecture test 04-05 covering HIGH-04/05/06 simultaneously, with the 6 keepAlive providers as a hard-coded const list inside the test.

| Option | Description | Selected |
|--------|-------------|----------|
| 全部接受 | 6 plans / 4 waves as drafted. Architecture test 04-05 covers HIGH-04/05/06 simultaneously, keepAlive 6-name hardcoded + Riverpod global duplicate scan. | ✓ |
| 拆小 04-05：keepAlive/UnimplementedError 提前到 W1 | Split 04-05 into 04-05a (Wave 1, HIGH-05/06 — independent of structure) and 04-05b (Wave 4, HIGH-04 — depends on 04-02). + Earlier safety net; — Plan count rises to 7. | |
| 合并 04-01/02，减少 plan 总数到 5 | Combine 04-01 (application scaffolding) and 04-02 (presentation refactor) into one plan. + Fewer cross-plan deps; — Single plan ~40 files, bisect unfriendly. | |

**User's choice:** 全部接受
**Notes:** None — full acceptance of proposed structure.

---

## Claude's Discretion

The user explicitly delegated the following decisions to Claude / the planner:
- Exact split point for `sync_providers.dart` / `group_providers.dart` / `avatar_sync_providers.dart` / `home_providers.dart` between DI fold and `state_*.dart` rename — per-provider determination after reading each file.
- Concrete naming of new use cases in Plan 04-01 (verb + noun + UseCase pattern from existing application/).
- Whether `application/i18n/formatter_service.dart` is class-with-methods vs Riverpod-provider-only.
- Whether to remove `mockito` from pubspec dev_deps in Plan 04-04 or follow-up plan.
- The exact allowlist set in `lib/features/*/presentation/import_guard.yaml`.
- Order of feature processing within Plan 04-02.
- Whether `lib/application/<feature>/repository_providers.dart` is a new file or colocated with existing application-layer code (e.g., dual_ledger has `providers.dart` already).

## Deferred Ideas

Captured in CONTEXT.md `<deferred>` section. Highlights:
- `state_*.dart` filename convention CLAUDE.md doc → Phase 7
- `application/i18n/formatter_service.dart` injectable pattern doc → Phase 7
- Mocktail-only test convention doc → Phase 7
- `presentation NEVER imports infrastructure` rule formalization in CLAUDE.md → Phase 7
- `lib/application/<feature>/repository_providers.dart` hoisting pattern doc → Phase 7
- `test/_fakes/` shared directory empirical re-evaluation → Phase 7/8
- CategoryLocaleService rename, ARB-driven static map elimination → Phase 5 MED-02 + FUTURE-ARCH-01
- Mockito removal from pubspec dev_deps if blocked → follow-up plan / Phase 6
- FUTURE-ARCH-02 (Mocktail vs Mockito CI-gen) effectively closes once Plan 04-04 lands → archival in Phase 7
- `dart_code_linter` provider hygiene rules replacing arch tests → Phase 7/8
