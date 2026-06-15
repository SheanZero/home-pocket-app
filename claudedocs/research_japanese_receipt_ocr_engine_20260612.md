# 日文小票 OCR 引擎开发调研报告

**主题:** 隐私优先、离线、本地处理的日文小票（レシート／領収書）OCR 引擎选型与开发路径
**日期:** 2026-06-12
**适用模块:** MOD-005 OCR（文档为 MOD-004_OCR.md）, MOD-003 智能分类
**相关决策:** ADR-005 OCR/ML 技术选型（2026-02-03 已接受）
**调研方法:** 4 路并行 web 调研（引擎对比 / 领域知识 / ML KIE 模型 / Flutter 实现），全部主张附 URL 引用
**约束前提:** 数据不上云（零知识架构硬约束）；包体积单模型 <10MB、内存峰值 <200MB、OCR <2s、iOS 14+ / Android 7+

---

## 0. 执行摘要

调研结论：**ADR-005 的"Android 用 ML Kit + iOS 用 Apple Vision"双原生策略，到 2026 年依然是正确选择**——独立开发者实测一致认为这是隐私优先 Flutter 应用的最优解，跨平台单引擎方案（Tesseract / PaddleOCR）在精度、包体积、Flutter 集成成熟度三方面都更差。

但调研发现了 ADR-005（2026-02 起草）**未捕捉到的硬冲突和若干新事实**，必须在动工前处理：

1. **🔴 iOS 部署目标冲突（最高优先级）：** 项目目标 iOS 14+，但 (a) ML Kit 日文 pod 要求 **iOS ≥ 15.5**；(b) Apple Vision 的日文支持始于 **iOS 16**。iOS 14/15 设备上两个引擎都无法正常做日文 OCR。必须决策：抬高部署目标到 iOS 16，还是为 iOS 14–15 设计降级路径。
2. **🟡 MVP 不需要 ML 模型：** 主流生产级小票 app 用"原生 OCR + 正则/启发式解析 + 算术校验"即可达到清晰打印小票 ~85–90% 字段精度。ADR-005 设想的 CORD/TFLite ML 模型应推迟到 Phase 2，且大多数 KIE 模型（Donut 860MB、LayoutLMv3-Large 1.4GB）**根本无法满足 <10MB / <200MB 约束**。
3. **🟢 日文小票领域复杂度被低估：** 軽減税率 8%/10% 双税率、インボイス制度（2023-10 起，T+13 位登录番号）、令和年号、全角/半角数字、半角片假名、热敏纸褪色——这些是解析层的真正难点，需要专门的校验规则（本报告 §4.4 给出 10 条算术不变量）。
4. **🟢 新增可选项：** PP-OCRv5（2025-03，5M 参数 <50MB，日文行精度从 v4 的 32% 跃升到 72%）是 ADR-005 起草时尚不成熟、现在值得记录的 Phase-2 跨平台候选——但**目前没有可用的 Flutter 包**，集成成本高。

**建议的开发分期见 §7。**

---

## 1. 与现有决策（ADR-005 / MOD-004）的关系

| 现有决策 | 调研结论 | 处置建议 |
|---|---|---|
| OCR 用平台原生（ML Kit + Vision） | ✅ 2026 仍成立，独立实测背书 | 保持。补充 iOS 降级策略 |
| 准确率目标 >85% | ✅ 清晰打印小票可达；噪声/手写不行 | 保持，但区分"清晰打印"与"褪色/手写"两档目标 |
| 包体积 <10MB | ⚠️ 原生 OCR 本身满足；任何 ML KIE 模型都不满足 | Phase 1 守住；Phase 2 重新定义为 ~100–150MB INT8 后台模型 |
| 图像预处理用 opencv_dart | ⚠️ MVP 用纯 Dart `image` 包即可（0 原生体积）；opencv_dart 加 5–20MB | MVP 先 `image` 包；需要透视矫正/自适应二值化再上 opencv_dart |
| Phase 2 集成 CORD 模型 | ⚠️ CORD 是印尼语数据集，与日文不匹配 | 改用 Japanese-Mobile-Receipt-OCR-1.3K（2025）做微调基准 |
| iOS 14+ 目标 | 🔴 与 ML Kit(15.5)/Vision(16) 日文支持冲突 | **必须决策**（见 §3） |

ADR 是 append-only：若采纳本报告结论，应在 ADR-005 末尾追加 `## Update 2026-06-12` 区段，记录 iOS 部署目标修订与 PP-OCRv5/ML-KIE 的 Phase-2 重定位，不改原决策正文。

---

## 2. OCR 引擎选型（on-device）

### 2.1 排名与对比

| 排名 | 引擎 | 平台 | 小票精度 | Flutter 集成 | 体积成本 | 结论 |
|---|---|---|---|---|---|---|
| 1 | Apple Vision (`.accurate`, `ja-JP`) | **iOS 16+** | iOS 上最佳 | 自建 MethodChannel/Pigeon | 0MB（系统内置） | iOS 首选 |
| 2 | ML Kit v2 (`script: japanese`) | iOS+Android | 清晰文本良好 | 生产级 Flutter 包 | iOS ~10–25MB / Android ~4–8MB | Android 首选 + iOS 降级 |
| 3 | Tesseract (`jpn.traineddata`) | iOS+Android | 仅清晰扫描可接受 | Flutter 包（publisher 未验证） | 每语言包 ~14MB | 最后手段 |
| 4 | PaddleOCR / PP-OCRv5 | iOS+Android | 场景文本良好 | **无可用 Flutter 包** | ~15–20MB | Flutter 生产暂不可行 |
| 5 | 边缘 VLM（Moondream/Florence-2 等） | 不定 | 研究级 | 无 | 0.5–2GB | 2027+ 再看 |

### 2.2 关键事实（附引用）

**Apple Vision** — 日文 (`ja-JP`) 自 **iOS 16** 加入（[WWDC22 session 10025](https://developer.apple.com/videos/play/wwdc2022/10025/)）；iOS 18 起 `supportedRecognitionLanguages()` 返回 18 种语言含 `ja-JP`。`.accurate` 走 ANE，单张静图 ~300ms，但对印刷日文精度最高、零包体积。需 iPhone X+（2018 后）的 ANE 才有理想速度。无一线 Flutter 包，需自建 ~100 行 Swift（推荐用 Pigeon 类型安全代码生成）。([Apple docs: recognitionLanguages](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/recognitionlanguages))

**ML Kit v2** — `google_mlkit_text_recognition` **v0.15.1**（社区维护，非 Google 官方），`TextRecognitionScript.japanese`。Android: `text-recognition-japanese:16.0.1`（bundled ~4MB/ABI，unbundled 仅 ~260KB 但依赖 Play Services，华为/AOSP 不可用）。iOS pod `GoogleMLKit/TextRecognitionJapanese ~> 9.0.0`，**最低部署目标 iOS 15.5（硬要求）**，且非拉丁文比拉丁文慢。([pub.dev](https://pub.dev/packages/google_mlkit_text_recognition), [Android docs](https://developers.google.com/ml-kit/vision/text-recognition/v2/android))

**Tesseract** — `flutter_tesseract_ocr` v0.4.31（publisher 未验证，依赖健康风险）。`jpn.traineddata`(best) **13.7MB** 必须打包进 asset。场景文本基准 60–70% vs PaddleOCR 85–90%（[mljourney 对比](https://mljourney.com/paddleocr-vs-tesseract-comprehensive-comparison-for-ocr-implementation/)），对热敏小票需大量预处理才可用，移动端比 ML Kit 慢。

**PaddleOCR / PP-OCRv5**（2025-03）— 5M 参数单模型原生含日文，日文行精度 **72%**（v4 仅 32.2%）（[arXiv 2603.24373](https://arxiv.org/abs/2603.24373v1)）。但 pub.dev 唯一的 `paddle_ocr` 包 5 年未更新、39 次下载；`ente-io/mobile_ocr` 用 PP-OCR 但只含中英字典、无日文。Flutter 集成需自建 Paddle-Lite C++ FFI——工程量大。

### 2.3 "双原生策略是否仍正确"的明确判断

**是。** 三点理由：(1) iOS 上 Apple Vision 日文精度最高、零体积、跑 ANE，无跨平台替代品能在 Apple 硬件上匹敌；(2) Android 上 ML Kit 是唯一生产级、活跃维护、隐私保护的 on-device 日文 OCR，PaddleOCR 无 Flutter 路径、Tesseract 在热敏小票上更差；(3) 唯一的跨平台替代（Tesseract）在两个平台上都更差——更慢、热敏字体精度更低、要打包 14MB+ asset、包 publisher 未验证。

---

## 3. 🔴 必须决策：iOS 部署目标冲突

这是动工前的**阻断性问题**，ADR-005 未处理。

- 项目当前目标：**iOS 14+**
- ML Kit 日文 pod 最低：**iOS 15.5**
- Apple Vision 日文支持：**iOS 16+**（iOS 14/15 上设 `ja-JP` 会静默降级或乱码）

**三种可选路径：**

| 方案 | 描述 | 代价 |
|---|---|---|
| **A. 抬高到 iOS 16+**（推荐评估） | OCR 功能门控在 iOS 16+；iOS 16 起 Vision 主路径，ML Kit 仅作 Android | 最简单；放弃 iOS 14/15 用户（2026 已是很小份额）。若全 app 抬高到 16 影响最小代码 |
| **B. iOS 16+ 用 Vision，iOS 14–15 用 ML Kit** | 但 ML Kit pod 本身要 15.5 → iOS 14 仍无解 | iOS 14 用户无 OCR；需在 UI 优雅禁用 |
| **C. OCR 整体门控 iOS 15.5+** | 用 ML Kit 作 iOS 通用引擎，iOS 16+ 额外启用 Vision | 折中；仅丢 iOS 14。但放弃 Vision 零体积优势的一部分 |

> 这是产品/用户决策，需用 iOS 14/15 实际安装占比来定。技术上推荐 A 或 C。

---

## 4. 日文小票领域知识（解析层的真正难点）

### 4.1 文档类型与字段词表

- **レシート**（POS 自动打印，含明细/数量/单价）vs **領収書**（正式付款凭证，含收款方与但し書き，可能无明细）。两者若含 6 要素均可成为**適格請求書**（合格发票）。

关键字段标签（含变体）：

| 标签 | 变体 | 语义 |
|---|---|---|
| 合計 | お買上合計 / 税込合計 / 合計金額 | 应付总额（通常含税） |
| 小計 | — | 税前/付款前小计 |
| 消費税 | 税額 / 内消費税 | 税额 |
| 税込 / 税抜 | 税別 | 含税 / 不含税标识 |
| 内税 / 外税 | — | 价含税 / 税另加 |
| 8%対象 / 10%対象 | 軽減税率対象合計 / 標準税率対象合計 | 分税率小计 |
| お預り / お釣り | お預かり / おつり | 实收 / 找零 |
| 点数 | 合計点数 | 商品件数 |
| 登録番号 | T番号 | 合格发票登录番号（T+13 位） |

**总额识别歧义：** 合計/お買上合計/税込合計/合計金額 都可能；最可靠的判定是满足算术约束 `合計 = お預り − お釣り`，而非靠关键字或"最大数字"。

### 4.2 軽減税率（双税率）与インボイス制度

- 2019-10-01 起：**10% 标准 / 8% 轻减**（外带/外卖食品饮料 8%，堂食/酒类 10%；报纸订阅等特例）。
- 8% 商品须逐行标记：常用 **※** 或 **軽**，底部有图例如 `※印は軽減税率対象商品です`。
- **税额按"每税率类目对小计"计算一次，不是逐行**，且可向下取整/四舍五入/向上取整（同张小票内一致）。⇒ Σ(逐行税额估算) ≠ 打印税额是**正常现象**。
- **インボイス制度**（2023-10-01 起）：合格发票须含 6 要素，其中**登録番号 = `T` + 13 位数字**（法人为法人番号；个体户另发）。正则 `^T\d{13}$`，可对 [NTA 公开库](https://www.invoice-kohyo.nta.go.jp/) 校验。
  来源：[Stripe 合格发票格式](https://stripe.com/resources/more/qualified-invoices-format-japan)、[Stripe 登录番号](https://stripe.com/resources/more/invoice-system-registration-number-japan)

### 4.3 日期格式

须同时支持：西历 `2026/06/12`、`2026年06月12日`、和历 `令和8年6月12日` / `R8.6.12`、首年 `令和元年`、两位年 `26/06/12`、含时间 `14:32`（居酒屋可能 `26:30` 表次日凌晨）。

**陷阱：** `令和元年`=1 年须特判；`令和N年` → 西历 = N+2018；`令和1年4月30日` 不存在（4/30 仍是平成 31）；令(U+4EE4) 易被 OCR 误读为 今(U+4ECA)。
来源：[Wikipedia 日本日期记法](https://en.wikipedia.org/wiki/Date_and_time_notation_in_Japan)

### 4.4 OCR 校验规则（10 条算术不变量——抓 OCR 错误的核心武器）

这些是 OCR 正确时必成立的约束，违反即提示错误（非小票错误）：

1. **明细求和 = 小计：** `Σ(line_amount) ≈ 小计`（±1 円容差；仅当列出全部明细时成立）
2. **小计 + 税 = 合計：** 双税率时 `(8%税抜+消費税8%)+(10%税抜+消費税10%) = 合計`（±1 円）
3. **税 ≈ 小计 × 税率（按类目）：** `消費税10% ≈ floor(10%対象 × 0.10)`（±1 円，因取整模式不定）
4. **实收 ≥ 合計：** `お預り ≥ 合計`
5. **找零 = 实收 − 合計：** `お釣り = お預り − 合計`（**精确相等，无容差——单字段最强校验**）
6. **日期合理性：** 晚于店铺开业、早于当前；令和年号范围合理
7. **金额位数合理：** 零售单笔总额几乎都在 ¥100–¥999,999（≤6 位）；8 位多半是逗号被读成数字或 ¥ 被吞
8. **T 番号格式：** `^T\d{13}$`
9. **税率标记一致：** 带 ※ 的明细须计入 8%対象
10. **取整模式一致：** 三种取整模式中应恰有一种对 8%/10% 都 ±0 円吻合；都不吻合则有数字 OCR 错误

来源：[Stripe 消費税收据](https://stripe.com/resources/more/how-to-include-consumption-tax-on-receipts-japan)

### 4.5 OCR 物理难点

热敏纸褪色（数月内掉 20–50% 墨度）、203dpi 低分辨率（字高 16–24px）、混合字符集（全角/半角片假名、全角/半角数字、汉字假名混排、无词边界）、易混字形（0/O、1/l、ロ/口、令/今、8/B、全角０/半角0）、两列价格对齐易错位、58mm/80mm 窄纸换行无缩进。
来源：[mailmate 全角半角](https://mailmate.jp/blog/half-width-full-width-hankaku-zenkaku-explained)、[arXiv JaWildText](https://arxiv.org/pdf/2603.27942)

---

## 5. 结构化提取：MVP 用规则，ML KIE 推迟

### 5.1 MVP：原生 OCR + 正则/启发式 + 校验（充分）

主流生产小票 app 正是这套分层。清晰打印小票总额字段可达 ~85–90%：
- **金额：** `[合計|小計|税込][^\d]*([¥￥]?[\d,]+)`
- **日期：** 西历/和历多模式正则
- **商家：** 用 ML Kit/Vision 返回的 bounding-box Y 坐标取顶部最大文本块
- **置信度：** 高置信自动填充，低置信/缺失提示用户确认编辑
- 学术背书：规则优先、超阈值正则覆盖 ML 预测的混合法优于单一法（[MDPI 2025](https://www.mdpi.com/2504-4990/7/4/167)）

**规则法的已知局限：** 手写金额（居酒屋）、无 合計 关键字的非标准版式、撕裂/模糊/倾斜、大规模逐项明细提取。

### 5.2 触发上 ML KIE 的信号

| 触发 | 阈值 |
|---|---|
| 用户报告字段提取错误 | >10% 小票需手工纠正 |
| 手写小票需求 | 用户明确请求 |
| 逐项明细需求 | 预算追踪需要 per-item |
| 商家分类失败 | 规则匹配失败 >20% |

### 5.3 KIE 模型现实（绝大多数不能上端）

| 模型 | CORD F1 | 体积 | 端侧可行性 | 日文 |
|---|---|---|---|---|
| LayoutLMv3-Base | 96.56% | 133M(~135MB INT8) | 勉强；需额外 OCR 前置 | 仅英文预训练 |
| **LiLT**（布局模块仅 6M） | 96.07% | 配蒸馏多语编码器 ~75M | **最有希望** | XFUND 日文 79.6% F1 |
| Donut（OCR-free） | 91.3% | ~860MB | ❌ 不可行 | 预训练含日文 |
| Florence-2/Moondream2/Qwen2.5-VL | — | 0.9–3.2GB | ❌ 远超约束 | 需微调 |

**结论：** Phase 2 推荐 **PP-OCRv5（读字）+ LiLT 布局模块 + 蒸馏多语编码器（~100–150MB INT8）**，在 Japanese-Mobile-Receipt-OCR-1.3K 上微调，目标延迟 3–5s（后台线程，小票扫描非实时可接受）。**切勿**在端上跑 Donut/LayoutLMv3-Large/任何 VLM。
来源：[arXiv 2408.06345 KIE 综述](https://arxiv.org/pdf/2408.06345)、[LiLT](https://aclanthology.org/2022.acl-long.534/)

### 5.4 云端精度天花板（仅作基准，不可用于本 app）

- Azure AI Document Intelligence `prebuilt-receipt` **支持日文** ja——最佳日文小票云基准（[MS Learn](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/language-support/prebuilt?view=doc-intel-4.0.0)）
- Google Document AI Expense Parser 自 v1.3.2(2024-09) **支持日文**
- AWS Textract AnalyzeExpense **不支持日文**（且不支持竖排）
- **JaPOC 基准**（[arXiv 2409.19948](https://arxiv.org/html/2409.19948v1)）：通用日文 OCR 在带印章凭证上仅 26.6%，Google Vision 72%，会计专用 Robota 99.1%，后处理纠正（T5）把均值 85.4%→94.8%——**印证：领域专用 + 后处理纠正对日文会计文档至关重要**
- 日本厂商（AI inside DX Suite 称 99.6%、Cogent Tegaki 称 99.2%）**均无 on-device 移动 SDK**，不适用

---

## 6. Flutter 实现细节

### 6.1 图像预处理

- **`image` 包 v4.9.1**（纯 Dart，0 原生体积）：灰度、对比度、高斯模糊、全局阈值。**无** Otsu/自适应二值化命名方法、无透视矫正、无去倾斜。配 `compute()` 跑 isolate。
- **`opencv_dart` v2.2.1+4**（FFI，预编译二进制）：自适应阈值、Otsu、Canny、`getPerspectiveTransform`+`warpPerspective`、形态学。体积 Android ~5–10MB/ABI（默认 core+imgproc+imgcodecs，opencv-mobile 最小构建），iOS ~4–5MB。同步执行，须自己包 `Isolate.run()`，**勿跨 isolate 传 Mat，传 Uint8List**。
- **建议：** MVP 用 `image` 包做灰度+对比度；需要透视矫正/不均匀光照自适应二值化再上 opencv_dart。

### 6.2 ML Kit 集成要点

`google_mlkit_text_recognition: ^0.15.1`，`TextRecognizer(script: TextRecognitionScript.japanese)`。Android API ≥23（日文模型），iOS 部署目标须抬到 ≥15.5，排除 armv7。复用 `TextRecognizer` 实例，相机流限一次仅一个 in-flight 调用。

### 6.3 Apple Vision 集成要点

推荐 **Pigeon**（类型安全代码生成）而非裸 MethodChannel。`request.recognitionLevel = .accurate`、`usesLanguageCorrection = true`、`recognitionLanguages = ["ja-JP", "en-US"]`（首语言优先级最高）。`boundingBox` 原点在左下需翻 Y 轴；`perform()` 须在后台线程；iOS 14–15 日文降级到 ML Kit。

### 6.4 拍摄与文档扫描

- 拍摄用 **`camera`**（`ResolutionPreset.high` 1080p，可叠加边缘检测 overlay）优于 `image_picker`。
- 文档扫描（自动裁切边界，显著提升 OCR 精度）：**`cunning_document_scanner` v1.4.0** 跨平台（Android 用 ML Kit，iOS 用 VisionKit）最实用；`google_mlkit_document_scanner` 功能更全但**仅 Android**。

### 6.5 性能（守住 <2s）

实测 ML Kit+解析 0.5–2s/帧、~50–100MB 峰值内存；Vision `.accurate` ~1.5–2.5s/帧。达标手段：输入 ≤1080p、文档扫描预裁切、**ROI 裁切 + 2x 上采样关键区域（实测最有效的单项改进）**、单张拍摄而非视频流、复用 recognizer 实例。
来源：[note.com 传单 OCR 复盘](https://note.com/myathy/n/n8823ecda2431?hl=en-US)

### 6.6 值得研究的开源样例

- **`receipt_recognition`**（ML Kit + fuzzywuzzy + 多帧稳定性合并，[GitHub](https://github.com/manfredbork/receipt_recognition)）：完整 4 层管道，多帧合并对实时模式关键，德/英
- **`ocr_scan_text`**（Boursorama，ML Kit + camera）：可配置校验阈值的 ScanModule 模式；ML Kit 会把相邻文本切成多块，需空间重组
- **note.com 传单 OCR 复盘**（Vision+ML Kit 日文）：ROI+2x 上采样最有效；Vision 与 ML Kit **并行跑再合并**取长补短；教科书式二值化锐化反而**降低**彩色版面效果（热敏小票可能不同，需实测）

---

## 7. 分阶段开发建议

### Phase 1 — MVP（守住 <10MB / <200MB / <2s）
1. **决策 iOS 部署目标**（§3，阻断项）
2. 拍摄：`camera` + `cunning_document_scanner` 预裁切
3. 预处理：`image` 包（灰度+对比度，isolate）
4. OCR：Android `google_mlkit_text_recognition` 日文；iOS 16+ Apple Vision(Pigeon) + iOS 15.5–15 降级 ML Kit
5. 提取：正则 + bounding-box 启发式
6. 校验：§4.4 的 10 条算术规则 + 置信度门控 + 用户确认 UI
7. 全角/半角数字归一化、令和年号转换作为独立工具函数

### Phase 2 — ML 增强（触发条件见 §5.2）
1. OCR 升级评估 PP-OCRv5 ONNX（需自建 FFI；先验证 Flutter 集成可行性）
2. KIE：LiLT 布局模块 + 蒸馏多语编码器（~100–150MB INT8，后台 3–5s）
3. 在 Japanese-Mobile-Receipt-OCR-1.3K 上微调（**先确认数据集 license**）
4. 后处理纠正层（JaPOC 模式）
5. 重新定义 Phase-2 体积约束（ML 模型不可能 <10MB）

### Phase 3 — 反馈闭环
用户纠正回流 → 商家库扩充 / 规则调优 / 模型再训练

---

## 8. 未解问题 / 低置信项（需进一步确认）

- **iOS 14/15 实际安装占比**——决定 §3 方案选择，需产品数据
- **ML Kit iOS pod 实际增包体积**——无 Google 官方数字，估 ~10–25MB（低置信）
- **Japanese-Mobile-Receipt-OCR-1.3K license**——preprint 摘要未声明，生产使用前必须确认
- **热敏小票上 ML Kit/Vision 的日文 CER/WER**——无公开针对性基准，~85–90% 为行业估算（中置信）
- **教科书二值化对热敏小票的效果**——传单复盘显示对彩色版面有害，热敏黑白可能相反，需实测
- **PP-OCRv5 Flutter 集成的真实工程量**——无现成包，需 spike 验证

---

## 9. 引用来源

**引擎对比**
- [google_mlkit_text_recognition (pub.dev)](https://pub.dev/packages/google_mlkit_text_recognition) · [ML Kit v2 Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android) · [ML Kit v2 iOS](https://developers.google.com/ml-kit/vision/text-recognition/v2/ios)
- [WWDC22 文本识别 session](https://developer.apple.com/videos/play/wwdc2022/10025/) · [VNRecognizeTextRequest.recognitionLanguages](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/recognitionlanguages) · [Apple 论坛: 日文支持](https://developer.apple.com/forums/thread/692193)
- [Vision vs ML Kit 对比 (Bitfactory)](https://www.bitfactory.io/de/dev-blog/comparing-on-device-ocr-frameworks-apple-vision-and-google-mlkit/) · [PaddleOCR vs Tesseract (ML Journey)](https://mljourney.com/paddleocr-vs-tesseract-comprehensive-comparison-for-ocr-implementation/)
- [flutter_tesseract_ocr](https://pub.dev/packages/flutter_tesseract_ocr) · [tessdata_best jpn (13.7MB)](https://github.com/tesseract-ocr/tessdata_best/blob/main/jpn.traineddata)
- [PP-OCRv5 (arXiv 2603.24373)](https://arxiv.org/abs/2603.24373v1) · [japan_PP-OCRv3_mobile_rec (HF)](https://huggingface.co/PaddlePaddle/japan_PP-OCRv3_mobile_rec) · [ente-io/mobile_ocr](https://github.com/ente-io/mobile_ocr)

**领域知识**
- [Stripe 合格发票格式](https://stripe.com/resources/more/qualified-invoices-format-japan) · [Stripe 登录番号](https://stripe.com/resources/more/invoice-system-registration-number-japan) · [Stripe 消費税收据](https://stripe.com/resources/more/how-to-include-consumption-tax-on-receipts-japan) · [Stripe 轻减税率](https://stripe.com/resources/more/consumption-tax-reduction-japan)
- [invoicedataextraction.com 读日文发票](https://invoicedataextraction.com/blog/how-to-read-japanese-invoices) · [mailmate 全角半角](https://mailmate.jp/blog/half-width-full-width-hankaku-zenkaku-explained) · [Wikipedia 日本日期记法](https://en.wikipedia.org/wiki/Date_and_time_notation_in_Japan)
- [NTA 消費税](https://www.nta.go.jp/english/taxes/consumption_tax/01.htm) · [NTA 合格发票公开库](https://www.invoice-kohyo.nta.go.jp/)

**数据集与 ML KIE**
- [CORD (clovaai)](https://github.com/clovaai/cord) · [Japanese-Mobile-Receipt-OCR-1.3K (TechRxiv)](https://www.techrxiv.org/doi/10.36227/techrxiv.175616889.90325672) · [Japanese-Receipt-VL-3B-JSON (HF)](https://huggingface.co/sabaridsnfuji/Japanese-Receipt-VL-3B-JSON)
- [Donut (arXiv 2111.15664)](https://arxiv.org/abs/2111.15664) · [LayoutLMv3 (arXiv 2204.08387)](https://arxiv.org/abs/2204.08387) · [LiLT (ACL 2022)](https://aclanthology.org/2022.acl-long.534/) · [KIE 综述 (arXiv 2408.06345)](https://arxiv.org/pdf/2408.06345)
- [JaPOC 后处理纠正 (arXiv 2409.19948)](https://arxiv.org/html/2409.19948v1) · [JaWildText (arXiv 2603.27942)](https://arxiv.org/pdf/2603.27942) · [混合规则+ML (MDPI 2025)](https://www.mdpi.com/2504-4990/7/4/167)

**云基准**
- [Azure Document Intelligence 语言支持](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/language-support/prebuilt?view=doc-intel-4.0.0) · [Google Document AI 处理器列表](https://cloud.google.com/document-ai/docs/processors-list) · [AWS Textract AnalyzeExpense](https://docs.aws.amazon.com/textract/latest/dg/invoices-receipts.html)
- [AI inside DX Suite](https://inside.ai/en/dx-suite/faq) · [Cogent Tegaki](https://www.cogent.co.jp/en/news/cogentlabs-tegaki-reborn/) · [Veryfi 基准](https://www.veryfi.com/technology/line-item-extraction-accuracy-benchmarks/)

**Flutter 实现**
- [opencv_dart](https://pub.dev/packages/opencv_dart) · [opencv-mobile (体积基准)](https://github.com/nihui/opencv-mobile) · [image 包](https://pub.dev/packages/image) · [Pigeon](https://pub.dev/packages/pigeon)
- [cunning_document_scanner](https://pub.dev/packages/cunning_document_scanner) · [google_mlkit_document_scanner](https://pub.dev/packages/google_mlkit_document_scanner)
- [receipt_recognition (GitHub)](https://github.com/manfredbork/receipt_recognition) · [ocr_scan_text (Boursorama)](https://github.com/boursorama/ocr_scan_text) · [note.com 传单 OCR 复盘](https://note.com/myathy/n/n8823ecda2431?hl=en-US)

---

> 本报告仅为调研产出，不含实现。后续：决策 §3 的 iOS 目标后，可走 `/gsd-plan-phase`（MOD-005 OCR）或 `/sc:design` 进入设计。建议先做一个 PP-OCRv5 Flutter 集成可行性 spike，以确认 Phase-2 路径成本。
