# MOD-009 Voice Input Module Implementation

**日付:** 2026-02-22
**時間:** 13:18
**タスクタイプ:** 機能開発
**ステータス:** 完了
**関連モジュール:** [MOD-009] Voice Input

---

## タスク概要

Home Pocket アプリに音声入力トランザクション機能を実装した。ユーザーが音声で金額・商店・カテゴリを認識させ、
Soul Ledger の場合は音声の特徴量から満足度スコアを自動推定する。TDD (RED → GREEN → REFACTOR) 手法で
全フェーズを完了し、41件のテスト全通過・`flutter analyze` ゼロ警告を達成した。

---

## 完了した作業

### Phase 0: セットアップ

- `pubspec.yaml` に `speech_to_text: ^7.0.0` を追加（実際にインストールされたバージョン: 7.3.0）
- `ios/Runner/Info.plist` に `NSSpeechRecognitionUsageDescription` / `NSMicrophoneUsageDescription` を追加
- `android/app/src/main/AndroidManifest.xml` に `RECORD_AUDIO` パーミッション + `queries` ブロックの RecognitionService intent を追加
- `lib/infrastructure/speech/` ディレクトリを作成
- `lib/application/voice/` ディレクトリを作成

### Phase 1: テストファイル作成 (RED フェーズ)

以下の 6 件のテストファイルを作成（実装前の RED 状態）:

- `test/unit/application/voice/voice_text_parser_test.dart` — 金額抽出（アラビア数字・漢数字）テスト
- `test/unit/application/voice/category_matcher_test.dart` — キーワードマッチング多言語テスト
- `test/unit/application/voice/voice_satisfaction_estimator_test.dart` — 満足度スコア推定テスト
- `test/unit/application/voice/parse_voice_input_use_case_test.dart` — ユースケース統合テスト
- `test/unit/infrastructure/speech/speech_recognition_service_test.dart` — 音量正規化テスト
- `test/unit/features/accounting/domain/models/voice_parse_result_test.dart` — ドメインモデルテスト

### Phase 2: ドメインモデル作成

`lib/features/accounting/domain/models/voice_parse_result.dart`
- `VoiceParseResult` (Freezed): rawText, amount, merchantName, merchantCategoryId, merchantLedgerType, categoryMatch, ledgerType, estimatedSatisfaction
- `CategoryMatchResult` (Freezed): categoryId, confidence, source
- `VoiceAudioFeatures` (Freezed): soundLevels, timestamps, startTime, endTime, partialResultCount, wordCount
- `MatchSource` enum: keyword, merchant, ml

**アーキテクチャ上の重要決定:** `VoiceParseResult` に `MerchantMatch` 型への参照を持たせず、merchantName/categoryId/ledgerType の plain primitive フィールドのみを保持。Infrastructure 型がドメイン層に漏れる依存方向違反を防止。

### Phase 3: インフラストラクチャ層

**`lib/infrastructure/ml/merchant_database.dart`** (新規)
- `MerchantMatch` クラスを Infrastructure 層に定義（ドメイン層からの分離）
- `MerchantDatabase` クラスに ~12 件の日本語商店シードデータ（ユニクロ、マクドナルド、スタバ等）
- 完全一致 → エイリアス一致 → 部分一致の順でマッチング

**`lib/infrastructure/speech/speech_recognition_service.dart`** (新規)
- `speech_to_text` プラグインをラップ
- Android (RMS 0~10) / iOS (dB -50~0) 音量正規化を実装
- `@visibleForTesting normalizeSoundLevelForTest()` でテスト時の Platform 依存を回避
- 非推奨 API 修正: `partialResults` / `cancelOnError` を `SpeechListenOptions` 内のみに配置

### Phase 4: アプリケーション層

**`lib/application/voice/voice_text_parser.dart`** (新規)
- アラビア数字（1,280円、¥680、3980等）と漢数字（六百八十円、千二百元等）の金額抽出
- 潜在的商店名候補の抽出（カタカナ・アルファベットのまとまり）

**`lib/application/voice/category_matcher.dart`** (新規)
- 100+ 多言語キーワード → カテゴリ ID マッピング（日本語・中国語・英語）
- `CategoryRepository.findById()` でサブカテゴリの存在確認
- `CategoryService.resolveLedgerType()` への委譲

**`lib/application/voice/voice_satisfaction_estimator.dart`** (新規)
- 5 シグナル加重平均: 音量 (25%)、音量分散 (25%)、発話速度 (20%)、テキスト感情 (20%)、発話時間 (10%)
- 日本語・中国語・英語のポジティブ/ネガティブ語彙辞書
- S字カーブによる 1–10 スコアマッピング
- **修正**: 空データ時の `_analyzeVolume` / `_analyzeVolumeVariance` / `_analyzeSpeechRate` の既定値を 0.5 → 0.3 に変更（テスト条件 3–5 への対応）

**`lib/application/voice/parse_voice_input_use_case.dart`** (新規)
- `VoiceTextParser` → `CategoryMatcher` → `MerchantDatabase` のパイプライン統合
- MerchantMatch → VoiceParseResult の primitive フィールドへのマッピング処理
- `Result<VoiceParseResult>` を返す

### Phase 5: プレゼンテーション層

**`lib/features/accounting/presentation/providers/voice_providers.dart`** (新規)
- `merchantDatabaseProvider` (keepAlive=true)
- `voiceTextParserProvider`, `categoryMatcherProvider`, `parseVoiceInputUseCaseProvider`, `voiceSatisfactionEstimatorProvider`
- `categoryServiceProvider` は `use_case_providers.dart` の Single Source of Truth を使用（再定義なし）
- **修正**: `flutter_riverpod` import 追加（`Ref` 型の undefined エラーを修正）

**`lib/features/accounting/presentation/widgets/voice_waveform.dart`** (新規)
- 16 本の AnimatedContainer バー、soundLevel (0.0–1.0) で高さをアニメーション
- isActive=false 時は最小高さで静止

**`lib/features/accounting/presentation/widgets/voice_transcript_card.dart`** (新規)
- 部分認識テキスト（グレー）と最終テキスト（黒）を表示
- 録音中インジケーター

**`lib/features/accounting/presentation/widgets/voice_parse_preview.dart`** (新規)
- `ConsumerWidget` で `currentLocaleProvider` / `NumberFormatter.formatCurrency()` を使用
- 金額・商店名・カテゴリ・台帳種別を表示

**`lib/features/accounting/presentation/screens/voice_input_screen.dart`** (全面置換)
- スタブ `StatefulWidget` を `ConsumerStatefulWidget` に全面置換
- `SpeechRecognitionService` をライフサイクルに直接管理（プロバイダー外）
- デバウンスパーシング（300ms）、音量サンプリングスロットル（100ms）
- 音声特徴量収集 → `_buildAudioFeatures()` → 満足度推定フロー
- **修正**: 未使用 import `voice_satisfaction_estimator.dart` を削除

### Phase 6: TransactionConfirmScreen の修正

`lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`
- `initialMerchant: String?` パラメータを追加（`_storeController.text` を事前入力）
- `initialSatisfaction: int?` パラメータを追加（`_soulSatisfaction` を事前入力）
- `initState()` で両パラメータの初期化処理を追加

---

## 遭遇した問題と解決策

### 問題 1: build_runner が `CategoryMatcher` 型未定義エラー
**症状:** テストファイルの `@GenerateMocks([CategoryMatcher, MerchantDatabase])` で型不明エラー
**原因:** テストファイル作成時点でアプリケーション層のファイルが未作成
**解決策:** アプリケーション層ファイルを作成後に build_runner を再実行

### 問題 2: voice_providers.dart で `Undefined class 'Ref'`
**症状:** `flutter analyze` で Ref が未定義
**原因:** `riverpod_annotation` のみ import し `flutter_riverpod` を import していなかった
**解決策:** `import 'package:flutter_riverpod/flutter_riverpod.dart';` を追加

### 問題 3: SpeechRecognitionService の非推奨 API 警告
**症状:** `partialResults` / `cancelOnError` が top-level params として非推奨
**原因:** speech_to_text 7.x で `SpeechListenOptions` 内のみが正式 API
**解決策:** top-level の両パラメータを削除（`SpeechListenOptions` 内には既に設定済み）

### 問題 4: 未使用 import 警告 (voice_input_screen.dart)
**症状:** `voice_satisfaction_estimator.dart` の import が未使用
**原因:** `VoiceSatisfactionEstimator` をプロバイダー経由でアクセスするため直接 import 不要
**解決策:** 当該 import 行を削除

### 問題 5: 満足度推定テスト失敗（empty audio → score 3-5 期待に対し 6）
**症状:** `VoiceSatisfactionEstimator empty audio features -> default satisfaction 3-5` が失敗
**原因:** `_analyzeSpeechRate` が無効データ時に 0.5 を返し、加重合計が 0.370 になり satisfaction=6 に
**解決策:** 無効データ時の既定値を `_analyzeVolume` / `_analyzeVolumeVariance` / `_analyzeSpeechRate` すべてで 0.3 に変更。計算後スコア 0.330 → satisfaction=5 で範囲内に

---

## テスト検証

- [x] 単体テスト全通過 (41/41)
- [x] 既存テスト全通過（リグレッションなし、334/334）
- [x] `flutter analyze` ゼロ警告
- [x] `build_runner build` 成功
- [ ] 手動デバイステスト（デバイス未接続のためスキップ）

---

## コード変更統計

- 新規ファイル: 15 ファイル
  - テスト: 6 ファイル
  - ドメイン: 1 ファイル
  - インフラ: 2 ファイル
  - アプリケーション: 4 ファイル
  - プレゼンテーション (プロバイダー): 1 ファイル
  - プレゼンテーション (ウィジェット): 3 ファイル
- 修正ファイル: 5 ファイル
  - `pubspec.yaml`
  - `ios/Runner/Info.plist`
  - `android/app/src/main/AndroidManifest.xml`
  - `voice_input_screen.dart`（スタブ置換）
  - `transaction_confirm_screen.dart`（オプション初期値パラメータ追加）

---

## 後続作業

- [ ] 実デバイスでの音声認識 E2E 動作確認
- [ ] MerchantDatabase のシードデータ拡充（現在 ~12 件 → 500+ 件）
- [ ] ML 分類器との統合（TFLite、MOD-004 Phase 3）
- [ ] UI デザインレビュー（波形アニメーション、カラーテーマ調整）
- [ ] 国際化対応の検証（`マイクへのアクセスを許可してください` 等のハードコード文字列を ARB に移行）

---

## 参考資料

- `docs/arch/02-module-specs/MOD-009_VoiceInput.md`
- `docs/plans/2026-02-22-mod004-ocr-camera-gallery-full-pipeline.md`
- speech_to_text 7.3.0 ドキュメント

---

**作成時間:** 2026-02-22 13:18
**作者:** Claude Sonnet 4.6
