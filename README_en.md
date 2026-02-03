# Home Pocket (まもる家計簿)

**[中文](README.md) | [English](README_en.md) | [日本語](README_ja.md)**

> Turn money arguments into family games | 把为钱吵架变成一起玩游戏

**Privacy-first, tamper-proof, gamified family accounting app for Japanese households**
*隐私优先、防篡改、趣味化的日本家庭记账应用*

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![PRD](https://img.shields.io/badge/PRD-Complete-green)](doc/requirement/)

---

## 📖 Table of Contents

- [Product Vision](#-product-vision)
- [Core Differentiation](#-core-differentiation)
- [Target Users](#-target-users)
- [Core Features](#-core-features)
- [Technical Architecture](#️-technical-architecture)
- [Quick Start](#-quick-start)
- [Project Documentation](#-project-documentation)
- [Open Source Strategy](#-open-source-strategy)

---

## 🎯 Product Vision

To become the guardian of family financial trust and joy, transforming every accounting moment into a beautiful family interaction.


### Product Principles

| Principle | Description | Implementation |
|------|------|------|
| **Privacy First** | User data belongs only to users | E2EE, local-first, no account system |
| **Honesty & Transparency** | Family members cannot hide transactions | Blockchain-style hash chain for tamper-proofing |
| **Warmth & Fun** | Accounting should be enjoyable | Gamification |
| **Respect for Space** | Individuals need private domains | Soul accounts, mutual non-aggression treaty |
| **Open & Transparent** | Code is fully transparent and auditable | Apache 2.0 open source license |

---

## 🌟 Core Differentiation

### Market Positioning
**Home Pocket's Position:** High Privacy + Moderate Automation + Gamification

| Dimension | Competitor Status | Home Pocket Differentiation |
|------|---------|-------------------|
| **Trust** | Cloud storage, companies can access data | E2EE encryption, tamper-proof hash chain |
| **Experience** | Feature-oriented, tedious accounting | Gamification, social currency-style feedback |
| **Relationships** | Surveillance-style sharing | Privacy-respecting family collaboration |
| **Culture** | Generic design | Deep integration with Japanese culture (Kakeibo, Omikuji, Oshikatsu) |

---

## 👥 Target Users

### Primary User Persona A: Couple Users "Relationship Guardians" (Primary Target)
| Attribute | Description |
|------|------|
| **Demographics** | 25-50 years old, married or cohabiting partners |
| **Pain Points** | Financial issues easily trigger conflicts, lack financial transparency but need personal space |
| **Motivation** | Maintain relationship stability, mutual understanding, preserve private space in married life |

**Typical Scenario:**
> The Tanaka couple (35+32 years old): Married for 3 years, both with full-time jobs. They want to jointly manage household expenses but also want to keep their own "small treasury" for personal hobbies. They've had minor friction due to not understanding each other's spending habits and hope to find a balance between transparency and privacy.

### User Persona B: Single Users "Hobby Managers"
| Attribute | Description |
|------|------|
| **Demographics** | 25-45 years old, single or not yet managing finances jointly |
| **Pain Points** | Hobby spending lacks planning, prone to impulse purchases leading to end-of-month stress |
| **Motivation** | Use accounting to sustain hobbies healthily, balance survival and soul |


---

## ✨ Core Features

### 🔐 Multi-Layer Encryption Protection

**4-Layer Security Architecture:**
1. **Layer 1: Biometric Lock** - Face ID / Touch ID / Fingerprint / PIN Code
2. **Layer 2: Field Encryption** - ChaCha20-Poly1305 (AEAD) encrypts sensitive fields
3. **Layer 3: Database Encryption** - SQLCipher AES-256-CBC, 256,000 PBKDF2 iterations
4. **Layer 4: Transport Encryption** - TLS 1.3 + Ed25519 end-to-end encrypted sync

**Key Management:**
- Ed25519 device key pairs
- BIP39 24-word recovery mnemonic (Recovery Kit)
- HKDF key derivation and caching
- Optional key export and cross-device import

### 📊 Dual Ledger System

**Core Concept: Distinguishing "Survival" and "Soul"**

- **Survival Ledger** 🟢
  - Daily necessities (food, housing, transportation, healthcare)
  - Categories: Food, Housing, Transportation, Utilities, Communication, Daily Goods
  - Theme: Healing Japanese style (warm beige + green)

- **Soul Ledger** 🟣
  - Self-investment and pleasure spending (hobbies, entertainment, learning, social)
  - Categories: Hobbies, Entertainment, Learning, Social, Travel, Oshikatsu
  - Theme: Cyber-cute style (gradient purple + particle effects)
  - **Special Feature:** Soul spending celebration animations (particle burst + positive messages)

**3-Layer Intelligent Classification Engine:**
1. **Rule Engine** - Keyword matching (~70% accuracy)
2. **Merchant Database** - 500+ Japanese merchant mappings (~85% accuracy)
3. **ML Classifier** - TensorFlow Lite model (~85%+ accuracy)

### 🔄 P2P Family Sync

**Device-to-device sync without central server:**
- **Pairing Methods:** QR code face-to-face scanning (MVP) / Remote short-code pairing (V1.0)
- **Sync Protocol:** Bluetooth / NFC / Local WiFi Direct
- **Conflict Resolution:** CRDT (Yjs) automatic merge + user intervention
- **Intra-family Transfers:** 2-Phase Commit (2PC) ensures atomicity
- **Offline Support:** Offline queue, automatic sync after network recovery

### 📸 OCR Intelligent Scanning

**Local Privacy OCR (No Internet Required):**
- **Engine:** ML Kit (Android) / Vision Framework (iOS)
- **Recognition Targets:** Amount >90%, Date >85%, Merchant >80%
- **Workflow:** Image preprocessing → OCR recognition → Information extraction → Auto-classification → AES-GCM encrypted storage
- **Merchant Auto-classification:** Based on 500+ Japanese merchant database
- **User Confirmation Interface:** Editable OCR results

### 🎮 Gamification Features

**C01: Fun Converter (Ohtani Converter)**
- Convert any amount into fun units (e.g., "5% of Tokyo-Osaka Shinkansen fare", "3.5 bowls of ramen")
- OTA hot-update unit library (follow current events)
- Social sharing functionality


### ⛓️ Hash Chain Integrity Verification

**Blockchain-style Tamper-proof Protection:**
- Each transaction contains the hash of the previous transaction
- Incremental verification algorithm (100-2000x performance improvement vs. full chain verification)
- Visual audit report (displays hash chain integrity)
- PDF export audit log

### 🌐 Fully Offline Capable

- Zero dependency on cloud services
- Complete local data storage (SQLCipher encrypted database)
- P2P direct device sync (no intermediary server needed)
- All ML models localized (TensorFlow Lite)

---

## 🏗️ Technical Architecture


### Project Structure

```
lib/
├── core/                      # Core configuration
│   ├── config/               # App configuration
│   ├── constants/            # Constants definition
│   ├── router/               # GoRouter routing configuration
│   └── theme/                # Dual theme system
│
├── features/                  # Feature modules (Clean Architecture)
│   ├── accounting/           # MOD-001: Basic Accounting
│   │   ├── presentation/     # UI layer (screens, widgets, providers)
│   │   ├── application/      # Business logic layer (use cases, services)
│   │   ├── domain/           # Domain layer (models, repository interfaces)
│   │   └── data/             # Data layer (repository impl, DAOs, DTOs)
│   ├── dual_ledger/          # MOD-003: Dual Ledger
│   ├── family_sync/          # MOD-004: Family Sync
│   ├── security/             # MOD-006: Security Module
│   ├── analytics/            # MOD-007: Data Analytics
│   ├── settings/             # MOD-008: Settings Management
│   └── ocr/                  # MOD-005: OCR Scanning
│
├── shared/                    # Shared components
│   ├── widgets/              # Reusable UI components
│   ├── extensions/           # Dart extension methods
│   └── utils/                # Utility functions
│
└── l10n/                     # Internationalization (ja, zh, en)
```

### Technology Stack

| Technology | Version | Purpose |
|------|------|------|
| **Flutter** | 3.16+ | Cross-platform UI framework |
| **Dart** | 3.2+ | Programming language |
| **Riverpod** | 2.4+ | State management + dependency injection |
| **Drift** | 2.14+ | Type-safe database ORM |
| **SQLCipher** | 0.6+ | AES-256 database encryption |
| **Freezed** | 2.4+ | Immutable data models |
| **GoRouter** | 13.0+ | Declarative routing navigation |
| **Cryptography** | 2.5+ | ChaCha20-Poly1305 encryption |
| **PointyCastle** | 3.7+ | Ed25519 key pairs |
| **ML Kit** | - | OCR text recognition (Android) |
| **Vision** | - | OCR text recognition (iOS) |
| **TFLite** | 0.10+ | ML classification model |
| **Yjs** | - | CRDT sync protocol |
| **fl_chart** | 0.65+ | Data visualization charts |
| **Lottie** | 3.0+ | Animation effects |

### Performance Optimization Goals

- **Incremental Balance Updates:** 40-400x performance improvement vs. full recalculation
- **Incremental Hash Chain Verification:** 100-2000x performance improvement vs. full chain verification
- **Fast Accounting:** < 3 seconds to complete transaction entry
- **UI Smoothness:** 60 FPS scrolling
- **Pagination Loading:** 50-100 items/page

---

## 🚀 Quick Start

### Environment Requirements

- Flutter 3.16.0+
- Dart 3.2.0+
- iOS 14+ / Android 7+ (API 24+)
- Xcode 15+ (for iOS) / Android Studio (for Android)

### Installation Steps

```bash
# 1. Clone repository
git clone https://github.com/your-org/home-pocket-app.git
cd home-pocket-app

# 2. Install Flutter dependencies
flutter pub get

# 3. Code generation (Riverpod, Freezed, Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Generate localization files
flutter gen-l10n

# 5. Run application
flutter run

# (Optional) Continuous watch for code changes
flutter pub run build_runner watch
```

### Development Commands

```bash
# Code analysis
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Generate test coverage report
flutter test --coverage

# Run integration tests
flutter test integration_test/

# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

**Test Coverage Requirement:** ≥80%

### iOS Build Notes

If you encounter SQLCipher conflicts or ML Kit build errors, please refer to the iOS Build Configuration section in [CLAUDE.md](CLAUDE.md).

---

## 📖 Project Documentation

### Requirements Documentation (doc/requirement/)
- **[BRD_Home_Pocket_Complete.md](doc/requirement/BRD_Home_Pocket_Complete.md)** - Business Requirements Document
- **[PRD_Index.md](doc/requirement/PRD_Index.md)** - PRD Document System Index
- **[PRD_MVP_Global.md](doc/requirement/PRD_MVP_Global.md)** - MVP Global Product Requirements
- **[PRD_MVP_App.md](doc/requirement/PRD_MVP_App.md)** - App-side Overall PRD
- **[PRD_Module_BasicAccounting.md](doc/requirement/PRD_Module_BasicAccounting.md)** - Basic Accounting Module Detailed Design
- **[PRD_Modules_Summary.md](doc/requirement/PRD_Modules_Summary.md)** - Other Module PRD Framework

### Architecture Documentation (arch2/)
- **[ARCH-001_Complete_Guide.md](arch2/01-core-architecture/ARCH-001_Complete_Guide.md)** - Complete Technical Guide
- **[ARCH-002_Data_Architecture.md](arch2/01-core-architecture/ARCH-002_Data_Architecture.md)** - Database Design, Encryption Strategy
- **[ARCH-003_Security_Architecture.md](arch2/01-core-architecture/ARCH-003_Security_Architecture.md)** - Multi-layer Encryption, Key Management
- **[ARCH-004_State_Management.md](arch2/01-core-architecture/ARCH-004_State_Management.md)** - Riverpod Best Practices
- **[ARCH-008_Layer_Clarification.md](arch2/01-core-architecture/ARCH-008_Layer_Clarification.md)** - Clean Architecture Explained
- **[Module Specifications](arch2/02-module-specs/)** - Detailed design for each feature module (MOD-001 to MOD-009)
- **[ADR Decision Records](arch2/03-adr/)** - Architecture Decision Records

### Development Documentation
- **[PROJECT_DEVELOPMENT_PLAN.md](worklog/PROJECT_DEVELOPMENT_PLAN.md)** - Complete 12-week Development Roadmap
- **[FLUTTER_PROJECT_STRUCTURE.md](FLUTTER_PROJECT_STRUCTURE.md)** - Flutter Project Structure Explained
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute Quick Start Guide
- **[CLAUDE.md](CLAUDE.md)** - Claude Code Working Guide
---

## 🌐 Open Source Strategy

### Fully Open Source Commitment

**Home Pocket adopts a fully open source model:**

- **License:** Apache License 2.0
- **Code Repository:** Public GitHub repository
- **Core Code:** Client fully open source
- **V1.0 Server:** Relay components open source
- **Business Model:** Generate revenue through value-added services (cloud sync, LLM enhancement), not closed-source code

### Benefits of Open Source

1. **Enhanced Trust:** Auditable code builds user trust in privacy protection
2. **Community Contributions:** Attract developers to participate, accelerate feature iteration
3. **Technical Brand:** Establish technical reputation, enhance market awareness
4. **Reduce Concerns:** Eliminate user worries about data security

### Community Participation

We welcome all forms of contributions:
- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🌐 Multi-language translations
- 🔧 Code contributions
---

## 📊 Project Status

**Current Version:** v0.1.0
**Development Stage:** 🟡 Phase 1 - Infrastructure Layer in Development
**Last Updated:** 2026-02-03

### Development Progress

- [x] Project framework setup
- [x] Clean Architecture 5-layer structure
- [x] Technology stack configuration complete
- [x] Code generation configuration
- [x] Internationalization configuration
- [x] iOS/Android platform support
- [ ] MOD-006: Security Module (in progress)
- [ ] MOD-001: Basic Accounting
- [ ] MOD-003: Dual Ledger
- [ ] MOD-004: Family Sync
---

## 📜 License

This project is licensed under the **Apache License 2.0**.

For details, please see the [LICENSE](LICENSE) file.

```
Copyright 2026 Home Pocket Team

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

## 📞 Contact

- **Project Repository:** [GitHub](https://github.com/your-org/home-pocket-app)
- **Issue Feedback:** [Issues](https://github.com/your-org/home-pocket-app/issues)
- **Discussion Community:** [Discussions](https://github.com/your-org/home-pocket-app/discussions)
- **Documentation Feedback:** Welcome to submit PRs to improve documentation

---

## 🙏 Acknowledgments

Special thanks to the following open source projects:

- [Flutter](https://flutter.dev/) - Google's cross-platform UI framework
- [Riverpod](https://riverpod.dev/) - Remi Rousselet's state management solution
- [Drift](https://drift.simonbinder.eu/) - Simon Binder's type-safe database
- [SQLCipher](https://www.zetetic.net/sqlcipher/) - Zetetic's database encryption
- [Yjs](https://yjs.dev/) - Kevin Jahns' CRDT library
- All contributors and supporters ❤️

---

**Make accounting fun, make families warmer!** 🏠💰✨

**让记账变得有趣,让家庭更加温暖!** 🏠💰✨

---

**Updated:** 2026-02-03
**Document Version:** 2.0
