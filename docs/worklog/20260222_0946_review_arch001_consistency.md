# Architecture Document Consistency Review: ARCH-001 vs ARCH-002~008

**Date:** 2026-02-22
**Time:** 09:46
**Task Type:** Documentation Review
**Status:** Completed
**Related Module:** ARCH-001 through ARCH-008

---

## Task Overview

This report documents a thorough consistency review between the primary architecture guide (`ARCH-001_Complete_Guide.md`, v2.0) and each of the specialized architecture documents (`ARCH-002` through `ARCH-008`). The review covers layer definitions, dependency rules, the "Thin Feature" pattern, directory structure conventions, provider organization rules, crypto/security infrastructure placement, i18n infrastructure placement, and application layer placement.

---

## 1. ARCH-001 vs ARCH-002 (Data Architecture)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06) - Updated based on ARCH-008
- **ARCH-002:** v1.0 (2026-02-03) - **NOT updated to v2.0**

### Inconsistencies Found

#### 1.1 Drift Index Syntax (CRITICAL)

**ARCH-002** uses the old Drift index syntax which contradicts both ARCH-001 and CLAUDE.md mandatory rules:

```dart
// ARCH-002 (WRONG):
@override
List<Index> get customIndexes => [
  Index('idx_transactions_book_id', [bookId]),
];

// CLAUDE.md / ARCH-001 mandatory syntax:
List<TableIndex> get customIndices => [
  TableIndex(name: 'idx_transactions_book_id', columns: {#bookId}),
];
```

Issues:
- Uses `Index()` instead of `TableIndex()`
- Uses `List<Index>` instead of `List<TableIndex>`
- Uses `[column]` instead of `{#symbol}`
- Uses `@override` annotation (CLAUDE.md says DO NOT add `@override` to `customIndices`)

#### 1.2 ERD Field Differences (HIGH)

**ARCH-001 ERD (section 2.1):**
- `Books` table has: `id`, `name`, `type` ('personal'|'family'), `created_at`
- `Categories` has: `id`, `name`, `icon`, `color`, `ledger_t`, `is_system`, `is_archived`, `created_at`
- No `currency`, `deviceId` fields on Books

**ARCH-002 ERD:**
- `Books` table has: `id`, `name`, `currency`, `createdAt`, `deviceId` (FK)
- `Categories` has: `id`, `name`, `icon`, `color`, `parentId`, `level`, `isSystem` (3-level hierarchy)
- Includes `SoulAccountCfg` table not present in ARCH-001 ERD

Key differences:
- ARCH-001 Books has `type` field; ARCH-002 Books has `currency` + `deviceId`
- ARCH-001 Categories uses `ledgerType` for dual-ledger; ARCH-002 Categories uses `parentId`+`level` (hierarchical)
- ARCH-002 has a `SoulAccountCfg` entity not in ARCH-001's ERD

#### 1.3 Drift Table Column Types (MEDIUM)

**ARCH-001** Drift tables (section 2.1) use:
```dart
IntColumn get createdAt => integer()();    // epoch-based timestamps
IntColumn get isPrivate => integer().withDefault(const Constant(0))();  // integer for booleans
```

**ARCH-002** Drift tables use:
```dart
DateTimeColumn get createdAt => dateTime()();   // native DateTime
BoolColumn get isArchived => boolean().withDefault(const Constant(false))();  // native booleans
```

No canonical decision on which type convention to use.

#### 1.4 Repository Pattern Alignment (OK)

Both documents agree on:
- Repository interfaces in `lib/features/*/domain/repositories/`
- Repository implementations in `lib/data/repositories/`
- ARCH-002 correctly references `ADR-007: Clean Architecture Layer Responsibilities`

### Suggested Modifications for ARCH-002

1. **Update to v2.0** to reflect ARCH-008 layer standards
2. **Fix all Drift index syntax** to use `TableIndex` with `{#symbol}` format
3. **Reconcile ERD** with ARCH-001 - decide on canonical field sets for Books and Categories
4. **Standardize column types** - decide between `integer()`/`dateTime()` and `integer()`/`boolean()` patterns

---

## 2. ARCH-001 vs ARCH-003 (Security Architecture)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06)
- **ARCH-003:** v1.0 (2026-02-03) - **NOT updated to v2.0**

### Inconsistencies Found

#### 2.1 KeyManager Pattern - Singleton vs Riverpod Provider (CRITICAL)

**ARCH-003** consistently uses the singleton pattern:
```dart
class KeyManager {
  static final KeyManager instance = KeyManager._();
  KeyManager._();
  // ...
}

// Usage throughout ARCH-003:
final keyManager = KeyManager.instance;
```

**ARCH-001** and **CLAUDE.md** mandate Riverpod providers:
```dart
// CLAUDE.md pattern:
final keyManager = ref.read(keyManagerProvider);
```

The singleton pattern is used 14+ times across ARCH-003. This fundamentally contradicts the Riverpod-based dependency injection architecture defined in ARCH-001, ARCH-004, and CLAUDE.md.

#### 2.2 Corrupted/Duplicated Code Block (HIGH)

Around lines 1120-1157 in ARCH-003, there is corrupted content where code from an older verification function appears to be pasted over newer content:

```
// Line 1133: End of VerificationScheduler
  }
}
      } else {    // <-- ORPHANED CODE STARTS HERE
        // 后续交易
        if (tx.prevHash != expectedPrevHash) {
          return HashChainVerificationResult(
```

This appears to be a leftover fragment from a previous version's `verifyComplete()` method that was accidentally left after an edit.

#### 2.3 HashChainVerificationResult Duplication (MEDIUM)

ARCH-003 defines `HashChainVerificationResult` as a plain class (lines 1160-1177), while ARCH-001/ARCH-008 specify that it should be a Freezed model defined uniquely at `lib/infrastructure/crypto/models/chain_verification_result.dart`.

#### 2.4 Security Infrastructure Placement (OK)

ARCH-003's content about crypto services aligns with ARCH-001/ARCH-008's placement at `lib/infrastructure/crypto/`, but the code examples don't reflect the Riverpod provider-based architecture.

### Suggested Modifications for ARCH-003

1. **Update to v2.0** - align with ARCH-008 layer standards
2. **Replace all singleton KeyManager references** with Riverpod provider pattern (`keyManagerProvider`)
3. **Remove corrupted code block** around lines 1120-1157
4. **Update `HashChainVerificationResult`** to reference the Freezed model at `lib/infrastructure/crypto/models/`
5. **Align all code examples** with Riverpod dependency injection

---

## 3. ARCH-001 vs ARCH-004 (State Management)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06)
- **ARCH-004:** v1.0 (2026-02-03) - **NOT updated to v2.0**

### Inconsistencies Found

#### 3.1 Provider Directory Structure (HIGH)

**ARCH-004** shows providers at:
```
lib/
  ├── core/
  │   └── providers/
  │       ├── database_provider.dart
  │       ├── key_manager_provider.dart
  │       └── device_manager_provider.dart
  ├── features/
  │   ├── accounting/
  │   │   └── providers/                    # <-- Missing presentation/ level
  │   │       ├── transaction_repository_provider.dart
  │   │       ├── transaction_list_provider.dart
  │   │       └── ...
```

**ARCH-001/CLAUDE.md** structure:
```
lib/
  ├── features/
  │   ├── accounting/
  │   │   └── presentation/
  │   │       └── providers/                # <-- Correct: under presentation/
  │   │           ├── repository_providers.dart
  │   │           └── transaction_providers.dart
```

Issues:
- ARCH-004 places providers directly under `features/accounting/providers/` instead of `features/accounting/presentation/providers/`
- ARCH-004 shows `core/providers/` directory for database/key manager - ARCH-001 does not define this path
- ARCH-004 uses separate files per provider (`transaction_repository_provider.dart`) vs ARCH-001/CLAUDE.md pattern of consolidated `repository_providers.dart`

#### 3.2 Default Locale Setting (MEDIUM)

**ARCH-004** (line 739):
```dart
@Default(Locale('zh', 'CN')) Locale locale,
```

**ARCH-001/CLAUDE.md**: Japanese (`ja`) is the default locale. The app's primary language file is `app_ja.arb`.

#### 3.3 Old Document Reference (LOW)

**ARCH-004** (line 26) references:
```
详细决策理由参见 [14_ADR_State_Management.md](./14_ADR_State_Management.md)。
```

This uses the old numbering scheme. Should reference `ADR-001_State_Management.md` or the correct ADR number.

#### 3.4 Use Case Provider Location (MEDIUM)

**ARCH-004** shows Use Case providers at `lib/features/accounting/providers/`:
```dart
// lib/features/accounting/providers/create_transaction_use_case_provider.dart
```

Per ARCH-001/CLAUDE.md, Use Case providers should be in `lib/features/accounting/presentation/providers/` and the Use Case classes themselves in `lib/application/accounting/`.

### Suggested Modifications for ARCH-004

1. **Update to v2.0** - align with ARCH-008 layer standards
2. **Fix provider directory paths** to include `presentation/` level
3. **Change default locale** from `Locale('zh', 'CN')` to `Locale('ja')`
4. **Update document references** from old `14_ADR_*` format to `ADR-xxx_*` format
5. **Clarify core/providers/** - either define this in ARCH-001 or remove from ARCH-004
6. **Consolidate provider file patterns** to match `repository_providers.dart` pattern from CLAUDE.md

---

## 4. ARCH-001 vs ARCH-005 (Integration Patterns)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06)
- **ARCH-005:** v1.0 (2026-02-03) - **NOT updated to v2.0**

### Inconsistencies Found

#### 4.1 Layer Naming (HIGH)

**ARCH-005** (line 39) labels the second layer as:
```
Business Logic Layer (业务逻辑层)
```

**ARCH-001** consistently uses:
```
APPLICATION LAYER (全局业务逻辑层)
```

While the concept is similar, "Business Logic Layer" and "Application Layer" are different names for what ARCH-001 defines as the same layer. ARCH-005 should use the canonical name.

#### 4.2 Event Bus Path References (HIGH)

**ARCH-005** references paths that do not exist in ARCH-001's directory structure:
- `lib/core/domain/events/app_event.dart` (line 1053)
- `lib/core/domain/events/event_bus.dart` (line 1094)
- `lib/core/domain/exceptions/app_exception.dart` (line 1184)

ARCH-001 does not define a `lib/core/domain/` directory. Error/exception types are placed at `lib/core/error/` per ARCH-006, and events are not explicitly placed in ARCH-001's directory structure.

#### 4.3 Old Document References (LOW)

**ARCH-005** references old file names:
- `[06_MOD_BasicAccounting.md](./06_MOD_BasicAccounting.md)` (line 1524)
- `[08_MOD_FamilySync.md](./08_MOD_FamilySync.md)` (lines 960, 1525)

These should be updated to:
- `MOD-001_BasicAccounting.md`
- `MOD-003_FamilySync.md` (or equivalent)

#### 4.4 Use Case Placement (OK)

ARCH-005 correctly places Use Cases at `lib/application/accounting/` which aligns with ARCH-001/ARCH-008's global Application layer.

### Suggested Modifications for ARCH-005

1. **Update to v2.0** - align with ARCH-008 layer standards
2. **Rename "Business Logic Layer"** to "Application Layer" to match ARCH-001 terminology
3. **Fix path references** for event bus and exceptions to match ARCH-001 directory structure
4. **Update document references** from old `06_MOD_*` / `08_MOD_*` format to `MOD-xxx_*` format

---

## 5. ARCH-001 vs ARCH-006 (Error Boundaries)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06)
- **ARCH-006:** v1.0 (2026-02-03) - **NOT updated to v2.0**

### Inconsistencies Found

#### 5.1 Domain Exception Path (HIGH)

**ARCH-006** (line 376) defines Domain exceptions at:
```dart
// lib/domain/error/domain_exceptions.dart
```

**ARCH-001** does not have a top-level `lib/domain/` directory. Domain models and interfaces live inside features at `lib/features/{feature}/domain/`. Shared exceptions would likely be at `lib/core/error/` or a similar shared location.

#### 5.2 Presentation Layer Paths (HIGH)

**ARCH-006** uses old presentation paths:
- `lib/presentation/core/error/failures.dart` (line 594)
- `lib/presentation/features/transaction/providers/transaction_provider.dart` (line 1237)
- `lib/presentation/features/transaction/pages/transaction_list_page.dart` (line 1342)
- `lib/presentation/core/widgets/error_state_widget.dart` (line 1414)
- `lib/presentation/core/widgets/empty_state_widget.dart` (line 1464)

**ARCH-001** structure:
- Feature presentation: `lib/features/{feature}/presentation/`
- Shared widgets: `lib/shared/widgets/`

There is no `lib/presentation/` top-level directory in ARCH-001.

#### 5.3 Use Case Path (HIGH)

**ARCH-006** places Use Cases at:
- `lib/domain/usecases/create_transaction_usecase.dart` (line 963)
- `lib/domain/usecases/update_transaction_usecase.dart` (line 1068)

**ARCH-001/ARCH-008** place Use Cases at:
- `lib/application/accounting/create_transaction_use_case.dart`

This is a fundamental structural difference - ARCH-006 puts Use Cases in the Domain layer, while ARCH-001/ARCH-008 put them in the Application layer.

#### 5.4 Error Architecture Diagram Layer Naming (MEDIUM)

**ARCH-006** (line 77) labels the Use Case layer as:
```
Domain Layer (Use Cases)
```

**ARCH-001** separates Domain (models + repo interfaces) from Application (Use Cases). Combining them as "Domain Layer (Use Cases)" contradicts the 5-layer architecture.

### Suggested Modifications for ARCH-006

1. **Update to v2.0** - align with ARCH-008 layer standards
2. **Fix all `lib/domain/` paths** to match ARCH-001 structure (`lib/features/*/domain/` for models, `lib/application/` for Use Cases)
3. **Fix all `lib/presentation/` paths** to match ARCH-001 structure (`lib/features/*/presentation/` and `lib/shared/widgets/`)
4. **Move Domain exceptions** from `lib/domain/error/` to an appropriate shared location like `lib/core/error/`
5. **Update layer naming** in error architecture diagram to separate Application and Domain layers

---

## 6. ARCH-001 vs ARCH-007 (Architecture Diagram I18N)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06)
- **ARCH-007:** v2.0 (2026-02-03) - Updated for i18n

### Inconsistencies Found

#### 6.1 Tech Stack: sqlite3_flutter_libs (CRITICAL)

**ARCH-007** (line 317) lists:
```
本地数据库
├─ drift 2.14+ (ORM)
├─ sqlite3_flutter_libs 0.5+
└─ sqlcipher_flutter_libs 0.6+ (加密)
```

**CLAUDE.md** explicitly states:
> DO NOT use `sqlite3_flutter_libs` - use only `sqlcipher_flutter_libs` (conflicts!)

**ARCH-001** (line 48) also lists `sqlite3_flutter_libs ^0.5.18` alongside `sqlcipher_flutter_libs ^0.6.0`. Both documents contradict CLAUDE.md on this point.

#### 6.2 Tech Stack: intl Version (HIGH)

**ARCH-007** (line 329) and **ARCH-001** (line 71) list:
```
intl 0.19+   /   intl ^0.19.0
```

**CLAUDE.md** states:
> Don't use `intl` version other than 0.20.2 (pinned by flutter_localizations)

#### 6.3 Feature Names Mismatch (HIGH)

**ARCH-007** directory structure (lines 386-395) uses:
```
features/
├── onboarding/
├── transaction/
├── category/
├── dual_ledger/
├── family_sync/
├── ocr/
├── security/
├── analytics/
├── settings/
└── gamification/
```

**ARCH-001** directory structure (lines 389-435):
```
features/
├── accounting/          # (not "transaction/")
├── dual_ledger/
├── ocr/
├── security/
├── sync/                # (not "family_sync/")
├── analytics/
├── settings/
└── gamification/
```

Differences:
- `transaction/` (ARCH-007) vs `accounting/` (ARCH-001)
- `category/` (ARCH-007) - does not exist as separate feature in ARCH-001
- `family_sync/` (ARCH-007) vs `sync/` (ARCH-001)
- `onboarding/` (ARCH-007) - does not exist in ARCH-001

#### 6.4 flutter_gen Reference (LOW)

**ARCH-007** (line 330) lists `flutter_gen` for code generation. This is not in ARCH-001's tech stack.

#### 6.5 Layer Naming (MEDIUM)

**ARCH-007** uses "BUSINESS LOGIC LAYER" (line 43) instead of ARCH-001's "APPLICATION LAYER".

#### 6.6 i18n Infrastructure Placement (OK)

ARCH-007 correctly shows i18n infrastructure in `lib/infrastructure/i18n/` and LocaleProvider in `lib/features/settings/presentation/providers/`. This aligns with ARCH-001/ARCH-008.

### Suggested Modifications for ARCH-007

1. **Remove `sqlite3_flutter_libs`** from tech stack - only `sqlcipher_flutter_libs`
2. **Update intl version** from `0.19+` to `0.20.2`
3. **Align feature names** with ARCH-001 (`accounting/` not `transaction/`, `sync/` not `family_sync/`)
4. **Remove or clarify `flutter_gen`** reference
5. **Rename "BUSINESS LOGIC LAYER"** to "APPLICATION LAYER"

---

## 7. ARCH-001 vs ARCH-008 (Layer Clarification)

### Version Status
- **ARCH-001:** v2.0 (2026-02-06)
- **ARCH-008:** v2.0 (2026-02-06) - Most authoritative for layer definitions

### Inconsistencies Found

#### 7.1 Old File Name Reference (MEDIUM)

**ARCH-008** (line 584) references:
```
- 文件: `01_MVP_Complete_Architecture_Guide.md`
```

This is the old file name. Should be `ARCH-001_Complete_Guide.md`.

#### 7.2 ADR Reference (LOW)

**ARCH-008** references `ADR-006_Layer_Responsibilities.md` consistently. This should be verified against the actual ADR file naming.

#### 7.3 Layer Definitions (OK - ALIGNED)

ARCH-008 and ARCH-001 are well-aligned on:
- 5-layer architecture (Presentation, Application, Domain, Data, Infrastructure)
- "Thin Feature" pattern
- Feature constraints (no application/, infrastructure/, data/tables/, data/daos/ inside features)
- Global Application layer at `lib/application/`
- Aggregated core capabilities table

This is expected since ARCH-001 v2.0 was specifically updated based on ARCH-008.

### Suggested Modifications for ARCH-008

1. **Update old file reference** from `01_MVP_Complete_Architecture_Guide.md` to `ARCH-001_Complete_Guide.md`
2. **Verify ADR-006 reference** matches actual file name in `docs/arch/03-adr/`

---

## 8. ARCH-001 Internal Inconsistencies

### 8.1 sqlite3_flutter_libs in Tech Stack (CRITICAL)

**ARCH-001** (line 48) lists:
```yaml
Database Engine: sqlite3_flutter_libs ^0.5.18
Encryption: sqlcipher_flutter_libs ^0.6.0
```

**CLAUDE.md** explicitly prohibits `sqlite3_flutter_libs`:
> Don't add `sqlite3_flutter_libs` - use only `sqlcipher_flutter_libs` (conflicts!)

ARCH-001 should remove `sqlite3_flutter_libs` from its tech stack.

### 8.2 intl Version (HIGH)

**ARCH-001** (line 71) lists:
```yaml
Internationalization: intl ^0.19.0
```

**CLAUDE.md** states intl is pinned at 0.20.2. ARCH-001 should update this.

---

## Summary Table

| # | Document | Issue | Severity | Category |
|---|----------|-------|----------|----------|
| 1 | ARCH-001 | Lists `sqlite3_flutter_libs` in tech stack (contradicts CLAUDE.md) | CRITICAL | Tech Stack |
| 2 | ARCH-001 | Lists `intl ^0.19.0` (should be 0.20.2 per CLAUDE.md) | HIGH | Tech Stack |
| 3 | ARCH-002 | Still v1.0 - not updated to v2.0 layer standards | HIGH | Version |
| 4 | ARCH-002 | Uses old Drift index syntax (`Index` vs `TableIndex` with `{#symbol}`) | CRITICAL | Code Pattern |
| 5 | ARCH-002 | Uses `@override` on `customIndexes` (forbidden by CLAUDE.md) | HIGH | Code Pattern |
| 6 | ARCH-002 | ERD field differences from ARCH-001 (Books, Categories) | HIGH | Data Model |
| 7 | ARCH-002 | Column type convention differs (dateTime/boolean vs integer) | MEDIUM | Data Model |
| 8 | ARCH-003 | Still v1.0 - not updated to v2.0 layer standards | HIGH | Version |
| 9 | ARCH-003 | Uses singleton KeyManager pattern (14+ occurrences) vs Riverpod providers | CRITICAL | Architecture Pattern |
| 10 | ARCH-003 | Corrupted/duplicated code block (lines 1120-1157) | HIGH | Document Quality |
| 11 | ARCH-003 | Defines `HashChainVerificationResult` as plain class (should be Freezed model) | MEDIUM | Code Pattern |
| 12 | ARCH-004 | Still v1.0 - not updated to v2.0 layer standards | HIGH | Version |
| 13 | ARCH-004 | Provider paths missing `presentation/` level | HIGH | Directory Structure |
| 14 | ARCH-004 | Default locale set to `zh_CN` instead of `ja` | MEDIUM | i18n |
| 15 | ARCH-004 | References old `14_ADR_State_Management.md` format | LOW | Document Reference |
| 16 | ARCH-004 | Shows `core/providers/` directory not in ARCH-001 | MEDIUM | Directory Structure |
| 17 | ARCH-005 | Still v1.0 - not updated to v2.0 layer standards | HIGH | Version |
| 18 | ARCH-005 | Uses "Business Logic Layer" instead of "Application Layer" | HIGH | Layer Naming |
| 19 | ARCH-005 | References `lib/core/domain/events/` paths not in ARCH-001 | HIGH | Directory Structure |
| 20 | ARCH-005 | References old `06_MOD_*` / `08_MOD_*` file names | LOW | Document Reference |
| 21 | ARCH-006 | Still v1.0 - not updated to v2.0 layer standards | HIGH | Version |
| 22 | ARCH-006 | Uses `lib/domain/` top-level path (does not exist in ARCH-001) | HIGH | Directory Structure |
| 23 | ARCH-006 | Uses `lib/presentation/` top-level path (does not exist in ARCH-001) | HIGH | Directory Structure |
| 24 | ARCH-006 | Places Use Cases in Domain layer instead of Application layer | HIGH | Architecture Pattern |
| 25 | ARCH-006 | Labels Use Case layer as "Domain Layer (Use Cases)" | MEDIUM | Layer Naming |
| 26 | ARCH-007 | Lists `sqlite3_flutter_libs` in tech stack (contradicts CLAUDE.md) | CRITICAL | Tech Stack |
| 27 | ARCH-007 | Lists `intl 0.19+` (should be 0.20.2) | HIGH | Tech Stack |
| 28 | ARCH-007 | Feature names differ from ARCH-001 (`transaction/` vs `accounting/`, etc.) | HIGH | Directory Structure |
| 29 | ARCH-007 | Uses "BUSINESS LOGIC LAYER" instead of "APPLICATION LAYER" | MEDIUM | Layer Naming |
| 30 | ARCH-007 | References `flutter_gen` not in ARCH-001 tech stack | LOW | Tech Stack |
| 31 | ARCH-008 | References old file name `01_MVP_Complete_Architecture_Guide.md` | MEDIUM | Document Reference |

---

## Severity Distribution

| Severity | Count | Percentage |
|----------|-------|-----------|
| CRITICAL | 4 | 13% |
| HIGH | 18 | 58% |
| MEDIUM | 7 | 23% |
| LOW | 2 | 6% |
| **Total** | **31** | **100%** |

---

## Priority Recommendations

### Immediate (CRITICAL - Fix before any development)

1. **Remove `sqlite3_flutter_libs` from ARCH-001 and ARCH-007 tech stacks** - This directly conflicts with the SQLCipher requirement and will cause build failures.
2. **Fix Drift index syntax in ARCH-002** - Developers following ARCH-002 examples will produce code that fails to compile.
3. **Replace singleton KeyManager in ARCH-003 with Riverpod providers** - The singleton pattern undermines the entire DI architecture.

### Short-term (HIGH - Fix within current sprint)

4. **Update ARCH-002, ARCH-003, ARCH-004, ARCH-005, ARCH-006 to v2.0** - These documents still reflect the pre-ARCH-008 architecture. Developers following them will create incorrect directory structures.
5. **Reconcile ERD between ARCH-001 and ARCH-002** - Contradictory data models will cause implementation confusion.
6. **Fix directory structure paths** in ARCH-004, ARCH-005, ARCH-006 to match the v2.0 "Thin Feature" pattern.
7. **Standardize layer naming** across all documents (use "Application Layer" consistently).

### Medium-term (MEDIUM/LOW - Fix during documentation sprint)

8. **Reconcile column type conventions** (integer vs dateTime/boolean) across ARCH-001 and ARCH-002.
9. **Update all old document references** (`14_ADR_*`, `06_MOD_*`, `01_MVP_*`) to current naming scheme.
10. **Clean up corrupted code in ARCH-003** (lines 1120-1157).
11. **Align feature names in ARCH-007** with ARCH-001.

---

## Test Verification

- [x] All 8 ARCH documents read completely
- [x] Cross-referenced layer definitions across all documents
- [x] Cross-referenced directory structure paths
- [x] Verified tech stack consistency against CLAUDE.md
- [x] Verified code examples against CLAUDE.md mandatory patterns
- [x] Identified all version discrepancies

---

## References

- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` (v2.0, primary reference)
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` (v1.0)
- `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` (v1.0)
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` (v1.0)
- `docs/arch/01-core-architecture/ARCH-005_Integration_Patterns.md` (v1.0)
- `docs/arch/01-core-architecture/ARCH-006_Error_Boundaries.md` (v1.0)
- `docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` (v2.0)
- `docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md` (v2.0)
- `CLAUDE.md` (canonical project instructions)

---

**Created:** 2026-02-22 09:46
**Author:** Claude Opus 4.6
