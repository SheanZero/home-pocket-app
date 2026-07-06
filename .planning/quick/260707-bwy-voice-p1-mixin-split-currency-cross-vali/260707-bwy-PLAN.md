---
phase: quick-260707-bwy
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart
  - test/unit/application/voice/voice_currency_cross_validation_test.dart
autonomous: true
requirements: [MOD009-P1-7, MOD009-P1-8]

must_haves:
  truths:
    - "既有基线 3675 passed + 11 skipped 零修改零失败 — R1/R2 是行为字节不变重构；R3 的测试是 additive（新文件，不动任何既有测试）"
    - "primary 检出外币 ISO X 且任一 alternate 显式检出不同外币 ISO Y（两者均非 null 且 X≠Y）→ detectedCurrency 保守压制为 null，不触发换算，用户可手动改币种（voice-consolidation P1-8）"
    - "alternate 无币种 token、alternate 为 native token（元/円 → null）、或 alternates 空集 → primary 检出原样放行"
    - "voice_ptt_session_mixin 库拆为三个文件（会话状态机 / 填充编排 / 外币+notice+satisfaction），每个文件 <800 行（voice-consolidation P1-7）"
    - "两个宿主（manual_one_step_screen / voice_input_screen）的 with 子句、mixin_test harness 的 with 面、mixin 全部公开方法名与签名、全部私有成员名与可见性——字节级不变"
    - "manual_one_step_screen.dart 的语音接线段（_onVoiceRecordTap/_onVoiceReset/_onVoiceModalExit/onPttCommitted 镜像体/语音面板 builder）移入同库 part 文件；keypad/currency 段一行不动"
  artifacts:
    - "lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart"
    - "lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart"
    - "lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart"
    - "test/unit/application/voice/voice_currency_cross_validation_test.dart"
  key_links:
    - "ParseVoiceInputUseCase.execute 1c 段 → _crossValidateCurrency(primary, alternateTexts, localeId)（复用既有 _detectCurrency 单点，零新检测逻辑）"
    - "part 文件与库私有性：extension 成员跨 part 访问 mixin/类私有成员（同库），startPttSession（主文件）对 _onResult/_onSoundLevel（fill part）做 tear-off 传参"
    - "_parseFinalResult（fill part）→ _applyEstimatedSatisfaction（foreign/notice part，joy 分支逐字搬移）"
---

<objective>
语音 P1 结构重构 + 高危换算防线（voice-consolidation P1-7/P1-8）：

1. **R3（先做，小而独立）**：`ParseVoiceInputUseCase` 增加 alternates 币种交叉验证——primary 检出外币 X 而任一 alternate 显式检出不同外币 Y 时，保守压制 detectedCurrency 为 null（换算是高危写操作，宁可不换算留给用户手动改）。TDD 三组先红后绿。
2. **R1**：`VoicePttSessionMixin`（1053 行）按职责拆为三个文件，每个 <800 行，行为字节不变、公开 API 与私有语义零改动。
3. **R2**：`manual_one_step_screen.dart`（1027 行）语音接线段抽出到同库 part 文件；只抽语音相关，残余行数记 SUMMARY。

Purpose: mixin 巨石（S1/S2 痛点）是后续语音演进（引擎 spike、LLM 兜底层）的结构性障碍；币种交叉验证补上换算路径缺失的最后一道文法防线。
Output: 三个新 lib part 文件 + 瘦身后的 mixin/宿主 + 币种交叉验证及其测试；全量 suite 基线零修改零失败。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md
@lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart
@lib/application/voice/parse_voice_input_use_case.dart
@lib/shared/constants/voice_currency_suffixes.dart
@test/unit/application/voice/parse_voice_input_use_case_test.dart
@test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
@test/architecture/mod009_live_lib_scan_test.dart
</context>

<mechanical_decision>
## R1 机械方案裁定：选 (a)，落地形态 = 同库 part 文件 + mixin 类型上的 extension

**裁定依据（判据：若 (b) 需动 >15 个私有成员可见性，选 (a)）**：跨块私有成员实测约 22 个私有字段（`_isRecording`/`_partialText`/`_finalText`/`_parseResult`/`_displayCurrency`/`_continuousActive`/`_restarting`/`_parsing`/`_listenStatus`/`_mergedAmount`/`_amountMerger`/`_lastFilledAmount`/`_parseDebounce`/`_soundLevels`/`_timestamps`/`_startTime`/`_partialResultCount`/`_lastWordCount`/`_pressStart`/`_soundLevel`/`_lastSampleTime`/`_amountArbiter`）+ 约 14 个跨块私有方法。方案 (b) 需要提升的可见性远超 15 → **选 (a)**。

**Dart 语言事实（(a) 的落地形态修正）**：单个 `mixin` 声明不能跨 part 文件拆分（Dart 无 partial class/mixin）。忠实保留 (a) 全部卖点（私有成员跨文件可见 / 宿主 with 子句零改动 / 零可见性提升 / 风险最低）的唯一落地形态是：**mixin 声明保留在主文件（保留全部字段、抽象契约、@override 成员、公开 getter），方法体按块搬到同库 part 文件中「on VoicePttSessionMixin<W> 的 extension」里**。同库（part）→ extension 成员可直接读写 mixin 私有字段、调用私有方法，零改名零提升。

**已核实的安全前提**（executor 无需重新论证，但 verify 会兜底）：
- harness `_MixinHostState` 与两个宿主只 override 六个抽象契约成员（pttFormState/pttInjectedSpeechService/pttVoiceLocaleId/onPttSessionChanged/onPttCommitted/onVoiceLocaleResolved）——全部留在 mixin 声明里，extension 静态派发不改变任何行为。
- `pushVoiceForeignTriple` 在 lib/test 全库无外部调用点（仅 mixin_test 一条注释提及）——放入 extension 安全；extension 取公开名 `VoicePttForeignNotice` 以保留其对外可调用性。
- `test/architecture/layer_import_rules_test.dart` 只扫 `^import` 行；part 文件无 import 行 → 零交互。presentation 文件本身不受该测试任何规则约束。
- `hardcoded_cjk_ui_scan_test` 只匹配字符串字面量内的 CJK；被搬移代码的 CJK 全在注释里 → 安全。
- analyzer 的 import 使用判定是**库级**（主文件 + parts 合并判定）→ 主文件 import 一行不动、不会出现 unused_import。
- extension 方法 tear-off（`onResult: _onResult`）为 Dart 2.15+ 稳定特性。
- extension 不能声明实例字段、不能 override、不能用 `super` → 字段/契约/`onError`/`onStatus`/`late final _amountArbiter` 必须留在 mixin 声明（本方案正是如此分配）。

**R2 同方案**：`extension _ManualOneStepVoiceWiring on _ManualOneStepScreenState` 放入 `part` 文件（私有类 → 必须同库，part 是唯一通路）。
</mechanical_decision>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: R3 — alternates 币种交叉验证（voice-consolidation P1-8，TDD 先红后绿）</name>
  <files>lib/application/voice/parse_voice_input_use_case.dart, test/unit/application/voice/voice_currency_cross_validation_test.dart</files>
  <behavior>
    新建测试文件 test/unit/application/voice/voice_currency_cross_validation_test.dart，harness 完全镜像 parse_voice_input_use_case_test.dart 的构造方式（mocktail mock CategoryRecognizer/MerchantRecognizer + 真 VoiceTextParser；两 engine stub 为无命中即可——本测试只关心 detectedCurrency）。币种检测走真实数字状态机 token 扫描，直接用真实语料，无需 fake：
    - Test 组 1（矛盾压制）：execute('五百美元的东西', localeId: 'zh-CN', alternateTexts: ['五百人民币的东西']) → result.data.detectedCurrency == null（primary 美元→USD，alternate 人民币→CNY，X≠Y → 压制）。再加一条 ja 向量：primary 'ドル' 句 + alternate '人民元' 句 → null。
    - Test 组 2（无矛盾放行）：primary '五百美元的东西' + alternates ['五百美元的东西啊'（同 ISO）, '去超市买东西'（无币种 token）, '五百元的东西'（native 元 → 检出 null，非矛盾）] → detectedCurrency == 'USD'。三种 alternate 各断言一条（同 ISO / 无 token / native token 均不构成矛盾）。
    - Test 组 3（alternates 空集放行）：primary '五百美元的东西' + alternateTexts: const [] → detectedCurrency == 'USD'。另加对照：primary 无外币（'五百元的东西'）+ alternate 有外币（'五百美元的东西'）→ detectedCurrency == null（primary 为 native 时 alternates 不得引入外币——保守方向单边有效）。
    RED commit（test(quick-260707-bwy): …）先行，确认新测试失败于「压制未发生」；随后 GREEN commit（feat(quick-260707-bwy): …）。
  </behavior>
  <action>
    在 ParseVoiceInputUseCase 中实现最小落地：execute() 的 1c 段把现有单行 detectedCurrency 赋值改为两步——先 primaryCurrency = _detectCurrency(recognizedText, localeId)，再 detectedCurrency = _crossValidateCurrency(primary: primaryCurrency, alternateTexts: alternateTexts, localeId: localeId)。新增私有方法 _crossValidateCurrency：primary 为 null 直接返回 null；否则遍历 alternateTexts，对每条跑既有 _detectCurrency（单一检测点复用，禁止新写 token 扫描逻辑），任一 alternate 检出非 null 且 != primary → 返回 null（保守压制，不触发换算；detectedCurrency 为 null 时 mixin 侧自然跳过 pushVoiceForeignTriple，表单留 JPY，用户可手动改币种）；否则返回 primary。alternate 检出 null（无 token 或 native 元/円）不构成矛盾。
    注释措辞用「voice-consolidation P1-8」与 260703 1D 先例交叉引用；禁止出现被 test/architecture/mod009_live_lib_scan_test.dart 封禁的旧模块文档编号 token。零新 ARB、零 freezed 字段、零 build_runner。日期槽位交叉验证明确不做（低危且 resolve-on-final 已稳）——这一决策记入 SUMMARY，不写代码。
  </action>
  <verify>
    <automated>flutter test test/unit/application/voice/voice_currency_cross_validation_test.dart && flutter test test/unit/application/voice/parse_voice_input_use_case_test.dart test/unit/application/voice/voice_amount_repair_test.dart && flutter analyze</automated>
  </verify>
  <done>新测试三组全绿（先有一次 RED 记录在 commit 历史）；既有 use-case/repair 套件零修改零失败；analyze 0；execute() 除 1c 段两行改写 + 一个新私有方法外无其他改动。</done>
</task>

<task type="auto">
  <name>Task 2: R1 — voice_ptt_session_mixin 三文件拆分（voice-consolidation P1-7，行为字节不变）</name>
  <files>lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart, lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart, lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart</files>
  <action>
    按 <mechanical_decision> 裁定执行同库 part 拆分。方法体**逐字搬移**（连同各自的注释块），除以下三类外禁止任何文本改写：(1) extension 包裹声明；(2) satisfaction 助手抽取（见下）；(3) 新文件头注释（措辞用 voice-consolidation P1-7）。

    **主文件 voice_ptt_session_mixin.dart 保留**（约 590 行）：文件头（追加一段 part 结构说明）、全部 import（一行不动）、紧随 import 之后的两条 part 指令（fill_orchestration / foreign_notice）、enum PttListenStatus、const kVoiceLargeAmountNoticeThreshold、mixin 声明本体——抽象宿主契约五成员 + onPttCommitted 默认体、全部字段（含 late final _amountArbiter 与 pttSpeechService）、全部公开 getter（pttIsRecording…pttListenStatus、pttCanStart）、VoiceRecognitionEventHandlerMixin 契约 override 段、以及**会话状态机块**：initPttSpeechService、disposePttSession、startPttSession、stopPttSessionAndCommit、_stopAndFill、startPttTapSession、exitPttTapSession、resetPttSessionAndRestart、_transientSilenceErrors、onError、_recoverBarAfterFatalError、onStatus、cancelPttSessionAndDiscard、onPttHoldStart/End/Cancel、resetPttSessionState、_clearSessionBuffers。（onError/onStatus 是 override、字段与契约是声明成员——语言层面必须留此，恰与「会话状态机块」职责重合。）

    **voice_ptt_session_fill_orchestration.dart**（填充编排块，约 370 行）：首行 part of 指令指回主文件，无任何 import/library 指令；单个 extension _VoicePttFillOrchestration<W extends ConsumerStatefulWidget> on VoicePttSessionMixin<W>，逐字搬入：_onSoundLevel、_onResult、_parseVoiceInput、_parseFinalResult、_cachedParseFor、_fillFormFromText、_fillFormFromTextInner、_rebuildAmountMerger。其中 _parseFinalResult 的 LedgerType.joy 分支（buildVoiceAudioFeatures + estimator + copyWith 约 14 行）替换为一行 parseResult = _applyEstimatedSatisfaction(parseResult, text)，分支体逐字迁往 foreign_notice part（satisfaction 触发按需求归属外币+notice+satisfaction 块）。

    **voice_ptt_session_foreign_notice.dart**（外币+notice+satisfaction 块，约 190 行）：首行 part of 指令；单个**公开** extension VoicePttForeignNotice<W extends ConsumerStatefulWidget> on VoicePttSessionMixin<W>（公开名保住 pushVoiceForeignTriple 的对外可调用面），逐字搬入：pushVoiceForeignTriple、_extractRate、_showVoiceAmountNotice、_showVoiceSnackBar，以及新助手 _applyEstimatedSatisfaction(VoiceParseResult parseResult, String text)——内部保留 ledgerType == LedgerType.joy 守卫（非 joy 原样返回入参），守卫内为 _parseFinalResult 原分支体逐字内容。

    硬约束：两个宿主文件与 harness 在本任务**零改动**（with 子句、调用面字节不变）；mixin 无任何私有成员改名或可见性提升；无 // ignore:；新文件注释禁旧模块文档编号 token（用 voice-consolidation P1-7 措辞）；主文件 import 不增不减（parts 共享库级 import）。
  </action>
  <verify>
    <automated>flutter analyze && wc -l lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart lib/features/accounting/presentation/screens/voice_ptt_session_fill_orchestration.dart lib/features/accounting/presentation/screens/voice_ptt_session_foreign_notice.dart && flutter test test/unit/features/accounting/presentation/screens/ test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart test/widget/features/accounting/presentation/screens/voice_input_screen_foreign_save_test.dart test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart test/integration/features/accounting/voice_save_entry_source_test.dart test/architecture/ && git diff --name-only HEAD -- test/</automated>
  </verify>
  <done>三个文件 wc -l 各 <800；mixin/screen 全套 + 架构测试零修改零失败；git diff 显示 test/ 目录零改动（Task 1 已提交的新测试文件除外——diff 对象是本任务工作区）；两宿主文件 git diff 为空；analyze 0。commit 类型 refactor(quick-260707-bwy)。</done>
</task>

<task type="auto">
  <name>Task 3: R2 — 宿主语音接线瘦身 + 全量收口</name>
  <files>lib/features/accounting/presentation/screens/manual_one_step_screen.dart, lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart</files>
  <action>
    与 R1 同方案（同库 part + 私有 extension）。manual_one_step_screen.dart 紧随 import 之后加一条 part 指令；新建 manual_one_step_voice_wiring.dart（首行 part of 指令，无 import），内含单个 extension _ManualOneStepVoiceWiring on _ManualOneStepScreenState，逐字搬入语音接线段：
    - _onVoiceRecordTap、_onVoiceModalExit、_onVoiceReset（:296-351 的 tap-modal voice-record lifecycle 段，含注释）。
    - onPttCommitted 的镜像体（:165-188 的 setState keypad 镜像块，含 mounted 守卫与全部注释）→ extension 方法 _mirrorPttFillIntoKeypad()；主文件的 @override onPttCommitted() 缩为一行委托调用（override 语言层面必须留在类内）。
    - build 的语音面板 builder 段（:964-973 的 VoiceRecordPanel(...) 构造）→ extension 方法 Widget _buildVoicePanel()，build 内三元分支改为调用 _buildVoicePanel()；VoiceRecordBar(onTap: _onVoiceRecordTap) 一行留在 build（一行引用，非接线段主体）。
    **范围盒（硬边界）**：只抽语音相关。字段（_voiceSnapshot/_voiceModalOpen/_voiceLocaleId/_lastFillWasVoice）、契约 override getter、initState/dispose 的 init/dispose 调用、didChangeAppLifecycleState（override）留在类内。keypad/currency/save/foreignTriple 段一行不动。抽完若主文件仍 ≥800 行，**不再扩大范围**，把残余行数记入 SUMMARY 即可。
    收口：dart format 仅新建/改动的 lib 文件（禁止全目录 format）；跑全量 flutter test **直接执行，禁止 pipe 到 tail/head**（exit code 与计数器是唯一真相）；R2 的 SUMMARY 记录三件事——主文件残余行数、R3 日期槽位交叉验证明确不做的决策、R1 机械方案裁定（(a) 的 part+extension 落地形态与 (b) 被 >15 私有成员判据否决）。
  </action>
  <verify>
    <automated>flutter analyze && wc -l lib/features/accounting/presentation/screens/manual_one_step_screen.dart lib/features/accounting/presentation/screens/manual_one_step_voice_wiring.dart && flutter test</automated>
  </verify>
  <done>analyze 0；voice_wiring part <800 行；全量 suite = 基线 3675 passed + 11 skipped 零修改零失败 + Task 1 新增测试全绿（预期 ≥3678 passed + 11 skipped）；零 generated/ARB/golden 变更（git status 无 lib/generated、lib/l10n、test/golden 改动）；SUMMARY 三项决策记录齐备。commit 类型 refactor(quick-260707-bwy)。</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| STT recognizer → parse pipeline | 不可信转写文本（含 iOS ITN 毒化的 primary/alternates）进入金额/币种槽位解析 |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-bwy-01 | Tampering | ParseVoiceInputUseCase._detectCurrency（币种误检 → 错误汇率换算写入） | high | mitigate | 本任务 R3：alternates 交叉验证，矛盾即压制为 native（不换算），换算本身保留既有 resolve-on-final + 可撤销 SnackBar 双防线 |
| T-bwy-02 | Tampering | R1/R2 重构引入行为漂移 | medium | mitigate | 逐字搬移 + 既有 3675/11 基线零修改零失败硬门 + 两宿主/harness 字节不变约束 |
| T-bwy-03 | Repudiation | 换算压制不留痕（用户困惑金额未换算） | low | accept | 保守方向本身即需求裁定（零新 ARB、留手动改币种通路）；如 UAT 反馈困惑再补 notice |
</threat_model>

<verification>
- 全量 flutter test 直接执行（不 pipe），基线 3675 passed + 11 skipped 零修改零失败，新增测试 additive 全绿。
- flutter analyze 0；无 // ignore: 新增；git status 确认零 generated/ARB/golden 变更。
- wc -l 五个 lib 文件：voice_ptt_session_mixin / fill_orchestration / foreign_notice / manual_one_step_voice_wiring 全部 <800（manual_one_step_screen 残余若 ≥800 记 SUMMARY，属预期）。
- test/architecture/ 全套通过（含 mod009_live_lib_scan / hardcoded_cjk_ui_scan / layer_import_rules —— part 文件均在其扫描域内）。
- git diff 证明：voice_input_screen.dart 零改动；voice_ptt_session_mixin_test.dart 等全部既有测试零改动。
</verification>

<success_criteria>
- [ ] R3：矛盾压制 / 无矛盾放行 / 空集放行 三组测试先红后绿；execute() 仅 1c 段改写 + 一个私有方法
- [ ] R1：mixin 库三文件各 <800 行；公开 API、私有语义、两宿主 with 子句、harness with 面全部字节不变
- [ ] R2：语音接线段移入 part；keypad/currency 段零改动；残余行数记 SUMMARY
- [ ] 全量 suite 基线零修改零失败 + additive 新测试；analyze 0；零 generated/ARB/golden 变更
- [ ] SUMMARY 记录：机械方案裁定、日期槽位不做的决策、宿主残余行数
</success_criteria>

<output>
Create `.planning/quick/260707-bwy-voice-p1-mixin-split-currency-cross-vali/260707-bwy-SUMMARY.md` when done
</output>
