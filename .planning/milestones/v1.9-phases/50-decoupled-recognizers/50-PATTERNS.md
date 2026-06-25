# Phase 50: Decoupled Recognizers - Pattern Map

**Mapped:** 2026-06-23
**Files analyzed:** 13 (new/modified/deleted)
**Analogs found:** 11 / 11 mappable (2 are pure deletions)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/application/voice/recognition/merchant_recognizer.dart` (NEW) | service (engine) | transform / request-response | `lib/infrastructure/ml/merchant_database.dart` (anti-pattern it replaces) + `voice_category_resolver.dart` (`_seedCache` load-once) | role-match |
| `lib/application/voice/recognition/category_recognizer.dart` (NEW) | service (engine) | transform | `lib/application/voice/voice_category_resolver.dart` (direct evolution, minus step-1) | exact |
| `lib/features/accounting/domain/models/merchant_candidate.dart` (NEW) | model (verdict) | value object | `lib/infrastructure/ml/merchant_database.dart` `MerchantMatch` + `voice_parse_result.dart` `CategoryMatchResult` | role-match |
| `lib/application/voice/parse_voice_input_use_case.dart` (REWRITE) | use case (orchestrator) | request-response | self (rewrite of existing two-branch merge) | exact (self) |
| `lib/application/voice/voice_text_parser.dart` (MODIFY — delete merchant block) | utility (parser) | transform | self (delete `:504-567`) | exact (self) |
| `lib/features/accounting/domain/repositories/merchant_repository.dart` (MODIFY — add method) | repository interface | CRUD/read | self (Phase 49 interface) | exact (self) |
| `lib/data/daos/merchant_dao.dart` (MODIFY — add query) | DAO | read | self (`findAllMatchKeyRows`/`findMatchKeysFor` already present) | exact (self) |
| `lib/data/repositories/merchant_repository_impl.dart` (MODIFY — add method) | repository impl | read | self (`findAll` join-in-tx pattern) | exact (self) |
| `lib/shared/constants/default_synonyms.dart` (DATA expansion) | config/data (authored seed) | batch | self + `lib/shared/constants/default_merchants.dart` (Phase 49 authored-seed scale) | exact (self) |
| `test/.../default_synonyms_categoryid_test.dart` (NEW gate) | test | — | `test/unit/shared/constants/default_merchants_categoryid_test.dart` (Phase 49 D-08 gate) | exact |
| `test/.../merchant_recognizer_test.dart` + `merchant_false_positive_test.dart` (NEW) | test | — | existing voice recognizer tests | role-match |
| `lib/infrastructure/ml/merchant_database.dart` (DELETE) | — | — | — (D-05 retirement) | n/a |
| `lib/application/ml/lookup_merchant_use_case.dart` + provider + test (DELETE) | — | — | — (D-05, no live consumer per research A3) | n/a |

## Pattern Assignments

### `lib/application/voice/recognition/merchant_recognizer.dart` (service, transform)

**Analogs:** `merchant_database.dart` (the bidirectional-substring `:158-159` it REPLACES — anti-pattern), `merchant_name_normalizer.dart` (reuse verbatim on query side), `voice_category_resolver.dart` (`_seedCache` load-once + longest-key-wins ranking).

**Query normalization — REUSE verbatim** (`merchant_name_normalizer.dart:24`, `:112`):
```dart
// The SAME function the Phase-49 seed used to compute merchant_match_keys.matchKey.
// Idempotent; double-normalize is safe. Do NOT write a second normalizer.
import '../../../infrastructure/ml/merchant_name_normalizer.dart';
final nq = normalizeMerchantKey(query);   // or MerchantNameNormalizer.key(query)
```

**Anti-pattern being replaced** (`merchant_database.dart:155-161` — do NOT copy this shape):
```dart
if (lowerQuery.length < 3) return null;            // IN-03 <3-char guard (idea kept, generalized)
for (final entry in _entries) {
  if (lowerQuery.contains(entry.name.toLowerCase()) ||   // ← bidirectional substring
      entry.name.toLowerCase().contains(lowerQuery)) {   //   false-positives at 400-scale
```

**Replacement: anchored scoring tiers** (RESEARCH Pattern 1; nq = normalized query, mk = row.matchKey):
```dart
double score;
if (nq == mk)                              score = 1.00;  // exact
else if (mk.startsWith(nq) || nq.startsWith(mk)) score = 0.85; // anchored prefix (すたば⊂すたーばっくす)
else if (mk.contains(nq) && _passesScriptMinLength(nq))  score = 0.60; // weak — recall only
else if (nq.contains(mk) && _passesScriptMinLength(mk))  score = 0.55; // weak — recall only
else continue;
// _passesScriptMinLength: kana/latin >= 3 runes, kanji-containing >= 2 runes (A2; tune vs corpus)
// D-03 submit floor = 0.85 (lives in the ORCHESTRATOR, not the engine).
```

**Load-once warm cache** (mirror `voice_category_resolver.dart:69` `_seedCache ??= await ...`, RESEARCH A5):
```dart
// Recommended: load all match entries once via merchantRepository.loadAllForMatching()
// (~391+ rows), keepAlive provider; recognizer stays synchronous after warm-up.
List<MerchantMatchEntry>? _cache;
```

**Ranking** (mirror resolver "longest-key-wins" `voice_category_resolver.dart:150`): sort score DESC, then longer matchKey first; dedupe one candidate per merchantId (keep best-scoring surface).

**Engine independence (DECOUP-01):** MUST NOT import/take `CategoryRecognizer`. Merge happens only in orchestrator.

---

### `lib/application/voice/recognition/category_recognizer.dart` (service, transform)

**Analog:** `lib/application/voice/voice_category_resolver.dart` — this IS that file minus step-1.

**Carry over UNCHANGED:** steps 2 (`:104-118` exact keyword via `_preferenceRepository.findByKeyword`), 2.5 (`:120-166` substring fallback over `_seedCache` + promoted learned rows, `kLearnedPromotionThreshold=3`), `_ensureL2` (`:188-202`), `normalizeToL2` (`:180`), `resolveLedgerType` (`:205`).

**DELETE:** step-1 merchant lookup (`:86-99` `_merchantDatabase.findMerchant`), the `_merchantDatabase` field (`:63`) + constructor param (`:54`), and the `merchant_database.dart` import (`:26`).

**Constructor after edit** (drop one dependency from `:50-58`):
```dart
CategoryRecognizer({
  required CategoryRepository categoryRepository,
  required CategoryKeywordPreferenceRepository preferenceRepository,
  required CategoryService categoryService,
  // merchantDatabase param DELETED
}) : ...
```

**Runs UNCONDITIONALLY (DECOUP-02)** — no merchant gate. `resolve(extractedKeyword)` returns `CategoryMatchResult?` exactly as today. Rename class → `CategoryRecognizer`; Riverpod 3 generates `categoryRecognizerProvider` (name strips nothing here — see RESEARCH Open Q #3).

---

### `lib/features/accounting/domain/models/merchant_candidate.dart` (model, value object)

**Analogs:** `MerchantMatch` (`merchant_database.dart:9-21` — the infra type being replaced) + `CategoryMatchResult` (`voice_parse_result.dart:52-58` — the `@freezed` shape to mirror).

**Mirror this `@freezed` shape** (`voice_parse_result.dart:51-58`):
```dart
@freezed
abstract class MerchantCandidate with _$MerchantCandidate {
  const factory MerchantCandidate({
    required String merchantId,
    required String displayName,
    required double score,        // raw score only — NO banding this phase (RESEARCH Open Q #2)
    required String categoryId,   // real L2 from Merchant.categoryId
    required String ledgerHint,   // NON-authoritative (Phase 49 D-09) — never stamped as ledger
  }) = _MerchantCandidate;
}
```

**Domain constraint:** Domain must NOT import application/data/infrastructure (CLAUDE.md Pitfall 2). Plain value object, no I/O. Requires `flutter pub run build_runner build` after.

---

### `lib/application/voice/parse_voice_input_use_case.dart` (use case, REWRITE)

**Analog:** self — rewrite the merchant/keyword merge block (`:70-115`).

**KEEP unchanged:** amount (`:59`), currency detection (`:65`, `_detectCurrency` `:148`), date (`:68`), `_extractKeyword` (`:192`) as the SINGLE canonical key source (Pitfall 4 / 260526-pg6), `resolvedKeyword = keyword.isEmpty ? null : keyword` (`:87`), the `Result.success/error` envelope (`:117`, `:131`).

**DELETE:** `_merchantDatabase` field (`:28`) + ctor param (`:40`), `merchant_database.dart` import (`:3`), `extractAndMatchMerchant` call (`:71-74`), and the **merchant-ledger short-circuit `:106`** `ledgerType = merchantMatch.ledgerType;` (LEDGER-01 brought forward — D-02).

**NEW thin keyword-priority merge (D-02)** replaces `:90-115` (RESEARCH Pattern 3):
```dart
// Two engines run independently (DECOUP-01) — neither calls the other.
final categoryMatch = await _categoryRecognizer.resolve(keyword);          // unconditional
final merchantCandidates = _merchantRecognizer.recognize(recognizedText);  // ranked, recall-first

CategoryMatchResult? finalCategory;
LedgerType? ledgerType;
if (categoryMatch != null) {
  finalCategory = categoryMatch;                                            // keyword wins
  ledgerType = await _categoryRecognizer.resolveLedgerType(categoryMatch.categoryId);
} else {
  final best = merchantCandidates.isEmpty ? null : merchantCandidates.first;
  if (best != null && best.score >= kMerchantAutoFillFloor) {              // 0.85 (D-03)
    final l2 = await _categoryRecognizer.normalizeToL2(best.categoryId);
    finalCategory = CategoryMatchResult(
      categoryId: l2 ?? best.categoryId, confidence: best.score, source: MatchSource.merchant);
    ledgerType = await _categoryRecognizer.resolveLedgerType(finalCategory.categoryId); // pure fn — NOT ledgerHint
  }
  // below floor → finalCategory null; candidates still surfaced on verdict.
}
```

**Carry merchant candidates onto `VoiceParseResult`** (extend model; preserve `resolvedKeyword` write — `:127`).

---

### `lib/application/voice/voice_text_parser.dart` (utility, MODIFY)

**Analog:** self. **DELETE** `extractAndMatchMerchant` (`:504-519`) + `_extractPotentialMerchantNames` (`:521-567`) + the `merchant_database.dart` import (top). **KEEP** all amount/date/keyword extraction (heavily corpus-tested — RESEARCH Don't Hand-Roll).

---

### Repository match-key lookup — interface + DAO + impl

**Interface** `merchant_repository.dart` — add to the existing abstract class (`:8-24`):
```dart
/// Load every match-key row paired with its merchant's category/ledger hint,
/// for in-memory recognizer matching. Loaded once (keepAlive); ~391+ rows.
Future<List<MerchantMatchEntry>> loadAllForMatching();
```

**DAO** `merchant_dao.dart` — the join data already exists: reuse `findAllMerchantRows()` (`:29`) + `findAllMatchKeyRows()` (`:46`) inside `readInTransaction` (`:24`). No new query needed; impl joins them.

**Impl** `merchant_repository_impl.dart` — mirror `findAll()` (`:18-35`) join-in-one-read-transaction pattern (WR-04 point-in-time consistency):
```dart
@override
Future<List<MerchantMatchEntry>> loadAllForMatching() {
  return _dao.readInTransaction(() async {
    final rows = await _dao.findAllMerchantRows();
    final keys = await _dao.findAllMatchKeyRows();
    final byId = { for (final r in rows) r.id: r };
    return keys.map((k) {
      final m = byId[k.merchantId]!;
      return MerchantMatchEntry(matchKey: k.matchKey, surface: k.surface,
        merchantId: m.id, displayName: m.nameJa, categoryId: m.categoryId, ledgerHint: m.ledgerHint);
    }).toList();
  });
}
```
`MerchantMatchEntry` is a flat `@freezed` record (place in domain/models alongside `MerchantCandidate`, or reuse the `Merchant`/`MerchantMatchKey` models from `merchant.dart`).

**Provider wiring** (`repository_providers.dart`): `merchantRepositoryProvider` (`:85`) already exists. Add `merchantRecognizerProvider` + `categoryRecognizerProvider` (rename `voiceCategoryResolverProvider` `:262`); update `parseVoiceInputUseCaseProvider` (`:278`) ctor args; DELETE `merchantDatabase:` arg (`:269`, `:279`).

---

### `lib/shared/constants/default_synonyms.dart` (DATA expansion, D-04)

**Analogs:** self (`DefaultVoiceSynonyms._seed` pattern `:152`, VOICE-06 contract — add a literal, no resolver change) + `lib/shared/constants/default_merchants.dart` (Phase-49-scale authored-seed deliverable — plan as a dedicated wave/plan).

**Pattern to clone — one `_seed(keyword, categoryId)` per surface** (`:33-147`). zh+ja only (English deferred, see header `:24-27`). Expand ~120 → full speakable-L2 (~103 L2 × zh+ja). SC4 gap to add (RESEARCH Code Examples):
```dart
_seed('加油', 'cat_car_fuel'), _seed('给油', 'cat_car_fuel'),
_seed('給油', 'cat_car_fuel'), _seed('ガソリン', 'cat_car_fuel'),
// existing seed only has ガス→cat_utilities_gas (household gas) — that mis-resolves 加油.
```
L1 ids are legitimate (e.g. `食事`→`cat_food` `:43`) — `_ensureL2` routes them. May split into per-L1 files aggregated by `default_synonyms.dart` (VOICE-06 allows). **User spot-checks before commit (D-04 mandate).**

---

### `test/unit/shared/constants/default_synonyms_categoryid_test.dart` (NEW gate)

**Analog:** clone `test/unit/shared/constants/default_merchants_categoryid_test.dart` (Phase 49 D-08 gate, full structure above).

**Key difference (Pitfall 3):** legal set must allow L1 ids that `_ensureL2` resolves (existing seeds use them), not only level==2. Extend the `l2Ids` set:
```dart
final l2Ids = DefaultCategories.all.where((c)=>c.level==2).map((c)=>c.id).toSet();
final l1WithChild = DefaultCategories.all.where((c)=>c.level==1 &&
    DefaultCategories.all.any((x)=>x.parentId==c.id)).map((c)=>c.id).toSet();
for (final s in DefaultVoiceSynonyms.all) {
  expect(l2Ids.contains(s.categoryId) || l1WithChild.contains(s.categoryId), isTrue,
    reason: 'Seed "${s.keyword}" -> ${s.categoryId} is neither real L2 nor L1-with-child (silent-null)');
}
```
Copy the offenders-list-naming style (`:23-34`) so failures name exact bad rows.

---

### New recognizer tests

- `merchant_recognizer_test.dart` — scoring tiers + ranking + four surface forms (スタバ / ｽﾀﾊﾞ half-width / マクド Kansai / Starbucks romaji → 咖啡); DECOUP-03/SC3.
- `merchant_false_positive_test.dart` + `test/fixtures/merchant_false_positive_corpus.dart` — ~40 adversarial entries (お米/杉並区/comment-words), assert "no match OR score < 0.85 floor"; SC2, validates A1/A2.
- `category_recognizer_test.dart` — port `voice_category_resolver_test.dart`, drop merchant-step-1 assertions.
- `parse_voice_input_use_case_test.dart` — REWRITE for four-quadrant (merchant✓keyword✓「在星巴克买杯子」→购物 / merchant✓keyword✗ bare スタバ→咖啡 / merchant✗keyword✓「加油用了400块」→燃料 / merchant✗keyword✗→no auto-fill). Preserve `resolvedKeyword` write-key==read-key regression (260526-pg6).

## Shared Patterns

### Normalization (reuse, never re-implement)
**Source:** `lib/infrastructure/ml/merchant_name_normalizer.dart` `normalizeMerchantKey` (`:24`) / `MerchantNameNormalizer.key` (`:112`)
**Apply to:** `MerchantRecognizer` query side (byte-identical to seed-side or matches silently miss — Pitfall 1). Idempotent; zero new deps (no `kana_kit`).

### `@freezed` value-object models
**Source:** `voice_parse_result.dart` (`CategoryMatchResult` `:52`, `MerchantMatch` infra `:9`)
**Apply to:** `MerchantCandidate`, `MerchantMatchEntry`. Run build_runner after.

### Read-in-one-transaction repository reads (WR-04)
**Source:** `merchant_repository_impl.dart` `findAll()` (`:18-35`) wrapping `_dao.readInTransaction` (`merchant_dao.dart:24`)
**Apply to:** `loadAllForMatching()`.

### Riverpod 3 `@riverpod` provider wiring
**Source:** `repository_providers.dart` `merchantRepository` (`:85`), `voiceCategoryResolver` (`:262`), `parseVoiceInputUseCase` (`:278`)
**Apply to:** new `merchantRecognizerProvider` / renamed `categoryRecognizerProvider`; provider name derives from class (CLAUDE.md Riverpod-3 conventions). Keep `MerchantRecognizer` keepAlive (in-memory cache, mirrors `appMerchantDatabase` keepAlive rationale `application/ml/repository_providers.dart:18`).

### Authored-seed gate (D-08 → D-04 mirror)
**Source:** `test/unit/shared/constants/default_merchants_categoryid_test.dart`
**Apply to:** the `seed-keyword-categoryId-是真L2` gate (extended legal set for L1-with-child).

### Ledger = pure function of final category (LEDGER-01)
**Source:** `voice_category_resolver.dart` `resolveLedgerType` (`:205`) → `CategoryService.resolveLedgerType`
**Apply to:** orchestrator merge — NEVER stamp `merchant.ledgerHint` (Phase 49 D-09 non-authoritative). Delete `parse_voice_input_use_case.dart:106`.

### Security — no-log discipline (V7)
**Apply to:** both new engines — never `print`/log raw transcript / amount / merchant. Resolved merchant name flows into the already-encrypted transaction field. Seed lists are public; user utterances are not.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | Every new file has a strong in-repo analog. `MerchantRecognizer` scorer (~60 lines) is the only genuinely new LOGIC, but its normalization, data backend, ranking, and load-once cache all reuse existing patterns. |

## Metadata

**Analog search scope:** `lib/application/voice/`, `lib/application/voice/recognition/` (new), `lib/infrastructure/ml/`, `lib/features/accounting/domain/{models,repositories}/`, `lib/data/{daos,repositories}/`, `lib/shared/constants/`, `lib/features/accounting/presentation/providers/`, `test/unit/shared/constants/`
**Files scanned:** 12 read in full/section + 1 grep pass over provider wiring
**Pattern extraction date:** 2026-06-23
