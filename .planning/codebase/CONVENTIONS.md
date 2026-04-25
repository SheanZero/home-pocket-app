# CONVENTIONS

**Analysis Date:** 2026-04-25

## Naming Patterns

**Files:** `snake_case.dart` for all sources. Test files end with `_test.dart` and mirror source path (`lib/shared/utils/result.dart` → `test/unit/shared/utils/result_test.dart`). Generated suffixes: `*.g.dart`, `*.freezed.dart`, `*.mocks.dart` — never edited by hand. Drift table files end with `_table.dart`, DAOs `_dao.dart`, repository impls `_repository_impl.dart`, use cases `_use_case.dart`.

**Classes:** `PascalCase` everywhere. Riverpod notifier base: `extends _$ClassName`. Static helper containers use `abstract final class` with private ctor (e.g. `lib/core/theme/app_text_styles.dart`).

**Functions / Variables:** `camelCase`; `_leadingUnderscore` for library-private members.

**Drift tables:** `PascalCase` plural (`Transactions`, `AuditLogs`). Generated row class via `@DataClassName('TransactionRow')`. Index naming: `idx_{table_short}_{columns}` snake_case (e.g. `idx_tx_book_timestamp`).

## Code Style (`analysis_options.yaml`)

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_single_quotes: true
    prefer_relative_imports: true
    avoid_print: false
```

- `dart format .` enforced before commits
- Trailing commas on multi-line argument lists
- **Zero analyzer warnings policy** — `flutter analyze` MUST be 0 issues before commit
- Don't suppress with `// ignore:` — fix the root cause
- `custom_lint: ^0.7.5` + `riverpod_lint: ^2.6.4` wired in `dev_dependencies` for Riverpod-specific checks

## Import Organization

Order observed:
1. `dart:` core libraries
2. blank line, then `package:` external imports
3. blank line, then **relative** imports (e.g., `import '../../domain/models/category.dart';`)
4. `part 'file.g.dart';` / `part 'file.freezed.dart';` directives at the bottom

No path aliases — relative imports inside `lib/` are mandatory (`prefer_relative_imports`). Tests under `test/` use absolute `package:home_pocket/...` imports.

Example (`lib/features/accounting/presentation/screens/category_selection_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/category.dart';
import '../providers/repository_providers.dart';
```

## Immutability via Freezed

All domain models MUST be Freezed `abstract class` with `@freezed`. Use `const factory` constructors, `@Default(...)` for defaults, and `copyWith` for updates — NEVER mutate. Add `factory FromJson(...)` for JSON-serialized models.

Example (`lib/features/accounting/domain/models/category.dart`):
```dart
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon,
    required String color,
    String? parentId,
    required int level,
    @Default(false) bool isSystem,
    @Default(false) bool isArchived,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
```

`build.yaml` config: `freezed.format: true`, `json_serializable.explicit_to_json: true`.

## Riverpod Provider Rules

Prefer `@riverpod` codegen (riverpod_annotation 2.6+). Function-style for stateless deps; class-style for stateful notifiers (`extends _$Name`).

Function-style (`lib/features/accounting/presentation/providers/repository_providers.dart`):
```dart
@riverpod
BookRepository bookRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return BookRepositoryImpl(dao: BookDao(database));
}
```

Notifier-style (`lib/features/accounting/presentation/providers/category_reorder_notifier.dart`):
```dart
@riverpod
class CategoryReorderNotifier extends _$CategoryReorderNotifier {
  @override
  CategoryReorderState build() => const CategoryReorderState();
}
```

**Rules (from `CLAUDE.md`):**
- ONE `repository_providers.dart` per feature — single source of truth
- Use case providers reference repositories via `ref.watch(...)`
- NEVER duplicate repository provider definitions
- NEVER throw `UnimplementedError` in providers
- Use Case **classes** live in `lib/application/`, but the **wiring providers** live in feature `presentation/providers/`

## Drift Conventions

Example (`lib/data/tables/transactions_table.dart`):
```dart
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  IntColumn get amount => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
  ];

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_tx_book_id', columns: {#bookId}),
    TableIndex(name: 'idx_tx_book_timestamp', columns: {#bookId, #timestamp}),
  ];
}
```

**Index syntax (CRITICAL):** Use `TableIndex` (NOT `Index`). Columns are Symbols `{#bookId}`. Naming `idx_{table_short}_{columns}`. `customIndices` getter must NOT use `@override`. `primaryKey` and `customConstraints` MUST use `@override`.

Schema versioning lives in `lib/data/app_database.dart` — increment `schemaVersion` and add `if (from < N) {...}` block in `MigrationStrategy.onUpgrade`.

## Error Handling

Use Cases return `Result<T>` (`lib/shared/utils/result.dart`) — never throw to caller:
```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  bool get isError => !isSuccess;

  factory Result.success(T? data) => Result._(data: data, isSuccess: true);
  factory Result.error(String message) =>
      Result._(error: message, isSuccess: false);
}
```

Use case pattern (`lib/application/accounting/delete_transaction_use_case.dart`):
```dart
Future<Result<void>> execute(String transactionId) async {
  if (transactionId.isEmpty) {
    return Result.error('transactionId must not be empty');
  }
  final existing = await _transactionRepo.findById(transactionId);
  if (existing == null) return Result.error('Transaction not found');
  await _transactionRepo.softDelete(transactionId);
  return Result.success(null);
}
```

UI consumes via `try/catch` for repo ops or by checking `result.isSuccess`. Errors surface via `SnackBar` using localized strings. NEVER silently swallow errors — at minimum log via `dart:developer`:
```dart
import 'dart:developer' as dev;
dev.log('Master key initialized', name: 'AppInit');
```

## i18n Rules (`l10n.yaml`)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/generated
nullable-getter: false
```

ARB files: `app_en.arb`, `app_ja.arb`, `app_zh.arb`. Default locale = `ja`.

**Mandatory:**
- ALL UI strings via `S.of(context)` — NEVER hardcode display text
- When adding a new key, update **all 3 ARB files** then run `flutter gen-l10n`
- Format dates via `DateFormatter` (`lib/infrastructure/i18n/formatters/date_formatter.dart`)
- Format currency / numbers via `NumberFormatter` (`lib/infrastructure/i18n/formatters/number_formatter.dart`)
- Always pass `Locale` from `currentLocaleProvider`:
  ```dart
  final localeAsync = ref.watch(currentLocaleProvider);
  final locale = localeAsync.valueOrNull ?? const Locale('ja');
  ```
- Capture `final l10n = S.of(context);` once at the top of `build` and reuse

**Date formats:** ja `2026/04/25`, zh `2026年04月25日`, en `04/25/2026`.
**Currency:** JPY 0 decimals (`¥1,235`); USD/CNY/EUR/GBP 2 decimals; compact ja/zh `123万`, en `1.23M`.

## Amount Display Style

ALL monetary values MUST use `AppTextStyles.amount{Large,Medium,Small}` from `lib/core/theme/app_text_styles.dart`. These three styles bundle `fontFeatures: [FontFeature.tabularFigures()]` to keep digits column-aligned:

```dart
static const _tabularFigures = [FontFeature.tabularFigures()];

static const amountLarge = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 30,
  fontWeight: FontWeight.w700,
  height: 0.9,
  color: AppColors.textPrimary,
  fontFeatures: _tabularFigures,
);

static const amountMedium = TextStyle(... fontSize: 18, fontFeatures: _tabularFigures);
static const amountSmall  = TextStyle(... fontSize: 15, fontFeatures: _tabularFigures);
```

Usage with `.copyWith(color: ...)` for ledger tint:
```dart
Text(formatted, style: AppTextStyles.amountSmall.copyWith(color: amountColor))
```

NEVER use `headlineLarge`, `titleLarge`, `bodyLarge` for monetary values — they lack tabular figures and amounts will misalign across rows.

Real call sites:
- `lib/features/accounting/presentation/widgets/amount_display.dart` (lines 79, 104)
- `lib/features/home/presentation/widgets/month_overview_card.dart` (line 70)
- `lib/features/home/presentation/widgets/home_transaction_tile.dart` (line 96)
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` (lines 202, 274)

## Widget Parameter Pattern

Nullable parameters with provider fallback (NEVER hardcode defaults):
```dart
class TransactionFormScreen extends ConsumerWidget {
  const TransactionFormScreen({super.key, this.bookId});
  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
    // ...
  }
}
```

When the screen cannot function without the value AND a router always supplies it, `required this.bookId` is acceptable (e.g. `TransactionConfirmScreen`, `VoiceInputScreen`, `OcrScannerScreen` in `lib/features/accounting/presentation/screens/`).

Constructors: prefer `const`; always `super.key`; named parameters for clarity.

## Function & Module Design

- Functions < 50 lines (per `.claude/rules/coding-style.md`)
- Files 200–400 lines typical, 800 max
- No barrel files — consumers import specific source files
- Layer dependency rule (from `CLAUDE.md`): Presentation → Application → Domain ← Data ← Infrastructure. Domain never imports outward layers. "Thin Feature" rule: features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`.

## Comments

`///` Dart doc comments for public APIs (see `Category.name` field doc explaining system vs custom). `//` inline comments explain WHY, not WHAT (e.g. `// throws propagate` in `category_reorder_notifier.dart`). TODO comments allowed and prefixed: `// TODO: Remove after all screens are migrated to Wa-Modern`.

## Code Generation Workflow

After ANY change to `@freezed`, `@riverpod`, Drift tables/DAOs, or ARB files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n      # only if ARB files changed
```

Also after `git pull`/`merge`/`rebase`. Generated files (`.g.dart`, `.freezed.dart`, `lib/generated/app_localizations.dart`) ARE committed — do NOT `.gitignore` them.

## Files Referenced

- `analysis_options.yaml`
- `pubspec.yaml`
- `l10n.yaml`
- `build.yaml`
- `CLAUDE.md`
- `lib/main.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/data/app_database.dart`
- `lib/data/tables/transactions_table.dart`
- `lib/shared/utils/result.dart`
- `lib/application/accounting/delete_transaction_use_case.dart`
- `lib/features/accounting/domain/models/category.dart`
- `lib/features/accounting/presentation/providers/repository_providers.dart`
- `lib/features/accounting/presentation/providers/category_reorder_notifier.dart`
- `lib/infrastructure/i18n/formatters/date_formatter.dart`
