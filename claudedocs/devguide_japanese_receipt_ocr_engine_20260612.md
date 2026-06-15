# 日文小票 OCR 引擎 开发手册

**版本:** 1.1（1.0→1.1 补全 §11 人工分工 / §12 样本采集 / §13 工程边界）
**日期:** 2026-06-12
**适用模块:** MOD-005 OCR（规范文档 MOD-004_OCR.md）/ MOD-003 智能分类
**相关决策:** ADR-005（双原生 OCR，已接受）
**依据调研:**
- `claudedocs/research_japanese_receipt_ocr_engine_20260612.md`（引擎/领域/ML/Flutter 四路调研）
- 本会话 sub-50MB 专题二次调研（KIE 小模型 + OCR+KIE 整体管道）

> **本手册定位:** 把调研结论落成可执行的工程方案。收敛架构 = **分层 sub-50MB**（读字层 + 规则抽取 + 算术校验 + 可选微型标注器），放弃 280MB 单体大模型路线。

---

## 0. 开工前的阻断决策（必须先定）

### 🔴 D-0: iOS 部署目标
项目当前 iOS 14+,但:
- ML Kit 日文 pod 最低 **iOS 15.5**
- Apple Vision 日文支持始于 **iOS 16**

iOS 14/15 上两个引擎都无法做日文 OCR。**这是 OCR 一切工作的前置条件,先定再开工。** 推荐:

| 方案 | 取舍 | 推荐度 |
|---|---|---|
| **A. OCR 功能门控 iOS 16+** | Vision 主路径,最简洁,丢 iOS 14/15(2026 已极少) | ⭐ 推荐 |
| C. OCR 门控 iOS 15.5+,ML Kit 通用 + iOS16 加 Vision | 仅丢 iOS 14,折中 | 备选 |
| B. 为 iOS 14 单独降级 | ML Kit 本身要 15.5,iOS14 仍无解,徒增复杂度 | ✗ 不推荐 |

> 决策需用 iOS 14/15 实际安装占比佐证。技术默认走 **A**。

---

## 1. 架构总览

### 1.1 四模块管道（与 MOD-004 一致,修正 ML 部分）

```
拍摄/选图
  → [A] 图像预处理
  → [B] OCR 引擎（读字：词 + bounding box + 置信度）
  → [C] 结构化提取（规则优先 + bbox 启发式）
  → [D] 算术校验 + 置信度门控
  → 用户确认 UI
  → 落库（交易草稿）
       ↘ [E 可选增强] 微型 KIE 标注器（店名/明细补强,仅触发后启用）
```

### 1.2 sub-50MB 组件预算（收敛后的核心架构）

| 组件 | 技术 | iOS 增量 | Android 增量 |
|---|---|---|---|
| OCR 检测+识别 | iOS: Apple Vision / Android: ML Kit 日文 | **0MB**（系统内置） | **~4MB**/架构 |
| OCR 备选(评估) | PP-OCRv5 mobile ONNX | ~21MB | ~21MB |
| 图像预处理 | `image` 包（纯 Dart） | 0MB | 0MB |
| 规则抽取 + 归一化 | Dart 代码 | 0MB | 0MB |
| 算术校验 | Dart 代码 | 0MB | 0MB |
| **[E] 微型 KIE 标注器** | BiLSTM-CRF INT8 ONNX | **2–8MB** | 2–8MB |
| **MVP 合计** | | **~0MB** | **~4MB** ✅ |
| **增强合计** | | **~2–8MB** | **~6–12MB** ✅ |

> 关键事实:**MVP 几乎零模型增量**。OCR 复用系统/ML Kit,抽取与校验全是 Dart。sub-50MB 目标在增强阶段也轻松满足。280MB 的 LiLT-XLM-R 方案**不采用**。

### 1.3 精度预期（vs 280MB 大模型,见调研专题）

| 字段 | MVP(规则+校验) | +微型标注器 | 280MB LiLT(对照,不采用) |
|---|---|---|---|
| 合計 | 90–95% | 93–96% | 97–99% |
| 日期 | 92–96% | 92–96% | 97–99% |
| 税额 | 88–93% | 88–93% | 95–98% |
| 店名 | 55–70% | **75–85%** | 90–95% |
| 逐项明细 | 60–80% | 70–80% | 85–92% |

**结论:对记账 app,合計/税/日期(关键三项)MVP 即 ≥90%。店名/明细才需要微型标注器,差距与 280MB 方案仅 ~10 点,但体积差 30–50 倍。**

---

## 2. ⭐ 核心重点工作（Critical Path）

> 这一节是全手册的重心。按**杠杆度 × 依赖关系**排序,前 5 项是 MVP 必做且互相依赖的关键路径,第 6–7 项是可选增强。

### CP-1 🔴 决策 iOS 部署目标（§0）
- **杠杆:** 阻断 OCR 全部工作 · **工作量:** 决策 · **依赖:** 无
- 不定这个,OCR 引擎层无法动工。

### CP-2 ⭐⭐⭐ OCR 引擎抽象层 + 双原生实现（地基）
- **杠杆:** 最高,后续全部依赖它 · **工作量:** 中-高 · **依赖:** CP-1
- 定义统一接口 `OcrService`,返回**词 + 归一化 bounding box + 置信度**(不只是纯文本——bbox 是 §C 启发式和 §E 标注器的命脉)。
- Android: `google_mlkit_text_recognition`(日文 script);iOS: **Pigeon** 封装 `VNRecognizeTextRequest`(`ja-JP` + `.accurate`)。
- **这是整个引擎的地基,质量决定上限。**

### CP-3 ⭐⭐⭐ 日文归一化工具集（小但渗透一切）
- **杠杆:** 极高(每个下游模块都调用) · **工作量:** 低 · **依赖:** 无(可与 CP-2 并行)
- 全角↔半角数字归一化、`¥/￥/円` 统一、令和/平成年号→西历、`令和元年`=1 特判、易混字形纠正(`令/今`、`ロ/口`、`0/O`)。
- **不做这个,后面所有正则和校验都会零散踩坑。优先做、做扎实、单元测试覆盖。**

### CP-4 ⭐⭐ 规则提取器（交付 MVP 价值）
- **杠杆:** 高(直接产出可用结果) · **工作量:** 中 · **依赖:** CP-2, CP-3
- 合計/小計/税/日期正则 + 用 bbox 的 Y 坐标取顶部最大块当店名。
- 总额判定**不靠关键字,靠算术约束**(见 CP-5)。
- 用 MVP 规则做 §E 训练数据的**预标注器**(人工只纠错)——一举两得。

### CP-5 ⭐⭐⭐ 算术校验层（精度倍增器,极廉价）
- **杠杆:** 极高(几乎零成本把精度从"识别"提到"可信") · **工作量:** 低 · **依赖:** CP-3
- 10 条算术不变量(§6.4),最强是 **`お釣り = お預り − 合計`(精确相等)**。
- 作用:抓 OCR 数字错、消歧总额/小计、给每字段算置信度。
- **这是 sub-50MB 路线能逼近大模型精度的关键武器,务必完整实现。**

### CP-6 ⭐⭐ 置信度门控 + 用户确认 UI（让错误可恢复）
- **杠杆:** 高(决定产品体验) · **工作量:** 中 · **依赖:** CP-4, CP-5
- 高置信自动填充,低置信/校验失败高亮提示用户确认编辑。
- 用户纠正回流本地训练集(接 CP-7 / Phase 3 闭环)。

### CP-7 ⭐（增强,触发后才做）微型 KIE 标注器
- **杠杆:** 中(只补店名/明细) · **工作量:** 高 · **依赖:** CP-2~CP-6 + 标注数据
- 触发条件(任一):纠错率 >10% / 需手写支持 / 需逐项明细 / 店名匹配失败 >20%。
- 方案见 §5。**不要提前做**——MVP 关键三项已够用。

### 核心重点一句话
> **地基是 CP-2(OCR 抽象+双原生)**;**最高性价比是 CP-3 归一化 + CP-5 算术校验**(低成本、高杠杆,把识别结果变可信);**CP-4 交付价值**。这四项构成 MVP,几乎零模型增量就拿到关键字段 ≥90%。CP-7 是按需增强。

---

## 3. 分层落地（放到 Clean Architecture 哪一层）

遵循"Thin Feature"——feature 内不放 application/infrastructure/data。

```
lib/infrastructure/ocr/                 # 技术能力:OCR 引擎
  ├── ocr_service.dart                  # 抽象接口（CP-2）
  ├── mlkit_ocr_service.dart            # Android 实现
  ├── vision_ocr_service.dart           # iOS（走 Pigeon channel）
  └── ocr_engine_selector.dart          # 按平台/iOS 版本选引擎 + 降级
lib/infrastructure/ocr/preprocessing/   # 图像预处理（模块A）
  └── image_preprocessor.dart           # image 包,跑 isolate
lib/infrastructure/i18n/normalize/      # 日文归一化（CP-3,跨模块复用）
  ├── number_normalizer.dart            # 全角/半角、¥/円
  └── japanese_date_parser.dart         # 令和/平成/西历
lib/infrastructure/ml/                   # 微型 KIE 标注器（CP-7,可选）
  └── receipt_kie_tagger.dart           # onnxruntime 加载 INT8 模型
lib/application/ocr/                      # 业务用例（模块C/D）
  ├── scan_receipt_use_case.dart        # 编排 A→B→C→D
  ├── receipt_field_extractor.dart      # 规则提取（CP-4）
  ├── receipt_validator.dart            # 算术校验 10 条（CP-5）
  └── record_correction_use_case.dart   # 用户纠正回流（CP-6/Phase3）
lib/features/ocr/domain/
  ├── models/                           # ParsedReceipt, ReceiptField, FieldConfidence
  └── repositories/                     # OcrRepository 接口
lib/features/ocr/presentation/
  ├── screens/                          # 拍摄、确认编辑页
  ├── widgets/                          # 字段编辑卡、置信度标记
  └── providers/                        # Riverpod 装配（@riverpod）
ios/Runner/Ocr/                          # Native:Pigeon 生成的 Swift + Vision 实现
```

**Native(iOS):** Pigeon schema 放 `pigeons/ocr_api.dart`,生成 Dart + Swift 桩;Vision 实现 ~100 行 Swift。

---

## 4. 模块详解

### 4.1 模块 A — 图像预处理
- **MVP:** `image` 包(纯 Dart,0 原生体积):灰度 + 对比度增强,`compute()` 跑 isolate。
- **需要时:** 透视矫正/不均匀光照自适应二值化 → `opencv_dart`(+5–20MB,谨慎)。
- **拍摄:** `camera`(1080p,可叠边缘 overlay)+ `cunning_document_scanner`(自动裁切,跨平台,显著提升精度)。
- **关键提醒:** 热敏小票黑白,教科书式二值化/锐化**未必有益**(彩色版面实测反而有害,需实测);**ROI 裁切 + 2x 上采样**是实测最有效的单项改进。

### 4.2 模块 B — OCR 引擎（CP-2）
统一接口契约:
```dart
abstract class OcrService {
  Future<OcrResult> recognize(File image);
}
class OcrResult {
  final List<OcrToken> tokens;   // 每个含 text + box(归一化0-1) + confidence
  final String rawText;
}
```
- **Android:** `TextRecognizer(script: TextRecognitionScript.japanese)`,复用实例,相机流限单 in-flight。
- **iOS(16+):** Pigeon → `VNRecognizeTextRequest`,`recognitionLanguages = ["ja-JP","en-US"]`,`recognitionLevel = .accurate`,`usesLanguageCorrection = true`;`boundingBox` 原点左下需翻 Y;`perform()` 在后台线程。
- **选择器:** `OcrEngineSelector` 按平台 + iOS 版本路由,iOS<16 按 CP-1 决策处理(降级 ML Kit 或禁用)。

### 4.3 模块 C — 结构化提取（CP-4）
- 金额:`[合計|お買上合計|税込合計][^\d]*([¥￥]?[\d,]+)`
- 日期:西历 + 和历多模式(先过 CP-3 的 `japanese_date_parser`)
- 店名:bbox Y 坐标最顶 + 字号最大块(MVP 启发式)
- 税:`消費税|税額` 锚定;识别 `8%対象/10%対象` 双税率块
- **总额最终判定走算术约束(CP-5),不信单一关键字**
- 输出每字段附 candidate 列表 + 来源,供校验层消歧

### 4.4 模块 D — 算术校验（CP-5,10 条不变量）
1. `Σ明细 ≈ 小計`(±1円,仅当列全明细)
2. `小計 + 税 = 合計`(双税率分别)(±1円)
3. `税 ≈ 类目小计 × 税率`(±1円,取整模式不定)
4. `お預り ≥ 合計`
5. **`お釣り = お預り − 合計`(精确,最强单字段校验)**
6. 日期合理性(晚于开业、早于今天、令和范围)
7. 金额位数合理(零售总额 ≤6 位)
8. T番号 `^T\d{13}$`
9. ※ 标记明细须计入 8%対象
10. 三种取整模式应恰有一种对 8%/10% 都吻合
- 每条违反 → 降低相关字段置信度 + 标记给 UI。

### 4.5 模块 E — 微型 KIE 标注器（CP-7,可选,见 §5）

---

## 5. 微型 KIE 标注器 训练手册（CP-7）

> 仅在 §2 CP-7 触发条件出现后做。目标:补强店名/明细,体积 2–8MB(INT8),远小于 280MB 大模型。

### 5.1 选型:BiLSTM-CRF（首选）或 LiLT+微型编码器
| 方案 | INT8 体积 | 布局感知 | 工作量 | 适用 |
|---|---|---|---|---|
| **BiLSTM-CRF（字符 embed + 手工空间特征 + CRF）** | **2–8MB** | 靠手工特征 | 中(从头训) | ⭐ 首选 |
| LiLT 布局模块(6MB)+ 自训 4 层日语编码器 | ~21–40MB | 原生 | 高(需预训练) | 要更强布局时 |
| LINE DistilBERT-Ja + INT4 | ~17–34MB | 否(纯文本) | 中 | 不需布局时 |

> 不选:XLM-R(即便词表裁剪+INT4 仍 ~60–80MB);Tohoku 字符 BERT(主体 84MB);Donut/VLM(数百 MB–GB)。

### 5.2 训练流程（BiLSTM-CRF）
1. **数据:** OCR token 序列 + 每 token BIO 标签(STORE_NAME/TOTAL/DATE/TAX/ITEM_NAME/ITEM_PRICE…)。来源:用 CP-4 规则预标注 + 人工纠错;Japanese-Mobile-Receipt-OCR-1.3K(确认 license)对齐;SynthDoG-ja 合成补稀有字段。数百~千条即可。
2. **特征:** 字符 embedding(dim 25–50)+ **手工空间特征**(x 位置桶、行号、字号桶、是否含 ¥/数字/※)——这是替代布局 transformer 的关键。
3. **模型:** char-embed → char BiLSTM → token BiLSTM → CRF。日文用字符级优于词级。
4. **训练:** PyTorch/Keras,seqeval entity-F1 评估,**按店铺/版式留出测试集**。
5. **导出:** → ONNX → INT8 量化(onnxruntime)→ 2–8MB。
6. **集成:** Flutter `onnxruntime` 包,后台 isolate;链路 OCR(词+框)→ 特征 → 标注器 → 重构字段 → CP-5 校验。

### 5.3 数据增强（必做）
热敏褪色模拟、模糊、旋转、透视、亮度抖动——真实小票都劣质。

### 5.4 反馈闭环（Phase 3）
用户纠正 → 本地存样本 → **你机器上离线重训 → 下发模型**(不在端上训练)。Active learning:优先标注低置信/违反校验的样本。

---

## 6. 日文领域要点速查

### 6.1 字段词表（关键）
合計/お買上合計/税込合計(总额) · 小計 · 消費税/税額 · 税込/税抜 · 内税/外税 · 8%対象/10%対象 · 消費税8%/消費税10% · お預り · お釣り · 点数 · 登録番号(T+13位)

### 6.2 軽減税率 & インボイス
- 2019-10 起 10% 标准 / 8% 轻减(外带食品饮料 8%,堂食/酒 10%)
- 8% 商品逐行标 ※ 或 軽,底部图例 `※印は軽減税率対象商品です`
- 税按"每税率类目"算一次,可向下/四舍五入/向上取整 → **Σ逐行税 ≠ 打印税是正常的**
- インボイス(2023-10 起):登録番号 `T` + 13 位数字,可对 NTA 公开库校验

### 6.3 日期
西历 `2026/06/12`、`2026年06月12日`、和历 `令和8年6月12日`/`R8.6.12`、首年 `令和元年`(=1,特判)、含时间(居酒屋可 `26:30`)。令和N年 → 西历 = N+2018。令(U+4EE4) 易误读为 今。

### 6.4 字符
全角/半角片假名、全角/半角数字、汉字假名混排、**无词边界**(标签直连数值,不能靠空格分隔)。易混:0/O、1/l、ロ/口、令/今、8/B、全角０/半角0。

---

## 7. 测试策略

| 层 | 测试 |
|---|---|
| CP-3 归一化 | 单元:全角/半角、各年号、`令和元年`、易混字形(高覆盖,基石) |
| CP-4 提取 | 单元:各字段正则;真实小票样本回归集 |
| CP-5 校验 | 单元:10 条规则各正/反例;构造 OCR 错误验证能抓出 |
| CP-2 OCR | 集成:Android ML Kit / iOS Vision channel;mock OcrResult 喂下游 |
| 端到端 | 真实多版式小票(便利店/超市/餐厅)按店铺留出,**连 OCR 一起测**(错误会传导) |
| CP-7 标注器 | seqeval F1;§6.4 校验作 sanity |

覆盖率 ≥80%(项目要求)。

---

## 8. 分阶段路线图

### Phase 1 — MVP（关键路径 CP-1~CP-6,~0 模型增量）
里程碑:
- M1: CP-1 决策 + CP-2 OCR 抽象+双原生跑通(出词+框+置信度)
- M2: CP-3 归一化工具集 + 单测
- M3: CP-4 规则提取 + CP-5 校验
- M4: CP-6 确认 UI + 端到端真机验证(关键三项 ≥90%)

### Phase 2 — 增强（触发后,CP-7,sub-50MB）
- M5: 标注数据 + BiLSTM-CRF 训练 + ONNX INT8
- M6: Flutter onnxruntime 集成 + 回落策略 + A/B 对比规则法

### Phase 3 — 闭环
- M7: 纠正回流 + 离线重训 + active learning

---

## 9. 关键决策与风险登记

| ID | 项 | 状态 | 处置 |
|---|---|---|---|
| D-0 | iOS 部署目标(14+ vs 16+) | 🔴 待决策 | 阻断 CP-2,需安装占比数据 |
| R-1 | iOS 14/15 无日文 OCR | 开放 | 由 D-0 决定 |
| R-2 | ML Kit pod iOS 增包体积无官方数 | 低 | 估 ~10–25MB,集成后实测 |
| R-3 | Japanese-Mobile-Receipt-OCR-1.3K license 未声明 | 开放 | 用前必确认,否则自标注/合成 |
| R-4 | 热敏小票 ML Kit/Vision 日文无公开基准 | 中 | ~85–90% 估算,需自建回归集实测 |
| R-5 | 教科书二值化对热敏效果不确定 | 中 | 实测决定预处理强度 |
| R-6 | 微型标注器无现成日语 checkpoint | 中 | 需自训(CP-7) |
| DOC-1 | MOD-004 Phase 2 事实错误(CORD=11000日语 / Donut转TFLite>98%) | 待修 | 改为本手册 sub-50MB 路线 |

---

## 10. 人工参与 vs 纯开发分工

分两个维度——开发期(参与者:你/标注员/领域专家)与运行期(参与者:终端用户)。

### 11.1 开发期

🟢 **纯开发**(写代码即可,输入输出明确、可单测):
- CP-2 OCR 抽象 + 双原生封装(Pigeon/ML Kit wiring)
- CP-3 归一化工具 · CP-5 算术校验 · CP-6 UI 代码 · 模块A 预处理
- CP-7 推理侧:ONNX 加载 + Flutter 集成;INT8 量化/导出脚本

🟡 **需人工参与/判断**(无法靠代码自动完成):
| 工作 | 谁 | 人工做什么 |
|---|---|---|
| CP-1 iOS 目标决策 | 产品/你 | 看安装占比拍板(阻断 CP-2) |
| 真实小票采集 | 人力 | 多版式收集(见 §12) |
| CP-4 规则设计前样本观察 | 工程+领域 | 看真实小票总结版式再写正则 |
| 精度回归集标注 | 标注员 | 标 ground-truth 才能量化精度 |
| CP-7 训练数据 BIO 标注 | 标注员(重) | 即便预标注仍需纠错 |
| 置信度阈值调参 | 工程师 | 看 precision/recall 权衡 |
| 领域正确性审查 | 懂日本税制者 | 税率/年号/※标记语义确认 |
| 预处理强度实测 | 工程师 | 二值化对热敏纸是否有益 |
| 模型达标判定 | 你 | 看 F1 决定上线/回落 |

> **资源黑洞:** CP-7 的数据标注是最大人力消耗;领域审查需一名懂日本税制的人把关。MVP(CP-2~CP-6)人工集中在"样本观察 + 回归集标注 + 阈值调参",可控。

### 11.2 运行期(产品流程)

🟢 **全自动(用户无感):** 预处理 → OCR → 规则提取 → 算术校验 → 置信度 → 高置信字段自动填充

🟡 **需用户人工校验:**
| 触发 | 原因 |
|---|---|
| 低置信字段 | 识别不确定,请确认/编辑 |
| 算术校验失败(如 お釣り≠お預り−合計) | 必有 OCR 错,强制核对 |
| 店名(MVP 55–70%) | 高概率需确认(CP-7 后→75–85%) |
| 逐项明细 | 精度低,需核对 |
| 缺失字段 | 用户补填 |
| 落库前整单 review | 点"保存"确认草稿 |

> **原则:** 关键三项(合計/税/日期)高置信静默填充;其余 + 任何校验失败项主动高亮请用户确认。用户纠正回流训练集(CP-6→CP-7 闭环)。

---

## 11. 真实小票样本:用途分布与采集纪律

样本"采集一次、多处复用",但用量与标注要求不同。

| 步骤 | 用途 | 用量 | 标注 | 阶段 |
|---|---|---|---|---|
| ① CP-4 规则观察 | 总结版式写正则/启发式 | 几十张 | 不需 | MVP,最早 |
| ② 精度回归集 | 量化精度、卡发布、防回归 | ~150 张 | 需 ground-truth | MVP,贯穿 |
| ③ CP-7 训练数据 | 训练 BiLSTM-CRF(BIO) | **数百~千张(大头)** | 需 BIO 标注 | Phase 2 |
| (次)预处理实测 R-5 | 判断二值化是否有益 | 几十张 | 不需 | MVP |
| (次)Phase 3 闭环 | 用户纠正回流 | 持续 | 自带纠正 | 运行时 |

**MVP 主要用在 ①+②;Phase 2 大规模消耗在 ③。**

### ⚠️ 采集纪律:三向切分,测试集锁死
回归集(②)绝不能参与规则设计(①)或训练(③),否则"对着考卷出题",精度虚高。
```
采集(版式多样:便利店/超市/餐厅/药妆,清晰+褪色+倾斜)
  ├── 观察集 ~30张(不标注,给①)
  ├── 测试集 ~150张(标 ground-truth,给②,锁死)
  └── 训练集 数百-千张(BIO 标注,给③,可增强)
```
务必覆盖:**多连锁版式 + 热敏褪色 + 模糊/倾斜 + 8%/10% 双税率 + 令和/西历日期 + 带 T番号合格发票**——精度差距集中在这些地方。

---

## 12. 工程边界:app 内开发 vs 单独工具

交接物是 **`.onnx` 模型文件**:单独工具产出 → 作为 asset 打进 app 被调用。

### 🟦 在 app 里(打包,跑在用户设备)
| 步骤 | 形态 |
|---|---|
| CP-2 OCR 抽象 + 双原生 | Dart + **iOS Swift(Pigeon,也编进包)** |
| CP-3 归一化 / CP-4 规则 / CP-5 校验 | Dart |
| CP-6 门控 + 确认 UI / 模块A 预处理拍摄 | Dart(Flutter) |
| CP-7 推理侧 | Dart(`onnxruntime`)+ `.onnx` asset |

### 🟧 单独工具(独立脚本,不打包,跑你机器/服务器)
| 步骤 | 栈 |
|---|---|
| 样本采集/管理、三向切分 | 脚本 + 目录规范 |
| 标注工作流 | Label Studio + 预标注脚本 |
| 精度回归评估 | **Dart test**(优先)或 Python |
| CP-7 训练 / 数据增强 / SynthDoG-ja 合成 | Python/PyTorch |
| ONNX 导出 + INT8 量化(产出交接物) | Python(optimum/onnxruntime) |
| Phase 3 离线重训 + 模型下发 | Python + 分发基建 |

### 交接点
```
[单独工具] 训练→量化→ receipt_kie.onnx
                          ↓ asset 打包
[app 内]  onnxruntime 加载→推理→字段
```

### ⚠️ 两处易混淆
1. **CP-4 规则逻辑两边用**:主体在 app(Dart 运行时),训练阶段预标注脚本也要同逻辑。建议 **Dart 单实现**,工具侧用 `dart` 脚本跑同一套代码,避免双实现漂移。
2. **回归评估是中间态**:在 repo 但不打包,写成 **`flutter test`** 直接复用 app 的 CP-4/CP-5 Dart 代码 + 回归集,既不进生产包又不重写逻辑。

### 一句话
- **app 内:** CP-2~CP-6 全部(含 iOS Swift)+ CP-7 推理侧 = "识别→提取→校验→UI→跑模型"
- **单独工具:** 所有数据与模型生产 = "造模型"的一切
- **交接物:** `.onnx`;**特例:** 规则逻辑 Dart 单实现两边共用、回归评估写成 `flutter test`

---

## 13. 引用

详见两份调研报告:
- `claudedocs/research_japanese_receipt_ocr_engine_20260612.md`（含 ML Kit/Vision/Tesseract/PaddleOCR、軽減税率/インボイス、CORD/数据集、Flutter 实现等全部一手引用）
- sub-50MB 专题关键来源:PP-OCRv5 mobile ~21MB([DeepWiki](https://deepwiki.com/PaddlePaddle/PaddleOCR/2.1-pp-ocrv5-universal-text-recognition))、日文行精度 75.77%([HF](https://huggingface.co/PaddlePaddle/PP-OCRv5_mobile_rec))、LiLT 布局模块 6.1M([LiLT](https://ar5iv.labs.arxiv.org/html/2202.13669))、词表裁剪([vocabtrimmer](https://github.com/asahi417/lm-vocab-trimmer))、BiLSTM-CRF 日文 NER([ACL W17-4114](https://aclanthology.org/W17-4114/))、混合规则+ML F1=0.98([MDPI](https://www.mdpi.com/2504-4990/7/4/167))、`onnxruntime` Flutter([plugin](https://github.com/gtbluesky/onnxruntime_flutter))

---

> **后续路径:** 定 D-0 后,可走 `/gsd-plan-phase`(MOD-005)把 CP-1~CP-6 排成可执行计划;或先做 CP-2/CP-3 的 spike 验证双原生与归一化。CP-7 待触发条件出现再启动。
