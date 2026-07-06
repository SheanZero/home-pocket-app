---
phase: quick-260706-saz
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/shared/constants/voice_tuning.dart
  - lib/application/voice/amount_arbiter.dart
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/application/voice/voice_chunk_merger.dart
  - lib/application/voice/voice_text_parser.dart
  - lib/application/voice/english_number_words.dart
  - lib/application/voice/recognition/category_recognizer.dart
  - lib/application/voice/recognition/merchant_recognizer.dart
  - lib/infrastructure/speech/speech_recognition_service.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
  - test/unit/application/voice/voice_tuning_consistency_test.dart
  - test/unit/application/voice/amount_arbiter_test.dart
  - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
autonomous: true
requirements: [MOD009-P0-1, MOD009-P0-2, MOD009-P0-3, MOD009-P0-5]

must_haves:
  truths:
    - "全部既有测试（3601+）零修改零失败 — 本任务是行为字节不变的收敛重构（MOD009-P0-1/2/3）"
    - "use-case 已做量级采用（candidate swap）且 merger 缓存仍毒化时，表单最终显示 use-case 修复值，1A SnackBar 撤销可回到原毒化值（kzr 53102/5312 与 35016/3516 向量，MOD009-P0-5）"
    - "语音调参常量单点收口于 lib/shared/constants/voice_tuning.dart；domain 侧与 application 侧 kMerchantAutoFillFloor 由一致性测试锁定相等"
    - "presentation mixin 不再承载金额仲裁业务逻辑 — 无 voice_text_parser / amount_magnitude_guard import（S3 泄漏修复）"
    - "mixin 公开 API（stopPttSessionAndCommit / exitPttTapSession / resetPttSessionState 等方法名与签名）与 VoiceParseResult 字段不变"
  artifacts:
    - "lib/shared/constants/voice_tuning.dart"
    - "lib/application/voice/amount_arbiter.dart"
    - "test/unit/application/voice/voice_tuning_consistency_test.dart"
    - "test/unit/application/voice/amount_arbiter_test.dart"
  key_links:
    - "ParseVoiceInputUseCase 1a/1b 块 → AmountArbiter.resolveParsedAmount（内部 late final 实例，构造签名不变）"
    - "mixin _fillFormFromTextInner 显示仲裁 → AmountArbiter.resolveDisplayAmount 一行调用"
    - "mixin _rebuildAmountMerger 的 amountExtractor 闭包 → arbiter.extractAmount（去掉 mixin 内 VoiceTextParser 实例化）"
    - "speech_recognition_service 默认参数 / merger 窗口 / mixin 两处 listen 配置 → VoiceTuning 常量（infra/app/pres 均可 import shared，layer_import_rules 三条 deny 规则均不涉及 lib/shared/）"
---

<objective>
MOD-009 v2.0 §10 P0 前三项 + P0-5 组合测试缺口：AmountArbiter 提取（P0-1，修 S3 业务逻辑泄漏 + S4 量级仲裁双写）、VoiceTuning 常量集中（P0-2，修 S5 魔法数散落）、重复方法合并（P0-3，修 S4 stopPttSessionAndCommit≈exitPttTapSession + 两处 reset 清零重叠）、两仲裁站点组合测试（P0-5）。

Purpose: 语音金额管线在 260703/260706-kzr 连续补丁后决策逻辑散落在 use-case 与 presentation mixin 两处，后续 P1 mixin 拆分（1075 行）依赖本次先收敛出单一仲裁点与常量单点。

Output: 新增 amount_arbiter.dart + voice_tuning.dart + 2 个新测试文件 + mixin 组合测试追加；全部为行为字节不变的收敛重构，现有 3601 个测试 0 修改 0 失败是硬门。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md
@docs/arch/02-module-specs/MOD-009_VoiceInput.md
@lib/application/voice/parse_voice_input_use_case.dart
@lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
@lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart
@lib/application/voice/voice_chunk_merger.dart
@lib/infrastructure/speech/speech_recognition_service.dart
@lib/shared/constants/voice_currency_suffixes.dart
@lib/features/voice/domain/services/recognition_reconciler.dart
@test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
</context>

<planning_findings>
执行前必读的已核实事实（planner 已逐一验证，executor 无需重查，直接依赖）：

1. **层规则**：`test/architecture/layer_import_rules_test.dart` 的三条 deny 规则（infra 不得 import application/presentation；application 不得 import presentation；domain 不得 import infra/application/presentation）**均不涉及 `lib/shared/`** → infrastructure、application、presentation 都可以 import `lib/shared/constants/voice_tuning.dart`。service 的默认参数值可直接引用 VoiceTuning 常量（static const 是合法的默认参数 const 表达式）。
2. **`lib/application/voice/repository_providers.dart` 是 `@riverpod` codegen 文件**（有 .g.dart）。为守「不动 generated / 零 build_runner」约束（kzr 先例），**不要**为 arbiter 加 provider——AmountArbiter 是纯无状态类，直接构造。
3. **既有公开常量的测试引用**：`test/unit/application/voice/parse_voice_input_use_case_test.dart` 引用 `kMerchantAutoFillFloor`（use-case 文件里的声明）；`test/unit/application/voice/recognition/category_recognizer_test.dart` 引用 `kLearnedPromotionThreshold`；`intraSessionThreshold` 是 event-handler mixin 上的 public static const。→ 这三个声明**原地保留**（改为引用 VoiceTuning 值的 alias），import 站点零变动。
4. **常量站点清单**（planner 已 grep 核实）：
   - listenFor 30s / pauseFor 3s：`voice_ptt_session_mixin.dart` 两处（startPttSession :270-271、resetPttSessionAndRestart :690-691）+ `speech_recognition_service.dart` 默认参数 :55-56
   - partial parse debounce 300ms：mixin :926（`_onResult` 内 Timer）
   - hold misfire 300ms：mixin :1050（`onPttHoldEnd` 内 D-03 阈值）——**与 debounce 不同义，分别命名**
   - merger 窗口 2500ms：`voice_chunk_merger.dart` :49 `_windowDuration`
   - intraSessionThreshold 800ms：`voice_recognition_event_handler_mixin.dart` :68
   - 音量节流 100ms：mixin :907（`_onSoundLevel` 内毫秒比较）
   - 大额提示 1M：mixin :70 `kVoiceLargeAmountNoticeThreshold`（public，260703 1E）
   - 金额上限 10M（exclusive `<`）：`voice_text_parser.dart` :224 + `english_number_words.dart` :76
   - kLearnedPromotionThreshold 3：`category_recognizer.dart` :42
   - kMerchantAutoFillFloor 0.85 双声明：`parse_voice_input_use_case.dart` :21（application 侧）与 `recognition_reconciler.dart` :9（domain 侧）
   - merchant tier 0.85：`merchant_recognizer.dart` :44 `_scoreAnchoredPrefix`——**语义不同（打分档位，非 auto-fill floor），不合并**
5. **两个合并目标的精确 diff**：
   - `stopPttSessionAndCommit`(:277-291) 与 `exitPttTapSession`(:598-610) 唯一差异 = exit 开头多一行 `_continuousActive = false;`，其余逐行相同（merger.stop → service.stop → mounted 检查 → 状态复位 → text 取值 → `_fillFormFromText(text, data: _cachedParseFor(text))`）。**Pattern 7 顺序不变式：merger.stop() 必须先于 service.stop()**。
   - reset 清零两处共享字段恰好 7 个：`_displayCurrency`（复位 JPY）、`_partialText`、`_finalText`、`_parseResult`、`_mergedAmount`、`_soundLevel`、`_lastFilledAmount`。`resetPttSessionAndRestart`(:650-661) 额外有 `_continuousActive = true`（VRESET-01 复活语义）、`_parsing = false`、`_listenStatus = listening`；`resetPttSessionState`(:1064-1073) 没有这三项。
6. **kzr 既有向量位置**：`voice_ptt_session_mixin_test.dart` :1622（merged 53102 → parsed 5312）与 :1657（merged 35016 → parsed 3516 走 magnitude 分支；测试内注释确认 detectConcatRepairCandidate('35016') 为 null）。harness 结构：`CapturingSpeechService`（:43，可 emitFinal）、`FakeParseVoiceInputUseCase`（:138，text→VoiceParseResult map）、`_MixinHost`（:246）。R4 新测试完全照抄这两个测试的机制。
7. **SnackBar 测试陷阱**（项目 memory）：混用 runAsync 的 widget 测试里 SnackBar auto-dismiss timer 落在 fake zone 外——不要试图 pump(时长) 等它消失；需要清场时用下滑 drag 关闭；不要用 warnIfMissed:false。
8. **use-case 构造签名不能变**：use-case 单测直接以 (textParser, categoryRecognizer, merchantRecognizer) 构造 ParseVoiceInputUseCase。arbiter 必须以内部 `late final` 成员形式引入（`AmountArbiter(textParser: _textParser)`），复用注入的同一 parser 实例（否则注入 fake parser 的测试语义会变）。
</planning_findings>

<tasks>

<task type="auto">
  <name>Task 1: VoiceTuning 常量集中（R2 / P0-2，零行为改动地基）</name>
  <files>lib/shared/constants/voice_tuning.dart, lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart, lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart, lib/infrastructure/speech/speech_recognition_service.dart, lib/application/voice/voice_chunk_merger.dart, lib/application/voice/voice_text_parser.dart, lib/application/voice/english_number_words.dart, lib/application/voice/recognition/category_recognizer.dart, lib/application/voice/recognition/merchant_recognizer.dart, test/unit/application/voice/voice_tuning_consistency_test.dart</files>
  <action>
新建 `lib/shared/constants/voice_tuning.dart`（与 voice_currency_suffixes.dart 同层先例：私有构造 + static const 成员，文件头注释说明「MOD-009 P0-2 语音调参常量单点」并为每个常量注明来源站点与语义）。建议成员命名（Claude 裁量，可微调但两个 300ms 必须不同名）：

- `listenFor`（30 秒会话上限）、`pauseFor`（3 秒静音收尾）——Duration
- `partialParseDebounce`（300ms，partial 结果解析防抖）与 `holdMisfireThreshold`（300ms，D-03 按住误触阈值）——**两个不同义常量分别命名，各自注释讲清语义**
- `mergerWindow`（2500ms 跨 final 合并窗口）
- `intraSessionThreshold`（800ms，Phase 23 D-05 会话内 notListening 启发式）
- `soundLevelThrottle`（100ms 音量采样节流）
- `largeAmountNoticeThresholdJpy`（int 1000000，260703 1E 大额提示）
- `amountUpperBoundExclusive`（int 10000000，T-52-10 金额上限，语义为 exclusive 上界）
- `learnedPromotionThreshold`（int 3，学习词条晋升阈值）

替换各站点（见 planning_findings #4 的精确行号），逐站点规则：

1. mixin 两处 listen 配置（startPttSession 与 resetPttSessionAndRestart）：30 秒/3 秒字面量 → `VoiceTuning.listenFor` / `VoiceTuning.pauseFor`。
2. `speech_recognition_service.dart` 默认参数：两个 Duration 字面量默认值 → 直接引用 VoiceTuning 常量（planning_findings #1 已确认 infra→shared 无层障碍且 static const 可作默认参数）。
3. mixin `_onResult` 的 300ms Timer → `VoiceTuning.partialParseDebounce`；`onPttHoldEnd` 的 300ms 阈值 → `VoiceTuning.holdMisfireThreshold`。
4. `voice_chunk_merger.dart` 的 `_windowDuration` → 赋值改为 `VoiceTuning.mergerWindow`（保留私有名以免动用测试可能依赖的行为面；merger 内部引用点不变）。
5. `voice_recognition_event_handler_mixin.dart` 的 `intraSessionThreshold`：**声明原地保留（public API）**，值改为 `VoiceTuning.intraSessionThreshold`。
6. mixin `_onSoundLevel` 的 100ms 毫秒比较 → 与 `VoiceTuning.soundLevelThrottle.inMilliseconds` 比较（行为字节不变）。
7. mixin 顶部 `kVoiceLargeAmountNoticeThreshold`：**声明原地保留**，值改为 `VoiceTuning.largeAmountNoticeThresholdJpy`。
8. `voice_text_parser.dart` 与 `english_number_words.dart` 的两处 10M 上界比较 → `VoiceTuning.amountUpperBoundExclusive`（比较算子与方向一字不动；文档注释里的 10_000_000 提法可保留）。
9. `category_recognizer.dart` 的 `kLearnedPromotionThreshold`：**声明原地保留**（测试 import 它），值改为 `VoiceTuning.learnedPromotionThreshold`。
10. **`kMerchantAutoFillFloor` 双声明策略（requirement R2 明确锁定）**：application 侧（parse_voice_input_use_case.dart）与 domain 侧（recognition_reconciler.dart）**两个声明都原地保留、值不动**——domain 不引 shared 避免依赖争议。不把 floor 放进 VoiceTuning。
11. `merchant_recognizer.dart` 的 `_scoreAnchoredPrefix`：**不合并、值不动**，在其声明处追加一句注释：该 0.85 是 anchored-prefix 打分档位（tier score），与 auto-fill floor 数值巧合相等但语义无关——floor 变了它不跟。

新增 `test/unit/application/voice/voice_tuning_consistency_test.dart`：
- 断言 domain 侧 kMerchantAutoFillFloor == application 侧 kMerchantAutoFillFloor（import 两个文件，测试不受 lib 层规则约束）
- 断言三个 alias（kVoiceLargeAmountNoticeThreshold、intraSessionThreshold、kLearnedPromotionThreshold）分别等于对应 VoiceTuning 值
- 断言 VoiceTuning 各值等于既有行为值（30s/3s/300ms/300ms/2500ms/800ms/100ms/1M/10M/3）——锁值防漂移

禁止：任何比较算子、时序语义、默认参数语义的改动；任何现有测试文件的修改。
  </action>
  <verify>
    <automated>flutter analyze && flutter test test/unit/application/voice/voice_tuning_consistency_test.dart test/unit/application/voice/ test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart test/architecture/layer_import_rules_test.dart</automated>
  </verify>
  <done>
voice_tuning.dart 存在且集中 10 个命名常量；planning_findings #4 清单里除 floor 双声明与 merchant tier 外的所有字面量站点都改引 VoiceTuning；三个 public alias 原地保留；一致性测试绿；`grep -v '//' lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart | grep -c 'Duration(seconds: 30)'` 返回 0 且同法查 'Duration(seconds: 3)' 返回 0（注释行已滤除）；flutter analyze 0 issues；上述 verify 套件全绿且既有测试文件零修改。
  </done>
</task>

<task type="auto">
  <name>Task 2: AmountArbiter 提取（R1 / P0-1，核心收敛）</name>
  <files>lib/application/voice/amount_arbiter.dart, lib/application/voice/parse_voice_input_use_case.dart, lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart, test/unit/application/voice/amount_arbiter_test.dart</files>
  <action>
**前置 GREEN 基线**：动刀前先跑 `flutter test test/unit/application/voice/voice_amount_repair_test.dart test/unit/application/voice/voice_amount_magnitude_test.dart test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart` 确认全绿——这三套是本次重构的 characterization 网（260703 + 260706-kzr 全语义已被钉死）。

新建 `lib/application/voice/amount_arbiter.dart`：纯无状态 application 层类，构造签名 `AmountArbiter({VoiceTextParser? textParser})`，未注入时默认自建 VoiceTextParser。内部按 use-case 现有模式持有 zh state machine（static const）、ja state machine（static final）与 english_number_words 调用。三个公开方法：

1. `resolveParsedAmount({required int? parsed, required String recognizedText, required List<String> alternateTexts, required String? localeId})` → 返回 record `({int? amount, int? repairCandidate})`。**逐行迁移** use-case 的 1a 块（:97-114：contains-verbatim 签名门 → detectConcatRepairCandidate → confirmedByAlternate 静默采用 else 候选 ride-along）+ 1b 块（:132-150：expectedDigitCountForAmount(primary) ?? 首个 alternate 期望 → 位数违反时 _adoptByMagnitude 采用阶梯 → candidate swap）+ 三个私有 helper `_firstAlternateExpectation` / `_adoptByMagnitude` / `_magnitudeReread`（:274-325 整体搬入，逻辑一字不动：采用阶梯顺序 ①1a repair candidate ②state-machine/en 重读 ③alternates 全 parser 路由，候选位数必须精确等于 expected——precision over recall）。
2. `resolveDisplayAmount({required int? parsed, required int? merged, required String rawText, required String? localeId})` → 返回 `int?`。**逐行迁移** mixin :381-416 的显示仲裁：默认 merged 优先（merged ?? parsed）；concat 例外（merged 与 parsed 双非空且不等、detectConcatRepairCandidate 判 merged 恰为 parsed 的毒化 → parsed 赢）；kzr magnitude 例外（rawText 有量级锚、merged 违反位数而 parsed 满足 → parsed 赢；其余分歧一律 merged 优先）。两个例外的判断顺序与现文件一致（concat 先、magnitude 后，magnitude 分支带 amount != parsedAmount 前置条件）。
3. `extractAmount(String text, {String? localeId})` → 委托内部 parser 的 extractAmount。给 mixin 的 merger 闭包用，让 presentation 彻底不需要 VoiceTextParser。

**use-case 侧改造**（构造签名不变，planning_findings #8）：新增成员 `late final AmountArbiter _arbiter = AmountArbiter(textParser: _textParser);`（复用注入的同一 parser 实例）。execute() 里 1a+1b 两块整体替换为一次 `_arbiter.resolveParsedAmount(...)` 调用并解构出 resolvedAmount / amountRepairCandidate；1a/1b 的大段注释随逻辑迁去 arbiter（use-case 留一行指路注释）。删除已无引用的 helper 与 import（amount_magnitude_guard、english_number_words；zh/ja machine 成员**保留**——_detectCurrency 仍用）。

**mixin 侧改造**：新增成员 `late final AmountArbiter _amountArbiter = AmountArbiter();`。_fillFormFromTextInner 的 :381-416 整段替换为一行 `final amount = _amountArbiter.resolveDisplayAmount(parsed: data.amount, merged: _mergedAmount, rawText: data.rawText, localeId: pttVoiceLocaleId) ?? 0;`（保持后续 `amount > 0` 门与 _lastFilledAmount 语义不变）。_rebuildAmountMerger 的 amountExtractor 闭包改走 `_amountArbiter.extractAmount(text, localeId: pttVoiceLocaleId)`，删除闭包内的 VoiceTextParser 实例化（260703 1E 注释迁到 arbiter.extractAmount 或原地保留指路均可）。随后删除 mixin 对 voice_text_parser.dart 与 amount_magnitude_guard.dart 的两条 import——本任务完成后 presentation 不再 import 这两个文件（S3 修复的可验证面）。

新增 `test/unit/application/voice/amount_arbiter_test.dart`（纯增量单测，直测 arbiter 两个 resolve 方法）：
- resolveParsedAmount：260703 向量（250046 签名门 + alternate 确认静默采用 / 无 alternate 时候选 ride-along / kanji-parsed 不二猜）+ kzr 向量（expected 违反 → 阶梯采用 + candidate swap；anchor-free → 原样返回）
- resolveDisplayAmount：merged 优先默认；concat 例外命中；magnitude 例外命中（53102/5312、35016/3516）；both-compliant / both-violating / anchor-free 三类分歧仍 merged 赢

**GREEN 门 = 前置基线三套件 + 全量 application/voice 套件零修改零失败**。260703/kzr 语义一字不动：1a 精确-alternate 静默采用优先级、candidate swap、precision over recall、1a 修复后 1b 自然 no-op。禁止：给 VoiceParseResult 加字段；改 use-case/mixin 任何公开签名；跑 build_runner。
  </action>
  <verify>
    <automated>flutter analyze && flutter test test/unit/application/voice/ test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart</automated>
  </verify>
  <done>
amount_arbiter.dart 存在且三方法齐备；use-case 1a/1b 与 mixin :381-416 的决策逻辑只在 arbiter 有单一实现；`grep -c '^import.*voice_text_parser' lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` 返回 0 且 `grep -c '^import.*amount_magnitude_guard' lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` 返回 0；amount_arbiter_test.dart 覆盖两方法的 260703+kzr 向量并全绿；voice_amount_repair_test / voice_amount_magnitude_test / mixin 套件零修改全绿；flutter analyze 0。
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: 组合测试（R4 / P0-5）先行 + 重复合并（R3 / P0-3）+ 全量收口</name>
  <files>test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart, lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart</files>
  <behavior>
    - 组合向量 A（53102/5312）：FakeParseVoiceInputUseCase 对 final 文本返回「use-case 已完成 candidate swap」的 VPR（amount=5312、amountRepairCandidate=53102、rawText 照抄 :1622 既有测试的锚定机制），merger 经 emitFinal + 2.5s 窗口把 53102 提交进 _mergedAmount → 断言表单 currentAmount == 5312，且 1A 撤销 SnackBar（voiceAmountRepairSuspect）出现、点其 action 后 currentAmount == 53102
    - 组合向量 B（35016/3516）：同构造（amount=3516、amountRepairCandidate=35016，rawText 带量级锚照抄 :1657 机制，concat 检测器对 35016 为 null 故走 magnitude 分支）→ 断言 currentAmount == 3516，撤销后 == 35016
    - R3 合并后：既有 stopPttSessionAndCommit / exitPttTapSession / resetPttSessionState 全部调用方与测试零改动通过（公开签名不变，thin delegate）
  </behavior>
  <action>
**第一步（R4 测试先行，充当 R3 的 characterization 门）**：在 `voice_ptt_session_mixin_test.dart` 末尾（kzr 组附近）追加上述两个组合测试。机制完全照抄 :1622-1690 两个既有 kzr 测试（同一 harness：CapturingSpeechService.emitFinal、FakeParseVoiceInputUseCase 的 text→VPR map、merger 2.5s 窗口触发），差异仅在 map 出的 VPR 额外带 amountRepairCandidate（模拟 use-case 已 swap），并新增两条断言维度：1A SnackBar 的出现与 action 点击后的撤销值。SnackBar 相关谨记 planning_findings #7：不要 pump(时长) 等 auto-dismiss、清场用下滑 drag、不用 warnIfMissed:false；两个测试之间若 SnackBar 残留需先清场。写完先跑该文件确认新增测试绿（它们测的是现有行为——若不绿，先修测试构造而非改产品代码）。

**第二步（R3a 合一）**：mixin 新增私有 `Future<void> _stopAndFill({required bool endContinuous})`，方法体 = 现 stopPttSessionAndCommit 全文，仅在最顶部加 endContinuous 为真时置 _continuousActive 为 false（planning_findings #5：这是两方法唯一差异；Pattern 7 的 merger.stop 先于 service.stop 顺序不变式与其注释一并保留）。`stopPttSessionAndCommit` 与 `exitPttTapSession` 变为一行薄委托（分别传 endContinuous: false / true），**方法名、签名、public 可见性、doc 注释全部原地保留**（:209 的 stopRecordingAndCommit override 委托链不动）。

**第三步（R3b 清零抽取）**：mixin 新增私有 `void _clearSessionBuffers()`，内容 = planning_findings #5 列出的 7 个共享字段赋值（不包 onPttSessionChanged——由调用方包）。resetPttSessionAndRestart 的清零块改为：onPttSessionChanged 回调内先置 _continuousActive = true（VRESET-01 注释保留原地），再调 _clearSessionBuffers()，再置 _parsing = false 与 _listenStatus = listening。resetPttSessionState 改为 onPttSessionChanged(_clearSessionBuffers)。两处字段集差异（_continuousActive/_parsing/_listenStatus 只属 restart 路径）必须保持——先对照 planning_findings #5 的 diff 再动手。

**第四步（全量收口）**：`flutter analyze`（0 issues）→ **完整 `flutter test`，不 pipe 不 tail**（memory：`-N` 计数器是真相，piping 会掩盖 exit code；main.dart boot-provider 类回归只有全量能抓）。确认 `git diff --numstat -- test/` 中既有测试文件删除列为 0（只增不改）。

禁止：任何 // ignore:；改动 generated 文件；ARB 改动；公开方法签名变化。
  </action>
  <verify>
    <automated>flutter analyze && flutter test</automated>
  </verify>
  <done>
两个组合测试（53102/5312、35016/3516 × candidate-swap VPR × merger 毒化）在 mixin 套件中存在且绿，断言覆盖最终显示值 + 1A 撤销 affordance 双维度；stopPttSessionAndCommit 与 exitPttTapSession 均为对 _stopAndFill 的薄委托、清零逻辑收敛于 _clearSessionBuffers 且两路径字段集差异保持；完整 flutter test 全绿（既有 3601 个测试零修改零失败 + 本任务新增全绿）；flutter analyze 0；git diff 显示既有测试文件只增不删。
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| STT 转写文本 → 金额解析管线 | 不可信语音识别输出（含 ITN 毒化）进入 app 的唯一入口，本任务重构其仲裁层 |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-saz-01 | Tampering | AmountArbiter（迁移后的仲裁逻辑） | medium | mitigate | 行为字节不变门：voice_amount_repair / voice_amount_magnitude / mixin kzr 三套 characterization 测试零修改全绿 + 新增 arbiter 直测；采用阶梯 precision-over-recall（候选位数必须精确匹配，永不发明数值）语义原样迁移 |
| T-saz-02 | Tampering | VoiceTuning.amountUpperBoundExclusive（T-52-10 10M 上限） | high | mitigate | 上限值与 exclusive 比较方向一字不动，仅字面量改名；一致性测试锁值 10000000 防未来静默漂移 |
| T-saz-03 | Elevation | kMerchantAutoFillFloor 双声明漂移（domain vs application 各改一边 → 低置信度商家静默 auto-fill） | medium | mitigate | voice_tuning_consistency_test 断言双侧值恒等，任何单边改动即红（ADR-012 floor 契约的机器锁） |

无新依赖、无包安装（Package Legitimacy Gate 不适用）、无新 I/O 面、无加密路径触碰。
</threat_model>

<verification>
1. `flutter analyze` — 0 issues（无 // ignore: 新增）
2. 完整 `flutter test`（不 pipe）— 既有 3601 个测试零修改零失败；新增 voice_tuning_consistency_test / amount_arbiter_test / 2 个组合测试全绿
3. S3 修复可验证面：mixin 文件无 voice_text_parser / amount_magnitude_guard import（Task 2 done 里的 import 锚定 grep）
4. S4 修复可验证面：量级/concat 仲裁决策仅存于 amount_arbiter.dart 单一实现；stop/exit 与两处清零各收敛为单一私有方法
5. S5 修复可验证面：voice_tuning.dart 单点 + 一致性测试锁值
6. `test/architecture/layer_import_rules_test.dart` 绿（shared 引入未破层）
7. `git diff --numstat -- test/` 既有测试文件删除列为 0
</verification>

<success_criteria>
- MOD-009 §10 P0-1/2/3 落地 + P0-5 组合测试缺口关闭，全程行为字节不变
- 公开 API 冻结面守住：mixin 方法名/签名、VoiceParseResult 字段、ParseVoiceInputUseCase 构造签名、三个 public 常量声明位置
- 零 build_runner、零 generated 改动、零 ARB 改动
- 后续 P1 mixin 拆分（S1/S2）获得单一仲裁点与常量单点作为地基
</success_criteria>

<output>
执行完成后在本目录写 `260706-saz-SUMMARY.md`（quick 任务惯例：frontmatter status: complete + 偏差记录；若 SnackBar 组合测试构造中发现 harness 需要新 helper，属 Rule 3 偏差，记入 SUMMARY）
</output>
