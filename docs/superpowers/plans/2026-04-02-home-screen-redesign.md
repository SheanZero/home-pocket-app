# Home Screen Wa-Modern Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the home screen (`home_screen.dart`) and all its widgets to match the Wa-Modern (和モダン) design from Pencil (nodes: `Psivj`, `7tgtB`, `LP8mE`, `rwQy7`).

**Architecture:** Replace the current blue-hero Stack layout with a flat vertical scroll. Update color tokens from blue (`#8AB8DA`) to warm ivory (`#FCFBF9`) + coral accent (`#E85A4F`). Font changes from IBM Plex Sans to Outfit. Decompose the screen into atomic widgets matching the Pencil node tree: header, section dividers, overview card, ledger comparison rows, soul fullness card, group bar, family invite banner, transaction list, and pill-style bottom nav.

**Tech Stack:** Flutter, Riverpod 2.4+, Freezed, Drift, Outfit font (Google Fonts fallback), intl for formatting.

**Design Reference:** `docs/design/design-system.md`, `docs/design/design-tokens.json`, `docs/design/flutter-color-mapping.dart`

---

## Scope Check

This plan covers a single subsystem: **Home tab UI** (Tab 0 within `MainShellScreen`). It does NOT cover dark theme implementation (Phase 2 follow-up), navigation logic changes, or other tabs. Dark theme colors are documented here for reference but NOT implemented in this plan.

---

## File Structure

### Files to Modify
| File | Responsibility | Lines (est.) |
|------|---------------|-------------|
| `lib/core/theme/app_colors.dart` | Replace ALL color tokens with Wa-Modern light palette + compat aliases | ~90 |
| `lib/core/theme/app_text_styles.dart` | Update font family to Outfit, add new type scale styles | ~120 |
| `lib/core/theme/app_theme.dart` | Update colorSchemeSeed, scaffold bg, appBar, fontFamily | ~25 |
| `lib/features/home/presentation/screens/home_screen.dart` | Rewrite: flat scroll layout, remove Stack/hero, wire new widgets | ~200 |
| `lib/features/home/presentation/screens/main_shell_screen.dart` | Update `bottomNavigationBar` to use new pill nav | ~75 |
| `lib/features/home/presentation/widgets/hero_header.dart` | Rewrite: flat header with month picker + family badge + settings | ~80 |
| `lib/features/home/presentation/widgets/month_overview_card.dart` | Rewrite: total amount + trend badge + last month row | ~120 |
| `lib/features/home/presentation/widgets/soul_fullness_card.dart` | Rewrite: title + 2 metric tiles + divider + recent spending | ~120 |
| `lib/features/home/presentation/widgets/home_transaction_tile.dart` | Rewrite: tag + merchant/category + amount row | ~70 |
| `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart` | Rewrite: floating pill nav + separate FAB | ~130 |
| `lib/features/home/presentation/widgets/family_invite_banner.dart` | Rewrite: vertical card with avatars + CTA button | ~100 |

### Files to Create
| File | Responsibility | Lines (est.) |
|------|---------------|-------------|
| `lib/features/home/domain/models/ledger_row_data.dart` | Freezed model for ledger comparison row data | ~35 |
| `lib/features/home/presentation/widgets/section_divider.dart` | Reusable "label ─── line" divider component | ~40 |
| `lib/features/home/presentation/widgets/ledger_comparison_section.dart` | 2-3 ledger rows (survival/soul/shared) | ~150 |
| `lib/features/home/presentation/widgets/group_bar.dart` | Family group bar with overlapping avatars | ~90 |
| `lib/features/home/presentation/widgets/member_avatar.dart` | Single circular avatar with initial letter | ~40 |
| `lib/features/home/presentation/widgets/transaction_list_card.dart` | Container for transaction rows with border + clip | ~80 |

### Files to Delete (after migration)
| File | Reason |
|------|--------|
| `lib/features/home/presentation/widgets/ohtani_converter.dart` | Not in new design |

### Test Localization Helper

**IMPORTANT:** All widget tests that render widgets using `S.of(context)` (i18n) MUST wrap in a `MaterialApp` with localization delegates. Create a shared test helper or add to every test:

```dart
MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  locale: const Locale('ja'),
  home: Scaffold(body: WidgetUnderTest()),
)
```

This applies to: HeroHeader, MonthOverviewCard, SoulFullnessCard, FamilyInviteBanner, HomeBottomNavBar, HomeScreen tests. Pure UI widgets that take only primitive params (SectionDivider, MemberAvatar, GroupBar, TransactionListCard) do NOT need this.

### Test Files to Create
| File | Tests |
|------|-------|
| `test/features/home/presentation/widgets/section_divider_test.dart` | Render, label display |
| `test/features/home/presentation/widgets/ledger_comparison_section_test.dart` | 2-row solo, 3-row group, colors |
| `test/features/home/presentation/widgets/group_bar_test.dart` | Render, avatar count, family name |
| `test/features/home/presentation/widgets/member_avatar_test.dart` | Initial letter, color, size |
| `test/features/home/presentation/widgets/home_header_test.dart` | Month text, badge visibility, settings tap |
| `test/features/home/presentation/widgets/month_overview_card_test.dart` | Amount format, trend badge, last month row |
| `test/features/home/presentation/widgets/soul_fullness_card_test.dart` | Metrics display, recent spending |
| `test/features/home/presentation/widgets/home_transaction_tile_test.dart` | Tag, merchant, amount |
| `test/features/home/presentation/widgets/transaction_list_card_test.dart` | Container border, dividers, empty state |
| `test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart` | Active tab, pill shape, FAB tap |
| `test/features/home/presentation/widgets/family_invite_banner_test.dart` | CTA button, avatar icons |
| `test/features/home/presentation/screens/home_screen_test.dart` | Full integration: group vs solo mode |

---

## Task 1: Update Color Tokens (`app_colors.dart`)

**Files:**
- Modify: `lib/core/theme/app_colors.dart`
- Reference: `docs/design/flutter-color-mapping.dart`

- [ ] **Step 1: Write failing test for new color values**

```dart
// test/core/theme/app_colors_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'dart:ui';

void main() {
  group('AppColors Wa-Modern light palette', () {
    test('background is warm ivory', () {
      expect(AppColors.background, const Color(0xFFFCFBF9));
    });
    test('accent primary is coral', () {
      expect(AppColors.accentPrimary, const Color(0xFFE85A4F));
    });
    test('text primary is dark', () {
      expect(AppColors.textPrimary, const Color(0xFF1E2432));
    });
    test('survival is blue', () {
      expect(AppColors.survival, const Color(0xFF5A9CC8));
    });
    test('soul is green', () {
      expect(AppColors.soul, const Color(0xFF47B88A));
    });
    test('border default is light gray', () {
      expect(AppColors.borderDefault, const Color(0xFFEFEFEF));
    });
    test('FAB gradient start is lighter coral', () {
      expect(AppColors.fabGradientStart, const Color(0xFFF08070));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: FAIL — old color values don't match

- [ ] **Step 3: Rewrite `app_colors.dart` with Wa-Modern tokens**

Replace the entire contents of `lib/core/theme/app_colors.dart` with the Wa-Modern light palette. Use `docs/design/flutter-color-mapping.dart` as the canonical source for hex values:

```dart
import 'dart:ui';

abstract final class AppColors {
  // ── Backgrounds ──
  static const background = Color(0xFFFCFBF9);       // warm ivory
  static const card = Color(0xFFFFFFFF);
  static const backgroundMuted = Color(0xFFF5F4F2);   // section divider lines
  static const backgroundSubtle = Color(0xFFFCFBF9);  // nested card (last month)
  static const backgroundDivider = Color(0xFFF0F0F0); // inner card dividers

  // ── Text ──
  static const textPrimary = Color(0xFF1E2432);
  static const textSecondary = Color(0xFFABABAB);
  static const textTertiary = Color(0xFFC4C4C4);      // inactive nav, chevrons

  // ── Borders ──
  static const borderDefault = Color(0xFFEFEFEF);     // card strokes
  static const borderDivider = Color(0xFFF5F4F2);     // section dividers
  static const borderList = Color(0xFFE8E8E8);        // transaction list
  static const borderInputActive = Color(0xFFE85A4F);

  // ── Accent — Primary (Coral) ──
  static const accentPrimary = Color(0xFFE85A4F);
  static const accentPrimaryLight = Color(0xFFFEF5F4); // family badge, satisfaction
  static const accentPrimaryBorder = Color(0xFFF5D5D2);
  static const fabGradientStart = Color(0xFFF08070);
  static const fabGradientEnd = Color(0xFFE85A4F);

  // ── Accent — Survival (Blue) ──
  static const survival = Color(0xFF5A9CC8);
  static const survivalLight = Color(0xFFE8F0F8);

  // ── Accent — Soul (Green) ──
  static const soul = Color(0xFF47B88A);
  static const soulLight = Color(0xFFE5F5ED);

  // ── Accent — Olive (Trends) ──
  static const olive = Color(0xFF8A9178);
  static const oliveLight = Color(0xFFF0FAF4);
  static const oliveBorder = Color(0xFFC8E6D5);

  // ── Shared Ledger (Group mode) ──
  static const shared = Color(0xFFD4845A);
  static const sharedLight = Color(0xFFFFF0E0);
  static const sharedBorder = Color(0xFFF0DCC8);
  static const sharedChevron = Color(0xFFD4B89A);

  // ── Shadows ──
  static const fabShadow = Color(0x35E85A4F);
  static const navShadow = Color(0x08000000);

  // ── Compatibility aliases (for non-home files that still reference old names) ──
  // These prevent breaking files in accounting/, family_sync/, etc.
  // TODO: Remove these after all screens are migrated to Wa-Modern
  static const primary = accentPrimary;           // app_theme.dart
  static const divider = borderDivider;            // otp_digit_input, voice_transcript_card
  static const tabBarBackground = card;            // voice_transcript_card
  static const textMuted = textSecondary;          // accounting widgets
  static const inactiveTab = textTertiary;         // (home nav, migrated in Task 12)
  static const comparisonPositive = olive;         // (text styles, migrated in Task 2)
  static const survivalBorder = borderDefault;     // (family_invite_banner, migrated in Task 11)
}
```

- [ ] **Step 4: Update `app_theme.dart`**

Rewrite `lib/core/theme/app_theme.dart` to use new tokens and Outfit font:
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.accentPrimary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Outfit',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppColors.borderDefault),
      ),
    ),
  );
}
```

- [ ] **Step 5: Fix remaining compilation errors from renamed/removed colors**

Files in `features/accounting/` and `features/family_sync/` that reference old names should now compile via the compat aliases added in Step 3. The home feature widgets (hero_header, month_overview_card, soul_fullness_card, etc.) still reference old tokens but will be rewritten in later tasks. For now, add temporary compat aliases for any tokens still referenced by home widgets that haven't been rewritten yet:

Add to the compat aliases section if needed:
- `heroBackground` → `background` (temporary, removed when hero_header is rewritten)
- `textOnPrimary` → `Color(0xFFFFFFFF)` (add `static const textOnPrimary = Color(0xFFFFFFFF);`)
- `modeBadgeBg` → `accentPrimaryLight`
- `familyInviteBackground` → `card`
- `survivalLight` — already exists as new token
- `soulCardBg`, `soulMetricBg1`, `soulMetricBg2`, `soulProgressBg`, `soulBadgeBg`, `soulTextDark`, `soulTextMuted`, `soulQuoteText` → add as temp compat for soul_fullness_card (removed in Task 8)
- `ohtaniBackground`, `ohtaniText`, `ohtaniClose` → add as temp compat for ohtani_converter (removed in Task 15)
- `survivalBarBg`, `previousBarSurvival`, `previousBarSoul`, `currentBarSoul` → add as temp compat for month_overview_card (removed in Task 6)

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: PASS

- [ ] **Step 7: Run full analysis**

Run: `flutter analyze`
Expected: 0 issues (all old references fixed via compat aliases)

- [ ] **Step 8: Commit**

```bash
git add lib/core/theme/app_colors.dart lib/core/theme/app_theme.dart test/core/theme/app_colors_test.dart
git commit -m "refactor(theme): update color tokens to Wa-Modern palette with compat aliases"
```

---

## Task 2: Update Text Styles (`app_text_styles.dart`)

**Files:**
- Modify: `lib/core/theme/app_text_styles.dart`
- Reference: `docs/design/design-system.md` section 3

- [ ] **Step 1: Write failing test for new text styles**

```dart
// test/core/theme/app_text_styles_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';

void main() {
  group('AppTextStyles Wa-Modern', () {
    test('font family is Outfit', () {
      expect(AppTextStyles.headlineLarge.fontFamily, 'Outfit');
    });
    test('headlineLarge is 30px bold', () {
      expect(AppTextStyles.headlineLarge.fontSize, 30);
      expect(AppTextStyles.headlineLarge.fontWeight, FontWeight.w700);
    });
    test('headlineMedium is 24px bold', () {
      expect(AppTextStyles.headlineMedium.fontSize, 24);
      expect(AppTextStyles.headlineMedium.fontWeight, FontWeight.w700);
    });
    test('titleMedium is 15px semibold', () {
      expect(AppTextStyles.titleMedium.fontSize, 15);
      expect(AppTextStyles.titleMedium.fontWeight, FontWeight.w600);
    });
    test('amountLarge is 30px bold with tabular figures', () {
      expect(AppTextStyles.amountLarge.fontSize, 30);
      expect(AppTextStyles.amountLarge.fontWeight, FontWeight.w700);
      expect(AppTextStyles.amountLarge.fontFeatures, isNotEmpty);
    });
    test('navLabel uses DM Sans', () {
      expect(AppTextStyles.navLabel.fontFamily, 'DM Sans');
      expect(AppTextStyles.navLabel.fontSize, 9);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_text_styles_test.dart`
Expected: FAIL

- [ ] **Step 3: Rewrite `app_text_styles.dart` with Wa-Modern type scale**

```dart
import 'package:flutter/painting.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _fontFamily = 'Outfit';
  static const _tabularFigures = [FontFeature.tabularFigures()];

  // ── Headlines ──
  static const headlineLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 30, fontWeight: FontWeight.w700,
    height: 0.9, color: AppColors.textPrimary,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Titles ──
  static const titleLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const titleMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const titleSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ── Captions & Labels ──
  static const caption = TextStyle(
    fontFamily: _fontFamily, fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const overline = TextStyle(
    fontFamily: _fontFamily, fontSize: 9, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const micro = TextStyle(
    fontFamily: _fontFamily, fontSize: 8, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Section divider label ──
  static const dividerLabel = TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500,
    letterSpacing: 2, color: AppColors.textSecondary,
  );

  // ── Labels (compat) ──
  static const labelMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const labelSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ── Nav ──
  static const navLabel = TextStyle(
    fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w500,
  );
  static const navLabelActive = TextStyle(
    fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );

  // ── Amount styles (tabular figures) ──
  static const amountLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 30, fontWeight: FontWeight.w700,
    height: 0.9, color: AppColors.textPrimary, fontFeatures: _tabularFigures,
  );
  static const amountMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFeatures: _tabularFigures,
  );
  static const amountSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 13, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, fontFeatures: _tabularFigures,
  );
}
```

- [ ] **Step 4: Fix compilation errors from changed style names/signatures**

Old styles used by other files: `tabLabel`, `comparisonDelta`, `legendLabel`. Map them:
- `tabLabel` → `navLabel`
- `comparisonDelta` → remove (comparison bar chart is removed)
- `legendLabel` → remove

Run: `flutter analyze`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/theme/app_text_styles_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_text_styles.dart test/core/theme/app_text_styles_test.dart
git commit -m "refactor(theme): update text styles to Outfit font with Wa-Modern scale"
```

---

## Task 3: Create `SectionDivider` Widget

**Files:**
- Create: `lib/features/home/presentation/widgets/section_divider.dart`
- Test: `test/features/home/presentation/widgets/section_divider_test.dart`

**Design spec (from Pencil node `P8dSg`):**
- Horizontal row, align children to bottom (crossAxisAlignment: end)
- Left: label text (11px, weight 500, `#ABABAB`, letterSpacing 2)
- Right: fill_container line (1px height, `#F5F4F2`)
- Gap: 4px between label and line (via Padding or SizedBox)

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/section_divider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/section_divider.dart';

void main() {
  testWidgets('SectionDivider renders label text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionDivider(label: '今月の支出')),
      ),
    );
    expect(find.text('今月の支出'), findsOneWidget);
  });

  testWidgets('SectionDivider renders divider line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionDivider(label: 'Test')),
      ),
    );
    // The line is a Container with 1px height
    final containers = find.byType(Container);
    expect(containers, findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/section_divider_test.dart`
Expected: FAIL — file doesn't exist

- [ ] **Step 3: Implement `section_divider.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Wa-Modern section divider: label ─── thin line
/// Used between content sections on the home screen.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.dividerLabel),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderDivider,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/section_divider_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/section_divider.dart test/features/home/presentation/widgets/section_divider_test.dart
git commit -m "feat(home): add SectionDivider widget for Wa-Modern design"
```

---

## Task 4: Create `MemberAvatar` Widget

**Files:**
- Create: `lib/features/home/presentation/widgets/member_avatar.dart`
- Test: `test/features/home/presentation/widgets/member_avatar_test.dart`

**Design spec (from Pencil node `8keGc`):**
- Size: 24x24, radius 12 (circle)
- Stroke: 2px outside, white
- Fill: member color (passed via param)
- Content: single character initial, 11px, weight 600, white
- Overlap layout: parent uses gap -6px (handled by parent)

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/member_avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/member_avatar.dart';

void main() {
  testWidgets('MemberAvatar displays initial', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(initial: '太', color: Color(0xFF5A9CC8)),
        ),
      ),
    );
    expect(find.text('太'), findsOneWidget);
  });

  testWidgets('MemberAvatar has correct size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(initial: '花', color: Color(0xFFE85A4F)),
        ),
      ),
    );
    final box = tester.getSize(find.byType(MemberAvatar));
    // 24 + 2*2 border = 28, but border is decorative not layout
    expect(box.width, 28); // 24 + 4 for outside stroke
    expect(box.height, 28);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/member_avatar_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `member_avatar.dart`**

```dart
import 'package:flutter/material.dart';

/// Circular member avatar with initial letter.
/// Used in group bar and transaction tags.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.initial,
    required this.color,
    this.size = 24,
    this.strokeWidth = 2,
    this.strokeColor = const Color(0xFFFFFFFF),
  });

  final String initial;
  final Color color;
  final double size;
  final double strokeWidth;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    final totalSize = size + strokeWidth * 2;
    return Container(
      width: totalSize,
      height: totalSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: strokeColor, width: strokeWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/member_avatar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/member_avatar.dart test/features/home/presentation/widgets/member_avatar_test.dart
git commit -m "feat(home): add MemberAvatar widget"
```

---

## Task 5: Rewrite `HeroHeader` → Flat Header

**Files:**
- Modify: `lib/features/home/presentation/widgets/hero_header.dart`
- Test: `test/features/home/presentation/widgets/home_header_test.dart`

**Design spec (from Pencil node `vYjVy`):**
- Layout: horizontal, space_between, fill width
- Left: month wrap (text "2026年3月" 24px 700 `#1E2432` + chevron-down 20px `#ABABAB`, gap 6)
- Center (group mode only): family badge (radius 8, bg `#FEF5F4`, padding [4,10], gap 4, users icon 12px coral + "家族モード" 11px 500 coral)
- Center (solo mode only): solo badge (radius 8, bg `#EDF5FA`, "ソロモード" blue)
- Right: settings icon (22px `#1E2432`)
- NO blue background — this is on the warm ivory page background

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/home_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/hero_header.dart';

void main() {
  testWidgets('HomeHeader shows month text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroHeader(
            year: 2026, month: 3,
            isGroupMode: true,
            onSettingsTap: () {},
            onDateTap: () {},
          ),
        ),
      ),
    );
    // Month display uses l10n — just check the widget renders
    expect(find.byType(HeroHeader), findsOneWidget);
  });

  testWidgets('HomeHeader shows settings icon', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroHeader(
            year: 2026, month: 3,
            isGroupMode: false,
            onSettingsTap: () => tapped = true,
            onDateTap: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/home_header_test.dart`
Expected: FAIL — old HeroHeader has different constructor

- [ ] **Step 3: Rewrite `hero_header.dart`**

Complete rewrite: remove blue Container, remove SafeArea wrapping, remove `bottomOverlap`. New layout is a simple Row with month picker + optional badge + settings icon. Add `isGroupMode` parameter to control badge display.

Key implementation details:
- Month picker: GestureDetector wrapping Row(Text + Icon(chevron-down))
- Family badge (group mode): Container with radius 8, `#FEF5F4` bg, Icon(users 12px coral) + Text("家族モード")
- Solo badge (solo mode): Container with radius 8, `#EDF5FA` bg, Text("ソロモード") — from Pencil node `4LJf4`
- Settings: GestureDetector wrapping Icon(settings_outlined, 22px, `#1E2432`)
- Font for month: Outfit 24px w700 `#1E2432`
- Chevron: Icons.keyboard_arrow_down, 20px, `#ABABAB`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/home_header_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/hero_header.dart test/features/home/presentation/widgets/home_header_test.dart
git commit -m "refactor(home): rewrite HeroHeader as flat header with mode badge"
```

---

## Task 6: Rewrite `MonthOverviewCard`

**Files:**
- Modify: `lib/features/home/presentation/widgets/month_overview_card.dart`
- Test: `test/features/home/presentation/widgets/month_overview_card_test.dart`

**Design spec (from Pencil node `25zgF`):**
- Container: radius 14, bg white, padding 18, gap 16 vertical, 1px `#EFEFEF` stroke (no shadow!)
- Top row (`gOverTop`): space_between
  - Left: amount text "¥248,500" (30px 700 `#1E2432`, lineHeight 0.9)
  - Right: trend badge (pill radius 999, bg `#F0FAF4`, padding [4,10], gap 4)
    - Icon: trending-down 14px `#8A9178`
    - Text: "-12%" 11px 600 `#8A9178`
- Bottom row (`gLastMonth`): radius 12, bg `#FCFBF9`, padding [10,0], space_between
  - Left: calendar icon (14px `#ABABAB`) + "先月: ¥282,300" (12px 500 `#ABABAB`), gap 6
  - Right: chevron-right 14px `#C4C4C4`

**Data params:**
- `totalExpense: int`
- `previousMonthTotal: int`
- `onLastMonthTap: VoidCallback?`

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/month_overview_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/month_overview_card.dart';

void main() {
  testWidgets('MonthOverviewCard displays formatted total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MonthOverviewCard(
            totalExpense: 248500,
            previousMonthTotal: 282300,
          ),
        ),
      ),
    );
    expect(find.textContaining('248,500'), findsOneWidget);
  });

  testWidgets('MonthOverviewCard shows trend percentage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MonthOverviewCard(
            totalExpense: 248500,
            previousMonthTotal: 282300,
          ),
        ),
      ),
    );
    // (248500 - 282300) / 282300 * 100 ≈ -12%
    expect(find.textContaining('-12%'), findsOneWidget);
  });

  testWidgets('MonthOverviewCard shows last month amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MonthOverviewCard(
            totalExpense: 248500,
            previousMonthTotal: 282300,
          ),
        ),
      ),
    );
    expect(find.textContaining('282,300'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/month_overview_card_test.dart`
Expected: FAIL — constructor signature changed

- [ ] **Step 3: Rewrite `month_overview_card.dart`**

Complete rewrite. Remove the bar chart comparison section, survival/soul breakdown, and `child` slot. The new card is much simpler:
- Calculate trend: `((totalExpense - previousMonthTotal) / previousMonthTotal * 100).round()`
- Trend badge shows positive olive color regardless of direction (design uses olive for both)
- Amount formatting: `NumberFormat.currency(symbol: '¥', decimalDigits: 0)`
- No `modeBadgeText`, `survivalExpense`, `soulExpense`, `currentMonthNumber`, `previousMonthNumber` params — remove them

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/month_overview_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/month_overview_card.dart test/features/home/presentation/widgets/month_overview_card_test.dart
git commit -m "refactor(home): rewrite MonthOverviewCard with trend badge + last month row"
```

---

## Task 7: Create `LedgerComparisonSection`

**Files:**
- Create: `lib/features/home/presentation/widgets/ledger_comparison_section.dart`
- Test: `test/features/home/presentation/widgets/ledger_comparison_section_test.dart`

**Design spec (from Pencil node `gpBvs`):**
- Container: gap 6 vertical, fill_container width
- Each row (e.g. `5t2e3`): radius 12, bg white, padding [10,14], gap 8, 1px `#EFEFEF` stroke, horizontal align center
  - Left info (`raInfo`): vertical, gap 2, fill_container
    - Title row (`raTR`): horizontal, gap 6
      - Tag (`raTag`): radius 3, bg `#E8F0F8` (survival) / `#E5F5ED` (soul) / `#FFF0E0` (shared), padding [1,6]
        - Text: 生/灵/person initial, 8px 700, colored per ledger
      - Title: "生存帳本" / "灵魂帳本" / "花の帳本", 11px 600, `#1E2432` (survival/shared) / `#47B88A` (soul)
    - Subtitle: "先月 ¥198,000  ▾-6%", 9px 400, `#ABABAB`
  - Amount: "¥186,200", 16px 700, colored per ledger (`#5A9CC8` / `#47B88A` / `#D4845A`)
  - Chevron: 13px, `#C4C4C4` (survival/soul) / `#D4B89A` (shared)
- In solo mode: only 2 rows (survival + soul), tags show "生" / "灵"
- In group mode: 3 rows, tags show person initials, shared row has orange border `#F0DCC8`

**Data model — `LedgerRowData` (Freezed, in domain layer per Clean Architecture):**

Create `lib/features/home/domain/models/ledger_row_data.dart`:
```dart
import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_row_data.freezed.dart';

@freezed
class LedgerRowData with _$LedgerRowData {
  const factory LedgerRowData({
    required String tagText,
    required Color tagBgColor,
    required Color tagTextColor,
    required String title,
    required Color titleColor,
    required String subtitle,
    required String formattedAmount,
    required Color amountColor,
    required Color chevronColor,
    Color? borderColor, // null = default #EFEFEF
  }) = _LedgerRowData;
}
```

- [ ] **Step 1: Create `LedgerRowData` Freezed model**

Create `lib/features/home/domain/models/ledger_row_data.dart` with the code above.

- [ ] **Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `ledger_row_data.freezed.dart` generated

- [ ] **Step 3: Write failing test**

```dart
// test/features/home/presentation/widgets/ledger_comparison_section_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/domain/models/ledger_row_data.dart';
import 'package:home_pocket/features/home/presentation/widgets/ledger_comparison_section.dart';

void main() {
  testWidgets('renders 2 rows in solo mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerComparisonSection(
            rows: const [
              LedgerRowData(
                tagText: '生', tagBgColor: Color(0xFFE8F0F8),
                tagTextColor: Color(0xFF5A9CC8),
                title: '生存帳本', titleColor: Color(0xFF1E2432),
                subtitle: '先月 ¥198,000', formattedAmount: '¥186,200',
                amountColor: Color(0xFF5A9CC8),
                chevronColor: Color(0xFFC4C4C4),
              ),
              LedgerRowData(
                tagText: '灵', tagBgColor: Color(0xFFE5F5ED),
                tagTextColor: Color(0xFF47B88A),
                title: '灵魂帳本', titleColor: Color(0xFF47B88A),
                subtitle: '先月 ¥54,800', formattedAmount: '¥62,300',
                amountColor: Color(0xFF47B88A),
                chevronColor: Color(0xFFC4C4C4),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('生存帳本'), findsOneWidget);
    expect(find.text('灵魂帳本'), findsOneWidget);
    expect(find.text('¥186,200'), findsOneWidget);
    expect(find.text('¥62,300'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/ledger_comparison_section_test.dart`
Expected: FAIL — widget file doesn't exist

- [ ] **Step 5: Implement `ledger_comparison_section.dart`**

Create `lib/features/home/presentation/widgets/ledger_comparison_section.dart`. Imports `LedgerRowData` from `../../domain/models/ledger_row_data.dart`. Renders rows in a Column with gap 6. Each row is a Container matching the Pencil spec.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/ledger_comparison_section_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/domain/models/ledger_row_data.dart lib/features/home/domain/models/ledger_row_data.freezed.dart lib/features/home/presentation/widgets/ledger_comparison_section.dart test/features/home/presentation/widgets/ledger_comparison_section_test.dart
git commit -m "feat(home): add LedgerRowData model and LedgerComparisonSection widget"
```

---

## Task 8: Rewrite `SoulFullnessCard`

**Files:**
- Modify: `lib/features/home/presentation/widgets/soul_fullness_card.dart`
- Test: `test/features/home/presentation/widgets/soul_fullness_card_test.dart`

**Design spec (from Pencil node `AeG3R`):**
- Container: radius 14, bg white, padding 16, gap 12 vertical, 1px `#EFEFEF` stroke
- Title row (`h5`): space_between
  - Text: "灵魂の充実度" 13px 600 `#1E2432`
  - Chevron-right: 14px `#C4C4C4`
- Metrics row (`pr5`): horizontal, gap 8
  - Satisfaction tile (`p5a`): radius 12, bg `#FEF5F4`, border `#F5D5D2`, padding [6,30], gap 8, space_between
    - Left: vertical gap 2: flame icon 14px coral + "満足度" 8px 400 coral
    - Right: "78%" 16px 700 coral
  - ROI tile (`p5b`): radius 12, bg `#F0FAF4`, border `#C8E6D5`, same layout
    - Left: zap icon 14px olive + "幸福ROI" 8px 400 olive
    - Right: "2.4x" 16px 700 olive
- Divider: 1px `#F0F0F0`
- Spending row (`sp5`): space_between, align end
  - Left: "最近の灵魂支出" 10px 500 `#ABABAB`
  - Right: "¥8,500" 18px 700 `#5A9CC8`

**Data params (simplified):**
- `satisfactionPercent: int` (e.g. 78)
- `happinessROI: double` (e.g. 2.4)
- `recentSoulAmount: int` (e.g. 8500)
- `onTap: VoidCallback?` (chevron tap)

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/soul_fullness_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/soul_fullness_card.dart';

void main() {
  testWidgets('SoulFullnessCard shows satisfaction and ROI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulFullnessCard(
            satisfactionPercent: 78,
            happinessROI: 2.4,
            recentSoulAmount: 8500,
          ),
        ),
      ),
    );
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('2.4x'), findsOneWidget);
  });

  testWidgets('SoulFullnessCard shows recent amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulFullnessCard(
            satisfactionPercent: 78,
            happinessROI: 2.4,
            recentSoulAmount: 8500,
          ),
        ),
      ),
    );
    expect(find.textContaining('8,500'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/soul_fullness_card_test.dart`
Expected: FAIL

- [ ] **Step 3: Rewrite `soul_fullness_card.dart`**

Complete rewrite. Remove battery animation, progress bar, charge status, recent transaction detail. New layout is:
1. Title row with "灵魂の充実度" + chevron
2. Two metric tiles side by side (satisfaction coral + ROI olive)
3. Divider line
4. Recent spending row (label + formatted amount)

Remove params: `soulPercentage`, `happinessROI`, `fullnessLevel`, `recentMerchant`, `recentQuote`. New params: `satisfactionPercent`, `happinessROI`, `recentSoulAmount`, `onTap?`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/soul_fullness_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/soul_fullness_card.dart test/features/home/presentation/widgets/soul_fullness_card_test.dart
git commit -m "refactor(home): rewrite SoulFullnessCard with metric tiles"
```

---

## Task 9: Create `GroupBar` Widget

**Files:**
- Create: `lib/features/home/presentation/widgets/group_bar.dart`
- Test: `test/features/home/presentation/widgets/group_bar_test.dart`

**Design spec (from Pencil node `lfQZV`):**
- Container: radius 14, bg white, padding [12,16], space_between, 1px `#EFEFEF` stroke
- Left (`gGroupLeft`): horizontal, gap 10
  - Users icon: 18px coral `#E85A4F`
  - Family name: "田中家" 14px 600 `#1E2432`
- Center (`gAvatars`): horizontal, gap -6
  - MemberAvatar × N (overlapping, using MemberAvatar widget from Task 4)
- Right: chevron-right 16px `#C4C4C4`

**Data params:**
- `familyName: String`
- `members: List<({String initial, Color color})>`
- `onTap: VoidCallback?`

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/group_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/group_bar.dart';

void main() {
  testWidgets('GroupBar shows family name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupBar(
            familyName: '田中家',
            members: const [
              (initial: '太', color: Color(0xFF5A9CC8)),
              (initial: '花', color: Color(0xFFE85A4F)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('田中家'), findsOneWidget);
  });

  testWidgets('GroupBar shows correct number of avatars', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupBar(
            familyName: '田中家',
            members: const [
              (initial: '太', color: Color(0xFF5A9CC8)),
              (initial: '花', color: Color(0xFFE85A4F)),
              (initial: '翔', color: Color(0xFF8A9178)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('太'), findsOneWidget);
    expect(find.text('花'), findsOneWidget);
    expect(find.text('翔'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/widgets/group_bar_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `group_bar.dart`**

Use a Row with MainAxisAlignment.spaceBetween. Left section has users icon + text. Center uses a Row with negative margin via Transform.translate for overlapping avatars. Right has chevron icon.

For overlapping avatars, use a Stack or a Row with negative padding via `Padding(padding: EdgeInsets.only(left: index > 0 ? -6 : 0))` pattern, or a custom layout.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/widgets/group_bar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/group_bar.dart test/features/home/presentation/widgets/group_bar_test.dart
git commit -m "feat(home): add GroupBar widget with overlapping avatars"
```

---

## Task 10: Rewrite `HomeTransactionTile` and Create `TransactionListCard`

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_transaction_tile.dart`
- Create: `lib/features/home/presentation/widgets/transaction_list_card.dart`
- Test: `test/features/home/presentation/widgets/home_transaction_tile_test.dart`
- Test: `test/features/home/presentation/widgets/transaction_list_card_test.dart`

**Transaction Row design spec (from Pencil node `25UvN`):**
- Layout: horizontal, gap 8, padding [10,14], fill_container, align center
- Tag: radius 3, padding [1,6], colored per tag type
  - Text: person initial or ledger tag (8px 700, colored)
- Info (`gR1i`): vertical, gap 2, fill_container
  - Merchant: "スーパーマーケット" 12px 500 `#1E2432`
  - Category: "食費" 10px 400, colored: `#ABABAB` (normal) or `#E85A4F` (soul/special)
- Amount: "-¥3,480" 13px 700, colored: `#1E2432` (normal) or `#E85A4F` (soul highlight)

**TransactionListCard design spec (from Pencil node `jGWEX`):**
- Container: clip true, radius 12, bg white, 1px `#E8E8E8` stroke, vertical layout
- Rows separated by 1px `#F0F0F0` dividers

**Data params for tile:**
- `tagText: String` (e.g. "太" or "生")
- `tagBgColor: Color`
- `tagTextColor: Color`
- `merchant: String`
- `category: String`
- `categoryColor: Color`
- `formattedAmount: String`
- `amountColor: Color`
- `onTap: VoidCallback?`

- [ ] **Step 1: Write failing tests for both widgets**

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement `home_transaction_tile.dart`**

Rewrite: remove the 40x40 icon container. New layout matches Pencil exactly:
- Row with tag container + info column + amount text
- Remove `iconData` and `ledgerType` params, add tag and color params

- [ ] **Step 4: Implement `transaction_list_card.dart`**

```dart
/// Bordered container that wraps transaction tiles with dividers.
class TransactionListCard extends StatelessWidget {
  const TransactionListCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderList),
      ),
      child: Column(
        children: _intersperseDividers(children),
      ),
    );
  }

  List<Widget> _intersperseDividers(List<Widget> items) {
    if (items.isEmpty) return items;
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(Container(height: 1, color: AppColors.backgroundDivider));
      }
    }
    return result;
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/widgets/home_transaction_tile.dart lib/features/home/presentation/widgets/transaction_list_card.dart test/features/home/presentation/widgets/home_transaction_tile_test.dart test/features/home/presentation/widgets/transaction_list_card_test.dart
git commit -m "refactor(home): rewrite transaction tile and add TransactionListCard"
```

---

## Task 11: Rewrite `FamilyInviteBanner` (Solo Mode)

**Files:**
- Modify: `lib/features/home/presentation/widgets/family_invite_banner.dart`
- Test: `test/features/home/presentation/widgets/family_invite_banner_test.dart`

**Design spec (from Pencil node `KrfcC` in LP8mE):**
- Container: radius 16, bg white, padding 20, gap 14 vertical, 1px `#EFEFEF` stroke
- Icon row (`iconRow`): overlapping face emojis (center aligned, gap -10)
- Text group (`txtGroup`): vertical, gap 4, fill_container, center aligned
  - Title: "家族と一緒に管理しよう" 14px 600 `#1E2432`, center
  - Subtitle: "パートナーや家族と一緒に... " 11px 500 `#ABABAB`, center
- CTA button (`btnC`): radius 12, bg coral `#E85A4F`, padding [10,0], center, fill_container
  - Text: "家族を招待する" 13px 600 white, icon: plus or users

- [ ] **Step 1: Write failing test**

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Rewrite `family_invite_banner.dart`**

Complete rewrite from horizontal card to vertical card. Replace the icon+text+chevron layout with:
1. Row of emoji/avatar icons (overlapping, centered)
2. Title + subtitle text (centered)
3. Full-width coral CTA button

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/family_invite_banner.dart test/features/home/presentation/widgets/family_invite_banner_test.dart
git commit -m "refactor(home): rewrite FamilyInviteBanner as vertical card with CTA"
```

---

## Task 12: Rewrite `HomeBottomNavBar` as Pill Nav

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_bottom_nav_bar.dart`
- Test: `test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart`

**Design spec (from Pencil node `pibKW`):**
- Wrapper: padding [16,21,21,21], gap 12, align end, horizontal
- Pill (`ByYKj`): h62, radius 32, bg white, padding [0,12], space_around, fill_container
  - 1px `#EFEFEF` stroke
  - Shadow: 0 4px 20px `#00000008`
  - Active tab (`gT1`): radius 14, bg coral `#E85A4F`, vertical, gap 4, padding [8,14]
    - Icon: 20px white (lucide: house/list/chart-no-axes-column/square-check-big)
    - Label: DM Sans 9px 600 white
  - Inactive tab: transparent bg, icon 20px `#C4C4C4`, label DM Sans 9px 500 `#C4C4C4`
- FAB (`20reY`): 62x62, radius 31, center
  - Gradient: linear 180deg, `#F08070` → `#E85A4F`
  - Shadow: 0 4px 14px `#E85A4F35`
  - Icon: plus 24px white
- **Layout: pill and FAB are siblings in a Row**, not stacked/positioned

**Icon mapping (Material Icons since Lucide not natively available):**
- house → Icons.home_outlined / Icons.home
- list → Icons.list
- chart-no-axes-column → Icons.bar_chart
- square-check-big → Icons.check_box_outlined

- [ ] **Step 1: Write failing test**

```dart
// test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';

void main() {
  testWidgets('HomeBottomNavBar renders 4 tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeBottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onFabTap: () {},
          ),
        ),
      ),
    );
    // 4 tab icons
    expect(find.byType(Icon), findsAtLeastNWidgets(4));
  });

  testWidgets('FAB tap triggers callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeBottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onFabTap: () => tapped = true,
          ),
        ),
      ),
    );
    // FAB has plus icon
    await tester.tap(find.byIcon(Icons.add));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Rewrite `home_bottom_nav_bar.dart`**

Complete rewrite. Remove the old Stack-based layout. New layout:
- Outer Container with padding [16,21,21,21]
- Row(crossAxisAlignment: end) containing:
  - Expanded pill container (h62, white bg, rounded, shadow, stroke)
    - Row with space_around: 4 tab items
    - Active tab has coral background pill (radius 14)
  - SizedBox(width: 12)
  - FAB circle (62x62, gradient, shadow)

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_bottom_nav_bar.dart test/features/home/presentation/widgets/home_bottom_nav_bar_test.dart
git commit -m "refactor(home): rewrite HomeBottomNavBar as floating pill with FAB"
```

---

## Task 13: Rewrite `HomeScreen` (Main Assembly)

**Files:**
- Modify: `lib/features/home/presentation/screens/home_screen.dart`
- Test: `test/features/home/presentation/screens/home_screen_test.dart`

**Design spec (from Pencil full screen layout, section 10 of design-system.md):**

```
SingleChildScrollView
├── Column (crossAxisAlignment: start)
│   ├── SafeArea (bottom: false)
│   ├── Padding(horizontal: 28, top: 4)
│   │   ├── HeroHeader (month + badge + settings)
│   │   ├── SizedBox(16)
│   │   ├── SectionDivider("今月の支出")
│   │   ├── SizedBox(16)
│   │   ├── MonthOverviewCard (total + trend + last month)
│   │   ├── SizedBox(16)
│   │   ├── SectionDivider("帳 本")
│   │   ├── SizedBox(16)
│   │   ├── LedgerComparisonSection (2 or 3 rows)
│   │   ├── SizedBox(16)
│   │   ├── SoulFullnessCard
│   │   ├── SizedBox(16)
│   │   ├── [if groupMode] GroupBar
│   │   ├── [if groupMode] SizedBox(16)
│   │   ├── [if !groupMode] FamilyInviteBanner
│   │   ├── [if !groupMode] SizedBox(16)
│   │   ├── Transactions header row ("最近の取引" + "すべて見る")
│   │   ├── SizedBox(12)
│   │   ├── TransactionListCard (containing HomeTransactionTile × N)
│   │   └── SizedBox(100) // padding for bottom nav
```

**Key changes from current implementation:**
1. Remove Stack + blue background hero pattern entirely
2. Remove `_HeroWithCard` inner widget (inline the logic)
3. Use flat Padding(28) wrapper for ALL content
4. Wire new widgets with correct data params
5. Remove OhtaniConverter reference
6. Remove `ohtaniConverterVisibleProvider` watch
7. Build `LedgerRowData` list based on `isGroupMode` + monthly report data
8. Build transaction tile data with tag info based on mode

- [ ] **Step 1: Write integration test for HomeScreen**

Test group vs solo rendering differences: group mode shows GroupBar, solo shows FamilyInviteBanner. Use mock providers.

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Rewrite `home_screen.dart`**

Complete rewrite. Remove `_HeroWithCard` class. The `HomeScreen` ConsumerWidget now:
1. Watches: `todayTransactionsProvider`, `monthlyReportProvider`, `isGroupModeProvider`, `currentLocaleProvider`
2. Returns `SingleChildScrollView > Column` with all sections in order
3. Constructs `LedgerRowData` list from report data
4. Maps transactions to `HomeTransactionTile` with tag data
5. No blue hero, no Stack, no Ohtani converter

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/screens/home_screen.dart test/features/home/presentation/screens/home_screen_test.dart
git commit -m "refactor(home): complete HomeScreen redesign with Wa-Modern layout"
```

---

## Task 14: Update `MainShellScreen` Integration

**Files:**
- Modify: `lib/features/home/presentation/screens/main_shell_screen.dart`

- [ ] **Step 1: Update `bottomNavigationBar` integration**

The new `HomeBottomNavBar` has the same constructor API (`currentIndex`, `onTap`, `onFabTap`), so the `MainShellScreen` should work without changes. However, verify:
- The pill nav sits correctly at the bottom
- The nav background is transparent (content scrolls behind)
- Consider wrapping the body in a Stack with the nav overlaid at the bottom instead of using `bottomNavigationBar` (since the pill nav has its own padding and should float)

If the pill nav needs to float over content:
```dart
Scaffold(
  body: Stack(
    children: [
      IndexedStack(index: currentIndex, children: [...]),
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: HomeBottomNavBar(...),
      ),
    ],
  ),
  // Remove bottomNavigationBar
)
```

- [ ] **Step 2: Test navigation still works**

Run the app: `flutter run`
Verify: all 4 tabs switch, FAB opens transaction entry, returning refreshes data.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/screens/main_shell_screen.dart
git commit -m "refactor(home): update MainShellScreen for floating pill nav"
```

---

## Task 15: Remove OhtaniConverter and Clean Up

**Files:**
- Delete: `lib/features/home/presentation/widgets/ohtani_converter.dart`
- Modify: `lib/features/home/presentation/providers/home_providers.dart` (remove `OhtaniConverterVisible`)

- [ ] **Step 1: Remove `ohtani_converter.dart` file**

Run: `rm lib/features/home/presentation/widgets/ohtani_converter.dart`

- [ ] **Step 2: Remove `OhtaniConverterVisible` from `home_providers.dart`**

Remove the `@Riverpod(keepAlive: true)` class and its generated part.

- [ ] **Step 3: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run analysis and tests**

Run: `flutter analyze && flutter test`
Expected: 0 issues, all tests pass

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore(home): remove OhtaniConverter and cleanup unused provider"
```

---

## Task 16: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 2: Run analysis**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 3: Run app and visual check**

Run: `flutter run`
Verify against Pencil screenshots:
- [ ] Warm ivory background (#FCFBF9), no blue hero
- [ ] Header: month picker + family/solo badge + settings icon
- [ ] Section dividers with label text and thin line
- [ ] Overview card: total amount + trend badge + last month row, no shadow (1px border only)
- [ ] Ledger comparison: 2 rows (solo) or 3 rows (group) with colored tags and amounts
- [ ] Soul fullness: metric tiles (coral satisfaction + olive ROI) + divider + recent amount
- [ ] Group bar (group mode): family name + overlapping avatars + chevron
- [ ] Family invite banner (solo mode): vertical card with CTA
- [ ] Transaction list: bordered container, tag + merchant + category + amount rows
- [ ] Bottom nav: floating pill with coral active tab + separate coral gradient FAB
- [ ] No Ohtani converter visible
- [ ] Outfit font throughout

- [ ] **Step 4: Run coverage**

Run: `flutter test --coverage`
Expected: >= 80% coverage for modified files

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "test(home): add integration tests for HomeScreen redesign"
```
