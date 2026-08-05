# ストア プライバシー申告チェックリスト — まもる家計簿（Home Pocket）

**種別:** 上線オペレーター向けデリバラブル（`.planning/` ドキュメント。アプリコードではない）
**対象:** Apple App Store「Privacy Nutrition Labels（App Privacy）」 × Google Play「Data Safety」
**作成:** 56-06（Phase 56-setting / LEGAL-05 / D-05）
**口径基準:** `assets/legal/privacy_ja.md`（56-02）と、アプリおよび中継サーバーの**実際のネットワーク挙動**（v1.7 為替レート取得 + FCM プッシュトークン + E2EE 家族同期）

> このチェックリストは「反射的に『何も収集しない』と申告しない」ためのものです。ゼロ知識設計であっても、アプリには**実在する限定的な外部通信**があります。ストア申告はアプリの実挙動と `privacy_*.md` に完全一致させること（T-56-03: 申告と実挙動の不一致は compliance リスク）。

---

## 0. アプリの実データフロー（申告の根拠）

| # | フロー | 送信されるもの | 送信されないもの | ストア上の扱い |
|---|--------|----------------|------------------|----------------|
| F1 | 端末内の家計データ保存 | （外部送信なし。家族同期は F4） | 端末内データベースの取引・金額・カテゴリ・メモ・写真は4層暗号化 | 端末内処理は「収集(Collect)」対象外 |
| F2 | **為替レート取得（v1.7）** | 通貨コード等のレート要求のみ | 個人情報・家計データは一切送信しない | 開発者が「収集」する個人データではない（機能提供に必要な外部 API 呼び出し） |
| F3 | プッシュ通知トークン登録（**有効時のみ**） | FCM プッシュトークン（Google / Firebase Cloud Messaging） | 家計データは送信しない | 「Device ID / 識別子」を Google と共有する可能性あり（プッシュ利用時のみ） |
| F4 | 家族同期（E2EE 中継） | E2EE 暗号化メッセージ、端末/グループ識別子、公開鍵、端末名・表示名・グループ名、プラットフォーム、メンバー状態等 | 復号鍵、家計データ平文、レシート写真 | 密文は7日間の有効期限を持ち、受信確認時または期限経過後の定期処理で物理削除。運用メタデータはサーバーから読取可能であり「サーバー収集なし」とは申告しない |
| F5 | 広告 / 解析 / トラッキング SDK | **なし** | — | Tracking なし・第三者解析なし |

---

## 1. Apple App Store — Privacy Nutrition Labels（App Privacy）

Apple の設問順（Data Collection → Data Types → Linked/Tracking）に沿って回答する。

### 1-1. Data Collection の有無

- **「Do you or your third-party partners collect data from this app?」**
  - 回答方針: **Yes**（反射的な No は不可）。理由:
    - F3 プッシュトークンを Google に登録する経路がある（プッシュ有効時）。
    - F2 為替 API 呼び出しがある（ただし個人データは送信しない）。
    - F4 で端末/グループ識別子、表示名、運用ログ等を中継サーバーが保持する。
  - 家計データ本体は F4 で端末外へ送信されるが、E2EE により開発者/中継者が読める形では保存されない。Apple の Collect 定義（開発者または第三者が要求処理時間を超えてアクセス可能な形での保存）との最終対応は、App Store Connect 送信時に法務/運用者が確認する。

### 1-2. Data Types（申告すべきカテゴリ）

| Apple カテゴリ | 申告 | 根拠フロー | 用途(Purpose) | Linked to user? | Used for Tracking? |
|----------------|------|------------|---------------|-----------------|--------------------|
| Financial Info | **暫定: 申告しない**（法務確認必須） | F1 端末内 + F4 は中継者が読めない E2EE 密文のみ | App Functionality | 端末/グループには配送上関連するが、サーバーは内容を読めない | **No** |
| Contacts / Photos の中身 | **申告しない**（端末内のみ） | F1 | — | — | — |
| Identifiers（Device / Group ID、Push Token） | **申告する** | F3 + F4 | App Functionality / Security | **Yes**（端末・グループ状態に関連付ける） | **No** |
| Name（端末名・表示名・グループ名） | **申告する** | F4 | App Functionality | **Yes**（端末・グループ状態に関連付ける） | **No** |
| Diagnostics / Usage Data（パス、状態、処理時間） | **申告する方向で最終確認** | F4 サーバーログ | App Functionality / Security | **Yes**（端末IDと同じログ行） | **No** |
| Location / Browsing / Contacts 等 | **申告しない** | 該当機能なし | — | — | — |

- **App Tracking Transparency（ATT）:** トラッキング SDK なし（F5）→ Tracking 申告は **なし**、ATT プロンプトも不要。

### 1-3. 「上线前 by launch operator」記入欄

- [ ] プッシュ通知機能を **v1.0 で有効化するか** を最終確認（無効なら F3 の Identifiers 申告を外す）。
- [ ] F4 の Identifiers / Name / Diagnostics の App Privacy 回答を、実際の本番ログ設定と Apple の最新定義に照らして法務確認する。
- [ ] 本番 `BACKUP_KEEP_DAYS`: `__________`（標準設定14日。実値を確認して政策 §4-1 と一致させる）
- [ ] バックアップ保存先の暗号化とアクセス制御: `__________`（標準 compose は `.sql.gz` を Docker volume に保存するだけで、リポジトリから保存先暗号化を確認できない）
- [ ] アプリ/DB/アクセスログ保存期間と削除方法: `__________`（現行 server コード・標準 deploy では未設定）
- [ ] PostgreSQL に `log_parameter_max_length=0` を設定し、500ms 以上のSQLログへバインド値が出力されないことを本番相当環境で確認する。
- [ ] 為替レート提供元サービス名 / エンドポイント: `__________`（実装確定後に記入）
- [ ] プライバシーポリシー公開 URL: `__________`（`privacy_*.md` の掲載先。App Privacy 必須項目）
- [ ] サポート連絡先メール: `__________`（`privacy_ja.md` §7 の `support@example.com` を実アドレスに差し替え）

---

## 2. Google Play — Data Safety

Google の設問（Data collection & sharing → Data types → Security practices）に沿って回答する。

### 2-1. Data collection / sharing の有無

- **「Does your app collect or share any of the required user data types?」**
  - 回答方針: **Yes**（F3 プッシュトークンおよび F4 の読取可能な運用メタデータを扱うため）。
  - F4 の家計データ本体は E2EE で中継者にも読めず、Google Play の明示的な E2EE 除外条件を満たす限り、Financial info の collection 申告対象外。端末/グループ識別子や表示名、ログはこの除外に含めない。

### 2-2. Data types（申告すべきカテゴリ）

| Google カテゴリ | Collected | Shared | 根拠フロー | 用途 | 備考 |
|-----------------|-----------|--------|------------|------|------|
| Financial info（購入履歴・家計データ） | **No**（E2EE 除外前提） | No | F1 端末内 + F4 E2EE | App functionality | 開発者/中継者を含む仲介者が復号不可で、鍵は送受信者のみが保持 |
| App activity / App info & performance | **Yes** | No | F4 のリクエストパス、応答状態、処理時間 | App functionality / Security | 解析 SDK ではなく中継運用ログ。保存期間の固定と PostgreSQL バインド値ログの無効化が上线条件 |
| Device or other IDs（Device / Group ID、Push token） | **Yes** | プッシュ有効時 **Yes**（Google/FCM） | F3 + F4 | App functionality / Security | 中継利用時はプッシュ無効でも Device / Group ID をサーバーが保持 |
| Personal info（端末名・表示名・グループ名） | **Yes** | No | F4 | App functionality | 実名入力は必須ではないが、ユーザー入力文字列をサーバーが読取可能な形で保持 |
| Location | **No** | No | 該当機能なし | — | — |

### 2-3. Security practices（Google 必須の追加設問）

- [x] **Data is encrypted in transit:** Yes（TLS + 家族同期 E2EE / F4）
- [ ] **Data is encrypted at rest:** 端末内家計データは4層暗号化、F4 メッセージ本文はE2EE密文。ただしサーバー運用メタデータと `.sql.gz` バックアップ保存先の暗号化はリポジトリから確認できないため、本番インフラ確認前に一律 Yes としない。
- [ ] **Users can request data deletion:** 現行 server API には端末/グループ運用メタデータ全体の削除リクエスト経路がない。受信確認/7日間の期限経過による密文削除と、端末内データのアプリ削除だけではこの設問を満たすと断定しない。上线前に削除窓口または API を実装し、政策とフォームを一致させる。
- [ ] **Independent security review:** 該当なし（v1.0 では申告しない）

### 2-4. 「上线前 by launch operator」記入欄

- [ ] Data Safety フォームは審査で**実挙動と照合**される。F2/F3 の実装を最終ビルドで確認してから送信。
- [ ] データ削除リクエスト URL / 手順記載欄: `__________`
- [ ] プライバシーポリシー URL（Play でも必須）: `__________`

---

## 3. 口径ロック — 一貫性チェック

以下は `assets/legal/privacy_ja.md`（56-02）と**同一口径**であること（差異があれば申告 or ポリシーのどちらかが誤り）:

- [ ] F1 家計データ = 端末内・4層暗号化・開発者アクセス不可（ゼロ知識） — privacy §1〜2 と一致
- [ ] F2 **為替レート取得**は実在する外部通信・PII/家計データは非送信 — privacy §3-1 と一致
- [ ] F3 プッシュトークン登録は**有効時のみ**・Google/FCM・家計データ非送信 — privacy §3-2 と一致
- [ ] F4 家族同期は E2EE 密文を中継サーバーが一時保存・転送し、受信確認または7日間の期限経過後に物理削除。運用メタデータとログは別管理 — privacy §4 と一致
- [ ] F5 広告・トラッキング SDK なし — privacy §5 と一致

---

## 4. 上线前の運用メモ（launch operator）

- **審査ラウンドトリップの余裕を確保:** Apple / Google とも申告と実挙動の不一致で reject され得る。初回提出は公開希望日から**十分前倒し**で行い、差し戻し往復のスラックを見込むこと（T-56-03）。
- **プッシュ通知の有効/無効が申告を左右する（F3）:** v1.0 の最終判断で Identifiers / Device ID 申告の要否が変わる。ビルド確定後に本チェックリストの該当行を確定させる。
- **中継サーバー設定を実環境で確認:** リポジトリ標準値はメッセージ7日、制御イベント90日、バックアップ14日。ログ保存期間と期限切れグループ鍵要求レコードの削除期限は未固定。PostgreSQL の遅いSQLログはバインド値を除外していない。本番環境の上書き値、`log_parameter_max_length=0`、ログローテーションを確認し、政策とストア申告に反映する。
- **草案マーカー:** `privacy_*.md` は日本の法務による復核前の草案。正式版確定時に本チェックリストの URL / 連絡先欄も同時に更新する。
- **このファイルはアプリに同梱しない:** `.planning/` 配下の運用ドキュメント。`lib/` には配置しないこと（D-05）。
