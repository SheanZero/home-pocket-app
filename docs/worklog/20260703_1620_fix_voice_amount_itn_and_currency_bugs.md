# 语音记账金额/货币缺陷修复（BUG-1 ITN 拼接全防线 + BUG-2 裸元误判 CNY）

**日期:** 2026-07-03
**时间:** 16:20
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** 语音记账（infrastructure/voice, application/voice, features/voice, voice_ptt_session_mixin, l10n）

---

## 任务概述

按 2026-07-03 上午的根因分析（worklog `20260703_1520`、架构文档 Artifact），用户指示修复除 2D（「元」语义设置项）以外的全部 9 项：1A/1B/1C/1D/1E/2A/2B/2C。全程 TDD（每项先写失败测试再实现）。

---

## 完成的工作

### 1. 主要变更（按修复项）

- **1C · scan() 连续 Digit 位值合并** — `numeral_state_machine.dart` 新增 `_mergePositionalDigit`：后段数字可填入前段尾零时相加（`2500`+`46`→2546），否则保持 last-wins（自我纠正 `3000`→`5000` 不变）。zh/ja 共享。
- **1B · VoiceChunkMerger 三处** — `voice_chunk_merger.dart`：① 合并改空格拼接（`'$_buffer $text'`，两个 ITN 阿拉伯段各自成 token，依赖 1C 位值合并；汉字路径无感）；② `_bufferLooksOpen` 认「整百阿拉伯缓冲」（≥100 且 %100==0）为开放——修掉「提交 2500、静默丢弃 46元」的截断；③ 提交改走注入的 `amountExtractor`（完整 parser 路由，补逗号权威防线，消除 `2,546元`→546 隐患）。mixin `_rebuildAmountMerger` 注入 `VoiceTextParser.extractAmount`。
- **1A-parser · 拼接签名检测器** — `voice_text_parser.dart` 新增 `detectConcatRepairCandidate(digits)`（纯静态）：S=head++tail、head 尾零≥2、tail 1–2 位且不以 0 开头、tail 长度≤尾零数、len(S)≥5 → 候选 head+tail（250046→2546）；最长 head 优先；`250000`/`3005`/`99999` 等合法金额不误报。另新增 `_spacedRoundGroupPattern` 路由：「整百组+空格+短尾段+货币后缀/串尾」走状态机（`2500 46元`→2546），日期尾（`1200 15号`）与 en 隔离不受影响。
- **1A/1D · use case 线程化 + alternates 交叉验证** — `VoiceParseResult` 新增 `amountRepairCandidate`（freezed 再生成）；`ParseVoiceInputUseCase.execute` 新增 `alternateTexts`：金额数字串逐字出现在转写中才跑检测器（汉字解析产物永不被质疑）；某备选转写独立解析出候选值 → **直接采用**（amount=候选、候选清空），否则候选随结果供表单确认。mixin `_onResult` 把 `result.alternates`（去掉首个）传入。
- **2A · 裸「元」→ 本币 null（supersede D-08 zh 分支）** — `parse_voice_input_use_case.dart` 删除 bare-yuan 特判（落入 native→null 兜底）；`voice_currency_suffixes.dart` 删除已无引用的 `bareYuanToken` 常量；5 处注释同步；`currency_detection_test.dart` 断言翻转 + 新增「五十元人民币 仍→CNY」护栏；决策记录追加至 `.planning/STATE.md` Decisions。
- **2C · 换算仅 final 触发** — 汇率块 gate 进 `fillCategory`（resolve-on-final 同门）；partial 不再每 300ms 取汇率/金额跳动；`_displayCurrency` 改为会话开始复位 + 仅 final 更新。
- **2B · 换算可见化 + 撤销** — `pushVoiceForeignTriple` 返回 `({int jpy, String rate})?`；final 换算后 SnackBar「已识别为外币：$50 → ¥7,500（汇率 150.00）」+ 撤销（恢复口述金额、清空货币三元组、显示币种回 JPY）。
- **1A/1E · 金额提示 SnackBar** — `_showVoiceAmountNotice` 单发优先级：换算撤销 > 修复候选采用（「金额识别为 ¥250,046，是否应为 ¥2,546？」[改为 ¥2,546]）> 大额提醒（≥¥1,000,000，无动作）。金额经 `NumberFormatter.formatCurrency`（环境 locale）。候选在展示金额≠解析金额时抑制；另加 merged-vs-parsed 决胜：merger 提交值恰为解析值的拼接毒化时，采用解析值（防 exit 重填复活毒值）。
- **i18n** — 5 个新 S 键 ×3 ARB（en/ja/zh）+ `flutter gen-l10n`。

### 2. 技术决策

- 1A 提示 UI 从「表单 chip」改为 **SnackBar**（与 2B 同一机制）：全部收在 mixin 一处、两个宿主（manual_one_step / legacy voice screen）零改动，宿主金额镜像经 `pttLastFilledAmount` + `onPttSessionChanged` 自然同步。
- 1E 大额确认从「弹层」降为**非阻断提醒**：语音 one-shot 会话中模态弹层打断流；金额仍可编辑。
- SnackBar 时长 6s→4s（Material 默认）：减少对底部按钮的遮挡窗口。

### 3. 代码变更统计

lib 9 文件（+生成物 5）、test 11 文件（含新文件 `voice_amount_repair_test.dart`）、ARB ×3、STATE.md。新增测试 ~40 条。

---

## 遇到的问题与解决方案

### 问题 1: 全量套件唯一失败 — `voice_input_screen_foreign_save_test` CR-01
**症状:** 3530 通过、1 失败：外币 E2E 的 Save 点击未触达 `create()`（tap 命中了 2B 的浮动 SnackBar）。
**原因:** SnackBar 浮层盖住 legacy 语音屏底部保存键；且该测试的 `runAsync`（真实时钟）舞步使 dismiss 计时器落在 fake zone 外，等待无法清除。
**解决方案:** ① 生产侧 auto-dismiss 在 `voice_ptt_session_mixin_test` 1E 用例中加 `findsNothing` 断言实证（fake time 下正常消失）；② E2E 在保存前用**下滑手势**关闭 SnackBar（真实用户行为），注释说明原因。

### 问题 2: use case 接口加参数破坏 5 个测试 fake
**症状:** `implements ParseVoiceInputUseCase` 的 fake 缺新命名参数 → invalid override。
**解决方案:** perl 批量补 `List<String> alternateTexts = const []` 到 5 个测试文件。

---

## 测试验证

- [x] TDD：9 项均先 RED（含 `Expected 2546 / Actual 46`、`Expected null / Actual 'CNY'` 等正确失败）后 GREEN
- [x] `flutter analyze` 0 issues
- [x] FULL `flutter test` 全绿（首轮 3530/3531，修复 E2E 后复跑全绿；计数见终端记录）
- [x] `flutter gen-l10n` + `build_runner`（freezed）
- [x] `dart format` 仅改动文件（遵守「不整仓格式化 test/」）

---

## Git 提交记录

见本次 commit（`fix(voice): ...`，包含本 worklog）。基线 main @ 0b0ac6c5。

---

## 后续工作

- [ ] 真机 UAT：中文说「两千五百四十六元」验证 2546 直读或修复候选 chip；说「五十美元」验证换算 SnackBar+撤销
- [ ] （可选，2D）设置项「说『元』指日元/人民币」——本次按用户指示未做
- [ ] 观察 iOS alternates 质量，若稳定可将修复候选自动采用的置信面扩大

---

## 参考资源

- 根因分析 worklog: `docs/worklog/20260703_1520_voice_arch_doc_and_amount_currency_bug_analysis.md`
- 架构文档（已更新实施状态）: <https://claude.ai/code/artifact/5c69940b-31d1-419f-8da3-391c548e518f>
- 决策记录: `.planning/STATE.md` Decisions `[quick 260703]`

---

**创建时间:** 2026-07-03 16:20
**作者:** Claude (Fable 5)
