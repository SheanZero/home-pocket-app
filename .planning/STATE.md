---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: 列表功能
status: ready_to_plan
stopped_at: Phase 26 complete (4/4) — ready to discuss Phase 27
last_updated: 2026-05-30T01:18:14.854Z
last_activity: 2026-05-30 -- Phase 26 execution started
progress:
  total_phases: 7
  completed_phases: 4
  total_plans: 172
  completed_plans: 9
  percent: 57
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-29 — v1.4 列表功能 milestone started)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes survival spending from soul spending
**Current focus:** Phase 27 — calendar header + month summary

## Current Position

Phase: 27
Plan: Not started
Status: Ready to plan
Last activity: 2026-05-30

**Next action:** `/gsd:plan-phase 24`

## Phase Overview (v1.4)

| Phase | Name | Requirements | Status |
|-------|------|-------------|--------|
| 24 | Data Layer Extension | LIST-02 | Not started |
| 25 | Domain Models + Use Case | SORT-01, SORT-02, SORT-03, SORT-04 | Not started |
| 26 | Providers + Shell Wiring | FILTER-01, FILTER-02, FILTER-03, FILTER-04 | Not started |
| 27 | Calendar Header + Month Summary | CAL-01, CAL-02, CAL-03, CAL-04 | Not started |
| 28 | Transaction Tile + Sort/Filter Bar | LIST-01, ROW-01, ROW-02, SORT-01–04, FILTER-01–04 | Not started |
| 29 | List Screen Assembly + Family | LIST-04, FAM-01, FAM-02, FAM-03, FAM-04 | Not started |
| 30 | i18n + Empty States + Golden Polish | LIST-03 | Not started |

Note: SORT-01/02/03/04 and FILTER-01/02/03/04 are defined in Phases 25/26 respectively and first become fully user-observable in Phase 28. Their traceability maps to Phase 28 as the primary delivery phase per REQUIREMENTS.md.

## Last Milestone Snapshot (v1.3)

- **Phases:** 6 (18-23)
- **Plans:** 47
- **Duration:** 2026-05-22 → 2026-05-26 (~5 days)
- **Commits:** 330 (vs v1.2 tag); 304 files changed; +64,157 / -4,747 LOC
- **Audit Status at Close:** `tech_debt` — accepted (Phase 18/21 missing VALIDATION.md; Phase 19/20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true`; documentation-grade debt only)
- **Outcome:** Single shared `TransactionDetailsForm` widget across 4 hosts (manual/voice/edit/OCR review); `ManualOneStepScreen` single-screen manual entry; SmartKeyboard 48dp touch-target floor + 6 golden baselines; voice number parser zh + ja (zh 96% + ja 100% corpus accuracy) with `VoiceChunkMerger` 2.5s continued-listening window; `VoiceCategoryResolver` always-L2 contract with extensible merchant DB + synonym dictionary; hold-to-record gesture with `<100ms` perceived state change; edit-from-list path with `entry_source` verbatim preservation; 2 BLOCKER gaps (G-01/G-02) closed; Phase 23 cleanup absorbed carried tech-debt (scanner allow-lists, 6 voice-flow surgical fixes, 4 mechanical polish items, REQUIREMENTS.md reconciliation, 9 device UATs run + passed, `voice_input_screen.dart` 838→776 LOC)
- **Tag:** `v1.3`

## Previous Milestone Snapshots

- **v1.2** (5 phases, 37 plans, 2026-05-19 → 2026-05-21, audit `tech_debt` accepted) — Happiness Metric Refresh
- **v1.1** (4 phases, 40 plans, 2026-05-01 → 2026-05-05, audit `known_debt` accepted) — Happiness Metric & Display
- **v1.0** (8 phases, 48 plans, 2026-04-24 → 2026-04-29, audit `passed`) — Codebase Cleanup Initiative

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.0 + v1.1 + v1.2 + v1.3 decisions captured there with outcomes.

**v1.4 locked product decisions (pre-implementation):**

- Calendar per-day totals: own-book only in v1.4 (combined family calendar totals deferred to v1.5+)
- Swipe-delete: confirm-only soft-delete, NO undo SnackBar in v1.4 (undo deferred — requires `RestoreTransactionUseCase`)
- Filter state persistence: keepAlive under `IndexedStack` — filter/sort state persists across tab switches (decided in Phase 26)
- Family "Mine only" shortcut: included in v1.4 (FAM-04)
- Scope: expense-only; no income tracking; no month settlement/lock; no amount-range filter; no "New" badge

### Pending Todos

Roadmap created. Ready to plan Phase 24.

### Blockers / Concerns

No active blockers for v1.4. Carried-forward debt (cross-milestone):

- **FUTURE-TOOL-03** *(coverage-baseline-review)*: Review 70% coverage threshold (triggered post-v1.2; still open)
- **FUTURE-QA-01** *(smoke-test-owner-driven)*: Owner runs smoke tests before v1 release
- **FUTURE-DOC-01..06** *(documentation drift)*: 6 doc-related items from v1.0 close
- **FUTURE-ARCH-04** *(security)*: `recoverFromSeed()` key-overwrite bug fix (held — security architecture out of scope)
- **v1.1 verification debt:** Phase 11 device/simulator UAT for AnalyticsScreen month chip + pull-to-refresh (human_needed)
- **v1.2 verification debt:** Phase 13 + 17 missing VERIFICATION.md (live code wired + integration-verified at milestone close)
- **v1.3 Nyquist debt:** Phase 18 + 21 missing VALIDATION.md; Phase 19 + 20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true` — documentation-grade only
- **v1.3 voice-flow polish backlog:** Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 on `voice_input_screen.dart`; Phase 23 WR-06 `_voiceLocaleId` reassignment functionally dead. Candidate for v1.4+ VOICE-POLISH-V2 phase.
- **MOD-005 OCR slot:** `ocr_review_screen.dart:54,58` hardcodes `EntrySource.manual` pending writer landing — annotated with `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)`. Schema accepts 'ocr' literal already (v1.2 schema v17).
- **VOICE-EN-V2-01:** English voice parser skeleton only (Plan 23-03 `voice_corpus_en.dart`); no production en voice parser.

**v1.4-specific risks to watch:**

- Shadow-book `note` decryption: `TransactionRepositoryImpl._toModel()` exception handling for undecryptable shadow notes — verify in Phase 24
- Ledger color constants: verify `AppColors.soul` / `AppColors.survival` against `lib/core/theme/app_colors.dart` before Phase 28 tile implementation (never use hardcoded hex)
- `ProviderException` wrapping: all provider error test assertions must use `throwsA(isA<ProviderException>().having(...))` — enforce in every phase adding providers
- Dual-ledger total contamination: calendar + month summary must filter `WHERE type = 'expense'` only — verify in Phase 27

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260518-kyr | Fix soul stats and monthly favorite not refreshing after new soul ledger entry | 2026-05-18 | 7f216e7 | Verified | [260518-kyr-fix-soul-stats-and-monthly-favorite-not-](./quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/) |
| 260518-pf5 | Home polish Bucket A — typography spacing, ledger bar color, caption removal, family invite i18n, tx display, analytics spacing | 2026-05-18 | 5b7b6ee | Verified (3/6 PASS round 1; remaining 3 items reworked in pf6) | [260518-pf5-home-polish-typography-spacing-ledger-ba](./quick/260518-pf5-home-polish-typography-spacing-ledger-ba/) |
| 260518-v4v | Home polish Round 2 — Best Joy Variant A (Pencil mock) + r2 flat-layout tweak, recent-tx soul color + icon reposition, home SizedBox 16→24 for analytics parity | 2026-05-19 | e142f4f | Verified | [260518-v4v-home-polish-round-2-best-joy-variant-a-r](./quick/260518-v4v-home-polish-round-2-best-joy-variant-a-r/) |
| 260522-fj5 | 悦己充盈卡片 UI 修复 — info icon 位置、小确幸数字右移、目标 default 50→100、圆环中心不显示目标、繁体→简体、内环目标固定 10、外环颜色过渡修复 | 2026-05-22 | c90ef9a | — (28 golden diffs pending human re-baseline) | [260522-fj5-ui-7-info-icon-50-100-10](./quick/260522-fj5-ui-7-info-icon-50-100-10/) |
| 260526-i9a | 添加账目 tab 切换改为只换 tag 下面的内容区（MaterialPageRoute → zero-duration PageRouteBuilder，AppBar/tab 不再整页滑动） | 2026-05-26 | 2a7d6ce | Verified | [260526-i9a-tab-switch-inner-content-only](./quick/260526-i9a-tab-switch-inner-content-only/) |
| 260526-inb | IME 收起后恢复数字键盘（TextField 加 textInputAction.done + onTapOutside；fixup: `_handleFocusChange` 把 `_amountFocused` 镜像到 `!hasTextFocus` 才能让 `_showSmartKeypad` 真正变 true）+ KeyboardToolbar elevation 0 + 完成按钮加 outlined frame | 2026-05-26 | 91b401a | Verified | [260526-inb-ime-dismiss-restore-keypad-and-action-ba](./quick/260526-inb-ime-dismiss-restore-keypad-and-action-ba/) |
| 260526-j98 | 添加账目 4 项 polish：(1) 备注 拆独立卡片放分类后；(2) 支出分类 → 用途/用途/Purpose（ARB 单 key）；(3) 底部 scrollPaddingBottom 从全键盘高改 32dp（删 `_computeSmartKeypadHeight`）；(4) freezed 加 `onPickerDismissed` 回调，date/category picker dismiss 后 `_restoreKeypadFocus()` 让 SmartKeyboard 回来；voice mic golden 同步 re-baseline | 2026-05-26 | fedf995 | Verified | [260526-j98-form-restructure-note-card-rename-paddin](./quick/260526-j98-form-restructure-note-card-rename-paddin/) |
| 260526-k92 | 语音 tab 4-fix：(1) ARB `manualInput` zh=手动/ja=手動 与 OCR/语音 长度对齐；(2) CRITICAL 保存按钮永久灰 — voice screen 没像 manual 那样 seed 默认 category，加 `_initializeDefaultCategory()` postFrame 调用 + `_canSave` 不再 gate `_hostAmount > 0`（无金额时点 submit 由 snackbar 兜底）；(3) 加固定 40dp transcript 区域显示 `_partialText` / `_finalText`；(4) `extractDate` 已存在但 `parsedDate` 没消费，加 `updateDate` setter + LAST-wins 多次提及规则 + zh/ja 各 5 条 date corpus | 2026-05-26 | f6fa621 | Superseded by 260526-l0o (real-world test surfaced 5 regressions/bugs) | [260526-k92-voice-tab-fixes-save-transcript-date-cat](./quick/260526-k92-voice-tab-fixes-save-transcript-date-cat/) |
| 260526-l0o | Voice follow-up 5-fix（k92 真机回归）：(1) `12,450日元 → 450` — `日元` 不在 `VoiceCurrencySuffixes.all` 导致 comma-aware regex miss 退回 `\d{3,7}` fallback；加 `日元/日圓/日币`；(2) `新干线 → 交际费/聚会饮酒` — `default_synonyms.dart` 没 Shinkansen 词条 + resolver 缺 substring fallback；加 13 个交通同义词 + resolver 增 substring 兜底；(3+5) 反转 voice 默认 category seed（manual 仍保留）+ `_canSave = !_isSubmitting`（去掉 `_hostCategory` gate，submit 时 snackbar 兜底）+ guard `_stopRecordingAndCommit` 不让 null 覆盖 host category；(4) transcript 从 bodyMedium/40dp → caption/28dp single-line ellipsis | 2026-05-26 | 5f94743 | Pending visual check | [260526-l0o-voice-followup-amount-parse-loss-categor](./quick/260526-l0o-voice-followup-amount-parse-loss-categor/) |
| 260526-n7b | 语音 amount parser 直接修复（无 plan/summary，单 commit）：「上周二交公交卡用了¥5240」→ 0 — 两个叠加 bug：(a) 周二 的 二 触发 `_numeralHintPattern` → 路由到 state machine → 失败但**不 fallthrough 到 arabic regex**（docstring 承诺了但 code 没做）；(b) `[¥￥]\s*(\d{1,3}...)` 的 \d{1,3} 贪婪匹配 "524" 出自 "5240"，无 `(?!\d)` 锚，alternation 永不试 `\d{4,9}`。加 fallthrough + 加 `(?!\d)` + 2 个 corpus 测试 | 2026-05-26 | (hotfix) | Pending visual check | (no plan dir) |
| 260526-pg6 | Option F active-learning（v1.3.1 quick win，研究报告推荐路径之一）：发现 write/read 用两个 keyword extractor 导致 learned row **silent orphan**（write 留 `日元` 后缀，read 剥掉 → 永不重命中）。加 `VoiceParseResult.resolvedKeyword` 共享 canonical key；learned row `hitCount ≥ 3` 自动 promote 到 substring fallback；`tool/dump_learned_keywords.dart` CLI inspection。Schema v17 不变。350/350 测试通过，zh/ja corpus 100% | 2026-05-26 | 6ff4ea3 | Pending visual check (round-trip 学习) | [260526-pg6-voice-active-learning-record-full-keywor](./quick/260526-pg6-voice-active-learning-record-full-keywor/) |
| 260526-r8y | 语音 polish + CRITICAL toolbar save bug：(1) 语音区包 `_FormCard` 风格 14dp 圆角+1px AppColors.borderDefault 边框，与上面表单卡片对齐；transcript 上方加 12dp padding；mic 手势/渐变不动；(2) 语音底部按钮 `l10n.save` → `l10n.record`（复用现有 ARB，0 文件 ARB 改动，zh=记录/ja=記録する/en=Record）；(3) CRITICAL — TextField `onTapOutside: unfocus`（260526-inb 加的）在 pointer-down 触发，**早于** KeyboardToolbar InkWell `onTap` 在 pointer-up resolve，unfocus 把 `_isTextFieldFocused→false` 翻转 → toolbar 下一帧被卸载 → tap-up 永远到不了 `onSave`。Fix：toolbar 包 `TapRegion(groupId: kKeyboardToolbarTapRegionGroup)` + 两个 TextField 加同样 `groupId`，toolbar 上的 tap 不再触发 `onTapOutside`。re-baseline voice mic golden（mic 现在住卡片里背景像素自然变） | 2026-05-26 | dc1f677 | Verified | [260526-r8y-voice-area-border-transcript-spacing-sav](./quick/260526-r8y-voice-area-border-transcript-spacing-sav/) |
| 260529-e5f | 用途 ledger pills 移到标题右侧同行（Card B `[Text, SizedBox(12), LedgerTypeSelector]` → `Row(spaceBetween)` + `Flexible` 标题左 / pills 右；`LedgerTypeSelector` Row 加 `MainAxisSize.min` 以可嵌入水平布局）— Card B 变矮，灵魂满足度选择器获得更多垂直空间；共享 widget 影响 4 hosts；whole-screen voice golden re-baseline。Follow-up：pills 字号 titleMedium→titleSmall、padding 10/16→8/14、icon 16→15 缩小以与标题层级一致（commit 8d6a479） | 2026-05-29 | f86e8fc | Pending visual check | [260529-e5f-purpose-pills-inline-right](./quick/260529-e5f-purpose-pills-inline-right/) |
| 260529-gbp | 修复语音灵魂支出满足度默认值 bug：voice 流程对 soul ledger 跑 `VoiceSatisfactionEstimator` 并 `updateSatisfaction` 覆盖表单默认 2；`_mapToSatisfaction` 旧 `0.3+score*0.7` 把中性语音(~0.3)映射到 ~5（中间表情）。重锚定线性映射：中性 ≈0.26→2、兴奋+正面 ≈0.56→7（`round(-2.4+16.7*score)` clamp 1..10）；估算回 2 时与默认相等，`updateSatisfaction` no-op，停在默认。同步更新 estimator 单测中性区间（calm 4-6→1-3、empty 3-5→1-4），excited/negative/range 不变。widget 测试用 fake estimator 不受影响 | 2026-05-29 | 11120ca | Pending visual check | [260529-gbp-voice-soul-satisfaction-default-2](./quick/260529-gbp-voice-soul-satisfaction-default-2/) |

## Deferred Items

### Items acknowledged and deferred at v1.3 milestone close on 2026-05-26

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phase 18 + 21 missing VALIDATION.md; Phase 19/20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true` (`wave_0_complete: false` across the draft set) | accept (documentation-grade, mirrors v1.0 FUTURE-DOC-05 / v1.2 close precedent) | v1.3 close |
| voice_polish_backlog | 6 standing WARNINGS (WR-02/03/06/07/NEW-02/NEW-03) + 3 INFOS (IN-01/02/03) on `voice_input_screen.dart` from Phase 22 — vacuous null check, async pipeline race, mocktail catch-all stub override, addListener closure equality, spurious tear-down toast, final-transcript double-parse, no permanent-error recovery affordance, dartdoc gap, missing localized error_audio assert | defer to v1.4+ VOICE-POLISH-V2 phase | v1.3 close |
| voice_polish_backlog | Phase 23 WR-06 `_voiceLocaleId = value` build-side reassignment functionally dead after Plan 23-09 mixin extraction (mixin listener with `fireImmediately:true` is canonical writer); benign but anti-pattern | defer to v1.4+ cleanup | v1.3 close |
| forward_compat | `ocr_review_screen.dart:54,58` hardcodes `EntrySource.manual` pending MOD-005 OCR writer; schema accepts 'ocr' literal already; annotated with `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)` marker | reserved (will be writer-claimed by MOD-005) | v1.3 close |

### Items acknowledged and deferred at v1.2 milestone close on 2026-05-21

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| verification_gap | Phase 13 (`ADR-016 Backend Foundation`) lacks 13-VERIFICATION.md; live code wired and integration-verified via Phase 14 transitively + audit integration check at close | accept (documentation-grade) | v1.2 close |
| verification_gap | Phase 17 (`Manual-Only Joy Sub-Metric`) lacks 17-VERIFICATION.md; live code wired and integration-verified at close | accept (documentation-grade) | v1.2 close |
| nyquist_gap | Phase 13/14/17 VALIDATION.md status: draft, `nyquist_compliant: false`, `wave_0_complete: false`; mirrors v1.0 FUTURE-DOC-06 pattern | accept (FUTURE-DOC equivalent) | v1.2 close |
| test_debt | 6 pre-existing test failures in `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` caused by Phase 15 commit `8d5f136` (`今月、` prefix dropped from `analyticsFamilyHighlightsSentence`); does NOT break any v1.2 user-observable flow; documented in Phase 16 `deferred-items.md` | accept (re-baseline test strings in next milestone) | v1.2 close |
| forward_compat | `EntrySource.ocr` literal accepted by schema v17 CHECK constraint and by DAO filter, but no production write site stamps `EntrySource.ocr` yet (consistent with MOD-005 OCR being a later module) | reserved (will be writer-claimed by MOD-005) | v1.2 close |
| metadata_drift | `gsd-sdk audit-open` reports 3 quick tasks (`260518-kyr`, `260518-pf5`, `260518-v4v`) as `missing` status while STATE.md confirms all 3 Verified with commit refs; tool reads internal slug metadata not STATE.md table | cosmetic, no functional gap | v1.2 close |

### Items acknowledged and deferred at v1.1 milestone close on 2026-05-05

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| verification_gap | Phase 11 `11-VERIFICATION.md` human UAT: run AnalyticsScreen on device/simulator and exercise month chip + pull-to-refresh on real app data | human_needed | v1.1 close |

### Items acknowledged and deferred at v1.0 milestone close on 2026-04-29

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| FUTURE-ARCH-01 | Drive `CategoryLocaleService` from ARB files (eliminate 735-line static map) | v2 backlog | v1.0 close |
| FUTURE-ARCH-02 | Replace residual committed `*.mocks.dart` with full Mocktail (largely closed in Phase 4) | v2 backlog | v1.0 close |
| FUTURE-ARCH-03 | Upgrade audit pipeline to DCM (paid) | v2 backlog | v1.0 close |
| FUTURE-ARCH-04 | Fix `recoverFromSeed()` key-overwrite bug (security-architecture) | v2 backlog | v1.0 close |
| FUTURE-TOOL-01 | Add `riverpod_lint` 3.x once `json_serializable` analyzer conflict resolves upstream | v2 backlog | v1.0 close |
| FUTURE-TOOL-02 | Drift-column unused-detection custom Dart script | v2 backlog | v1.0 close |
| FUTURE-TOOL-03 | Coverage-baseline review (raise uniformly to 80% or split per-area) | v2 backlog | 2026-04-28 (Phase 8 amend) |
| FUTURE-QA-01 | Owner-driven smoke-test execution before v1 release | v2 backlog | 2026-04-28 (Phase 8 close) |
| FUTURE-DOC-01 | MOD-numbering drift in MOD-002/006/007/008 internal headers | v2 backlog | v1.0 close |
| FUTURE-DOC-02 | ARCH-008 ADR-006 → ADR-007 citation drift | v2 backlog | v1.0 close |
| FUTURE-DOC-03 | Wire doc-sweep verifiers into CI | v2 backlog | v1.0 close |
| FUTURE-DOC-04 | Backfill 02-VALIDATION.md + 04-VALIDATION.md | v2 backlog | v1.0 close |
| FUTURE-DOC-05 | Backfill 03/06/08-VERIFICATION.md (substitute evidence exists) | v2 backlog | v1.0 close |
| FUTURE-DOC-06 | /gsd-validate-phase 07 (`nyquist_compliant: false`) | v2 backlog | v1.0 close |
| Tech-debt nit | 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart` (lines 57, 73) | accept | v1.0 close |
| Tech-debt nit | `amount_display.dart` absent from `cleanup-touched-files.txt` (Plan 08-04 deferred-items.md) | accept | v1.0 close |

**v1.1-deferred items (subsumed into v1.2 active scope and shipped):**

- HAPPY-V2-01..03 → shipped in Phases 16, 15, 17 respectively
- STATSUI-V2-01 → shipped in Phase 16
- TOOL-V2-02 → shipped in Phase 14
- FAMILY-V2-01..03 → still v2 backlog (explicitly out of v1.2 scope; candidate for next milestone)
- TOOL-V2-01 (fl_chart 1.x) → still v2 backlog

**v1.2-deferred items (subsumed into v1.3 active scope and shipped):**

- v1.2 close debt: 6 `family_insight_card_test.dart` failures from Phase 15 ARB drift → still carried (not touched by v1.3)
- Forward-compat `EntrySource.ocr` slot → still reserved (will be writer-claimed by MOD-005)

## Session Continuity

Last session: 2026-05-29T22:24:59.074Z
Stopped at: Phase 26 context gathered

**Planned Next:** `/gsd:plan-phase 24` — Data Layer Extension

## Operator Next Steps

- `/gsd:plan-phase 24` — start Phase 24: Data Layer Extension
- Key decisions for Phase 24 implementer:
  - Add `TransactionDao.findByBookIds(...)` + `.watch()` stream variant
  - Extract `DateBoundaries` utility to `lib/shared/utils/date_boundaries.dart`
  - Add chain-integrity-after-soft-delete test before any UI phase
  - Verify shadow-book `note` decryption exception handling in `TransactionRepositoryImpl._toModel()`
