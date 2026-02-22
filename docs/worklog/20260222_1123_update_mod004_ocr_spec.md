# MOD-004 OCR 模块规格更新

**日期:** 2026-02-22
**时间:** 11:23
**任务类型:** 文档
**状态:** 已完成
**相关模块:** MOD-004 OCR

---

## 任务概述

基于实际代码实现（OcrScannerScreen、TransactionConfirmScreen）和 docs/arch/01-core-architecture 架构文档，全面更新 MOD-004_OCR.md 技术实现方案，使其准确反映当前实现状态和未来规划。

---

## 完成的工作

### 1. 主要变更

**修正了模块编号错误：**
- 旧文档 header 错误标注为 `MOD-005`，文件名是 `MOD-004_OCR.md`，已更正为 `MOD-004`

**反映真实实现状态：**
- 新增"当前实现状态"章节，明确区分已实现（stub）和待实现功能
- `OcrScannerScreen` 是 stub：快门按钮仅执行 `Navigator.pop()`，无实际 OCR 逻辑
- 后端管道（`lib/application/ocr/`、`lib/infrastructure/ml/`）尚未创建

**更正架构位置：**
- 旧文档：声称存在 `lib/features/ocr/` 独立 feature（实际不存在）
- 新文档：OCR screens 实际位于 `lib/features/accounting/presentation/screens/`
- 明确 "不创建独立 OCR feature" 的设计决策，遵循 thin feature 模式

**明确共用 TransactionConfirmScreen 的设计：**
- OCR 流程不使用单独的 OCRConfirmationScreen（旧文档有误）
- 与手动录入共用同一 `TransactionConfirmScreen`
- 识别结果通过构造函数参数（amount、category、parentCategory、date）传入

**记录 EntryModeNavigationConfig 导航机制：**
- `InputMode` enum（manual/ocr/voice）
- `pushReplacement` 模式切换（同一 back stack 层级）
- `EntryModeSwitcher` → `InputModeTabs` → `navigateToEntryMode()`

**补充 TransactionConfirmScreen 实际能力：**
- 金额、分类、日期均可编辑
- 商家（merchant）、备注（memo）文本输入
- LedgerTypeSelector（账本类型）自动从 category 解析
- SoulSatisfactionSlider（灵魂满足感滑条）
- SoulCelebrationOverlay（灵魂账本保存庆祝动效）
- "添加照片"stub 按钮（待接入 PhotoRepository）

### 2. 技术决策

**保留完整后端实现方案（Phase 2）：**
- 保留了 ReceiptParser、MerchantDatabase、OCRService 等实现细节
- 更新 ScanReceiptUseCase 返回类型为 `ScannedReceiptResult`，明确其与 TransactionConfirmScreen 参数的对应关系

**删除了：**
- 旧的 `OCRConfirmationScreen` UI 代码示例（实际不存在）
- `lib/features/ocr/` 目录结构示例（实际架构不如此）
- 过时的 OCRScanScreen UI 代码（与实际代码不一致）

### 3. 代码变更统计
- 修改文件：1（docs/arch/02-module-specs/MOD-004_OCR.md）
- 文档从 ~2300 行精简并重构为结构更清晰的版本
- 文档版本：v2.0 → v3.0

---

## 关键发现

| 发现 | 影响 |
|------|------|
| OcrScannerScreen 仅是 stub | 实现快门功能前无法端到端测试 OCR 流程 |
| lib/application/ocr/ 不存在 | OCR 后端 7 天工期从零开始 |
| TransactionConfirmScreen 完整可用 | OCR 接入只需要实现扫描→参数传递，确认页无需改动 |
| EntryModeNavigationConfig 已完成 | 三模式切换基础设施已就绪 |

---

## 测试验证

- [x] 文档结构检查
- [x] 与实际代码对照验证（OcrScannerScreen、TransactionConfirmScreen、EntryModeNavigationConfig）
- [x] 架构层次验证（符合 5 层 Clean Architecture）
- [ ] 后端实现阶段再做集成测试

---

## 后续工作

- [ ] 实现 OcrScannerScreen 快门功能（image_picker 接入）
- [ ] 实现 lib/infrastructure/ml/ocr/ OCR 服务（ML Kit / Vision Framework）
- [ ] 实现 lib/infrastructure/ml/image_preprocessor.dart
- [ ] 实现 lib/application/ocr/ 用例层
- [ ] 实现 lib/data/tables/receipt_photos_table.dart
- [ ] 在 TransactionConfirmScreen 接入照片显示（photoHash）

---

**创建时间:** 2026-02-22 11:23
**作者:** Claude Sonnet 4.6
