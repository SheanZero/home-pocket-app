# Home Page Implementation Plan (v2)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Home Page UI as designed in `home.pen` (Node `Iyfgx`), with a global shell bottom navigation, localized strings, and real data from existing use cases.

**Architecture:** Global shell pattern — `MainShellScreen` owns the bottom nav bar and `IndexedStack`; `HomeScreen` is just the scrollable content for tab 0. All user-facing text goes through `S.of(context)` (ARB-backed). Currency via `intl`'s `NumberFormat`, dates via `DateFormat`. Providers reuse existing analytics/accounting use cases. "Thin Feature" pattern: no business logic inside `lib/features/home/`.

**Tech Stack:** Flutter 3.x, Riverpod 2.4+ codegen, Freezed, Drift/SQLCipher, Material 3, IBM Plex Sans, `intl: 0.20.2`, `flutter_localizations`.

**Design Reference:** Pencil `/Users/xinz/Documents/home.pen`, Node `Iyfgx`

**Color Scheme:**
| Role | Hex | Usage |
|------|-----|-------|
| Primary (整体布局) | `#8AB8DA` | Hero header, primary tint |
| Survival (生存帐本) | `#5A9CC8` | Survival metrics, active tab, FAB |
| Soul (灵魂帐本) | `#47B88A` | Soul metrics, progress bars |

---

## Review-Issue Fixes (v1 → v2)

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| 1 | Blocker | `execute(bookId)` — wrong signature | Use `execute(GetTransactionsParams(...))` |
| 2 | Blocker | Bottom nav inside HomeScreen — other tabs lose nav | Move nav to `MainShellScreen` shell; HomeScreen is content only |
| 3 | High | Committing `.g.dart` files | Removed from all `git add` commands |
| 4 | High | Hardcoded strings violate i18n | Phase 0 bootstraps `flutter_localizations` + ARB files; all widgets use `S.of(context)` |
| 5 | Bug | `${now.month - 1}月` → "0月" in January | Use `MonthComparison.previousMonth` from report (already handles rollover) |
| 6 | Medium | Tests lack provider overrides | All widget tests use `ProviderScope(overrides: [...])` with mock data |

---

## Phase 0: i18n Bootstrap

### Task 0.1: Add flutter_localizations, intl, and ARB files

**Why:** CLAUDE.md mandates `S.of(context)` for all user-facing text. No i18n infra exists today.

**Files:**
- Modify: `pubspec.yaml` (add deps)
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb` (template)
- Create: `lib/l10n/app_ja.arb`
- Create: `lib/l10n/app_zh.arb`

**Step 1: Add dependencies to pubspec.yaml**

```yaml
# In dependencies: section, add:
  flutter_localizations:
    sdk: flutter
  intl: 0.20.2
```

**Step 2: Create l10n.yaml at project root**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
```

**Step 3: Create ARB files with home page strings**

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appName": "Home Pocket",
  "@appName": { "description": "App title" },

  "homeMonthlyExpense": "Monthly Expenses",
  "@homeMonthlyExpense": { "description": "Home card title" },

  "homeSurvivalExpense": "Living Expenses",
  "@homeSurvivalExpense": { "description": "Survival ledger label" },

  "homeSoulExpense": "Joy Expenses",
  "@homeSoulExpense": { "description": "Soul ledger label" },

  "homeMonthComparison": "vs Last Month",
  "@homeMonthComparison": { "description": "Comparison header" },

  "homeSoulFullness": "Soul Fullness",
  "@homeSoulFullness": { "description": "Soul section title" },

  "homeSoulPercentLabel": "Soul spending ratio",
  "@homeSoulPercentLabel": { "description": "Metric label" },

  "homeHappinessROI": "Happiness ROI",
  "@homeHappinessROI": { "description": "Metric label" },

  "homeFamilyInviteTitle": "Invite Family",
  "@homeFamilyInviteTitle": { "description": "Banner title" },

  "homeFamilyInviteDesc": "Share your ledger with your partner",
  "@homeFamilyInviteDesc": { "description": "Banner description" },

  "homeTodayTitle": "Today's Records",
  "@homeTodayTitle": { "description": "Section title" },

  "homeTodayCount": "{count} items",
  "@homeTodayCount": { "description": "Transaction count", "placeholders": { "count": { "type": "int" } } },

  "homePersonalMode": "Personal Mode",
  "@homePersonalMode": { "description": "Mode badge" },

  "homeTabHome": "Home",
  "@homeTabHome": { "description": "Tab label" },

  "homeTabList": "List",
  "@homeTabList": { "description": "Tab label" },

  "homeTabChart": "Charts",
  "@homeTabChart": { "description": "Tab label" },

  "homeTabTodo": "Todo",
  "@homeTabTodo": { "description": "Tab label" },

  "homeMonthFormat": "{year}/{month}",
  "@homeMonthFormat": { "description": "Month display", "placeholders": { "year": { "type": "int" }, "month": { "type": "int" } } },

  "homeRecentSoulTransaction": "Recent: {merchant} ¥{amount}",
  "@homeRecentSoulTransaction": { "description": "Recent soul tx", "placeholders": { "merchant": { "type": "String" }, "amount": { "type": "int" } } },

  "homeSurvivalTag": "Survival",
  "@homeSurvivalTag": { "description": "Ledger type tag" },

  "homeSoulTag": "Soul",
  "@homeSoulTag": { "description": "Ledger type tag" },

  "homeMonthBadge": "This month {percent}%",
  "@homeMonthBadge": { "description": "Soul badge", "placeholders": { "percent": { "type": "int" } } }
}
```

```json
// lib/l10n/app_ja.arb
{
  "@@locale": "ja",
  "appName": "まもる家計簿",
  "homeMonthlyExpense": "今月の出費",
  "homeSurvivalExpense": "暮らしの支出",
  "homeSoulExpense": "ときめき支出",
  "homeMonthComparison": "先月比",
  "homeSoulFullness": "灵魂充盈度",
  "homeSoulPercentLabel": "本月灵魂支出占比",
  "homeHappinessROI": "快乐 ROI",
  "homeFamilyInviteTitle": "家族を招待する",
  "homeFamilyInviteDesc": "パートナーと家計簿を共有しよう",
  "homeTodayTitle": "今日の記録",
  "homeTodayCount": "{count}件",
  "homePersonalMode": "個人モード",
  "homeTabHome": "主画面",
  "homeTabList": "列表",
  "homeTabChart": "图表",
  "homeTabTodo": "待办事项",
  "homeMonthFormat": "{year}年{month}月",
  "homeRecentSoulTransaction": "最近一笔: {merchant} ¥{amount}",
  "homeSurvivalTag": "生存",
  "homeSoulTag": "灵魂",
  "homeMonthBadge": "本月 {percent}%"
}
```

```json
// lib/l10n/app_zh.arb
{
  "@@locale": "zh",
  "appName": "守护家计簿",
  "homeMonthlyExpense": "本月支出",
  "homeSurvivalExpense": "生存支出",
  "homeSoulExpense": "灵魂支出",
  "homeMonthComparison": "较上月",
  "homeSoulFullness": "灵魂充盈度",
  "homeSoulPercentLabel": "本月灵魂支出占比",
  "homeHappinessROI": "快乐 ROI",
  "homeFamilyInviteTitle": "邀请家人",
  "homeFamilyInviteDesc": "与伴侣共享家计簿",
  "homeTodayTitle": "今日记录",
  "homeTodayCount": "{count}条",
  "homePersonalMode": "个人模式",
  "homeTabHome": "主页",
  "homeTabList": "列表",
  "homeTabChart": "图表",
  "homeTabTodo": "待办事项",
  "homeMonthFormat": "{year}年{month}月",
  "homeRecentSoulTransaction": "最近一笔: {merchant} ¥{amount}",
  "homeSurvivalTag": "生存",
  "homeSoulTag": "灵魂",
  "homeMonthBadge": "本月 {percent}%"
}
```

**Step 4: Generate localization files**

Run: `flutter gen-l10n`

Expected: Creates `lib/generated/app_localizations.dart` and friends. These are generated files — do NOT commit them.

**Step 5: Verify generation**

Run: `ls lib/generated/`
Expected: `app_localizations.dart`, `app_localizations_en.dart`, etc.

**Step 6: Commit (source files only)**

```bash
git add pubspec.yaml l10n.yaml lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb
git commit -m "feat(i18n): bootstrap flutter_localizations with home page strings"
```

---

### Task 0.2: Wire up localization delegates in main.dart

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add imports and delegates**

In `lib/main.dart`, add:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
```

Update `MaterialApp` in `build()`:

```dart
return MaterialApp(
  title: 'Home Pocket',
  // ... theme ...
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  locale: const Locale('ja'), // Default to Japanese
  home: _buildHome(),
);
```

**Step 2: Run app to verify**

Run: `flutter run`
Expected: App starts without localization errors.

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(i18n): wire up localization delegates in main.dart"
```

---

## Phase 1: Theme Foundation

### Task 1.1: Create AppColors

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Test: `test/unit/core/theme/app_colors_test.dart`

**Step 1: Write the failing test**

```dart
// test/unit/core/theme/app_colors_test.dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is #8AB8DA', () {
      expect(AppColors.primary, const Color(0xFF8AB8DA));
    });
    test('survival is #5A9CC8', () {
      expect(AppColors.survival, const Color(0xFF5A9CC8));
    });
    test('soul is #47B88A', () {
      expect(AppColors.soul, const Color(0xFF47B88A));
    });
    test('background is #F1F7FD', () {
      expect(AppColors.background, const Color(0xFFF1F7FD));
    });
  });
}
```

**Step 2: Run test → FAIL**

Run: `flutter test test/unit/core/theme/app_colors_test.dart`

**Step 3: Implementation**

```dart
// lib/core/theme/app_colors.dart
import 'dart:ui';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF8AB8DA);
  static const survival = Color(0xFF5A9CC8);
  static const soul = Color(0xFF47B88A);

  // Backgrounds
  static const background = Color(0xFFF1F7FD);
  static const card = Color(0xFFFFFFFF);
  static const heroBackground = Color(0xFF8AB8DA);
  static const tabBarBackground = Color(0xFFF7FBFF);
  static const familyInviteBackground = Color(0xFFF4F9FE);

  // Text
  static const textPrimary = Color(0xFF2C2C2C);
  static const textSecondary = Color(0xFF9A9A9A);
  static const textMuted = Color(0xFF6B6B6B);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Survival tints
  static const survivalLight = Color(0x155A9CC8);
  static const survivalBorder = Color(0xFFD8E8F5);
  static const survivalBarBg = Color(0xFFD0DEE8);

  // Soul tints
  static const soulLight = Color(0xFFE8F8EF);
  static const soulCardBg = Color(0xFFF4FCF8);
  static const soulMetricBg1 = Color(0xFFE5F5ED);
  static const soulMetricBg2 = Color(0xFFD9F0E5);
  static const soulProgressBg = Color(0xFFD4EDDF);
  static const soulBadgeBg = Color(0xFFD4F0E2);
  static const soulTextDark = Color(0xFF2D8E68);

  // Misc
  static const divider = Color(0xFFD0DEE8);
  static const comparisonPositive = Color(0xFF6DB87A);
  static const fabGradientStart = Color(0xFF90C4E8);
  static const fabGradientEnd = Color(0xFF5A9CC8);
  static const fabShadow = Color(0x665A9CC8);
  static const ohtaniBackground = Color(0xFF2F5B78);
  static const ohtaniText = Color(0xFFEAF6FF);
  static const ohtaniClose = Color(0xFFB9CFDF);
  static const inactiveTab = Color(0xFFAAAAAA);
}
```

**Step 4: Run test → PASS**

**Step 5: Commit**

```bash
git add lib/core/theme/app_colors.dart test/unit/core/theme/app_colors_test.dart
git commit -m "feat(theme): add AppColors"
```

---

### Task 1.2: Create AppTextStyles

**Files:**
- Create: `lib/core/theme/app_text_styles.dart`
- Test: `test/unit/core/theme/app_text_styles_test.dart`

Same as v1 plan — no changes needed. Key styles: `headlineLarge(24/w600)`, `titleMedium(14/w600)`, `bodySmall(12/normal)`, `labelSmall(10/w500)`, `tabLabel(10/w500)`, all with `fontFamily: 'IBM Plex Sans'`.

**Step 5: Commit**

```bash
git add lib/core/theme/app_text_styles.dart test/unit/core/theme/app_text_styles_test.dart
git commit -m "feat(theme): add AppTextStyles"
```

---

### Task 1.3: Create AppTheme + integrate into main.dart

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Modify: `lib/main.dart` (replace inline theme)
- Test: `test/unit/core/theme/app_theme_test.dart`

Same as v1 plan. Replace `Colors.deepPurple` seed with `AppColors.primary`. Add `scaffoldBackgroundColor: AppColors.background`.

**Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/main.dart test/unit/core/theme/app_theme_test.dart
git commit -m "feat(theme): add AppTheme, integrate into main.dart"
```

---

## Phase 2: Shell Architecture

### Task 2.1: Create HomeBottomNavBar widget

**Files:**
- Create: `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart`
- Test: `test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart`

**Step 1: Write the failing test**

```dart
// test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';

// Minimal localization stub for testing
import '../helpers/test_localizations.dart';

void main() {
  group('HomeBottomNavBar', () {
    testWidgets('displays 4 tab labels from S.of(context)', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Japanese locale labels (from ARB)
      expect(find.text('主画面'), findsOneWidget);
      expect(find.text('列表'), findsOneWidget);
      expect(find.text('图表'), findsOneWidget);
      expect(find.text('待办事项'), findsOneWidget);
    });

    testWidgets('active tab uses survival blue', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('主画面'));
      expect(text.style?.color, AppColors.survival);
    });

    testWidgets('FAB calls onFabTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      expect(tapped, isTrue);
    });
  });
}
```

**Test helper** — Create `test/widget/features/home/helpers/test_localizations.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Wraps a widget with MaterialApp + localization delegates for testing.
Widget testLocalizedApp({required Widget child, Locale locale = const Locale('ja')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}
```

**Step 2: Run test → FAIL**

**Step 3: Implementation**

```dart
// lib/features/home/presentation/widgets/home_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tabs = [
      _Tab(Icons.home_outlined, Icons.home, l10n.homeTabHome),
      _Tab(Icons.list_outlined, Icons.list, l10n.homeTabList),
      _Tab(Icons.schedule, Icons.schedule, l10n.homeTabChart),
      _Tab(Icons.checklist, Icons.checklist, l10n.homeTabTodo),
    ];

    return Container(
      height: 90,
      color: AppColors.tabBarBackground,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 12, right: 12, bottom: 24),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isActive = i == currentIndex;
                final color = isActive ? AppColors.survival : AppColors.inactiveTab;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isActive ? tab.activeIcon : tab.icon, size: 24, color: color),
                        const SizedBox(height: 4),
                        Text(tab.label, style: AppTextStyles.tabLabel.copyWith(color: color)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // FAB
          Positioned(
            right: 20,
            top: -5,
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: AppColors.fabShadow, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
```

**Step 4: Run test → PASS**

**Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_bottom_nav_bar.dart test/widget/features/home/presentation/widgets/home_bottom_nav_bar_test.dart test/widget/features/home/helpers/test_localizations.dart
git commit -m "feat(home): add HomeBottomNavBar with localized labels and FAB"
```

---

### Task 2.2: Refactor MainShellScreen to own bottom nav globally

**Critical fix:** Bottom nav MUST be at the shell level so ALL tabs can navigate.

**Files:**
- Modify: `lib/features/home/presentation/screens/main_shell_screen.dart`
- Create: `lib/features/home/presentation/providers/home_providers.dart`
- Test: `test/widget/features/home/presentation/screens/main_shell_screen_test.dart`

**Step 1: Write the failing test**

```dart
// test/widget/features/home/presentation/screens/main_shell_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import '../../helpers/test_localizations.dart';

void main() {
  group('MainShellScreen', () {
    testWidgets('renders HomeBottomNavBar at shell level', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: testLocalizedApp(
            child: const MainShellScreen(bookId: 'test-book'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeBottomNavBar), findsOneWidget);
    });

    testWidgets('bottom nav persists across tab switches', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: testLocalizedApp(
            child: const MainShellScreen(bookId: 'test-book'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tab 1 ("列表")
      await tester.tap(find.text('列表'));
      await tester.pumpAndSettle();

      // Bottom nav still there
      expect(find.byType(HomeBottomNavBar), findsOneWidget);
      // Tab 1 content visible
      expect(find.text('列表'), findsWidgets); // tab label + possibly content
    });
  });
}
```

**Step 2: Run test → FAIL**

**Step 3: Create home_providers.dart**

```dart
// lib/features/home/presentation/providers/home_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

/// Currently selected tab index in the global bottom nav.
@Riverpod(keepAlive: true)
class SelectedTabIndex extends _$SelectedTabIndex {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

/// Whether the Ohtani converter banner is visible.
@riverpod
class OhtaniConverterVisible extends _$OhtaniConverterVisible {
  @override
  bool build() => true;

  void dismiss() => state = false;
}
```

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 4: Rewrite MainShellScreen**

```dart
// lib/features/home/presentation/screens/main_shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounting/presentation/screens/transaction_form_screen.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/home_providers.dart';
import '../widgets/home_bottom_nav_bar.dart';
import 'home_screen.dart';

/// Global navigation shell — owns the bottom nav bar.
///
/// All tab screens are children of this shell's [IndexedStack],
/// guaranteeing the nav bar is always visible regardless of
/// which tab is active.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: [
          HomeScreen(bookId: bookId),
          // Tab 1: Transaction list (reuse DualLedgerScreen or placeholder)
          const Scaffold(body: Center(child: Text('列表 — coming soon'))),
          AnalyticsScreen(bookId: bookId),
          // Tab 3: Todo (placeholder)
          const Scaffold(body: Center(child: Text('待办事项 — coming soon'))),
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: tabIndex,
        onTap: (i) => ref.read(selectedTabIndexProvider.notifier).select(i),
        onFabTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionFormScreen(bookId: bookId),
            ),
          );
        },
      ),
    );
  }
}
```

**Step 5: Run test → PASS**

**Step 6: Commit**

```bash
git add lib/features/home/presentation/screens/main_shell_screen.dart lib/features/home/presentation/providers/home_providers.dart
git commit -m "refactor(home): move bottom nav to MainShellScreen shell level"
```

---

## Phase 3: Home Widgets (all using S.of(context))

### Task 3.1: Create HeroHeader widget

**Files:**
- Create: `lib/features/home/presentation/widgets/hero_header.dart`
- Test: `test/widget/features/home/presentation/widgets/hero_header_test.dart`

**Step 1: Write the failing test**

```dart
// test/widget/features/home/presentation/widgets/hero_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import '../../helpers/test_localizations.dart';

void main() {
  group('HeroHeader', () {
    testWidgets('displays localized month format', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: HeroHeader(
              year: 2026,
              month: 2,
              onSettingsTap: () {},
              onDateTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Japanese format: "2026年2月"
      expect(find.text('2026年2月'), findsOneWidget);
    });

    testWidgets('settings icon triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            body: HeroHeader(
              year: 2026, month: 2,
              onSettingsTap: () => tapped = true,
              onDateTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(tapped, isTrue);
    });
  });
}
```

**Step 3: Implementation**

```dart
// lib/features/home/presentation/widgets/hero_header.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.year,
    required this.month,
    required this.onSettingsTap,
    required this.onDateTap,
  });

  final int year;
  final int month;
  final VoidCallback onSettingsTap;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.heroBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onDateTap,
                    child: Row(
                      children: [
                        Text(
                          l10n.homeMonthFormat(year, month),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textOnPrimary, size: 18),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textOnPrimary, size: 24),
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/hero_header.dart test/widget/features/home/presentation/widgets/hero_header_test.dart
git commit -m "feat(home): add HeroHeader with localized month format"
```

---

### Task 3.2: Create MonthOverviewCard widget

**Files:**
- Create: `lib/features/home/presentation/widgets/month_overview_card.dart`
- Test: `test/widget/features/home/presentation/widgets/month_overview_card_test.dart`

**Key changes from v1:**
- All labels via `S.of(context)` (`homeMonthlyExpense`, `homeSurvivalExpense`, etc.)
- Currency via `NumberFormat.currency(locale: ..., symbol: '¥', decimalDigits: 0)` from `intl`
- Previous month label from `MonthComparison.previousMonth` (not `now.month - 1`)

**Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';
import '../../helpers/test_localizations.dart';

void main() {
  group('MonthOverviewCard', () {
    testWidgets('displays localized total with NumberFormat', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 142800,
                survivalExpense: 102200,
                soulExpense: 40600,
                previousMonthTotal: 155700,
                currentMonthNumber: 2,
                previousMonthNumber: 1,
                modeBadgeText: '個人モード',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // NumberFormat with ¥ symbol, no decimals
      expect(find.text('¥142,800'), findsOneWidget);
    });

    testWidgets('uses localized section labels', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 142800,
                survivalExpense: 102200,
                soulExpense: 40600,
                previousMonthTotal: 155700,
                currentMonthNumber: 2,
                previousMonthNumber: 1,
                modeBadgeText: '個人モード',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // From app_ja.arb: homeMonthlyExpense = "今月の出費"
      expect(find.text('今月の出費'), findsOneWidget);
      // From app_ja.arb: homeMonthComparison = "先月比"
      expect(find.text('先月比'), findsOneWidget);
    });

    testWidgets('month labels use number not arithmetic', (tester) async {
      // January scenario: previousMonth should be 12, not 0
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: MonthOverviewCard(
                totalExpense: 50000,
                survivalExpense: 30000,
                soulExpense: 20000,
                previousMonthTotal: 60000,
                currentMonthNumber: 1,
                previousMonthNumber: 12, // Correctly passed as 12
                modeBadgeText: '個人モード',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
      // NOT "0月"
      expect(find.text('0月'), findsNothing);
    });
  });
}
```

**Step 3: Implementation highlights**

```dart
// In MonthOverviewCard widget:
import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';

// Parameters: currentMonthNumber and previousMonthNumber (ints from MonthComparison)
// NOT computed from now.month - 1

String _formatCurrency(int amount) {
  return NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(amount);
}

// In build():
final l10n = S.of(context);
// Title: l10n.homeMonthlyExpense
// Survival label: l10n.homeSurvivalExpense
// Soul label: l10n.homeSoulExpense
// Comparison header: l10n.homeMonthComparison
// Bar labels: '${currentMonthNumber}月' / '${previousMonthNumber}月'
```

**Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/month_overview_card.dart test/widget/features/home/presentation/widgets/month_overview_card_test.dart
git commit -m "feat(home): add MonthOverviewCard with intl currency and localized labels"
```

---

### Task 3.3: Create SoulFullnessCard widget

Same structure as v1 but with `S.of(context)` for all labels (`homeSoulFullness`, `homeSoulPercentLabel`, `homeHappinessROI`, `homeMonthBadge`, `homeRecentSoulTransaction`).

**Commit:**
```bash
git add lib/features/home/presentation/widgets/soul_fullness_card.dart test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart
git commit -m "feat(home): add SoulFullnessCard with localized labels"
```

---

### Task 3.4: Create FamilyInviteBanner widget

Uses `l10n.homeFamilyInviteTitle` and `l10n.homeFamilyInviteDesc`.

**Commit:**
```bash
git add lib/features/home/presentation/widgets/family_invite_banner.dart test/widget/features/home/presentation/widgets/family_invite_banner_test.dart
git commit -m "feat(home): add FamilyInviteBanner with localized text"
```

---

### Task 3.5: Create HomeTransactionTile widget

Same as v1 but uses `NumberFormat.currency(symbol: '¥', decimalDigits: 0)` for amount formatting. Category label is passed from parent (already resolved from category + ledger type).

**Commit:**
```bash
git add lib/features/home/presentation/widgets/home_transaction_tile.dart test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart
git commit -m "feat(home): add HomeTransactionTile with intl currency format"
```

---

### Task 3.6: Create OhtaniConverter widget

Same as v1. Text is fun/dynamic content — passed as parameter, not a fixed i18n key.

**Commit:**
```bash
git add lib/features/home/presentation/widgets/ohtani_converter.dart test/widget/features/home/presentation/widgets/ohtani_converter_test.dart
git commit -m "feat(home): add OhtaniConverter widget"
```

---

## Phase 4: Data Integration

### Task 4.1: Create today_transactions_provider with correct API

**Files:**
- Create: `lib/features/home/presentation/providers/today_transactions_provider.dart`
- Test: `test/unit/features/home/presentation/providers/today_transactions_provider_test.dart`

**Step 1: Write the failing test**

```dart
// test/unit/features/home/presentation/providers/today_transactions_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/use_case_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/today_transactions_provider.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactionsUseCase extends Mock implements GetTransactionsUseCase {}

void main() {
  late MockGetTransactionsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetTransactionsUseCase();
    registerFallbackValue(
      const GetTransactionsParams(bookId: 'test'),
    );
  });

  test('fetches today transactions using startDate/endDate params', () async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final testTx = Transaction(
      id: 'tx1',
      bookId: 'book1',
      deviceId: 'dev1',
      amount: 3280,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: now,
      currentHash: 'hash1',
      createdAt: now,
    );

    when(() => mockUseCase.execute(any())).thenAnswer(
      (_) async => Result.success([testTx]),
    );

    final container = ProviderContainer(
      overrides: [
        getTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );

    final result = await container.read(
      todayTransactionsProvider(bookId: 'book1').future,
    );

    expect(result, hasLength(1));
    expect(result.first.id, 'tx1');

    // Verify correct params were passed
    final captured = verify(() => mockUseCase.execute(captureAny())).captured;
    final params = captured.first as GetTransactionsParams;
    expect(params.bookId, 'book1');
    expect(params.startDate, todayStart);
    expect(params.endDate?.day, todayEnd.day);
  });
}
```

**Step 2: Run test → FAIL**

**Step 3: Implementation (correct API!)**

```dart
// lib/features/home/presentation/providers/today_transactions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/get_transactions_use_case.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/providers/use_case_providers.dart';

part 'today_transactions_provider.g.dart';

/// Fetches today's transactions for a given book.
///
/// Uses [GetTransactionsParams.startDate] and [endDate] to filter
/// at the repository level — no client-side filtering needed.
@riverpod
Future<List<Transaction>> todayTransactions(
  Ref ref, {
  required String bookId,
}) async {
  final useCase = ref.watch(getTransactionsUseCaseProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final result = await useCase.execute(
    GetTransactionsParams(
      bookId: bookId,
      startDate: todayStart,
      endDate: todayEnd,
    ),
  );

  if (result.isSuccess && result.data != null) {
    return result.data!.where((t) => !t.isDeleted).toList();
  }
  return [];
}
```

**Step 4: Run codegen**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Run test → PASS**

**Step 6: Commit (NO .g.dart)**

```bash
git add lib/features/home/presentation/providers/today_transactions_provider.dart test/unit/features/home/presentation/providers/today_transactions_provider_test.dart
git commit -m "feat(home): add todayTransactionsProvider with correct GetTransactionsParams API"
```

---

### Task 4.2: Create HomeScreen (content only, no bottom nav)

**Critical:** HomeScreen is ONLY the scrollable content. No `Scaffold`, no `bottomNavigationBar`. The parent `MainShellScreen` provides those.

**Files:**
- Create: `lib/features/home/presentation/screens/home_screen.dart`
- Test: `test/widget/features/home/presentation/screens/home_screen_test.dart`

**Step 1: Write the failing test WITH provider overrides**

```dart
// test/widget/features/home/presentation/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/today_transactions_provider.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';
import '../../helpers/test_localizations.dart';

void main() {
  // Stable mock data
  final mockReport = MonthlyReport(
    year: 2026,
    month: 2,
    totalIncome: 300000,
    totalExpenses: 142800,
    savings: 157200,
    savingsRate: 52.4,
    survivalTotal: 102200,
    soulTotal: 40600,
    categoryBreakdowns: [],
    dailyExpenses: [],
    previousMonthComparison: null,
  );

  group('HomeScreen', () {
    testWidgets('renders HeroHeader and MonthOverviewCard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the monthly report provider with static data
            monthlyReportProvider(bookId: 'test', year: 2026, month: 2)
                .overrideWith((_) async => mockReport),
            // Override today transactions with empty list
            todayTransactionsProvider(bookId: 'test')
                .overrideWith((_) async => <Transaction>[]),
          ],
          child: testLocalizedApp(
            child: const Scaffold(
              body: HomeScreen(bookId: 'test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HeroHeader), findsOneWidget);
      expect(find.byType(MonthOverviewCard), findsOneWidget);
    });

    testWidgets('does NOT contain a BottomNavigationBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyReportProvider(bookId: 'test', year: 2026, month: 2)
                .overrideWith((_) async => mockReport),
            todayTransactionsProvider(bookId: 'test')
                .overrideWith((_) async => <Transaction>[]),
          ],
          child: testLocalizedApp(
            child: const Scaffold(
              body: HomeScreen(bookId: 'test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // HomeScreen must NOT own the nav bar — MainShellScreen does
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
```

**Step 2: Run test → FAIL**

**Step 3: Implementation**

```dart
// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../providers/home_providers.dart';
import '../providers/today_transactions_provider.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/month_overview_card.dart';
import '../widgets/ohtani_converter.dart';
import '../widgets/soul_fullness_card.dart';

/// Home tab content — scrollable, no Scaffold, no bottom nav.
///
/// Rendered inside [MainShellScreen]'s IndexedStack.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final now = DateTime.now();
    final ohtaniVisible = ref.watch(ohtaniConverterVisibleProvider);

    final reportAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: now.year, month: now.month),
    );
    final todayAsync = ref.watch(
      todayTransactionsProvider(bookId: bookId),
    );

    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Hero header
          Positioned(
            top: 0, left: 0, right: 0, height: 250,
            child: HeroHeader(
              year: now.year,
              month: now.month,
              onSettingsTap: () {
                // Navigate to settings (handled by parent)
              },
              onDateTap: () {
                // Show month picker
              },
            ),
          ),

          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 110),

                // Month overview card
                reportAsync.when(
                  data: (report) {
                    final prevMonth = report.previousMonthComparison;
                    return MonthOverviewCard(
                      totalExpense: report.totalExpenses,
                      survivalExpense: report.survivalTotal,
                      soulExpense: report.soulTotal,
                      previousMonthTotal: prevMonth?.previousExpenses ?? 0,
                      currentMonthNumber: report.month,
                      previousMonthNumber: prevMonth?.previousMonth ?? (report.month == 1 ? 12 : report.month - 1),
                      modeBadgeText: l10n.homePersonalMode,
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // Soul fullness
                reportAsync.when(
                  data: (report) {
                    final soulPct = report.totalExpenses > 0
                        ? (report.soulTotal / report.totalExpenses * 100).round()
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SoulFullnessCard(
                        soulPercentage: soulPct,
                        happinessROI: 4.6,
                        fullnessLevel: 78,
                        recentMerchant: '书店',
                        recentAmount: 128,
                        recentQuote: '知识就是力量，也是快乐',
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 14),

                // Family invite
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FamilyInviteBanner(onTap: () {}),
                ),

                const SizedBox(height: 14),

                // Today's transactions
                _buildTodaySection(context, l10n, todayAsync),

                const SizedBox(height: 14),

                // Ohtani converter
                if (ohtaniVisible)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OhtaniConverter(
                      emoji: '🍚',
                      text: '6.6杯の牛丼を食べました',
                      onDismiss: () {
                        ref.read(ohtaniConverterVisibleProvider.notifier).dismiss();
                      },
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(
    BuildContext context,
    S l10n,
    AsyncValue<List<Transaction>> todayAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.homeTodayTitle,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary)),
              todayAsync.when(
                data: (txs) => Text(
                  l10n.homeTodayCount(txs.length),
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          todayAsync.when(
            data: (txs) => _buildTransactionList(txs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> txs) {
    if (txs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text('—',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < txs.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 66, color: AppColors.divider),
            HomeTransactionTile(
              merchant: txs[i].merchant ?? txs[i].categoryId,
              categoryLabel: _categoryLabel(txs[i]),
              formattedAmount: '-${formatter.format(txs[i].amount)}',
              ledgerType: txs[i].ledgerType,
              iconData: _iconForCategory(txs[i].categoryId),
            ),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(Transaction tx) {
    final tag = tx.ledgerType == LedgerType.soul ? '灵魂 💖' : '生存';
    return '${tx.categoryId} · $tag';
  }

  IconData _iconForCategory(String categoryId) {
    // Map common categories to icons
    const map = {
      'cat_food': Icons.shopping_cart,
      'cat_transport': Icons.train,
      'cat_shopping': Icons.shopping_bag,
      'cat_entertainment': Icons.gamepad,
      'cat_housing': Icons.home,
    };
    return map[categoryId] ?? Icons.receipt;
  }
}
```

**Important:** `HomeTransactionTile` now receives `formattedAmount` (String) instead of raw int — formatting is done by the parent using `NumberFormat`.

**Step 4: Run test → PASS**

**Step 5: Commit**

```bash
git add lib/features/home/presentation/screens/home_screen.dart test/widget/features/home/presentation/screens/home_screen_test.dart
git commit -m "feat(home): add HomeScreen as content-only scrollable view"
```

---

### Task 4.3: Update HomeTransactionTile to accept pre-formatted amount

Slight API change from v1: widget receives `formattedAmount: String` (already formatted by parent via `NumberFormat`), not a raw `int`.

```dart
// In HomeTransactionTile:
final String formattedAmount; // e.g. "-¥3,280"

// In build():
Text(formattedAmount, style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary)),
```

This keeps the widget dumb — no formatting logic inside.

**Commit:**
```bash
git add lib/features/home/presentation/widgets/home_transaction_tile.dart
git commit -m "refactor(home): HomeTransactionTile accepts pre-formatted amount"
```

---

## Phase 5: Polish

### Task 5.1: Add IBM Plex Sans font

**Option A (recommended):** Bundle font files

```yaml
# pubspec.yaml, under flutter:
flutter:
  uses-material-design: true
  fonts:
    - family: IBM Plex Sans
      fonts:
        - asset: assets/fonts/IBMPlexSans-Regular.ttf
        - asset: assets/fonts/IBMPlexSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/IBMPlexSans-Bold.ttf
          weight: 700
```

Download from Google Fonts, place in `assets/fonts/`.

**Option B:** Use `google_fonts` package (downloads at runtime).

**Commit:**
```bash
git add pubspec.yaml assets/fonts/
git commit -m "feat(theme): bundle IBM Plex Sans font"
```

---

### Task 5.2: Run full test suite + lint pass

**Step 1: Run codegen**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 2: Run l10n gen**

```bash
flutter gen-l10n
```

**Step 3: Run analyzer (must be 0 issues)**

```bash
flutter analyze
```

**Step 4: Run formatter**

```bash
dart format .
```

**Step 5: Run all tests**

```bash
flutter test
```

**Step 6: Fix any issues, then commit**

```bash
git add -A  # safe here — .g.dart and generated/ are gitignored
git commit -m "chore(home): pass lint + full test suite"
```

---

## Architecture Summary

```
MainShellScreen (owns bottom nav globally)
├── HomeBottomNavBar ← always visible
├── IndexedStack
│   ├── Tab 0: HomeScreen (scrollable content, no Scaffold)
│   │   ├── HeroHeader
│   │   ├── MonthOverviewCard ← monthlyReportProvider
│   │   ├── SoulFullnessCard
│   │   ├── FamilyInviteBanner
│   │   ├── Today Section ← todayTransactionsProvider
│   │   └── OhtaniConverter
│   ├── Tab 1: (DualLedgerScreen — future)
│   ├── Tab 2: AnalyticsScreen
│   └── Tab 3: (TodoScreen — future)
└── FAB → pushes TransactionFormScreen
```

**Data flow:**
```
MonthlyReport ← monthlyReportProvider(bookId, year, month)
             ← GetMonthlyReportUseCase.execute(bookId:, year:, month:)
             ← AnalyticsRepository

Today Transactions ← todayTransactionsProvider(bookId)
                   ← GetTransactionsUseCase.execute(GetTransactionsParams(
                        bookId: bookId,
                        startDate: todayStart,
                        endDate: todayEnd,
                     ))
                   ← TransactionRepository
```

**File inventory:**

| Phase | New Files | Modified Files |
|-------|-----------|----------------|
| Phase 0: i18n | 4 (l10n.yaml + 3 ARB) | 1 (pubspec, main.dart) |
| Phase 1: Theme | 3 (colors, text, theme) | 1 (main.dart) |
| Phase 2: Shell | 2 (nav bar, providers) | 1 (main_shell_screen) |
| Phase 3: Widgets | 6 widgets | 0 |
| Phase 4: Data | 2 (provider, screen) | 1 (transaction tile) |
| Phase 5: Polish | 1 (fonts) | 0 |
| Tests | ~14 test files + 1 helper | 0 |

**NO `.g.dart` or `lib/generated/` files committed** — all are gitignored.
