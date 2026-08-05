# Settings 法务·赞助（设置法务/赞助区块）— DESIGN-03 QA 与批准记录

**surface**: Settings legal/sponsor / 设置法务·赞助（完整设置页）
**winning sketch**: sketch 003 · tone **C 混合**（合并精简分区 + 法务·应援同组）· ★ 选定
**scope**: 不是孤立法务区块，而是**完整 Settings 页**——既有 8 区按序保留，叠加 v2.0 新增（应用锁展开 / 法的情報扩充 / 応援外链）
**requirement**: **DESIGN-03** — Setting 法务/赞助区块布局的 HTML 设计稿产出并经用户确认
**source**: `.planning/sketches/003-legal-sponsor/index.html`（tone-C 区块：`C · 混合 ★ 选定`）
**ADR**: 配色遵循 ADR-019「桜餅×若葉」v1.6（`screen warm` 暖底，primary 若叶绿，`new` 标签 `#eef5ee`/`daily-text`，外链色 `shared` 钢蓝）

---

## 设计问题（已定）

完整设置页的分区粒度与法务/赞助呈现方式：保持 8 个独立分区（A/B）还是合并精简（C）；赞助入口独占一组（A）还是单行（B/C）。tone C 以**合并精简**胜出——`一般` 合并 外観+音声認識+悦己目標 五项，`法的情報・応援` 单组承载四条法务 + 一条外链赞助；应用锁在 `セキュリティ & プライバシー` 内由 master 开关展开 Face ID/PIN 子行，替换原先孤立的生物识别开关。

落选备选：A 温柔抛茶感（卡片分组、暖色图标、赞助独占组）；B 清爽极简（iOS 原生分组列表、无图标、赞助降为单行 ↗外部，最 store-safe）。

---

## 逐元素验证表（DESIGN-03）

每一项给出 sketch 003 tone-C 内可 grep 的确切字符串作为证据。

| DESIGN-03 元素 | 状态 | sketch 003 tone-C 证据（确切串） |
|---|---|---|
| 应用锁 master 开关 | ✓ PRESENT | `セキュリティ & プライバシー` 组内 `アプリロック`<span>新</span> + 副标 `Face ID・PIN で家計簿を保護` + `sw`（master toggle）|
| Face ID / 指紋 子行 | ✓ PRESENT | `row2 subrow` 内 `Face ID / 指紋` + `sw`（子开关）|
| PIN コード 子行 | ✓ PRESENT | `row2 subrow` 内 `PIN コード` + `設定する ›` |
| 「Face ID が優先」优先注记 | ✓ PRESENT | `note`：`両方設定時は Face ID が優先。失敗時は PIN に切替。`（含 `Face ID が優先`）|
| プライバシーポリシー | ✓ PRESENT | `法的情報・応援` 组首行 `プライバシーポリシー` |
| 利用規約 | ✓ PRESENT | `利用規約`<span>新</span> |
| 特定商取引法に基づく表記 | ✓ PRESENT | `特定商取引法に基づく表記`<span>新</span> + 副标 `日本での提供に必要な表記` |
| OSS ライセンス | ✓ PRESENT | `OSS ライセンス`（⚖️ 行）|
| 外部 応援 / sponsor 行（非 IAP）| ✓ PRESENT | `開発を応援する`<span>新</span> + `ext`：`↗ 外部`（外链标记，非 IAP）|
| 整合进完整 Settings 页 | ✓ PRESENT | 既有分区保留并精简：`一般`（テーマ/言語/週の開始/音声認識言語/悦己の目標）+ `家族共有` + `データ管理` + `法的情報・応援` + `アプリについて`；profile 卡 `たろう` |

---

## QA 结论

- 胜出 sketch（003 · tone C 混合 · 完整设置页）经逐元素 QA **全部满足 DESIGN-03**，设计稿 **已定稿、可提交用户批准**。
- 本次 QA 对 HTML **未作任何编辑**（minimal-edit 触发条件未命中——所有必需元素本就齐备）。tone A/B 未触碰。
- 自动校验通过：`grep "★ 选定"` / `アプリロック` / `Face ID / 指紋` / `PIN コード` / `Face ID が優先` / `プライバシーポリシー` / `利用規約` / `特定商取引法に基づく表記` / `OSS` / `開発を応援する` / `外部` 均命中。

---

## 下游（Phase 56）继承的约束

本批准的 UI 仅是设计契约；真正的法务文本、合规与赞助外链实现落在 Phase 56（上线关卡，自带外部评审余量）。被批准的设计对 Phase 56 隐含：

- **复用既有 Settings 分区并按 winner C 精简合并**：`一般` = 外観 + 音声認識 + 悦己目標 合并为一组；`法的情報・応援` 四条法务 + 一条外链赞助合并为一组；不新增独立配色轴。
- **应用锁展开替换孤立生物识别开关**：master `アプリロック` → `Face ID / 指紋` + `PIN コード` 子行 + 「Face ID が優先」优先注记（与 Phase 55 锁屏设计对齐）。
- **法务页三语离线 + 托管 URL 占位**：プライバシーポリシー（LEGAL-01）/ 利用規約（LEGAL-02）app 内置 ja/zh/en 文本离线可读 + App Store Connect 强制托管 URL 占位（上线前填）。
- **OSS 经 Flutter 内置 `showLicensePage`/`LicenseRegistry` 自动聚合**（LEGAL-03），不手维护清单。
- **特商法表記参考 napu.co.jp/sale 表記结构**（LEGAL-04，运营者/所在地/联系方式/退款等条目，可遵「请求时提供」型），三语承载，上线前由日本法务确认细节。
- **応援行经 `url_launcher` `LaunchMode.externalApplication` 打开外部浏览器**（DONATE-02），到日本赞助平台（FANBOX/OFUSE 等），**绝不内嵌 WebView、绝不 IAP**；URL 可配置占位（DONATE-04），中性非交易性措辞、完全可选、不弹窗（DONATE-03）。
- **商店隐私表单如实填写**（LEGAL-05，与 v1.7 汇率出站调用一致），新增法务/合规文案三语覆盖并通过 ARB parity + 硬编码 CJK 扫描（LEGAL-06）。
- Phase 56 依赖 Phase 54（Setting 承载面），与 Phase 55 相互独立可并行。

---

## DESIGN-04 gate-exit（零生产代码）

本 surface 的全部产物仅为 `.md` / `.html`，位于 `.planning/` 下：`53-03-settings-legal-sponsor-qa.md`（本文件）+ 既有 `003-legal-sponsor/index.html`（未改）。本计划 **零 Dart / 零 pubspec / 零 lib/ / 零 test/ / 零 ARB** 改动，满足 DESIGN-04 硬关卡（`git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'` 为空）。
