# Home Page i18n Keys

All user-facing strings in the Home Page feature are localized via `S.of(context)` with ARB-backed translations in 3 locales.

## Key Mapping

| Key | English (en) | Japanese (ja) | Chinese (zh) | Used In |
|-----|-------------|---------------|--------------|---------|
| `homeMonthlyExpense` | Monthly Expenses | 今月の出費 | 本月支出 | MonthOverviewCard |
| `homeSurvivalExpense` | Living Expenses | 暮らしの支出 | 生存支出 | MonthOverviewCard (metrics + legend) |
| `homeSoulExpense` | Joy Expenses | ときめき支出 | 灵魂支出 | MonthOverviewCard (metrics + legend) |
| `homeMonthComparison` | vs Last Month | 先月比 | 较上月 | MonthOverviewCard |
| `homeMonthLabel` | M{month} | {month}月 | {month}月 | MonthOverviewCard (bar chart labels) |
| `homeSoulFullness` | Soul Fullness | 魂の充実度 | 灵魂充盈度 | SoulFullnessCard |
| `homeSoulPercentLabel` | Soul spending ratio | 今月の魂支出の割合 | 本月灵魂支出占比 | SoulFullnessCard |
| `homeHappinessROI` | Happiness ROI | 幸せROI | 快乐 ROI | SoulFullnessCard |
| `homeSoulChargeStatus` | Soul Fullness {fullness}% / Happiness ROI {roi}x | 魂の充実度 {fullness}% · 幸せROI {roi}x | 灵魂充盈度 {fullness}% · 快乐ROI {roi}x | SoulFullnessCard (charge card) |
| `homeMonthBadge` | This month {percent}% | 今月 {percent}% | 本月 {percent}% | SoulFullnessCard (badge) |
| `homeRecentSoulTransaction` | Recent: {merchant} yen{amount} | 直近: {merchant} ¥{amount} | 最近一笔: {merchant} ¥{amount} | SoulFullnessCard |
| `homeFamilyInviteTitle` | Invite Family | 家族を招待する | 邀请家人 | FamilyInviteBanner |
| `homeFamilyInviteDesc` | Share your ledger with your partner | パートナーと家計簿を共有しよう | 与伴侣共享家计簿 | FamilyInviteBanner |
| `homeTodayTitle` | Today's Records | 今日の記録 | 今日记录 | (HomeScreen section header) |
| `homeTodayCount` | {count} items | {count}件 | {count}条 | (HomeScreen section header) |
| `homePersonalMode` | Personal Mode | 個人モード | 个人模式 | MonthOverviewCard (mode badge) |
| `homeTabHome` | Home | ホーム | 主页 | HomeBottomNavBar |
| `homeTabList` | List | 一覧 | 列表 | HomeBottomNavBar |
| `homeTabChart` | Charts | チャート | 图表 | HomeBottomNavBar |
| `homeTabTodo` | Todo | やること | 待办事项 | HomeBottomNavBar |
| `homeMonthFormat` | {year}/{month} | {year}年{month}月 | {year}年{month}月 | HeroHeader |

## Parameterized Keys

| Key | Parameters | Type |
|-----|-----------|------|
| `homeTodayCount` | `count` | `int` |
| `homeMonthFormat` | `year`, `month` | `int`, `int` |
| `homeMonthLabel` | `month` | `int` |
| `homeRecentSoulTransaction` | `merchant`, `amount` | `String`, `int` |
| `homeSoulChargeStatus` | `fullness`, `roi` | `int`, `double` |
| `homeMonthBadge` | `percent` | `int` |

## Widgets Without Hardcoded Strings

These widgets receive all text content via constructor parameters and do not need direct i18n:

- **HomeTransactionTile** -- merchant, categoryLabel, formattedAmount all injected
- **OhtaniConverter** -- emoji and text injected by parent

## ARB Files

- `lib/l10n/app_en.arb` -- English (template)
- `lib/l10n/app_ja.arb` -- Japanese
- `lib/l10n/app_zh.arb` -- Chinese (Simplified)

## Usage Pattern

```dart
import '../../../../generated/app_localizations.dart';

@override
Widget build(BuildContext context) {
  final l10n = S.of(context);
  return Text(l10n.homeMonthlyExpense);
}
```
