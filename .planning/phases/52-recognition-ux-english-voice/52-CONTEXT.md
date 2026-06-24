# Phase 52: Recognition UX + English Voice - Context

**Gathered:** 2026-06-24
**Status:** Ready for planning

<domain>
## Phase Boundary

在录入表单**展示** Phase 51 已算好的识别结果——选定类目 + 3 档**定性**置信度带 + 可点备选 chips + 内联纠错（保存时回流 `category_keyword_preferences` KEYWORD 学习表，绝不污染商家表），全程 ADR-012-safe；**同屏**把英文语音补到与中日**实用对齐**（英文类目关键词 + 商家英文别名 + 英文数字词有界兜底 + `localeId` 端到端），并加一个独立于 app UI 语言的语音识别语言切换；ARB parity + 反毒性扫描 + macOS golden 重基线作为合并前**内联**门禁。

**这是「渲染 + 数据补齐」，不是「重算仲裁」。** Phase 51 已产纯领域 `RecognitionReconciler` + `RecognitionOutcome` 契约（`selectedCategoryId` / `ConfidenceBand{strong,medium,weak}` / 排序 `alternates` / `resolvedKeyword` / `keywordMerchantConflict`），band 已由 reconciler 在 domain 算好。Phase 52 只**渲染** band→视觉、把 `alternates` 变 chips、把纠错写回 KEYWORD 表，并把英文做成**数据 + recognizer 接线 + 语音 locale 解耦**之上的加法。

**关键实现前置（已发现）：** `ParseVoiceInputUseCase` 算了 `outcome.band` / `alternates` / `keywordMerchantConflict`，但当前返回的 `VoiceParseResult` **未携带**这三项（只带 `merchantCandidates`/`categoryMatch`/`resolvedKeyword`）——这正是 Phase 51 deferred 的「unread outcome」。把它们 thread 到表单是 RECUX 渲染的前置（D-11）。

**In scope:** RecognitionOutcome → VoiceParseResult → form 的字段 thread；band 纯视觉渲染（+ a11y 隐藏标签）；alternates → 上限 ~3 备选 chips + 出口 chip；保存时纠错回流 KEYWORD 表（写键==读键）；HTML mock-first 设计（连 `VoiceRecordPanel` 一起重 mock，覆盖说话中→落定→纠错全流程）；全量英文类目关键词 + 商家英文别名 + 英文数字词 ~30 行有界兜底（含「X fifty」→X.50）；独立语音识别语言切换（zh/ja/en，与 app UI locale 解耦）+ `localeId` 端到端；ARB parity + 反毒性扫描扩到新 UI + macOS golden 重基线（内联）。

**Out of scope（属后续 / 越界）:** 商家纠正回流学习（`merchant_category_preferences`）= 明确 out（RECUX 只教 KEYWORD 表；本期商家名可编辑/清除但不学习）；商家专属账本 affordance（用商家 ledgerType 列）= 未来；完整口述英文数字状态机 = 不做（只有界 ~30 行兜底 + STT 阿拉伯数字优先）；商家库凑 600-800 / 中国及其他地区目录 / FTS5 = MERCH-V2；重算仲裁 / 改 band 计算 = Phase 51 已定，不动。

</domain>

<decisions>
## Implementation Decisions

### RECUX — 置信度带 + chips 视觉设计（RECUX-01/02）
- **D-01 走 mock-first。** plan 阶段先出 HTML 设计稿（沿用 Phase 43 design gate / 260622-nhs / 260623-0cj 的 mock-first 模式），用户确认选定后再写生产代码。band 视觉、chip 形态、布局、纠错 sheet 形态在稿里定；CONTEXT 只锁约束：ADR-012 纯定性、绝不数字 %/分数/gauge/meter；复用 ADR-019 调色 token，不发明新色板；过反毒性扫描。
- **D-02 mock 范围 = 连 `VoiceRecordPanel` 一起重设计。** 不是「affordance 贴在静态表单上」，而是把就地替换键盘的录音面板（260622-nhs）连同识别 affordance 一起重 mock，覆盖「说话中 → 类目落定 → 纠错」全流程。

### RECUX — band 框架 + chips 限量（RECUX-01/02/04）
- **D-03 band 纯视觉、无可见文字。** 3 档 `ConfidenceBand{strong,medium,weak}` 只用颜色/图标强度表达（如 chip 边框深浅或一个小点），**不显示任何可见文字标签**；仅给 a11y 一个隐藏 `Semantics` 标签供屏幕朗读。结果：零游戏化词风险、无新 ARB band 文案键、反毒性扫描新文案面缩到最小。
- **D-04 chips 上限 ~3 + 一个出口 chip。** 按 reconciler rank 取前 ~3 个备选（冲突时被降级的商家默认类目含在这 3 个里，按 L2 去重）+ 一个末尾「其他/更多」出口 chip 打开完整类目选择器。保证不溢出 + 总有逆路。

### RECUX — 纠错交互（RECUX-03）
- **D-05 教学推迟到保存。** 点 chip 立即换类目 + 重派生 ledger（即时 UI 反馈），但「写 `category_keyword_preferences`」**推迟到用户真正保存成交易时**才发生。避免从「试探/重置/放弃」的草稿污染学习表（现有单页录入有 reset / 连续记账 / 返回）。
- **D-06 chip 和完整选择器都算纠错。** 任何把最终类目改离「识别原始类目」的动作——无论经快捷 chip 还是完整类目选择器——在保存时都记一条纠错。chip 只是快捷；需在表单状态记住「识别原始类目」以检测变更。
- **D-07 写键 = `resolvedKeyword` verbatim；无关键词不教。** 写键 = `outcome.resolvedKeyword`（写键==读键，260526-pg6 orphan-key 契约，locked）。`resolvedKeyword` 为 null（裸商家 / both-weak / 无关键词抽取）时：该笔**不写学习表、绝不写商家表**（商家学习不在 RECUX 范围）。

### RECUX — 提示出现时机（RECUX × 260622-nhs 接缝）
- **D-08 类目一落定就显示。** band+chips 在类目首个 end-of-speech `isFinal` 落定那一刻就渲染到表单（Phase 51 D-02 resolve-on-final）；若录音面板仍在场则两者同时可见（与 D-02「连面板重 mock」一致）。
- **D-09 改后清掉 band。** 用户一旦选定任何类目（chip 或选择器），band 立即清掉——变 user-authoritative，无需「推测」标记；chips 可一并收起。
- **D-10 手工录入不显示。** 手工录入（无识别 outcome）完全不显示 band/chips affordance（correct-by-construction：无 outcome → 无渲染）。

### RECUX — 商家名识别错误
- **D-16 商家名可编辑/清除，但不回流学习。** 商家名是表单里普通可编辑文本预填（现状即是），用户可改可清；改商家名**不教任何表**（守「只教 KEYWORD 表」契约）；本期不加专门商家纠错 affordance。

### VEN — 英文覆盖深度（VEN-01）
- **D-12 全量对齐。** 英文覆盖走全量——每个有 zh/ja 关键词的 L2 都补英文类目关键词；每家有英文名的日本商家都填 `nameEn`/英文别名。research 先确认 Phase 49 merchant `nameEn` 列现有填充率 + 两个 recognizer 的 en-locale 匹配接线，决定是「数据撰写为主」还是「recognizer 接线为主」。
- **D-13 英文货币词复用、不 fork。** 英文货币词已全覆盖（quick task 260614-goh，`VoiceCurrencySuffixes`，longest-first 扫描）。VEN 不新建货币词路径；可按需补 buck/bucks/quid 等口语词（非必须）。

### VEN — 英文数字（VEN-02）
- **D-14 支持「X fifty」→X.50 习语 + 有界兜底。** 英文数字词兜底支持「X fifty」→X.50 价格习语（「five fifty」→5.50），**仅在金钱上下文触发**以防与 550 歧义。其余沿 roadmap 锁定的 ~30 行有界兜底（one…twenty / thirty…ninety / hundred / thousand / a|an→1），**仅当数字正则无命中时触发，绝不进 CJK 数字路径**。英文 STT 阿拉伯数字优先。隔离断言：任何英文 utterance 永不进入 ja/zh 数字路径（防 v1.8 golden WR-04 类回归）。

### VEN — 英文 locale 路由
- **D-15 独立语音识别语言切换。** 给录入加一个语音识别语言选择（zh/ja/en），**独立于 app UI 语言**——ja/zh-app 用户也能直接说英文（owner 旅行场景）。⚠ 这把 `localeId` 与 `currentLocaleProvider`（app UI locale）**解耦**：需 thread 一个 session 语音 locale 端到端到 STT + 两个 recognizer + 数字/货币解析，并守 v1.8 golden WR-04 类回归（golden 需 override 正确 locale provider）。selector 落点（录音面板内 / 表单 / 设置）交 research/plan；优先体验 over 最小接线，但 research 要量化解耦接线面。

### 内联收尾门禁（locked process — RECUX-04/05）
- **D-17 三语收尾全部 Phase 52 内联跑、不延到里程碑 close。** ARB parity（三语键数相等、无 orphan、`flutter gen-l10n` 干净、`git add -f lib/generated/`）+ 反毒性扫描（覆盖新 chips/纠错/band affordance × ja/zh/en × 全状态，**完整**禁词表含 score/streak/accuracy/正确率/連続/ストリーク/達成 — 补 v1.8 WR-02 不完整）+ macOS golden 重基线。商家名是 DATA（Drift 多语列、不进 ARB），类目标签是 ARB（RECUX-05）。

### Claude's Discretion（留 research/plan）
- D-11 outcome→VoiceParseResult→form 的 thread 具体形状（扩 VPR 字段 vs 直接传 outcome）。
- band 视觉/chip 形态/布局/纠错 sheet 形态——HTML mock 里定。
- 语音语言 selector 落点（面板内 / 表单 / 设置）。
- 英文数字词兜底的精确 token 集 + 「金钱上下文」判定逻辑。
- merchant `nameEn` 填充策略（recognizer 接线为主 vs 数据补写为主，看现有填充率）。
- 纠错写路径的具体入口（`recordCorrection` 在 use case / repo 的定位）。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求 / 路线图（authoritative scope）
- `.planning/ROADMAP.md` §"Phase 52: Recognition UX + English Voice" — Goal、7 条 Success Criteria（RECUX-01..05 / VEN-01..02，wave 标注）、Depends on Phase 51（`RecognitionOutcome` 契约）/ 49（alias 列）/ 50（recognizers）、`UI hint: yes`。
- `.planning/ROADMAP.md` §"v1.9 Cross-Cutting Constraints" + §"Pitfall→Phase→Regression-Test Map"（pitfalls 5/7/8/9/10）+ §"Research Flags"（Phase 52 段）— drift 2.31.0/schema 不动、ADR-012 定性置信度、learning-key 身份契约、i18n parity 内联、security。
- `.planning/REQUIREMENTS.md` 行 37-46 — RECUX-01..05 + VEN-01..02 全文。

### Phase 51 产出（必读 — 契约 + 已落地，52 只渲染不重算）
- `.planning/phases/51-cross-validation-daily-joy-ledger-rework/51-CONTEXT.md` — D-09/D-10 `RecognitionOutcome` 契约 + `ConfidenceBand` 由 reconciler 算（52 只 band→视觉，不重算仲裁）；D-05 both-weak 自动填 best-guess（安全靠 52 band+chips affordance）；D-13 `resolvedKeyword` 透传契约。
- `lib/features/voice/domain/models/recognition_outcome.dart` — `RecognitionOutcome`（`selectedCategoryId`/`band`/`alternates`/`resolvedKeyword`/`keywordMerchantConflict`）+ `ConfidenceBand{strong,medium,weak}` 定义 + dartdoc（明言 alternates「for Phase-52 chips」）。
- `lib/features/voice/domain/services/recognition_reconciler.dart` — band 计算逻辑（**Phase 52 不改**）。
- `lib/application/voice/parse_voice_input_use_case.dart` 行 ~100-187 — `reconcile(...)` + 映射到 `VoiceParseResult`；**当前丢弃 `outcome.band`/`alternates`/`keywordMerchantConflict`**（D-11 补 thread）。
- `lib/features/voice/domain/models/voice_parse_result.dart` — `VoiceParseResult` DTO（含 `CategoryMatchResult`/`MatchSource`）；RECUX 要扩字段携带 outcome 三项。

### 录入 UI / 表单（RECUX 落点）
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — 共享表单（4 host）；band+chips 渲染落点；类目选择器 + 商家名字段在此。
- `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` — 单页「按住说话」会话（260622-nhs R1-R8 真机验收）；`VoiceRecordPanel` 就地替换键盘；`PttListenStatus`；类目 resolve-on-final 填表点。
- `lib/features/accounting/presentation/screens/voice_input_screen_helpers.dart` — `extractVoiceKeyword`（消费 `resolvedKeyword`，写==读契约的读侧参照）。
- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` — 单页录入主屏（注：已 >800 LOC，nhs 记录的累积偏差，待后续抽，本期不主动扩）。

### 学习表（RECUX-03 纠错回流）
- `lib/features/accounting/domain/repositories/category_keyword_preference_repository.dart`、`lib/features/accounting/domain/models/category_keyword_preference.dart` — KEYWORD 学习表接口/模型（纠错**唯一**回流目标）。
- ⚠ **绝不**写 `merchant_category_preferences`（商家表）— 守契约。

### 英文语音（VEN）
- `lib/shared/constants/voice_currency_suffixes.dart` — `VoiceCurrencySuffixes`（英文货币词已全覆盖 260614-goh，`regexAlternation` longest-first，复用不 fork）。
- `lib/application/voice/recognition/category_recognizer.dart`、`merchant_recognizer.dart` — 两路引擎；英文关键词/别名匹配接线落点（含 NFKC/锚定匹配的 en-locale 行为）。
- `lib/shared/constants/default_merchants.dart`（`nameEn` 字段，行 ~36/48）、`lib/data/tables/merchants_table.dart`（`nameEn` 列，行 27）— 英文别名数据底座（research 查现有填充率）。
- `lib/infrastructure/voice/{numeral_state_machine,chinese_numeral_state_machine,japanese_numeral_state_machine}.dart` — CJK 数字状态机；英文数字词兜底**不进**这些路径（VEN-02 隔离断言）。
- `lib/application/voice/parse_voice_input_use_case.dart` / `start_speech_recognition_use_case.dart` — `localeId` / 语音语言 threading 起点（D-15 解耦）。
- `lib/features/settings/presentation/providers/`（`currentLocaleProvider`）— app UI locale；D-15 语音 locale 要与之**解耦**（不直接复用作识别语言）。

### 约束 / 已知陷阱（project memory + ADR）
- `MEMORY.md` `voice-form-merchant-floor-bypass` — 明确「deferred WR-01..04 是 Phase 52 inputs（unread `outcome.alternates`/`conflict`/`resolvedKeyword`）」——本 CONTEXT D-11 即补此 thread。
- `MEMORY.md` 学习键身份契约（260526-pg6）— `resolvedKeyword` 写键==读键；纠错教 KEYWORD 表不污染商家表。
- `MEMORY.md` `voice-entry-ios-recognition-gotchas` — iOS 错误码分类 / 一次性 listen / 多位阿拉伯数字解析（英文数字解析参照）。
- `MEMORY.md` `golden-ci-platform-gate` — golden 仅 macOS 重基线；CI ubuntu 用 `BaselineExistenceGoldenComparator`；勿 `dart format` 整个 test/。
- `docs/arch/03-adr/ADR-012`（反游戏化恒久约束）— band 定性、绝不数字/分数/连胜/徽章；若需新 recognition-confidence affordance ADR，`ls docs/arch/03-adr/ADR-*.md` 当前最大 ADR-022、用下一个序号。
- `docs/arch/03-adr/ADR-019`（桜餅×若葉 调色板）— band/chips 复用 `AppPalette` token，不发明新色。
- import_guard / arch test — domain 不 import application/data/infrastructure；recognition 域类型集中在 `features/voice/domain/`（Phase 51 D-11），新增类型沿此落位。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`RecognitionOutcome` + `ConfidenceBand`**：Phase 51 已算 band，52 只渲染——零仲裁逻辑新写。
- **`VoiceCurrencySuffixes`**：英文货币词已全（260614-goh），longest-first 扫描，复用。
- **`TransactionDetailsForm` + `VoicePttSessionMixin` + `VoiceRecordPanel`**：现有录入面，RECUX 在其上加 band/chips affordance（mock 连面板重设计）。
- **现有类目 chip / 选择器样式**：D-04 chips 复用，不重画 chip 原子。
- **KEYWORD 学习表全套**（接口/模型/repo）：纠错回流目标，零新数据层。
- **merchant `nameEn` 列**（Phase 49 已建）：VEN 英文别名数据底座。
- **反毒性扫描范式**（`anti_toxicity_phase47_test.dart` 等）：扩到新 chips/纠错/band UI × ja/zh/en × 全状态。

### Established Patterns
- **mock-first 设计**（Phase 43 design gate / 260622-nhs / 260623-0cj）：新 UI 先出 HTML 稿、用户确认再写代码。
- **band 在 domain 算、presentation 只渲染**（Phase 51 D-10）。
- **resolve-on-final 填表**（Phase 51 D-02）：类目首个 final 落定才填、不随 partial 抖动。
- **写键==读键学习契约**（260526-pg6）。
- **内联三语收尾门禁**（ARB parity + 反毒 + golden）——v1.7/v1.8 lesson，不延到 close。
- **golden 仅 macOS 重基线**（CI ubuntu 平台门）。

### Integration Points
- **`ParseVoiceInputUseCase` → `VoiceParseResult`**：thread `outcome.band`/`alternates`/`keywordMerchantConflict`（D-11，补 unread-outcome）。
- **`VoiceParseResult` → `TransactionDetailsForm`**：渲染 band（纯视觉 + a11y 标签）+ alternates chips（上限 3 + 出口）。
- **chip/选择器 tap → 保存时 → 写 KEYWORD 表**（D-05/D-06/D-07，写键=resolvedKeyword verbatim；null→不写）。
- **语音语言 selector → `localeId` → STT + 两 recognizer + 数字/货币解析**（D-15 与 app UI locale 解耦）。
- **商家名 → 已加密 merchant 字段**：可编辑、不学习（D-16）；不 log 原始 transcript/amount/merchant（security）。

</code_context>

<specifics>
## Specific Ideas

- **band 纯视觉是 ADR-012 + i18n 双重最优**：无词可被游戏化、无新 ARB band 键、反毒扫描面最小（用户明确选「纯视觉、无可见文字」over「确定度措辞」）。
- **chips 上限 3 + 出口 chip**：既给一键纠错又总有完整选择器逆路；冲突降级的商家默认类目含在 3 个内。
- **教学推迟到 save**：单页录入有 reset/连续记账/放弃，tap 即教会从草稿污染学习表——用户明确选「保存成交易时才教」。
- **独立语音语言切换**是用户明确取向（owner ja/zh app + 旅行说英文），优先体验 over 最小接线——但 research 要量化 `localeId` 与 app locale 解耦的接线面 + 守 WR-04 golden-locale 回归。
- **全量英文覆盖**是用户取向（不做高频子集）；research 先看 `nameEn` 填充率决定「数据活」还是「接线活」。
- 「X fifty」→X.50 价格习语用户确认要做，但**仅金钱上下文触发**防与 550 歧义。

</specifics>

<deferred>
## Deferred Ideas

- **商家纠正回流学习**（`merchant_category_preferences`）→ 明确 **out**（RECUX 只教 KEYWORD 表）；本期商家名可改可清但不学。
- **商家专属账本 affordance**（用商家 ledgerType 列）→ 未来（Phase 49/51 保列、断言不读）。
- **完整口述英文数字状态机**（spoken-number state machine）→ **不做**（VEN 只 ~30 行有界兜底 + STT 阿拉伯数字优先）。
- **商家库凑 600-800 / 中国及其他地区目录 / FTS5** → MERCH-V2。

None reviewed-but-deferred from todos（`cross_reference_todos` 无匹配，`todo_count=0`）。

</deferred>

---

*Phase: 52-Recognition UX + English Voice*
*Context gathered: 2026-06-24*
