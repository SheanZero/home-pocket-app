# Voice follow-up: amount comma loss, Shinkansen miscategory, save always clickable, transcript polish

**日期:** 2026-05-26
**时间:** 15:30
**任务类型:** Bug修复 + 设计调整 + UI优化
**状态:** 已完成（待人工真机验证）
**相关模块:** MOD-001 Basic Accounting / Voice Input Sub-system

---

## 任务概述

承接 quick task `260526-k92` 的真机回归 — 用户实测「昨天做新干线用了12,450日元」一句话报告 5 个问题：金额解析丢千位（450 vs 12450）、新干线被错分到「交际费>聚会饮酒」、保存按钮持续灰色、transcript 显示过于醒目、k92 加的默认分类逻辑在语音 tab 上反而成了源头 bug。本次按计划 `260526-l0o-PLAN.md` 把 5 个问题作为单一改动批次落地。

---

## 完成的工作

### 1. Issue 1 — 金额解析丢千位（commit `dc5e37a`）

- `lib/shared/constants/voice_currency_suffixes.dart`：把 `'日元'` 加到 `VoiceCurrencySuffixes.all` 列表首位（longest-first 顺序保证 `日元` 在 `元` 之前匹配）。
- `lib/application/voice/voice_text_parser.dart` `_extractArabicAmount`：
  - 改用 `VoiceCurrencySuffixes.regexAlternation` 作为后缀集合，与 `_extractKeyword` 保持单一来源。
  - 把第二个 pattern 扩展为支持全角逗号 `，`，并把数字上限从 7 位提到 9 位（覆盖百万级）。
  - 新增一条「纯逗号分隔无后缀」pattern：`12,450` → 12450。
  - 数字清洗的 `replaceAll(',', ...)` 改成 `replaceAll(RegExp(r'[,，]'), ...)`。
- 语料库：`voice_corpus_zh.dart` +5 条、`voice_corpus_ja.dart` +3 条。

测试：zh corpus 53/55 (96.4%, 前 96%)、ja corpus 53/53 (100%, 前 100%) — 双双保住 ≥95% gate。

### 2. Issue 2 — 新干线被错分到交际费/聚会饮酒（commit `342d576`）

- `lib/shared/constants/default_synonyms.dart`：+13 条交通同义词（新干线/新幹線/しんかんせん/飞机/飞机票/機票/飛行機/地下鉄/巴士/出租车/出租/的士/高速バス），每条都指向已存在的 `cat_transport_*` L2 id。
- `lib/application/voice/voice_category_resolver.dart`：在 step 2 exact-match miss 之后增加 step 2.5「substring fallback」，只扫 seed rows（hitCount=0），最长 seed 优先，要求 key length ≥ 2 防单字误命中（本/服/药/书），confidence 0.80 < exact-match 的 0.85。
- DAO/repo wiring：`findAllSeeds()` (DAO) + `findAllSeedRows()` (Repository) + impl mapping。
- 测试 fixture：`voice_category_corpus_zh.dart` +5 条、`voice_category_corpus_ja.dart` +3 条，覆盖 exact + substring 两种命中。
- mocktail fake：`voice_category_resolver_test.dart` 在 `setUp` 给 `findAllSeedRows()` 默认返回 `[]`，所有 miss-path 测试自动走 step 2.5 空集分支。

测试：zh category corpus 35/35 (100%)、ja category corpus 34/34 (100%)、resolver unit test 全绿。

### 3. Issue 3 + 5 — 语音 tab 保存按钮永远可点 + commit 流不再覆盖 hostCategory（commit `9276b23`）

设计反转：k92 给语音 tab 加的「初始默认分类 + `_canSave` gate on category」其实是 5 号 bug 的根源。`_stopRecordingAndCommit` 在 resolver miss 时无条件 `setState(_hostCategory = category)` 会把 seed 的 default 覆盖成 null → `_canSave = false` → 按钮变灰。用户的心智模型是「语音 tab 不要默认，按钮永远可点，submit 时报错弹 snackbar」。

- `lib/features/accounting/presentation/screens/voice_input_screen.dart`：
  - 删除 `_initializeDefaultCategory()` 方法及其 `addPostFrameCallback` 调用。
  - `_canSave` 收紧为 `!_isSubmitting`。
  - `_hostCategory` 字段整个删掉（analyzer 否则会报 unused_field 警告）— form 内部的 `_category` 是 save-time 唯一权威，host-cache 只需要 `_hostAmount` 给 AmountDisplay 用。
  - `_stopRecordingAndCommit` 的 commit-flow setState 改为只写 `_hostAmount`。
- `voice_input_screen_test.dart`：重写 k92 的 save-enabled-at-start 测试为 no-seed 变体；新增 2 条 — Issue 5 stays-enabled-after-voice-miss + submit-null-snackbar。`FakeCategoryRepositoryWithSeed` 类标 `// ignore: unused_element` 保留以备将来手动 tab 测试复用。

手动 tab `manual_one_step_screen.dart` 未改动，其默认 category 逻辑原样保留。

### 4. Issue 4 — Transcript 文字+边界缩小（commit `620d366`）

- `lib/features/accounting/presentation/screens/voice_input_screen.dart` transcript 区块：
  - `SizedBox` 高度 40dp → 28dp。
  - 文本样式 `AppTextStyles.bodyMedium` → `AppTextStyles.caption`（已存在的 12sp w400 token，不新建）。
  - `maxLines: 2` → `1`；`TextOverflow.fade` → `TextOverflow.ellipsis`。
- Golden `voice_input_screen_mic_button_idle.png` re-baseline（mic button 因 transcript 收缩上移 ~12px）。

### 5. 技术决策

- **substring scan 限定 seed rows**（不扫学习行）：限制误判风险，curated set 安全可控；学习行严格 exact match。
- **seed key length >= 2** 过滤：单字 seed（本/服/药/书等）放在 exact-only 路径，避免「本」匹配任意带"本"字的长 utterance。
- **不自动清理污染的 user `category_keyword_preferences`**：交互模式（用户再纠正一次会 bump 正确映射的 hitCount）比一刀切删数据更尊重用户意图。在 verify checkpoint 中说明。
- **`_hostCategory` 直接删除，不是保留 + ignore**：CLAUDE.md 「零分析器警告」硬约束 + 字段确实失去任何 reader。
- **采用现有 `VoiceCategoryCorpusCase` typedef**（带 pre-extracted keyword 字段）而非 PLAN.md 提议的新 `VoiceCategoryCase` typedef，保持 fixture 一致性。

### 6. 代码变更统计

| Commit | 改动 |
| ------ | ---- |
| `dc5e37a` | 4 files, +44/-5 (Issue 1) |
| `342d576` | 8 files, +128/-0 (Issue 2) |
| `9276b23` | 2 files, +141/-73 (Issues 3+5) |
| `620d366` | 2 files, +12/-10 (Issue 4) |

总计：~12 个生产/测试文件、+325/-88 行。

---

## 遇到的问题与解决方案

### 问题 1：删除 `_hostCategory` 导致 unused_field warning

**症状：** 第一版只是把 `_canSave` 改成 `!_isSubmitting`，留下 `_hostCategory` 仅写不读 → analyzer warning。
**原因：** Plan 说「keep the field for future use」，但 CLAUDE.md 是零警告硬约束。
**解决方案：** 整个字段连写入点一起删除，把行为约束写进 dartdoc — 「voice tab 的 `_canSave` 不再 gate on category，form 内部的 `_category` 才是 save-time 权威」。

### 问题 2：mocktail resolver 测试在 step 2.5 引入 `findAllSeedRows()` 后失败

**症状：** 添加 substring fallback 后，所有 miss-path 的 mock test 都会调到没 stub 的 `findAllSeedRows()`。
**原因：** mocktail 默认对未 stub 的方法 throw。
**解决方案：** 在 `setUp` 加一条 `when(() => mockPrefRepo.findAllSeedRows()).thenAnswer((_) async => [])`，所有不显式测试 substring 路径的 case 自动获得空 cache。

### 问题 3：现有 `voice_category_corpus_zh.dart` 已有 `打车` 测试

**症状：** Plan 列出的语料里有 `打车回家 -> cat_transport_taxi`，但现有 fixture 第 138-142 行已经覆盖了这个 case。
**解决方案：** 不重复，把新增放在文件末尾「l0o Issue 2」分组，挑 5 条真正新增的：新干线（exact + substring）+ 飞机票（new seed）+ 地铁卡充值（substring on 地铁）+ 出租车去机场（new seed）。

---

## 测试验证

- [x] flutter analyze 0 issues on touched files
- [x] flutter analyze repo-wide 4 pre-existing infos (k92 baseline)，无回归
- [x] voice text parser unit tests 全绿
- [x] voice corpus zh 96.4%（前 96%，新增 5 case 全过）
- [x] voice corpus ja 100%（前 100%，新增 3 case 全过）
- [x] voice category resolver unit tests 全绿
- [x] voice category corpus zh 35/35 (100%)
- [x] voice category corpus ja 34/34 (100%)
- [x] voice input screen widget tests 22/22（含 3 条 l0o 新 case）
- [x] voice mic button golden 重新基线化
- [x] manual one step screen tests 全绿（确认无回归）
- [ ] 真机测试 — Task 6 human-verify checkpoint，待用户验证

---

## Git 提交记录

```bash
dc5e37a fix(voice): handle comma-separated amounts and 日元 suffix in arabic parser
342d576 feat(voice): add transport synonyms and resolver substring fallback
9276b23 refactor(voice): drop voice-tab default category seed and category gate
620d366 style(voice): shrink transcript readout to caption/28dp single-line ellipsis
```

---

## 后续工作

- [ ] **真机验证**（PLAN.md Task 5 / Task 6 checkpoint:human-verify）— 在 iOS sim 或真机依次跑 10 条验证项：金额、分类、默认移除、保存可点、保存 after voice miss、transcript 缩小、手动 tab 未受影响、完整存档落库。
- [ ] **污染数据用户提示** — 如 k92 测试时已经把「昨天做新干线用了…」这种长 utterance 误存到 `cat_social_drinks`，新 seed 不会自动覆盖。让用户再次手动纠正一次 → upsert 会把正确映射的 hitCount bump 到 1+，统计上压过旧污染。或者「设置→重置语音学习」给个手动入口（v1.4 backlog）。
- [ ] **deferred item**：长 utterance keyword 污染审计（`extractVoiceKeyword` 产出的字符串很少能 verbatim 复用），future cleanup 可考虑剪掉 `keyword.length > 20` 或含标点的 row。
- [ ] **deferred item**：`_extractKeyword` 改造为吐 token 列表（真正解决 step 2 exact-match 不命中长字串的问题，substring scan 是 pragmatic workaround），v1.4+。
- [ ] **deferred item**：英文交通同义词（train/subway/bus/taxi/flight/shinkansen），与 VOICE-EN-V2-01 一起到 v1.4+。

---

## 参考资源

- 计划：`.planning/quick/260526-l0o-voice-followup-amount-parse-loss-categor/260526-l0o-PLAN.md`
- 父任务：`docs/worklog/20260526_1452_voice_tab_4fix_save_transcript_nlu.md`（k92）
- 架构上下文：ARCH-001 Complete Guide §Voice / MOD-001 Basic Accounting / Phase 21 (`DefaultVoiceSynonyms`) / Phase 22 (voice screen body rewrite)
- 设计反转记录：本日志「Issue 3 + 5」节
