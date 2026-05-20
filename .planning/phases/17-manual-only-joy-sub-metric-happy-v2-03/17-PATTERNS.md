# Phase 17: Manual-Only Joy Sub-Metric (HAPPY-V2-03) — Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 19 new/modified files (5 new, 14 modified)
**Analogs found:** 19 / 19 (100% coverage — every file has a precedent in-codebase from Phase 13–16)

---

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| **NEW** `lib/features/accounting/domain/models/entry_source.dart` | domain-model (enum) | n/a (value object) | `lib/features/accounting/domain/models/transaction.dart` (LedgerType enum, line 8) | exact (sibling enum) |
| **NEW** `lib/features/analytics/presentation/providers/state_joy_metric_variant.dart` | provider (Riverpod notifier) | session-state | `lib/features/analytics/presentation/providers/state_time_window.dart` | exact |
| **NEW** `lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart` | widget (ConsumerWidget AppBar chip) | request-response (tap → sheet → set) | `lib/features/analytics/presentation/widgets/time_window_chip.dart` | exact |
| **NEW** `test/unit/data/migrations/migration_v16_to_v17_test.dart` | test (Drift migration) | round-trip | `test/unit/data/migrations/migration_v15_to_v16_test.dart` | exact |
| **NEW** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` (or extend Phase 16 file) | test (widget i18n sweep) | render-and-assert | `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | exact (extend list + states) |
| **MOD** `lib/data/tables/transactions_table.dart` | data-table (Drift schema) | DDL | self (soulSatisfaction column, line 35) | exact (sibling column) |
| **MOD** `lib/data/app_database.dart:45` | data (migration block) | DDL migration | self (`if (from < 11)` addColumn block, lines 130-135) | exact (sibling migration step) |
| **MOD** `lib/data/daos/transaction_dao.dart` | data-DAO | CRUD insert | self (`insertTransaction` method, lines 11-55) | exact (extend signature) |
| **MOD** `lib/data/daos/analytics_dao.dart` (12+ methods) | data-DAO | aggregate-read | self (`getBestJoyMoment` lines 373-404; Phase 16 `bookIds: List<String>` precedent in `getSharedJoyCategoryInsight` lines 441-465) | exact |
| **MOD** `lib/features/accounting/domain/models/transaction.dart` | domain-model (Freezed) | n/a | self (`soulSatisfaction` field with `@Default(2)`, line 42) | exact (sibling field) |
| **MOD** `lib/application/accounting/create_transaction_use_case.dart` | use-case | request-response | self (`CreateTransactionParams` lines 14-37, threading lines 144-159) | exact |
| **MOD** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | screen (ConsumerStatefulWidget) | request-response | self (constructor lines 28-44, params build lines 298-317) | exact |
| **MOD** `lib/features/accounting/presentation/screens/voice_input_screen.dart:352` | screen (push site) | navigation | self (existing `Navigator.push` to `TransactionConfirmScreen`, lines 350-364) | exact |
| **MOD** `lib/features/accounting/presentation/screens/transaction_entry_screen.dart:225` | screen (push site) | navigation | self (existing `Navigator.push`, lines 223-233) | exact |
| **MOD** `lib/application/analytics/demo_data_service.dart:103,137` | service (seed) | batch insert | self (existing `insertTransaction` calls) | exact |
| **MOD** `lib/features/accounting/domain/models/transaction_sync_mapper.dart` | domain (mapper) | serialize/deserialize | self (`soulSatisfaction` round-trip, lines 31 + 58) | exact |
| **MOD** `lib/application/analytics/*_use_case.dart` (10+ files) | use-case | aggregate-read | self (`GetPerCategorySoulBreakdownAcrossBooksUseCase.execute`, lines 26-44 — Phase 16 added `bookIds: List<String>` here) | exact |
| **MOD** `lib/features/analytics/presentation/providers/state_*.dart` (`state_happiness.dart`, `state_analytics.dart`, `state_ledger_snapshot.dart`) | provider (Riverpod family) | aggregate-read | self (`happinessReport` family-keyed Future provider, `state_happiness.dart` lines 14-30) | exact |
| **MOD** `lib/features/analytics/presentation/screens/analytics_screen.dart` | screen (AppBar.actions, `_refresh`) | composition | self (`AppBar.actions` lines 67-75; `_refresh` lines 200-284) | exact |
| **MOD** `lib/l10n/app_{en,ja,zh}.arb` (5 keys × 3 locales) | i18n | resource | self (`analyticsTimeWindowChip*` family, `app_en.arb` lines 1697-1727) | exact |
| **MOD** `.planning/ROADMAP.md` (SC-3 wording) | docs | text edit | Phase 16 D-15 ROADMAP correction pattern | exact (same pattern) |

---

## Pattern Assignments

### NEW `lib/features/accounting/domain/models/entry_source.dart` (domain-model, enum)

**Analog:** `lib/features/accounting/domain/models/transaction.dart` (sibling `LedgerType` enum, line 8)

**Existing pattern** (`transaction.dart:1-9`):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType { expense, income, transfer }

enum LedgerType { survival, soul }
```

**Copy semantics:**
- Plain top-level Dart enum, no `@freezed`, no annotations.
- Member names directly correspond to SQL column values via `EntrySource.name` (verified by `LedgerType.values.byName(data['ledgerType'] as String)` precedent in `transaction_sync_mapper.dart:48`).
- Planner discretion (per D-01 + CONTEXT "Claude's Discretion"): either create a new `entry_source.dart` file OR append the enum to `transaction.dart` next to `LedgerType`. The new-file option is preferred for grep-ability and aligns with `lib/features/analytics/domain/models/time_window.dart` precedent for single-enum files.

**Required values:** `enum EntrySource { manual, voice, ocr }` — order matters only for `.values` iteration, not persistence.

---

### NEW `lib/features/analytics/presentation/providers/state_joy_metric_variant.dart` (provider, session-state)

**Analog:** `lib/features/analytics/presentation/providers/state_time_window.dart` (full file, 22 lines)

**Imports + part directive pattern** (`state_time_window.dart:1-5`):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/time_window.dart';

part 'state_time_window.g.dart';
```

**Core notifier pattern** (`state_time_window.dart:7-21`):
```dart
/// Session-scoped AnalyticsScreen time-window selection (D-12: HomeHero is NOT
/// a consumer). Default = current calendar month per ADR-016 §3 ring semantics
/// consistency.
@riverpod
class SelectedTimeWindow extends _$SelectedTimeWindow {
  @override
  TimeWindow build() {
    final now = DateTime.now();
    return TimeWindow.month(year: now.year, month: now.month);
  }

  void setWindow(TimeWindow window) {
    state = window;
  }
}
```

**Copy semantics for Phase 17:**
- Class name `SelectedJoyMetricVariant extends _$SelectedJoyMetricVariant` → generates `selectedJoyMetricVariantProvider` (Riverpod 3 strips `Notifier` suffix; this rule is documented in project CLAUDE.md and verified by precedent).
- `build()` returns `JoyMetricVariant.all` (D-10 default).
- Mutator `void setVariant(JoyMetricVariant variant) { state = variant; }`.
- No persistence — session-only is automatic for `@riverpod` notifiers (Phase 15 D-12 precedent).
- The `JoyMetricVariant` enum (`{ all, manualOnly }`) is defined at the top of this file per project pattern. (Alternative: define alongside `EntrySource` enum — planner discretion. Recommended: keep `JoyMetricVariant` co-located with its provider, since it is a UI-state enum, not a domain enum.)
- Import `riverpod_annotation/riverpod_annotation.dart` only — do NOT import `flutter_riverpod/legacy.dart` (Pitfall #6 from RESEARCH).

---

### NEW `lib/features/analytics/presentation/widgets/joy_metric_variant_chip.dart` (widget, AppBar chip)

**Analog:** `lib/features/analytics/presentation/widgets/time_window_chip.dart` (full file, 99 lines)

**Imports pattern** (`time_window_chip.dart:1-11`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/time_window.dart';
import '../providers/state_time_window.dart';
import 'time_window_picker_sheet.dart';
```

**ConsumerWidget chip pattern** (`time_window_chip.dart:13-71`):
```dart
class TimeWindowChip extends ConsumerWidget {
  const TimeWindowChip({super.key, required this.locale, this.earliestData});

  final Locale locale;
  final DateTime? earliestData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final window = ref.watch(selectedTimeWindowProvider);
    final label = _labelFor(window, l10n, locale);

    return Tooltip(
      message: l10n.analyticsTimeWindowChipTooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => TimeWindowPickerSheet.show(
            context,
            ref,
            earliestData: earliestData,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.wmCard,
                border: Border.all(color: context.wmBorderDefault),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextPrimary)),
                    const SizedBox(width: 4),
                    Text('▼', style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Copy semantics for Phase 17:**
- Same `ConsumerWidget` + `Tooltip` + `InkWell` + `DecoratedBox` chip layout. Same min 44×44 tap target (accessibility).
- Same `context.wmCard` / `context.wmBorderDefault` / `AppTextStyles.bodyMedium` theme tokens — `app_theme_colors.dart` extension already exposes them.
- `ref.watch(selectedJoyMetricVariantProvider)` replaces `selectedTimeWindowProvider`; label is `JoyMetricVariant.all → l10n.analyticsJoyMetricVariantOptionAll` etc. (D-13 keys).
- `onTap` opens either a bottom sheet (matches `TimeWindowPickerSheet.show()` pattern — recommended) OR a `PopupMenuButton` (planner discretion per D-12). Bottom sheet is consistent with `TimeWindowChip` and `MonthChipPicker`; popup is simpler for 2 options. **Recommendation: bottom sheet — only because 2-option `PopupMenuButton` in AppBar density is awkward, and a bottom sheet has room for the "manualOnly · excludes voice-estimated entries" explanation copy (D-13 key `analyticsJoyMetricVariantManualOnlyExplain`).**
- `_labelFor` becomes a simple `switch (variant)` over the 2-value enum (much shorter than the `TimeWindow` sealed-class switch).

---

### NEW `test/unit/data/migrations/migration_v16_to_v17_test.dart` (test, migration round-trip)

**Analog:** `test/unit/data/migrations/migration_v15_to_v16_test.dart` (full file, 93 lines)

**Imports + setup pattern** (`migration_v15_to_v16_test.dart:1-17`):
```dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

const _targetSchemaVersion = 16;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });
```

**Schema version + default assertion pattern** (`migration_v15_to_v16_test.dart:18-31`):
```dart
group('v16 soul satisfaction default migration', () {
  test('AppDatabase schemaVersion is 16', () {
    expect(db.schemaVersion, _targetSchemaVersion);
  });

  test('omitted soulSatisfaction stores default 2', () async {
    await _insertTransaction(db, id: 'tx_default');
    final row = await _findTransaction(db, 'tx_default');
    expect(row.soulSatisfaction, equals(2));
  });
```

**CHECK constraint violation assertion** (`migration_v15_to_v16_test.dart:33-42`):
```dart
test('rejects soulSatisfaction above 10', () async {
  expect(
    () => _insertTransaction(
      db,
      id: 'tx_invalid_high',
      soulSatisfaction: const Value(11),
    ),
    throwsA(isA<Object>()),
  );
});
```

**Helper functions pattern** (`migration_v15_to_v16_test.dart:63-92`):
```dart
Future<void> _insertTransaction(
  AppDatabase db, {
  required String id,
  Value<int> soulSatisfaction = const Value.absent(),
}) async {
  final now = DateTime(2026, 5, 2, 12);
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: id,
          bookId: 'book_v16',
          deviceId: 'device_v16',
          amount: 1200,
          type: 'expense',
          categoryId: 'cat_joy',
          ledgerType: 'soul',
          timestamp: now,
          currentHash: 'hash_$id',
          createdAt: now,
          soulSatisfaction: soulSatisfaction,
        ),
      );
}

Future<TransactionRow> _findTransaction(AppDatabase db, String id) {
  return (db.select(
    db.transactions,
  )..where((row) => row.id.equals(id))).getSingle();
}
```

**Copy semantics for Phase 17:**
- `_targetSchemaVersion = 17`.
- Test cases (research § Migration round-trip test fixture):
  1. `schemaVersion is 17`
  2. `omitted entry_source stores DEFAULT 'manual'` (D-04 backfill verification)
  3. `accepts 'voice'`
  4. `accepts 'ocr'` (reserved value smoke test)
  5. `rejects invalid entry_source via CHECK constraint` (e.g., `Value('keyboard')`)
- Helper `_insertTransaction` accepts optional `Value<String> entrySource = const Value.absent()`.
- Pitfall #1 alert: the test MUST verify both fresh-install (Drift creates table from `customConstraints`) and migration-from-v16 (`customStatement` ALTER TABLE) paths produce the same CHECK behavior. The `AppDatabase.forTesting()` constructor uses fresh-install path — a separate test (skipped if difficult) should explicitly construct a v16 schema and run the migration.

---

### NEW (or EXTEND) `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart`

**Analog:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`

**Imports pattern** (`anti_toxicity_phase16_test.dart:1-11`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_soul_breakdown.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/per_category_breakdown_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/soul_vs_survival_card.dart';

import '../../../../../helpers/test_localizations.dart';
```

**Forbidden-substring list pattern** (`anti_toxicity_phase16_test.dart:33-79`):
```dart
const forbiddenEn = <String>[
  'better', 'worse', 'winner', 'loser', 'vs', 'versus', 'compare',
  'comparison', 'higher is good', 'lower is bad', 'score', 'rank',
  'ranking', 'wins', 'loses',
];

const forbiddenZh = <String>[
  '更好', '更差', '赢', '输', '胜', '败', 'vs', '对比', '比较',
  '排名', '分数', '胜出', '落败',
];

const forbiddenJa = <String>[
  '勝ち', '負け', 'より良い', 'より悪い', '比較', '対決',
  'スコア', 'ランキング', '勝つ', '負ける',
];

const locales = <Locale>[Locale('en'), Locale('ja'), Locale('zh')];
```

**Copy semantics for Phase 17:**
- Extend each `forbidden*` list with Phase 17 substrings per CONTEXT D-14:
  - en: `'less accurate', 'invalid', 'unreliable', 'less valid', 'inaccurate', 'wrong'` (omit bare `'estimated'` — see RESEARCH Open Question 1; `analyticsJoyMetricVariantManualOnlyExplain` may say "voice-estimated entries" descriptively).
  - ja: `'不正確', '信頼できない', '不完全', '精度が低い', '誤り'`.
  - zh: `'不准', '不可靠', '不完整', '质量差', '估算不准', '错误'`.
- Test surfaces: `JoyMetricVariantChip` + bottom sheet contents + explanation copy.
- Pump for each locale × { all-selected, manualOnly-selected } state matrix.
- Reuse `helpers/test_localizations.dart` test scaffolding.

---

### MOD `lib/data/tables/transactions_table.dart` (data-table, DDL)

**Analog:** Self — `soulSatisfaction` column (line 35) + `customConstraints` (lines 41-43).

**Existing pattern** (`transactions_table.dart:34-43`):
```dart
// Soul ledger satisfaction (1-10, default 2; D-10 unipolar positive scale)
IntColumn get soulSatisfaction => integer().withDefault(const Constant(2))();

@override
Set<Column> get primaryKey => {id};

@override
List<String> get customConstraints => [
  'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
];
```

**Copy semantics for Phase 17:**
- Add `TextColumn get entrySource => text().withDefault(const Constant('manual'))();` adjacent to `soulSatisfaction` (line 35, after the comment block at line 34).
- Append `"CHECK(entry_source IN ('manual', 'voice', 'ocr'))"` to the `customConstraints` list (line 42 — single-quoted Dart string with escaped SQL single quotes, or use a raw string `r"CHECK(...)"`).
- D-05: NO new entry to `customIndices` (lines 45-52).
- **Pitfall #1 reminder (from RESEARCH):** the table-level `customConstraints` is applied at fresh-install only. The migration step in `app_database.dart` must use raw `customStatement` to apply the CHECK inline on the ALTER TABLE statement.

---

### MOD `lib/data/app_database.dart:45` (migration block)

**Analog:** Self — existing v11 migration step (lines 130-135), and v15 index migration step (lines 243-262).

**schemaVersion bump pattern** (`app_database.dart:44-46`):
```dart
@override
int get schemaVersion => 16;
```

**Existing addColumn precedent** (`app_database.dart:130-135`):
```dart
if (from < 11) {
  await migrator.addColumn(books, books.isShadow);
  await migrator.addColumn(books, books.groupId);
  await migrator.addColumn(books, books.ownerDeviceId);
  await migrator.addColumn(books, books.ownerDeviceName);
}
```

**Existing customStatement precedent for CHECK-aware DDL** (`app_database.dart:243-251`):
```dart
if (from < 15) {
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)',
  );
  // ... more customStatement calls
}
```

**Copy semantics for Phase 17 (per RESEARCH Pattern 1 + Pitfall #1):**
- Bump `schemaVersion => 17`.
- Append a new step BEFORE the closing brace of `onUpgrade`:
```dart
if (from < 17) {
  // D-01: column-level inline CHECK and DEFAULT in a single ALTER TABLE
  // statement. The DEFAULT applies to all pre-existing rows in one
  // operation (D-04). table-level customConstraints does NOT apply to
  // existing rows during migrator.addColumn — see RESEARCH Pitfall #1.
  await customStatement(
    "ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL "
    "DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))",
  );
}
```
- Do NOT use `migrator.addColumn(transactions, transactions.entrySource)` — it would omit the CHECK on existing rows.

---

### MOD `lib/data/daos/transaction_dao.dart` (DAO insert + update)

**Analog:** Self — `insertTransaction` method (lines 11-55) and `updateTransaction` method (lines 115-159).

**Existing signature pattern** (`transaction_dao.dart:11-30`):
```dart
Future<void> insertTransaction({
  required String id,
  required String bookId,
  required String deviceId,
  required int amount,
  required String type,
  required String categoryId,
  required String ledgerType,
  required DateTime timestamp,
  required String currentHash,
  required DateTime createdAt,
  String? note,
  String? photoHash,
  String? merchant,
  String? metadata,
  String? prevHash,
  bool isPrivate = false,
  bool isSynced = false,
  int soulSatisfaction = 2,
}) async {
```

**Existing companion-insert pattern** (`transaction_dao.dart:31-54`):
```dart
await _db
    .into(_db.transactions)
    .insert(
      TransactionsCompanion.insert(
        id: id,
        bookId: bookId,
        // ... existing fields ...
        soulSatisfaction: Value(soulSatisfaction),
      ),
    );
```

**Copy semantics for Phase 17:**
- Add named parameter `required String entrySource` (no default — D-06 propagates "required" up the stack; alternatively `String entrySource = 'manual'` for backward source compat at DAO layer, but the use case enforces required).
  - **Recommended:** `required String entrySource` to match D-06's "every caller must specify" contract. Demo data and tests pass explicit `'manual'`.
- Add `entrySource: Value(entrySource)` inside `TransactionsCompanion.insert(...)`.
- Apply the same change to `updateTransaction` (lines 115-159) for completeness, even though Phase 17 has no update path that mutates entry_source.

---

### MOD `lib/data/daos/analytics_dao.dart` (12+ methods gain `EntrySource? entrySourceFilter`)

**Analog:** Self — `getBestJoyMoment` (lines 373-404) for the single-book pattern; `getSharedJoyCategoryInsight` (lines 441-465) for the across-books pattern.

**Existing predicate-drift constants** (`analytics_dao.dart:102-114`) — **MUST remain unchanged (D-17):**
```dart
/// D-01 / HAPPY-05: ledger + lifecycle filter ONLY. NO satisfaction predicate.
/// Single source of truth: every soul aggregator MUST compose via interpolation.
static const String _soulExpenseFilter =
    "ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0";

/// Mirror of [_soulExpenseFilter] for survival ledger.
static const String _survivalExpenseFilter =
    "ledger_type = 'survival' AND type = 'expense' AND is_deleted = 0";
```

**Existing single-book DAO method shape** (`analytics_dao.dart:373-404`):
```dart
Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db
      .customSelect(
        'SELECT id, amount, soul_satisfaction, category_id, timestamp '
        'FROM transactions '
        'WHERE book_id = ? AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ? '
        'ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC '
        'LIMIT 1',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();
  // ...
}
```

**Phase 16 across-books precedent** (`analytics_dao.dart:441-465`):
```dart
Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
  required List<String> bookIds,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (bookIds.isEmpty) return null;

  final placeholders = List.filled(bookIds.length, '?').join(', ');
  final results = await _db
      .customSelect(
        'SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
        'FROM transactions '
        'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ? '
        'GROUP BY category_id '
        // ...
        variables: [
          ...bookIds.map(Variable.withString),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();
```

**Copy semantics for Phase 17 (per RESEARCH Pattern 3):**
- Add `EntrySource? entrySourceFilter` after `endDate` and before any limit/sort parameters (CONTEXT "Claude's Discretion": "place after time-range parameters, null-default to make most existing call sites compile without changes").
- Append `AND entry_source = ?` clause when filter is non-null:
```dart
Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  EntrySource? entrySourceFilter,  // NEW
}) async {
  final entrySourceClause = entrySourceFilter != null
      ? ' AND entry_source = ?'
      : '';
  final results = await _db
      .customSelect(
        'SELECT id, amount, soul_satisfaction, category_id, timestamp '
        'FROM transactions '
        'WHERE book_id = ? AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ?'
        '$entrySourceClause '
        'ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC '
        'LIMIT 1',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          if (entrySourceFilter != null)
            Variable.withString(entrySourceFilter.name),
        ],
      )
      .get();
  // ... unchanged
}
```
- **D-17 invariant:** `_soulExpenseFilter` / `_survivalExpenseFilter` strings remain untouched. The `entry_source` clause is appended *outside* the constant interpolation.
- Add `EntrySource` import: `import '../../features/accounting/domain/models/entry_source.dart';`.
- **Methods to update (verified line numbers from `analytics_dao.dart` grep):**
  - `getMonthlyTotals` (line 137) — D-15 KPI mini-hero
  - `getCategoryTotals` (line 176)  — D-15 category donut
  - `getBestJoyMoment` (line 373)
  - `getSoulRowsForJoyContribution` (line 409)
  - `getSharedJoyCategoryInsight` (line 441) — across-books variant
  - `getPerCategorySoulBreakdown` (line 490)
  - `getPerCategorySoulBreakdownAcrossBooks` (line 528)
  - Soul-vs-Survival composed-predicate methods at lines 585 and 626
  - Plus: `getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getLargestMonthlyExpense`, `getExpenseTrend` (6-month trend per D-15)
- **NOT updated:** `getEarliestTransactionTimestamp` (line 117) — used for time-window initialization, not feeding any AnalyticsScreen card.

---

### MOD `lib/features/accounting/domain/models/transaction.dart` (Freezed model)

**Analog:** Self — `soulSatisfaction` field (line 42).

**Existing field pattern** (`transaction.dart:10-46`):
```dart
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    // ... existing fields ...
    @Default(false) bool isPrivate,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,

    // Soul ledger satisfaction score (1-10, default 2)
    @Default(2) int soulSatisfaction,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

**Copy semantics for Phase 17:**
- Add `@Default(EntrySource.manual) EntrySource entrySource` (or `required EntrySource entrySource` — D-06 contract is enforced at the use-case `CreateTransactionParams` layer, not at the Freezed model layer; the model has a default for backward-compatible deserialization from older sync payloads per D-09).
  - **Recommended:** `@Default(EntrySource.manual) EntrySource entrySource` to match the `soulSatisfaction` default-2 precedent. The required-no-default contract is enforced one layer up at `CreateTransactionParams` (D-06).
- Import `entry_source.dart` (or rely on co-location if planner appends `EntrySource` to this file).
- Code generation triggered: `flutter pub run build_runner build --delete-conflicting-outputs` regenerates `transaction.freezed.dart` and `transaction.g.dart`.

---

### MOD `lib/application/accounting/create_transaction_use_case.dart`

**Analog:** Self — `CreateTransactionParams` (lines 14-37) and `execute` Transaction construction (lines 144-159).

**Existing params class pattern** (`create_transaction_use_case.dart:14-37`):
```dart
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;
  final String? merchant;
  final int? soulSatisfaction;
  final LedgerType? ledgerType;

  const CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
    this.merchant,
    this.soulSatisfaction,
    this.ledgerType,
  });
}
```

**Existing Transaction construction** (`create_transaction_use_case.dart:143-159`):
```dart
// 8. Create domain object
final transaction = Transaction(
  id: id,
  bookId: params.bookId,
  deviceId: deviceId,
  amount: params.amount,
  type: params.type,
  categoryId: params.categoryId,
  ledgerType: resolvedLedgerType,
  timestamp: timestamp,
  prevHash: prevHash,
  currentHash: currentHash,
  createdAt: now,
  note: params.note,
  merchant: params.merchant,
  soulSatisfaction: soulSatisfaction,
);
```

**Hash chain calculation** (`create_transaction_use_case.dart:132-141`) — **MUST remain unchanged (D-02):**
```dart
final currentHash = _hashChainService.calculateTransactionHash(
  transactionId: id,
  amount: hashAmount,
  timestamp: hashTimestamp,
  previousHash: prevHash,
);
```

**Copy semantics for Phase 17:**
- Add `final EntrySource entrySource;` to `CreateTransactionParams` (after `ledgerType`).
- Add `required this.entrySource,` to the const constructor — **NO default** (D-06: every caller must specify).
- Thread `entrySource: params.entrySource` into the `Transaction(...)` constructor (line 158).
- Hash chain inputs UNCHANGED — `entry_source` does NOT enter `calculateTransactionHash` (D-02).
- `TransactionSyncMapper.toCreateOperation(transaction, ...)` call (lines 166-172) requires no change at this site — the mapper itself is extended (next section) to serialize `entrySource`.

---

### MOD `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`

**Analog:** Self — constructor (lines 28-44) and `_save` method (lines 289-317).

**Existing constructor pattern** (`transaction_confirm_screen.dart:28-44`):
```dart
class TransactionConfirmScreen extends ConsumerStatefulWidget {
  const TransactionConfirmScreen({
    super.key,
    required this.bookId,
    required this.amount,
    this.category,
    this.parentCategory,
    required this.date,
    this.initialMerchant,
    this.initialSatisfaction,
    this.voiceKeyword,
  });

  final String bookId;
  final int amount;
  final Category? category;
  final Category? parentCategory;
  final DateTime date;
  // ...
  final String? voiceKeyword;
```

**Existing `_save` CreateTransactionParams build** (`transaction_confirm_screen.dart:298-317`):
```dart
final createUseCase = ref.read(createTransactionUseCaseProvider);
final result = await createUseCase.execute(
  CreateTransactionParams(
    bookId: widget.bookId,
    amount: _amount,
    type: TransactionType.expense,
    categoryId: _category!.id,
    timestamp: _date,
    note: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
    merchant: _storeController.text.trim().isEmpty ? null : _storeController.text.trim(),
    soulSatisfaction: _ledgerType == LedgerType.soul ? _soulSatisfaction : null,
    ledgerType: _ledgerType,
  ),
);
```

**Copy semantics for Phase 17:**
- Add `required this.entrySource,` to constructor (no default — matches push-site explicitness per D-06).
- Add `final EntrySource entrySource;` field.
- Add `entrySource: widget.entrySource,` to `CreateTransactionParams(...)` call (line 316, after `ledgerType`).
- Import `entry_source.dart`.
- **Leave `voiceKeyword` field untouched** — it's category-learning state, semantically distinct from `entrySource` per D-06 rationale (line 252-262 of confirm screen records voice corrections independently of stamping).

---

### MOD `lib/features/accounting/presentation/screens/voice_input_screen.dart:352`

**Analog:** Self — existing `Navigator.push` to `TransactionConfirmScreen` (lines 350-364).

**Existing push site** (`voice_input_screen.dart:350-364`):
```dart
await Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TransactionConfirmScreen(
      bookId: widget.bookId,
      amount: result.amount ?? 0,
      category: category,
      parentCategory: parentCategory,
      date: result.parsedDate ?? DateTime.now(),
      initialMerchant: result.merchantName,
      initialSatisfaction: result.ledgerType == LedgerType.soul
          ? result.estimatedSatisfaction
          : null,
      voiceKeyword: keyword,
    ),
  ),
```

**Copy semantics for Phase 17:**
- Add `entrySource: EntrySource.voice,` immediately after `voiceKeyword: keyword,` (line 362).
- Import `entry_source.dart`.

---

### MOD `lib/features/accounting/presentation/screens/transaction_entry_screen.dart:225`

**Analog:** Self — existing `Navigator.push` (lines 223-233).

**Existing push site** (`transaction_entry_screen.dart:223-233`):
```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TransactionConfirmScreen(
      bookId: widget.bookId,
      amount: amount,
      category: _selectedCategory!,
      parentCategory: _selectedParentCategory,
      date: _selectedDate,
    ),
  ),
);
```

**Copy semantics for Phase 17:**
- Add `entrySource: EntrySource.manual,` to the `TransactionConfirmScreen(...)` constructor call (after `date: _selectedDate`).
- Import `entry_source.dart`.

---

### MOD `lib/application/analytics/demo_data_service.dart:103, 137`

**Analog:** Self — existing `transactionDao.insertTransaction` calls (lines 103-115 income, lines 137-160 expense loop).

**Existing call pattern** (`demo_data_service.dart:103-115`):
```dart
await transactionDao.insertTransaction(
  id: 'demo_tx_${year}_${month}_income_$txCount',
  bookId: bookId,
  deviceId: 'demo_device',
  amount: 300000 + _random.nextInt(100000),
  type: 'income',
  categoryId: 'cat_income',
  ledgerType: 'survival',
  timestamp: DateTime(year, month, day, 9, 0),
  currentHash: hash,
  prevHash: prevHash.isEmpty ? null : prevHash,
  createdAt: DateTime(year, month, day, 9, 0),
);
```

**Copy semantics for Phase 17:**
- Add `entrySource: 'manual',` (D-08 — demo seed is keyboard-style; honest label) to both call sites (lines ~103 income, lines ~137 expense).
- Since `TransactionDao.insertTransaction` accepts `String` (per planner discretion at the DAO layer), pass the literal string `'manual'`. Alternatively if planner wires the DAO to accept the enum, pass `EntrySource.manual` and import the enum file.

---

### MOD `lib/features/accounting/domain/models/transaction_sync_mapper.dart`

**Analog:** Self — `soulSatisfaction` round-trip (lines 31 + 58).

**Existing serialize pattern** (`transaction_sync_mapper.dart:7-34`):
```dart
static Map<String, dynamic> toSyncMap(
  Transaction transaction, {
  required String sourceBookId,
  required String sourceBookName,
  required String sourceBookType,
}) {
  return {
    'id': transaction.id,
    'amount': transaction.amount,
    'type': transaction.type.name,
    'categoryId': transaction.categoryId,
    'ledgerType': transaction.ledgerType.name,
    // ... other fields ...
    'soulSatisfaction': transaction.soulSatisfaction,
    'isPrivate': transaction.isPrivate,
  };
}
```

**Existing deserialize pattern** (`transaction_sync_mapper.dart:36-60`):
```dart
static Transaction fromSyncMap(
  Map<String, dynamic> data, {
  required String bookId,
  required String deviceId,
}) {
  return Transaction(
    id: data['id'] as String,
    // ... other fields ...
    ledgerType: LedgerType.values.byName(data['ledgerType'] as String),
    // ...
    isPrivate: data['isPrivate'] as bool? ?? false,
    isSynced: true,
    soulSatisfaction: data['soulSatisfaction'] as int? ?? 2,
  );
}
```

**Copy semantics for Phase 17 (per RESEARCH "Sync mapper extension" example):**
- `toSyncMap`: add `'entrySource': transaction.entrySource.name,` after `'soulSatisfaction'` (use `.name` per `ledgerType` precedent, not `.toString()`).
- `fromSyncMap`: add `entrySource: EntrySource.values.byName((data['entrySource'] as String?) ?? 'manual'),` (D-09 fallback) after `soulSatisfaction`.
- Import `entry_source.dart`.
- `toCreateOperation` / `toUpdateOperation` (lines 62-102) require no change — they delegate to `toSyncMap`.

---

### MOD `lib/application/analytics/*_use_case.dart` (10+ files)

**Analog:** `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart` (full file, 45 lines) — Phase 16 precedent for adding a new optional parameter on `execute(...)`.

**Existing use-case shape** (`get_per_category_soul_breakdown_across_books_use_case.dart:19-45`):
```dart
class GetPerCategorySoulBreakdownAcrossBooksUseCase {
  GetPerCategorySoulBreakdownAcrossBooksUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<PerCategorySoulBreakdown>> execute({
    required List<String> groupBookIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    if (groupBookIds.isEmpty) {
      return const Empty();
    }

    final items = await _repo.getPerCategorySoulBreakdownAcrossBooks(
      bookIds: groupBookIds,
      startDate: startDate,
      endDate: endDate,
    );

    return aggregatePerCategoryBreakdown(items);
  }
}
```

**Copy semantics for Phase 17:**
- Add `EntrySource? entrySourceFilter` parameter to each affected `execute(...)` (null-default — most existing callers compile unchanged per CONTEXT "Claude's Discretion").
- Thread through to the matching `_repo.method(...)` call.
- **Files to update (per CONTEXT D-15 / D-17 list):**
  - `get_happiness_report_use_case.dart`
  - `get_monthly_report_use_case.dart`
  - `get_per_category_soul_breakdown_use_case.dart`
  - `get_per_category_soul_breakdown_across_books_use_case.dart`
  - `get_soul_vs_survival_snapshot_use_case.dart`
  - `get_soul_vs_survival_snapshot_across_books_use_case.dart`
  - `get_best_joy_moment_use_case.dart`
  - `get_satisfaction_distribution_use_case.dart`
  - `get_largest_monthly_expense_use_case.dart`
  - `get_expense_trend_use_case.dart` (D-15: 6-month trend respects variant)
  - `get_family_happiness_use_case.dart`
- **EXPLICITLY NOT MODIFIED (D-15 exclusion):**
  - `get_monthly_joy_target_recommendation_use_case.dart` — Settings consumer; stays universal.
- The `AnalyticsRepository` interface and its impl must be re-emitted with the new parameter (per RESEARCH Open Question 2 recommendation).

---

### MOD `lib/features/analytics/presentation/providers/state_*.dart` (3+ files: state_happiness, state_analytics, state_ledger_snapshot)

**Analog:** Self — `state_happiness.dart` (full file, 121 lines). The `happinessReport`, `bestJoyMoment`, `largestMonthlyExpense`, `familyHappiness` family providers are the direct shape.

**Existing family provider pattern** (`state_happiness.dart:14-30`):
```dart
/// HAPPY-01..04 personal happiness report.
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    currencyCode: currencyCode,
  );
}
```

**Counter-example (NOT to be modified)** (`state_happiness.dart:48-63`):
```dart
/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget from past 3 months.
@riverpod
Future<MetricResult<int>> monthlyJoyTargetRecommendation(
  Ref ref, {
  required String bookId,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getMonthlyJoyTargetRecommendationUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    currencyCode: currencyCode,
    asOf: DateTime.now(),
  );
}
```

**Copy semantics for Phase 17:**
- For each AnalyticsScreen-feeding family provider, add `required JoyMetricVariant joyMetricVariant` to the family key parameter list.
- Inside the provider body, resolve `joyMetricVariant` to `EntrySource?`:
```dart
final entrySourceFilter = joyMetricVariant == JoyMetricVariant.manualOnly
    ? EntrySource.manual
    : null;
```
- Pass `entrySourceFilter: entrySourceFilter` to the `useCase.execute(...)` call.
- **`monthlyJoyTargetRecommendation` provider must NOT be modified** — D-15 exclusion. Its family key stays `(bookId, currencyCode)`; it does not read `selectedJoyMetricVariantProvider`.
- Riverpod 3 will automatically invalidate the family entry when the key tuple changes (Pitfall #3 — no manual `ref.invalidate` needed for toggle changes).

---

### MOD `lib/features/analytics/presentation/screens/analytics_screen.dart`

**Analog:** Self — `AppBar.actions` (lines 67-75) and `_refresh` method (lines 200-284).

**Existing AppBar.actions pattern** (`analytics_screen.dart:66-75`):
```dart
return Scaffold(
  appBar: AppBar(
    title: Text(l10n.analyticsTitle),
    actions: [
      TimeWindowChip(
        locale: locale,
        earliestData: earliestMonthAsync.value,
      ),
    ],
  ),
```

**Existing _refresh pattern with HomeHero isolation comment** (`analytics_screen.dart:200-225`):
```dart
void _refresh(
  WidgetRef ref, {
  required DateTime startDate,
  required DateTime endDate,
  required DateTime trendAnchor,
  required String currencyCode,
  required bool isGroupMode,
}) {
  // D-12: _refresh MUST NOT invalidate any home/* provider (verified by widget test home_screen_isolation_test.dart in Plan 06).
  ref.invalidate(
    monthlyReportProvider(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    ),
  );
  ref.invalidate(expenseTrendProvider(bookId: bookId, anchor: trendAnchor));
```

**Copy semantics for Phase 17:**
- Add `JoyMetricVariantChip(...)` immediately after `TimeWindowChip(...)` in the `actions` list (line 73, before the closing `]`).
- In `_refresh`, every `ref.invalidate(<provider>(bookId: ..., startDate: ..., endDate: ...))` call now needs `joyMetricVariant: ref.read(selectedJoyMetricVariantProvider)` added to the family key — OR the provider should be invalidated as a family root (`ref.invalidate(<provider>)`) to clear all variant keys.
  - **Recommended:** Read the current variant once at the top of `_refresh` and append it to each invalidation tuple. Matches the existing `bookId`/`startDate`/`endDate` shape and avoids over-invalidation.
- **DO NOT add invalidation for `selectedJoyMetricVariantProvider`-keyed providers in `setVariant`** (Pitfall #3 — Riverpod 3 auto-invalidates family keys on tuple change).
- D-18 invariant: HomeHero / Home-tab providers MUST NOT be added to `_refresh` invalidation list.

---

### MOD `lib/l10n/app_{en,ja,zh}.arb` (5 new keys per locale)

**Analog:** `lib/l10n/app_en.arb` — existing `analyticsTimeWindowChip*` block (lines 1697-1727).

**Existing ARB key + metadata pattern** (`app_en.arb:1697-1709`):
```json
"analyticsTimeWindowChipTooltip": "Pick a time window",
"@analyticsTimeWindowChipTooltip": {
  "description": "Analytics screen time-window selector chip tooltip"
},
"analyticsTimeWindowChipLabelWeek": "Week of {monday}",
"@analyticsTimeWindowChipLabelWeek": {
  "description": "Analytics screen time-window selector week chip label",
  "placeholders": {
    "monday": {
      "type": "String"
    }
  }
},
```

**Copy semantics for Phase 17 (per CONTEXT D-13 anchors):**
- Add 5 new keys in same block style (each with `@key` metadata + `description`):
  1. `analyticsJoyMetricVariantChipLabel`
  2. `analyticsJoyMetricVariantSheetTitle`
  3. `analyticsJoyMetricVariantOptionAll`
  4. `analyticsJoyMetricVariantOptionManualOnly`
  5. `analyticsJoyMetricVariantManualOnlyExplain`
- Trilingual lockstep MUST be enforced — add ALL 5 keys to all 3 ARB files in ONE commit (Pitfall #4).
- After adding, run `flutter gen-l10n` and verify build.
- Anchor wording (D-13):
  - en `analyticsJoyMetricVariantManualOnlyExplain`: `Manual entries only · excludes voice-estimated entries`
  - ja: `手動入力のみ · 音声推定を除外`
  - zh: `仅手动输入 · 不含语音估算条目`
- D-14 cross-check: anti-toxicity widget test must pass with the chosen wording (the en candidate uses `voice-estimated` — descriptive, allowable as long as bare `estimated` is NOT on the forbidden list per RESEARCH Open Question 1).

---

### MOD `.planning/ROADMAP.md` (SC-3 wording correction, plan-phase task #1)

**Analog:** Phase 16 D-15 ROADMAP correction (precedent for "first plan rewrites the success criterion").

**Copy semantics for Phase 17:**
- Plan 01 = single-file commit that rewrites SC-3 in `.planning/ROADMAP.md`.
- Current SC-3: `"...all Joy metrics (Σ joy_contribution, per-category breakdown, Soul-vs-Survival comparison) re-query with entry_source = 'manual' filter."`
- Replacement (per CONTEXT D-16): `"When manual-only is selected, every data card on AnalyticsScreen re-queries with entry_source = 'manual' filter (including total spend / category distribution / 6-month trend / largest expense / Soul-vs-Survival both columns). HomeHero and Settings recommendation remain unaffected (SC-4)."`

---

## Shared Patterns

### Pattern A: Trilingual ARB key addition

**Source:** `lib/l10n/app_{en,ja,zh}.arb`
**Apply to:** Plan adding the 5 D-13 keys.

**Procedure** (Pitfall #4):
1. Add to `app_en.arb` (with `@key` metadata, `description`, `placeholders` if any).
2. Add the same key to `app_ja.arb` (Japanese value, same metadata block).
3. Add the same key to `app_zh.arb` (Chinese value, same metadata block).
4. Run `flutter gen-l10n` — must succeed without warnings.
5. Run `flutter analyze` — `S.of(context).analyticsJoyMetricVariantX` must resolve.
6. ALL 5 keys in ONE commit so the lockstep is git-bisect-friendly.

### Pattern B: Riverpod 3 `@riverpod` notifier session state

**Source:** `lib/features/analytics/presentation/providers/state_time_window.dart`
**Apply to:** New `state_joy_metric_variant.dart`.

- Import only `riverpod_annotation/riverpod_annotation.dart` for the notifier.
- Import `flutter_riverpod/flutter_riverpod.dart` in consumer widgets (no `legacy.dart` per CLAUDE.md Riverpod 3 conventions).
- Class name pattern: `Selected<X>` → generates `selected<X>Provider` (suffix `Notifier` is stripped).

### Pattern C: DAO method gains optional filter parameter

**Source:** `lib/data/daos/analytics_dao.dart` (Phase 16 `bookIds: List<String>` pattern in `getSharedJoyCategoryInsight`).
**Apply to:** All 12+ AnalyticsDao methods modified per D-17.

- New parameter `EntrySource? entrySourceFilter` placed AFTER `endDate`, BEFORE limit/sort params.
- Null default → no behavior change to existing call sites.
- Append `' AND entry_source = ?'` to the SQL string when filter non-null.
- Add `Variable.withString(entrySourceFilter.name)` to variables list inside `if (entrySourceFilter != null)` guard.
- NEVER mutate `_soulExpenseFilter` / `_survivalExpenseFilter` constants (D-17).

### Pattern D: Use case `execute` gains optional filter parameter

**Source:** Phase 16 `GetPerCategorySoulBreakdownAcrossBooksUseCase` (added `bookIds` parameter).
**Apply to:** All 10+ AnalyticsScreen-feeding use cases listed in D-17.

- Add `EntrySource? entrySourceFilter` to `execute(...)`, null-default.
- Thread through to `_repo.method(...)` call unchanged otherwise.
- `TimeWindowValidation.assertValid(startDate, endDate)` and empty-list guards remain as-is.

### Pattern E: Family provider key extension (Riverpod 3 auto-invalidation)

**Source:** `state_happiness.dart` family provider shape.
**Apply to:** Each `state_*.dart` provider in the AnalyticsScreen-feeding set (NOT `monthlyJoyTargetRecommendation`).

- Add `required JoyMetricVariant joyMetricVariant` to the family key parameter list.
- Resolve to `EntrySource?` inside the provider body.
- Riverpod 3 auto-invalidates the family entry when the key tuple changes — no manual `ref.invalidate` needed in `setVariant` (Pitfall #3).

### Pattern F: Forbidden-substring trilingual widget sweep

**Source:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`.
**Apply to:** Phase 17's new/extended anti-toxicity test.

- Three lists (`forbiddenEn`, `forbiddenJa`, `forbiddenZh`) extended with Phase 17 strings (CONTEXT D-14).
- Locales `[en, ja, zh]` × widget states `[all-selected, manualOnly-selected]` matrix.
- Use `helpers/test_localizations.dart` for `MaterialApp` test scaffolding.
- Omit bare `'estimated'` from `forbiddenEn` to avoid false-positive on `voice-estimated` descriptive copy.

### Pattern G: Schema migration with column-level inline CHECK

**Source:** `lib/data/app_database.dart` (existing `if (from < N)` chain + `customStatement` pattern from v14/v15).
**Apply to:** New `if (from < 17)` migration step.

- Use raw `customStatement('ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL DEFAULT \'manual\' CHECK(entry_source IN (\'manual\', \'voice\', \'ocr\'))')`.
- Do NOT use `migrator.addColumn(transactions, transactions.entrySource)` — would skip CHECK on existing rows (RESEARCH Pitfall #1).
- ALSO update `transactions_table.dart` `customConstraints` list so fresh-install path produces equivalent CHECK.

### Pattern H: Code generation regen after annotated-class change

**Source:** CLAUDE.md Pitfall #3 + RESEARCH Pitfall #5.
**Apply to:** Every plan that modifies `@freezed`, `@riverpod`, or Drift table.

- After modifying any of: `transaction.dart` (Freezed), `state_joy_metric_variant.dart` (Riverpod notifier), `transactions_table.dart` (Drift table), `app_database.dart` (schema version) — run:
  ```
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Verify generated files (`.freezed.dart`, `.g.dart`, `app_database.g.dart`) are committed.

---

## No Analog Found

| File | Reason |
|------|--------|
| (none) | Every file in this phase has a direct in-codebase precedent from Phase 13–16. Phase 17 is "mechanical wiring on top of well-established v1.2 precedents" (RESEARCH summary line 9). |

---

## Metadata

**Analog search scope:**
- `lib/data/tables/`, `lib/data/daos/`, `lib/data/repositories/`, `lib/data/app_database.dart`
- `lib/features/accounting/domain/models/`, `lib/features/accounting/presentation/screens/`
- `lib/features/analytics/presentation/providers/`, `lib/features/analytics/presentation/widgets/`, `lib/features/analytics/presentation/screens/`
- `lib/application/accounting/`, `lib/application/analytics/`
- `lib/l10n/`
- `test/unit/data/migrations/`, `test/widget/features/analytics/presentation/widgets/`

**Files scanned:** 22 source files + 4 ARB files + 2 test files (Read tool); plus targeted Bash/Grep for line-number anchoring.

**Pattern extraction date:** 2026-05-20

**Confidence:** HIGH. Every pattern assignment has a verified analog with file path and line numbers. The phase is plumbing on top of Phase 13–16 architecture — there are no novel patterns. The risk surface (per RESEARCH) is execution discipline (Drift migration CHECK semantics, ARB lockstep, build_runner after `@freezed`/`@riverpod`/Drift edits, anti-toxicity substring list completeness), not pattern discovery.
