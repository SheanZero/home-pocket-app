# MOD-009 语音记账模块技术文档编写

**日期:** 2026-02-22
**时间:** 11:27
**任务类型:** 文档
**状态:** 已完成
**相关模块:** MOD-009 语音记账

---

## 任务概述

基于用户需求，设计并编写语音记账模块（MOD-009）的完整技术设计文档。模块使用 `speech_to_text` 库实现语音转文字，重点解决金额提取、类目/商家模糊匹配、以及灵魂账本语音满意度估算。

---

## 完成的工作

### 1. 技术调研

- 调研 `speech_to_text` v7.x API：核心方法、partial/final results、sound level callback
- 确认多语言支持：ja-JP、zh-CN、en-US 均原生支持
- 分析音量数据：仅提供 dB/RMS 单值，不提供音高(Hz)
- 评估满意度估算方案：排除音高分析（Android 麦克风独占限制），确定使用"音量+语速+文本情感"组合方案
- 调研现有代码架构：VoiceInputScreen stub、InputMode 枚举、EntryModeNavigationConfig、分类/商家系统

### 2. 文档编写

新建 `docs/arch/02-module-specs/MOD-009_VoiceInput.md`，包含：

- **模块概述**: 业务价值、核心功能表、技术栈
- **功能需求 (FR-001~FR-006)**: 语音转文字、金额提取、类目匹配、商家匹配、满意度估算、权限管理
- **技术设计**: 5层架构图、目录结构、依赖关系
- **核心流程**: SpeechRecognitionService 封装、ParseVoiceInputUseCase、VoiceParseResult 模型
- **NLP解析引擎**: 阿拉伯数字+汉字数词金额提取、商家提取算法、100+多语言关键词类目匹配
- **语音满意度估算**: 5信号加权算法（音量均值25%、音量变化率25%、语速20%、文本情感20%、时长10%）
- **UI组件设计**: 界面布局、状态流转、波形动画组件
- **测试策略**: 单元测试（VoiceTextParser/CategoryMatcher/SatisfactionEstimator）、Widget测试、集成测试
- **性能优化**: 防抖解析、商家匹配缓存、音量采样优化

### 3. 索引更新

更新 `ARCH-000_INDEX.md`：
- 功能模块表新增 MOD-009 条目
- 统计数据：功能模块 7→8，总计 29→30

### 4. 关键技术决策

| 决策 | 选项 | 结论 | 理由 |
|------|------|------|------|
| 满意度信号来源 | 音高分析 vs 音量+文本 | 音量+文本组合 | Android 麦克风独占，无法同时使用 speech_to_text 和音高检测 |
| NLP引擎 | 第三方NLP库 vs 纯Dart正则 | 纯Dart正则+关键词 | 避免额外依赖，金额/类目场景规则明确 |
| 商家匹配 | 新建数据库 vs 复用 MOD-004 | 复用 MerchantDatabase | DRY原则，500+商家已定义 |
| 音量归一化 | 统一范围 vs 原始值 | 归一化至 0.0~1.0 | Android RMS 和 iOS dB 单位不同，必须统一 |

---

## 代码变更统计

- 新增文件: 1 (`docs/arch/02-module-specs/MOD-009_VoiceInput.md`)
- 修改文件: 1 (`docs/arch/01-core-architecture/ARCH-000_INDEX.md`)
- 文档行数: ~900 行

---

## 测试验证

- [x] MOD-009 文档结构完整（参照 MOD-004 格式）
- [x] 架构遵循 5 层 Clean Architecture + Thin Feature 规则
- [x] 目录结构无违规（Use Cases 在 application/、Infrastructure 在 infrastructure/）
- [x] ARCH-000_INDEX.md 链接有效
- [ ] 实际代码实现（待后续开发）

---

## 后续工作

- [ ] 实际开发 MOD-009（预估 8 天）
- [ ] 添加 `speech_to_text` 依赖到 pubspec.yaml
- [ ] 实现 SpeechRecognitionService
- [ ] 实现 VoiceTextParser（NLP 金额+商家提取）
- [ ] 实现 CategoryMatcher
- [ ] 实现 VoiceSatisfactionEstimator
- [ ] 改造 VoiceInputScreen stub
- [ ] 编写单元测试和集成测试
- [ ] 配置 iOS/Android 权限

---

**创建时间:** 2026-02-22 11:27
**作者:** Claude Opus 4.6
