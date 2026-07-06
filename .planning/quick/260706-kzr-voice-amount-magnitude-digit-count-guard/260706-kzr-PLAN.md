---
quick_id: 260706-kzr
title: 语音金额「量级词↔位数」一致性守卫 — 千=乘数位数+3、万=乘数位数+4（zh/ja/en）
type: feature
branch: main
worktree: false
autonomous: true
files_modified:
  - lib/application/voice/amount_magnitude_guard.dart
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/features/voice/domain/models/voice_parse_result.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - test/unit/application/voice/amount_magnitude_guard_test.dart
  - test/unit/application/voice/voice_amount_magnitude_test.dart
  - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
must_haves:
  truths:
    - 说「3千5百16元」后表单最终显示 4 位数字 3516；说「五万」显示 5 位——量级词与位数不一致时绝不原样落表单（用户锁定需求）
    - ITN 毒化「53102元」在 alternate 含「五千三百一十二元」时，表单最终填 5312（用户截图案）
    - 惯用语「千万别」「万一」「成千上万」「1万步」以及日期「3号」不触发校验（precision over recall）
    - 无量级锚的话语行为与 260703 现状逐字节一致（零回归）
  artifacts:
    - lib/application/voice/amount_magnitude_guard.dart（L1 纯函数）
    - test/unit/application/voice/amount_magnitude_guard_test.dart
    - test/unit/application/voice/voice_amount_magnitude_test.dart
  key_links:
    - parse_voice_input_use_case.dart 1a 块之后插入 1b 量级仲裁（读 expectedDigitCountForAmount）
    - voice_ptt_session_mixin.dart _fillFormFromTextInner 行 386-394 仲裁泛化（rawText 锚）
    - 采用修复时 amountRepairCandidate ← 原毒化值（swap），既有 1A 通知自动变成「改回原值」撤销 affordance——零新 ARB key、零 freezed 字段
---

# Quick Task 260706-kzr — 语音金额量级位数守卫

## Task

用户原话：「语音输入增加检查，如果用户说了3千5百16，一定要确保最后显示的数字是4位，万是5位，日语和英文也要做相同的处理。」

规格（锁定）：
- 最高量级词 千/仟(zh)、千/せん/ぜん(ja)、thousand(en) → 期望位数 = 乘数位数 + 3
- 最高量级词 万/萬(zh)、万/まん(ja) → 期望位数 = 乘数位数 + 4（en 无 ten-thousand 词，不适用）
- 「最后显示的数字」= `_fillFormFromText` 落进表单的 `amount`，校验必须支配这条路径
- primary 无量级锚（ITN 已毒化成纯数字）时从 **alternates** 转录找锚（260703 已把 alternates 传入 use case）

## 已核对的管线事实（executor 直接引用，不必重勘）

- `extractAmount` 路由：voice_text_parser.dart:84-131。en 完全隔离分支；zh/ja 逗号权威 → hint/spaced 走状态机 → Arabic 兜底。混合形「3千5百16」状态机已能正确读 3516。
- `detectConcatRepairCandidate`：voice_text_parser.dart:152-168，纯 static，5-9 位、head 尾零 ≥ tail 长。
- 裁决层 1a：parse_voice_input_use_case.dart:87-112。alternate 精确 == candidate → 静默自动采用；否则 candidate 骑行 `amountRepairCandidate`。**空隙 = alternate 不精确相等（或形状探测不到）时毒化值照常显示。**
- 显示仲裁：voice_ptt_session_mixin.dart:380-394。`amount = _mergedAmount ?? data.amount ?? 0`，唯一例外是 merged 恰为 parsed 的 concat 毒化形。alternates 构造在 :925-928，`_parseFinalResult` :975 透传。
- 通知：`_showVoiceAmountNotice`（mixin :463 起），至多一条，2B > 1A > 1E。1A 触发条件 `candidate != null && filledAmount == data.amount && candidate != filledAmount`；ARB 文案 `voiceAmountRepairSuspect(original, candidate)` =「金额识别为 {original}，是否应为 {candidate}？」+ `voiceAmountRepairApply(candidate)` =「改为 {candidate}」（app_zh.arb:1721/1729，ja/en 同位）。
- 量级 token 表：zh 机 `_kanjiUnits` 有 千/仟=1000、万/萬=10000（chinese_numeral_state_machine.dart:51-58）；ja 机同 :57-63（萬 也有），kana 走 `japaneseNumeralDictionary`（せん/ぜん/まん 在 hint pattern voice_text_parser.dart:31-35 已列）。两机 `.parse` 可独立解析乘数子串（「三十五」→35、「五」→5）。
- `VoiceParseResult` 是 freezed（voice_parse_result.dart）。**本方案不加字段** → 不跑 build_runner，只改 `amountRepairCandidate` 的 doc 注释。
- en 数词：english_number_words.dart `parseEnglishNumberWords(text, moneyContext:)`，_units 含 a/an→1，clamp <10M。
- 货币锚：`VoiceCurrencySuffixes.regexAlternation`（longest-first、已 escape）。

## 关键设计决定（Claude 自由裁量区，已定，executor 不再选型）

**采用修复时的通知 = candidate swap，零新 ARB、零新字段**：L2 量级仲裁采用修复后，`resolvedAmount ← 修复值`，`amountRepairCandidate ← 原毒化值`。这样表单填的是正确位数（用户硬需求），且既有 1A 通知自动触发——文案变成「金额识别为 {修复值}，是否应为 {原值}？[改为 原值]」，即一键**撤销**回原读数。语义统一为「candidate = 另一种读数，一 tap 可达」；`amountRepairCandidate` doc 注释同步改写。260703 的 1a 精确-alternate 静默采用**保持原样不动**（candidate 仍为 null），量级采用是其后的第二道机会。绝不发明数值：所有候选只来自真实 parse。

---

## Tasks

### T1 — L1 纯函数 `expectedDigitCountForAmount`（TDD，先红后绿）

- **files**: `lib/application/voice/amount_magnitude_guard.dart`（新）、`test/unit/application/voice/amount_magnitude_guard_test.dart`（新）
- **behavior**（RED 测试矩阵，全部先写）：
  - 正例：zh「3千5百16元」→4；「三千五百一十六元」→4；「三十五万」串尾→6；「3千516」串尾→4；「上个月3号 花了3千5百16元」→4（锚定元-表达式，不受 3号 干扰）；ja「一万二千円」→5；「千円」→4（裸千缺省乘数 1）；「千五百円」→4；「五万円」→5；かな「さんぜんえん」→4；en "three thousand five hundred sixteen dollars"→4；"thirty five thousand dollars"→5；"a thousand yen"→4。
  - 反例（全部 null）：「千万别乱花钱」「万一有问题」「成千上万」「走了1万步」（万后残部非数字/货币/串尾）「3.5千元」（小数乘数）zh 裸「千」无乘数无货币直跟、en "thousands of people"、「99999元」（无量级词）。
- **action**: 新建顶层纯函数 `int? expectedDigitCountForAmount(String text, {String? localeId})`，library 风格镜像 english_number_words.dart；library 内私有单例 `const ChineseNumeralStateMachine` + `final JapaneseNumeralStateMachine`（镜像 ParseVoiceInputUseCase 的 statics）。算法：
  - **en 分支**（localeId startsWith 'en'，镜像 extractAmount 的隔离原则，绝不触 CJK 机）：定位 `thousand` token，其前必须有可解析乘数——阿拉伯 1-999，或把 thousand 前的连续数词子串喂 `parseEnglishNumberWords(…, moneyContext: true)` 得 1-999；金额语境锚 = `$`/dollar(s)/VoiceCurrencySuffixes token 存在，或表达式在串尾。expected = 乘数位数 + 3。无有效乘数或无锚 → null。
  - **zh/ja 分支**（null locale 走合并 token 集，乘数解析 ja??zh 兜底，镜像 `_runStateMachine`）：在文本中扫描「(乘数run)(量级token)(低位残部)(货币后缀|串尾)」形态的金额表达式。量级 token：万/萬/まん → power 4；千/仟/せん/ぜん → power 3；同一表达式内取最高。乘数 run = 量级 token 紧邻前置的最长数字串（阿拉伯或 CJK 数字+十/百，万前允许含千），经对应状态机 `.parse`（阿拉伯 `int.parse`）解出后限 1-999，超界/含小数点或「点」→ null。乘数缺失：ja 且表达式货币锚定 → 缺省 1；zh → null（自动免疫 千万别：「千」作万的乘数 parse 出 1000 超界 → null，双保险）。低位残部只允许数字类字符，混入其他字（万步的步）→ null。expected = 乘数位数 + power。
  - **precision over recall（沿 `_spacedRoundGroupPattern` 哲学）**：多个货币锚定表达式给出互斥 expected → null；一切歧义 → null。宁可不校验，绝不错判。
- **verify**:
  <automated>flutter test test/unit/application/voice/amount_magnitude_guard_test.dart</automated>
- **done**: 上述正反例矩阵全绿；`flutter analyze` 对新文件 0 issue。

### T2 — L2 use-case 量级仲裁（TDD，先红后绿）

- **files**: `lib/application/voice/parse_voice_input_use_case.dart`、`lib/features/voice/domain/models/voice_parse_result.dart`（仅 doc 注释）、`test/unit/application/voice/voice_amount_magnitude_test.dart`（新，harness 跟随 voice_amount_repair_test.dart / parse_voice_input_use_case_test.dart 现有风格：真 VoiceTextParser + stub 两引擎）
- **behavior**（RED）：
  - 「53102元」+ alternates [「五千三百一十二元」] (zh) → result.amount == 5312（用户截图案；260703 的 1a 精确路径已覆盖也无妨，回归钉死）。
  - **新路径专属证明**：「100002000円」+ alternates [「一万二千円」] (ja) → amount == 12000——此形状 concat 探测器无法触发（tail 会以 0 开头），只有量级仲裁的来源③能修，且 `amountRepairCandidate == 100002000`（swap 撤销锚）。
  - en："$350016" + alternates ["three thousand five hundred sixteen dollars"] → amount == 3516。
  - 回归：无 alternates、无量级锚的「250046元」→ 行为与现状逐字节一致（amount 250046 + candidate 2546 骑行）；kanji 正常话语「三千五百元」→ 3500、candidate null、无仲裁介入。
- **action**: 在 1a 块（:87-112）之后、`_detectCurrency`（1b 现注释）之前插入量级仲裁块，并把原 1b/2 注释序号顺延：
  1. `expected = expectedDigitCountForAmount(recognizedText, localeId: localeId) ?? alternateTexts 顺序首个非 null`。
  2. 仅当 `expected != null && resolvedAmount != null && resolvedAmount.toString().length != expected` 时按序尝试采用（**候选也必须位数 == expected 才采用**）：① 既有 `amountRepairCandidate`（1a 未采用时）② 状态机对 primary 重读（zh/ja：locale 对应机 `.parse(recognizedText)`；en：money-context 下 `parseEnglishNumberWords`）③ 逐个 alternate 走 `_textParser.extractAmount(alt, localeId:)`。
  3. 采用 → 先存 `original = resolvedAmount`，再 `resolvedAmount = 采用值; amountRepairCandidate = original`（swap，见设计决定——1A 通知自动变撤销 affordance，零 ARB、零字段）。全部不匹配 → 保持现值、既有 candidate 照旧骑行。
  4. **不回退 260703 语义**：1a 的 confirmedByAlternate 静默采用分支一字不改，量级仲裁只在其后运行（1a 已修好时位数通常达标 → 本块天然 no-op）。
  - `voice_parse_result.dart` 中 `amountRepairCandidate` 的 doc 注释改写为泛化语义：「另一种读数，一 tap 可达——1a 未确认修复候选（tap=采用），或量级仲裁已采用后的原始读数（tap=撤销回原值）」。不加字段、不跑 build_runner、不改 .freezed.dart。
- **verify**:
  <automated>flutter test test/unit/application/voice/</automated>
- **done**: 新测试绿 + voice_amount_repair_test.dart / parse_voice_input_use_case_test.dart / voice_text_parser*_test.dart 既有全绿。

### T3 — L3 mixin 显示仲裁泛化 + 全量回归门

- **files**: `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`、`test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart`
- **behavior**（RED，跟随该测试文件既有 harness）：
  - merged=53102、parsed=5312、rawText=「五千三百一十二元」（量级锚在 rawText）→ 表单填 5312。
  - merged=8000、parsed=3500、rawText 无量级锚 → merged 8000 照旧赢（merged 优先语义回归）。
  - merged 与 parsed 均满足 expected 位数 → merged 赢（只在 merged 违位、parsed 达位时才翻转）。
- **action**: `_fillFormFromTextInner` :386-394 的 concat 例外**保持原判据不动**，追加 OR 分支：`final expected = expectedDigitCountForAmount(data.rawText, localeId: pttVoiceLocaleId)`，当 `expected != null && '$mergedAmount'.length != expected && '$parsedAmount'.length == expected` 时同样 `amount = parsedAmount`。其余 merged 优先语义不变（`_mergedAmount ?? data.amount ?? 0` 主干、_lastFilledAmount、通知精度序 2B>1A>1E 全不动）。`_showVoiceAmountNotice` **零改动**——T2 的 swap 已让 1A 在量级采用后自动作为撤销通知触发。presentation → application 导入合法（mixin 已 import VoiceTextParser 同层文件）。
- **verify**:
  <automated>flutter test test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart</automated>
- **done**: mixin 测试绿；随后执行**完整** `flutter test`（禁止管道到 tail —— `-N` 计数器即真相，项目 memory 教训）全绿 + `flutter analyze` 0 issues、零 `// ignore:`。

---

## Verification gate（整任务收口）

- `flutter analyze` = 0 issues
- 完整 `flutter test` 全绿（含 260703 四层防线回归、architecture tests）
- 零新 ARB key、零 generated 文件改动（`git status` 无 .g.dart/.freezed.dart/lib/generated 变更）
- must_haves.truths 逐条可由 T1/T2/T3 的具名测试用例证明

## Out of scope

- 不改 1a confirmedByAlternate 语义、不改 `_amountMerger` 内部、不改 2B 汇率撤销
- 不做 en ten-thousand（英语无此量级词）
- 不新增 VoiceParseResult 字段（本方案零 freezed 变更；若未来要区分「采用来源」再议）
