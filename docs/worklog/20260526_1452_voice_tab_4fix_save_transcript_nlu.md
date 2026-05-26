# Voice tab fixes: tab label rename, save button bug, transcript display, date/category silent-fill

**日期:** 2026-05-26
**时间:** 14:52
**任务类型:** Bug修复 + 功能开发
**状态:** 已完成（待人工验证 — Item 1/2/3/4 待 Task 4 checkpoint）
**相关模块:** MOD-001 Basic Accounting · MOD-008 Voice Input

---

## 任务概述

Quick task `260526-k92` — 添加账目页面的 4 项 voice tab 修复，作为一组逻辑变更交付：

1. **Item 1**：tab 标签 `手动输入 / 手動入力` → `手动 / 手動`（与 `OCR / 语音 / 音声` 长度齐平）。
2. **Item 2**：CRITICAL — 语音 tab 的 `保存` 按钮始终灰色，因 voice screen 未在 initState 中预置默认 category。
3. **Item 3**：语音识别 transcript 文本未渲染，用户看不到 partial / final 识别结果。
4. **Item 4**：语音 NLU — date phrase (`明天/明日/あさって` 等) 与 category keyword silent-fill；解决 `parsedDate` 在 use case 中计算但未推入 form 的问题。

依据 PLAN.md `.planning/quick/260526-k92-voice-tab-fixes-save-transcript-date-cat/260526-k92-PLAN.md`。

---

## 完成的工作

### Task 1 — ARB shorten + 默认 category 初始化 + form `updateDate` setter

**Commit:** `8df85aa`

- `lib/l10n/app_zh.arb` line 877：`手动输入 → 手动`
- `lib/l10n/app_ja.arb` line 877：`手動入力 → 手動`
- `lib/l10n/app_en.arb`：未改（已是 `Manual`）
- `flutter gen-l10n` 重新生成 `app_localizations_{zh,ja}.dart`
- `voice_input_screen.dart`：
  - 新增私有方法 `_initializeDefaultCategory()` —— 复用 `manual_one_step_screen.dart:135` 的实现，使用 `categoryRepositoryProvider.findActive()` 解析默认 L1 + L2，在 `_formKey.currentState?.updateCategory(...)` 与 `setState(() => _hostCategory = defaultL2)` 中同步写入 form 与 host-cache mirror。
  - 在 `initState` 末尾通过 `WidgetsBinding.instance.addPostFrameCallback` 调用 `_initializeDefaultCategory()`，确保 form 的 GlobalKey 已就绪。
  - 放宽 `_canSave`：去掉 `_hostAmount > 0` 子句，改为 `_hostCategory != null && !_isSubmitting`。Amount 校验交由 form 的 `submit()` 内部负责，命中时通过 existing snackbar 反馈。
- `transaction_details_form.dart`：新增 public 方法 `updateDate(DateTime)` —— 镜像 `updateAmount / updateCategory` 的 idempotency 形态（whole-day 归一化对比、`!mounted` 守卫）。

### Task 2 — Voice NLU date parser 扩展 + `_stopRecordingAndCommit` wiring + LAST-wins

**Commit:** `8a847f7`

- `lib/application/voice/voice_text_parser.dart` `_extractRelativeDate`：
  - 新增 zh keywords：`明天 (+1)`、`后天 (+2)`、`大前天 (-3)`
  - 新增 ja keywords：`明日 (+1)`、`あした (+1)`、`あす (+1)`、`明後日 (+2)`、`あさって (+2)`
  - 算法从「first-match-wins」改为「rightmost-end-position-wins, length tiebreak」：
    - 排序键为 `text.lastIndexOf(key) + key.length`（rightmost end-position 优先）
    - 平局时优先取更长的 key（保证 `一昨日` 仍能在 `一昨日のランチ` 里击败 `昨日` 子串）
    - 英文 keywords (`yesterday`, `today`, `day before yesterday`) 同步规则
  - 满足 brief「contradictory phrases (e.g. 昨天今天) take the LAST one」语义。
- `voice_input_screen.dart` `_stopRecordingAndCommit`：在 `state.updateCategory(...)` 之后追加 `if (data.parsedDate != null) state.updateDate(data.parsedDate!);` —— null 时为 no-op (silent fill)。
- `test/fixtures/voice_corpus_zh.dart`：新增 `VoiceDateCase` typedef + `voiceDateCorpusZh` (5 cases)。
- `test/fixtures/voice_corpus_ja.dart`：新增 `VoiceDateCaseJa` typedef + `voiceDateCorpusJa` (5 cases)。
- `test/integration/voice/voice_date_corpus_test.dart` (新文件)：iterate 两个 list，断言 `parser.extractDate(input)` 偏移天数等于期望值；`expectedToday` 在 `setUpAll` 抓取一次以容忍 setUp 与 parse 间的 sub-second 漂移。

### Task 3 — Transcript display widget + widget tests

**Commit:** `f6fa621`

- `voice_input_screen.dart`：在 `Expanded(form)` 与 `Padding(waveform)` 之间插入 `SizedBox(key: ValueKey('voice-transcript'), height: 40)`，内嵌 `Text(_partialText.isNotEmpty ? _partialText : _finalText, maxLines: 2, overflow: TextOverflow.fade)`。
  - partial 文本：tertiary 色（淡灰）
  - final 文本：primary 色（正常字重）
  - 空字符串状态：保留 40-px slot，无 layout reflow
  - `_startRecording` 已存在的 `_partialText = ''` + `_finalText = ''` 自动清理新一轮 utterance 开头
- `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart`：
  - 新增 `FakeCategoryRepositoryWithSeed`：`findActive()` 返回 L1 (food) + L2 (dining) 以驱动 `_initializeDefaultCategory()`。
  - 新增 group `260526-k92 — save-button + transcript` 的两个测试：
    - **Item 2 regression guard**：使用 seeded repo 渲染屏幕后，断言 `voice-save-button` 的 `InkWell.onTap != null`。
    - **Item 3**：断言 `voice-transcript` SizedBox 存在且初始 `Text.data == ''`。
  - 修复 D-09 既存测试：在 tap 前先 `tester.ensureVisible(merchantField)`。新增的 40-px transcript SizedBox 把 `Expanded(form)` 区域缩小，导致测试视口里 merchant TextField 滑出 hit-test 范围，`warnIfMissed:false` 静默吞掉 tap。改用 `ensureVisible` 把字段滚入可点击区。
- Mic golden re-baselined：`voice_input_screen_mic_button_idle.png`。`expectLater(find.byKey('voice-mic-button'), matchesGoldenFile)` 实际捕获整屏（无 `RepaintBoundary` 在 mic 节点）—— Item 1 tab 标签变短 + Item 3 transcript SizedBox 都会引起像素差异，必须 re-baseline。

### Task 4 — Human verification checkpoint (待执行)

未提交代码；待用户在 iOS 模拟器/设备上按 PLAN.md `Task 4` 的 6 步骤验证。详见 SUMMARY.md。

---

## 技术决策

### LAST-wins 算法选型

最初按 plan 的简版「`text.lastIndexOf` 最大者获胜」实现，结果 `一昨日のランチ` 中 `昨日` 子串 lastIndexOf=1 击败了 `一昨日` 的 lastIndexOf=0，导致 `extracts 一昨日 (Japanese day before yesterday)` 既存测试失败。改用「end-position (lastIndexOf + length) 最大者获胜，平局优先更长 key」算法，同时满足两个需求：

- `昨天今天都没记账` → `今天` 胜 (end=4 vs 2)
- `一昨日のランチ` → `一昨日` 胜 (end=3 平局 → 长度 3 vs 2 → `一昨日` 胜)

英文 keyword 块同步规则，覆盖 `day before yesterday` vs `yesterday` 的 substring overlap。

### Save button gate 改为 category-only

放弃「(b) 让用户能在 `_hostAmount == 0` 时点保存并在 submit 看到 snackbar」原本是 PLAN 拒绝过的方案——但 (a) 默认 category seed 落地后，amount=0 已是 form `submit()` 内部 `validationError` 路径覆盖的场景。最终采用 plan 推荐的复合方案：default category 在 initState 预置 + 放宽 `_canSave` 取消 amount 门控。优势：用户立即获得「按钮可点 → 有金额校验提示」的清晰反馈，而非永久灰按钮的「为何点不动」困惑。

### 代码变更统计

- 4 production files modified
- 4 test files modified (含 1 个新文件 + 1 个 fixture 扩展 + 1 个 golden re-baseline)
- ~270 lines added / ~9 lines deleted（含测试 fixture）
- 3 atomic commits（Task 1-3）

---

## 遇到的问题与解决方案

### 问题 1: `一昨日` 测试因 LAST-wins 失败

**症状:** `flutter test test/unit/application/voice/voice_text_parser_test.dart` 报 `Expected: <24> Actual: <25>` —— extractDate(`一昨日のランチ`) 返回 -1 而非 -2。
**原因:** 简版 LAST-wins 按 `lastIndexOf` 排序，`昨日` 在 `一昨日` 内部 lastIndexOf=1 击败了 `一昨日` 的 lastIndexOf=0。
**解决方案:** 改用「end position + length tiebreak」算法（见上）。`fix(260526-k92)` 落入 Task 2 同一 commit。

### 问题 2: D-09 既存测试在 transcript widget 加入后失败

**症状:** `INPUT-02 D-09: text-field focus during recording auto-stops without batch fill` 报 `Expected: true Actual: false`（speechService.canceled）。
**原因:** 新增 `SizedBox(height: 40)` 占用了 Column 的固定 40 像素，`Expanded(form)` 被挤压；测试视口里 merchant TextField 滚到可视区外，`tester.tap(merchantField, warnIfMissed: false)` 静默 miss，FocusNode 从未获焦。
**解决方案:** 在 tap 前加 `await tester.ensureVisible(merchantField); await tester.pumpAndSettle();`。`feat(260526-k92)` 落入 Task 3 同一 commit。

### 问题 3: Voice mic golden 是整屏快照

**症状:** `voice_input_screen_mic_button_golden_test.dart` 报 4.46% 像素差。期待是 mic-only crop（PLAN 评估「likely crops to mic button only」）。
**原因:** `find.byKey('voice-mic-button')` 节点上没有 `RepaintBoundary`，flutter_test 的 golden matcher 实际捕获整个 screen。Item 1 tab 标签变短 + Item 3 transcript SizedBox 都影响整屏布局。
**解决方案:** `flutter test --update-goldens` 重新基线化该单文件。Plan Task 3 已显式授权此场景下 re-baseline。

---

## 测试验证

- [x] `flutter test test/integration/voice/voice_date_corpus_test.dart` — 10/10 pass
- [x] `flutter test test/integration/voice/voice_corpus_zh_test.dart` — zh 96%+ accuracy (unchanged)
- [x] `flutter test test/integration/voice/voice_corpus_ja_test.dart` — 50/50 100% (unchanged)
- [x] `flutter test test/unit/application/voice/voice_text_parser_test.dart` — 65/65 pass
- [x] `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — 20/20 pass
- [x] `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` — pass (re-baselined)
- [x] `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form*.dart` — 29/29 pass
- [x] `flutter analyze` — 0 issues 在所有 touched files (4 pre-existing repo-wide infos/warnings 与本变更无关)
- [ ] **Task 4 human verification on iOS sim** — 待执行（见 SUMMARY.md 的 6-step playbook）

---

## Git 提交记录

```
8df85aa  fix(260526-k92): seed voice screen default category and add form updateDate setter
8a847f7  feat(260526-k92): wire voice date parsing into save flow with LAST-wins corpus tests
f6fa621  feat(260526-k92): display partial/final voice transcript above mic button
```

---

## 后续工作

- [ ] **Task 4**: 用户在 iOS 模拟器执行 PLAN.md `Task 4` 的 6 步骤人工验证
- [ ] 待 Task 4 PASS 后，由 orchestrator 合并 docs commit（SUMMARY.md + STATE.md + worklog）

---

## 参考资源

- PLAN: `.planning/quick/260526-k92-voice-tab-fixes-save-transcript-date-cat/260526-k92-PLAN.md`
- SUMMARY: `.planning/quick/260526-k92-voice-tab-fixes-save-transcript-date-cat/260526-k92-SUMMARY.md`
- 相关既存代码：
  - `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` (默认 category init 蓝本)
  - `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (`updateAmount` setter 形态蓝本)
  - `lib/application/voice/parse_voice_input_use_case.dart:52` (parsedDate 来源)

---

**创建时间:** 2026-05-26 14:52
**作者:** Claude Opus 4.7 (1M context)
