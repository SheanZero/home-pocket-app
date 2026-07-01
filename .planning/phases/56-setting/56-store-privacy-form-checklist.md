# ストア プライバシー申告チェックリスト — まもる家計簿（Home Pocket）

**種別:** 上線オペレーター向けデリバラブル（`.planning/` ドキュメント。アプリコードではない）
**対象:** Apple App Store「Privacy Nutrition Labels（App Privacy）」 × Google Play「Data Safety」
**作成:** 56-06（Phase 56-setting / LEGAL-05 / D-05）
**口径基準:** `assets/legal/privacy_ja.md`（56-02）と、アプリの**実際のネットワーク挙動**（v1.7 為替レート取得 + FCM プッシュトークン）

> このチェックリストは「反射的に『何も収集しない』と申告しない」ためのものです。ゼロ知識設計であっても、アプリには**実在する限定的な外部通信**があります。ストア申告はアプリの実挙動と `privacy_*.md` に完全一致させること（T-56-03: 申告と実挙動の不一致は compliance リスク）。

---

## 0. アプリの実データフロー（申告の根拠）

| # | フロー | 送信されるもの | 送信されないもの | ストア上の扱い |
|---|--------|----------------|------------------|----------------|
| F1 | 端末内の家計データ保存 | （外部送信なし） | 取引・金額・カテゴリ・メモ・写真すべて端末内のみ・4層暗号化 | 「収集(Collect)」対象外（開発者/サーバーはアクセス不可） |
| F2 | **為替レート取得（v1.7）** | 通貨コード等のレート要求のみ | 個人情報・家計データは一切送信しない | 開発者が「収集」する個人データではない（機能提供に必要な外部 API 呼び出し） |
| F3 | プッシュ通知トークン登録（**有効時のみ**） | FCM プッシュトークン（Google / Firebase Cloud Messaging） | 家計データは送信しない | 「Device ID / 識別子」を Google と共有する可能性あり（プッシュ利用時のみ） |
| F4 | 家族同期（P2P） | 端末間 E2EE 通信のみ | 開発者サーバーには一切保存しない | サーバー収集なし・端末間のエンドツーエンド暗号化 |
| F5 | 広告 / 解析 / トラッキング SDK | **なし** | — | Tracking なし・第三者解析なし |

---

## 1. Apple App Store — Privacy Nutrition Labels（App Privacy）

Apple の設問順（Data Collection → Data Types → Linked/Tracking）に沿って回答する。

### 1-1. Data Collection の有無

- **「Do you or your third-party partners collect data from this app?」**
  - 回答方針: **Yes**（反射的な No は不可）。理由:
    - F3 プッシュトークンを Google に登録する経路がある（プッシュ有効時）。
    - F2 為替 API 呼び出しがある（ただし個人データは送信しない）。
  - 家計データ本体（F1）は端末内のみで開発者は復号不可 → **Collect には該当しない**。

### 1-2. Data Types（申告すべきカテゴリ）

| Apple カテゴリ | 申告 | 根拠フロー | 用途(Purpose) | Linked to user? | Used for Tracking? |
|----------------|------|------------|---------------|-----------------|--------------------|
| Financial Info | **申告しない**（Not Collected） | F1 端末内・E2EE | — | — | — |
| Contacts / Photos の中身 | **申告しない**（端末内のみ） | F1 | — | — | — |
| Identifiers（Device ID / Push Token） | **プッシュ有効時に申告** | F3 | App Functionality | No（家計データと紐付けない） | **No** |
| Diagnostics / Usage Data | **申告しない** | F5 なし | — | — | — |
| Location / Browsing / Contacts 等 | **申告しない** | 該当機能なし | — | — | — |

- **App Tracking Transparency（ATT）:** トラッキング SDK なし（F5）→ Tracking 申告は **なし**、ATT プロンプトも不要。

### 1-3. 「上线前 by launch operator」記入欄

- [ ] プッシュ通知機能を **v1.0 で有効化するか** を最終確認（無効なら F3 の Identifiers 申告を外す）。
- [ ] 為替レート提供元サービス名 / エンドポイント: `__________`（実装確定後に記入）
- [ ] プライバシーポリシー公開 URL: `__________`（`privacy_*.md` の掲載先。App Privacy 必須項目）
- [ ] サポート連絡先メール: `__________`（`privacy_ja.md` §7 の `support@example.com` を実アドレスに差し替え）

---

## 2. Google Play — Data Safety

Google の設問（Data collection & sharing → Data types → Security practices）に沿って回答する。

### 2-1. Data collection / sharing の有無

- **「Does your app collect or share any of the required user data types?」**
  - 回答方針: **Yes**（F3 プッシュトークンを Google と共有し得るため）。
  - 家計データ本体（F1）は端末内のみ・開発者アクセス不可 → collect/share 対象外。

### 2-2. Data types（申告すべきカテゴリ）

| Google カテゴリ | Collected | Shared | 根拠フロー | 用途 | 備考 |
|-----------------|-----------|--------|------------|------|------|
| Financial info（購入履歴・家計データ） | **No** | No | F1 端末内・E2EE | — | 開発者/サーバー復号不可 |
| App activity / App info & performance | **No** | No | F5 なし | — | 解析 SDK なし |
| Device or other IDs（Push token） | プッシュ有効時 **Yes** | **Yes**（Google/FCM） | F3 | App functionality（通知配信） | プッシュ無効なら No |
| Personal info（氏名・メール等） | **No** | No | 収集機能なし | — | サポート連絡は任意・アプリ外 |
| Location | **No** | No | 該当機能なし | — | — |

### 2-3. Security practices（Google 必須の追加設問）

- [x] **Data is encrypted in transit:** Yes（TLS + 家族同期 E2EE / F4）
- [x] **Data is encrypted at rest:** Yes（4層暗号化・SQLCipher AES-256 / F1）
- [x] **Users can request data deletion:** 端末内保存のため、アプリ削除でデータ消去。データ削除手段を明記すること。
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
- [ ] F4 家族同期は端末間 E2EE・サーバー保存なし — privacy §4 と一致
- [ ] F5 広告・トラッキング SDK なし — privacy §5 と一致

---

## 4. 上线前の運用メモ（launch operator）

- **審査ラウンドトリップの余裕を確保:** Apple / Google とも申告と実挙動の不一致で reject され得る。初回提出は公開希望日から**十分前倒し**で行い、差し戻し往復のスラックを見込むこと（T-56-03）。
- **プッシュ通知の有効/無効が申告を左右する（F3）:** v1.0 の最終判断で Identifiers / Device ID 申告の要否が変わる。ビルド確定後に本チェックリストの該当行を確定させる。
- **草案マーカー:** `privacy_*.md` は日本の法務による復核前の草案。正式版確定時に本チェックリストの URL / 連絡先欄も同時に更新する。
- **このファイルはアプリに同梱しない:** `.planning/` 配下の運用ドキュメント。`lib/` には配置しないこと（D-05）。
