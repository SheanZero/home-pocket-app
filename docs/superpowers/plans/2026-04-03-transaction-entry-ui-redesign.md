# Transaction Entry UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor all 4 transaction-entry screens (Entry, Voice, Confirm, Category) to match the Pencil design (Wa-Modern style) with full light/dark mode support.

**Architecture:** Modify existing screen files and widgets in `lib/features/accounting/presentation/`. Extract new shared widgets where the design introduces reusable patterns. Keep all business logic, providers, and navigation flow unchanged — this is a pure UI refactoring.

**Tech Stack:** Flutter, Riverpod, Outfit font, Lucide-equivalent Material Icons, AppColors/AppColorsDark tokens

---

## Design Reference

Pencil Node IDs (in `docs/design/home-pocket-app.pen`):
- **Transaction Entry:** `bEeOY` (Light), `50Lfv` (Dark)
- **Voice Input:** `bmacP` (Light), `efb8D` (Dark)
- **Confirm:** `SnvOC` (Light), `n8vpV` (Dark)
- **Category Selection:** `MkNZo` (Light), `mQUCn` (Dark)

---

## Gap Analysis Summary

| Area | Current | Design | Effort |
|------|---------|--------|--------|
| Entry bg color | `#F5F9FD` (blue tint) | `#FCFBF9` (warm ivory) | S |
| Entry selector chips | Horizontal `Row` of chip buttons | Vertical card with rows + dividers | M |
| Category screen colors | Blue-tinted chips `#EEF4FA`, `survival` blue | Category's own color (coral for 食費, blue for 交通, green for 住居, etc.) | M |
| Category expanded border | `survival` blue always | Category's own accent color | S |
| Category "Add" button | None | "カテゴリを追加" button + "+追加" L2 chip | S |
| Confirm satisfaction | 10-segment bar slider (green gradient) | 5 emoji face buttons with labels | L |
| Confirm detail card | `_DetailRow` with Material patterns | Card with icon-label rows, memo textarea, store row | M |
| Confirm save button | Inside scrollable content | Bottom-pinned bar outside scroll | S |
| Voice transcript | `VoiceTranscriptCard` + `VoiceParsePreview` | Unified card: transcript + parsed field list | M |
| Dark mode | Partial — some screens use hardcoded colors | Full dark mode with `AppColorsDark` tokens | M |

---

## File Structure

### Files to Create
- `lib/features/accounting/presentation/widgets/detail_info_card.dart` — Reusable card with icon-label rows and dividers (used by Entry and Confirm screens)
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` — 5-face emoji satisfaction picker replacing 10-segment slider

### Files to Modify
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` — Bg color, replace chip Row with detail card
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — New detail card layout, emoji picker, bottom-pinned save button
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` — Category-colored borders/chips, add-category button, bg color
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` — Unified transcript card layout
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` — Minor color adjustments for dark mode
- `lib/features/accounting/presentation/widgets/amount_display.dart` — Currency badge style update
- `lib/features/accounting/presentation/widgets/input_mode_tabs.dart` — Active tab shadow, icon integration
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` — Icon integration, dark mode colors

### Files to Remove (after replacement)
- `lib/features/accounting/presentation/widgets/soul_satisfaction_slider.dart` — Replaced by `satisfaction_emoji_picker.dart`
- `lib/features/accounting/presentation/widgets/voice_transcript_card.dart` — Inlined into VoiceInputScreen
- `lib/features/accounting/presentation/widgets/voice_parse_preview.dart` — Inlined into VoiceInputScreen

### ARB Entries to Add (all 3 locales: ja, zh, en)
New i18n keys required for satisfaction picker and category management:
- `satisfactionLevel` — "満足度" / "满足度" / "Satisfaction"
- `satisfactionBad` — "不満" / "不满" / "Bad"
- `satisfactionSlightlyBad` — "やや不満" / "稍有不满" / "Slightly bad"
- `satisfactionNormal` — "普通" / "一般" / "Normal"
- `satisfactionGood` — "良い" / "良好" / "Good"
- `satisfactionVeryGood` — "とても良い" / "非常好" / "Very good"
- `satisfactionExcellent` — "最高！" / "最好！" / "Excellent!"
- `addSubcategory` — "追加" / "添加" / "Add"
- `addCategory` — "カテゴリを追加" / "添加分类" / "Add category"
- `recognitionResult` — "認識結果" / "识别结果" / "Recognition result"
- `tapToRecord` — "タップして録音" / "点击录音" / "Tap to record"

### Test Files
- `test/widget/features/accounting/presentation/widgets/detail_info_card_test.dart`
- `test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart`
- `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart`
- `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

---

## Task 0: Add i18n ARB Entries

**Purpose:** Add all new localization keys required by the redesigned screens. Must run before any widget creation to ensure `S.of(context)` keys are available.

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add keys to Japanese ARB**

Add these entries to `lib/l10n/app_ja.arb`:
```json
"satisfactionLevel": "満足度",
"satisfactionBad": "不満",
"satisfactionSlightlyBad": "やや不満",
"satisfactionNormal": "普通",
"satisfactionGood": "良い",
"satisfactionVeryGood": "とても良い",
"satisfactionExcellent": "最高！",
"addSubcategory": "追加",
"addCategory": "カテゴリを追加",
"recognitionResult": "認識結果",
"tapToRecord": "タップして録音"
```

- [ ] **Step 2: Add keys to Chinese ARB**

Add these entries to `lib/l10n/app_zh.arb`:
```json
"satisfactionLevel": "满足度",
"satisfactionBad": "不满",
"satisfactionSlightlyBad": "稍有不满",
"satisfactionNormal": "一般",
"satisfactionGood": "良好",
"satisfactionVeryGood": "非常好",
"satisfactionExcellent": "最好！",
"addSubcategory": "添加",
"addCategory": "添加分类",
"recognitionResult": "识别结果",
"tapToRecord": "点击录音"
```

- [ ] **Step 3: Add keys to English ARB**

Add these entries to `lib/l10n/app_en.arb`:
```json
"satisfactionLevel": "Satisfaction",
"satisfactionBad": "Bad",
"satisfactionSlightlyBad": "Slightly bad",
"satisfactionNormal": "Normal",
"satisfactionGood": "Good",
"satisfactionVeryGood": "Very good",
"satisfactionExcellent": "Excellent!",
"addSubcategory": "Add",
"addCategory": "Add category",
"recognitionResult": "Recognition result",
"tapToRecord": "Tap to record"
```

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: SUCCESS — new `S` class methods available

- [ ] **Step 5: Verify generated file**

Run: `grep "satisfactionLevel" lib/generated/app_localizations.dart`
Expected: 1 match in generated file

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_en.arb lib/generated/
git commit -m "feat(i18n): add ARB entries for transaction entry UI redesign"
```

---

## Task 1: Create DetailInfoCard Widget

**Purpose:** Reusable card component with icon-label-value rows separated by dividers. Used in both Transaction Entry (date/category) and Confirm screens (amount/category/date/store/memo).

**Files:**
- Create: `lib/features/accounting/presentation/widgets/detail_info_card.dart`
- Test: `test/widget/features/accounting/presentation/widgets/detail_info_card_test.dart`

### Design Spec (from Pencil)
- Card: White bg (`AppColors.card`), cornerRadius 14, border 1px `#EFEFEF` (`AppColors.borderDefault`)
- Row: padding 16, horizontal layout, space-between
- Left side: icon (16px, `AppColors.textTertiary`) + label text (Outfit 13px w500, `AppColors.textSecondary`), gap 8
- Right side: value text (Outfit 14px w600, `AppColors.textPrimary`) + optional chevron (14px, `AppColors.textSecondary`), gap 4
- Divider: 1px `#F0F0F0` (`AppColors.backgroundDivider`) with horizontal padding 16
- Dark mode: card bg `AppColorsDark.card`, border `AppColorsDark.borderDefault`, text colors `AppColorsDark.textPrimary/Secondary/Tertiary`

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/features/accounting/presentation/widgets/detail_info_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/detail_info_card.dart';

void main() {
  group('DetailInfoCard', () {
    Widget buildTestWidget({
      required List<DetailInfoRow> rows,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: DetailInfoCard(rows: rows),
        ),
      );
    }

    testWidgets('renders all rows with labels and values', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        rows: [
          DetailInfoRow(
            icon: Icons.calendar_today,
            label: '日付',
            value: '今日',
          ),
          DetailInfoRow(
            icon: Icons.grid_view,
            label: 'カテゴリ',
            value: '食費 › コンビニ',
            showChevron: true,
            onTap: () {},
          ),
        ],
      ));

      expect(find.text('日付'), findsOneWidget);
      expect(find.text('今日'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);
      expect(find.text('食費 › コンビニ'), findsOneWidget);
    });

    testWidgets('shows dividers between rows', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        rows: [
          DetailInfoRow(icon: Icons.calendar_today, label: 'A', value: '1'),
          DetailInfoRow(icon: Icons.grid_view, label: 'B', value: '2'),
          DetailInfoRow(icon: Icons.store, label: 'C', value: '3'),
        ],
      ));

      // 3 rows → 2 dividers
      final dividers = find.byType(Container).evaluate().where((e) {
        final widget = e.widget as Container;
        final decoration = widget.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFFF0F0F0);
        }
        return false;
      });
      // At least 2 divider-like containers
      expect(dividers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('chevron icon visible when showChevron is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        rows: [
          DetailInfoRow(
            icon: Icons.grid_view,
            label: 'Test',
            value: 'Val',
            showChevron: true,
          ),
        ],
      ));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('onTap callback fires when row is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestWidget(
        rows: [
          DetailInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: 'Today',
            onTap: () => tapped = true,
          ),
        ],
      ));

      await tester.tap(find.text('Today'));
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/accounting/presentation/widgets/detail_info_card_test.dart`
Expected: FAIL — `detail_info_card.dart` does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/accounting/presentation/widgets/detail_info_card.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A row of data inside [DetailInfoCard].
class DetailInfoRow {
  const DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = false,
    this.onTap,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showChevron;
  final VoidCallback? onTap;

  /// Override the default value text color (e.g. for amounts).
  final Color? valueColor;
}

/// Reusable card with icon-label-value rows separated by thin dividers.
///
/// Matches the Wa-Modern detail card pattern used in Transaction Entry
/// and Confirm screens.
class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({
    super.key,
    required this.rows,
    this.trailing,
  });

  final List<DetailInfoRow> rows;

  /// Optional widget appended after the last row (e.g. memo section).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColorsDark.card : AppColors.card;
    final borderColor = isDark
        ? AppColorsDark.borderDefault
        : AppColors.borderDefault;
    final dividerColor = isDark
        ? AppColorsDark.backgroundDivider
        : AppColors.backgroundDivider;
    final iconColor = isDark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;
    final labelColor = isDark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
    final valueColor = isDark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) _buildDivider(dividerColor),
            _buildRow(rows[i], iconColor, labelColor, valueColor),
          ],
          if (trailing != null) ...[
            _buildDivider(dividerColor),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: color),
    );
  }

  Widget _buildRow(
    DetailInfoRow row,
    Color iconColor,
    Color labelColor,
    Color defaultValueColor,
  ) {
    final child = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(row.icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            row.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              row.value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: row.valueColor ?? defaultValueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (row.showChevron) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: labelColor,
            ),
          ],
        ],
      ),
    );

    if (row.onTap != null) {
      return GestureDetector(onTap: row.onTap, child: child);
    }
    return child;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/features/accounting/presentation/widgets/detail_info_card_test.dart`
Expected: PASS — all 4 tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounting/presentation/widgets/detail_info_card.dart test/widget/features/accounting/presentation/widgets/detail_info_card_test.dart
git commit -m "feat(accounting): add DetailInfoCard widget for Wa-Modern detail rows"
```

---

## Task 2: Create SatisfactionEmojiPicker Widget

**Purpose:** Replace the 10-segment slider with a 5-emoji-face picker. Maps 5 faces to satisfaction values (1-2, 3-4, 5-6, 7-8, 9-10). Design shows faces: 不満 (displeased), 普通 (neutral), and 最高！ (excellent) labels below.

**Files:**
- Create: `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart`
- Test: `test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart`

### Design Spec (from Pencil node `SnvOC`)
- Header row: "満足度" label (Outfit 13px w600) left, descriptive text right (e.g. "とても良い", Outfit 12px w600, `#47B88A` soul green)
- 5 face buttons: 52×52, cornerRadius 14, bg `#F5F4F2`, each with an emoji face icon
- Selected face: bg `#E5F5ED` (soul light), border 2px `#47B88A` (soul green)
- Label row below: "不満" left, "普通" center, "最高！" right (Outfit 10px w500, `#ABABAB`)
- Gap between header and faces: 12, faces to labels: implied by layout

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart';

void main() {
  group('SatisfactionEmojiPicker', () {
    Widget buildTestWidget({
      required int value,
      required ValueChanged<int> onChanged,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: SatisfactionEmojiPicker(
            value: value,
            onChanged: onChanged,
            title: '満足度',
            levelLabels: const ['不満', 'やや不満', '普通', '良い', 'とても良い'],
            bottomLabels: const ['不満', '普通', '最高！'],
          ),
        ),
      );
    }

    testWidgets('renders 5 face buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        value: 5,
        onChanged: (_) {},
      ));

      // 5 emoji face icons
      final faceButtons = find.byType(GestureDetector);
      expect(faceButtons, findsAtLeast(5));
    });

    testWidgets('renders satisfaction labels', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        value: 5,
        onChanged: (_) {},
      ));

      expect(find.text('不満'), findsOneWidget);
      expect(find.text('普通'), findsOneWidget);
      expect(find.text('最高！'), findsOneWidget);
    });

    testWidgets('tapping a face calls onChanged with mapped value', (tester) async {
      int? newVal;
      await tester.pumpWidget(buildTestWidget(
        value: 5,
        onChanged: (v) => newVal = v,
      ));

      // Tap the last face (index 4 → value 9-10 → we map to 10)
      final faces = find.byKey(const ValueKey('face_4'));
      await tester.tap(faces);
      expect(newVal, 10);
    });

    testWidgets('shows header with satisfaction label text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        value: 7,
        onChanged: (_) {},
      ));

      expect(find.text('満足度'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart`
Expected: FAIL — `satisfaction_emoji_picker.dart` does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 5-face emoji picker for soul satisfaction (maps to 1-10 scale).
///
/// Replaces the 10-segment slider with a more intuitive emoji-based picker
/// matching the Wa-Modern design system.
///
/// All label strings are passed via constructor for i18n support.
/// Caller provides `S.of(context).satisfactionLevel`, etc.
class SatisfactionEmojiPicker extends StatelessWidget {
  const SatisfactionEmojiPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.levelLabels,
    required this.bottomLabels,
  });

  /// Current satisfaction value (1-10).
  final int value;

  /// Called with new value when user taps a face.
  final ValueChanged<int> onChanged;

  /// Header label (e.g. "満足度").
  final String title;

  /// 5 descriptive labels for each level, indexed 0-4.
  /// e.g. ["不満", "やや不満", "普通", "良い", "とても良い"]
  final List<String> levelLabels;

  /// 3 labels for bottom scale: [low, mid, high].
  /// e.g. ["不満", "普通", "最高！"]
  final List<String> bottomLabels;

  /// Maps face index (0-4) to satisfaction value.
  static const _faceValues = [2, 4, 6, 8, 10];

  /// Emoji icons for each face level.
  static const _faceIcons = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  int get _selectedIndex {
    if (value <= 2) return 0;
    if (value <= 4) return 1;
    if (value <= 6) return 2;
    if (value <= 8) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIdx = _selectedIndex;

    return Column(
      children: [
        // Header: title + level label
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: isDark
                    ? AppColorsDark.textPrimary
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              levelLabels[selectedIdx],
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.soul,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 5 face buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final isSelected = i == selectedIdx;
            return GestureDetector(
              key: ValueKey('face_$i'),
              onTap: () => onChanged(_faceValues[i]),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColorsDark.tagGreen : AppColors.soulLight)
                      : (isDark
                          ? AppColorsDark.backgroundMuted
                          : AppColors.backgroundMuted),
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? Border.all(color: AppColors.soul, width: 2)
                      : null,
                ),
                child: Icon(
                  _faceIcons[i],
                  size: 24,
                  color: isSelected
                      ? AppColors.soul
                      : (isDark
                          ? AppColorsDark.textSecondary
                          : AppColors.textSecondary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Bottom labels: low / mid / high
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in bottomLabels)
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColorsDark.textSecondary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart`
Expected: PASS — all 4 tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart
git commit -m "feat(accounting): add SatisfactionEmojiPicker with 5-face design"
```

---

## Task 3: Refactor TransactionEntryScreen

**Purpose:** Update the entry screen to match the Wa-Modern design — warm ivory background, replace horizontal selector chips with a DetailInfoCard, and ensure dark mode support.

**Files:**
- Modify: `lib/features/accounting/presentation/screens/transaction_entry_screen.dart`
- Test: `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart`

### Design Changes
1. Background: `Color(0xFFF5F9FD)` → `AppColors.background` (`#FCFBF9`)
2. Replace horizontal `Row` of `_SelectorChip` widgets with `DetailInfoCard` containing 2 rows (Date, Category)
3. Remove `_SelectorChip` private class (no longer needed)
4. Dark mode: scaffold bg → `AppColorsDark.background`

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/detail_info_card.dart';

void main() {
  // This test verifies the new design pattern exists in the widget tree.
  // Full integration test requires Riverpod container + repository mocks.
  testWidgets('DetailInfoCard renders in a card-like container', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DetailInfoCard(
          rows: [
            DetailInfoRow(
              icon: Icons.calendar_today,
              label: '日付',
              value: '今日',
              showChevron: true,
            ),
            DetailInfoRow(
              icon: Icons.grid_view,
              label: 'カテゴリ',
              value: '食費 › コンビニ',
              showChevron: true,
            ),
          ],
        ),
      ),
    ));

    // Verify card-based layout exists
    expect(find.text('日付'), findsOneWidget);
    expect(find.text('カテゴリ'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });
}
```

- [ ] **Step 2: Run test to verify it passes (widget-level test for the card)**

Run: `flutter test test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart`
Expected: PASS (tests the new widget being integrated)

- [ ] **Step 3: Refactor the TransactionEntryScreen**

In `lib/features/accounting/presentation/screens/transaction_entry_screen.dart`:

**Change 1:** Update background color
```dart
// OLD
backgroundColor: const Color(0xFFF5F9FD),
// NEW
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColorsDark.background
    : AppColors.background,
```

**Change 2:** Replace selector chips Row with DetailInfoCard
```dart
// OLD (lines ~276-300): Padding > Row > _SelectorChip, _SelectorChip
// NEW:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: DetailInfoCard(
    rows: [
      DetailInfoRow(
        icon: Icons.calendar_today_outlined,
        label: l10n.date,
        value: _isToday
            ? l10n.todayDate
            : DateFormatter.formatDate(_selectedDate, locale),
        showChevron: true,
        onTap: _selectDate,
      ),
      DetailInfoRow(
        icon: _categoryChipIcon(),
        label: l10n.category,
        value: _categoryChipLabel(locale, l10n.selectCategory),
        showChevron: true,
        onTap: _selectCategory,
      ),
    ],
  ),
),
```

**Change 3:** Remove the `_SelectorChip` private class entirely (lines 330-375)

**Change 4:** Add import for `detail_info_card.dart`
```dart
import '../widgets/detail_info_card.dart';
```

- [ ] **Step 4: Run analyzer and existing tests**

Run: `flutter analyze lib/features/accounting/presentation/screens/transaction_entry_screen.dart && flutter test`
Expected: 0 analyzer issues, all tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounting/presentation/screens/transaction_entry_screen.dart test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart
git commit -m "refactor(accounting): redesign TransactionEntryScreen with DetailInfoCard layout"
```

---

## Task 4: Refactor TransactionConfirmScreen

**Purpose:** Update the confirm screen to use DetailInfoCard for the detail section, SatisfactionEmojiPicker for satisfaction, and pin the save button to the bottom.

**Files:**
- Modify: `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`

### Design Changes
1. Background: match `AppColors.background`
2. AppBar: back button with "< 戻る" text in survival blue (left), title "支出の詳細" centered
3. Detail section: use `DetailInfoCard` with rows for Amount, Category, Date, Store
4. Memo section: as trailing widget of DetailInfoCard — label + gray bg textarea
5. Ledger Card: separate card with "支出の分類" title, Survival/Soul toggle, SatisfactionEmojiPicker
6. Photo button: bordered card-style button "写真を追加" with camera icon
7. Save button: bottom-pinned outside scrollable area, coral gradient, "記録する"
8. Replace `SoulSatisfactionSlider` import with `SatisfactionEmojiPicker`

- [ ] **Step 1: Read the full confirm screen file**

Read: `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (all lines)
Purpose: Understand the full structure before making changes

- [ ] **Step 2: Update AppBar to match design**

```dart
// Replace existing AppBar with:
appBar: AppBar(
  backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
  elevation: 0,
  scrolledUnderElevation: 0,
  leading: GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left, size: 20, color: AppColors.survival),
          Text(
            l10n.back,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.survival,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  ),
  title: Text(l10n.expenseDetail, style: AppTextStyles.headlineMedium),
  centerTitle: true,
),
```

- [ ] **Step 3: Replace detail section with DetailInfoCard**

First, add these helper methods/getters to `_TransactionConfirmScreenState`:
```dart
String get _categoryLabel {
  if (_category == null) return '';
  return formatCategoryPath(
    category: _category!,
    parentCategory: _parentCategory,
    locale: ref.read(currentLocaleProvider),
  );
}

Widget _buildMemoSection(bool isDark) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_outlined, size: 16,
              color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(S.of(context).note,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w500,
              )),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _memoController,
            maxLines: null,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration.collapsed(hintText: ''),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSaveButton() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: _isSubmitting ? null : _save,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.fabShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: _isSubmitting
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
              )
            : Text(S.of(context).record,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                )),
      ),
    ),
  );
}
```

Then replace the manually built `_DetailRow` widgets with:
```dart
DetailInfoCard(
  rows: [
    DetailInfoRow(
      icon: Icons.payments_outlined,
      label: l10n.amount,
      value: NumberFormatter.formatCurrency(_amount, 'JPY', locale),
      showChevron: true,
      onTap: _editAmount,
    ),
    DetailInfoRow(
      icon: Icons.shopping_bag_outlined,
      label: l10n.category,
      value: _categoryLabel,
      showChevron: true,
      onTap: _editCategory,
    ),
    DetailInfoRow(
      icon: Icons.calendar_today_outlined,
      label: l10n.date,
      value: DateFormatter.formatDate(_date, locale),
      showChevron: true,
      onTap: _editDate,
    ),
    DetailInfoRow(
      icon: Icons.store_outlined,
      label: l10n.merchant,
      value: _storeController.text.isEmpty ? '' : _storeController.text,
    ),
  ],
  trailing: _buildMemoSection(isDark),
),
```

Note: `_editAmount`, `_editCategory`, `_editDate` already exist in the current code. Remove the old `_DetailRow` and `_Divider` private classes and the old `_formatAmount` helper method.

- [ ] **Step 4: Replace SoulSatisfactionSlider with SatisfactionEmojiPicker in Ledger Card**

```dart
// OLD
import '../widgets/soul_satisfaction_slider.dart';
// ...
SoulSatisfactionSlider(
  value: _soulSatisfaction,
  onChanged: (v) => setState(() => _soulSatisfaction = v),
  label: l10n.soulSatisfaction,
),

// NEW
import '../widgets/satisfaction_emoji_picker.dart';
// ...
SatisfactionEmojiPicker(
  value: _soulSatisfaction,
  onChanged: (v) => setState(() => _soulSatisfaction = v),
  title: l10n.satisfactionLevel,
  levelLabels: [
    l10n.satisfactionBad,
    l10n.satisfactionSlightlyBad,
    l10n.satisfactionNormal,
    l10n.satisfactionGood,
    l10n.satisfactionVeryGood,
  ],
  bottomLabels: [
    l10n.satisfactionBad,
    l10n.satisfactionNormal,
    l10n.satisfactionExcellent,
  ],
),
```

- [ ] **Step 5: Pin save button to bottom**

At the top of the `build` method, add:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

Restructure body to:
```dart
body: Column(
  children: [
    Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          children: [
            // DetailInfoCard, LedgerCard, PhotoBtn ...
          ],
        ),
      ),
    ),
    // Bottom-pinned save button
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _buildSaveButton(),
    ),
  ],
),
```

- [ ] **Step 6: Remove old _DetailRow and _Divider private classes**

Delete the `_DetailRow` and `_Divider` classes that are no longer used.

- [ ] **Step 7: Run analyzer and tests**

Run: `flutter analyze lib/features/accounting/presentation/screens/transaction_confirm_screen.dart && flutter test`
Expected: 0 analyzer issues, all tests pass

- [ ] **Step 8: Commit**

```bash
git add lib/features/accounting/presentation/screens/transaction_confirm_screen.dart
git commit -m "refactor(accounting): redesign TransactionConfirmScreen with DetailInfoCard and emoji picker"
```

---

## Task 5: Refactor CategorySelectionScreen

**Purpose:** Update category screen to use category-colored borders/chips instead of uniform survival blue, warm ivory background, and add the "カテゴリを追加" button at bottom.

**Files:**
- Modify: `lib/features/accounting/presentation/screens/category_selection_screen.dart`
- Test: `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart`

### Design Changes
1. Background: `Color(0xFFF5F9FD)` → `AppColors.background`
2. Search box: bg `#F5F4F2` (`AppColors.backgroundMuted`), cornerRadius 12, icon search, placeholder "カテゴリを検索"
3. Expanded group border: use the **category's own color** (not always survival blue)
4. L2 chips: selected chip uses **category's own color** as bg with white text; inactive chips use category's light tint
5. Active L1 group: expanded state shows chevron-up; collapsed shows chevron-right
6. Add "＋追加" chip in expanded L2 section (stub — just UI, no action yet)
7. Bottom: "カテゴリを追加" button (circle-plus icon + label, bordered, full width)
8. Dark mode support for all colors

- [ ] **Step 1: Update background color**

```dart
// OLD
backgroundColor: const Color(0xFFF5F9FD),
// NEW
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColorsDark.background
    : AppColors.background,
```

- [ ] **Step 2: Update search box styling**

```dart
// OLD
fillColor: const Color(0xFFF5F9FD),
// NEW
fillColor: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
```

- [ ] **Step 3: Update _CategoryGroup to use category's own color for border and chips**

In the `_CategoryGroup.build` method:
```dart
// OLD — always survival blue
border: isExpanded
    ? Border.all(color: AppColors.survival, width: 1.5)
    : null,

// NEW — use category's own color
border: isExpanded
    ? Border.all(color: color, width: 1.5)
    : Border.all(color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault),
```

For L2 chips:
```dart
// OLD — survival colors
color: isSelected ? AppColors.survival : const Color(0xFFEEF4FA),
// ...
color: isSelected ? Colors.white : AppColors.survival,

// NEW — category-aware colors
color: isSelected ? color : color.withValues(alpha: 0.1),
// ...
color: isSelected ? Colors.white : color,
```

- [ ] **Step 4: Add "＋追加" chip to L2 section**

After the existing `children.map(...)` in the L2 chips Wrap, add:
```dart
GestureDetector(
  onTap: () {
    // TODO: Implement add L2 category
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          l10n.addSubcategory,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 5: Add "カテゴリを追加" button at bottom of list**

After the ListView in the Column, add:
```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  child: GestureDetector(
    onTap: () {
      // TODO: Implement add L1 category
    },
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            l10n.addCategory,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  ),
),
```

- [ ] **Step 6: Pass dark mode flag to _CategoryGroup**

Add `isDark` parameter to `_CategoryGroup` and thread it through.

- [ ] **Step 7: Run analyzer and tests**

Run: `flutter analyze lib/features/accounting/presentation/screens/category_selection_screen.dart && flutter test`
Expected: 0 analyzer issues, all tests pass

- [ ] **Step 8: Commit**

```bash
git add lib/features/accounting/presentation/screens/category_selection_screen.dart
git commit -m "refactor(accounting): redesign CategorySelectionScreen with per-category colors"
```

---

## Task 6: Refactor VoiceInputScreen

**Purpose:** Update the voice input screen to show a unified transcript card with parsed results in a list-row format, matching the Wa-Modern design.

**Files:**
- Modify: `lib/features/accounting/presentation/screens/voice_input_screen.dart`

### Design Changes
1. Background: warm ivory `AppColors.background`
2. Transcript area: single white card containing:
   - "認識結果" label (Outfit 11px w500, letterSpacing 2, `#ABABAB`)
   - Transcript text (Outfit 18px w600, centered, lineHeight 1.4)
   - Divider
   - Parsed results list card (same row pattern as DetailInfoCard): Amount, Category, Date rows
3. Waveform: thin vertical bars with survival blue gradient opacity
4. Mic button: 72×72 circle with coral gradient, drop shadow, mic icon 32px white
5. Hint: "タップして録音" below mic button
6. Next button: full width coral gradient, bottom-pinned

- [ ] **Step 1: Read the full voice input screen**

Read: `lib/features/accounting/presentation/screens/voice_input_screen.dart`
Purpose: Understand current structure before modifying

- [ ] **Step 2: Update background color**

```dart
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColorsDark.background
    : AppColors.background,
```

- [ ] **Step 3: Add computed getters for transcript and parsed data**

Add these to `_VoiceInputScreenState`:
```dart
String get _transcriptText =>
    _finalText.isNotEmpty ? _finalText : _partialText;

String get _parsedAmountText {
  final amount = _parseResult?.amount;
  if (amount == null) return '';
  return NumberFormatter.formatCurrency(amount, 'JPY', ref.read(currentLocaleProvider));
}

String get _parsedCategoryText {
  final cat = _parseResult?.categoryName;
  return cat ?? '';
}

String get _parsedDateText {
  return S.of(context).todayDate;
}
```

- [ ] **Step 4: Replace transcript card section**

Replace `VoiceTranscriptCard` and `VoiceParsePreview` with a unified card.
Remove imports for `voice_transcript_card.dart` and `voice_parse_preview.dart`.
Add import for `detail_info_card.dart`.

```dart
Container(
  decoration: BoxDecoration(
    color: isDark ? AppColorsDark.card : AppColors.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
    ),
  ),
  padding: const EdgeInsets.all(20),
  child: Column(
    children: [
      Text(
        l10n.recognitionResult,
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _transcriptText,
        style: AppTextStyles.titleLarge.copyWith(
          color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Container(height: 1, color: isDark ? AppColorsDark.backgroundDivider : AppColors.backgroundDivider),
      const SizedBox(height: 4),
      // Parsed results — borderless card (inline rows, not nested card)
      _buildParsedRow(Icons.payments_outlined, l10n.amount, _parsedAmountText, isDark),
      _buildParsedDivider(isDark),
      _buildParsedRow(Icons.shopping_bag_outlined, l10n.category, _parsedCategoryText, isDark),
      _buildParsedDivider(isDark),
      _buildParsedRow(Icons.calendar_today_outlined, l10n.date, _parsedDateText, isDark),
    ],
  ),
),
```

Add these helper methods to the State class:
```dart
Widget _buildParsedRow(IconData icon, String label, String value, bool isDark) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
    child: Row(
      children: [
        Icon(icon, size: 16,
          color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
          fontSize: 13, fontWeight: FontWeight.w500,
        )),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
          fontSize: 14, fontWeight: FontWeight.w600,
        )),
      ],
    ),
  );
}

Widget _buildParsedDivider(bool isDark) {
  return Container(
    height: 1,
    color: isDark ? AppColorsDark.backgroundDivider : AppColors.backgroundDivider,
  );
}
```

Note: We use inline row helpers instead of nesting `DetailInfoCard` to avoid a double-card visual artifact (the outer container already provides the card styling).

- [ ] **Step 4: Update mic button to match design**

```dart
Container(
  width: 72,
  height: 72,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.fabShadow,
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: const Icon(Icons.mic, size: 32, color: Colors.white),
),
```

- [ ] **Step 5: Delete dead widget files**

Verify no remaining imports:
```bash
grep -r "voice_transcript_card" lib/
grep -r "voice_parse_preview" lib/
```
Expected: 0 matches (imports already removed in Step 4)

Delete:
```bash
rm lib/features/accounting/presentation/widgets/voice_transcript_card.dart
rm lib/features/accounting/presentation/widgets/voice_parse_preview.dart
```

- [ ] **Step 6: Run analyzer and tests**

Run: `flutter analyze lib/features/accounting/presentation/screens/voice_input_screen.dart && flutter test`
Expected: 0 analyzer issues, all tests pass

- [ ] **Step 7: Commit**

```bash
git add lib/features/accounting/presentation/screens/voice_input_screen.dart
git rm lib/features/accounting/presentation/widgets/voice_transcript_card.dart
git rm lib/features/accounting/presentation/widgets/voice_parse_preview.dart
git commit -m "refactor(accounting): redesign VoiceInputScreen, remove dead transcript widgets"
```

---

## Task 7: Update Supporting Widgets for Dark Mode

**Purpose:** Ensure SmartKeyboard, AmountDisplay, InputModeTabs, and LedgerTypeSelector all properly support dark mode using AppColorsDark tokens.

**Files:**
- Modify: `lib/features/accounting/presentation/widgets/smart_keyboard.dart`
- Modify: `lib/features/accounting/presentation/widgets/amount_display.dart`
- Modify: `lib/features/accounting/presentation/widgets/input_mode_tabs.dart`
- Modify: `lib/features/accounting/presentation/widgets/ledger_type_selector.dart`

### Changes Per Widget

**SmartKeyboard:**
- Key bg: `isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted`
- Key text: `isDark ? AppColorsDark.textPrimary : AppColors.textPrimary`
- Container bg: `isDark ? AppColorsDark.card : AppColors.card`
- Top border: `isDark ? AppColorsDark.borderDefault : AppColors.borderDefault`

**AmountDisplay:**
- Currency badge bg: survival light in both modes
- Amount text color: theme-aware

**InputModeTabs:**
- Tab bar bg: `isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted`
- Active tab: `isDark ? AppColorsDark.card : AppColors.card` with shadow
- Active text/icon: `AppColors.accentPrimary`
- Inactive text/icon: theme-aware secondary

**LedgerTypeSelector:**
- Toggle bg: theme-aware backgroundMuted
- Active segment bg/text: survival or soul colors (same in both modes)
- Inactive text: theme-aware secondary

- [ ] **Step 1: Update SmartKeyboard dark mode**

Read and modify `lib/features/accounting/presentation/widgets/smart_keyboard.dart`:
- Add `final isDark = Theme.of(context).brightness == Brightness.dark;`
- Replace all hardcoded colors with theme-aware variants

- [ ] **Step 2: Update AmountDisplay dark mode**

Read and modify `lib/features/accounting/presentation/widgets/amount_display.dart`:
- Theme-aware text and background colors

- [ ] **Step 3: Update InputModeTabs dark mode**

Read and modify `lib/features/accounting/presentation/widgets/input_mode_tabs.dart`:
- Theme-aware tab bar and active/inactive states

- [ ] **Step 4: Update LedgerTypeSelector dark mode**

Read and modify `lib/features/accounting/presentation/widgets/ledger_type_selector.dart`:
- Theme-aware toggle background and inactive text

- [ ] **Step 5: Run analyzer and tests**

Run: `flutter analyze && flutter test`
Expected: 0 analyzer issues, all tests pass

- [ ] **Step 6: Commit**

```bash
git add lib/features/accounting/presentation/widgets/smart_keyboard.dart lib/features/accounting/presentation/widgets/amount_display.dart lib/features/accounting/presentation/widgets/input_mode_tabs.dart lib/features/accounting/presentation/widgets/ledger_type_selector.dart
git commit -m "refactor(accounting): add dark mode support to entry widgets"
```

---

## Task 8: Delete Old SoulSatisfactionSlider

**Purpose:** Clean up the replaced widget file.

**Files:**
- Delete: `lib/features/accounting/presentation/widgets/soul_satisfaction_slider.dart`

- [ ] **Step 1: Verify no remaining imports**

Run: `grep -r "soul_satisfaction_slider" lib/`
Expected: 0 matches (already replaced in Task 4)

- [ ] **Step 2: Delete the file**

```bash
rm lib/features/accounting/presentation/widgets/soul_satisfaction_slider.dart
```

- [ ] **Step 3: Run analyzer and tests**

Run: `flutter analyze && flutter test`
Expected: 0 issues, all tests pass

- [ ] **Step 4: Commit**

```bash
git rm lib/features/accounting/presentation/widgets/soul_satisfaction_slider.dart
git commit -m "chore(accounting): remove deprecated SoulSatisfactionSlider widget"
```

---

## Task 9: Final Verification and Visual QA

**Purpose:** Run the full test suite, verify analyzer is clean, and do a final visual check.

- [ ] **Step 1: Run full analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 2: Run full test suite**

Run: `flutter test --coverage`
Expected: All tests pass, coverage ≥ 80%

- [ ] **Step 3: Build and run on simulator**

Run: `flutter run` (or verify build succeeds with `flutter build ios --debug`)
Expected: App builds and runs without errors

- [ ] **Step 4: Visual verification checklist**

Manually verify (or screenshot-compare) each screen:
- [ ] Transaction Entry (Light) matches Pencil node `bEeOY`
- [ ] Transaction Entry (Dark) matches Pencil node `50Lfv`
- [ ] Voice Input (Light) matches Pencil node `bmacP`
- [ ] Voice Input (Dark) matches Pencil node `efb8D`
- [ ] Confirm (Light) matches Pencil node `SnvOC`
- [ ] Confirm (Dark) matches Pencil node `n8vpV`
- [ ] Category (Light) matches Pencil node `MkNZo`
- [ ] Category (Dark) matches Pencil node `mQUCn`

- [ ] **Step 5: Final commit (if any fixes)**

```bash
git add -A
git commit -m "fix(accounting): visual polish for transaction entry screens"
```

---

## Summary

| Task | Description | Est. Effort |
|------|-------------|-------------|
| 0 | Add i18n ARB entries | S |
| 1 | Create DetailInfoCard widget | S |
| 2 | Create SatisfactionEmojiPicker widget | S |
| 3 | Refactor TransactionEntryScreen | M |
| 4 | Refactor TransactionConfirmScreen | L |
| 5 | Refactor CategorySelectionScreen | M |
| 6 | Refactor VoiceInputScreen | M |
| 7 | Dark mode for supporting widgets | M |
| 8 | Delete old SoulSatisfactionSlider | S |
| 9 | Final verification and visual QA | S |

**Dependencies:** Task 0 must complete first (i18n keys needed by all widgets). Tasks 1-2 must complete before Tasks 3-6. Tasks 3-7 are independent of each other. Task 8 depends on Task 4. Task 9 runs last.

**Parallelizable:** After Task 0, Tasks 1 and 2 can run in parallel. After Tasks 1-2, Tasks 3, 4, 5, 6, 7 can all run in parallel (independent screen refactorings).
