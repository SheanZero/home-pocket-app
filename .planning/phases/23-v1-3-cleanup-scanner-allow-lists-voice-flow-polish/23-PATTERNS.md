# Phase 23: v1.3 cleanup — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 24 (6 new, 18 modified)
**Analogs found:** 24 / 24 (100% — every file has a direct in-repo precedent, except the mixin which has a researcher-supplied skeleton because no in-house mixin exists yet)

---

## File Classification

Grouped by data-flow layer (Infrastructure → Data → Application → Presentation → Tests → Docs).

### Application Layer

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `lib/application/seed/seed_all_use_case.dart` | NEW | use-case (orchestrator) | request-response (composition) | `lib/application/accounting/seed_categories_use_case.dart` + `lib/application/accounting/seed_voice_synonyms_use_case.dart` | exact (constructor-DI use case wrapping ordered awaits) |
| `lib/application/seed/seed_providers.dart` | NEW | Riverpod provider | DI wiring | `lib/application/voice/repository_providers.dart` (entire file) | exact (same `@riverpod` function-style provider exposing a use case, with `part` directive for codegen) |
| `lib/application/voice/voice_chunk_merger.dart` | MOD | application service | streaming (timer + buffer) | (self — adding public `lastFinalAt` getter; mirror existing `_lastFinalAt` private at line 55) | exact (in-file accessor add) |
| `lib/application/voice/voice_category_resolver.dart` | MOD | application service | request-response | (self — replace local const map with import) | trivial (1-line import swap) |

### Data Layer

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `lib/data/daos/category_keyword_preference_dao.dart` | MOD | DAO | CRUD | (self — replace local `final epoch = DateTime(2026, 1, 1)` at line 90 with shared import) | trivial (1-line import + 1-line constant swap) |

### Infrastructure Layer

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `lib/infrastructure/ml/merchant_database.dart` | MOD | infrastructure service | request-response (lookup) | (self — guard insertion at line 150 substring-pass head) | trivial (3-line early-return guard) |

### Shared Constants

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `lib/shared/constants/category_other_id_overrides.dart` | NEW | constants | static data | `lib/shared/constants/voice_currency_suffixes.dart` (uninstantiable class) AND `lib/shared/constants/default_synonyms.dart` (`abstract final class`) | exact (single-source-of-truth constant pattern) |
| `lib/shared/constants/default_synonyms.dart` | MOD | constants | static data | (self — make `_epoch` → `kVoiceSynonymSeedEpoch` public; append 3 seed rows) | trivial (visibility flip + 3 appended `_seed(...)` calls) |

### Presentation Layer

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` | NEW | mixin on State | event-driven | **NO in-repo precedent** (zero user-authored mixins in `lib/`) — use researcher skeleton in `23-RESEARCH.md` §Pattern 1 (lines 306-391); abstract-getter contract pattern is standard Flutter idiom | researcher-derived (no in-house analog) |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | MOD | screen | event-driven | (self — extract `_onStatus`/`_onError` lines 172-220 to mixin; add D-05 guard inside mixin; add D-07 `ref.listen` in initState; add D-08 popUntil deferral in `_onSavePressed`; D-09 hoist `_handleFocusChange` already idiomatic — see Open Q2) | self-refactor |

### Tests

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `test/unit/application/seed/seed_all_use_case_test.dart` | NEW | unit test | mocktail | `test/unit/application/accounting/seed_categories_use_case_test.dart` | exact (mocktail `Mock implements` + `setUp` + `useCase.execute` pattern) |
| `test/integration/voice/voice_corpus_en_test.dart` | NEW | integration test | corpus | `test/integration/voice/voice_corpus_zh_test.dart` (skeleton shape) AND `test/integration/voice/voice_category_corpus_zh_test.dart` (resolver setup); per RESEARCH Open Q4, single inline `testWidgets` — no fixture file needed | role-match (shape from zh, single-case downsize per Open Q4) |
| `test/integration/voice/voice_corpus_zh_test.dart` | MOD | integration test | corpus | (self — add `其他` anchor case to anchor-cases group) | self-extend |
| `test/integration/voice/voice_corpus_ja_test.dart` | MOD | integration test | corpus | (self — add `その他` anchor case to anchor-cases group) | self-extend |
| `test/unit/infrastructure/ml/merchant_database_test.dart` | MOD | unit test | request-response | (self — add D-13 length-guard tests; existing `test` block pattern at lines 13-53) | self-extend |
| `test/architecture/category_other_l2_invariant_test.dart` | MOD | architecture test | invariant | (self — replace local `_otherIdOverrides` const at line 35 with shared import) | trivial (1-line import) |
| `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | MOD | widget test | event-driven | (self — extend G-02 test at lines 946-1004 per D-11; add D-05/D-07/D-08/D-09 anchor `testWidgets` blocks using existing `FakeStartSpeechRecognitionUseCase` / `CapturingStartSpeechRecognitionUseCase` fakes at lines 23-130) | self-extend |
| `lib/main.dart` | MOD | bootstrap | sequential init | (self — collapse lines 108-114 into single `seedAllUseCaseProvider` read) | trivial (1 line replacing 6) |

### Documentation

| File | NEW/MOD | Role | Data Flow | Closest Analog | Match Quality |
|------|---------|------|-----------|----------------|---------------|
| `.planning/REQUIREMENTS.md` | MOD | requirements doc | checkbox + table edits | (self — 10 `[ ]`→`[x]` flips at lines 21, 22, 26, 29, 32, 39, 40, 41, 50, 51; table rows 110-117 + 120-121 `Pending`→`Complete`) | trivial (mechanical text edits) |
| `.planning/phases/18-shared-details-form-foundation/18-{02,04,06,07,08}-SUMMARY.md` | MOD (5 files) | phase doc | YAML frontmatter | `.planning/phases/22-voice-one-step-integration-record-button-ux/22-04-SUMMARY.md:62` (`requirements-completed: [INPUT-02, REC-01, REC-02]`) + Phase 19 `19-02-SUMMARY.md:59` (`requirements-completed: [KEYPAD-01]`) | exact (one-line YAML key in frontmatter, before `# Metrics` block) |
| `.planning/phases/19-manual-one-step-keypad-polish/19-{03,05}-SUMMARY.md` | MOD (2 files) | phase doc | YAML frontmatter | same as above | exact |

---

## Pattern Assignments

### NEW: `lib/application/seed/seed_all_use_case.dart` (use-case orchestrator)

**Analogs:**
- `lib/application/accounting/seed_categories_use_case.dart` (full file — 30 LOC)
- `lib/application/accounting/seed_voice_synonyms_use_case.dart` (full file — 34 LOC)

**Imports pattern** (from `seed_categories_use_case.dart` lines 1-4):
```dart
import '../../features/accounting/domain/repositories/category_ledger_config_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../shared/constants/default_categories.dart';
import '../../shared/utils/result.dart';
```
Phase 23 imports both leaf use cases (not their repositories):
```dart
import '../accounting/seed_categories_use_case.dart';
import '../accounting/seed_voice_synonyms_use_case.dart';
import '../../shared/utils/result.dart';
```

**Constructor-DI pattern** (from `seed_categories_use_case.dart` lines 11-18):
```dart
class SeedCategoriesUseCase {
  SeedCategoriesUseCase({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  }) : _categoryRepo = categoryRepository,
       _configRepo = ledgerConfigRepository;

  final CategoryRepository _categoryRepo;
  final CategoryLedgerConfigRepository _configRepo;
```

**Execute pattern** (from `seed_categories_use_case.dart` lines 20-29):
```dart
Future<Result<void>> execute() async {
  final existing = await _categoryRepo.findAll();
  if (existing.isNotEmpty) {
    return Result.success(null);
  }
  await _categoryRepo.insertBatch(DefaultCategories.all);
  await _configRepo.upsertBatch(DefaultCategories.defaultLedgerConfigs);
  return Result.success(null);
}
```

Phase 23 SeedAllUseCase.execute composes the two awaits with short-circuit on first failure — see RESEARCH §Pattern 4 (lines 462-484) for the verbatim skeleton:
```dart
Future<Result<void>> execute() async {
  final categoriesResult = await _seedCategories.execute();
  if (!categoriesResult.isSuccess) return categoriesResult;
  return _seedVoiceSynonyms.execute();
}
```

---

### NEW: `lib/application/seed/seed_providers.dart` (Riverpod wiring)

**Analog:** `lib/application/voice/repository_providers.dart` (full file — 43 LOC)

**Top-of-file `part` + import pattern** (lines 1-8):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/speech/speech_recognition_service.dart';
import '../../infrastructure/voice/chinese_numeral_state_machine.dart';
import '../../infrastructure/voice/japanese_numeral_state_machine.dart';
import 'start_speech_recognition_use_case.dart';

part 'repository_providers.g.dart';
```

For Phase 23 Phase 23 (note: file is `seed_providers.dart`, so `part` filename matches):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../accounting/seed_categories_use_case.dart';
import '../accounting/seed_voice_synonyms_use_case.dart';
import 'seed_all_use_case.dart';

part 'seed_providers.g.dart';
```

**Function-style provider that composes other providers** (lines 19-25):
```dart
@riverpod
StartSpeechRecognitionUseCase startSpeechRecognitionUseCase(Ref ref) {
  return StartSpeechRecognitionUseCase(
    service: ref.watch(appSpeechRecognitionServiceProvider),
  );
}
```

Phase 23 wires `seedAllUseCaseProvider` reading the two existing leaf providers via `ref.watch`:
```dart
@riverpod
SeedAllUseCase seedAllUseCase(Ref ref) {
  return SeedAllUseCase(
    seedCategories: ref.watch(seedCategoriesUseCaseProvider),
    seedVoiceSynonyms: ref.watch(seedVoiceSynonymsUseCaseProvider),
  );
}
```

Note the leaf providers `seedCategoriesUseCaseProvider` + `seedVoiceSynonymsUseCaseProvider` live in `lib/features/accounting/presentation/providers/repository_providers.dart:168-182` — the new file must import that.

**Codegen requirement:** after creating this file, run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `seed_providers.g.dart`. See generated-file precedent at `lib/application/voice/repository_providers.g.dart`.

---

### NEW: `lib/shared/constants/category_other_id_overrides.dart` (single-source-of-truth constant)

**Analogs:**
- `lib/shared/constants/voice_currency_suffixes.dart` (full file — 36 LOC) — uninstantiable class with private ctor + static `const List<String>`
- `lib/shared/constants/default_synonyms.dart` (lines 20-26) — `abstract final class` with documentary docstring + `static final` constants

**Pattern A: top-level `const Map` (matches what's already in resolver + arch test)** — both source sites currently use a top-level `const Map<String, String>`. Keep this shape; just promote to public, drop the leading underscore:

From `lib/application/voice/voice_category_resolver.dart:28-35`:
```dart
/// L1 ids whose `_other` L2 child does NOT follow the `${l1Id}_other` convention.
/// Mirrors test/architecture/category_other_l2_invariant_test.dart::_otherIdOverrides
/// (Phase 21 D-03 + PATTERNS.md §7 caveat). When adding entries here, update
/// the architecture test allowlist atomically. IN-05 follow-up tracks lifting
/// this to a single shared source of truth.
const Map<String, String> _otherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

From `test/architecture/category_other_l2_invariant_test.dart:30-37`:
```dart
/// Explicit override map for L1 ids whose `${l1Id}_other` L2 does NOT follow
/// the `${l1Id}_other` convention — verified in `default_categories.dart`
/// (line ~1181 for cat_other_other). Adding entries here is permitted ONLY
/// after VoiceCategoryResolver._ensureL2 (Plan 03) is updated to consult the
/// same map.
const Map<String, String> _otherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

**Phase 23 target shape** (see RESEARCH §D-12 IN-05 code example at lines 649-663):
```dart
// lib/shared/constants/category_other_id_overrides.dart
// Source: Phase 23 D-12 IN-05 dedup. Replaces duplicate maps in
// lib/application/voice/voice_category_resolver.dart:33-35 and
// test/architecture/category_other_l2_invariant_test.dart:35-37.

/// L1 ids whose `_other` L2 child does NOT follow the `${l1Id}_other`
/// convention. Single source of truth — both VoiceCategoryResolver and
/// the architecture test import this map.
const Map<String, String> kCategoryOtherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

Naming convention `k`-prefix matches the new `kVoiceSynonymSeedEpoch` constant being extracted in D-12 IN-01. Both are top-level `const` (not class statics) — simpler than wrapping in a class for a single constant.

---

### NEW: `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` (mixin on State)

**Analog:** **NONE in-repo.** This is the first user-authored mixin in `lib/`. Use the researcher-supplied skeleton in `23-RESEARCH.md` §Pattern 1 (lines 306-391) verbatim, then add the D-05 guard per `23-RESEARCH.md` §Code Examples (lines 606-644).

**Key contract decisions** (from RESEARCH lines 318-348):
- Generic `on State<W extends StatefulWidget>` so the mixin can read `mounted`, call `setState`, access `widget`.
- Abstract getters/setters for screen-local state the mixin needs to read/write (`isRecording`, `pressStart`, `isInitialized`, `soundLevel`, `lastMergerFinalAt`).
- Abstract method `Future<void> stopRecordingAndCommit()` — the screen retains ownership of the commit path (CONTEXT.md `<specifics>` "Commit-path is OFF LIMITS"), the mixin only invokes it.
- D-05 threshold exposed as `static const Duration intraSessionThreshold = Duration(milliseconds: 800)` so tests + device UAT can read it without dart reflection.

**File location justification** (from RESEARCH constraint table line 108): mixin lives in `lib/features/accounting/presentation/screens/` because it is presentation glue, not domain logic — Thin Feature rule only restricts `application/`, `infrastructure/`, `data/tables/`, `data/daos/` from appearing inside `features/`.

---

### MOD: `lib/application/voice/voice_chunk_merger.dart` (add `lastFinalAt` getter)

**Analog:** (self) — mirror the existing private field at line 55.

**Existing private field** (line 55):
```dart
DateTime? _lastFinalAt;
```

**Phase 23 addition** (per RESEARCH §Open Q1 lines 759-773 — expose `lastFinalAt`, NOT `lastPartialAt`):
```dart
/// Phase 23 D-05: last final-result timestamp, exposed for the voice screen's
/// intra-session `notListening` heuristic guard. Null when no final has been
/// fed yet in the current session. See RESEARCH §Open Q1 for the
/// final-vs-partial timing analysis.
DateTime? get lastFinalAt => _lastFinalAt;
```

Place after the `_lastFinalAt` field declaration (around line 56) or in the public API surface near `stop()` (lines 100-103) — planner's choice.

**Risk note (RESEARCH Open Q1):** if device UAT reveals that finals are too sparse to drive D-05 reliably, the planner pivots to adding `_lastPartialAt` to `_VoiceInputScreenState` and exposing it via the mixin's abstract `DateTime? get lastPartialAt`. Phase 23 ships with `lastFinalAt` first; device UAT is the revision trigger.

---

### MOD: `lib/application/voice/voice_category_resolver.dart` (import shared constant)

**Analog:** (self) — replace lines 33-35 with import.

**Before** (lines 28-35):
```dart
/// L1 ids whose `_other` L2 child does NOT follow the `${l1Id}_other` convention.
/// Mirrors test/architecture/category_other_l2_invariant_test.dart::_otherIdOverrides
/// (Phase 21 D-03 + PATTERNS.md §7 caveat). When adding entries here, update
/// the architecture test allowlist atomically. IN-05 follow-up tracks lifting
/// this to a single shared source of truth.
const Map<String, String> _otherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

**After:** Add to import block (lines 21-26):
```dart
import '../../shared/constants/category_other_id_overrides.dart';
```

Delete the local `_otherIdOverrides` const. Update line 133 reference:
```dart
// Before
final otherId = _otherIdOverrides[cat.id] ?? '${cat.id}_other';
// After
final otherId = kCategoryOtherIdOverrides[cat.id] ?? '${cat.id}_other';
```

---

### MOD: `lib/data/daos/category_keyword_preference_dao.dart` (import shared epoch)

**Analog:** (self) — replace line 90 local literal with shared constant.

**Before** (lines 86-105):
```dart
Future<void> insertSeedBatch(
  List<({String keyword, String categoryId})> seeds,
) async {
  if (seeds.isEmpty) return;
  final epoch = DateTime(2026, 1, 1);          // ← line 90
  await _db.batch((b) {
    for (final seed in seeds) {
      b.insert(
        _db.categoryKeywordPreferences,
        CategoryKeywordPreferencesCompanion.insert(
          keyword: seed.keyword,
          categoryId: seed.categoryId,
          hitCount: const Value(0),
          lastUsed: epoch,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });
}
```

**After:** Add import at top:
```dart
import '../../shared/constants/default_synonyms.dart' show kVoiceSynonymSeedEpoch;
```

Delete `final epoch = DateTime(2026, 1, 1);` at line 90. Replace `lastUsed: epoch` with `lastUsed: kVoiceSynonymSeedEpoch`.

**Note** (RESEARCH Pitfall 5 lines 568-574): the planner MUST sequence the constant-rename in `default_synonyms.dart` AND the DAO import in the **same task** to prevent silent drift back to two literals.

---

### MOD: `lib/shared/constants/default_synonyms.dart` (D-12 IN-01 + D-15)

**Analog:** (self) — two changes in one file.

**D-12 IN-01: visibility flip** (line 26):

Before:
```dart
static final DateTime _epoch = DateTime(2026, 1, 1);
```

After (promote to top-level `final`, top-of-file, with `k`-prefix per Dart constant convention):
```dart
/// Phase 21 D-01 / Phase 23 D-12: fixed epoch written by both
/// [CategoryKeywordPreferenceDao.insertSeedBatch] and
/// [DefaultVoiceSynonyms._seed]. Single source of truth so audit queries
/// that filter on `lastUsed = epoch` see consistent row counts.
final DateTime kVoiceSynonymSeedEpoch = DateTime(2026, 1, 1);
```

Inside `DefaultVoiceSynonyms`, update line 117 `lastUsed: _epoch` → `lastUsed: kVoiceSynonymSeedEpoch`. Delete the private `_epoch` field.

**D-15: append 3 new seed rows** (after line 105 `_seed('书', 'cat_education_books'),`):

Per RESEARCH §D-15 code example lines 711-718:
```dart
// ===== Other-expense override seeds (D-15 / IN-06) =====
// Exercises the cat_other_expense → cat_other_other override in
// VoiceCategoryResolver._ensureL2 via real corpus utterances.
// 'other' is added as a v1.4+ en-voice hedge — voice gating in v1.3 is
// zh/ja only, but the override is exercised in case en voice activates.
_seed('その他', 'cat_other_expense'),
_seed('其他', 'cat_other_expense'),
_seed('other', 'cat_other_expense'),
```

---

### MOD: `lib/infrastructure/ml/merchant_database.dart` (D-13 length guard)

**Analog:** (self) — early-return guard at the head of the substring pass at line 150.

**Existing substring pass** (lines 150-162):
```dart
// 3. Substring match (query contains entry name, or entry name contains query)
for (final entry in _entries) {
  if (lowerQuery.contains(entry.name.toLowerCase()) ||
      entry.name.toLowerCase().contains(lowerQuery)) {
    return _toMatch(entry);
  }
  for (final alias in entry.aliases) {
    if (lowerQuery.contains(alias.toLowerCase()) ||
        alias.toLowerCase().contains(lowerQuery)) {
      return _toMatch(entry);
    }
  }
}
```

**Phase 23 addition** (per RESEARCH §D-13 lines 668-685 — insert BEFORE line 151 `for`):
```dart
// 3. Substring match (query contains entry name, or entry name contains query)
// IN-03 guard: skip substring matching for queries shorter than 3 chars
// because single/double-char queries match too many false positives
// (e.g., 'a' matches 'amazon' via 'amazon'.contains('a')).
// Exact-match pass (steps 1+2 above) is unaffected.
if (lowerQuery.length < 3) return null;

for (final entry in _entries) {
  // ... existing body unchanged ...
}
```

**Safety verification needed** (per RESEARCH Pitfall 7 lines 588-590): planner should grep merchant DB entry names + aliases for length-<3 strings before landing the guard. The 12 hardcoded entries currently all have names ≥3 chars (McDonald, Starbucks, Yoshinoya, 7-Eleven, FamilyMart, Lawson, Sukiya, Uniqlo, Nitori, Yamada, Amazon, Netflix). Add a regression test enforcing this in `test/unit/infrastructure/ml/merchant_database_test.dart`.

---

### MOD: `lib/features/accounting/presentation/screens/voice_input_screen.dart` (D-05, D-07, D-08, D-09, D-10, D-11 partial)

**Analog:** (self) — six surgical edits.

**D-10 (mixin extraction):** Remove `_onStatus` body (lines 172-196) and `_onError` body (lines 198-220) from `_VoiceInputScreenState`. Replace with `with VoiceRecognitionEventHandlerMixin<VoiceInputScreen>` on the class declaration (current line 54-55):

Before:
```dart
class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with WidgetsBindingObserver {
```

After:
```dart
class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with WidgetsBindingObserver, VoiceRecognitionEventHandlerMixin {
```

Implement the abstract contract: add public getter/setter pairs delegating to existing private fields (`_isRecording`, `_pressStart`, etc.) — per RESEARCH §Pitfall 2 lines 546-548, the screen exposes a single `set isInitialized(bool value)` setter wrapping `setState` so the mixin and screen share one write surface.

**D-05 (intra-session guard):** Lands INSIDE the mixin's `onStatus`, not in the screen — see Pattern Assignments for the mixin file above. The screen only needs to provide `DateTime? get lastMergerFinalAt => _amountMerger?.lastFinalAt;`.

**D-07 (cold-start race):** Add a new `_isLocaleReady` flag, initialized to `false`. In `initState` (after `_initSpeechService()` call at line 154), add `ref.listenManual` per RESEARCH §Pattern 2 lines 416-430:
```dart
ref.listenManual<AsyncValue<String>>(
  voiceLocaleIdProvider,
  (prev, next) {
    if (next case AsyncData(:final value)) {
      _voiceLocaleId = value;
      if (mounted && !_isLocaleReady) {
        setState(() => _isLocaleReady = true);
      }
    } else if (next case AsyncError()) {
      // Pitfall 3 lines 552-558: graceful degradation. Fall back to default locale.
      if (mounted && !_isLocaleReady) {
        setState(() => _isLocaleReady = true);
      }
    }
  },
  fireImmediately: true,
);
```

Update `_onLongPressStart` at line 243 to gate on the new flag:
```dart
void _onLongPressStart(LongPressStartDetails details) {
  if (!_isInitialized || !_isLocaleReady || _isRecording) return;
  _pressStart = DateTime.now();
  _startRecording();
}
```

**D-08 (popUntil deferral):** In `_onSavePressed` (line 397 onward), branch on ledger type. For soul-ledger, await celebration before pop. Per RESEARCH §Pattern 3 option (A) at lines 449-450: add a `Future<void> waitForCelebrationDismissed()` method to `TransactionDetailsFormState` and `await` it before `popUntil` in the soul branch. Survival-ledger pops immediately as today.

Wrap the deferred pop in `if (!mounted) return;` per RESEARCH §Pitfall 4 lines 562-564.

**D-09 (listener hoist):** Per RESEARCH §Open Q2 lines 776-792 — the voice screen ALREADY uses the same method reference (`_handleFocusChange` at line 140-141 is the same instance tear-off for both add and dispose). The real bug is test-only in `transaction_details_form_test.dart` (NOT in scope per the file list). Phase 23 work here: add a regression unit test asserting `FocusNode.hasListeners == false` post-dispose. No production code change needed.

**Line-cap target** (RESEARCH §A5 line 749): after extracting `_onStatus` (~25 lines) + `_onError` (~23 lines) the screen drops from 832 to ≈785 LOC, below the 800 cap.

---

### MOD: `lib/main.dart` (D-14 seed call collapse)

**Analog:** (self) — collapse lines 108-114 to one provider read.

**Before** (lines 108-114):
```dart
// Seed categories
final seedCategories = ref.read(seedCategoriesUseCaseProvider);
await seedCategories.execute();
// Phase 21 D-01: synonyms must run AFTER categories.
final seedVoiceSynonyms = ref.read(seedVoiceSynonymsUseCaseProvider);
await seedVoiceSynonyms.execute();
```

**After** (per RESEARCH §D-14 lines 689-702):
```dart
// Phase 23 D-14: SeedAllUseCase owns the ordering contract.
final seedAll = ref.read(seedAllUseCaseProvider);
await seedAll.execute();
```

Update import block at lines 12-15 — remove `seedCategoriesUseCaseProvider` + `seedVoiceSynonymsUseCaseProvider` if no other call site uses them in this file; add `seedAllUseCaseProvider` from `lib/application/seed/seed_providers.dart`.

---

### NEW: `test/unit/application/seed/seed_all_use_case_test.dart`

**Analog:** `test/unit/application/accounting/seed_categories_use_case_test.dart` (full file — 63 LOC)

**Imports + mocks pattern** (lines 1-11):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryLedgerConfigRepository extends Mock
    implements CategoryLedgerConfigRepository {}
```

Phase 23 SeedAllUseCase test imports:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/application/accounting/seed_voice_synonyms_use_case.dart';
import 'package:home_pocket/application/seed/seed_all_use_case.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSeedCategoriesUseCase extends Mock implements SeedCategoriesUseCase {}
class _MockSeedVoiceSynonymsUseCase extends Mock implements SeedVoiceSynonymsUseCase {}
```

**setUp pattern** (lines 13-25):
```dart
late _MockCategoryRepository mockCategoryRepo;
late _MockCategoryLedgerConfigRepository mockConfigRepo;
late SeedCategoriesUseCase useCase;

setUp(() {
  mockCategoryRepo = _MockCategoryRepository();
  mockConfigRepo = _MockCategoryLedgerConfigRepository();
  useCase = SeedCategoriesUseCase(
    categoryRepository: mockCategoryRepo,
    ledgerConfigRepository: mockConfigRepo,
  );
});
```

**Ordering assertion pattern** (per RESEARCH §D-14 line 488 — "record completion + start timestamps, assert categories complete before synonyms start"). Mocktail `thenAnswer` can use `DateTime.now()` capture:
```dart
test('D-14: seeds categories before synonyms', () async {
  DateTime? categoriesCompletedAt;
  DateTime? synonymsStartedAt;

  when(() => mockSeedCategories.execute()).thenAnswer((_) async {
    await Future.delayed(const Duration(milliseconds: 5));
    categoriesCompletedAt = DateTime.now();
    return Result.success(null);
  });
  when(() => mockSeedSynonyms.execute()).thenAnswer((_) async {
    synonymsStartedAt = DateTime.now();
    return Result.success(null);
  });

  await useCase.execute();

  expect(categoriesCompletedAt, isNotNull);
  expect(synonymsStartedAt, isNotNull);
  expect(categoriesCompletedAt!.isBefore(synonymsStartedAt!), isTrue,
    reason: 'Phase 23 D-14: categories must complete before synonyms start');
});
```

Add a second test for the short-circuit-on-failure case (categories fails → synonyms not invoked).

---

### NEW: `test/integration/voice/voice_corpus_en_test.dart`

**Analogs:**
- `test/integration/voice/voice_corpus_zh_test.dart` (full file — 90 LOC) for the file shape
- `test/integration/voice/voice_category_corpus_zh_test.dart` (lines 33-46) for the resolver setup (seeded provider scope)

**Per RESEARCH Open Q4 (lines 805-811):** single inline `testWidgets` (no fixture file). The CONTEXT.md D-15 specific says "skeleton with just the one `その他/他/etc.` override case. Do NOT expand en corpus coverage beyond this one case."

**Resolver setup pattern** (from `voice_category_corpus_zh_test.dart:25-46`):
```dart
void main() {
  late final container = createTestProviderScope();
  late VoiceCategoryResolver resolver;
  late CategoryKeywordPreferenceRepository prefRepo;

  setUpAll(() async {
    await container.read(seedCategoriesUseCaseProvider).execute();
    await container.read(seedVoiceSynonymsUseCaseProvider).execute();
    prefRepo = container.read(categoryKeywordPreferenceRepositoryProvider);
    resolver = VoiceCategoryResolver(
      categoryRepository: container.read(categoryRepositoryProvider),
      preferenceRepository: prefRepo,
      categoryService: container.read(categoryServiceProvider),
      merchantDatabase: MerchantDatabase(),
    );
  });

  group('en hedge corpus (Phase 23 D-15 / IN-06)', () {
    test('"other" -> cat_other_other (en voice hedge)', () async {
      final result = await resolver.resolve('other');
      expect(result, isNotNull);
      expect(result!.categoryId, 'cat_other_other');
    });
  });
}
```

Note: when this file goes to D-14 the SeedAll wrapper will be available, but `voice_category_corpus_zh_test.dart` calls the leaf providers directly (lines 35-37) and that pattern still works (RESEARCH Pitfall 8 lines 593-598 — the wrapper does NOT replace the leaves).

---

### MOD: `test/integration/voice/voice_corpus_zh_test.dart` AND `voice_corpus_ja_test.dart` (D-15 anchor cases)

**Analog:** (self) — both files have `anchor cases` group at lines 15-46 (zh) / 15-46 (ja). Add a `D-15: 其他/その他 override` anchor case.

**Caution:** the existing anchor cases test the **number parser** (`VoiceTextParser.extractAmount`) — they DON'T exercise the category resolver. The D-15 corpus assertions must hit the resolver path. Two choices for the planner:

1. **Add to `voice_category_corpus_zh_test.dart` / `voice_category_corpus_ja_test.dart`** (which DO exercise the resolver — these are different files from `voice_corpus_*_test.dart`). This is the technically correct location for resolver assertions. CONTEXT.md says `voice_corpus_zh_test.dart` but the actual seed→resolver routing belongs in the `voice_category_corpus_*` files.
2. **Follow CONTEXT.md verbatim** (`voice_corpus_zh_test.dart`) — add a new `testWidgets` block that builds the resolver inline (heavier setup).

**Recommended: extend `voice_category_corpus_zh_test.dart` / `voice_category_corpus_ja_test.dart`** (option 1). The planner should flag this divergence from CONTEXT.md in the plan rationale. The CONTEXT.md naming may be a typo conflating the two file families.

If keeping CONTEXT.md verbatim (option 2), the test cannot assert categoryId — it can only assert the seed row exists (read from `categoryKeywordPreferenceRepository`), which is a weaker contract.

---

### MOD: `test/unit/infrastructure/ml/merchant_database_test.dart` (D-13 length-guard tests)

**Analog:** (self) — existing tests at lines 13-53 follow `test('description', () { ... })` shape with `setUp` providing a fresh `MerchantDatabase` instance (lines 7-11).

**Existing setUp** (lines 7-11):
```dart
late MerchantDatabase database;

setUp(() {
  database = MerchantDatabase();
});
```

**Phase 23 additions** (per RESEARCH §D-13 lines 666-685 + Pitfall 7 lines 588-589):
```dart
test('D-13: findMerchant returns null for queries shorter than 3 chars', () {
  expect(database.findMerchant('a'), isNull);
  expect(database.findMerchant('ab'), isNull);
});

test('D-13: findMerchant continues to substring-match at 3 chars', () {
  // 'mac' is a substring of 'マクドナルド' aliases or 'McDonald' — verifies
  // the 3-char threshold is the floor, not blocking legitimate matches.
  final match = database.findMerchant('mac');
  expect(match, isNotNull);
});

test('D-13: Pitfall 7 regression — all merchant entries have name length >= 3', () {
  // No automated way to introspect _entries; assert via a representative
  // exact-match probe of every known entry. Planner: enumerate the 12
  // entries explicitly here.
  for (final name in ['McDonald', 'Starbucks', 'Yoshinoya', ...]) {
    expect(name.length, greaterThanOrEqualTo(3),
      reason: 'D-13 substring guard: all entry names must be ≥3 chars');
  }
});
```

---

### MOD: `test/architecture/category_other_l2_invariant_test.dart` (import shared constant)

**Analog:** (self) — replace lines 35-37 with import.

**Before** (lines 30-37):
```dart
/// Explicit override map for L1 ids whose `${l1Id}_other` L2 does NOT follow
/// the `${l1Id}_other` convention — verified in `default_categories.dart`
/// (line ~1181 for cat_other_other). Adding entries here is permitted ONLY
/// after VoiceCategoryResolver._ensureL2 (Plan 03) is updated to consult the
/// same map.
const Map<String, String> _otherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

**After:** Add to import block:
```dart
import 'package:home_pocket/shared/constants/category_other_id_overrides.dart';
```

Delete the local `_otherIdOverrides` const. Update line 64 reference:
```dart
// Before
final expectedOtherId = _otherIdOverrides[l1Id] ?? '${l1Id}_other';
// After
final expectedOtherId = kCategoryOtherIdOverrides[l1Id] ?? '${l1Id}_other';
```

---

### MOD: `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (D-05/D-07/D-08/D-09/D-11 anchors)

**Analog:** (self) — file is 1006 LOC; G-02 permanent test at lines 946-1004 already follows the right shape. Existing fakes (`FakeStartSpeechRecognitionUseCase` at lines 26-54; `CapturingStartSpeechRecognitionUseCase` reused at line 949) are the test rigging to reuse.

**D-11 (extend G-02 test at line 976):**

Before:
```dart
// The toast appears (already covered by transient test for assertion
// depth; here we just confirm no exception was thrown).
expect(find.byType(SoftToast), findsOneWidget);
```

After (add localized-string assertion BEFORE the SoftToast presence assertion, per RESEARCH §Validation lines 174-180):
```dart
// D-11: assert the localized error string appears in the toast. This
// verifies G-02's ARB-key lookup path is healthy. Comes BEFORE the
// SoftToast presence assertion so failure points at the missed string
// rather than the toast.
final l10n = lookupAppLocalizations(const Locale('ja')); // or whichever locale buildSubject uses
expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget);

expect(find.byType(SoftToast), findsOneWidget);
```

Confirm the locale used by `buildSubject` to construct the `l10n` for the assertion.

**D-05 / D-07 / D-08 / D-09 (new testWidgets blocks):** Per CONTEXT.md `<specifics>` anchor scenarios (lines 175-183):

- **D-05 intra-session guard** — Two tests: `lastFinalAt = now - 100ms` → assert `_stopRecordingAndCommit` NOT called (use Capturing fake to record stop call); `lastFinalAt = now - 2000ms` → assert commit fires.
- **D-07 cold-start gate** — Override `voiceLocaleIdProvider` to `AsyncValue.loading()`, simulate long-press, assert no startListening; resolve provider, second press fires.
- **D-08 popUntil deferral** — Soul-ledger save: assert `SoulCelebrationOverlay` present + navigator did NOT pop; trigger overlay's `onCompleted`, assert pop. Survival-ledger save: assert pop fires immediately.
- **D-09 listener-leak regression** — Pump screen, dispose, assert `FocusNode.hasListeners == false`.

All four extensions follow the same `testWidgets('description', (tester) async { ... })` shape as the G-02 test (lines 946-1004). Reuse `buildSubject(...)` helper (defined elsewhere in this file).

Per CONTEXT.md D-20 ("default: extend existing files unless the new test bucket has natural file boundary") — keep all five in this file.

---

### MOD: `.planning/REQUIREMENTS.md` (D-04 checkbox + table flips)

**Analog:** (self) — mechanical text edits. No code analog needed.

Per CONTEXT.md D-04: 10 `[ ]`→`[x]` flips at lines 21 (INPUT-03), 22 (INPUT-04), 26 (VOICE-01), 29 (VOICE-02), 32 (VOICE-03), 39 (VOICE-04), 40 (VOICE-05), 41 (VOICE-06), 50 (EDIT-01), 51 (EDIT-02). Traceability table rows 110-117 + 120-121 `Pending`→`Complete`. All line refs verified in RESEARCH §Phase Requirements (lines 85-95).

---

### MOD: Seven SUMMARY.md frontmatter backfills

**Analog:** `.planning/phases/22-voice-one-step-integration-record-button-ux/22-04-SUMMARY.md:62`:
```yaml
requirements-completed: [INPUT-02, REC-01, REC-02]
```

Also `.planning/phases/19-manual-one-step-keypad-polish/19-02-SUMMARY.md:59`:
```yaml
requirements-completed: [KEYPAD-01]
```

**Pattern:** single YAML key in the closing-frontmatter block, before `# Metrics`. Insert as one line.

**Phase 23 backfills** (per RESEARCH §Phase Requirements lines 95-96):

| File | Insert | Source |
|------|--------|--------|
| `.planning/phases/18-shared-details-form-foundation/18-02-SUMMARY.md` | `requirements-completed: [INPUT-04, EDIT-01]` (verify per audit) | v1.3-MILESTONE-AUDIT.md `partial_requirements[]` |
| `.planning/phases/18-shared-details-form-foundation/18-04-SUMMARY.md` | `requirements-completed: [INPUT-03, INPUT-04, EDIT-02]` (verify) | same |
| `.planning/phases/18-shared-details-form-foundation/18-06-SUMMARY.md` | `requirements-completed: [...]` (verify) | same |
| `.planning/phases/18-shared-details-form-foundation/18-07-SUMMARY.md` | `requirements-completed: [...]` (verify) | same |
| `.planning/phases/18-shared-details-form-foundation/18-08-SUMMARY.md` | `requirements-completed: [...]` (verify) | same |
| `.planning/phases/19-manual-one-step-keypad-polish/19-03-SUMMARY.md` | `requirements-completed: [INPUT-01]` | RESEARCH line 96 |
| `.planning/phases/19-manual-one-step-keypad-polish/19-05-SUMMARY.md` | `requirements-completed: [INPUT-01]` | RESEARCH line 96 |

Planner: cross-check the exact list per-file against `v1.3-MILESTONE-AUDIT.md` `partial_requirements[]` before writing.

---

## Shared Patterns

### Pattern: Constructor-DI use case with `Result<T>` return

**Source:** `lib/application/accounting/seed_categories_use_case.dart` (full file)
**Apply to:** `lib/application/seed/seed_all_use_case.dart` (NEW — D-14)

```dart
class SeedCategoriesUseCase {
  SeedCategoriesUseCase({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  }) : _categoryRepo = categoryRepository,
       _configRepo = ledgerConfigRepository;

  final CategoryRepository _categoryRepo;
  final CategoryLedgerConfigRepository _configRepo;

  Future<Result<void>> execute() async {
    // ...
    return Result.success(null);
  }
}
```

Every use case in `lib/application/` follows this shape. Phase 23 SeedAllUseCase MUST match.

---

### Pattern: `@riverpod` function-style provider with `ref.watch` composition

**Source:** `lib/features/accounting/presentation/providers/repository_providers.dart:168-182`
**Apply to:** `lib/application/seed/seed_providers.dart` (NEW — D-14)

```dart
@riverpod
SeedCategoriesUseCase seedCategoriesUseCase(Ref ref) {
  return SeedCategoriesUseCase(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}
```

After codegen, the provider is auto-named `seedCategoriesUseCaseProvider` (strip the `UseCase` suffix? NO — for function-style providers, the provider name = function name + `Provider`). Verify by running `flutter pub run build_runner build --delete-conflicting-outputs` and inspecting `seed_providers.g.dart`.

---

### Pattern: Top-level `const Map<String, String>` for cross-file lookup tables

**Source:** `lib/application/voice/voice_category_resolver.dart:33-35` AND `test/architecture/category_other_l2_invariant_test.dart:35-37` (currently duplicated)
**Apply to:** `lib/shared/constants/category_other_id_overrides.dart` (NEW — D-12 IN-05)

```dart
const Map<String, String> kCategoryOtherIdOverrides = {
  'cat_other_expense': 'cat_other_other',
};
```

Top-level `const` with `k`-prefix per Dart convention. Imported by both the resolver and the architecture test.

---

### Pattern: Mocktail-based use-case unit test

**Source:** `test/unit/application/accounting/seed_categories_use_case_test.dart` (full file)
**Apply to:** `test/unit/application/seed/seed_all_use_case_test.dart` (NEW — D-14)

Structure:
1. Top-of-file `class _MockX extends Mock implements X {}` declarations
2. `late` fields + `setUp` that instantiates fresh mocks + use case under test
3. `group('UseCaseName', () { ... })` containing one `test(...)` per behavior
4. Use `when(() => mock.method(any())).thenAnswer((_) async { ... });` for stubbing
5. Use `verify(() => ...).called(1);` / `verifyNever(...)` for invocation assertions

---

### Pattern: Riverpod 3 `ref.listen` for side-effect gating

**Source:** RESEARCH §Pattern 2 lines 401-430 (no in-repo full example — the voice screen already uses `ref.watch` in build but D-07 needs `ref.listen` in initState)
**Apply to:** `lib/features/accounting/presentation/screens/voice_input_screen.dart` (D-07)

Per CLAUDE.md §"Riverpod 3 conventions": "Side-effect listeners belong in `ref.listen`, not `ref.watch`. Use `ref.listen` for navigation, snackbars, etc."

Use `ref.listenManual` in `initState` with `fireImmediately: true`. Handle both `AsyncData` and `AsyncError` per RESEARCH Pitfall 3.

---

### Pattern: `INSERT OR IGNORE` Drift seed batch + epoch sentinel

**Source:** `lib/data/daos/category_keyword_preference_dao.dart:86-105`
**Apply to:** (No new DAO writes in Phase 23 — but D-12 IN-01 must preserve the `hitCount=0` + `kVoiceSynonymSeedEpoch` sentinel pair so existing `decayStalePreferences` continues to protect seed rows.)

Reference pattern (NOT modified):
```dart
mode: InsertMode.insertOrIgnore,
// ...
hitCount: const Value(0),
lastUsed: epoch,  // ← becomes kVoiceSynonymSeedEpoch after D-12
```

---

### Pattern: YAML frontmatter `requirements-completed: [REQ-ID, ...]`

**Source:** `.planning/phases/22-voice-one-step-integration-record-button-ux/22-04-SUMMARY.md:62` AND `.planning/phases/19-manual-one-step-keypad-polish/19-02-SUMMARY.md:59`
**Apply to:** Seven Phase 18/19 SUMMARY files (D-04)

Insert as a single line in the existing frontmatter block, before the `# Metrics` divider. List form `[REQ-ID, REQ-ID]` with bracket-enclosed CSV.

---

## No Analog Found

| File | Role | Data Flow | Reason | Fallback |
|------|------|-----------|--------|----------|
| `lib/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart` | mixin on State | event-driven | Zero user-authored mixins exist in `lib/` (only Freezed/Drift codegen + framework mixins like `WidgetsBindingObserver`). Phase 23 establishes the precedent. | Use the researcher-supplied skeleton in `23-RESEARCH.md` §Pattern 1 (lines 306-391) — verified-correct against `voice_input_screen.dart:172-220` field-access inventory at line 393-397 of RESEARCH. |

---

## Metadata

**Analog search scope:**
- `lib/application/` — seed + voice use cases for D-14 patterns
- `lib/application/voice/` + `lib/infrastructure/voice/` — D-05 merger accessor + mixin contract
- `lib/shared/constants/` — D-12 + D-15 constant placement
- `lib/data/daos/` — D-12 IN-01 DAO import
- `lib/infrastructure/ml/` — D-13 guard
- `test/unit/application/accounting/` + `test/unit/application/voice/` — mocktail use-case test shapes
- `test/integration/voice/` — corpus test shapes (D-15)
- `test/architecture/` — invariant test pattern (D-12)
- `test/widget/features/accounting/presentation/screens/` — widget test fakes (D-05/D-07/D-08/D-09/D-11)
- `.planning/phases/22/*` + `.planning/phases/19/*` — frontmatter backfill pattern (D-04)

**Files scanned:** ~30 (use cases, providers, constants, DAOs, infrastructure services, tests, SUMMARY docs)

**Pattern extraction date:** 2026-05-25

**Confidence:** HIGH for every analog except the mixin (MEDIUM — researcher skeleton is verified against current code but no in-repo precedent exists for comparable mixin extractions).
