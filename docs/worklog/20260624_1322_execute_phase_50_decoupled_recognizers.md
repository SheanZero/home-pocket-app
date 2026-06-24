# Phase 50: Decoupled Recognizers 执行完成

**日期:** 2026-06-24
**时间:** 13:22
**任务类型:** 功能开发 / 重构
**状态:** 已完成（验证 4/4，phase.complete）
**相关模块:** v1.9 语音类目与商家识别系统重构（phase 2/4）— DECOUP-01/02/03

---

## 任务概述

通过 `/gsd-execute-phase 50` 执行 Phase 50 全部 5 个 plan（3 waves）。目标：把商家识别与类目识别拆成两个**互不调用**的纯 Dart 引擎；商家命中不再直接决定类目，类目引擎无条件运行——这是 v1.9 里程碑后续交叉验证（Phase 51）的解耦前提。

执行策略：因 local `main` 领先 `origin/HEAD` 10 个未推送规划提交（#683 base-drift），`worktree.base-check` 自动降级为 **sequential on main**（非并行 worktree），与项目历史上「并行 executor 在共享 ARB / `lib/generated/` 上冲突」的教训一致。

---

## 完成的工作

### Wave 1（数据基础 + keyword-only 引擎）
- **50-01** — `MerchantCandidate` + `MerchantMatchEntry`（`@freezed`）领域裁决/匹配行模型 + `MerchantRepository.loadAllForMatching()`（在单个读事务里 join Phase-49 的 `merchants` + `merchant_match_keys`）。无 schema 变更（v22），DECOUP-03。
- **50-02**（checkpoint plan）— `default_synonyms.dart` 关键词种子从 ~16 L2 扩到 **全 138/138 L2**（每个 ≥1 zh + ≥1 ja 直接种子，515 行），加 `seed-keyword-categoryId` 孤儿守卫 + 机器 coverage gate（D-04）。**用户 spot-check 决策**：纳入全部 admin/tax/asset/insurance/special 家族 + 应用全部 word-quality 精修（うーばー→ウーバー、中性 `伴侣零花钱`、hiragana 注音→自然片假名借词）。文件按家族拆分到 `lib/shared/constants/synonyms/*`（均 <347 行）。
- **50-04** — keyword-only `CategoryRecognizer`（由 `VoiceCategoryResolver` 去掉 step-1 商家查找 + `_merchantDatabase` 依赖复制而来），无条件运行（DECOUP-01/02）。旧 resolver 暂留，留待 50-05 原子删除。

### Wave 2（打分器）
- **50-03** — `MerchantRecognizer`：锚定/归一化（NFKC + 片↔平假名折叠 + 全角/小写 + 按字种最小别名长度）的纯 Dart 排序打分器，替代旧的双向子串匹配。RED→GREEN TDD + ~40 条对抗 false-positive 语料（SC2）。executor 自行追加 `>50%` rune-coverage 守卫以压制 prefix 误命中。

### Wave 3（编排重写 + 旧路径退役，相位验收门）
- **50-05** — `ParseVoiceInputUseCase` 改为两路引擎独立调用 + keyword-priority 合并 + `kMerchantAutoFillFloor = 0.85`（D-02/D-03）；删除 merchant→ledger 短路（LEDGER-01 提前）；旧路径整体退役（D-05）：`MerchantDatabase`、`LookupMerchantUseCase`、`VoiceCategoryResolver`（含测试）、`VoiceTextParser` 内嵌商家匹配全部删除，无悬挂引用。四象限回归为验收门。

### 代码评审 + 修复
- `gsd-code-review`（standard，24 文件）发现 **1 BLOCKER + 5 WR + 4 IN**。
- 用户决策「fix now + 全部 WR」。TDD 修复并去 mock 验收门。

---

## 遇到的问题与解决方案

### 问题 1（BLOCKER, CR-01）: 复合语句丢失商家、auto-fill 不触发
**症状:** 「スタバでコーヒー」「スタバで500円」「マクドでポテト食べた」等以商家名开头的主流日/中语序，`MerchantRecognizer.recognize()` 返回 NONE，auto-fill 静默不触发；只有裸「スタバ」或长全名能命中。
**为何门没拦住:** 验收门把 `MerchantRecognizer` mock 成 `any()→0.95`，真打分器从未端到端跑过（IN-04）。
**原因:** 编排器把**原始转写**喂进 recognizer（WR-03），且 `_scoreOf` 的 prefix 覆盖守卫对「别名是长语句前缀」误判 `return null`。
**解决方案:** 按字向拆分 `_scoreOf`——`nq.startsWith(mk)`（别名是语句前缀）走 alias-at-start 档（0.85，仅受字种最小长度约束），`mk.startsWith(nq)`（短词是长品牌前缀，SC2 误命中）保留 `>50%` 守卫；失败档 fall-through 而非 drop。编排器改喂 amount/particle-stripped surface。去 mock 验收门：新增一组用**真** `MerchantRecognizer` 跑微型种子端到端。

### 问题 2（WR-01/02/04/05 + IN-01）
- WR-01/02: 缓存 in-flight Future（并发首调共享一次 DB 读）+ 空种子不永久 latch。
- WR-04: `normalizeToL2` 返回 null 时不 auto-fill（类目留空），不再盖非-L2 id。
- WR-05: substring-fallback 改用模型 `winner.isLearned` 单一真值源。
- IN-01: 删除重复 `外食 → cat_food_dining_out` 种子。

---

## 测试验证

- [x] `flutter analyze`（全项目）= **0 issues**（途中修了 executor 漏检的 2 个 test 下划线 lint）
- [x] 全量 `flutter test` = **3258 passed, 0 failed**（每 wave 手动跑门；项目 test_command 为空、GSD 自动门会误嗅 xcodebuild）
- [x] SC2 ~400 商家对抗语料全部 <0.85 floor（无误 auto-fill）
- [x] SC3 surface 形态（スタバ / ｽﾀﾊﾞ / マクド / Starbucks + 复合语句）全部解析
- [x] 去 mock 的四象限验收门 + cache-poisoning 回归 + coverage/categoryId 门全绿
- [x] `gsd-verifier` 目标后向验证 **4/4 must-haves**，grep 证实两引擎构造解耦、旧路径无悬挂引用
- [x] `50-REVIEW.md` status → resolved；`50-VERIFICATION.md` status → passed

---

## Git 提交记录

Phase 实现 + 修复共 ~20 提交（`2ca88c30..HEAD`，45 文件 +3873/-1474）。关键：
```
2980f450 refactor(50-05): cut voice pipeline over to two decoupled engines (DECOUP-01)
5778bf28 test(50): add failing regression for compound merchant-then-words utterances (CR-01)
72b3f4f7 fix(50): resolve merchant on compound utterances + harden auto-fill (CR-01/WR-03/WR-04/IN-04)
c4e041d0 docs(phase-50): complete phase execution
1b2049c7 docs(phase-50): evolve PROJECT.md after phase completion
```

---

## 后续工作

- [ ] `/gsd-discuss-phase 51`（Cross-Validation + Daily/Joy Ledger Rework）— 下一相位，将插入纯领域 `RecognitionReconciler` 经 3×3 真值表合并两路裁决，并在同一处删除商家短路残留。
- [ ] （可选）`/gsd-secure-phase 50` — secure-phase capability 处于 active 但 `50-SECURITY.md` 缺失；本相位为纯逻辑重构、无新增 I/O / 加密面，安全价值低，phase.complete 未标记为 debt。
- [ ] （可选）`/gsd-validate-phase 50` — `50-VALIDATION.md` 已在规划期实例化，如需 Nyquist 覆盖审计可执行。
- [ ] `.planning/codebase/` 仍陈旧，Phase 51 规划前建议刷新。
- [ ] 残留已记录、未修：IN-02（死字段 `merchantLedgerType`，为 sync-format 兼容暂留）、IN-03（已被 CR-01 fall-through 覆盖）。

---

## 参考资源

- `.planning/phases/50-decoupled-recognizers/50-0{1..5}-SUMMARY.md` — 各 plan 规范记录
- `.planning/phases/50-decoupled-recognizers/50-REVIEW.md` — 代码评审 + Fixes Applied
- `.planning/phases/50-decoupled-recognizers/50-VERIFICATION.md` — 目标后向验证报告
- `.planning/ROADMAP.md` — Phase 50/51 目标 + 成功标准

---

**创建时间:** 2026-06-24 13:22
**作者:** Claude (gsd-execute-phase 编排)
