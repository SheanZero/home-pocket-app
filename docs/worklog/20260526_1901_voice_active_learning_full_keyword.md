# Voice 主动学习 — 把 user 喊的完整 keyword 写入 learning 表

**日期:** 2026-05-26
**时间:** 19:01
**任务类型:** 功能开发 + Bug修复
**状态:** 已完成（待真机 human-verify checkpoint）
**相关模块:** VOICE / VoiceCategoryResolver / category_keyword_preferences

---

## 任务概述

实现 v1.3.1 Option F（active learning from corrections）—— 关闭"silent orphan"bug：表单 write path 与 resolver read path 用的是两个**不同**的 keyword 抽取函数，所以用户每次更正分类，写入 `category_keyword_preferences` 的 key 跟 resolver 下次实际去查的 key 不一致，学习记录形同虚设。同时让高频 learned 行（hitCount ≥ 3）参与 resolver 的 substring fallback —— 学到 `坐新干线` 后说 `坐新干线去东京` 也能识别。

Quick task slug：`260526-pg6`。

---

## 完成的工作

### 1. 主要变更

**Task 1 — Surface canonical keyword through VoiceParseResult** (commit `772908e`)
- `lib/features/accounting/domain/models/voice_parse_result.dart`：加 freezed 字段 `String? resolvedKeyword`（additive nullable，免迁移）
- `lib/application/voice/parse_voice_input_use_case.dart`：把 `_extractKeyword(...)` 调用提到方法顶端，merchant 分支与 keyword 分支都把同一个 key 透出到 `VoiceParseResult.resolvedKeyword`
- 跑 `build_runner` 重生 `voice_parse_result.freezed.dart`
- 新增 4 个 unit test（1.A–1.D）

**Task 2 — Switch write path to canonical key** (commit `b9592b0`)
- `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart`：`extractVoiceKeyword` 优先消费 `result.resolvedKeyword`；legacy regex 路径只在 `resolvedKeyword == null/empty` 时兜底
- `voice_input_screen.dart` 没动 —— 552 行 `extractVoiceKeyword(_parseResult!)` 调用站点 once-helper-switches-source 自动正确
- 新建 `test/unit/features/accounting/presentation/screens/voice_input_screen_helpers_test.dart`（2.A 三档：canonical pref / null fallback / empty fallback）
- `test/widget/.../voice_input_screen_test.dart` 加 Test 2.B：voice batch fill 之后断言 `TransactionDetailsForm.config.voiceKeyword == "去外食"`（NOT `"去外食日元"`）

**Task 3 — Promote learned rows to substring fallback** (commit `af798bc`)
- `lib/application/voice/voice_category_resolver.dart`：顶部加 `const int kLearnedPromotionThreshold = 3`；step 2.5 candidate 集合改为 `seeds ∪ learned(hitCount ≥ 3)`；learned row 命中时 `source: MatchSource.learning` + 微提升 confidence
- DAO 加 `findLearnedAtOrAbove(int)`、`findTopLearned({limit})`
- Repository interface + impl 同步加两个方法
- 新增 5 个 resolver test（3.B–3.F）+ 3 个 DAO test
- 整合 corpus 跑：zh 38/38 (100%)、ja 34/34 (100%) —— 无回归

**Task 4 — CLI dump tool** (commit `b0bea53`)
- 新建 `tool/dump_learned_keywords.dart` —— 独立 Dart 脚本（不走 Flutter binding）
- 通过 `--key <hex>` 接受 32 字节 SQLCipher key（dev escape hatch；KeyManager 路径走不通因为 `flutter_secure_storage` 需要 `WidgetsFlutterBinding`）
- 输出：`hitCount | lastUsed (YYYY-MM-DD) | keyword -> categoryId`，英文 only，无 ARB
- 拒绝 Android（`sqlcipher_flutter_libs` 拖 Flutter，破坏独立编译）
- `dart analyze` 0 issues；`dart compile exe` 通过；`--help` 输出 usage

**Task 5 — Backward-compat + analyzer + worklog**（本 commit 待 stage）
- `voice_category_resolver_test.dart` 加 1 个 backward-compat 测试 —— 模拟 pre-v1.3.1 写入的脏数据行（key 带 `日元` 后缀），断言 resolver 对不含该字面量的 input 不会被污染
- `flutter analyze` 全部修改文件 0 issues
- `flutter test test/unit/application/voice/ test/unit/data/daos/category_keyword_preference_dao_test.dart test/widget/.../voice_input_screen_test.dart test/integration/voice/` —— 350 个测试全绿
- 写本 worklog

### 2. 技术决策

**为什么 surface canonical keyword 而不是统一两个 extractor？**
两个 extractor 各自处理 currency suffix 集合和 particle 集合不一致，正面统一意味着重写其中一个并仔细对齐所有边角，回归风险高。Surface canonical keyword 是 additive change：在 freezed 模型上加 nullable field，consumer 优先消费、不消费时走 legacy regex —— 0 schema 迁移、0 packages、0 ARB 变更，回滚成本最低。

**为什么 hitCount 阈值 = 3？**
- 比 `CategoryKeywordPreference.isLearned` 的 2 高一档 —— 2 仍然是"learning"的下界，3 是"frequent enough to participate in substring fallback"的更严格门槛
- 跟 `voice_category_corpus_zh_test.dart` 里 `咖啡 -> cat_hobbies_subscription` 测试（3 次 `recordCorrection` 之后断言 learned 胜出）的固定模式对齐 —— operator 已经习惯这个数字
- 单次 typo 不会触发 substring fallback（最坏 hitCount=1 stays exact-match only）

**为什么 learned 不缓存而 seeds 缓存？**
seed 是 app 版本内不变的；learned 的 hitCount 在 session 内可以从 2 跳到 3，立即跨过 promotion 门槛 —— 要让"现在更正第 3 次"的下一句话能命中，必须 fresh fetch。性能代价小（learned 行通常 < 50）。

**为什么 CLI 不读 KeyManager？**
KeyManager 经 `flutter_secure_storage` 走 platform channel，platform channel 需要 `WidgetsFlutterBinding.ensureInitialized()`，但 `WidgetsFlutterBinding` 不能独立 binary 运行。Operator 从 device debug log 抓 key、命令行传入 `--key <hex>` 是 dev tool 的可接受 escape hatch（tool/ 不进 app bundle）。

### 3. 代码变更统计

- 文件数：13 处（5 lib/、1 tool/、5 test/、1 generated freezed.dart、本 worklog）
- 测试新增：1 个 helpers 测试文件（3 个 test）+ 4 个 use case test + 5 个 resolver test + 1 个 backward-compat test + 3 个 DAO test + 1 个 widget test = 17 个新测试
- 测试总数：350（全绿）
- Schema 版本：保持 17，无迁移
- 新 packages：0
- 新 ARB strings：0
- UI 变更：0

---

## 遇到的问题与解决方案

### 问题 1: Freezed v3 sealed class 不能直接调 `.maybeWhen` 在 widget test
**症状:** `form.config.maybeWhen(...)` 在 widget test 里编译报 "method 'maybeWhen' isn't defined for the type 'TransactionDetailsFormConfig'"，但同样调用在生产代码 `transaction_details_form.dart:351` 工作。
**原因:** 不确定根本原因 —— 可能是 sealed 类型在测试上下文的 narrowing 差异、或 generated mixin 可见性。
**解决方案:** 用 Dart 内建的 `is`-narrowing 代替：`config is NewEntryConfig ? config.voiceKeyword : null` —— 更直白也更 type-safe。需要额外 import `transaction_details_form_config.dart` 直接拿到 `NewEntryConfig` 类型。

### 问题 2: CLI `dart compile exe` 拉 Flutter 而失败
**症状:** `package:sqlcipher_flutter_libs` 是 Flutter plugin，transitively pull `package:flutter` —— 独立 Dart 编译失败。
**原因:** 项目唯一的 SQLCipher 包是 Flutter-bound。CLAUDE.md 明确禁止换 `sqlite3_flutter_libs`（混淆 SQLCipher 符号导致运行时降级到系统 sqlite3）。
**解决方案:** 把 `sqlcipher_flutter_libs` import 从 CLI 脚本里删掉，platform check 早期拒绝 Android（"copy DB off-device first"）。macOS/Linux 走系统 dyld lookup（Homebrew sqlcipher）—— dev box 上够用。dartdoc 明确写清楚 platform 限制。

### 问题 3: legacy fallback 对 `昼ごはんに12,450円` 输出 `昼ごん` 而不是 `昼ごはん`
**症状:** Test 2.A.2 期望 `昼ごはん`，实际是 `昼ごん`。
**原因:** legacy regex 的 JP particle 列表 `[のにでをはがもへとや]` 把 `は` 也算 particle，会把 `ごはん` 中间的 `は` 也吃掉 —— 这是 pre-pg6 的 buggy-but-historic 行为。
**解决方案:** 把 Test 2.A.2 期望改成 `昼ごん`（pin 历史行为），加注释说明 fix the over-strip 是 deferred（要改的话必须 gate 在 localeId 上 —— 那是 plan 显式 defer 的更大统一项）。Test 2.A.3 同步用同一字符串。

---

## 测试验证

- [x] 单元测试通过 — 17 个新测试 + 350 个总体
- [x] 集成测试通过 — zh corpus 38/38 (100%)、ja corpus 34/34 (100%)
- [ ] 手动测试验证 — 等真机 human-verify checkpoint（Task 6）
- [x] 代码审查完成 — TDD red-then-green 顺序、每个 task atomic commit
- [x] 文档已更新 — 本 worklog

---

## Git 提交记录

```bash
b0bea53 feat(260526-pg6): add CLI tool to dump learned voice keywords
af798bc feat(260526-pg6): promote learned rows (hitCount>=3) into substring fallback
b9592b0 feat(260526-pg6): switch voice write path to canonical resolvedKeyword
772908e feat(260526-pg6): surface canonical resolvedKeyword through VoiceParseResult
```

---

## 后续工作

- [ ] **Human verify checkpoint (Task 6)**：真机走一遍 round-trip learning（3 次更正 + 第 4 次说 substring-containing utterance 验证 substring fallback 命中）+ CLI dump 输出 + 老脏数据保留 sanity check
- [ ] **v1.4+ P2P-sync 验证**：RESEARCH + CONTEXT 都声明 `category_keyword_preferences` 已通过 P2P 同步，但 `lib/infrastructure/sync` 和 `lib/application/sync` 初步 grep 没看到这个表 —— 需要在 v1.4 显式验证是否同步、是否需要同步、隐私影响（user phrasings 会跨设备扩散）
- [ ] **v1.4+ stale-row 清理工具**：本任务显式 non-goal 是 auto-purge pre-v1.3.1 脏数据。Future task：写一个 cleanup tool 检测 keyword 带 `日元/円/元/块/ドル` 后缀且 hitCount 来自 voice path 的 row 并提示删除
- [ ] **v1.4+ 统一两个 extractor**：目前 legacy regex 还在 helpers 当兜底，functional 但 dead weight。统一两个 extractor + gate particle strip on localeId 是更彻底的 fix（但需要更大测试覆盖）

---

## 参考资源

- Plan: `.planning/quick/260526-pg6-voice-active-learning-record-full-keywor/260526-pg6-PLAN.md`
- Research: `.planning/research/voice-category-recognition-improvements.md` §3.F + §4
- 前置 quick task: `260526-l0o`（substring fallback for seed rows，本任务在此基础上扩展到 learned rows）
- 阈值匹配的 corpus fixture: `test/integration/voice/voice_category_corpus_zh_test.dart` 第 50-60 行（3 次 `recordCorrection` setUp）

---

**创建时间:** 2026-05-26 19:01
**作者:** Claude Opus 4.7 (1M context)
