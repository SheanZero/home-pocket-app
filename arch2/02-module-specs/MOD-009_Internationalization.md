# MOD-014: 国际化多语言支持 - 技术设计文档

**模块编号:** MOD-014
**模块名称:** 国际化多语言支持 (i18n)
**文档版本:** 1.0
**创建日期:** 2026-02-03
**预估工时:** 4天
**优先级:** P0（MVP核心功能）
**依赖项:** 所有UI模块

---

## 📋 目录

1. [模块概述](#模块概述)
2. [业务价值](#业务价值)
3. [核心功能](#核心功能)
4. [技术设计](#技术设计)
5. [数据模型](#数据模型)
6. [核心实现流程](#核心实现流程)
7. [UI组件设计](#ui组件设计)
8. [测试策略](#测试策略)
9. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

国际化多语言支持模块为应用提供三种语言的完整支持：

- **中文 (zh):** 简体中文支持
- **日文 (ja):** 日语支持（默认语言）
- **英文 (en):** 英语支持

### 核心特性

- ✅ 基于Flutter intl的完整i18n方案
- ✅ 运行时语言切换，无需重启
- ✅ 支持复数、性别、日期格式化
- ✅ 自动检测系统语言
- ✅ 持久化用户语言偏好
- ✅ 所有UI文案国际化
- ✅ 错误消息本地化
- ✅ 货币和数字格式化

---

## 技术设计

### 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                 Presentation Layer                       │
│                                                          │
│  Widgets consume AppLocalizations                       │
│  Text(AppLocalizations.of(context).welcomeMessage)      │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              AppLocalizations                            │
│         (Generated from ARB files)                       │
│                                                          │
│  • AppLocalizations_ja (日語)                            │
│  • AppLocalizations_zh (中文)                            │
│  • AppLocalizations_en (English)                         │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                  ARB Files                               │
│                                                          │
│  • lib/l10n/app_ja.arb  (日語 - 模板)                    │
│  • lib/l10n/app_zh.arb  (中文翻译)                       │
│  • lib/l10n/app_en.arb  (English translation)            │
└──────────────────────────────────────────────────────────┘
```

### 依赖配置

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  flutter_gen: ^5.3.2

flutter:
  generate: true  # 启用代码生成

# l10n.yaml 配置
arb-dir: lib/l10n
template-arb-file: app_ja.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
```

---

## 数据模型

### 支持的语言

```dart
// lib/core/i18n/supported_locales.dart

import 'package:flutter/material.dart';

/// 应用支持的语言列表
class SupportedLocales {
  static const Locale japanese = Locale('ja');
  static const Locale chinese = Locale('zh');
  static const Locale english = Locale('en');

  static const List<Locale> all = [
    japanese,   // 日语（默认）
    chinese,    // 中文
    english,    // 英语
  ];

  static const Locale fallback = japanese;

  /// 根据语言代码获取Locale
  static Locale fromCode(String code) {
    return all.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => fallback,
    );
  }

  /// 获取语言显示名称
  static String getDisplayName(String code) {
    switch (code) {
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  /// 获取语言图标
  static String getFlag(String code) {
    switch (code) {
      case 'ja':
        return '🇯🇵';
      case 'zh':
        return '🇨🇳';
      case 'en':
        return '🇺🇸';
      default:
        return '🌐';
    }
  }
}
```

### 语言设置模型

```dart
// lib/core/i18n/language_settings.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'language_settings.freezed.dart';
part 'language_settings.g.dart';

@freezed
class LanguageSettings with _$LanguageSettings {
  const factory LanguageSettings({
    required String languageCode,
    @Default(false) bool useSystemLanguage,
  }) = _LanguageSettings;

  factory LanguageSettings.fromJson(Map<String, dynamic> json) =>
      _$LanguageSettingsFromJson(json);
}

extension LanguageSettingsX on LanguageSettings {
  Locale get locale => Locale(languageCode);

  String get displayName => SupportedLocales.getDisplayName(languageCode);

  String get flag => SupportedLocales.getFlag(languageCode);
}
```

---

## 核心实现流程

### 1. ARB文件结构

#### app_ja.arb (日语 - 模板文件)

```json
{
  "@@locale": "ja",

  "_common": "===== 通用 =====",
  "appName": "ホームポケット",
  "ok": "OK",
  "cancel": "キャンセル",
  "save": "保存",
  "delete": "削除",
  "edit": "編集",
  "close": "閉じる",
  "back": "戻る",
  "next": "次へ",
  "confirm": "確認",
  "error": "エラー",
  "success": "成功",
  "loading": "読み込み中...",

  "_navigation": "===== ナビゲーション =====",
  "navHome": "ホーム",
  "navTransactions": "取引",
  "navAnalytics": "分析",
  "navSettings": "設定",

  "_transaction": "===== 取引記録 =====",
  "transactionTitle": "取引記録",
  "addTransaction": "取引を追加",
  "editTransaction": "取引を編集",
  "deleteTransaction": "取引を削除",
  "transactionAmount": "金額",
  "transactionCategory": "カテゴリ",
  "transactionNote": "メモ",
  "transactionDate": "日付",
  "transactionType": "種類",
  "transactionTypeExpense": "支出",
  "transactionTypeIncome": "収入",
  "transactionTypeTransfer": "振替",

  "_ledger": "===== 双轨账本 =====",
  "survivalLedger": "生存帳簿",
  "soulLedger": "精神帳簿",
  "survivalExpense": "生存支出",
  "soulExpense": "精神支出",
  "totalIncome": "総収入",
  "totalExpense": "総支出",
  "balance": "残高",

  "_category": "===== 分类 =====",
  "categoryManagement": "カテゴリ管理",
  "addCategory": "カテゴリを追加",
  "editCategory": "カテゴリを編集",
  "categoryName": "カテゴリ名",
  "categoryIcon": "アイコン",
  "categoryColor": "色",

  "_preset_categories_survival": "===== 预设分类 - 生存 =====",
  "catFoodGroceries": "食費（スーパー）",
  "catHousingRent": "住宅（家賃）",
  "catUtilities": "光熱費",
  "catTransportCommute": "交通費（通勤）",
  "catMedical": "医療費",
  "catInsurance": "保険",
  "catCommunication": "通信費",
  "catDailyGoods": "日用品",

  "_preset_categories_soul": "===== 预设分类 - 灵魂 =====",
  "catFoodRestaurant": "食費（外食）",
  "catEntertainment": "娯楽",
  "catHobby": "趣味",
  "catShoppingFashion": "ファッション",
  "catBeauty": "美容",
  "catTravel": "旅行",
  "catEducationHobby": "学習（趣味）",

  "_preset_categories_income": "===== 预设分类 - 收入 =====",
  "catIncomeSalary": "給料（月給）",
  "catIncomeBonus": "ボーナス",
  "catIncomeSidejob": "副業",
  "catIncomeInvestment": "投資収益",
  "catIncomeOther": "その他収入",

  "_analytics": "===== 数据分析 =====",
  "analyticsTitle": "データ分析",
  "monthlyReport": "月次レポート",
  "dailyAverage": "1日平均",
  "transactionCount": "取引数",
  "categoryBreakdown": "カテゴリ別内訳",

  "_sync": "===== 家庭同步 =====",
  "syncTitle": "家族同期",
  "pairDevice": "デバイスをペアリング",
  "syncNow": "今すぐ同期",
  "syncStatus": "同期状態",
  "lastSyncTime": "最終同期",
  "syncSuccess": "同期成功",
  "syncFailed": "同期失敗",

  "_settings": "===== 设置 =====",
  "settingsTitle": "設定",
  "appearance": "外観",
  "themeMode": "テーマモード",
  "themeModeSystem": "システムに従う",
  "themeModeLight": "ライト",
  "themeModeDark": "ダーク",
  "language": "言語",
  "dataManagement": "データ管理",
  "exportBackup": "バックアップをエクスポート",
  "importBackup": "バックアップをインポート",
  "deleteAllData": "すべてのデータを削除",
  "security": "セキュリティ",
  "biometricLock": "生体認証ロック",
  "notifications": "通知",
  "about": "について",
  "version": "バージョン",
  "privacyPolicy": "プライバシーポリシー",
  "licenses": "オープンソースライセンス",

  "_validation": "===== 验证消息 =====",
  "validationRequired": "必須項目です",
  "validationInvalidAmount": "無効な金額",
  "validationAmountTooLarge": "金額が大きすぎます",
  "validationSelectCategory": "カテゴリを選択してください",

  "_errors": "===== 错误消息 =====",
  "errorGeneric": "エラーが発生しました",
  "errorNetwork": "ネットワークエラー",
  "errorDatabaseAccess": "データベースアクセスエラー",
  "errorEncryption": "暗号化エラー",
  "errorDecryption": "復号化エラー",
  "errorInvalidPassword": "パスワードが正しくありません",
  "errorBackupFailed": "バックアップに失敗しました",
  "errorRestoreFailed": "復元に失敗しました",

  "_messages": "===== 成功消息 =====",
  "msgTransactionSaved": "取引を保存しました",
  "msgTransactionDeleted": "取引を削除しました",
  "msgBackupExported": "バックアップをエクスポートしました",
  "msgBackupImported": "バックアップをインポートしました",
  "msgSettingsSaved": "設定を保存しました",

  "_dialogs": "===== 对话框 =====",
  "dialogDeleteTitle": "削除の確認",
  "dialogDeleteMessage": "この操作は取り消せません。本当に削除しますか？",
  "dialogExportTitle": "バックアップパスワードを設定",
  "dialogImportTitle": "バックアップパスワードを入力",
  "dialogPasswordHint": "パスワードを入力",

  "_gamification": "===== 趣味功能 =====",
  "soulCelebration": "精神資産 +1 💖",
  "celebrationMsg1": "快楽値充能中 ⚡",
  "celebrationMsg2": "魂満足度 UP ✨",
  "celebrationMsg3": "これは自分への投資！🎉",
  "celebrationMsg4": "生活には小確幸が必要 🌟",
  "ohtaniConverter": "大谷翔平換算機"
}
```

#### app_zh.arb (中文翻译)

```json
{
  "@@locale": "zh",

  "_common": "===== 通用 =====",
  "appName": "家庭口袋",
  "ok": "确定",
  "cancel": "取消",
  "save": "保存",
  "delete": "删除",
  "edit": "编辑",
  "close": "关闭",
  "back": "返回",
  "next": "下一步",
  "confirm": "确认",
  "error": "错误",
  "success": "成功",
  "loading": "加载中...",

  "_navigation": "===== 导航 =====",
  "navHome": "首页",
  "navTransactions": "交易",
  "navAnalytics": "分析",
  "navSettings": "设置",

  "_transaction": "===== 交易记录 =====",
  "transactionTitle": "交易记录",
  "addTransaction": "添加交易",
  "editTransaction": "编辑交易",
  "deleteTransaction": "删除交易",
  "transactionAmount": "金额",
  "transactionCategory": "分类",
  "transactionNote": "备注",
  "transactionDate": "日期",
  "transactionType": "类型",
  "transactionTypeExpense": "支出",
  "transactionTypeIncome": "收入",
  "transactionTypeTransfer": "转账",

  "_ledger": "===== 双轨账本 =====",
  "survivalLedger": "生存账户",
  "soulLedger": "灵魂账户",
  "survivalExpense": "生存支出",
  "soulExpense": "灵魂支出",
  "totalIncome": "总收入",
  "totalExpense": "总支出",
  "balance": "余额",

  "_category": "===== 分类 =====",
  "categoryManagement": "分类管理",
  "addCategory": "添加分类",
  "editCategory": "编辑分类",
  "categoryName": "分类名称",
  "categoryIcon": "图标",
  "categoryColor": "颜色",

  "_preset_categories_survival": "===== 预设分类 - 生存 =====",
  "catFoodGroceries": "食品（超市）",
  "catHousingRent": "住房（房租）",
  "catUtilities": "水电费",
  "catTransportCommute": "交通费（通勤）",
  "catMedical": "医疗费",
  "catInsurance": "保险",
  "catCommunication": "通讯费",
  "catDailyGoods": "日用品",

  "_preset_categories_soul": "===== 预设分类 - 灵魂 =====",
  "catFoodRestaurant": "食品（外出就餐）",
  "catEntertainment": "娱乐",
  "catHobby": "爱好",
  "catShoppingFashion": "时尚购物",
  "catBeauty": "美容",
  "catTravel": "旅行",
  "catEducationHobby": "学习（爱好）",

  "_preset_categories_income": "===== 预设分类 - 收入 =====",
  "catIncomeSalary": "工资（月薪）",
  "catIncomeBonus": "奖金",
  "catIncomeSidejob": "副业",
  "catIncomeInvestment": "投资收益",
  "catIncomeOther": "其他收入",

  "_analytics": "===== 数据分析 =====",
  "analyticsTitle": "数据分析",
  "monthlyReport": "月度报告",
  "dailyAverage": "日均消费",
  "transactionCount": "交易笔数",
  "categoryBreakdown": "分类明细",

  "_sync": "===== 家庭同步 =====",
  "syncTitle": "家庭同步",
  "pairDevice": "配对设备",
  "syncNow": "立即同步",
  "syncStatus": "同步状态",
  "lastSyncTime": "最后同步",
  "syncSuccess": "同步成功",
  "syncFailed": "同步失败",

  "_settings": "===== 设置 =====",
  "settingsTitle": "设置",
  "appearance": "外观",
  "themeMode": "主题模式",
  "themeModeSystem": "跟随系统",
  "themeModeLight": "浅色",
  "themeModeDark": "深色",
  "language": "语言",
  "dataManagement": "数据管理",
  "exportBackup": "导出备份",
  "importBackup": "导入备份",
  "deleteAllData": "删除所有数据",
  "security": "安全",
  "biometricLock": "生物识别锁",
  "notifications": "通知",
  "about": "关于",
  "version": "版本",
  "privacyPolicy": "隐私政策",
  "licenses": "开源许可证",

  "_validation": "===== 验证消息 =====",
  "validationRequired": "此项为必填项",
  "validationInvalidAmount": "无效的金额",
  "validationAmountTooLarge": "金额过大",
  "validationSelectCategory": "请选择分类",

  "_errors": "===== 错误消息 =====",
  "errorGeneric": "发生错误",
  "errorNetwork": "网络错误",
  "errorDatabaseAccess": "数据库访问错误",
  "errorEncryption": "加密错误",
  "errorDecryption": "解密错误",
  "errorInvalidPassword": "密码错误",
  "errorBackupFailed": "备份失败",
  "errorRestoreFailed": "恢复失败",

  "_messages": "===== 成功消息 =====",
  "msgTransactionSaved": "交易已保存",
  "msgTransactionDeleted": "交易已删除",
  "msgBackupExported": "备份已导出",
  "msgBackupImported": "备份已导入",
  "msgSettingsSaved": "设置已保存",

  "_dialogs": "===== 对话框 =====",
  "dialogDeleteTitle": "确认删除",
  "dialogDeleteMessage": "此操作无法撤销。确定要删除吗？",
  "dialogExportTitle": "设置备份密码",
  "dialogImportTitle": "输入备份密码",
  "dialogPasswordHint": "请输入密码",

  "_gamification": "===== 趣味功能 =====",
  "soulCelebration": "精神资产 +1 💖",
  "celebrationMsg1": "快乐值充能中 ⚡",
  "celebrationMsg2": "灵魂满足度提升 ✨",
  "celebrationMsg3": "这是对自己的投资！🎉",
  "celebrationMsg4": "生活需要小确幸 🌟",
  "ohtaniConverter": "大谷翔平换算器"
}
```

#### app_en.arb (English translation)

```json
{
  "@@locale": "en",

  "_common": "===== Common =====",
  "appName": "Home Pocket",
  "ok": "OK",
  "cancel": "Cancel",
  "save": "Save",
  "delete": "Delete",
  "edit": "Edit",
  "close": "Close",
  "back": "Back",
  "next": "Next",
  "confirm": "Confirm",
  "error": "Error",
  "success": "Success",
  "loading": "Loading...",

  "_navigation": "===== Navigation =====",
  "navHome": "Home",
  "navTransactions": "Transactions",
  "navAnalytics": "Analytics",
  "navSettings": "Settings",

  "_transaction": "===== Transactions =====",
  "transactionTitle": "Transactions",
  "addTransaction": "Add Transaction",
  "editTransaction": "Edit Transaction",
  "deleteTransaction": "Delete Transaction",
  "transactionAmount": "Amount",
  "transactionCategory": "Category",
  "transactionNote": "Note",
  "transactionDate": "Date",
  "transactionType": "Type",
  "transactionTypeExpense": "Expense",
  "transactionTypeIncome": "Income",
  "transactionTypeTransfer": "Transfer",

  "_ledger": "===== Dual Ledger =====",
  "survivalLedger": "Survival Ledger",
  "soulLedger": "Soul Ledger",
  "survivalExpense": "Survival Expense",
  "soulExpense": "Soul Expense",
  "totalIncome": "Total Income",
  "totalExpense": "Total Expense",
  "balance": "Balance",

  "_category": "===== Categories =====",
  "categoryManagement": "Category Management",
  "addCategory": "Add Category",
  "editCategory": "Edit Category",
  "categoryName": "Category Name",
  "categoryIcon": "Icon",
  "categoryColor": "Color",

  "_preset_categories_survival": "===== Preset Categories - Survival =====",
  "catFoodGroceries": "Food (Groceries)",
  "catHousingRent": "Housing (Rent)",
  "catUtilities": "Utilities",
  "catTransportCommute": "Transport (Commute)",
  "catMedical": "Medical",
  "catInsurance": "Insurance",
  "catCommunication": "Communication",
  "catDailyGoods": "Daily Goods",

  "_preset_categories_soul": "===== Preset Categories - Soul =====",
  "catFoodRestaurant": "Food (Dining Out)",
  "catEntertainment": "Entertainment",
  "catHobby": "Hobby",
  "catShoppingFashion": "Fashion Shopping",
  "catBeauty": "Beauty",
  "catTravel": "Travel",
  "catEducationHobby": "Education (Hobby)",

  "_preset_categories_income": "===== Preset Categories - Income =====",
  "catIncomeSalary": "Salary (Monthly)",
  "catIncomeBonus": "Bonus",
  "catIncomeSidejob": "Side Job",
  "catIncomeInvestment": "Investment Income",
  "catIncomeOther": "Other Income",

  "_analytics": "===== Analytics =====",
  "analyticsTitle": "Analytics",
  "monthlyReport": "Monthly Report",
  "dailyAverage": "Daily Average",
  "transactionCount": "Transaction Count",
  "categoryBreakdown": "Category Breakdown",

  "_sync": "===== Family Sync =====",
  "syncTitle": "Family Sync",
  "pairDevice": "Pair Device",
  "syncNow": "Sync Now",
  "syncStatus": "Sync Status",
  "lastSyncTime": "Last Synced",
  "syncSuccess": "Sync Successful",
  "syncFailed": "Sync Failed",

  "_settings": "===== Settings =====",
  "settingsTitle": "Settings",
  "appearance": "Appearance",
  "themeMode": "Theme Mode",
  "themeModeSystem": "Follow System",
  "themeModeLight": "Light",
  "themeModeDark": "Dark",
  "language": "Language",
  "dataManagement": "Data Management",
  "exportBackup": "Export Backup",
  "importBackup": "Import Backup",
  "deleteAllData": "Delete All Data",
  "security": "Security",
  "biometricLock": "Biometric Lock",
  "notifications": "Notifications",
  "about": "About",
  "version": "Version",
  "privacyPolicy": "Privacy Policy",
  "licenses": "Open Source Licenses",

  "_validation": "===== Validation Messages =====",
  "validationRequired": "This field is required",
  "validationInvalidAmount": "Invalid amount",
  "validationAmountTooLarge": "Amount is too large",
  "validationSelectCategory": "Please select a category",

  "_errors": "===== Error Messages =====",
  "errorGeneric": "An error occurred",
  "errorNetwork": "Network error",
  "errorDatabaseAccess": "Database access error",
  "errorEncryption": "Encryption error",
  "errorDecryption": "Decryption error",
  "errorInvalidPassword": "Incorrect password",
  "errorBackupFailed": "Backup failed",
  "errorRestoreFailed": "Restore failed",

  "_messages": "===== Success Messages =====",
  "msgTransactionSaved": "Transaction saved",
  "msgTransactionDeleted": "Transaction deleted",
  "msgBackupExported": "Backup exported",
  "msgBackupImported": "Backup imported",
  "msgSettingsSaved": "Settings saved",

  "_dialogs": "===== Dialogs =====",
  "dialogDeleteTitle": "Confirm Deletion",
  "dialogDeleteMessage": "This action cannot be undone. Are you sure you want to delete?",
  "dialogExportTitle": "Set Backup Password",
  "dialogImportTitle": "Enter Backup Password",
  "dialogPasswordHint": "Enter password",

  "_gamification": "===== Gamification =====",
  "soulCelebration": "Soul Asset +1 💖",
  "celebrationMsg1": "Charging happiness ⚡",
  "celebrationMsg2": "Soul satisfaction UP ✨",
  "celebrationMsg3": "This is an investment in yourself! 🎉",
  "celebrationMsg4": "Life needs small joys 🌟",
  "ohtaniConverter": "Ohtani Converter"
}
```

### 2. App配置

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/i18n/supported_locales.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_manager.dart';

class HomePocketApp extends ConsumerWidget {
  const HomePocketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Home Pocket',

      // 国际化配置
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: SupportedLocales.all,
      locale: locale,

      // 主题配置
      theme: ThemeManager.lightTheme,
      darkTheme: ThemeManager.darkTheme,
      themeMode: themeMode,

      // 路由配置
      routerConfig: router,

      // 调试配置
      debugShowCheckedModeBanner: false,
    );
  }
}

// Locale Provider
@riverpod
Locale locale(LocaleRef ref) {
  final settings = ref.watch(languageSettingsProvider).value;

  if (settings == null) {
    return SupportedLocales.fallback;
  }

  if (settings.useSystemLanguage) {
    // 获取系统语言
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

    // 检查是否支持系统语言
    final supported = SupportedLocales.all.firstWhere(
      (locale) => locale.languageCode == systemLocale.languageCode,
      orElse: () => SupportedLocales.fallback,
    );

    return supported;
  }

  return settings.locale;
}
```

### 3. 语言切换Provider

```dart
// lib/core/i18n/providers/language_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../language_settings.dart';
import '../supported_locales.dart';

part 'language_providers.g.dart';

/// 语言设置仓储
class LanguageRepository {
  final SharedPreferences _prefs;

  static const String _languageCodeKey = 'language_code';
  static const String _useSystemLanguageKey = 'use_system_language';

  LanguageRepository(this._prefs);

  /// 获取语言设置
  Future<LanguageSettings> getLanguageSettings() async {
    final languageCode = _prefs.getString(_languageCodeKey) ?? 'ja';
    final useSystemLanguage = _prefs.getBool(_useSystemLanguageKey) ?? true;

    return LanguageSettings(
      languageCode: languageCode,
      useSystemLanguage: useSystemLanguage,
    );
  }

  /// 设置语言
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_languageCodeKey, languageCode);
    await _prefs.setBool(_useSystemLanguageKey, false);
  }

  /// 设置使用系统语言
  Future<void> setUseSystemLanguage(bool useSystem) async {
    await _prefs.setBool(_useSystemLanguageKey, useSystem);
  }
}

@riverpod
LanguageRepository languageRepository(LanguageRepositoryRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return LanguageRepository(prefs);
}

@riverpod
Future<LanguageSettings> languageSettings(LanguageSettingsRef ref) async {
  final repo = ref.watch(languageRepositoryProvider);
  return await repo.getLanguageSettings();
}

/// 切换语言的Use Case
@riverpod
class LanguageController extends _$LanguageController {
  @override
  Future<LanguageSettings> build() async {
    final repo = ref.watch(languageRepositoryProvider);
    return await repo.getLanguageSettings();
  }

  /// 切换到指定语言
  Future<void> changeLanguage(String languageCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(languageRepositoryProvider);
      await repo.setLanguage(languageCode);
      return LanguageSettings(
        languageCode: languageCode,
        useSystemLanguage: false,
      );
    });
  }

  /// 切换到系统语言
  Future<void> useSystemLanguage() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(languageRepositoryProvider);
      final currentSettings = await repo.getLanguageSettings();
      await repo.setUseSystemLanguage(true);

      return currentSettings.copyWith(useSystemLanguage: true);
    });
  }
}
```

### 4. 语言选择UI组件

```dart
// lib/core/i18n/widgets/language_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../supported_locales.dart';
import '../providers/language_providers.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(languageControllerProvider);

    return settingsAsync.when(
      data: (settings) => ListTile(
        leading: const Icon(Icons.language),
        title: Text(l10n.language),
        subtitle: Text(settings.displayName),
        trailing: Text(
          settings.flag,
          style: const TextStyle(fontSize: 24),
        ),
        onTap: () => _showLanguageDialog(context, ref, settings),
      ),
      loading: () => const ListTile(
        leading: Icon(Icons.language),
        title: Text('Language'),
        trailing: CircularProgressIndicator(),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Language'),
        subtitle: Text('Error: $error'),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    LanguageSettings currentSettings,
  ) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 系统语言选项
            RadioListTile<bool>(
              title: Text(l10n.themeModeSystem),
              subtitle: const Text('Auto-detect'),
              value: true,
              groupValue: currentSettings.useSystemLanguage,
              onChanged: (value) async {
                if (value == true) {
                  await ref
                      .read(languageControllerProvider.notifier)
                      .useSystemLanguage();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            const Divider(),

            // 各语言选项
            ...SupportedLocales.all.map((locale) {
              final code = locale.languageCode;
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Text(
                      SupportedLocales.getFlag(code),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(SupportedLocales.getDisplayName(code)),
                  ],
                ),
                value: code,
                groupValue: currentSettings.useSystemLanguage
                    ? null
                    : currentSettings.languageCode,
                onChanged: (value) async {
                  if (value != null) {
                    await ref
                        .read(languageControllerProvider.notifier)
                        .changeLanguage(value);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
```

### 5. 使用示例

```dart
// lib/features/transaction/presentation/screens/transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionTitle),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.transactionAmount),
            trailing: const Text('¥1,000'),
          ),
          ListTile(
            title: Text(l10n.transactionCategory),
            trailing: Text(l10n.catFoodGroceries),
          ),
          ListTile(
            title: Text(l10n.transactionDate),
            trailing: Text(DateFormat.yMd(l10n.localeName).format(DateTime.now())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add transaction
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
      ),
    );
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/core/i18n/language_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('LanguageRepository', () {
    late LanguageRepository repository;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LanguageRepository(prefs);
    });

    test('getLanguageSettings returns default Japanese', () async {
      final settings = await repository.getLanguageSettings();

      expect(settings.languageCode, 'ja');
      expect(settings.useSystemLanguage, true);
    });

    test('setLanguage saves new language', () async {
      await repository.setLanguage('zh');

      final settings = await repository.getLanguageSettings();
      expect(settings.languageCode, 'zh');
      expect(settings.useSystemLanguage, false);
    });
  });
}
```

### Widget测试

```dart
// test/core/i18n/widgets/language_selector_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('LanguageSelector displays current language', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LanguageSelector(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.language), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
  });
}
```

---

## 性能优化

### 优化策略

1. **延迟加载翻译:**
   - 只加载当前语言的翻译
   - 避免加载所有语言

2. **缓存本地化:**
   - 使用`const`构造函数
   - 缓存常用翻译

3. **构建时生成:**
   - 使用flutter_gen生成类型安全的API
   - 编译时检查缺失翻译

---

## 验收标准

### 功能需求

- ✅ 支持中文、日文、英文三种语言
- ✅ 运行时切换语言无需重启
- ✅ 自动检测系统语言
- ✅ 持久化用户语言偏好
- ✅ 所有UI文案已国际化
- ✅ 日期、数字、货币格式本地化

### 性能需求

- ✅ 语言切换响应时间 < 500ms
- ✅ 翻译查找时间 < 1ms

---

## 开发时间线 (4天)

| 天数 | 任务 | 交付物 |
|------|------|--------|
| **第1天** | ARB文件创建 | 完成日语、中文、英文翻译 |
| **第2天** | 语言管理 | Repository、Provider实现 |
| **第3天** | UI集成 | 语言选择器、所有页面国际化 |
| **第4天** | 测试与优化 | 单元测试、Widget测试、性能优化 |

---

**文档状态:** 完成
**审核状态:** 待审核
**变更日志:**
- 2026-02-03: 创建国际化多语言支持模块技术文档
