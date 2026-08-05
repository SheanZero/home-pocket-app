# Phase 56: Setting 法务 + 赞助 + 日本合规（上线关卡） - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning

<domain>
## Phase Boundary

v2.0 里程碑的最后一个 phase、面向日本市场首次公开上线的**合规关卡**。在既有 Settings 页新增一个 `法的情報・応援` 分组（沿用 Phase 53 已批准的 tone-C 设计），承载：

- **4 个法务页**：プライバシーポリシー（LEGAL-01）/ 利用規約（LEGAL-02）/ 特定商取引法に基づく表記（LEGAL-04）/ OSS ライセンス（LEGAL-03）
- **1 个外链赞助行**：開発を応援する（DONATE-01..04），经 `url_launcher` 外部浏览器打开，绝不 WebView/IAP
- **上线配套非代码交付物**：商店隐私表单如实填写清单（LEGAL-05）

**已由前序 phase 完成、本 phase 不重做：**
- UI 布局 —— Phase 53 已批准（tone-C 合并 Settings，`法的情報・応援` 组）
- 应用锁 Settings 行展开（master `アプリロック` + PIN 子行）—— **Phase 55 已建**（`lib/features/settings/presentation/widgets/security_section.dart`），本 phase 不动
- Settings 承载面 + `scrollToSecurity` deep-link —— Phase 54 已建

**Requirements（10 项，锁定于 REQUIREMENTS.md）：** DONATE-01/02/03/04 · LEGAL-01/02/03/04/05/06

**上线余量：** 法务正文草稿 + 特商法运营者信息 + 托管/赞助 URL 均为「上线前由日本法务确认 / 填真实值」；本 phase 交付可评审的完整结构 + 内容草稿，保留真实 store-review round-trip 余量。
</domain>

<decisions>
## Implementation Decisions

### 法务长文本（隐私政策 / 利用規約 / 特商法正文）
- **D-01:** 本 phase 直接**起草可上线的完整三语（ja/zh/en）正文**（不是仅占位骨架）。正文基于本 app 真实数据行为撰写：本地优先、零知识加密、v1.7 汇率服务的出站网络调用（与 LEGAL-05 商店表单口径一致，非反射式「不收集」）。仍标注「上线前由日本法务复核」，但产出实际草稿内容而非 `[待填]`。

### 长文本承载机制
- **D-02:** 长文本用 **bundled per-locale assets**（每语一个文件，按 locale 加载），**不**塞进 ARB。规避 ARB 臃肿 + diff 噪声，符合 REQUIREMENTS LEGAL-06 明示路径。需新增一道**「三语文件都存在」的存在性门**（parity gate for assets，类比 ARB parity）。短标签/入口标题（分组名、行标题、按钮）仍走 ARB `S.of(context)`。

### 特商法（LEGAL-04）运营者信息呈现
- **D-03:** 采用「**请求时提供**」型 —— 页面声明「运营者信息可应请求提供」+ 一个联系邮箱（占位，上线前填），**不公开个人住址/电话**。个人独立开发者隐私友好、日本实务常见。完整表記（运营者全字段）已列为 v2（LEGAL-V2-01），本 phase 不做。 **[SUPERSEDED by D-06 — 2026-07-02, see below]**

### 托管 URL 占位 / 赞助 URL 占位
- **D-04:** 隐私政策/利用規約的 **App Store Connect 强制托管 URL**、以及**赞助平台 URL**（FANBOX/OFUSE 等，DONATE-04）集中到**一个 config 常量文件**（占位值 + 「上线前填真实值」注释），不散落各页。赞助行措辞中性、非交易性、完全可选、不弹窗（DONATE-03）。

### 商店隐私表单（LEGAL-05）
- **D-05:** 商店隐私表单**不是 app 代码**，交付一份 `.planning/` 下的**「如实填写」Markdown 清单**（Apple Privacy Nutrition Labels / Google Data Safety 两栏，与 v1.7 汇率出站调用口径一致）供上线时录入。

### 特商法（LEGAL-04）运营者信息呈现 —— 反转（supersedes D-03）
- **D-06 (supersedes D-03, UAT Test 4 gap-closure 56-07):** 反转 D-03，改采「完整表記」型（LEGAL-V2-01 前移）—— 特商法页面直接公开运营者全字段 事業者名 / 所在地 / 電話番号 / 運営責任者；真实值由用户上线前填写，本 gap-closure 以 `[上线前填真实值]` 占位（D-01/D-04 风格），保留每个 tokusho 文件的「上线前由日本法务复核」标记。**隐私权衡：** 公开个人独立开发者的真实住址/电话正是 D-03 当初为保护隐私而回避的取舍；占位符必须保留至用户确认真实值，且上线前须经日本法务复核个人 PII 公开的合规性与隐私影响。

### Claude's Discretion
- 新增 `法的情報・応援` 分组 widget 的具体拆分（单 section widget vs 每页独立 screen）、asset 文件格式（markdown vs 纯文本）、法务详情页的滚动/排版实现 —— 交由 research/planner 依既有 Settings section 模式决定。
- OSS 页直接用 Flutter 内置 `showLicensePage` / `LicenseRegistry` 自动聚合（LEGAL-03 已锁），无需自定义。
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求与设计契约
- `.planning/REQUIREMENTS.md` §Donation / §Legal & Compliance — DONATE-01..04 + LEGAL-01..06 的锁定需求全文（本 phase 的 WHAT）
- `.planning/phases/53-html/53-03-settings-legal-sponsor-qa.md` — Phase 53 已批准的 Settings tone-C 设计契约 + 「下游（Phase 56）继承的约束」清单（必读）
- `.planning/sketches/003-legal-sponsor/index.html` — 批准的 HTML 设计稿（tone-C `法的情報・応援` 组结构）

### 外部参考（内容起草）
- https://www.napu.co.jp/sale/ — 特商法「表記」结构参考（LEGAL-04，仅结构参考，采「请求时提供」型）

### 既有承载面 / 复用点
- `lib/features/settings/presentation/screens/settings_screen.dart` — Settings 页承载面（Phase 54 建，含 `scrollToSecurity`）；新 `法的情報・応援` 组挂此处
- `lib/features/settings/presentation/widgets/security_section.dart` — Phase 55 已建应用锁 section（**不改**，仅作分组邻接参考）
- `lib/features/settings/presentation/widgets/about_section.dart` — 最接近的「信息/链接型」既有 section，新法务组的最近分析样板

### 配色
- `docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md` — 桜餅×若葉 v1.6；外链色用 `shared` 钢蓝、`new` 标签 `#eef5ee`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **既有 Settings section 模式**：`about_section.dart` / `appearance_section.dart` 等给出「一组 ListTile + i18n 标题」的现成样板，新 `法的情報・応援` 组照抄结构。
- **`showLicensePage`（Flutter 内置）**：LEGAL-03 直接调用，零手维护 OSS 清单。
- **`AppSettings` (SharedPreferences)**：设置持久化走 SharedPreferences 非 Drift（见 memory `settings-persisted-via-sharedprefs-not-drift`）——本 phase 若需存任何开关无需 Drift 迁移；但法务/赞助多为静态内容，预计无新持久化字段。
- **i18n 管线**：`S.of(context)` + ARB ja/zh/en + gen-l10n，短标签复用；长正文走新 asset 通道（D-02）。

### Established Patterns
- **新运行时依赖 `url_launcher`**（当前不在 pubspec）：需 `flutter pub add url_launcher`，`LaunchMode.externalApplication`（DONATE-02）。iOS 需在 `Info.plist` 加 `LSApplicationQueriesSchemes`（https）——注意 iOS 构建（见 CLAUDE.md iOS Build 节，Podfile post_install 不可动）。
- **硬编码 CJK 扫描 + ARB parity**：新增短文案必须过既有架构测试（`hardcoded_cjk_ui_scan`）+ 全量 `flutter test`（见 memory `main-dart-boot-provider-...`：分组门须跑 FULL suite）。
- **asset 三语存在性门**（D-02 新增）：长文本不进 ARB，需新增一道断言 ja/zh/en 三个 asset 文件都存在的测试。

### Integration Points
- 新 `法的情報・応援` 组插入 `settings_screen.dart` 分区序列（在 `法的情報` 邻近位置，按 tone-C 设计）。
- 赞助行 → `url_launcher` 外链；URL 集中常量（D-04）。
- 商店隐私表单清单（D-05）→ `.planning/` 交付物，不进 lib/。
</code_context>

<specifics>
## Specific Ideas

- 特商法表記**结构**参考 napu.co.jp/sale 的条目组织，但**内容**采「请求时提供」型（D-03），不逐字照搬。
- 法务正文口径必须与 LEGAL-05 商店表单一致：如实反映 v1.7 汇率服务出站网络调用，**非**反射式「完全不收集」。
</specifics>

<deferred>
## Deferred Ideas

- **[已前移 2026-07-02]** **LEGAL-V2-01**（完整特商法全表記，运营者全字段）—— 依 UAT Test 4，D-03 已反转为 D-06，完整表記已在 gap-closure 56-07 实现（tokusho 三语直接公开运营者全字段，真实值上线前填）。**不再 deferred。**
- **真实托管 URL / 真实赞助平台 URL / 真实运营者联系方式** —— 占位于本 phase，**上线前**由用户填真实值（非本 phase 交付范围内的内容）。
- **LOCK-V2-05 ②**（主页 `MainShellScreen` 首帧懒加载优化）—— Phase 55 UAT 遗留，与本 phase 无关，v2 跟进。

</deferred>

---

*Phase: 56-setting*
*Context gathered: 2026-07-01*
