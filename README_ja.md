# Home Pocket (まもる家計簿)

**[English](README.md) | [中文](README_zh.md) | [日本語](README_ja.md)**

> お金の喧嘩を家族のゲームに変える | Turn money arguments into family games

**プライバシー優先、改ざん防止、ゲーミフィケーション搭載の日本の家庭向け家計簿アプリケーション**
*Privacy-first, tamper-proof, gamified family accounting app for Japanese households*

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![PRD](https://img.shields.io/badge/PRD-Complete-green)](doc/requirement/)

---

## 📖 目次 | Table of Contents

- [プロダクトビジョン](#-プロダクトビジョン)
- [コア差別化要素](#-コア差別化要素)
- [ターゲットユーザー](#-ターゲットユーザー)
- [主要機能](#-主要機能)
- [技術アーキテクチャ](#️-技術アーキテクチャ)
- [クイックスタート](#-クイックスタート)
- [プロジェクトドキュメント](#-プロジェクトドキュメント)
- [オープンソース戦略](#-オープンソース戦略)

---

## 🎯 プロダクトビジョン

家庭の財務における信頼と喜びの守護者となり、毎回の記帳を家族の絆を深める素晴らしい瞬間に変えます。


### プロダクト原則

| 原則 | 説明 | 実現方法 |
|------|------|------|
| **プライバシー最優先** | ユーザーデータはユーザーのみに属します | E2EE、ローカル優先、アカウント不要 |
| **誠実・透明性** | 家族間で取引を隠すことはできません | ブロックチェーン式ハッシュチェーンによる改ざん防止 |
| **温かく楽しく** | 記帳は楽しいものです | ゲーミフィケーション |
| **個人空間の尊重** | 個人にはプライベート領域が必要です | ソウルアカウント、相互不可侵条約 |
| **オープンソース** | コードは完全に透明で監査可能です | Apache 2.0オープンソースライセンス |

---

## 🌟 コア差別化要素

### 市場ポジショニング
**Home Pocketの位置付け：** 高プライバシー + 適度な自動化 + ゲーミフィケーション

| 項目 | 競合製品の現状 | Home Pocketの差別化 |
|------|---------|-------------------|
| **信頼** | クラウドストレージ、企業がデータを閲覧可能 | E2EE暗号化、改ざん防止ハッシュチェーン |
| **体験** | 機能重視、退屈な記帳作業 | ゲーミフィケーション、ソーシャルカレンシー式フィードバック |
| **関係性** | 監視型の共有 | プライバシーを尊重した家族協働 |
| **文化** | 汎用的デザイン | 日本文化に深く根ざした設計（家計簿、おみくじ、推し活） |

---

## 👥 ターゲットユーザー

### 主要ユーザーペルソナA：夫婦ユーザー「関係の守護者」（プライマリーターゲット）
| 属性 | 説明 |
|------|------|
| **デモグラフィック** | 25-50歳、既婚または同棲中のカップル |
| **ペインポイント** | 経済的な問題が衝突の原因になりやすい、財務の透明性が不足しているが個人のスペースも必要 |
| **モチベーション** | 関係の安定を維持、相互理解、夫婦生活において個人空間を保持 |

**典型的なシナリオ：**
> 田中夫妻（35歳+32歳）：結婚3年目、共働き。二人は家計を共同管理したいと考えているが、それぞれの趣味のための「へそくり」も確保したい。お互いの消費習慣を理解していないことで小さな衝突が生じたことがあり、透明性とプライバシーのバランスを求めている。

### ユーザーペルソナB：単身ユーザー「趣味経営者」
| 属性 | 説明 |
|------|------|
| **デモグラフィック** | 25-45歳、独身または共同での財務管理を行っていない |
| **ペインポイント** | 趣味への支出が計画的でなく、衝動買いで月末に困窮しがち |
| **モチベーション** | 記帳を通じて趣味を持続可能に発展させ、生存と心の豊かさのバランスを取る |


---

## ✨ 主要機能

### 🔐 多層暗号化保護

**4層セキュリティアーキテクチャ:**
1. **Layer 1: 生体認証ロック** - Face ID / Touch ID / 指紋認証 / PIN
2. **Layer 2: フィールド暗号化** - ChaCha20-Poly1305 (AEAD) による機密フィールド暗号化
3. **Layer 3: データベース暗号化** - SQLCipher AES-256-CBC、256,000回のPBKDF2
4. **Layer 4: 通信暗号化** - TLS 1.3 + Ed25519エンドツーエンド暗号化同期

**鍵管理:**
- Ed25519 デバイス鍵ペア
- BIP39 24単語リカバリーシードフレーズ（Recovery Kit）
- HKDF 鍵派生とキャッシング
- オプションの鍵エクスポートとデバイス間インポート

### 📊 デュアルレジャーシステム

**コアコンセプト：「生存」と「魂」の区別**

- **生存レジャー (Survival Ledger)** 🟢
  - 日常的な必需品支出（食費、住居費、交通費、医療費）
  - カテゴリ：食品、住居、交通、水道光熱費、通信、日用品
  - テーマ：和風癒し系スタイル（温かみのあるベージュ+グリーン）

- **魂レジャー (Soul Ledger)** 🟣
  - 自己投資と楽しみの消費（趣味、娯楽、学習、社交）
  - カテゴリ：趣味、娯楽、学習、社交、旅行、推し活
  - テーマ：サイバーキュートスタイル（グラデーション紫+パーティクルエフェクト）
  - **特別機能：** 魂消費お祝いアニメーション（パーティクルバースト+ポジティブメッセージ）

**3層インテリジェント分類エンジン:**
1. **ルールエンジン** - キーワードマッチング（精度 ~70%）
2. **マーチャントデータベース** - 日本国内の500+加盟店マッピング（精度 ~85%）
3. **ML分類器** - TensorFlow Liteモデル（精度 ~85%+）

### 🔄 P2P家族同期

**中央サーバー不要のデバイス間同期:**
- **ペアリング方法：** 対面QRコードスキャン（MVP）/ リモート短縮コードペアリング（V1.0）
- **同期プロトコル：** Bluetooth / NFC / ローカルWiFi Direct
- **競合解決：** CRDT (Yjs) による自動マージ + ユーザー介入
- **家族内転送：** 2フェーズコミット（2PC）によるアトミック性保証
- **オフライン対応：** オフラインキュー、ネットワーク回復後の自動同期

### 📸 OCRスマートスキャン

**ローカルプライバシーOCR（インターネット接続不要）:**
- **エンジン：** ML Kit (Android) / Vision Framework (iOS)
- **認識対象：** 金額 >90%、日付 >85%、加盟店名 >80%
- **フロー：** 画像前処理 → OCR認識 → 情報抽出 → 自動分類 → AES-GCM暗号化ストレージ
- **加盟店自動分類：** 日本国内500+加盟店データベースに基づく
- **ユーザー確認インターフェース：** 編集可能なOCR結果

### 🎮 ゲーミフィケーション機能

**C01: 楽しい換算ツール (Ohtani Converter)**
- 任意の金額を楽しい単位に変換（例：「東京-大阪間の新幹線代の5%」「ラーメン3.5杯分」）
- OTAホットアップデートによる単位ライブラリ（時事トレンドに追随）
- ソーシャルシェア機能


### ⛓️ ハッシュチェーン完全性検証

**ブロックチェーン式改ざん防止保護:**
- 各取引に前の取引のハッシュ値を含める
- 増分検証アルゴリズム（フルチェーン検証と比較して100-2000倍のパフォーマンス向上）
- 視覚化された監査レポート（ハッシュチェーンの完全性表示）
- PDF形式の監査ログエクスポート

### 🌐 完全オフライン対応

- クラウドサービスへの依存ゼロ
- 完全なローカルデータストレージ（SQLCipher暗号化データベース）
- P2Pデバイス間直接同期（中間サーバー不要）
- すべてのMLモデルのローカル化（TensorFlow Lite）

---

## 🏗️ 技術アーキテクチャ


### プロジェクト構造

```
lib/
├── core/                      # コア設定
│   ├── config/               # アプリケーション設定
│   ├── constants/            # 定数定義
│   ├── router/               # GoRouterルーティング設定
│   └── theme/                # デュアルテーマシステム
│
├── features/                  # 機能モジュール (Clean Architecture)
│   ├── accounting/           # MOD-001: 基本記帳
│   │   ├── presentation/     # UIレイヤー (screens, widgets, providers)
│   │   ├── application/      # ビジネスロジックレイヤー (use cases, services)
│   │   ├── domain/           # ドメインレイヤー (models, repository interfaces)
│   │   └── data/             # データレイヤー (repository impl, DAOs, DTOs)
│   ├── dual_ledger/          # MOD-003: デュアルレジャー
│   ├── family_sync/          # MOD-004: 家族同期
│   ├── security/             # MOD-006: セキュリティモジュール
│   ├── analytics/            # MOD-007: データ分析
│   ├── settings/             # MOD-008: 設定管理
│   └── ocr/                  # MOD-005: OCRスキャン
│
├── shared/                    # 共有コンポーネント
│   ├── widgets/              # 再利用可能なUIコンポーネント
│   ├── extensions/           # Dart拡張メソッド
│   └── utils/                # ユーティリティ関数
│
└── l10n/                     # 国際化 (ja, zh, en)
```

### 技術スタック

| 技術 | バージョン | 用途 |
|------|------|------|
| **Flutter** | 3.16+ | クロスプラットフォームUIフレームワーク |
| **Dart** | 3.2+ | プログラミング言語 |
| **Riverpod** | 2.4+ | 状態管理 + 依存性注入 |
| **Drift** | 2.14+ | 型安全なデータベースORM |
| **SQLCipher** | 0.6+ | AES-256データベース暗号化 |
| **Freezed** | 2.4+ | イミュータブルデータモデル |
| **GoRouter** | 13.0+ | 宣言的ルーティングナビゲーション |
| **Cryptography** | 2.5+ | ChaCha20-Poly1305暗号化 |
| **PointyCastle** | 3.7+ | Ed25519鍵ペア |
| **ML Kit** | - | OCRテキスト認識 (Android) |
| **Vision** | - | OCRテキスト認識 (iOS) |
| **TFLite** | 0.10+ | ML分類モデル |
| **Yjs** | - | CRDT同期プロトコル |
| **fl_chart** | 0.65+ | データ可視化チャート |
| **Lottie** | 3.0+ | アニメーションエフェクト |

### パフォーマンス最適化目標

- **増分残高更新:** 全量再計算と比較して40-400倍のパフォーマンス向上
- **増分ハッシュチェーン検証:** フルチェーン検証と比較して100-2000倍のパフォーマンス向上
- **高速記帳:** 取引入力完了まで3秒未満
- **UI流動性:** 60 FPSスクロール
- **ページネーション:** 50-100項目/ページ

---

## 🚀 クイックスタート

### 環境要件

- Flutter 3.16.0+
- Dart 3.2.0+
- iOS 14+ / Android 7+ (API 24+)
- Xcode 15+ (iOS向け) / Android Studio (Android向け)

### インストール手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/your-org/home-pocket-app.git
cd home-pocket-app

# 2. Flutter依存関係をインストール
flutter pub get

# 3. コード生成 (Riverpod, Freezed, Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 多言語ファイルを生成
flutter gen-l10n

# 5. アプリケーションを実行
flutter run

# (オプション) コード変更の継続的な監視
flutter pub run build_runner watch
```

### 開発コマンド

```bash
# コード解析
flutter analyze

# コードフォーマット
dart format .

# すべてのテストを実行
flutter test

# テストカバレッジレポートを生成
flutter test --coverage

# 統合テストを実行
flutter test integration_test/

# 利用可能なデバイスをリスト表示
flutter devices

# 特定のデバイスで実行
flutter run -d <device_id>
```

**テストカバレッジ要件:** ≥80%

### iOSビルドに関する注意事項

SQLCipherの競合やML Kitのビルドエラーが発生した場合は、[CLAUDE.md](CLAUDE.md)のiOS Build Configurationセクションをご参照ください。

---

## 📖 プロジェクトドキュメント

### 要件ドキュメント (doc/requirement/)
- **[BRD_Home_Pocket_Complete.md](doc/requirement/BRD_Home_Pocket_Complete.md)** - ビジネス要件ドキュメント
- **[PRD_Index.md](doc/requirement/PRD_Index.md)** - PRDドキュメント体系インデックス
- **[PRD_MVP_Global.md](doc/requirement/PRD_MVP_Global.md)** - MVPグローバル製品要件
- **[PRD_MVP_App.md](doc/requirement/PRD_MVP_App.md)** - アプリ側総合PRD
- **[PRD_Module_BasicAccounting.md](doc/requirement/PRD_Module_BasicAccounting.md)** - 基本記帳モジュール詳細設計
- **[PRD_Modules_Summary.md](doc/requirement/PRD_Modules_Summary.md)** - その他モジュールPRDフレームワーク

### アーキテクチャドキュメント (arch2/)
- **[ARCH-001_Complete_Guide.md](arch2/01-core-architecture/ARCH-001_Complete_Guide.md)** - 完全技術ガイド
- **[ARCH-002_Data_Architecture.md](arch2/01-core-architecture/ARCH-002_Data_Architecture.md)** - データベース設計、暗号化戦略
- **[ARCH-003_Security_Architecture.md](arch2/01-core-architecture/ARCH-003_Security_Architecture.md)** - 多層暗号化、鍵管理
- **[ARCH-004_State_Management.md](arch2/01-core-architecture/ARCH-004_State_Management.md)** - Riverpodベストプラクティス
- **[ARCH-008_Layer_Clarification.md](arch2/01-core-architecture/ARCH-008_Layer_Clarification.md)** - Clean Architecture詳解
- **[モジュール仕様](arch2/02-module-specs/)** - 各機能モジュール詳細設計 (MOD-001からMOD-009)
- **[ADR決定記録](arch2/03-adr/)** - アーキテクチャ決定ドキュメント

### 開発ドキュメント
- **[PROJECT_DEVELOPMENT_PLAN.md](worklog/PROJECT_DEVELOPMENT_PLAN.md)** - 完全12週間開発ロードマップ
- **[FLUTTER_PROJECT_STRUCTURE.md](FLUTTER_PROJECT_STRUCTURE.md)** - Flutterプロジェクト構造詳解
- **[QUICKSTART.md](QUICKSTART.md)** - 5分間クイックスタートガイド
- **[CLAUDE.md](CLAUDE.md)** - Claude Code作業ガイド
---

## 🌐 オープンソース戦略

### 完全オープンソースコミットメント

**Home Pocketは完全オープンソースモデルを採用しています：**

- **ライセンス：** Apache License 2.0
- **コードリポジトリ：** GitHub公開リポジトリ
- **コアコード：** クライアント完全オープンソース
- **V1.0 Server：** Relayコンポーネントオープンソース
- **ビジネスモデル：** 付加価値サービス（クラウド同期、LLM拡張機能）による収益、コードのクローズドソース化ではない

### オープンソースのメリット

1. **信頼性の向上：** コードの監査可能性により、プライバシー保護に対するユーザーの信頼を獲得
2. **コミュニティ貢献：** 開発者の参加を促進し、機能イテレーションを加速
3. **技術ブランディング：** 技術的評判を確立し、市場認知度を向上
4. **懸念の軽減：** データセキュリティに対するユーザーの不安を解消

### コミュニティ参加

あらゆる形式の貢献を歓迎します：
- 🐛 バグレポート
- 💡 機能提案
- 📝 ドキュメント改善
- 🌐 多言語翻訳
- 🔧 コード貢献
---

## 📊 プロジェクトステータス

**現在のバージョン：** v0.1.0
**開発フェーズ：** 🟡 Phase 1 - インフラストラクチャレイヤー開発中
**最終更新：** 2026-02-03

### 開発進捗

- [x] プロジェクトフレームワーク構築
- [x] Clean Architecture 5層構造
- [x] 技術スタック設定完了
- [x] コード生成設定
- [x] 国際化設定
- [x] iOS/Androidプラットフォーム対応
- [ ] MOD-006: セキュリティモジュール（進行中）
- [ ] MOD-001: 基本記帳
- [ ] MOD-003: デュアルレジャー
- [ ] MOD-004: 家族同期
---

## 📜 ライセンス

本プロジェクトは **Apache License 2.0** オープンソースライセンスを採用しています。

詳細は[LICENSE](LICENSE)ファイルをご参照ください。

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

## 📞 お問い合わせ

- **プロジェクトリポジトリ：** [GitHub](https://github.com/your-org/home-pocket-app)
- **問題報告：** [Issues](https://github.com/your-org/home-pocket-app/issues)
- **ディスカッションコミュニティ：** [Discussions](https://github.com/your-org/home-pocket-app/discussions)
- **ドキュメントフィードバック：** PRによるドキュメント改善を歓迎します

---

## 🙏 謝辞

以下のオープンソースプロジェクトに特別な感謝を申し上げます：

- [Flutter](https://flutter.dev/) - Googleのクロスプラットフォーム UIフレームワーク
- [Riverpod](https://riverpod.dev/) - Remi Rousseletの状態管理ソリューション
- [Drift](https://drift.simonbinder.eu/) - Simon Binderの型安全データベース
- [SQLCipher](https://www.zetetic.net/sqlcipher/) - Zeteticのデータベース暗号化
- [Yjs](https://yjs.dev/) - Kevin JahnsのCRDTライブラリ
- すべての貢献者とサポーター ❤️

---

**家計簿を楽しく、家族をもっと温かく！** 🏠💰✨

**Make accounting fun, make families warmer!** 🏠💰✨

---

**更新日：** 2026-02-03
**ドキュメントバージョン：** 2.0
