# Continuous Accounting Hit Target QA — 2026-07-18

- Source visual truth: `/Users/xinz/Downloads/截屏 2026-07-18 15.09.22.png`
- Implementation screenshot: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/continuous-hit-target-manual.png`
- Focused paired comparison: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-continuous-hit-target.png`
- Viewport/state: source mobile frame normalized against a 390px-wide Flutter widget render; manual keypad idle state with continuous accounting disabled. Voice uses the same centered-target contract in every dock state.

## Findings

No actionable P0, P1, or P2 issue remains.

- Fonts and typography: unchanged; the existing summary/action hierarchy and 6px inline spacing remain.
- Spacing and layout rhythm: the manual visual surface still reaches the screen bottom, while its interactive region is centered at 230×43 and excludes the bottom safe-area buffer. Voice uses a centered 230×27 interactive region.
- Colors and visual tokens: unchanged; the summary stays secondary and the mode action stays primary green.
- Image and icon fidelity: no image or icon changes were required.
- Copy and content: localized continuous/non-continuous wording is unchanged.
- Interaction evidence: manual and voice corner taps outside the centered target are ignored; taps inside the padded target toggle once. Semantics remain button/toggled controls on the constrained target.

## Comparison history

1. Before the change, the manual control's full 390px footer toggled the mode, while voice only made the action text tappable.
2. Both paths now use the same centered 230px-wide target. The surrounding footer, dock corners, and manual bottom buffer are non-interactive.
3. Post-fix widget tests pass for both manual keypad and voice dock; the focused capture confirms there is no unintended visual change.

final result: passed

---

# Manual Entry UI Design QA

- Source visual truth:
  - `/Users/xinz/Downloads/截屏 2026-07-18 13.55.24.png`
  - `/Users/xinz/Downloads/截屏 2026-07-18 13.56.53.png`
- Implementation captures:
  - `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/amount-clear-after-digits.png`
  - `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/voice-review-record-action.png`
  - `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/note-keyboard-toolbar.png`
- Viewport: 390 × 844 for the form captures; the voice dock is rendered at its exact 390 × 336 component contract inside the Flutter test surface.
- States: non-empty JPY amount; voice review ready to record; note field focused with keyboard accessory toolbar.

## Full-view comparison evidence

The note-focus capture shows the full 390 × 844 entry form. Voice provenance badges and the confidence marker above the purpose card are absent, while the keyboard toolbar remains aligned to the bottom edge. The voice-review capture shows the complete dock and its inset primary action.

## Focused comparison evidence

- Amount: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-amount.png`
- Voice review action: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-voice-action.png`
- Note keyboard toolbar: `/Users/xinz/.codex/visualizations/2026/07/18/019f7320-13de-7752-a730-71b36a01a307/comparison-note-toolbar.png`

## Findings

No actionable P0, P1, or P2 differences remain for the requested changes.

- Fonts and typography: existing `AppTextStyles` and the current amount size are preserved. Flutter widget captures use the deterministic test font, so production glyph shapes are verified by widget/icon identifiers rather than judged from the capture raster.
- Spacing and layout rhythm: the clear action follows the amount; the voice record action has 16 px horizontal insets; both keyboard-toolbar actions keep balanced padding.
- Colors and visual tokens: Record uses `accentPrimary`; Done retains the card/outline treatment; existing background and border tokens are unchanged.
- Image and icon fidelity: no new raster assets are needed. The voice and keyboard actions use Material receipt/keyboard icons; the submitting state no longer substitutes the loop icon in the Record action.
- Copy and content: all `Voice filled` provenance badges and the decorative confidence marker are absent. Existing localized Record and Done labels remain.

## Comparison history

1. Source screenshots showed the amount clear action before the amount, a full-width voice Record button with a loop icon, a pink text-only keyboard Record action, and visible voice-source/confidence decorations.
2. Implementation moved the clear action after the amount, inset the voice action, fixed its icon, made the keyboard Record action green, added icons to Record and Done, and hid the two decoration types.
3. Post-fix focused captures confirm the new geometry and visual tokens. Widget tests additionally assert exact icon data, color, width, ordering, and absence of the removed markers.

## Follow-up polish

- P3: a real-device screenshot can be used later for production-font raster comparison; no layout or behavior change depends on it.

final result: passed

---

# Home Pocket Design QA

## 2026-07-16 — 编辑交易与统一记账视觉收敛

**Comparison target**

- Source visual truth: the shared Flutter form implemented by `TransactionDetailsForm.edit`, `AmountDisplay`, `DetailInfoCard`, `LedgerTypeSelector`, `SatisfactionEmojiPicker`, and the fixed save area in `lib/features/accounting/presentation/screens/transaction_edit_screen.dart`; the V16 unified-entry component language in `docs/mockup/v16/index.html` is the visual sibling to match.
- Implementation: `docs/mockup/v16/index.html`, route `edit`, light theme, Chinese locale.
- Intended viewport: 390×844 CSS px. Required states: JPY daily, JPY Joy, USD foreign-currency linkage, submitting, amount sheet, and delete confirmation.
- Implementation screenshot path: unavailable. The in-app browser local `file://` page cannot be captured through the available browser automation because its URL safety policy rejects the local target.
- Full-view comparison evidence: unavailable for the same blocker; no visual pass is inferred from source inspection or DOM tests.
- Focused-region comparison evidence: unavailable. Header, amount, purpose, satisfaction, note, foreign linkage, save dock, amount sheet, and delete confirmation still require rendered crops.

**Code-grounded findings and fixes**

- [P1] The prior edit route used a separate 9/11px legacy form language (`amount-display`, `flat-card`, and `form-row`) while unified entry used semantic typography and `entry-*` components. The route now uses `accounting-screen`, the same 52px centered `entry-header`, 44px horizontal `entry-amount`, `entry-form`, `entry-purpose-card`, conditional satisfaction, and `entry-note-card`.
- [P1] The previous screen showed two destructive actions: a header icon and a page-bottom delete button. The bottom duplicate is removed; the only delete control is the error-colored header icon, and its dedicated confirmation sheet must complete before navigation.
- [P1] Merchant, purpose, and note were presented as static rows, and Joy satisfaction was absent. Merchant and note are now real editable fields, daily / Joy are accessible pressed-state controls, and Joy alone reveals five values mapped to 2 / 4 / 6 / 8 / 10.
- [P2] The previous edit layout did not represent foreign transactions or the existing amount-sheet behavior. The inspector now exposes a USD state whose headline remains in original currency and whose separate linkage card contains editable rate, read-only derived JPY, and rate date. Tapping the headline opens a bottom keypad while keeping currency immutable.
- [P2] Save previously scrolled with content and used the old page composition. It now sits in a fixed surface dock with the standard primary green, disables during submission, rejects duplicate saves, and returns to the actual home/list origin. Edit intentionally contains no voice entry, persistent keypad, or continuous-accounting control.

**Static and interaction verification**

- TDD contract first failed on the legacy `edit()` structure, then passed after the shared component rebuild: `flutter test test/architecture/main_surface_typography_contract_test.dart` — 5/5 passed.
- Inline JavaScript compiles. `/private/tmp/v16_edit_contract_test.cjs` passes shared structure, independent edit draft, merchant/note editing, daily/Joy switching, satisfaction, foreign linkage, amount confirmation, save double-submit protection, delete confirmation, and source-aware return.
- Existing `/private/tmp/v16_voice_contract_test.cjs` and `/private/tmp/v16_shopping_voice_contract_test.cjs` continue to pass; all 60 rendered `data-action` values have handlers.
- A rendered 390×844 comparison is still required before this section can pass visual QA. The required next pass must capture all four inspector states plus the amount and deletion sheets, check typography, spacing/rhythm, colors/tokens, icon fidelity, and app-specific copy, then fix any visible P0/P1/P2 mismatch.

final result: blocked

---

## 2026-07-16 — V16 统一记账、账目编辑与新增购物项实现验收

本节记录三张生产 Flutter 页面完成后的最终验收，并覆盖本文中同日关于本地页面
无法渲染、因而标记为 blocked 的历史结论。

**Comparison target**

- Source visual truth: `docs/mockup/v16/index.html`.
- Implementation: `ManualOneStepScreen`, `TransactionEditScreen`, and
  `ShoppingItemFormScreen`, together with their shared V16 amount, form,
  keyboard, selector, and voice-draft widgets.
- Viewport/state: 390×844 logical pixels, light theme; Chinese for unified
  entry/edit and Japanese for shopping create. Each final comparison places the
  source reference on the left and the rendered production Flutter widgets on
  the right in the same image.
- Unified entry reference / implementation / comparison:
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-entry-reference.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-entry-implementation.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-entry-comparison-final.png`
- Transaction edit reference / implementation / comparison:
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-transaction-edit-reference.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-transaction-edit-implementation.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-transaction-edit-comparison-final.png`
- Shopping create reference / implementation / comparison:
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-shopping-form-reference.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-shopping-form-implementation.png`
  - `/Users/xinz/.codex/visualizations/2026/07/16/019f6a6c-74de-7a63-a8bd-fa4d698b4b07/v16-shopping-form-comparison-final.png`

**Visible findings and fixes**

- Unified entry now matches the V16 amount hierarchy, compact information
  cards, purpose and satisfaction controls, neutral voice launch, 48dp keypad,
  primary record action, history action, and inline continuous-accounting row.
- Transaction edit reuses the same amount and form language, keeps amount
  editing explicit, presents a single destructive header action, and anchors
  the checked save action above the system bottom inset.
- Shopping create follows the source field order and card rhythm, with the
  compact quantity stepper, shopping-only purpose/privacy selectors, category,
  reference price, memo, right-side save action, and a single in-page voice
  draft surface.
- The first paired pass exposed amount-symbol/currency-chip scale, continuous
  control composition, edit affordances, and shopping card-spacing differences.
  Those were corrected before the final three paired captures above.
- No actionable P0/P1/P2 visual mismatch remains. P3 accepted: the HTML source
  includes a decorative phone frame, browser status bar, and home indicator,
  while the Flutter harness renders the production content with real top/bottom
  safe-area reservations. Native glyph antialiasing also differs slightly from
  the browser capture.

**Interaction and resilience checks**

- Unified voice entry covers idle, listening, processing, review, and
  unavailable states. Save stays disabled during recognition, parsing, and
  re-record cancellation; delayed partial results cannot overwrite a newer
  final result; weak/below-floor categories clear the default and require an
  explicit choice; voice-filled fields expose localized provenance markers.
- Snapshot restore keeps JPY and foreign-currency booked/original units
  consistent, and continuous mode resets atomically for the next entry.
- Shopping voice input recognizes Japanese, Chinese, and English name,
  quantity, purpose, category, and JPY price phrasing without inferring
  privacy. Unsupported foreign prices are ignored safely, re-record and
  keyboard transitions invalidate stale callbacks, and no voice path auto-saves.

**Verification**

- Final 390×844 production-widget render: 3/3 passed and all three paired
  comparisons inspected together.
- Focused V16 accounting/shopping regression set: 108/108 passed.
- ARB parity, hardcoded-CJK scan, and V16 typography/mockup contracts: 8/8
  passed.
- Full `flutter test`: 3,835 passed, 11 skipped.
- `flutter analyze`: 0 issues.
- `flutter gen-l10n` completed; final `git diff --check` passed.
- Existing non-blocking tooling warning: `sqlcipher_flutter_libs` does not yet
  advertise future Flutter Swift Package Manager support.

final result: passed

---

## 2026-07-16 — 购物项表单同步与语音草稿提案

**代码审查结论**

- 当前 Flutter 新增 / 编辑共用 `ShoppingItemFormScreen`，真实顺序是名称、数量、用途（日常 / 悦己）、类型（公开 / 私有）、分类、参考价格和备注；新增默认数量 1、日常、公开，保存位于 AppBar 右侧。
- 公开项目进入同步变更链，私有项目只在本机保存；类型创建后不可更改。购物 Tab 的 FAB 和空态入口目前都以 `public` 打开新增表单，不继承筛选值。
- 原 V16 购物表单静态预填“オリーブオイル”，只展示数量、分类、列表和备注，并把家庭模式错误映射为共享 / 个人，遗漏用途、参考价格、数值步进器、编辑锁定和真实保存校验。
- 现有代码仍有后续实现债务，本次只审查未改动 App：编辑时清空参考价格会被更新用例解释为“不修改”；分类没有清除入口；名称的 200 字数据库上限没有前端校验；现有 36px 保存与 38px 步进按钮小于推荐触控目标。

**Mockup 调整**

- `shopping-form` 已改为当前 App 的七字段结构，新增态为空名称、数量 1、日常、公开；数量使用不低于 1 的 44px 步进器，分类展示完整路径，参考价格直接输入，备注使用多行字段。
- 保存移到右上角并使用普通主绿色；名称为空时留在当前页显示错误，聆听 / 解析和提交期间不可重复保存。公开 / 私有始终独立于家庭模式，新建可切换，编辑禁用。
- “保存后不可更改”已收进公开 / 私有的类型控制区，并直接位于两个选项下方；它不再作为数量、用途和类型三行之后的整卡提示，因此数量与用途明确保持可编辑。新增态使用中性提示，编辑态才使用红色锁定提示。
- Inspector 增加手动、聆听、识别回填、编辑态和麦克风不可用五个入口；长按购物项的编辑动作也进入同一编辑表单。

**语音可行性与边界**

- 结论：可添加。可以复用 `SpeechRecognitionService`、`StartSpeechRecognitionUseCase`、语音语言 / 权限 / 设备端优先设置和 3 秒静音自动结束能力。
- 不可直接复用交易的 `ParseVoiceInputUseCase`、`VoiceParseResult` 或 `VoicePttSessionMixin`；它们绑定金额、商家、交易日期与 `TransactionDetailsFormState`，没有商品名称、数量或参考价格语义。
- Mockup 采用同页草稿：名称下方的中性语音卡片是唯一入口，约 3 秒停顿自动解析，中央按钮可提前结束；解析后直接回填表单，中央麦克风复用为重新录音，右上保存仍是唯一持久化动作，没有取消、独立确认或新路由。
- MVP 一次只处理一个商品。示例“牛乳を2本、日常、参考価格500円”填入名称、数量、用途、分类建议和参考价格；未口述备注保持原值，公开 / 私有始终保持录音前值，不由识别结果推断。
- 录音或解析中切回键盘会恢复快照；回填后切回键盘会保留结果；离页、重录和取消中的旧回调由会话序号拒绝。隐私文案改为“端末内認識を優先”，准确反映当前可配置云端降级。

**静态与交互验证**

- TDD 合同先以缺少 `data-shopping-input="name"` 失败，再完成实现；`flutter test test/architecture/main_surface_typography_contract_test.dart`：4/4 通过。
- 当前 App 的购物表单、新增用例和更新用例定向测试：34/34 通过；`flutter analyze test/architecture/main_surface_typography_contract_test.dart`：0 issues。
- `/private/tmp/v16_shopping_voice_contract_test.cjs` 通过：覆盖七字段默认值与 DOM 顺序、3 秒自动端点、手动停止、同页回填、公开 / 私有保持、未口述字段保持、键盘恢复 / 保留、旧回调失效、重录快照、名称校验、数量下限、提交态和编辑锁定。
- 既有 `/private/tmp/v16_voice_contract_test.cjs` 继续通过；内联 JavaScript 可编译，53 个渲染动作均有处理分支，范围内 `git diff --check` 通过。
- 浏览器自动化仍被本地 `file://` URL 安全策略阻止，因此本节没有新的 390×844 完整截图，不能标记视觉 QA 已通过。

**下一次视觉核验**

- 在 390×844 下刷新购物项目页，分别截取手动、聆听、解析、识别回填、编辑和权限不可用状态。
- 重点检查右上保存、名称与单一语音入口、44px 步进器、两组段控件、语音状态行、长文本换行、表单滚动和浅 / 深色对比度；修正所有 P0 / P1 / P2 后再将本节改为 passed。

final result: blocked

---

## 2026-07-15 — V16 整 App Mockup 同步与收口

**结果**

- 当前唯一整 App 交互基准已迁移到 `docs/mockup/v16/index.html`；`.planning/sketches` 中的 004/005/006 重复稿已由 V16 取代。
- 四个主页面统一到当前 `MainSurfaceHeader`：顶部 11px、左右 20px、46px 标题栏、20/28/700 标题、13px 正文间距、40px 操作区与 24px 图标。购物页补齐右侧设置入口。
- 购物筛选恢复带边框卡片、私有与类目二级筛选；家庭态显示“全部 / 个人”，并保留账簿筛选。类目使用购物专用 L1 多选底部面板，支持清空、取消和应用。
- 当前 mockup 清理只移除 `.planning/sketches` 中竞争性的整 App 重复稿；规划输入 001–003、quick 记录、设计审核、已归档里程碑证据，以及仍被 quick 计划直接引用的 V15 源文件继续保留，避免破坏历史引用。

**浏览器验收**

- 375 / 390 / 430 三档工具宽度均按真实像素生效且主屏横向溢出为 0；修正了 V15 中“430 按钮实际仍收缩到 390”的画布轨道问题。
- 主页、明细、统计、购物四页实测标题栏均为 46px、标题 20/28/700、正文间距 13px；主页/明细/统计各有两个 40×40 操作，购物有一个设置操作，全部图标为 24px。
- 购物设置入口可进入设置页并返回购物页；私有筛选得到“味噌 / コーヒー豆”，再叠加食费类目后仅剩“味噌”，继续切换悦己账簿会显示过滤空态。
- 家庭预设会把账簿、私有与类目恢复初始值；切换“全部 / 个人”范围也会执行同一重置。个人深色与家庭浅色均无横向溢出。
- 类目底部面板完整贴合手机画布底部，操作栏未溢出；浏览器控制台 0 error / warning，内联 JavaScript 语法检查通过。

**自动化验证**

- `flutter test test/architecture/main_surface_typography_contract_test.dart`：3/3 通过，覆盖 Flutter 字体契约、V16 字体令牌以及共享标题栏/购物筛选标记。
- `flutter analyze`：0 issues。
- 范围内 `git diff --check`：通过。

final result: passed

---

## 2026-07-16 — 统一记账方案 1「单页连续输入」

**Comparison target**

- Implementation: `docs/mockup/v16/index.html`, the single unified-entry page across idle, listening, processing, recognized-result, and unavailable states.
- Intended viewport: 390×844 CSS px, light theme, Chinese locale, listening → automatic processing → recognized result → optional continuous idle.
- Earlier references:
  - listening: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_Tm5WgM/截屏2026-07-16 13.20.36.png`
  - parsed result: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_fhqPuc/截屏2026-07-16 13.20.45.png`
- Latest user-supplied revision evidence:
  - listening with redundant cancel action: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_pXZwLD/截屏2026-07-16 14.54.58.png`
  - result with overlapping copy and duplicate rerecord action: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_QLjlcl/截屏2026-07-16 14.55.56.png`
  - over-accented manual voice launch: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_ezFcuC/截屏2026-07-16 15.18.39.png`
  - over-accented keyboard switch: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_lcBZoQ/截屏2026-07-16 15.18.53.png`
  - over-accented record and continuous actions: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_UjwKrW/截屏2026-07-16 15.18.59.png`
- Approved interaction direction: one page, automatic endpointing with optional immediate stop, a keyboard shortcut fixed at the top-right in every state, one central microphone control, one final record action, and continuous-accounting state inherited throughout the voice flow.
- Cropped implementation evidence is available through the latest user captures, but no screenshot exists after the current palette correction and no complete 390×844 frame is available because the in-app browser refuses automated access to the local `file://` page under its URL safety policy.

**Latest findings and fixes**

- [P1] Result copy overlaps the top status
  - Evidence: the latest result capture places “用语音填写账目” directly over “已填入账目”.
  - Fix applied: the redundant visible title is now screen-reader-only; the empty result-chip row was removed; the dock is fixed at 336px; and the privacy note, centered status, and keyboard action now use a three-column grid instead of overlapping absolute positions.
- [P1] Rerecord appears twice
  - Evidence: the latest result capture shows a central microphone and a separate bottom “重新录音” button for the same action.
  - Fix applied: the central microphone is the sole `entry-voice-rerecord` control. The result action slot contains only one full-width “记录” button, which confirms and saves in one step.
- [P2] Listening cancel action dominates the bottom of the dock
  - Evidence: the latest listening capture gives “取消本次语音” the largest visible footprint despite automatic endpointing and the persistent keyboard escape.
  - Fix applied: no cancel button is rendered in listening or processing. Users can wait for the 3-second endpoint, tap the central stop control to finish immediately, or switch to keyboard from the fixed top-right action.
- [P2] Joy color was applied to ordinary navigation and completion controls
  - Evidence: the three 15:18 captures show the manual voice launch, keyboard switch, final record action, and continuous-accounting link all competing in the same Joy pink as active voice feedback.
  - Impact: Joy reads as a ledger/voice-state accent instead of a focused state signal, while ordinary navigation and save controls drift away from the rest of the app.
  - Fix applied: Joy remains only on status dots, waveform, and the central listening/idle/review control. The manual voice launch is now a neutral surface/border/text card with only its icon using existing primary-soft/primary tokens; the keyboard switch uses neutral surface/border/muted-text; record returns to the standard `--hp-primary` action; and the voice-source marker plus continuous accounting use the ordinary primary family. No token or hex value was added.
- [P1] Continuous accounting was absent from voice entry
  - Impact: the setting visibly changed between manual and voice input, and a continuous voice save returned to the keypad.
  - Fix applied: manual and voice docks call the same continuous-accounting control. All five voice states preserve the same `aria-pressed` value. A continuous voice save clears the completed transaction and stays on the voice dock in a safe `idle` state; the microphone does not restart until the user taps the central control.

**Static implementation checks completed**

- Inline JavaScript compiles; all 44 rendered `data-action` values have handlers.
- All five voice states render the same status, keyboard, transcript, waveform, central-control, action-slot, and continuous-accounting structure in the sole `entry` route.
- Listening contains no rendered cancel action; review contains exactly one central rerecord action and one bottom record action. The visible duplicate voice title is absent.
- Fake-timer state tests cover the exact `2999ms listening → 3000ms processing → 3650ms review` endpoint, immediate stop idempotency, keyboard escape, stale-callback rejection, rerecord restoration, regular save, continuous voice save, safe idle, and explicit next-recording start.
- CSS contracts cover one fixed 336px dock, a 60px central control, a 44px keyboard target, the non-overlapping three-column status line, reduced motion, focused Joy feedback, neutral navigation, and standard primary actions.
- `flutter test test/architecture/main_surface_typography_contract_test.dart`: 3/3 passed.
- A rendered 390×844 same-state comparison is still required before marking visual QA passed.

**Next visual QA pass**

- Capture refreshed listening, review, and continuous-idle states at 390×844.
- Include the manual voice launch plus focused crops of the neutral keyboard switch, standard record action, voice-source marker, and continuous-accounting link.
- Compare the complete frames and verify the status line, transcript, waveform, central control, bottom action slot, keyboard target, and continuous row across states.
- Fix any remaining P0/P1/P2 mismatch and repeat the comparison.

final result: blocked

---

## 2026-07-15 — 购物清单完成勾选状态精确还原

本节是最新完成态视觉验收，并覆盖本节先前“所有账本统一使用主绿色完成圆”的
历史说明。最终规则是：完成圆恢复各自未完成时的账本色，再由整张完成卡片统一
弱化，日常和悦己保持可辨识。

**对照目标与证据**

- 用户完成态参考：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_sQqc94/截屏2026-07-15 17.02.49.png`
- 最终 iOS 完整购物页（日常与悦己同时完成）：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-ledger-colors-native-final.png`
- 最终聚焦对照（上方用户参考，下方悦己/日常实现）：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-ledger-colors-comparison.png`
- 双账本完整页面 golden：`test/golden/goldens/shopping_list_screen_v15_light_ja.png`
- 状态：简体中文、个人模式、浅色主题；iOS 实现同时包含一个悦己完成项和一个日常完成项。实现保留 68dp 可读行高与现有账本语义；参考中的商品名、分类和“个人”徽标只作为完成态层级与对号位置依据。

**发现与修正历史**

- [P1] 完成态原先分别给正文、账本徽标和右侧字形添加 0.58 透明度，卡片表面、边框和勾选圆没有一起弱化，导致视觉不像同一个完成状态。现在由完成卡片持有唯一的 `AnimatedOpacity(0.58)`，背景、边框和全部内容统一淡化，子区域不再重复叠加透明度。
- [P1] 上一轮把日常和悦己完成圆都改成 `accentPrimary`，虽然柔和，但抹掉了两个账本原有的颜色区分。按最新反馈，完成圆现在直接复用未完成圆环已有的 `ledgerColor`：日常为 `palette.daily`，悦己为 `palette.joy`；唯一的整卡 0.58 透明层让两者在完成后自然稍淡。未增加完成态专用颜色。
- [P2] 彩色账本胶囊在完成态淡化后仍带绿/粉色倾向。完成态保留“日常/悦己”文字语义，但视觉改为现有 `backgroundMuted` + `textSecondary`，合成后的米色底 `#F1EBE0` 与参考一致。
- [P2] 右侧完成字形以次级文字色为基色会比参考图过浅。完成态改用 `textPrimary` 后再随整卡弱化，和划线标题形成同一层级。
- [P1] 首轮实现错误地把 Flutter `Icons.check` 保持在圆心，未还原参考图明显的右下光学位置。重新测得参考圆心 `(60.5, 65.5)`、对号轮廓中心约 `(69, 68.5)`，即右 `8.5px`、下 `3px`；映射到当前 28dp 圆后用 `Offset(5, 2)` 修正。最终真机圆为 84px，对号轮廓相对圆心实测右 `15.5px`、下 `7px`，已经呈现同样的右下关系。
- 当前 V16 HTML mockup 已同步整卡 0.58、日常完成绿、悦己完成粉、中性完成徽标和主文字色手柄；其 Material Symbols 网页字形本身具有参考图的右下光学边界，因此没有叠加 CSS 位移，避免双重偏移。未增加颜色令牌或图标资源。

**五项视觉检查**

- 字体：商品标题继续使用现有 item-title 样式并保留删除线；副标题与徽标继续使用 supporting/compact 层级。真机中文字形完整，没有裁切或溢出。
- 间距与布局：完成卡继续使用当前 68dp 行高、28dp 勾选圆和 44dp 右侧槽位，与待购行保持一致；圆本身仍垂直居中，对号绘制位置单独右移 5dp、下移 2dp，交互命中区不变。
- 颜色：完成圆基色复用现有日常绿 `#5FAE72` 和悦己粉 `#D98CA0`，再通过唯一的整卡 0.58 透明层与页面背景合成。最终真机截图中日常为柔和浅绿、悦己为柔和浅粉，既符合“略淡一些”，也能在不依赖文字的情况下区分账本。
- 图像与图标：没有新增图片、SVG、自绘图标或近似资产；继续使用应用现有 Material 勾选与拖动字形。最终聚焦对照明确显示对号不在圆心，而位于参考要求的右下区域。
- 文案与内容：完成态只改变视觉表达；商品名、数量、账本归属、本地化和完成/恢复行为保持原有业务含义。

**验证**

- RED 阶段先把悦己完成圆的期望改为 `palette.joy`，稳定复现旧实现仍返回统一 `accentPrimary`；随后新增日常完成圆的独立颜色断言。
- 修正后购物项与购物页 widget 测试 40/40 通过；覆盖日常/悦己完成 fill 与 border、唯一整卡 0.58、子区域无二次透明度、中性徽标、主层级手柄，以及对号 `Offset(5, 2)` 的位置契约。
- 购物项三语明暗变体与完整 V15 购物页 golden 共 19/19 通过；完整页面 fixture 同时放入日常与悦己完成项，验证两个基色经过真实 0.58 合成后仍明显不同。更新后的基线已再次无更新参数复跑确认。
- `flutter analyze`：0 issues。
- iPhone 16e 模拟器中真实勾选一个悦己商品后，与已有日常完成项同屏检查；最终聚焦对照把用户参考和两种完成颜色放在同一张输入中。结果显示悦己淡粉、日常淡绿、右下对号、删除线和统一弱化均正确，未发现本次范围内剩余的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — 购物清单单项管理、直接拖动与 V15 完成态

**对照目标与证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.45.41.png`
- 修改后 iOS 列表渲染：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-after-drag.png`
- 长按正文操作菜单：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-action-sheet-real.png`
- 同高并排对照：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/shopping-source-vs-implementation.png`
- 状态：简体中文、个人模式、浅色主题、iPhone 16e；实现截图使用两条待购项和一条完成项。参考图处于旧的批量选择态，而实现图展示本次要求的常规单项管理态。

**发现与修正历史**

- [P1] 整行原先同时承载延迟拖动和批量选择长按，正文长按会进入多选，右侧也没有独立的拖动热区。已拆成两个相邻命中区：正文负责编辑/单项菜单，右侧 44×48dp 手柄独占延迟拖动。
- [P1] 页面保留“排序”按键、批量选择顶栏和批量删除底栏。已从购物页与主壳移除这些入口；旧的 provider 状态即使残留也不会隐藏底部导航或重新显示批量 UI。
- [P1] 正文长按缺少单项管理菜单。待购项现在显示“修改 / 置顶 / 置底 / 删除”，删除复用语义错误色；修改进入原有商品表单，置顶/置底与拖动共同复用连续排序写入。完成项继续遵循既有“按完成时间排列”的数据契约，因此只提供修改与删除，右侧显示 V15 的弱化非交互拖动字形。
- [P2] 完成态曾分别改写文字颜色和透明度，视觉层级与 V15 不一致。现在勾选圆保持全饱和绿色，名称/数量、账本徽标和右侧字形统一使用 0.58 透明度，名称保留删除线。
- 当前 V16 HTML mockup 已同步移除排序按键和批量选择逻辑，加入正文长按菜单、红色删除项及右侧手柄直接拖动；没有新增图标资产，继续使用应用现有 Material 拖动字形和勾选图标。

**五项视觉检查**

- 字体：标题、区段标题、商品名称、数量、徽标和底部菜单均沿用现有 `AppTextStyles` 与原生中文字体；删除项只改变语义色，不改变字号或字重体系。
- 间距与布局：待购项继续组成一个 68dp 行高的列表卡；完成项保持独立卡片。44dp 右侧拖动热区与正文命中区互不重叠，移除排序/批量栏后页面节奏与 V15 常规态一致。
- 颜色：未新增颜色令牌；活动勾选环、完成勾选、日常徽标、弱化完成态和错误红色均复用现有语义色。操作菜单遮罩、卡片和圆角使用主题表面色。
- 图像与图标：未增加图片、SVG 或自绘图标；拖动继续使用现有 `drag_indicator`，完成勾选继续使用现有应用图标体系。
- 文案与内容：新增三语“修改 / 編集 / Edit”键；置顶、置底和删除复用既有三语键。列表不再出现“排序”、取消/全选、已选数量或批量删除文案。

**验证**

- RED 阶段先复现旧批量栏、旧排序入口、缺少正文/手柄分区、缺少四项菜单及完成态透明度不一致。
- 修正后相关 shopping/home widget 测试 40/40 通过；新增覆盖正文四项菜单、删除红色、编辑导航、置顶/置底顺序、右侧延迟拖动、手柄长按不弹菜单、遗留批量状态不显示 UI，以及完成态 0.58 视觉契约。
- 购物项与完整购物页 golden 19/19 通过；三语 ARB 键一致性与硬编码 CJK 扫描 3/3 通过。
- `flutter analyze`：0 issues；范围内 `git diff --check`：通过。
- iOS 模拟器实测确认：正文真实长按显示四项操作且删除为红色；右侧手柄真实长按拖动后 Bread/Milk 顺序成功互换且未弹菜单；完成项的实心勾选、删除线和整体弱化与 V15 对照一致。
- 并排图已按同一高度归一化并检查字体、间距、卡片边界、完成态、手柄和底部导航；未发现本次范围内剩余的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — 统计页“全部”文案与空数据图形骨架

**对照目标与证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.42.35.png`
- 修改后 iOS 空月份渲染：`/private/tmp/analytics-picker-live.png`
- 圆环与控制区稳定渲染：`/private/tmp/analytics-empty-final.png`
- 全页并排对照：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/analytics-empty-source-vs-implementation.png`
- 聚焦并排对照：`/Users/xinz/.codex/visualizations/2026/07/15/019f6446-9055-7bd2-b8f7-38a3c2374afe/analytics-empty-focused-comparison.png`
- 状态：简体中文、个人模式、浅色主题、全部账本、无交易月份。参考截图为 2026 年 5 月、440×956；实现验收为 2026 年 2 月、390×844。两者都是同一业务空态；并排图按实现视口归一化，2 月日期轴按实际 28 天显示 6/12/18 日。

**发现与修正历史**

- [P2] 趋势首项复用了 KPI 专用“支出合计”文案。已新增趋势专用三语键：中文“全部”、日文“すべて”、英文“All”；KPI 卡原有“支出合计”不受影响。
- [P1] 空数据时趋势组件提前返回固定高度空盒，导致网格和日期轴一起消失。已让同一个 `LineChart` 始终构建；空态仅不给折线数据，并保留 0 基线、横向网格和日期轴，不伪造一条零值曲线。
- [P1] 分类/成员为空时 `DonutHero` 完全跳过 `PieChart`。已在原有 `PieChart` 内使用一个无标题的中性 track section，维持 63px 环宽和 58px 中心孔；分类与成员两种维度行为一致。
- 当前 V16 mockup 已同步首项文案，并支持 `?analytics-empty=1`：空态保留坐标轴、隐藏数据曲线/端点、显示 ¥0 提示和中性圆环，不回退到默认彩色 fixture。

**五项视觉检查**

- 字体：分段文案沿用现有 segmented-control label token；坐标轴、中心金额和笔数继续使用现有 compact/amount 样式，没有新增字号。
- 间距与布局：趋势卡高度、四条网格线、日期刻度、圆环 63/58 几何和下方控制区均保持原 V15 尺寸；空态与有数据状态不会发生布局跳变。
- 颜色：坐标网格继续使用 `backgroundDivider`；空圆环复用同一个中性 token，浅色截图中清晰可见且不暗示任何分类占比。
- 图像与图标：本次没有新增图片、图标或自绘资产；空圆环继续复用现有 `fl_chart`。
- 文案与内容：首项只在趋势分段改为“全部”；提示仍为“本月 ¥0”，圆环中心仍为“本月支出 / ¥0 / 0笔”。

**验证**

- RED 阶段三个回归分别复现：找不到“全部”、空态没有 `LineChart`、空态没有 `PieChart`。
- 修正后 34 项相关 widget 测试全部通过，覆盖空趋势的轴/网格/无折线、三语趋势专用文案和空圆环的中性色、半径、中心孔及无图例。
- ARB 键一致性与硬编码 CJK 扫描共 3 项架构测试通过。
- `flutter gen-l10n` 已更新三语生成文件；两份 HTML 内联脚本均通过 JavaScript 语法检查。
- `flutter analyze`：0 issues；`git diff --check`：通过。
- iOS 原生字体空月份对照确认：首项为“全部”，趋势空态仍有横向网格、0 基线和日期轴，分类卡仍有完整中性圆环；未发现本次范围内剩余的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — 列表页月历日期字号与金额裁切修正

**对照目标与证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.39.41.png`
- 修改后 iOS 实机渲染：`/private/tmp/list-calendar-after-fix-stable.png`
- 全页并排对照：`/private/tmp/list-calendar-reference-vs-implementation.png`
- 月历聚焦对照：`/private/tmp/list-calendar-focused-comparison.png`
- 状态：简体中文、个人模式、浅色主题、全部账本、2026 年 7 月、15 日有金额。参考截图为 440×956，实机验收为更窄的 390×844；并排图按高度归一化，聚焦图裁切到相同月历区域。模拟器包含两笔当日交易，因此金额为 13.3千而非参考图的 1.2千，布局与显示规则一致。

**发现与修正历史**

- [P2] 非本月日期字号偏大：`enabledDayPredicate` 先将外月日期判为 disabled，第三方月历优先走默认 disabled 样式，绕过应用的 11px 日期样式。已增加 `disabledBuilder`，让外月日期复用同一日期单元格，同时保留灰色透明度和不可点击行为。
- [P1] 日金额下半部被裁切：金额使用 15px compact 行高，但容器仅 10px 高。已将金额槽位改为 `AppTypography.compactLineHeight`，保留当前字号并完整显示文字。
- 修正后的聚焦对照中，外月 29/30 与本月 1/2 的字面尺寸一致；13.3千的所有笔画完整可见，没有裁切或挤压。

**五项视觉检查**

- 字体：所有日期继续使用现有原生字体栈与 11/15 compact token；外月仅改变透明度，不再改变字面尺寸。
- 间距与布局：44dp 日历行高、日期网格、卡片圆角、汇总行及页面节奏保持不变；15dp 金额槽位仍可容纳在现有行高内。
- 颜色：工作日、周末、今日和外月日期继续复用现有语义色；未增加颜色令牌。
- 图像与图标：本次不涉及图像或图标资产，没有新增或替换资源。
- 文案与内容：日期、紧凑金额格式和本地化文案均未改变。

**验证**

- 初始回归测试同时复现：外月日期 `fontSize` 未使用 compact，以及 1.2千渲染高度只有 10px。
- 修正后 `list_calendar_header_test.dart` 5/5 通过；覆盖同一个“30”在外月/本月均为 11px、1.2千使用 compact 字号且渲染高度至少 15px，以及外月日期不可选择。
- 列表功能相关 widget 测试 40/40 通过。
- `flutter analyze`：0 issues。
- 现有六张列表月历 golden 已包含同一工作区更早的全局字体改版且在本次修复前已经失配，因此未批量覆盖；本次以精确几何断言、完整列表测试和 iOS 原生字体实机截图完成视觉闭环。
- 没有剩余可执行的 P0/P1/P2 问题。

final result: passed

---

## 2026-07-15 — Four-page typography/readability refresh

This section supersedes the older compact 7–12px typography and 60px row
measurements retained below as historical comparison notes.

**Global type contract**

- Flutter source of truth: `lib/core/theme/app_text_styles.dart`
- Canonical HTML mirror: `docs/mockup/v16/index.html`
- Semantic scale: page title 20/28, section 16/22, item 15/21, body 14/21,
  label 13/18, supporting 12/17, compact 11/15, navigation 11/14, button
  14/20; amounts 34/38, 24/30, 18/24, and 15/20. Micro 10/14 is
  compatibility-only and limited to decorative ticket metadata.
- `test/architecture/main_surface_typography_contract_test.dart` prevents the
  four main Flutter surfaces from reintroducing numeric content font sizes and
  verifies the canonical V16 HTML file mirrors `AppTypography` exactly.

**Same-viewport comparison evidence**

- Home: `/private/tmp/typography-audit/compare-home.png`
- Detail/list: `/private/tmp/typography-audit/compare-list.png`
- Analytics: `/private/tmp/typography-audit/compare-analytics.png`
- Shopping: `/private/tmp/typography-audit/compare-shopping.png`
- Each combined input uses the updated 390×844 HTML mockup on the left and the
  Flutter implementation at the same logical viewport on the right. Native iOS
  captures were used for Home, List, and Shopping; Analytics uses a freshly
  rendered deterministic full-page Flutter fixture.

**Readability and layout findings**

- Main content no longer uses 7/8/9px text. List, Analytics, and Shopping have
  an 11px minimum; Home retains only three 10px decorative ticket labels.
- Home rows/cards were expanded around the larger copy: 108px metric region,
  82px ticket, 124–132px invite surface, and 68px transaction rows.
- List uses 46px calendar day rows and 68px transaction rows. Shopping uses a
  44px segmented control, 68px items, and a 28px completion control.
- Analytics expands the trend plot, chart axes/legends, donut center/rows,
  calendar details, drawer rows, and histogram so 11–16px text has sufficient
  room.
- The canonical V16 HTML file was tested at 320, 375, and 390px across all four pages:
  zero horizontal overflow, escaping elements, or clipped text. The phone frame
  now preserves the exact requested client width.
- No actionable P0/P1/P2 visual issue remains in the four refreshed surfaces.
- P3 accepted: the host golden renderer shows placeholder boxes for the native
  Japanese font stack; native iOS captures resolve Hiragino correctly.

**Verification**

- `flutter analyze`: 0 issues.
- Global typography/theme tests, four-page widget/screen tests, typography
  architecture tests, and the temporary on-device four-page navigation/capture
  test all pass.
- Full non-golden suite: 3,527 passed, 11 skipped.
- The existing golden suite reports 194 intended visual deltas from the global
  font/line-height change. Those pre-existing dirty baselines were deliberately
  not bulk-overwritten before user review; the only layout exception found in
  that run (a stale 60px list-row harness causing 2px overflow) was corrected to
  the new 68px row contract.
- `git diff --check`: passes for the scoped implementation and mockup changes.

final result: passed

---

## 2026-07-15 — 首页对齐与“本月最爱”等级区修正

本节是本次首页三处反馈的最新验收记录，并覆盖下文保留的关于“本月最爱”仍使用
22px Material 图标的历史说明。

**对照证据**

- 用户标注截图：`/Users/xinz/Downloads/截屏 2026-07-15 14.33.54.png`
- 修改后 iOS 实机渲染：`/private/tmp/home-pocket-returned-home.png`
- 并排对照：`/private/tmp/home-pocket-reference-vs-implementation.png`
- 对照均为简体中文、个人模式、浅色主题和 2026 年 7 月有数据状态；并排图按同一高度归一化，原始参考视口为 440×956，实机验收视口为 390×844。

**验收结果**

- “查看本月分析”现在占据悦己充盈标题行的最后一个固定区域，箭头右边缘与指标区右边缘一致；几何回归测试直接比较两个边缘坐标。
- 满足度均值和小确幸继续使用两个等高 `Center` 槽位；回归测试验证每项内容中心与其槽位中心的偏差小于 0.01 logical pixel。
- “本月最爱”右侧易撕等级区由 58dp 增至 72dp；等级图标增至 32dp，文案使用 12px supporting 样式。
- 等级图标改为现有 `SatisfactionFaceIcon`，按交易的 `joyFullness` 选择应用内 `assets/satisfaction/sat_01.svg` 至 `sat_05.svg`；未增加任何新图标或资源。
- 原有票券颜色、虚线、上下缺口、文案和本地化键均保持不变。

**验证**

- `home_hero_card_test.dart`：32 项通过，覆盖右对齐、上下居中、72dp 等级区、既有等级图标及 400dp 中文窄宽度无溢出。
- `home_screen_test.dart`：15 项通过。
- `flutter analyze`：0 issues。
- 原有 HomeHero golden 基线已包含同一工作区中更早的全局字体改版，因此未在本次局部修改中批量覆盖；本次使用几何断言与 iOS 原生字体实机截图完成视觉闭环。
- 未发现本次范围内的 P0/P1/P2 视觉问题。

final result: passed

### Detailed comparison evidence

**Comparison target**

- Source visual truth: `docs/mockup/v16/index.html`
- Focused user references:
  - Metrics alignment: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_7pfjXb/截屏2026-07-15 11.18.12.png`
  - Ticket tear interruption: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_T3v38X/截屏2026-07-15 11.20.11.png`
- Source capture: `/tmp/v15-home-source.png`
- Rendered implementation capture: `/tmp/v15-home-implementation-ios-final.png`
- Post-change rendered regression capture: `test/golden/goldens/home_hero_card_single_light_ja.png`
- Focused post-change ticket capture: `/private/tmp/home_ticket_notch_after.png`
- Combined comparison: `/tmp/v15-home-comparison-final.png`
- Viewport/state: 390×844 logical pixels, personal mode, Japanese, light theme. The implementation was captured from the production widgets on an iPhone 16e simulator using the native Hiragino system font.

**Full-view comparison evidence**

The combined capture places the V15 phone on the left and the iOS implementation on the right. After accounting for the mockup's 8px decorative phone frame, both use the same 20px content inset, header rhythm, hero proportions, 100px metric ring, 74px Best Joy ticket, invite-card placement, and detached navigation treatment.

**Focused region comparison evidence**

- Header: month title has no extra arrow; the compact `個人` badge and both 40px icon hit areas match V15.
- Hero density: the 10px label, 8px trend, 9px previous-month line, 8/10px ledger split, 11px region title, and 8px analysis link reproduce the denser hierarchy.
- Metrics: goal progress/track/value, satisfaction fill/text/track, small-win amber, and the olive divider use the exact V15 dedicated color set. The focused user crop was inspected separately for the requested alignment: the right column is now implemented as two explicit equal-height slots, and both content centers equal their slot centers within 0.01 logical pixels.
- Best Joy ticket: the final capture shows the 48px calendar, pale-green ticket surface, dedicated pink border/accent, dashed seal, top and bottom tear notches, 22px Material satisfaction icon, and no category icon. The focused post-change crop confirms that the outer horizontal border is absent across both notch openings, while the curved inner notch edges and vertical dashed tear line remain intact.
- Family invite: the primary-tinted border and soft 0/8/30 shadow are visible; the close target and CTA occupy the top/bottom action alignment from V15.
- Transactions: the component contract verifies a 60px row, 9×12 padding, 25px icon, 11px title, 8px metadata and 12px amount. Joy satisfaction and foreign secondary amount remain present by explicit product decision.

**List detail-page comparison evidence (L1–L7)**

- Source measurements were taken directly from the V15 list-page DOM/CSS in the comparison target: 46px header, 20px baseline, 40px header actions, 40px calendar rows, 16px weekday band, 10px/9px day typography, 14×10px summary padding, 14px blur filter material, 60px transaction rows, and 10px day-group spacing.
- Header: the Material `AppBar` is removed. The custom header uses the V15 46px height, information-blue month title, 20px page inset, and two 40px action targets.
- Calendar: the card now has the V15 warm shadow and compact grid/summary typography. The current-month predicate disables adjacent-month dates, and a behavioral test verifies that tapping the visible December 30 cell in January does not change the selected day or month.
- Compact amounts: Japanese and Chinese display values from 1000 as a fixed thousand unit (`1千`, `1.5千`, `10千`, `12.3千`) instead of locale-dependent compact notation. The analytics and calendar goldens affected by this shared formatter were refreshed and inspected.
- Filter material: the bar is edge-to-edge, 96% background opacity, 14px backdrop blur, and 20px internal content inset, matching the V15 full-width glass strip.
- Transactions: component goldens verify 60px minimum height, 9×12px padding, 25px icon, 11px title, 8px metadata, and 12px amount. The Joy satisfaction face remains visible, and foreign rows retain their second amount by explicit product decision.
- Visual regression evidence inspected after implementation: `test/golden/goldens/list_calendar_header_ja.png`, `test/golden/goldens/list_sort_filter_bar_ja.png`, `test/golden/goldens/list_transaction_tile_ja.png`, `test/golden/goldens/list_transaction_tile_foreign_ja.png`, `test/golden/goldens/category_drill_down_screen_light_ja.png`, `test/golden/goldens/within_month_trend_card_light_ja.png`, and `test/golden/goldens/joy_calendar_card_expand_light_ja.png`.

**Findings**

- No actionable P0/P1/P2 mismatch remains for H1–H6 or H8.
- No actionable P0/P1/P2 mismatch remains for L1–L7.
- P3 accepted: calendar month/day/weekday strings remain locale-formatted by the production date formatter instead of the mockup's fixed English abbreviations; this preserves the app's i18n contract.
- P3 accepted: the iOS status bar and native glyph antialiasing differ from the browser-rendered mockup as expected.

**Comparison history**

- Initial implementation review found 28dp page margins, a redundant month arrow, long mode labels, oversized hero copy, generic metric colors, an oversized ticket without tear notches, a custom satisfaction face, flat invite styling, and oversized transaction rows.
- First iOS comparison confirmed layout and colors but exposed the ticket's custom heart-face icon as a visible P2 mismatch.
- The ticket now uses the V15 Material `sentiment_very_satisfied` icon and a valid localized hobby category fixture.
- Post-fix combined evidence shows no remaining P0/P1/P2 mismatch.
- The latest focused feedback identified that `満足度の平均` and `小確幸` needed an explicit vertical-centering contract. The generic `Align` wrappers were replaced with named top/bottom `Center` slots. A widget-coordinate regression test verifies equal slot heights and exact vertical-center alignment; the HomeHero golden suite confirms no overflow or layout regression.
- The ticket follow-up identified a solid flat edge across each semicircular notch. The top notch now omits its top border and the bottom notch omits its bottom border, producing a true interruption in the ticket outline. The revised focused crop shows the break clearly, and a widget test asserts the asymmetric border sides directly.

**Implementation checklist**

- [x] 20px page margins and 13px header-to-hero spacing
- [x] Compact header labels and 40px calendar/settings targets
- [x] V15 hero typography and information density
- [x] Dedicated metric composition colors
- [x] Equal-height metric support slots with independently centered content
- [x] Ticket dimensions, colors, tear notches, icon, and copy density
- [x] Ticket outline interrupted at both tear-notch openings
- [x] Invite border, shadow, and action alignment
- [x] Compact transaction row while preserving Joy/foreign extensions
- [x] V15 list header, 20px baseline, and 40px header targets
- [x] Compact calendar styling, shadow, summary, and disabled outside dates
- [x] Fixed thousand-unit amount abbreviation from 1000
- [x] Full-width translucent blurred list filter material
- [x] Compact list transaction rows while preserving Joy/foreign extensions
- [x] 10px day-group spacing
- [x] Static analysis, focused tests, golden refresh, and native-font visual capture

**Follow-up polish**

- None required for the requested scope.

**Analytics-page comparison evidence (A1–A10)**

- Source visual truth: V16 analytics DOM/CSS in `docs/mockup/v16/index.html`, including the 16px card radius, 190px trend plot, 242px donut, 164/88px controls, 52px legend rows, 1px calendar grid, 44px day rows, and single pink histogram narrative.
- Source capture: `/private/tmp/v15-analytics-reference.png`.
- Rendered implementation captures inspected at original resolution: `test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png`, `test/golden/goldens/within_month_trend_card_light_ja.png`, `test/golden/goldens/category_donut_card_light_ja.png`, `test/golden/goldens/joy_calendar_card_expand_light_ja.png`, and `test/golden/goldens/satisfaction_histogram_card_light_ja.png`.
- Focused same-state donut comparison: `/private/tmp/v15-analytics-category-comparison.png` (V15 source left, production golden right). The comparison confirms the 242px outer diameter, 116px center opening, thicker 63px ring, smaller center total, and enlarged on-ring labels.
- Cards use 16px corners and the V15 0/3/14 warm shadow; category content alone uses the 18px inset.
- Trend plot height is 190px and both endpoint annotations are single-line (`M/d ¥…` and localized `先月 ¥…`).
- Category and member controls are fixed to 164×42 and 88×42; legend rows are 52px high with compact 11.5/11px typography.
- The Joy drawer no longer has the extra divider or 30px dead space; its 44px toggle and detail spacing match V15.
- Calendar cells use a 1px grid, 10px dates, non-zero count dots, 8px card inset, and second-tap collapse. Expanded content has the inset top border and 44px compact transaction rows.
- Satisfaction distribution now ends in one localized pink narrative; the split count/median-pill layout is absent.

**Analytics findings**

- No actionable P0/P1/P2 mismatch remains for A1–A10.
- P3 accepted: Flutter golden rendering in the test environment uses placeholder glyph boxes for the newly adopted native Japanese font stack; native iOS rendering uses Hiragino and is covered by the system-font theme contract.
- Verification passed: focused analytics widget tests, the complete golden suite, `flutter analyze`, and the full 3,736-test Flutter suite (11 skipped).

final result: passed

**Shopping-page comparison evidence (S1–S5)**

- Source visual truth: the current V16 shopping DOM/CSS in `docs/mockup/v16/index.html`.
- Current V15 source capture: `/private/tmp/v15-shopping-current-full.png`; 390×844 phone crop: `/private/tmp/v15-shopping-reference-current.png`.
- Rendered production-widget capture: `test/golden/goldens/shopping_list_screen_v15_light_ja.png`.
- Same-state combined comparison: `/private/tmp/v15-shopping-comparison.png` (V15 source left, Flutter production widgets right), 390×844 logical pixels, personal mode, Japanese, light theme.
- Header: the shared 46px main-surface header keeps the title on the left and adds the 40px settings action on the right.
- Personal filter: the bordered 18px-radius surface contains the three-way ledger segment plus the always-visible 私有 / カテゴリ row.
- Family filter: 全部 / 個人 scope stacks above the ledger segment; switching scope resets ledger, private, and category filters.
- Secondary filters: 私有 filters private items immediately; カテゴリ opens the shopping-only L1 multi-select bottom sheet with clear, cancel, and apply actions. Both combine with the ledger filter.
- Segmented control: the track is the V15 54% muted-surface mix with the warm 0/3/12 shadow; labels are 10.5px, unselected text uses the primary text token, and the selected option uses the V15 tone-specific fill/ring/shadow.
- Page/list geometry: list cards use the 20px page baseline and section titles use the 21px source offset.
- Active rows: the combined capture confirms 60px rows, 10×12px row padding, 23px ledger-colored completion rings, 11px names, 9px metadata, 8px badges, and a permanently visible 20px drag indicator. The completion control no longer reserves the old 44px horizontal lane.
- Checked state: completed rows use the ledger color as the 23px circle fill with a 15px white check; row copy, badge, and drag affordance fade to 58%, and the name receives a line-through. A focused widget test asserts the exact fill, icon color, and icon size.
- Completed rows: every completed item owns a separate 14px rounded bordered card with an 8px inter-card gap; no shared container or divider remains.

**Shopping findings**

- No actionable P0/P1/P2 mismatch remains for S1–S5.
- P3 accepted: Flutter's headless golden renderer uses placeholder glyph boxes for the platform font stack and Material icons; geometry and colors are deterministic, while native builds resolve the system Japanese and Material glyphs.
- Verification passed: 48 focused widget tests, 61 shopping golden tests, the new 390×844 personal-screen golden, `flutter analyze` with zero issues, and the complete Flutter test suite.

final result: passed

---

## Current result — 2026-07-16 unified entry option 1

The latest QA report is the 2026-07-16 “统一记账方案 1「单页连续输入」” section above. Its rendered same-state comparison remains blocked because the approved in-app browser surface cannot capture the local `file://` implementation.

final result: blocked

---

## Current result — 2026-07-16 V16 Flutter implementation

The completed production implementation and its final 390×844 paired visual
evidence are recorded in “V16 统一记账、账目编辑与新增购物项实现验收” above.
That rendered pass supersedes the earlier mockup-only blocked notes.

final result: passed
