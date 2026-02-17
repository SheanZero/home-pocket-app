# I18N Infrastructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the complete i18n infrastructure per BASIC-003 spec: ARB translations (3 locales, ~100+ keys), DateFormatter, NumberFormatter, LocaleSettings model, LocaleNotifierProvider, MaterialApp wiring, and migrate all hardcoded UI strings to `S.of(context)`.

**Architecture:** Infrastructure layer (`lib/infrastructure/i18n/`) for formatters and models. Presentation layer (`lib/features/settings/presentation/providers/`) for locale provider. ARB files in `lib/l10n/` with `flutter gen-l10n` code generation. All user-facing strings accessed via `S.of(context)`. Dates via `DateFormatter`, currency via `NumberFormatter`, both locale-aware.

**Tech Stack:** Flutter 3.x, `flutter_localizations` (SDK), `intl: 0.20.2` (pinned), Riverpod 2.4+ codegen, Freezed

**Reference Docs:**
- Architecture: `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md`
- Module Spec: `doc/arch/02-module-specs/MOD-014_i18n.md`
- Guidelines: `CLAUDE.md` (i18n section)

---

## Hardcoded Strings Inventory

Before starting, here is the complete audit of hardcoded strings in the codebase:

| File | Hardcoded Strings |
|------|-------------------|
| `main_shell_screen.dart` | 'Ledger', 'Analytics', 'Settings' |
| `dual_ledger_screen.dart` | 'Home Pocket', 'Survival', 'Soul' |
| `transaction_list_screen.dart` | 'Transactions', 'No transactions yet', 'Tap + to add your first transaction' |
| `transaction_form_screen.dart` | 'New Transaction', 'Amount', 'Expense', 'Income', 'Category', 'Note (optional)', 'Save', 'Enter a valid amount > 0', 'Select a category', 'Transaction saved', 'Failed to save' |
| `analytics_screen.dart` | 'Analytics', 'Generate Demo Data', 'Cancel', 'Generate', demo data dialog text, 'Demo data generated! Pull to refresh.' |
| `settings_screen.dart` | 'Settings', 'Error: $error' |
| `appearance_section.dart` | 'Appearance', 'Theme', 'Select Theme', 'System', 'Light', 'Dark' |
| `security_section.dart` | 'Security', 'Biometric Lock', 'Use Face ID / fingerprint to unlock', 'Notifications', 'Budget alerts and sync notifications' |
| `data_management_section.dart` | 'Data Management', 'Export Backup', 'Create encrypted backup file', 'Import Backup', 'Restore from backup file', 'Delete All Data', 'Permanently delete all records', 'Cancel', 'Delete', success/failure snackbar messages |
| `password_dialog.dart` | 'Enter password', 'Confirm password', 'Password must be at least 8 characters', 'Passwords do not match', 'Cancel', 'OK' |
| `about_section.dart` | 'About', 'Version', '0.1.0', 'Privacy Policy', 'Open Source Licenses', 'Home Pocket' |

---

## Phase 1: Dependencies & Configuration

### Task 1.1: Add flutter_localizations and intl to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependencies**

In `pubspec.yaml`, add to the `dependencies:` section (after `cupertino_icons`):

```yaml
  # Internationalization
  flutter_localizations:
    sdk: flutter
  intl: 0.20.2
```

Also add `generate: true` under the `flutter:` section:

```yaml
flutter:
  uses-material-design: true
  generate: true
```

**Step 2: Run flutter pub get**

Run: `flutter pub get`
Expected: Dependencies resolve successfully. No version conflicts (intl 0.20.2 is compatible with flutter_localizations).

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_localizations and intl dependencies for i18n"
```

---

### Task 1.2: Create l10n.yaml configuration

**Files:**
- Create: `l10n.yaml` (project root)

**Step 1: Create l10n.yaml**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
```

**Step 2: Commit**

```bash
git add l10n.yaml
git commit -m "chore: add l10n.yaml for Flutter localization code generation"
```

---

## Phase 2: ARB Translation Files

### Task 2.1: Create English ARB file (template with @metadata)

**Files:**
- Create: `lib/l10n/app_en.arb`

**Step 1: Create the file**

This is the template file — only this file has `@metadata` entries per BASIC-003 spec.

```json
{
  "@@locale": "en",

  "appName": "Home Pocket",
  "@appName": { "description": "App title" },

  "home": "Home",
  "@home": { "description": "Home tab label" },

  "transactions": "Transactions",
  "@transactions": { "description": "Transactions tab/screen label" },

  "analytics": "Analytics",
  "@analytics": { "description": "Analytics tab/screen label" },

  "settings": "Settings",
  "@settings": { "description": "Settings tab/screen label" },

  "ledger": "Ledger",
  "@ledger": { "description": "Ledger tab label" },

  "newTransaction": "New Transaction",
  "@newTransaction": { "description": "New transaction screen title" },

  "amount": "Amount",
  "@amount": { "description": "Amount field label" },

  "category": "Category",
  "@category": { "description": "Category field label" },

  "note": "Note",
  "@note": { "description": "Note field label" },

  "merchant": "Merchant",
  "@merchant": { "description": "Merchant field label" },

  "date": "Date",
  "@date": { "description": "Date field label" },

  "transactionTypeExpense": "Expense",
  "@transactionTypeExpense": { "description": "Expense transaction type" },

  "transactionTypeIncome": "Income",
  "@transactionTypeIncome": { "description": "Income transaction type" },

  "categoryFood": "Food",
  "@categoryFood": { "description": "Food category" },

  "categoryHousing": "Housing",
  "@categoryHousing": { "description": "Housing category" },

  "categoryTransport": "Transport",
  "@categoryTransport": { "description": "Transport category" },

  "categoryUtilities": "Utilities",
  "@categoryUtilities": { "description": "Utilities category" },

  "categoryEntertainment": "Entertainment",
  "@categoryEntertainment": { "description": "Entertainment category" },

  "categoryEducation": "Education",
  "@categoryEducation": { "description": "Education category" },

  "categoryHealth": "Health",
  "@categoryHealth": { "description": "Health category" },

  "categoryShopping": "Shopping",
  "@categoryShopping": { "description": "Shopping category" },

  "categoryOther": "Other",
  "@categoryOther": { "description": "Other category" },

  "survivalLedger": "Survival Ledger",
  "@survivalLedger": { "description": "Survival ledger label" },

  "soulLedger": "Soul Ledger",
  "@soulLedger": { "description": "Soul ledger label" },

  "survival": "Survival",
  "@survival": { "description": "Short survival label" },

  "soul": "Soul",
  "@soul": { "description": "Short soul label" },

  "save": "Save",
  "@save": { "description": "Save action" },

  "cancel": "Cancel",
  "@cancel": { "description": "Cancel action" },

  "delete": "Delete",
  "@delete": { "description": "Delete action" },

  "edit": "Edit",
  "@edit": { "description": "Edit action" },

  "confirm": "Confirm",
  "@confirm": { "description": "Confirm action" },

  "ok": "OK",
  "@ok": { "description": "OK action" },

  "retry": "Retry",
  "@retry": { "description": "Retry action" },

  "search": "Search",
  "@search": { "description": "Search action" },

  "filter": "Filter",
  "@filter": { "description": "Filter action" },

  "sort": "Sort",
  "@sort": { "description": "Sort action" },

  "refresh": "Refresh",
  "@refresh": { "description": "Refresh action" },

  "loading": "Loading...",
  "@loading": { "description": "Loading state text" },

  "noData": "No data available",
  "@noData": { "description": "Empty state text" },

  "today": "Today",
  "@today": { "description": "Today label" },

  "yesterday": "Yesterday",
  "@yesterday": { "description": "Yesterday label" },

  "daysAgo": "{count} days ago",
  "@daysAgo": {
    "description": "N days ago relative date",
    "placeholders": { "count": { "type": "int" } }
  },

  "errorNetwork": "Network error",
  "@errorNetwork": { "description": "Network error" },

  "errorUnknown": "An unknown error occurred",
  "@errorUnknown": { "description": "Unknown error" },

  "errorInvalidAmount": "Invalid amount",
  "@errorInvalidAmount": { "description": "Invalid amount error" },

  "errorRequired": "This field is required",
  "@errorRequired": { "description": "Required field error" },

  "errorInvalidDate": "Invalid date",
  "@errorInvalidDate": { "description": "Invalid date error" },

  "errorDatabaseWrite": "Database write error",
  "@errorDatabaseWrite": { "description": "Database write error" },

  "errorDatabaseRead": "Database read error",
  "@errorDatabaseRead": { "description": "Database read error" },

  "errorEncryption": "Encryption error",
  "@errorEncryption": { "description": "Encryption error" },

  "errorSync": "Sync error",
  "@errorSync": { "description": "Sync error" },

  "errorBiometric": "Biometric error",
  "@errorBiometric": { "description": "Biometric error" },

  "errorPermission": "Permission error",
  "@errorPermission": { "description": "Permission error" },

  "errorMinAmount": "Please enter an amount of at least {min}",
  "@errorMinAmount": {
    "description": "Minimum amount error",
    "placeholders": { "min": { "type": "double" } }
  },

  "errorMaxAmount": "Please enter an amount no greater than {max}",
  "@errorMaxAmount": {
    "description": "Maximum amount error",
    "placeholders": { "max": { "type": "double" } }
  },

  "successSaved": "Saved successfully",
  "@successSaved": { "description": "Save success" },

  "successDeleted": "Deleted successfully",
  "@successDeleted": { "description": "Delete success" },

  "successSynced": "Synced successfully",
  "@successSynced": { "description": "Sync success" },

  "merchantPlaceholder": "Enter merchant name",
  "@merchantPlaceholder": { "description": "Merchant placeholder" },

  "notePlaceholder": "Enter a note",
  "@notePlaceholder": { "description": "Note placeholder" },

  "noteOptional": "Note (optional)",
  "@noteOptional": { "description": "Optional note label" },

  "pleaseEnterAmount": "Please enter an amount",
  "@pleaseEnterAmount": { "description": "Amount prompt" },

  "amountMustBeGreaterThanZero": "Amount must be greater than zero",
  "@amountMustBeGreaterThanZero": { "description": "Amount validation" },

  "pleaseSelectCategory": "Please select a category",
  "@pleaseSelectCategory": { "description": "Category prompt" },

  "noTransactionsYet": "No transactions yet",
  "@noTransactionsYet": { "description": "Empty transaction list" },

  "tapToAddFirstTransaction": "Tap + to add your first transaction",
  "@tapToAddFirstTransaction": { "description": "Empty state hint" },

  "transactionSaved": "Transaction saved",
  "@transactionSaved": { "description": "Transaction save success" },

  "failedToSave": "Failed to save",
  "@failedToSave": { "description": "Save failure" },

  "appearance": "Appearance",
  "@appearance": { "description": "Appearance section title" },

  "theme": "Theme",
  "@theme": { "description": "Theme setting label" },

  "selectTheme": "Select Theme",
  "@selectTheme": { "description": "Theme dialog title" },

  "themeSystem": "System",
  "@themeSystem": { "description": "System theme" },

  "themeLight": "Light",
  "@themeLight": { "description": "Light theme" },

  "themeDark": "Dark",
  "@themeDark": { "description": "Dark theme" },

  "security": "Security",
  "@security": { "description": "Security section title" },

  "biometricLock": "Biometric Lock",
  "@biometricLock": { "description": "Biometric lock setting" },

  "biometricLockDescription": "Use Face ID / fingerprint to unlock",
  "@biometricLockDescription": { "description": "Biometric lock subtitle" },

  "notifications": "Notifications",
  "@notifications": { "description": "Notifications setting" },

  "notificationsDescription": "Budget alerts and sync notifications",
  "@notificationsDescription": { "description": "Notifications subtitle" },

  "dataManagement": "Data Management",
  "@dataManagement": { "description": "Data management section" },

  "exportBackup": "Export Backup",
  "@exportBackup": { "description": "Export backup action" },

  "exportBackupDescription": "Create encrypted backup file",
  "@exportBackupDescription": { "description": "Export subtitle" },

  "importBackup": "Import Backup",
  "@importBackup": { "description": "Import backup action" },

  "importBackupDescription": "Restore from backup file",
  "@importBackupDescription": { "description": "Import subtitle" },

  "deleteAllData": "Delete All Data",
  "@deleteAllData": { "description": "Delete all data action" },

  "deleteAllDataDescription": "Permanently delete all records",
  "@deleteAllDataDescription": { "description": "Delete all subtitle" },

  "deleteAllDataConfirmation": "This action cannot be undone. Are you sure you want to delete all data?",
  "@deleteAllDataConfirmation": { "description": "Delete all confirmation" },

  "allDataDeleted": "All data deleted",
  "@allDataDeleted": { "description": "Delete all success" },

  "deleteFailed": "Delete failed",
  "@deleteFailed": { "description": "Delete failure" },

  "backupExportedSuccessfully": "Backup exported successfully",
  "@backupExportedSuccessfully": { "description": "Export success" },

  "exportFailed": "Export failed",
  "@exportFailed": { "description": "Export failure" },

  "backupImportedSuccessfully": "Backup imported successfully",
  "@backupImportedSuccessfully": { "description": "Import success" },

  "importFailed": "Import failed",
  "@importFailed": { "description": "Import failure" },

  "setBackupPassword": "Set Backup Password",
  "@setBackupPassword": { "description": "Export password dialog title" },

  "enterBackupPassword": "Enter Backup Password",
  "@enterBackupPassword": { "description": "Import password dialog title" },

  "enterPassword": "Enter password",
  "@enterPassword": { "description": "Password hint" },

  "confirmPassword": "Confirm password",
  "@confirmPassword": { "description": "Confirm password hint" },

  "passwordMinLength": "Password must be at least 8 characters",
  "@passwordMinLength": { "description": "Password validation" },

  "passwordsDoNotMatch": "Passwords do not match",
  "@passwordsDoNotMatch": { "description": "Password mismatch" },

  "about": "About",
  "@about": { "description": "About section title" },

  "version": "Version",
  "@version": { "description": "Version label" },

  "privacyPolicy": "Privacy Policy",
  "@privacyPolicy": { "description": "Privacy policy link" },

  "openSourceLicenses": "Open Source Licenses",
  "@openSourceLicenses": { "description": "Licenses link" },

  "generateDemoData": "Generate Demo Data",
  "@generateDemoData": { "description": "Demo data action" },

  "generateDemoDataDescription": "This will create sample transactions for the last 3 months to showcase analytics features.",
  "@generateDemoDataDescription": { "description": "Demo data dialog text" },

  "generate": "Generate",
  "@generate": { "description": "Generate action" },

  "demoDataGenerated": "Demo data generated! Pull to refresh.",
  "@demoDataGenerated": { "description": "Demo data success" },

  "language": "Language",
  "@language": { "description": "Language setting label" },

  "languageJapanese": "Japanese",
  "@languageJapanese": { "description": "Japanese language option" },

  "languageEnglish": "English",
  "@languageEnglish": { "description": "English language option" },

  "languageChinese": "Chinese",
  "@languageChinese": { "description": "Chinese language option" },

  "error": "Error",
  "@error": { "description": "Error title" },

  "initializationError": "Failed to initialize app",
  "@initializationError": { "description": "Init error message" }
}
```

**Step 2: Verify JSON syntax**

Run: `dart run -- lib/l10n/app_en.arb` — this won't run but you can verify JSON with:

Run: `python3 -c "import json; json.load(open('lib/l10n/app_en.arb'))"`
Expected: No output (valid JSON)

---

### Task 2.2: Create Japanese ARB file

**Files:**
- Create: `lib/l10n/app_ja.arb`

**Step 1: Create the file**

Japanese translations (ja/zh files have keys + values only, NO @metadata):

```json
{
  "@@locale": "ja",

  "appName": "まもる家計簿",
  "home": "ホーム",
  "transactions": "取引",
  "analytics": "分析",
  "settings": "設定",
  "ledger": "帳簿",

  "newTransaction": "新しい取引",
  "amount": "金額",
  "category": "カテゴリ",
  "note": "メモ",
  "merchant": "店舗",
  "date": "日付",
  "transactionTypeExpense": "支出",
  "transactionTypeIncome": "収入",

  "categoryFood": "食費",
  "categoryHousing": "住居",
  "categoryTransport": "交通",
  "categoryUtilities": "光熱費",
  "categoryEntertainment": "娯楽",
  "categoryEducation": "教育",
  "categoryHealth": "医療",
  "categoryShopping": "買物",
  "categoryOther": "その他",

  "survivalLedger": "生存帳簿",
  "soulLedger": "魂帳簿",
  "survival": "生存",
  "soul": "魂",

  "save": "保存",
  "cancel": "キャンセル",
  "delete": "削除",
  "edit": "編集",
  "confirm": "確認",
  "ok": "OK",
  "retry": "再試行",
  "search": "検索",
  "filter": "フィルター",
  "sort": "並び替え",
  "refresh": "更新",

  "loading": "読み込み中...",
  "noData": "データがありません",
  "today": "今日",
  "yesterday": "昨日",
  "daysAgo": "{count}日前",

  "errorNetwork": "ネットワークエラー",
  "errorUnknown": "不明なエラーが発生しました",
  "errorInvalidAmount": "無効な金額です",
  "errorRequired": "必須項目です",
  "errorInvalidDate": "無効な日付です",
  "errorDatabaseWrite": "データベース書込エラー",
  "errorDatabaseRead": "データベース読取エラー",
  "errorEncryption": "暗号化エラー",
  "errorSync": "同期エラー",
  "errorBiometric": "生体認証エラー",
  "errorPermission": "権限エラー",
  "errorMinAmount": "{min}以上の金額を入力してください",
  "errorMaxAmount": "{max}以下の金額を入力してください",

  "successSaved": "保存しました",
  "successDeleted": "削除しました",
  "successSynced": "同期しました",

  "merchantPlaceholder": "店舗名を入力",
  "notePlaceholder": "メモを入力",
  "noteOptional": "メモ（任意）",
  "pleaseEnterAmount": "金額を入力してください",
  "amountMustBeGreaterThanZero": "金額は0より大きくしてください",
  "pleaseSelectCategory": "カテゴリを選択してください",

  "noTransactionsYet": "取引がまだありません",
  "tapToAddFirstTransaction": "＋をタップして最初の取引を追加",
  "transactionSaved": "取引を保存しました",
  "failedToSave": "保存に失敗しました",

  "appearance": "外観",
  "theme": "テーマ",
  "selectTheme": "テーマを選択",
  "themeSystem": "システム",
  "themeLight": "ライト",
  "themeDark": "ダーク",

  "security": "セキュリティ",
  "biometricLock": "生体認証ロック",
  "biometricLockDescription": "Face ID / 指紋認証でロック解除",
  "notifications": "通知",
  "notificationsDescription": "予算アラートと同期通知",

  "dataManagement": "データ管理",
  "exportBackup": "バックアップをエクスポート",
  "exportBackupDescription": "暗号化バックアップファイルを作成",
  "importBackup": "バックアップをインポート",
  "importBackupDescription": "バックアップファイルから復元",
  "deleteAllData": "全データを削除",
  "deleteAllDataDescription": "すべての記録を完全に削除",
  "deleteAllDataConfirmation": "この操作は取り消せません。すべてのデータを削除してもよろしいですか？",
  "allDataDeleted": "全データを削除しました",
  "deleteFailed": "削除に失敗しました",

  "backupExportedSuccessfully": "バックアップをエクスポートしました",
  "exportFailed": "エクスポートに失敗しました",
  "backupImportedSuccessfully": "バックアップをインポートしました",
  "importFailed": "インポートに失敗しました",

  "setBackupPassword": "バックアップパスワードを設定",
  "enterBackupPassword": "バックアップパスワードを入力",
  "enterPassword": "パスワードを入力",
  "confirmPassword": "パスワードを確認",
  "passwordMinLength": "パスワードは8文字以上にしてください",
  "passwordsDoNotMatch": "パスワードが一致しません",

  "about": "このアプリについて",
  "version": "バージョン",
  "privacyPolicy": "プライバシーポリシー",
  "openSourceLicenses": "オープンソースライセンス",

  "generateDemoData": "デモデータを生成",
  "generateDemoDataDescription": "過去3か月分のサンプル取引を作成し、分析機能をデモします。",
  "generate": "生成",
  "demoDataGenerated": "デモデータを生成しました！引っ張って更新してください。",

  "language": "言語",
  "languageJapanese": "日本語",
  "languageEnglish": "English",
  "languageChinese": "中文",

  "error": "エラー",
  "initializationError": "アプリの初期化に失敗しました"
}
```

---

### Task 2.3: Create Chinese ARB file

**Files:**
- Create: `lib/l10n/app_zh.arb`

**Step 1: Create the file**

```json
{
  "@@locale": "zh",

  "appName": "守护家计簿",
  "home": "首页",
  "transactions": "交易",
  "analytics": "分析",
  "settings": "设置",
  "ledger": "账本",

  "newTransaction": "新交易",
  "amount": "金额",
  "category": "分类",
  "note": "备注",
  "merchant": "商家",
  "date": "日期",
  "transactionTypeExpense": "支出",
  "transactionTypeIncome": "收入",

  "categoryFood": "餐饮",
  "categoryHousing": "住房",
  "categoryTransport": "交通",
  "categoryUtilities": "水电费",
  "categoryEntertainment": "娱乐",
  "categoryEducation": "教育",
  "categoryHealth": "医疗",
  "categoryShopping": "购物",
  "categoryOther": "其他",

  "survivalLedger": "生存账本",
  "soulLedger": "灵魂账本",
  "survival": "生存",
  "soul": "灵魂",

  "save": "保存",
  "cancel": "取消",
  "delete": "删除",
  "edit": "编辑",
  "confirm": "确认",
  "ok": "确定",
  "retry": "重试",
  "search": "搜索",
  "filter": "筛选",
  "sort": "排序",
  "refresh": "刷新",

  "loading": "加载中...",
  "noData": "暂无数据",
  "today": "今天",
  "yesterday": "昨天",
  "daysAgo": "{count}天前",

  "errorNetwork": "网络错误",
  "errorUnknown": "发生未知错误",
  "errorInvalidAmount": "无效金额",
  "errorRequired": "必填项",
  "errorInvalidDate": "无效日期",
  "errorDatabaseWrite": "数据库写入错误",
  "errorDatabaseRead": "数据库读取错误",
  "errorEncryption": "加密错误",
  "errorSync": "同步错误",
  "errorBiometric": "生物识别错误",
  "errorPermission": "权限错误",
  "errorMinAmount": "请输入至少{min}的金额",
  "errorMaxAmount": "请输入不超过{max}的金额",

  "successSaved": "保存成功",
  "successDeleted": "删除成功",
  "successSynced": "同步成功",

  "merchantPlaceholder": "请输入商家名称",
  "notePlaceholder": "请输入备注",
  "noteOptional": "备注（可选）",
  "pleaseEnterAmount": "请输入金额",
  "amountMustBeGreaterThanZero": "金额必须大于零",
  "pleaseSelectCategory": "请选择分类",

  "noTransactionsYet": "暂无交易记录",
  "tapToAddFirstTransaction": "点击 + 添加第一笔交易",
  "transactionSaved": "交易已保存",
  "failedToSave": "保存失败",

  "appearance": "外观",
  "theme": "主题",
  "selectTheme": "选择主题",
  "themeSystem": "跟随系统",
  "themeLight": "浅色",
  "themeDark": "深色",

  "security": "安全",
  "biometricLock": "生物识别锁",
  "biometricLockDescription": "使用面容/指纹解锁",
  "notifications": "通知",
  "notificationsDescription": "预算提醒和同步通知",

  "dataManagement": "数据管理",
  "exportBackup": "导出备份",
  "exportBackupDescription": "创建加密备份文件",
  "importBackup": "导入备份",
  "importBackupDescription": "从备份文件恢复",
  "deleteAllData": "删除所有数据",
  "deleteAllDataDescription": "永久删除所有记录",
  "deleteAllDataConfirmation": "此操作无法撤销。您确定要删除所有数据吗？",
  "allDataDeleted": "所有数据已删除",
  "deleteFailed": "删除失败",

  "backupExportedSuccessfully": "备份导出成功",
  "exportFailed": "导出失败",
  "backupImportedSuccessfully": "备份导入成功",
  "importFailed": "导入失败",

  "setBackupPassword": "设置备份密码",
  "enterBackupPassword": "输入备份密码",
  "enterPassword": "输入密码",
  "confirmPassword": "确认密码",
  "passwordMinLength": "密码至少需要8个字符",
  "passwordsDoNotMatch": "两次输入的密码不一致",

  "about": "关于",
  "version": "版本",
  "privacyPolicy": "隐私政策",
  "openSourceLicenses": "开源许可",

  "generateDemoData": "生成演示数据",
  "generateDemoDataDescription": "将创建过去3个月的示例交易，以展示分析功能。",
  "generate": "生成",
  "demoDataGenerated": "演示数据已生成！下拉刷新查看。",

  "language": "语言",
  "languageJapanese": "日本語",
  "languageEnglish": "English",
  "languageChinese": "中文",

  "error": "错误",
  "initializationError": "应用初始化失败"
}
```

---

### Task 2.4: Generate localization code

**Step 1: Run flutter gen-l10n**

Run: `flutter gen-l10n`
Expected: Generates `lib/generated/app_localizations.dart` and locale-specific files.

**Step 2: Verify generation**

Run: `ls lib/generated/`
Expected: `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ja.dart`, `app_localizations_zh.dart`

**Step 3: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb
git commit -m "feat(i18n): add ARB translation files for en, ja, zh (100+ keys)"
```

> **Note:** `lib/generated/` files should be in `.gitignore` (verify this). If not, add `lib/generated/` to `.gitignore`.

---

## Phase 3: DateFormatter (TDD)

### Task 3.1: Write DateFormatter tests

**Files:**
- Create: `test/unit/infrastructure/i18n/formatters/date_formatter_test.dart`

**Step 1: Write the failing tests**

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2026, 2, 6, 14, 30);
    const ja = Locale('ja');
    const en = Locale('en');
    const zh = Locale('zh');

    group('formatDate', () {
      test('formats Japanese date as yyyy/MM/dd', () {
        expect(DateFormatter.formatDate(testDate, ja), '2026/02/06');
      });

      test('formats English date as MM/dd/yyyy', () {
        expect(DateFormatter.formatDate(testDate, en), '02/06/2026');
      });

      test('formats Chinese date with year/month/day characters', () {
        expect(DateFormatter.formatDate(testDate, zh), '2026年02月06日');
      });

      test('falls back to English format for unknown locale', () {
        const ko = Locale('ko');
        expect(DateFormatter.formatDate(testDate, ko), '02/06/2026');
      });
    });

    group('formatDateTime', () {
      test('formats Japanese datetime with 24h time', () {
        expect(
          DateFormatter.formatDateTime(testDate, ja),
          '2026/02/06 14:30',
        );
      });

      test('formats English datetime with 12h AM/PM', () {
        expect(
          DateFormatter.formatDateTime(testDate, en),
          '02/06/2026 2:30 PM',
        );
      });

      test('formats Chinese datetime with 24h time', () {
        expect(
          DateFormatter.formatDateTime(testDate, zh),
          '2026年02月06日 14:30',
        );
      });
    });

    group('formatMonthYear', () {
      test('formats Japanese month-year', () {
        expect(DateFormatter.formatMonthYear(testDate, ja), '2026年2月');
      });

      test('formats English month-year', () {
        expect(DateFormatter.formatMonthYear(testDate, en), 'February 2026');
      });

      test('formats Chinese month-year', () {
        expect(DateFormatter.formatMonthYear(testDate, zh), '2026年2月');
      });
    });

    group('formatRelative', () {
      test('returns today label for same day', () {
        final now = DateTime.now();
        expect(DateFormatter.formatRelative(now, ja), '今日');
        expect(DateFormatter.formatRelative(now, en), 'Today');
        expect(DateFormatter.formatRelative(now, zh), '今天');
      });

      test('returns yesterday label for 1 day ago', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateFormatter.formatRelative(yesterday, ja), '昨日');
        expect(DateFormatter.formatRelative(yesterday, en), 'Yesterday');
        expect(DateFormatter.formatRelative(yesterday, zh), '昨天');
      });

      test('returns N days ago for 2-6 days', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        expect(DateFormatter.formatRelative(threeDaysAgo, ja), '3日前');
        expect(DateFormatter.formatRelative(threeDaysAgo, en), '3 days ago');
        expect(DateFormatter.formatRelative(threeDaysAgo, zh), '3天前');
      });

      test('falls back to formatDate for 7+ days', () {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        // Should return formatted date, not relative
        final result = DateFormatter.formatRelative(twoWeeksAgo, ja);
        expect(result, contains('/'));
      });
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/infrastructure/i18n/formatters/date_formatter_test.dart`
Expected: FAIL — `package:home_pocket/infrastructure/i18n/formatters/date_formatter.dart` not found.

---

### Task 3.2: Implement DateFormatter

**Files:**
- Create: `lib/infrastructure/i18n/formatters/date_formatter.dart`

**Step 1: Write the implementation**

```dart
import 'dart:ui';

import 'package:intl/intl.dart';

/// Locale-aware date formatting utility.
///
/// All methods are static. No instance creation needed.
/// See BASIC-003 spec for format patterns per locale.
class DateFormatter {
  DateFormatter._();

  /// Format date only (no time).
  ///
  /// - ja: 2026/02/06
  /// - zh: 2026年02月06日
  /// - en: 02/06/2026
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

  /// Format date + time.
  ///
  /// - ja: 2026/02/06 14:30 (24h)
  /// - zh: 2026年02月06日 14:30 (24h)
  /// - en: 02/06/2026 2:30 PM (12h)
  static String formatDateTime(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return DateFormat('yyyy/MM/dd HH:mm', locale.toString()).format(date);
      case 'zh':
        return DateFormat('yyyy年MM月dd日 HH:mm', locale.toString())
            .format(date);
      case 'en':
      default:
        return DateFormat('MM/dd/yyyy h:mm a', locale.toString()).format(date);
    }
  }

  /// Format month + year.
  ///
  /// - ja: 2026年2月
  /// - zh: 2026年2月
  /// - en: February 2026
  static String formatMonthYear(DateTime date, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
      case 'zh':
        return DateFormat('yyyy年M月', locale.toString()).format(date);
      case 'en':
      default:
        return DateFormat('MMMM yyyy', locale.toString()).format(date);
    }
  }

  /// Format relative time.
  ///
  /// - Same day: "Today" / "今日" / "今天"
  /// - Yesterday: "Yesterday" / "昨日" / "昨天"
  /// - 2-6 days: "N days ago" / "N日前" / "N天前"
  /// - 7+ days: falls back to formatDate()
  static String formatRelative(DateTime date, Locale locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return _getRelativeToday(locale);
    } else if (difference == 1) {
      return _getRelativeYesterday(locale);
    } else if (difference < 7) {
      return _getRelativeDaysAgo(difference, locale);
    } else {
      return formatDate(date, locale);
    }
  }

  static String _getRelativeToday(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '今日';
      case 'zh':
        return '今天';
      case 'en':
      default:
        return 'Today';
    }
  }

  static String _getRelativeYesterday(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '昨日';
      case 'zh':
        return '昨天';
      case 'en':
      default:
        return 'Yesterday';
    }
  }

  static String _getRelativeDaysAgo(int days, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return '$days日前';
      case 'zh':
        return '$days天前';
      case 'en':
      default:
        return '$days days ago';
    }
  }
}
```

**Step 2: Run tests to verify they pass**

Run: `flutter test test/unit/infrastructure/i18n/formatters/date_formatter_test.dart`
Expected: All tests PASS.

**Step 3: Commit**

```bash
git add lib/infrastructure/i18n/formatters/date_formatter.dart test/unit/infrastructure/i18n/formatters/date_formatter_test.dart
git commit -m "feat(i18n): add DateFormatter with locale-aware formatting (TDD)"
```

---

## Phase 4: NumberFormatter (TDD)

### Task 4.1: Write NumberFormatter tests

**Files:**
- Create: `test/unit/infrastructure/i18n/formatters/number_formatter_test.dart`

**Step 1: Write the failing tests**

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/formatters/number_formatter.dart';

void main() {
  group('NumberFormatter', () {
    const ja = Locale('ja');
    const en = Locale('en');
    const zh = Locale('zh');

    group('formatNumber', () {
      test('formats number with comma separators', () {
        expect(NumberFormatter.formatNumber(1234.56, en), '1,234.56');
      });

      test('formats with custom decimal places', () {
        expect(
          NumberFormatter.formatNumber(1234.5, en, decimals: 0),
          '1,235',
        );
      });
    });

    group('formatCurrency', () {
      test('formats JPY with yen symbol and 0 decimals', () {
        final result = NumberFormatter.formatCurrency(1235, 'JPY', ja);
        expect(result, contains('¥'));
        expect(result, contains('1,235'));
        // JPY has 0 decimal places
        expect(result.contains('.'), isFalse);
      });

      test('formats USD with dollar symbol and 2 decimals', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'USD', en);
        expect(result, contains('\$'));
        expect(result, contains('1,234.56'));
      });

      test('formats CNY with yen symbol and 2 decimals', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'CNY', zh);
        expect(result, contains('¥'));
        expect(result, contains('1,234.56'));
      });

      test('formats EUR with euro symbol', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'EUR', en);
        expect(result, contains('€'));
      });

      test('formats GBP with pound symbol', () {
        final result = NumberFormatter.formatCurrency(1234.56, 'GBP', en);
        expect(result, contains('£'));
      });
    });

    group('formatPercentage', () {
      test('formats decimal as percentage', () {
        expect(NumberFormatter.formatPercentage(0.156, en), '15.60%');
      });

      test('formats with custom decimals', () {
        expect(
          NumberFormatter.formatPercentage(0.156, en, decimals: 0),
          '16%',
        );
      });

      test('formats zero percent', () {
        expect(NumberFormatter.formatPercentage(0.0, en), '0.00%');
      });
    });

    group('formatCompact', () {
      test('formats Japanese numbers with 万 for 10000+', () {
        expect(NumberFormatter.formatCompact(12345, ja), contains('万'));
      });

      test('formats Chinese numbers with 万 for 10000+', () {
        expect(NumberFormatter.formatCompact(12345, zh), contains('万'));
      });

      test('formats English with K for 1000+', () {
        final result = NumberFormatter.formatCompact(12345, en);
        expect(result, contains('K'));
      });

      test('does not use 万 below 10000 for Japanese', () {
        expect(NumberFormatter.formatCompact(9999, ja), isNot(contains('万')));
      });
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart`
Expected: FAIL — `package:home_pocket/infrastructure/i18n/formatters/number_formatter.dart` not found.

---

### Task 4.2: Implement NumberFormatter

**Files:**
- Create: `lib/infrastructure/i18n/formatters/number_formatter.dart`

**Step 1: Write the implementation**

```dart
import 'dart:ui';

import 'package:intl/intl.dart';

/// Locale-aware number and currency formatting utility.
///
/// All methods are static. No instance creation needed.
/// See BASIC-003 spec for currency rules and compact number formats.
class NumberFormatter {
  NumberFormatter._();

  /// Format number with thousand separators.
  ///
  /// [decimals] controls decimal places (default 2).
  static String formatNumber(num number, Locale locale, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: decimals,
    );
    return formatter.format(number);
  }

  /// Format as currency with symbol.
  ///
  /// Currency rules (per BASIC-003):
  /// - JPY: ¥1,235 (0 decimals)
  /// - CNY: ¥1,234.56 (2 decimals)
  /// - USD: $1,234.56 (2 decimals)
  /// - EUR: €1,234.56 (2 decimals)
  /// - GBP: £1,234.56 (2 decimals)
  static String formatCurrency(
    num amount,
    String currencyCode,
    Locale locale,
  ) {
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: _getCurrencyDecimals(currencyCode),
    );
    return formatter.format(amount);
  }

  /// Format as percentage.
  ///
  /// [value] is a ratio (0.0 - 1.0).
  /// Example: 0.156 → "15.60%"
  static String formatPercentage(
    double value,
    Locale locale, {
    int decimals = 2,
  }) {
    final percentage = value * 100;
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Format compact number.
  ///
  /// - ja/zh: Uses 万 (10,000) unit for numbers >= 10,000
  /// - en: Uses K, M, B via intl compact formatter
  static String formatCompact(num number, Locale locale) {
    if (locale.languageCode == 'ja' || locale.languageCode == 'zh') {
      if (number >= 10000) {
        final manValue = number / 10000;
        final formatted = formatNumber(
          manValue,
          locale,
          decimals: manValue >= 100 ? 0 : 1,
        );
        return '$formatted万';
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
}
```

**Step 2: Run tests to verify they pass**

Run: `flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart`
Expected: All tests PASS.

**Step 3: Commit**

```bash
git add lib/infrastructure/i18n/formatters/number_formatter.dart test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
git commit -m "feat(i18n): add NumberFormatter with currency/compact support (TDD)"
```

---

## Phase 5: LocaleSettings Model (TDD)

### Task 5.1: Write LocaleSettings tests

**Files:**
- Create: `test/unit/infrastructure/i18n/models/locale_settings_test.dart`

**Step 1: Write the failing tests**

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/i18n/models/locale_settings.dart';

void main() {
  group('LocaleSettings', () {
    test('defaultSettings returns Japanese locale', () {
      final settings = LocaleSettings.defaultSettings();
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('fromSystem with supported locale uses it', () {
      final settings = LocaleSettings.fromSystem(const Locale('en'));
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('fromSystem with Chinese locale uses it', () {
      final settings = LocaleSettings.fromSystem(const Locale('zh'));
      expect(settings.locale, const Locale('zh'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('fromSystem with unsupported locale falls back to Japanese', () {
      final settings = LocaleSettings.fromSystem(const Locale('ko'));
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('fromSystem with French locale falls back to Japanese', () {
      final settings = LocaleSettings.fromSystem(const Locale('fr'));
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('copyWith preserves existing values', () {
      final original = LocaleSettings.defaultSettings();
      final copied = original.copyWith(locale: const Locale('en'));
      expect(copied.locale, const Locale('en'));
      expect(copied.isSystemDefault, original.isSystemDefault);
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/infrastructure/i18n/models/locale_settings_test.dart`
Expected: FAIL — file not found.

---

### Task 5.2: Implement LocaleSettings model

**Files:**
- Create: `lib/infrastructure/i18n/models/locale_settings.dart`

**Step 1: Write the implementation**

```dart
import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_settings.freezed.dart';

/// Locale settings model for the app.
///
/// Per BASIC-003: supported locales are ja, zh, en.
/// Falls back to Japanese for unsupported system locales.
@freezed
class LocaleSettings with _$LocaleSettings {
  const factory LocaleSettings({
    required Locale locale,
    required bool isSystemDefault,
  }) = _LocaleSettings;

  /// Default: Japanese, not system default.
  factory LocaleSettings.defaultSettings() => const LocaleSettings(
        locale: Locale('ja'),
        isSystemDefault: false,
      );

  /// Create from system locale with fallback.
  factory LocaleSettings.fromSystem(Locale systemLocale) {
    const supportedCodes = ['ja', 'zh', 'en'];
    final normalizedCode = supportedCodes.contains(systemLocale.languageCode)
        ? systemLocale.languageCode
        : 'ja';
    return LocaleSettings(
      locale: Locale(normalizedCode),
      isSystemDefault: true,
    );
  }
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates `locale_settings.freezed.dart`.

**Step 3: Run tests to verify they pass**

Run: `flutter test test/unit/infrastructure/i18n/models/locale_settings_test.dart`
Expected: All tests PASS.

**Step 4: Commit**

```bash
git add lib/infrastructure/i18n/models/locale_settings.dart lib/infrastructure/i18n/models/locale_settings.freezed.dart test/unit/infrastructure/i18n/models/locale_settings_test.dart
git commit -m "feat(i18n): add LocaleSettings Freezed model with fallback logic (TDD)"
```

> **Note:** We commit `.freezed.dart` here because the project currently tracks generated files. If `.gitignore` excludes them, omit from `git add`.

---

## Phase 6: LocaleNotifierProvider (TDD)

### Task 6.1: Write LocaleNotifier tests

**Files:**
- Create: `test/unit/features/settings/presentation/providers/locale_provider_test.dart`

**Step 1: Write the failing tests**

```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/infrastructure/i18n/models/locale_settings.dart';

void main() {
  group('LocaleNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is Japanese default', () {
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('setLocale changes to English', () {
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('setLocale changes to Chinese', () {
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('zh'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('zh'));
    });

    test('setSystemDefault uses system locale', () {
      container
          .read(localeNotifierProvider.notifier)
          .setSystemDefault(const Locale('en'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('setSystemDefault falls back for unsupported locale', () {
      container
          .read(localeNotifierProvider.notifier)
          .setSystemDefault(const Locale('ko'));
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('ja'));
      expect(settings.isSystemDefault, isTrue);
    });

    test('resetToDefault restores Japanese', () {
      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      container.read(localeNotifierProvider.notifier).resetToDefault();
      final settings = container.read(localeNotifierProvider);
      expect(settings.locale, const Locale('ja'));
    });
  });

  group('currentLocaleProvider', () {
    test('returns locale from LocaleNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentLocaleProvider), const Locale('ja'));

      container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      expect(container.read(currentLocaleProvider), const Locale('en'));
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/features/settings/presentation/providers/locale_provider_test.dart`
Expected: FAIL — `locale_provider.dart` not found.

---

### Task 6.2: Implement LocaleNotifierProvider

**Files:**
- Create: `lib/features/settings/presentation/providers/locale_provider.dart`

**Step 1: Write the implementation**

```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../infrastructure/i18n/models/locale_settings.dart';

part 'locale_provider.g.dart';

/// Manages the app's locale settings.
///
/// Initial state: Japanese default.
/// See BASIC-003 for provider dependency chain.
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  LocaleSettings build() {
    return LocaleSettings.defaultSettings();
  }

  /// Switch to a specific locale.
  void setLocale(Locale locale) {
    state = LocaleSettings(
      locale: locale,
      isSystemDefault: false,
    );
  }

  /// Follow the system locale (with fallback).
  void setSystemDefault(Locale systemLocale) {
    state = LocaleSettings.fromSystem(systemLocale);
  }

  /// Reset to Japanese default.
  void resetToDefault() {
    state = LocaleSettings.defaultSettings();
  }
}

/// Convenience provider for the current Locale object.
@riverpod
Locale currentLocale(Ref ref) {
  final settings = ref.watch(localeNotifierProvider);
  return settings.locale;
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates `locale_provider.g.dart`.

**Step 3: Run tests to verify they pass**

Run: `flutter test test/unit/features/settings/presentation/providers/locale_provider_test.dart`
Expected: All tests PASS.

**Step 4: Commit**

```bash
git add lib/features/settings/presentation/providers/locale_provider.dart test/unit/features/settings/presentation/providers/locale_provider_test.dart
git commit -m "feat(i18n): add LocaleNotifier and currentLocaleProvider (TDD)"
```

---

## Phase 7: MaterialApp Wiring

### Task 7.1: Wire localization delegates into MaterialApp

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add imports**

At the top of `lib/main.dart`, add:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/settings/presentation/providers/locale_provider.dart';
import 'generated/app_localizations.dart';
```

**Step 2: Add localization delegates and locale to MaterialApp**

In the `build()` method of `_HomePocketAppState`, modify the `MaterialApp` widget:

```dart
    // Before the return MaterialApp, add:
    final locale = ref.watch(currentLocaleProvider);

    return MaterialApp(
      title: 'Home Pocket',
      // Add these 3 properties:
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      // existing theme, darkTheme, themeMode...
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: _buildHome(),
    );
```

**Step 3: Verify the app builds**

Run: `flutter analyze`
Expected: No errors related to localization.

**Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(i18n): wire localization delegates and locale into MaterialApp"
```

---

## Phase 8: UI String Migration

Migrate all hardcoded strings to `S.of(context)` screen by screen.

### Task 8.1: Migrate MainShellScreen

**Files:**
- Modify: `lib/features/home/presentation/screens/main_shell_screen.dart`

**Step 1: Update the file**

Replace the hardcoded `BottomNavigationBarItem` labels:

```dart
import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../dual_ledger/presentation/screens/dual_ledger_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main navigation shell with BottomNavigationBar.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DualLedgerScreen(bookId: widget.bookId),
          AnalyticsScreen(bookId: widget.bookId),
          SettingsScreen(bookId: widget.bookId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: l10n.ledger,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Verify**

Run: `flutter analyze`
Expected: No warnings.

---

### Task 8.2: Migrate DualLedgerScreen

**Files:**
- Modify: `lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart`

**Step 1: Add import and replace hardcoded strings**

Add at top: `import '../../../../generated/app_localizations.dart';`

Replace in `build()`:
- `title: const Text('Home Pocket')` → `title: Text(S.of(context).appName)`
- `text: 'Survival'` → `text: S.of(context).survival`
- `text: 'Soul'` → `text: S.of(context).soul`

Remove `const` from `Tab` widgets since `S.of(context)` is not const.

---

### Task 8.3: Migrate TransactionListScreen

**Files:**
- Modify: `lib/features/accounting/presentation/screens/transaction_list_screen.dart`

**Step 1: Add import and replace strings**

Add at top: `import '../../../../generated/app_localizations.dart';`

Replace:
- `'No transactions yet'` → `S.of(context).noTransactionsYet`
- `'Tap + to add your first transaction'` → `S.of(context).tapToAddFirstTransaction`
- `title: const Text('Transactions')` → `title: Text(S.of(context).transactions)`

---

### Task 8.4: Migrate TransactionFormScreen

**Files:**
- Modify: `lib/features/accounting/presentation/screens/transaction_form_screen.dart`

**Step 1: Add import and replace strings**

Add at top: `import '../../../../generated/app_localizations.dart';`

Replace:
- `'New Transaction'` → `S.of(context).newTransaction`
- `labelText: 'Amount'` → `labelText: S.of(context).amount`
- `label: Text('Expense')` → `label: Text(S.of(context).transactionTypeExpense)`
- `label: Text('Income')` → `label: Text(S.of(context).transactionTypeIncome)`
- `'Category'` → `S.of(context).category`
- `'Note (optional)'` → `S.of(context).noteOptional`
- `'Save'` → `S.of(context).save`
- `'Enter a valid amount > 0'` → `S.of(context).amountMustBeGreaterThanZero`
- `'Select a category'` → `S.of(context).pleaseSelectCategory`
- `Text('Transaction saved')` → `Text(S.of(context).transactionSaved)`
- `Text(result.error ?? 'Failed to save')` → `Text(result.error ?? S.of(context).failedToSave)`

---

### Task 8.5: Migrate AnalyticsScreen

**Files:**
- Modify: `lib/features/analytics/presentation/screens/analytics_screen.dart`

**Step 1: Add import and replace strings**

Add at top: `import '../../../../generated/app_localizations.dart';`

Replace:
- `title: const Text('Analytics')` → `title: Text(S.of(context).analytics)`
- `tooltip: 'Generate Demo Data'` → `tooltip: S.of(context).generateDemoData`
- `title: const Text('Generate Demo Data')` → `title: Text(S.of(context).generateDemoData)`
- Demo dialog content → `Text(S.of(context).generateDemoDataDescription)`
- `child: const Text('Cancel')` → `child: Text(S.of(context).cancel)`
- `child: const Text('Generate')` → `child: Text(S.of(context).generate)`
- `Text('Demo data generated! Pull to refresh.')` → `Text(S.of(context).demoDataGenerated)`

---

### Task 8.6: Migrate SettingsScreen + all sections

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/features/settings/presentation/widgets/appearance_section.dart`
- Modify: `lib/features/settings/presentation/widgets/security_section.dart`
- Modify: `lib/features/settings/presentation/widgets/data_management_section.dart`
- Modify: `lib/features/settings/presentation/widgets/password_dialog.dart`
- Modify: `lib/features/settings/presentation/widgets/about_section.dart`

**Step 1: settings_screen.dart**

Add import: `import '../../../../generated/app_localizations.dart';`

Replace:
- `title: const Text('Settings')` → `title: Text(S.of(context).settings)`

**Step 2: appearance_section.dart**

Add import: `import '../../../../generated/app_localizations.dart';`

Replace:
- `'Appearance'` → `S.of(context).appearance`
- `'Theme'` → `S.of(context).theme`
- `'Select Theme'` → `S.of(context).selectTheme`
- `'System'` → `S.of(context).themeSystem`
- `'Light'` → `S.of(context).themeLight`
- `'Dark'` → `S.of(context).themeDark`

**Step 3: security_section.dart**

Add import: `import '../../../../generated/app_localizations.dart';`

Replace:
- `'Security'` → `S.of(context).security`
- `'Biometric Lock'` → `S.of(context).biometricLock`
- `'Use Face ID / fingerprint to unlock'` → `S.of(context).biometricLockDescription`
- `'Notifications'` → `S.of(context).notifications`
- `'Budget alerts and sync notifications'` → `S.of(context).notificationsDescription`

**Step 4: data_management_section.dart**

Add import: `import '../../../../generated/app_localizations.dart';`

Replace all hardcoded strings with their `S.of(context)` equivalents:
- `'Data Management'` → `S.of(context).dataManagement`
- `'Export Backup'` → `S.of(context).exportBackup`
- `'Create encrypted backup file'` → `S.of(context).exportBackupDescription`
- `'Import Backup'` → `S.of(context).importBackup`
- `'Restore from backup file'` → `S.of(context).importBackupDescription`
- `'Delete All Data'` → `S.of(context).deleteAllData`
- `'Permanently delete all records'` → `S.of(context).deleteAllDataDescription`
- Delete confirmation text → `S.of(context).deleteAllDataConfirmation`
- `'Cancel'` → `S.of(context).cancel`
- `'Delete'` → `S.of(context).delete`
- `'Backup exported successfully'` → `S.of(context).backupExportedSuccessfully`
- `'Backup imported successfully'` → `S.of(context).backupImportedSuccessfully`
- `'All data deleted'` → `S.of(context).allDataDeleted`
- `result.error ?? 'Export failed'` → `result.error ?? S.of(context).exportFailed`
- `result.error ?? 'Import failed'` → `result.error ?? S.of(context).importFailed`
- `result.error ?? 'Delete failed'` → `result.error ?? S.of(context).deleteFailed`

**Step 5: password_dialog.dart**

Add import: `import '../../../../generated/app_localizations.dart';`

Replace:
- `'Enter password'` → `S.of(context).enterPassword`
- `'Confirm password'` → `S.of(context).confirmPassword`
- `'Password must be at least 8 characters'` → `S.of(context).passwordMinLength`
- `'Passwords do not match'` → `S.of(context).passwordsDoNotMatch`
- `'Cancel'` → `S.of(context).cancel`
- `'OK'` → `S.of(context).ok`

**Note:** `_PasswordDialog` is a `StatefulWidget` — use `S.of(context)` in `build()` method only (context available there). For `_submit()` which sets `_errorText` as a String, either:
- Store the error key and resolve in build, OR
- Accept that error strings are set pre-localization and resolve at display time

Simplest approach: keep `_errorText` as a localized string by using `S.of(context)` in `_submit()` since `context` is available via `this.context` in State.

**Step 6: about_section.dart**

Add import: `import '../../../../generated/app_localizations.dart';`

Replace:
- `'About'` → `S.of(context).about`
- `'Version'` → `S.of(context).version`
- `'Privacy Policy'` → `S.of(context).privacyPolicy`
- `'Open Source Licenses'` → `S.of(context).openSourceLicenses`
- `applicationName: 'Home Pocket'` → `applicationName: S.of(context).appName`

Change `AboutSection` from `StatelessWidget` to accept `BuildContext` in its methods, OR convert to use the context in `build()` directly (it already has access via the build parameter).

---

### Task 8.7: Verify all migrations compile

**Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: 0 issues found.

**Step 2: Run all tests**

Run: `flutter test`
Expected: All existing tests pass. (Some widget tests may need localization delegates added — see Phase 9.)

**Step 3: Commit**

```bash
git add lib/features/ lib/generated/
git commit -m "feat(i18n): migrate all UI screens from hardcoded strings to S.of(context)"
```

---

## Phase 9: Test Helper & Widget Test Updates

### Task 9.1: Create localization test helper

**Files:**
- Create: `test/helpers/test_localizations.dart`

**Step 1: Write the helper**

Widget tests that use `S.of(context)` need localization delegates. Create a reusable wrapper:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/generated/app_localizations.dart';

/// Wraps a widget with MaterialApp + localization delegates for testing.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(
///   createLocalizedWidget(const MyWidget()),
/// );
/// ```
Widget createLocalizedWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}
```

> **Note:** Adjust the import path for `app_localizations.dart` based on your test runner's package resolution. You may need `import 'package:home_pocket/generated/app_localizations.dart';` instead.

---

### Task 9.2: Update existing widget tests for localization

**Files to check and update:**
- `test/widget/features/dual_ledger/presentation/screens/dual_ledger_screen_test.dart`
- `test/widget/features/settings/presentation/widgets/password_dialog_test.dart`
- `test/widget/features/accounting/presentation/widgets/transaction_list_tile_test.dart`
- `test/widget/features/dual_ledger/presentation/widgets/soul_celebration_overlay_test.dart`

**Step 1: For each widget test that pumps a widget using localized strings**

Wrap the widget under test with the localization helper. Example pattern:

```dart
// BEFORE (will fail after migration):
await tester.pumpWidget(
  MaterialApp(
    home: DualLedgerScreen(bookId: 'test-book'),
  ),
);

// AFTER:
await tester.pumpWidget(
  createLocalizedWidget(
    DualLedgerScreen(bookId: 'test-book'),
  ),
);
```

**Step 2: Update text matchers**

If tests use `find.text('Survival')`, these still work since the English ARB has the same strings. But verify each test.

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

**Step 4: Commit**

```bash
git add test/
git commit -m "test(i18n): update widget tests with localization delegates"
```

---

## Phase 10: Add .gitignore Entry for Generated Files

### Task 10.1: Verify .gitignore includes generated localization files

**Files:**
- Modify: `.gitignore` (if needed)

**Step 1: Check if lib/generated/ is already ignored**

Run: `grep -n "generated" .gitignore`

If NOT present, add:

```
# Localization generated files
lib/generated/
```

**Step 2: Commit if changed**

```bash
git add .gitignore
git commit -m "chore: add lib/generated/ to .gitignore for localization files"
```

---

## Phase 11: Final Verification

### Task 11.1: Full verification pass

**Step 1: Clean and regenerate everything**

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass.

**Step 4: Verify ARB key count parity**

Run: `python3 -c "import json; en=json.load(open('lib/l10n/app_en.arb')); ja=json.load(open('lib/l10n/app_ja.arb')); zh=json.load(open('lib/l10n/app_zh.arb')); en_keys=set(k for k in en if not k.startswith('@')); ja_keys=set(k for k in ja if not k.startswith('@')); zh_keys=set(k for k in zh if not k.startswith('@')); print(f'en:{len(en_keys)} ja:{len(ja_keys)} zh:{len(zh_keys)}'); missing_ja=en_keys-ja_keys; missing_zh=en_keys-zh_keys; print(f'Missing ja:{missing_ja}') if missing_ja else None; print(f'Missing zh:{missing_zh}') if missing_zh else None; print('All keys match!') if en_keys==ja_keys==zh_keys else print('MISMATCH!')"`

Expected: "All keys match!"

**Step 5: Verify no hardcoded UI strings remain**

Run: `grep -rn "const Text('" lib/features/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart" | grep -v "test"`

Review any remaining `const Text('...')` — they should all be either:
- Non-user-facing (e.g., version numbers from variables)
- Already migrated

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1.1-1.2 | Dependencies + l10n.yaml config |
| 2 | 2.1-2.4 | ARB files (en template, ja, zh) + code gen |
| 3 | 3.1-3.2 | DateFormatter (TDD) |
| 4 | 4.1-4.2 | NumberFormatter (TDD) |
| 5 | 5.1-5.2 | LocaleSettings Freezed model (TDD) |
| 6 | 6.1-6.2 | LocaleNotifierProvider (TDD) |
| 7 | 7.1 | MaterialApp wiring |
| 8 | 8.1-8.7 | UI string migration (7 screens/widgets) |
| 9 | 9.1-9.2 | Test helper + widget test updates |
| 10 | 10.1 | .gitignore for generated files |
| 11 | 11.1 | Full verification |

**Estimated Total:** 19 tasks, ~2-3 hours

---
