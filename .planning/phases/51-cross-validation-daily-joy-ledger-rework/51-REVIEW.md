---
phase: 51-cross-validation-daily-joy-ledger-rework
reviewed: 2026-06-24T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/features/voice/domain/services/recognition_reconciler.dart
  - lib/features/voice/domain/models/recognition_outcome.dart
  - lib/features/voice/domain/models/voice_parse_result.dart
  - lib/features/voice/domain/models/merchant_candidate.dart
  - lib/application/accounting/create_transaction_use_case.dart
  - lib/features/accounting/presentation/providers/repository_providers.dart
  - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
  - lib/shared/constants/default_categories.dart
  - test/unit/features/voice/domain/services/cross_validation_test.dart
  - test/integration/features/accounting/ledger_invariant_test.dart
  - test/architecture/ledger_reachable_l2_invariant_test.dart
  - test/unit/application/accounting/merchant_ledger_hint_never_read_test.dart
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 51: Code Review Report

**Reviewed:** 2026-06-24
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 51 merged the XVAL reconciler and the LEDGER rework. The core invariants the
phase was built to protect mostly hold up under tracing:

- **LEDGER purity holds.** `CreateTransactionUseCase` derives the ledger solely from
  `CategoryService.resolveLedgerType(categoryId) ?? daily` (lines 141-148). The merchant
  `ledgerHint` is genuinely never read for the transaction ledger — confirmed by grep
  (`merchantCategoryId`/`ledgerHint` have no ledger-deriving readers) and by
  `merchant_ledger_hint_never_read_test.dart`.
- **Domain purity holds.** `RecognitionReconciler` / `RecognitionOutcome` import only
  intra-domain model leaves + `freezed_annotation`; the `import_guard.yaml` whitelist
  structurally enforces it. The reconciler is pure/sync/ledger-free as specified.
- **Learning-key identity holds.** `VoiceParseResult.resolvedKeyword` is set from the
  single canonical `_extractKeyword` output (line 94/183), and the write path
  (`voice_input_screen_helpers.dart:66`) reads that exact field. Write-key == read-key.
- **The `band==medium` gating in the use case is correct.** The non-null assertions
  `outcome.selectedCategoryId!` are provably safe in both branches.

The serious problem is **downstream of** the use case: the form-fill consumer
(`voice_ptt_session_mixin.dart`) bypasses the 0.85 floor the phase formalized, filling
the form category from any below-floor merchant candidate. That is the one BLOCKER.

Several quality issues stem from `RecognitionOutcome` being a richer contract than any
production consumer reads — `alternates`, `keywordMerchantConflict`, and the threaded
`resolvedKeyword` on the outcome are all dead, and the auto-fill floor constant is now
duplicated across two files with no compile-time link.

## Critical Issues

### CR-01: Form-fill bypasses the 0.85 auto-fill floor — below-floor merchant categories are auto-stamped

**File:** `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart:341-349`
**Issue:**
The whole point of XVAL this phase was to gate category auto-fill on the 0.85 floor:
the use case only populates `VoiceParseResult.categoryMatch` when a keyword hit OR
`outcome.band == ConfidenceBand.medium` (merchant `>= 0.85`). Below the floor,
`categoryMatch` is deliberately left null and the candidate is surfaced only for manual
Phase-52 chips.

But the active form-fill path ignores that gate:

```dart
final categoryId =
    data.categoryMatch?.categoryId ?? data.merchantCategoryId;
if (categoryId != null) {
  final repo = ref.read(categoryRepositoryProvider);
  category = await repo.findById(categoryId);
  ...
}
if (category != null) state.updateCategory(category, parent);
```

`data.merchantCategoryId` is set unconditionally in the use case from
`bestCandidate?.categoryId` (`parse_voice_input_use_case.dart:180`) for *any* surfaced
candidate — including below-floor (e.g. score 0.55) ones, and including the
both-weak best-guess. Merchant `categoryId`s are L2 seed ids (per D-06 / A3), so
`findById` resolves to a real L2 and the form silently auto-fills it. Net effect: on
every end-of-speech final where the keyword missed and any merchant scored at/above the
recall threshold but **below** 0.85, the form auto-stamps the merchant category — exactly
the case the reconciler classifies `band=weak` and the use case refuses to fill.

This is the only production reader of `merchantCategoryId` (grep-confirmed), so the floor
is effectively defeated for the form category. The line predates Phase 51, but Phase 51
both edited this method (adding `fillCategory` hysteresis) and formalized the floor it
contradicts, so it is in scope and load-bearing for the phase's intent.

**Fix:** Drop the `?? data.merchantCategoryId` fallback so the form honors the use case's
gate (only `categoryMatch` — which is already floor-gated — fills the category). If a
below-floor pre-fill is genuinely wanted as a stop-gap before Phase-52 chips, make it
explicit and gate it on band, not on the always-present `merchantCategoryId`:

```dart
// Honor the use-case floor: only categoryMatch is floor-gated. The raw
// merchantCategoryId is below-floor / un-cross-validated and must NOT auto-fill.
final categoryId = data.categoryMatch?.categoryId;
```

## Warnings

### WR-01: `kMerchantAutoFillFloor` is duplicated across two files with no compile-time link — silent drift risk

**File:** `lib/application/voice/parse_voice_input_use_case.dart:19` and `lib/features/voice/domain/services/recognition_reconciler.dart:9`
**Issue:**
The floor const is declared in both files (both `0.85`). After this phase the gating logic
lives entirely in the reconciler (`bestMerchant.score >= kMerchantAutoFillFloor`, reconciler
line 39); the use case's copy is now referenced ONLY by its own docstrings and by the
boundary test. The two have no shared source of truth — a future tune of the reconciler's
floor (say to 0.80) would leave the use case const + its detailed `D-03` docstring silently
lying, and the boundary test (which imports the *use-case* copy, see WR-02) would still pass
against the stale value. The domain-can't-import-application constraint is real, but the
contract should be expressed once and re-exported, not hand-copied.
**Fix:** Make the reconciler's const the single source of truth and have the use case
re-export it (`export ... show kMerchantAutoFillFloor;` from the domain file, or a shared
domain constant both import), or add an `assert`/test asserting the two are equal so drift
is caught.

### WR-02: Floor boundary test pins the decorative use-case const, not the live reconciler const

**File:** `test/unit/application/voice/parse_voice_input_use_case_test.dart:339`
**Issue:**
The "exactly-at-floor (0.85) auto-fills" boundary test feeds
`_candidate(score: kMerchantAutoFillFloor)` imported from
`application/voice/parse_voice_input_use_case.dart`. That const no longer drives the gating
(the reconciler's own const does). The test therefore validates behavior against a value
that has no causal link to the code under test — if the reconciler floor moves, the
production boundary shifts but this test does not, so the regression net has a hole exactly
at the boundary it claims to defend.
**Fix:** Import the floor const from `recognition_reconciler.dart` (the authoritative
gating const) so the boundary test tracks the value that actually gates.

### WR-03: `RecognitionOutcome.alternates` and `keywordMerchantConflict` are computed then discarded — dead output

**File:** `lib/features/voice/domain/services/recognition_reconciler.dart:66-72, 87-92, 99-122`
**Issue:**
The reconciler does real work building the de-duplicated, rank-ordered `alternates` list and
the `keywordMerchantConflict` flag, but grep confirms **no production code reads either**
(`outcome.alternates` has zero readers; `keywordMerchantConflict` only appears at its
definition and assignment). The use case constructs `VoiceParseResult.merchantCandidates`
directly from the raw recognizer output (`parse_voice_input_use_case.dart:185`), bypassing
`outcome.alternates` entirely. This is forward-looking scaffolding for Phase-52 chips, but as
shipped it is dead computation on every parse and an unverified contract (the alternates
de-dup logic is exercised only by `cross_validation_test.dart`, never by an integration
consumer).
**Fix:** Acceptable to keep if Phase 52 is imminent, but either (a) wire the use case to
surface `outcome.alternates` on `VoiceParseResult` instead of re-deriving from raw
candidates, so the reconciler's de-dup is the single source, or (b) annotate the fields as
deliberately-fallow with the consuming phase id so a future reviewer does not mistake them
for live behavior.

### WR-04: `outcome.resolvedKeyword` threading is redundant — the live learning-key comes from a parallel local

**File:** `lib/features/voice/domain/services/recognition_reconciler.dart:70, 81, 91` and `lib/application/voice/parse_voice_input_use_case.dart:183`
**Issue:**
The reconciler threads `resolvedKeyword` into `RecognitionOutcome` (the D-13 identity
contract), but the use case never reads `outcome.resolvedKeyword`; it writes the local
`resolvedKeyword` variable directly onto `VoiceParseResult` (line 183). The learning-key
identity invariant is preserved — but via the local, not via the outcome. So the outcome's
`resolvedKeyword` field is dead, and the field comment on `recognition_outcome.dart:47-50`
claiming it is "threaded verbatim from the keyword verdict" overstates its role: the live
key never transits the outcome. This is a correctness-of-documentation issue that could
mislead a future maintainer into relying on `outcome.resolvedKeyword`.
**Fix:** Either consume `outcome.resolvedKeyword` in the use case (single threading path) or
drop the field from `RecognitionOutcome` and adjust the doc comment to reflect that the
canonical key is carried on `VoiceParseResult`, not the reconciliation outcome.

## Info

### IN-01: Most clothing L2s now override parent L1 to daily while the parent stays joy — verify intent

**File:** `lib/shared/constants/default_categories.dart:1198, 1213-1218`
**Issue:**
`cat_clothing` (L1) is `joy`, but 6 of its 10 L2 children (`clothes`, `shoes`, `underwear`,
`cleaning`, `hair`, `accessories`) are overridden to `daily`; the remaining 4 (`cosmetics`,
`esthetic`, `other`, `bags`) inherit `joy`. The split is plausible (everyday apparel = daily,
beauty/bags = joy) and is documented as user-approved (D-18), so this is informational, not a
defect — but it means the L1 ledger no longer represents the modal child, which can surprise
anyone reasoning about "clothing = joy."
**Fix:** None required; confirm the four non-overridden L2s (cosmetics/esthetic/other/bags
inheriting joy) is the intended product behavior.

### IN-02: `Result.error('Voice parse failed: $e')` interpolates the raw exception into the message

**File:** `lib/application/voice/parse_voice_input_use_case.dart:189`
**Issue:**
The catch-all interpolates `$e` into a user-surfaceable error string. The transcript/amount
are not directly embedded, but a parser exception's `toString()` could in principle carry a
fragment of the offending input. In a zero-knowledge app this is worth a glance.
**Fix:** Keep the raw `$e` for an internal/log channel only; return a generic user-facing
message ("voice parse failed") without interpolating arbitrary exception text into the
surfaced `Result.error`.

### IN-03: `_parseResult?.estimatedSatisfaction != null` is always true for a non-null result

**File:** `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart:366-368`
**Issue:**
`estimatedSatisfaction` is a non-nullable `int` (default 5), so the `!= null` guard is always
true whenever `_parseResult` is non-null — the intended "only write satisfaction when
estimated" semantics is not what the code does (it always writes, defaulting to 5 for
non-joy). Pre-existing (unchanged this phase), flagged for completeness.
**Fix:** Guard on the join (`if (_parseResult != null)`) or on a real "estimated" sentinel if
the default-vs-estimated distinction matters; otherwise the guard is misleading and should be
simplified.

---

_Reviewed: 2026-06-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
