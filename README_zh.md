# Happy Pocket (ハピポケ家族家計簿)

**[English](README.md) | [中文](README_zh.md) | [日本語](README_ja.md)**

> 把为钱吵架变成一起玩游戏 | Turn money arguments into family games

**隐私优先、防篡改、趣味化的日本家庭记账应用**
*Privacy-first, tamper-proof, gamified family accounting app for Japanese households*

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![PRD](https://img.shields.io/badge/PRD-Complete-green)](doc/requirement/)

---

## 📖 目录 | Table of Contents

- [产品愿景](#-产品愿景)
- [核心差异化](#-核心差异化)
- [目标用户](#-目标用户)
- [核心特性](#-核心特性)
- [技术架构](#️-技术架构)
- [快速开始](#-快速开始)
- [项目文档](#-项目文档)
- [开源策略](#-开源策略)

---

## 🎯 产品愿景

成为家庭财务信任与欢乐的守护者，让每一次记账都成为家庭互动的美好瞬间。


### 产品原则

| 原则 | 说明 | 体现 |
|------|------|------|
| **隐私至上** | 用户数据只属于用户 | E2EE、本地优先、无账号体系 |
| **诚实透明** | 家庭成员间无法隐藏交易 | 区块链风格哈希链防篡改 |
| **温暖有趣** | 记账是快乐的事 | 游戏化 |
| **尊重空间** | 个人需要私密领域 | 灵魂账户、互不侵犯条约 |
| **开源开放** | 代码完全透明可审计 | Apache 2.0开源许可 |

---

## 🌟 核心差异化

### 市场定位
**Happy Pocket 的位置：** 高隐私 + 适度自动化 + 趣味化

| 维度 | 竞品现状 | Happy Pocket 差异化 |
|------|---------|-------------------|
| **信任** | 云端存储，公司可见数据 | E2EE加密，防篡改哈希链 |
| **体验** | 功能导向，枯燥记账 | 游戏化，社交货币式反馈 |
| **关系** | 监控式共享 | 尊重隐私的家庭协作 |
| **文化** | 通用设计 | 深度融入日本文化（Kakeibo、Omikuji、推し活） |

---

## 👥 目标用户

### 主要用户画像 A：夫妻用户 "关系守护者" (Primary Target)
| 属性 | 描述 |
|------|------|
| **人口统计** | 25-50岁，已婚或同居伴侣 |
| **痛点** | 经济问题易引发矛盾，缺乏财务透明但又需要个人空间 |
| **动机** | 维持关系稳定，相互理解，在夫妻生活中保持私人空间 |

**典型场景：**
> 田中夫妇（35岁+32岁）：结婚3年，都有全职工作。两人希望共同管理家庭开支，但也想保留各自的"小金库"用于个人爱好。曾因为不了解对方的消费习惯产生过小摩擦，希望找到透明与隐私的平衡。

### 用户画像 B：单人用户 "爱好经营者"
| 属性 | 描述 |
|------|------|
| **人口统计** | 25-45岁，单身或暂未共同理财 |
| **痛点** | 爱好消费缺乏规划，容易冲动消费导致月底紧张 |
| **动机** | 通过记账让自己的爱好持续健康发展，平衡生存与灵魂 |


---

## ✨ 核心特性

### 🔐 多层加密防护

**4层安全架构:**
1. **Layer 1: 生物识别锁** - Face ID / Touch ID / 指纹 / PIN码
2. **Layer 2: 字段加密** - ChaCha20-Poly1305 (AEAD) 加密敏感字段
3. **Layer 3: 数据库加密** - SQLCipher AES-256-CBC，256,000次PBKDF2
4. **Layer 4: 传输加密** - TLS 1.3 + Ed25519端到端加密同步

**密钥管理:**
- Ed25519 设备密钥对
- BIP39 24词恢复助记词（Recovery Kit）
- HKDF 密钥派生与缓存
- 可选的密钥导出与跨设备导入

### 📊 双轨账本系统

**核心概念：区分"生存"与"灵魂"**

- **生存账本 (Survival Ledger)** 🟢
  - 日常必需开支（食物、住房、交通、医疗）
  - 分类：食品、住房、交通、水电、通讯、日用品
  - 主题：和风治愈风格（温暖米色+绿色）

- **灵魂账本 (Soul Ledger)** 🟣
  - 自我投资与享乐消费（兴趣、娱乐、学习、社交）
  - 分类：兴趣爱好、娱乐、学习、社交、旅行、推し活
  - 主题：赛博可爱风格（渐变紫+粒子特效）
  - **特殊功能：** 灵魂消费庆祝动画（粒子爆发+正向文案）

**3层智能分类引擎:**
1. **规则引擎** - 关键词匹配（准确率 ~70%）
2. **商户数据库** - 500+ 日本商户映射（准确率 ~85%）
3. **ML分类器** - TensorFlow Lite模型（准确率 ~85%+）

### 🔄 P2P家庭同步

**无需中心服务器的设备间同步:**
- **配对方式：** QR码面对面扫描（MVP）/ 远程短码配对（V1.0）
- **同步协议：** 蓝牙 / NFC / 本地WiFi Direct
- **冲突解决：** CRDT (Yjs) 自动合并 + 用户干预
- **家庭内部转账：** 2阶段提交（2PC）确保原子性
- **离线支持：** 离线队列，网络恢复后自动同步

### 📸 OCR智能扫描

**本地隐私OCR（无需联网）:**
- **引擎：** ML Kit (Android) / Vision Framework (iOS)
- **识别目标：** 金额 >90%、日期 >85%、商户 >80%
- **流程：** 图像预处理 → OCR识别 → 信息提取 → 自动分类 → AES-GCM加密存储
- **商户自动分类：** 基于500+日本商户数据库
- **用户确认界面：** 可编辑的OCR结果

### 🎮 趣味化功能 (Gamification)

**C01: 趣味换算器 (Ohtani Converter)**
- 将任意金额转换为趣味单位（如"东京到大阪 5%新干线费用"、"3.5份拉面"）
- OTA热更新单位库（紧跟时事热点）
- 社交分享功能


### ⛓️ 哈希链完整性验证

**区块链风格防篡改保护:**
- 每笔交易包含前一笔交易的哈希值
- 增量验证算法（100-2000x性能提升 vs 全链验证）
- 可视化审计报告（显示哈希链完整性）
- PDF导出审计日志

### 🌐 完全离线可用

- 零依赖云服务
- 完整的本地数据存储（SQLCipher加密数据库）
- P2P设备间直接同步（无需中间服务器）
- 所有ML模型本地化（TensorFlow Lite）

---

## 🏗️ 技术架构


### 项目结构

```
lib/
├── core/                      # 核心配置
│   ├── config/               # 应用配置
│   ├── constants/            # 常量定义
│   ├── router/               # GoRouter路由配置
│   └── theme/                # 双主题系统
│
├── features/                  # 功能模块 (Clean Architecture)
│   ├── accounting/           # MOD-001: 基础记账
│   │   ├── presentation/     # UI层 (screens, widgets, providers)
│   │   ├── application/      # 业务逻辑层 (use cases, services)
│   │   ├── domain/           # 领域层 (models, repository interfaces)
│   │   └── data/             # 数据层 (repository impl, DAOs, DTOs)
│   ├── dual_ledger/          # MOD-003: 双轨账本
│   ├── family_sync/          # MOD-004: 家庭同步
│   ├── security/             # MOD-006: 安全模块
│   ├── analytics/            # MOD-007: 数据分析
│   ├── settings/             # MOD-008: 设置管理
│   └── ocr/                  # MOD-005: OCR扫描
│
├── shared/                    # 共享组件
│   ├── widgets/              # 可复用UI组件
│   ├── extensions/           # Dart扩展方法
│   └── utils/                # 工具函数
│
└── l10n/                     # 国际化 (ja, zh, en)
```

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **Flutter** | 3.16+ | 跨平台UI框架 |
| **Dart** | 3.2+ | 编程语言 |
| **Riverpod** | 2.4+ | 状态管理 + 依赖注入 |
| **Drift** | 2.14+ | 类型安全的数据库ORM |
| **SQLCipher** | 0.6+ | AES-256数据库加密 |
| **Freezed** | 2.4+ | 不可变数据模型 |
| **GoRouter** | 13.0+ | 声明式路由导航 |
| **Cryptography** | 2.5+ | ChaCha20-Poly1305加密 |
| **PointyCastle** | 3.7+ | Ed25519密钥对 |
| **ML Kit** | - | OCR文本识别 (Android) |
| **Vision** | - | OCR文本识别 (iOS) |
| **TFLite** | 0.10+ | ML分类模型 |
| **Yjs** | - | CRDT同步协议 |
| **fl_chart** | 0.65+ | 数据可视化图表 |
| **Lottie** | 3.0+ | 动画效果 |

### 性能优化目标

- **增量余额更新:** 40-400x 性能提升 vs 全量重算
- **增量哈希链验证:** 100-2000x 性能提升 vs 全链验证
- **快速记账:** < 3秒完成交易录入
- **UI流畅度:** 60 FPS 滚动
- **分页加载:** 50-100 项/页

---

## 🚀 快速开始

### 环境要求

- Flutter 3.16.0+
- Dart 3.2.0+
- iOS 15+ / Android 7+ (API 24+)
- Xcode 15+ (for iOS) / Android Studio (for Android)

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/your-org/home-pocket-app.git
cd home-pocket-app

# 2. 安装Flutter依赖
flutter pub get

# 3. 代码生成 (Riverpod, Freezed, Drift)
flutter pub run build_runner build

# 4. 生成多语言文件
flutter gen-l10n

# 5. 运行应用
flutter run

# (可选) 持续监听代码变化
flutter pub run build_runner watch
```

### 开发命令

```bash
# 代码分析
flutter analyze

# 格式化代码
dart format .

# 运行所有测试
flutter test

# 生成测试覆盖率报告
flutter test --coverage

# 运行集成测试
flutter test integration_test/

# 列出可用设备
flutter devices

# 在特定设备运行
flutter run -d <device_id>
```

**测试覆盖率要求:** ≥80%

### iOS构建注意事项

如遇到SQLCipher冲突或ML Kit构建错误，请查看 [CLAUDE.md](CLAUDE.md) 的 iOS Build Configuration 章节。

---

## 📖 项目文档

### 需求文档 (doc/requirement/)
- **[BRD_Home_Pocket_Complete.md](doc/requirement/BRD_Home_Pocket_Complete.md)** - 商业需求文档
- **[PRD_Index.md](doc/requirement/PRD_Index.md)** - PRD文档体系索引
- **[PRD_MVP_Global.md](doc/requirement/PRD_MVP_Global.md)** - MVP全局产品需求
- **[PRD_MVP_App.md](doc/requirement/PRD_MVP_App.md)** - App端总体PRD
- **[PRD_Module_BasicAccounting.md](doc/requirement/PRD_Module_BasicAccounting.md)** - 基础记账模块详细设计
- **[PRD_Modules_Summary.md](doc/requirement/PRD_Modules_Summary.md)** - 其他模块PRD框架

### 架构文档 (arch2/)
- **[ARCH-001_Complete_Guide.md](arch2/01-core-architecture/ARCH-001_Complete_Guide.md)** - 完整技术指南
- **[ARCH-002_Data_Architecture.md](arch2/01-core-architecture/ARCH-002_Data_Architecture.md)** - 数据库设计、加密策略
- **[ARCH-003_Security_Architecture.md](arch2/01-core-architecture/ARCH-003_Security_Architecture.md)** - 多层加密、密钥管理
- **[ARCH-004_State_Management.md](arch2/01-core-architecture/ARCH-004_State_Management.md)** - Riverpod最佳实践
- **[ARCH-008_Layer_Clarification.md](arch2/01-core-architecture/ARCH-008_Layer_Clarification.md)** - Clean Architecture详解
- **[模块规范](arch2/02-module-specs/)** - 各功能模块详细设计 (MOD-001 到 MOD-009)
- **[ADR决策记录](arch2/03-adr/)** - 架构决策文档

### 开发文档
- **[PROJECT_DEVELOPMENT_PLAN.md](worklog/PROJECT_DEVELOPMENT_PLAN.md)** - 完整12周开发路线图
- **[FLUTTER_PROJECT_STRUCTURE.md](FLUTTER_PROJECT_STRUCTURE.md)** - Flutter项目结构详解
- **[QUICKSTART.md](QUICKSTART.md)** - 5分钟快速开始指南
- **[CLAUDE.md](CLAUDE.md)** - Claude Code工作指南
---

## 🌐 开源策略

### 完全开源承诺

**Happy Pocket 采用完全开源模式：**

- **许可证：** Apache License 2.0
- **代码仓库：** GitHub公开仓库
- **核心代码：** 客户端完全开源
- **V1.0 Server：** Relay组件开源
- **商业模式：** 通过增值服务（云同步、LLM增强）获取收入，而非代码闭源

### 开源的好处

1. **增强信任：** 代码可审计，用户对隐私保护的信任
2. **社区贡献：** 吸引开发者参与，加速功能迭代
3. **技术品牌：** 建立技术口碑，提升市场认知
4. **降低顾虑：** 消除用户对数据安全的担忧

### 社区参与

我们欢迎所有形式的贡献：
- 🐛 Bug报告
- 💡 功能建议
- 📝 文档改进
- 🌐 多语言翻译
- 🔧 代码贡献
---

## 📊 项目状态

**当前版本：** v0.1.0
**开发阶段：** 🟡 Phase 1 - 基础设施层开发中
**最后更新：** 2026-02-03

### 开发进度

- [x] 项目框架搭建
- [x] Clean Architecture 5层结构
- [x] 技术栈配置完成
- [x] 代码生成配置
- [x] 国际化配置
- [x] iOS/Android平台支持
- [ ] MOD-006: 安全模块（进行中）
- [ ] MOD-001: 基础记账
- [ ] MOD-003: 双轨账本
- [ ] MOD-004: 家庭同步
---

## 📜 许可证

本项目采用 **Apache License 2.0** 开源许可证。

详情请查看 [LICENSE](LICENSE) 文件。

```
Copyright 2026 Happy Pocket Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 📞 联系方式

- **项目仓库：** [GitHub](https://github.com/your-org/home-pocket-app)
- **问题反馈：** [Issues](https://github.com/your-org/home-pocket-app/issues)
- **讨论社区：** [Discussions](https://github.com/your-org/home-pocket-app/discussions)
- **文档反馈：** 欢迎提交PR改进文档

---

## 🙏 致谢

特别感谢以下开源项目：

- [Flutter](https://flutter.dev/) - Google的跨平台UI框架
- [Riverpod](https://riverpod.dev/) - Remi Rousselet的状态管理方案
- [Drift](https://drift.simonbinder.eu/) - Simon Binder的类型安全数据库
- [SQLCipher](https://www.zetetic.net/sqlcipher/) - Zetetic的数据库加密
- [Yjs](https://yjs.dev/) - Kevin Jahns的CRDT库
- 所有贡献者和支持者 ❤️

---

**让记账变得有趣，让家庭更加温暖！** 🏠💰✨

**Make accounting fun, make families warmer!** 🏠💰✨

---

**更新日期：** 2026-02-03
**文档版本：** 2.0
