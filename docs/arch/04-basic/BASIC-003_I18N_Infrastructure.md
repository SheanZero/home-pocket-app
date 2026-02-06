# BASIC-003: 国際化基盤 (I18N Infrastructure)

**文档編号:** BASIC-003
**文档版本:** 1.0
**創建日期:** 2026-02-06
**最後更新:** 2026-02-06
**状態:** 已実施
**作者:** Claude Opus 4.6

---

## 1. 概述

本文档は `lib/infrastructure/i18n/`、`lib/l10n/`、`lib/features/settings/` に分散する国際化（i18n）コンポーネントの**技術実装リファレンス**です。開発者向けに完全な API 仕様、フォーマットルール、ARB 翻訳キー一覧、およびコード例を提供します。

### 文档定位

| 文档 | 定位 | 関注点 |
|------|------|--------|
| **本文档 (BASIC-003)** | 基盤技術実装文書 | 全 i18n コンポーネントの API・アルゴリズム・コード例 |
| [MOD-014](../02-module-specs/MOD-014_i18n.md) | モジュール機能設計文書 | i18n モジュールのビジネス要件・テスト戦略・受入基準 |
| [CLAUDE.md](../../../CLAUDE.md) | 開発ガイドライン | i18n 必須ルールとコーディング規約 |

---

## 2. ディレクトリ構造

```
lib/
├── l10n/                                          # ARB 翻訳ファイル
│   ├── app_en.arb                                 # 英語（テンプレート）
│   ├── app_ja.arb                                 # 日本語
│   └── app_zh.arb                                 # 中国語（簡体字）
│
├── generated/                                     # 自動生成（gitignore）
│   └── app_localizations.dart                     # flutter gen-l10n 出力
│
├── infrastructure/i18n/                           # Infrastructure 層
│   ├── formatters/
│   │   ├── date_formatter.dart                    # 日付フォーマッタ
│   │   └── number_formatter.dart                  # 数値/通貨フォーマッタ
│   └── models/
│       └── locale_settings.dart                   # ロケール設定モデル
│
└── features/settings/                             # Feature 層
    ├── domain/entities/
    │   └── locale_settings.dart                   # ※現在の実体位置
    └── presentation/providers/
        └── locale_provider.dart                   # ロケール切替プロバイダ
```

> **注意:** `LocaleSettings` は現在 `lib/features/settings/domain/entities/` にあり、
> アーキテクチャ上は `lib/infrastructure/i18n/models/` への移行を計画しています。

### 生成パイプライン

```
l10n.yaml (設定)
    │
    ▼
lib/l10n/app_{en,ja,zh}.arb (翻訳ソース)
    │
    ▼ flutter gen-l10n
lib/generated/app_localizations.dart (生成コード)
    │
    ▼ S.of(context).keyName
ウィジェットで使用
```

---

## 3. ARB 翻訳ファイル

### 3.1 設定 (l10n.yaml)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
```

| 設定項目 | 値 | 説明 |
|----------|-----|------|
| `arb-dir` | `lib/l10n` | ARB ファイル格納ディレクトリ |
| `template-arb-file` | `app_en.arb` | テンプレート（@metadata 付き） |
| `output-class` | `S` | 生成クラス名（`S.of(context)` で使用） |
| `output-dir` | `lib/generated` | 生成ファイル出力先 |

### 3.2 翻訳キー一覧（163 キー）

#### ナビゲーション

| キー | 日本語 (ja) | 中国語 (zh) | 英語 (en) |
|------|------------|------------|-----------|
| `appName` | まもる家計簿 | 守护家计簿 | Home Pocket |
| `home` | ホーム | 首页 | Home |
| `transactions` | 取引 | 交易 | Transactions |
| `analytics` | 分析 | 分析 | Analytics |
| `settings` | 設定 | 设置 | Settings |

#### 取引管理

| キー | ja | zh | en |
|------|-----|-----|-----|
| `newTransaction` | 新しい取引 | 新交易 | New Transaction |
| `amount` | 金額 | 金额 | Amount |
| `category` | カテゴリ | 分类 | Category |
| `note` | メモ | 备注 | Note |
| `merchant` | 店舗 | 商家 | Merchant |
| `date` | 日付 | 日期 | Date |
| `transactionTypeExpense` | 支出 | 支出 | Expense |
| `transactionTypeIncome` | 収入 | 收入 | Income |

#### カテゴリ名

| キー | ja | zh | en |
|------|-----|-----|-----|
| `categoryFood` | 食費 | 餐饮 | Food |
| `categoryHousing` | 住居 | 住房 | Housing |
| `categoryTransport` | 交通 | 交通 | Transport |
| `categoryUtilities` | 光熱費 | 水电费 | Utilities |
| `categoryEntertainment` | 娯楽 | 娱乐 | Entertainment |
| `categoryEducation` | 教育 | 教育 | Education |
| `categoryHealth` | 医療 | 医疗 | Health |
| `categoryShopping` | 買物 | 购物 | Shopping |
| `categoryOther` | その他 | 其他 | Other |

#### デュアル台帳

| キー | ja | zh | en |
|------|-----|-----|-----|
| `survivalLedger` | 生存帳簿 | 生存账本 | Survival Ledger |
| `soulLedger` | 魂帳簿 | 灵魂账本 | Soul Ledger |

#### アクション

| キー | ja | zh | en |
|------|-----|-----|-----|
| `save` | 保存 | 保存 | Save |
| `cancel` | キャンセル | 取消 | Cancel |
| `delete` | 削除 | 删除 | Delete |
| `edit` | 編集 | 编辑 | Edit |
| `confirm` | 確認 | 确认 | Confirm |
| `retry` | 再試行 | 重试 | Retry |
| `search` | 検索 | 搜索 | Search |
| `filter` | フィルター | 筛选 | Filter |
| `sort` | 並び替え | 排序 | Sort |
| `refresh` | 更新 | 刷新 | Refresh |

#### 状態表示

| キー | ja | zh | en |
|------|-----|-----|-----|
| `loading` | 読み込み中... | 加载中... | Loading... |
| `noData` | データがありません | 暂无数据 | No data available |
| `today` | 今日 | 今天 | Today |
| `yesterday` | 昨日 | 昨天 | Yesterday |

#### エラーメッセージ

| キー | ja | zh | en |
|------|-----|-----|-----|
| `errorNetwork` | ネットワークエラー | 网络错误 | Network error |
| `errorUnknown` | 不明なエラーが発生しました | 发生未知错误 | An unknown error occurred |
| `errorInvalidAmount` | 無効な金額です | 无效金额 | Invalid amount |
| `errorRequired` | 必須項目です | 必填项 | This field is required |
| `errorInvalidDate` | 無効な日付です | 无效日期 | Invalid date |
| `errorDatabaseWrite` | データベース書込エラー | 数据库写入错误 | Database write error |
| `errorDatabaseRead` | データベース読取エラー | 数据库读取错误 | Database read error |
| `errorEncryption` | 暗号化エラー | 加密错误 | Encryption error |
| `errorSync` | 同期エラー | 同步错误 | Sync error |
| `errorBiometric` | 生体認証エラー | 生物识别错误 | Biometric error |
| `errorPermission` | 権限エラー | 权限错误 | Permission error |

#### パラメータ付きメッセージ

| キー | ja | en | パラメータ |
|------|-----|-----|-----------|
| `errorMinAmount` | {min}以上の金額を入力してください | Please enter an amount of at least {min} | `min: double` |
| `errorMaxAmount` | {max}以下の金額を入力してください | Please enter an amount no greater than {max} | `max: double` |

#### 成功メッセージ

| キー | ja | zh | en |
|------|-----|-----|-----|
| `successSaved` | 保存しました | 保存成功 | Saved successfully |
| `successDeleted` | 削除しました | 删除成功 | Deleted successfully |
| `successSynced` | 同期しました | 同步成功 | Synced successfully |

#### フォームラベル

| キー | ja | zh | en |
|------|-----|-----|-----|
| `merchantPlaceholder` | 店舗名を入力 | 请输入商家名称 | Enter merchant name |
| `notePlaceholder` | メモを入力 | 请输入备注 | Enter a note |
| `pleaseEnterAmount` | 金額を入力してください | 请输入金额 | Please enter an amount |
| `amountMustBeGreaterThanZero` | 金額は0より大きくしてください | 金额必须大于零 | Amount must be greater than zero |
| `pleaseSelectCategory` | カテゴリを選択してください | 请选择分类 | Please select a category |

### 3.3 ARB ファイルフォーマット

**テンプレートファイル (app_en.arb) の構造:**

```json
{
  "@@locale": "en",
  "appName": "Home Pocket",
  "@appName": {
    "description": "The application name"
  },
  "errorMinAmount": "Please enter an amount of at least {min}",
  "@errorMinAmount": {
    "description": "Minimum amount error",
    "placeholders": {
      "min": {
        "type": "double"
      }
    }
  }
}
```

**ルール:**
- テンプレートファイル (`app_en.arb`) にのみ `@metadata` を記述
- `ja`/`zh` ファイルはキーと値のみ
- パラメータ付きメッセージは `placeholders` で型を指定
- 全 3 ファイルのキー数は一致必須（現在 163 キー）

### 3.4 翻訳追加ワークフロー

```bash
# 1. 全 3 ファイルにキーを追加
#    lib/l10n/app_en.arb  ← @metadata 付き
#    lib/l10n/app_ja.arb
#    lib/l10n/app_zh.arb

# 2. ローカライゼーション再生成
flutter gen-l10n

# 3. コードで使用
# S.of(context).newKeyName
```

---

## 4. コア コンポーネント

### 4.1 LocaleSettings（ロケール設定モデル）

**ファイル:** `lib/features/settings/domain/entities/locale_settings.dart`
**計画移行先:** `lib/infrastructure/i18n/models/locale_settings.dart`

#### Freezed モデル定義

```dart
@freezed
class LocaleSettings with _$LocaleSettings {
  const factory LocaleSettings({
    /// 選択されたロケール (ja, zh, en)
    required Locale locale,
    /// システムデフォルトを使用するか
    required bool isSystemDefault,
  }) = _LocaleSettings;

  /// デフォルト設定（日本語）
  factory LocaleSettings.defaultSettings() => const LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );

  /// システムロケールから作成
  factory LocaleSettings.fromSystem(Locale systemLocale) {
    final supportedCodes = ['ja', 'zh', 'en'];
    final normalizedCode = supportedCodes.contains(systemLocale.languageCode)
        ? systemLocale.languageCode
        : 'ja';  // 非対応言語は日本語にフォールバック
    return LocaleSettings(
      locale: Locale(normalizedCode),
      isSystemDefault: true,
    );
  }
}
```

#### フィールド説明

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `locale` | `Locale` | 現在の言語設定 (`ja`, `zh`, `en`) |
| `isSystemDefault` | `bool` | システムデフォルト使用フラグ |

#### ファクトリメソッド

| メソッド | 説明 | デフォルト locale |
|----------|------|-------------------|
| `defaultSettings()` | 日本語デフォルト | `Locale('ja')` |
| `fromSystem(Locale)` | システム言語検出 | 非対応 → `Locale('ja')` |

#### 対応言語とフォールバック

```
システム言語 → 検出結果
────────────────────────
ja (日本語)   → Locale('ja')  ✅
zh (中国語)   → Locale('zh')  ✅
en (英語)     → Locale('en')  ✅
ko (韓国語)   → Locale('ja')  ← フォールバック
fr (仏語)     → Locale('ja')  ← フォールバック
```

---

### 4.2 LocaleNotifierProvider（ロケール管理プロバイダ）

**ファイル:** `lib/features/settings/presentation/providers/locale_provider.dart`

#### プロバイダ定義

```dart
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  LocaleSettings build() {
    return LocaleSettings.defaultSettings();  // 初期値: 日本語
  }

  /// アプリケーションのロケールを変更
  void setLocale(Locale locale) {
    state = LocaleSettings(
      locale: locale,
      isSystemDefault: false,
    );
  }

  /// システムデフォルトに設定
  void setSystemDefault(Locale systemLocale) {
    state = LocaleSettings.fromSystem(systemLocale);
  }

  /// 日本語デフォルトにリセット
  void resetToDefault() {
    state = LocaleSettings.defaultSettings();
  }
}

/// 現在の Locale オブジェクトを直接取得する便利プロバイダ
@riverpod
Locale currentLocale(CurrentLocaleRef ref) {
  final settings = ref.watch(localeNotifierProvider);
  return settings.locale;
}
```

#### メソッド一覧

| メソッド | 引数 | 説明 |
|----------|------|------|
| `setLocale(Locale)` | `Locale('ja')` / `Locale('en')` / `Locale('zh')` | 手動言語切替 |
| `setSystemDefault(Locale)` | デバイスの `systemLocale` | システム言語追従 |
| `resetToDefault()` | なし | 日本語にリセット |

#### プロバイダ依存関係

```
localeNotifierProvider (LocaleSettings)
    │
    ▼ ref.watch()
currentLocaleProvider (Locale)
    │
    ▼ ref.watch()
DateFormatter / NumberFormatter で使用
```

#### 使用例

```dart
// 言語切替
final notifier = ref.read(localeNotifierProvider.notifier);
notifier.setLocale(const Locale('en'));

// 現在のロケール取得
final locale = ref.watch(currentLocaleProvider);

// ドロップダウンで切替
DropdownButton<Locale>(
  value: ref.watch(currentLocaleProvider),
  items: const [
    DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
    DropdownMenuItem(value: Locale('en'), child: Text('English')),
    DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
  ],
  onChanged: (locale) {
    if (locale != null) {
      ref.read(localeNotifierProvider.notifier).setLocale(locale);
    }
  },
);
```

---

### 4.3 DateFormatter（日付フォーマッタ）

**ファイル:** `lib/infrastructure/i18n/formatters/date_formatter.dart`
（現在の実体: `lib/shared/utils/formatters/date_formatter.dart`）

**技術スタック:** `intl` パッケージの `DateFormat`

#### クラス設計

```dart
/// ロケール対応の日付フォーマットユーティリティ
///
/// すべてのメソッドは static。インスタンス生成不可。
class DateFormatter {
  DateFormatter._();  // プライベートコンストラクタ
}
```

#### メソッド一覧

##### formatDate

```dart
/// ロケールに応じた日付のみのフォーマット
///
/// - ja: 2026/02/06
/// - zh: 2026年02月06日
/// - en: 02/06/2026
static String formatDate(DateTime date, Locale locale)
```

##### formatDateTime

```dart
/// ロケールに応じた日時フォーマット
///
/// - ja: 2026/02/06 14:30      (24時間制)
/// - zh: 2026年02月06日 14:30   (24時間制)
/// - en: 02/06/2026 2:30 PM    (12時間制 AM/PM)
static String formatDateTime(DateTime date, Locale locale)
```

##### formatRelative

```dart
/// 相対時間フォーマット
///
/// - 当日:     "今日" / "今天" / "Today"
/// - 昨日:     "昨日" / "昨天" / "Yesterday"
/// - 2-6日前:  "N日前" / "N天前" / "N days ago"
/// - 7日以上:  formatDate() にフォールバック
static String formatRelative(DateTime date, Locale locale)
```

##### formatMonthYear

```dart
/// 年月フォーマット
///
/// - ja: 2026年2月
/// - zh: 2026年2月
/// - en: February 2026
static String formatMonthYear(DateTime date, Locale locale)
```

#### ロケール別フォーマットパターン

| メソッド | ja パターン | zh パターン | en パターン |
|----------|-----------|-----------|-----------|
| `formatDate` | `yyyy/MM/dd` | `yyyy年MM月dd日` | `MM/dd/yyyy` |
| `formatDateTime` | `yyyy/MM/dd HH:mm` | `yyyy年MM月dd日 HH:mm` | `MM/dd/yyyy h:mm a` |
| `formatMonthYear` | `yyyy年M月` | `yyyy年M月` | `MMMM yyyy` |

#### 相対時間の文字列マッピング

| 条件 | ja | zh | en |
|------|-----|-----|-----|
| 0 日前 | 今日 | 今天 | Today |
| 1 日前 | 昨日 | 昨天 | Yesterday |
| N 日前 (2-6) | N日前 | N天前 | N days ago |
| 7+ 日前 | `formatDate()` | `formatDate()` | `formatDate()` |

#### 実装詳細

```dart
static String formatDate(DateTime date, Locale locale) {
  switch (locale.languageCode) {
    case 'ja':
      return DateFormat('yyyy/MM/dd', locale.toString()).format(date);
    case 'zh':
      return DateFormat('yyyy年MM月dd日', locale.toString()).format(date);
    case 'en':
    default:
      return DateFormat('MM/dd/yyyy', locale.toString()).format(date);
  }
}

static String formatRelative(DateTime date, Locale locale) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return _getRelativeToday(locale);
  } else if (difference.inDays == 1) {
    return _getRelativeYesterday(locale);
  } else if (difference.inDays < 7) {
    return _getRelativeDaysAgo(difference.inDays, locale);
  } else {
    return formatDate(date, locale);
  }
}
```

#### 使用例

```dart
final locale = ref.watch(currentLocaleProvider);
final tx = ref.watch(transactionProvider);

// 日付のみ
Text(DateFormatter.formatDate(tx.timestamp, locale));
// → "2026/02/06" (ja)

// 日時
Text(DateFormatter.formatDateTime(tx.timestamp, locale));
// → "2026/02/06 14:30" (ja)

// 相対時間
Text(DateFormatter.formatRelative(tx.timestamp, locale));
// → "今日" or "昨日" or "3日前" or "2026/01/15" (ja)

// 年月（月次レポート）
Text(DateFormatter.formatMonthYear(reportDate, locale));
// → "2026年2月" (ja)
```

---

### 4.4 NumberFormatter（数値/通貨フォーマッタ）

**ファイル:** `lib/infrastructure/i18n/formatters/number_formatter.dart`
（現在の実体: `lib/shared/utils/formatters/number_formatter.dart`）

**技術スタック:** `intl` パッケージの `NumberFormat`

#### クラス設計

```dart
/// ロケール対応の数値・通貨フォーマットユーティリティ
///
/// すべてのメソッドは static。インスタンス生成不可。
class NumberFormatter {
  NumberFormatter._();  // プライベートコンストラクタ
}
```

#### メソッド一覧

##### formatNumber

```dart
/// 千桁区切り付き数値フォーマット
///
/// [number]: フォーマットする数値
/// [locale]: 現在のロケール
/// [decimals]: 小数桁数（デフォルト 2）
///
/// 例 (ja): 1,234.56
/// 例 (en): 1,234.56
static String formatNumber(num number, Locale locale, {int decimals = 2})
```

##### formatCurrency

```dart
/// 通貨シンボル付きフォーマット
///
/// [amount]: 金額
/// [currencyCode]: 通貨コード (JPY, USD, CNY, EUR, GBP)
/// [locale]: 現在のロケール
///
/// 例: ¥1,235 (JPY), $1,234.56 (USD), ¥1,234.56 (CNY)
static String formatCurrency(num amount, String currencyCode, Locale locale)
```

##### formatPercentage

```dart
/// パーセンテージフォーマット
///
/// [value]: 割合 (0.0-1.0 の範囲)
/// [locale]: 現在のロケール
/// [decimals]: 小数桁数（デフォルト 2）
///
/// 例: 0.156 → "15.60%"
static String formatPercentage(double value, Locale locale, {int decimals = 2})
```

##### formatCompact

```dart
/// コンパクト数値フォーマット
///
/// 日本語/中国語: 万 (10,000) 単位を使用
/// 英語: K, M, B 単位を使用
///
/// 例 (ja): 12,345 → "1.2万", 123,456,789 → "12346万"
/// 例 (en): 12,345 → "12.3K", 1,234,567 → "1.23M"
static String formatCompact(num number, Locale locale)
```

#### 通貨設定

| 通貨コード | シンボル | 小数桁数 | 例 |
|-----------|---------|---------|-----|
| `JPY` | ¥ | 0 | ¥1,235 |
| `CNY` | ¥ | 2 | ¥1,234.56 |
| `USD` | $ | 2 | $1,234.56 |
| `EUR` | € | 2 | €1,234.56 |
| `GBP` | £ | 2 | £1,234.56 |

#### コンパクト数値ルール

| ロケール | 閾値 | 単位 | 例 |
|---------|------|------|-----|
| ja/zh | ≥ 10,000 | 万 | 12,345 → "1.2万" |
| ja/zh | ≥ 1,000,000 | 万 | 1,500,000 → "150万" |
| en | ≥ 1,000 | K | 12,345 → "12.3K" |
| en | ≥ 1,000,000 | M | 1,500,000 → "1.5M" |
| en | ≥ 1,000,000,000 | B | 1,500,000,000 → "1.5B" |

#### 実装詳細

```dart
static String formatCurrency(num amount, String currencyCode, Locale locale) {
  final formatter = NumberFormat.currency(
    locale: locale.toString(),
    symbol: _getCurrencySymbol(currencyCode),
    decimalDigits: _getCurrencyDecimals(currencyCode),
  );
  return formatter.format(amount);
}

static String formatCompact(num number, Locale locale) {
  if (locale.languageCode == 'ja' || locale.languageCode == 'zh') {
    if (number >= 10000) {
      final manValue = number / 10000;
      return '${formatNumber(manValue, locale, decimals: manValue >= 100 ? 0 : 1)}万';
    }
  }
  final formatter = NumberFormat.compact(locale: locale.toString());
  return formatter.format(number);
}

static String _getCurrencySymbol(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
    case 'CNY':
      return '¥';
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return currencyCode;
  }
}

static int _getCurrencyDecimals(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'JPY':
      return 0;
    default:
      return 2;
  }
}
```

#### 使用例

```dart
final locale = ref.watch(currentLocaleProvider);

// 通貨フォーマット
Text(NumberFormatter.formatCurrency(1500, 'JPY', locale));
// → "¥1,500" (ja)

Text(NumberFormatter.formatCurrency(29.99, 'USD', locale));
// → "$29.99" (en)

// パーセンテージ
Text(NumberFormatter.formatPercentage(0.156, locale));
// → "15.60%"

// コンパクト
Text(NumberFormatter.formatCompact(58000, locale));
// → "5.8万" (ja) / "58K" (en)
```

---

## 5. 依存関係図

### プロバイダ依存チェーン

```
LocaleNotifier (state: LocaleSettings)
    │
    ├──▶ currentLocaleProvider (Locale)
    │       │
    │       ├──▶ DateFormatter.formatDate(date, locale)
    │       ├──▶ DateFormatter.formatRelative(date, locale)
    │       ├──▶ NumberFormatter.formatCurrency(amount, code, locale)
    │       └──▶ NumberFormatter.formatCompact(number, locale)
    │
    └──▶ MaterialApp.locale (アプリ全体の言語)
            │
            └──▶ S.of(context).keyName (ARB 翻訳)
```

### パッケージ依存

| パッケージ | バージョン | 用途 |
|-----------|---------|------|
| `flutter_localizations` | SDK | Flutter 標準 i18n |
| `intl` | **0.20.2** (固定) | DateFormat, NumberFormat |
| `flutter_riverpod` | 2.6.1 | 状態管理 |
| `freezed_annotation` | 2.5.8 | 不変モデル |
| `riverpod_annotation` | 2.6.1 | Provider コード生成 |

> **重要:** `intl` は `0.20.2` に固定。`flutter_localizations` が要求するバージョンのため、
> アップグレード不可。

---

## 6. ウィジェット統合パターン

### 6.1 ローカライズ文字列

```dart
// ❌ 禁止: ハードコード
Text('Settings')

// ✅ 必須: S.of(context) を使用
Text(S.of(context).settings)
```

### 6.2 日付フォーマット

```dart
// ❌ 禁止: toString()
Text(transaction.timestamp.toString())

// ✅ 必須: DateFormatter + locale
final locale = ref.watch(currentLocaleProvider);
Text(DateFormatter.formatDate(transaction.timestamp, locale))
```

### 6.3 通貨フォーマット

```dart
// ❌ 禁止: ハードコード通貨シンボル
Text('¥${amount.toStringAsFixed(0)}')

// ✅ 必須: NumberFormatter + 通貨コード
final locale = ref.watch(currentLocaleProvider);
Text(NumberFormatter.formatCurrency(amount, 'JPY', locale))
```

### 6.4 パラメータ付きエラー

```dart
// エラーメッセージ（パラメータ付き）
final l10n = S.of(context);
if (amount < 0.01) {
  return l10n.errorMinAmount(0.01);
  // ja: "0.01以上の金額を入力してください"
}
```

### 6.5 完全なウィジェット例

```dart
class TransactionCard extends ConsumerWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);

    return Card(
      child: ListTile(
        title: Text(transaction.merchant ?? l10n.noData),
        subtitle: Text(
          DateFormatter.formatRelative(transaction.timestamp, locale),
        ),
        trailing: Text(
          NumberFormatter.formatCurrency(
            transaction.amount,
            'JPY',
            locale,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
```

---

## 7. セキュリティ考慮事項

- **翻訳キーにユーザーデータを埋め込まない** — パラメータは `placeholders` 機構で渡す
- **フォーマッタは表示専用** — ビジネスロジックでフォーマット済み文字列を比較しない
- **ARB ファイルに秘密情報を含めない** — API キーやパスワードは絶対不可

---

## 8. 参考文档

| 文档 | 編号 | 説明 |
|------|------|------|
| i18n モジュール仕様 | [MOD-014](../02-module-specs/MOD-014_i18n.md) | ビジネス要件・テスト戦略・受入基準 |
| 開発ガイドライン | [CLAUDE.md](../../../CLAUDE.md) | i18n 必須ルール・コーディング規約 |
| Flutter i18n 公式 | [flutter.dev](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization) | 公式ドキュメント |
| intl パッケージ | [pub.dev](https://pub.dev/packages/intl) | DateFormat / NumberFormat |
| ARB 仕様 | [GitHub](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification) | ARB ファイル形式 |

---

**文档状態:** 完了
**審核状態:** 待審核
**変更ログ:**
- 2026-02-06: v1.0 i18n 基盤技術文書を作成（ARB・DateFormatter・NumberFormatter・LocaleProvider・LocaleSettings）
