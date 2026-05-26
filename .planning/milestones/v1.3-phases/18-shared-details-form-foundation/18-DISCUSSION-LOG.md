# Phase 18: Shared Details Form Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 18-Shared Details Form Foundation
**Areas discussed:** Widget shape + routing location, Mode + seed contract, OCR architectural slot

---

## Area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Widget shape + routing location | Embeddable widget vs full-route widget; naming/path; old TransactionConfirmScreen disposition. | ✓ |
| Mode + seed contract | How `(mode: new/edit, seed: Transaction?)` is expressed; defaults; field mutability on edit; voice-keyword placement. | ✓ |
| Update use case + sync | UpdateTransactionUseCase shape, hash-chain stance, trackUpdate, immutable fields, soul-celebration on edit, delete affordance. | (skipped — captured under Claude's discretion / D-19/D-20) |
| OCR architectural slot shape | Two-step container shape; step1→step2 data contract type name; TODO-marker test form. | ✓ |

**Notes:** User skipped the Update use case + sync area; standard decisions captured in CONTEXT.md `<decisions>` under Claude's discretion (D-19, D-20) — hash chain frozen on edit, `updatedAt` stamped, `trackUpdate` added to change tracker, no delete button, soul celebration only on `.new`, no dirty-state cancel dialog.

---

## Area 1: Widget shape + routing location

### Q1.1 Widget shape

| Option | Description | Selected |
|--------|-------------|----------|
| Embeddable widget | TransactionDetailsForm is a sub-component — no Scaffold/AppBar/save CTA; host owns chrome. Phase 19/22 can render keypad + form + bottom CTA on one screen. | ✓ |
| Full Route widget | TransactionDetailsForm self-contained with Scaffold/AppBar/save CTA; only usable at Route level. Phase 19/22 would need a re-extraction. | |
| Optional Scaffold (hybrid) | `includeScaffold`/`showSaveButton` bool parameters; switches internally. API surface bloats; mainstream considered anti-pattern. | |

**User's choice:** Embeddable Widget.
**Rationale:** Phase 19 (manual one-step) and Phase 22 (voice one-step) both need to render the form inline alongside another input affordance on a single screen with one bottom CTA — the embeddable shape is the only choice that doesn't force a re-extraction in those phases.

### Q1.2 Save CTA ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Form is fields-only; host owns save CTA via GlobalKey<TransactionDetailsFormState>.submit() | Standard Flutter form pattern (FormState.validate() analog). Host controls CTA style/placement. | ✓ |
| Form exposes onSave callback + isFormValid getter; host fires it | Form is API-neutral but needs a separate onChanged broadcast for CTA enable/disable. | |
| Form contains its own Save CTA | Phase 19 would have duplicate CTAs (one in keypad area, one in form). | |

**User's choice:** Form fields-only; host owns CTA.
**Rationale:** Phase 19/22 need a unified bottom CTA across multiple input affordances; form-internal CTA would duplicate.

### Q1.3 File location

| Option | Description | Selected |
|--------|-------------|----------|
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | Co-located with existing widget siblings (detail_info_card, amount_display, ledger_type_selector). | ✓ |
| `lib/features/accounting/presentation/forms/transaction_details_form.dart` | New `forms/` subdirectory; not yet a project category. | |
| `lib/features/accounting/presentation/screens/transaction_details_form.dart` | Violates Thin Feature convention — `screens/` is for routes. | |

**User's choice:** `widgets/transaction_details_form.dart`.

### Q1.4 Existing TransactionConfirmScreen (743 lines)

| Option | Description | Selected |
|--------|-------------|----------|
| Refactor in place: extract form logic to TransactionDetailsForm widget; TransactionConfirmScreen becomes a thin "new mode" route wrapper. Existing push sites unchanged. | Minimal blast radius. Phase 19/22 will eventually retire the route. | ✓ |
| Deprecate TransactionConfirmScreen file in Phase 18 | Existing push sites must change; surface that Phase 19/22 will handle. | |
| Refactor internals but no widget extraction | Violates SC-1 ("single TransactionDetailsForm widget"). | |

**User's choice:** Refactor in place; route name unchanged.

**Area 1 outcome:** Embeddable widget at `widgets/transaction_details_form.dart`; host screens (refactored `TransactionConfirmScreen`, new `TransactionEditScreen`, new `OcrReviewScreen`) own Scaffold + AppBar + save CTA; host submits via `GlobalKey<TransactionDetailsFormState>().submit()`.

---

## Area 2: Mode + seed contract

### Q2.1 How to express (mode, seed)

| Option | Description | Selected |
|--------|-------------|----------|
| Freezed sealed union `TransactionDetailsFormConfig.new(...)` / `.edit(seed)` | Type-safe; `.edit` cannot accept `entrySource`; `.new` cannot accept seed. Aligns with existing `TimeWindow` pattern. | ✓ |
| Enum mode + nullable seed + nullable initial values | Runtime assertions only; mode/seed combinations not enforced by compiler. | |
| Two widget named constructors (.forNew / .forEdit) | Cannot pass config object as first-class value; OcrReviewScreen needs to prepare config before construction. | |

**User's choice:** Freezed sealed union.

### Q2.2 `.new` mode default values

| Option | Description | Selected |
|--------|-------------|----------|
| Widget does not default category; caller passes initialCategory/initialParentCategory (both nullable) | Keeps widget pure (no IO at mount, no categoryRepositoryProvider coupling). Each caller resolves a sensible default. | ✓ |
| Widget internally pulls default category from repo | Widget gains IO dependency; tests harder; Phase 19 default-category decision duplicated. | |
| `.new` requires all initial values; only `.edit` has seed | Voice partial-parse / OCR partial-populate scenarios become unwieldy (must express "I don't know satisfaction" as nullable anyway). | |

**User's choice:** Caller supplies initialCategory.
**Rationale:** Form widget purity preserved; existing `_initializeDefaultCategory()` logic stays in transaction_entry_screen and migrates analogous logic into future Phase 19/22 hosts.

### Q2.3 Edit-mode field mutability

| Option | Description | Selected |
|--------|-------------|----------|
| Mutable: amount, categoryId, merchant, note, timestamp, ledgerType, soulSatisfaction. Preserved: id, bookId, deviceId, prevHash, currentHash, createdAt, entrySource. | 7+7 split aligns with hash-chain protection scope (creation event) and SC-3 (`entry_source` preserved). | ✓ |
| Stricter: also lock amount + timestamp (they're in the hash) | "I typed the wrong amount" requires delete + recreate — bad UX. | |
| All fields mutable (matches current `repo.update` behavior) | Would let `entrySource` flip on edit — violates SC-3. | |

**User's choice:** 7-mutable + 7-preserved.

### Q2.4 Voice-correction logic placement

| Option | Description | Selected |
|--------|-------------|----------|
| `.new` config gets `voiceKeyword: String?`; form widget contains the category-onChange correction call (verbatim port from TransactionConfirmScreen) | Form widget owns the voice-learning hook in `.new` mode; `.edit` mode never reaches that branch. | ✓ |
| Form exposes onCategoryChanged callback; voice_input_screen hosts the learning call externally | Adds an extra callback parameter; logic split across widget + screen. | |
| Move learning call to save-time, not category-change-time | Behavior shift from "select-and-record" to "save-and-record"; misses corrections that revert to original. | |

**User's choice:** voiceKeyword on `.new` config; form widget runs the learning call.

**Area 2 outcome:** `TransactionDetailsFormConfig` Freezed sealed union (`.new` / `.edit`); caller supplies initial category (no widget-internal default); edit-mode mutable = 7 fields, preserved = 7 fields; voice-keyword + category-correction logic ports verbatim into form widget's `.new` branch.

---

## Area 3: OCR architectural slot

### Q3.1 Two-step container shape

| Option | Description | Selected |
|--------|-------------|----------|
| Existing OcrScannerScreen unchanged (step 1) + new OcrReviewScreen (step 2) | Clear route-stack semantics; back from step 2 returns to step 1. MOD-005 changes step 1, step 2 untouched. | ✓ |
| Single screen with internal PageView/IndexedStack | Bloated screen; back-button semantics conflate "step back" vs "exit OCR flow." | |
| No new screen — just OcrParseDraft model + architecture test | Doesn't satisfy SC-4's "two-step container" wording. | |

**User's choice:** Two separate screen files.

### Q3.2 Step 1 → step 2 data contract

| Option | Description | Selected |
|--------|-------------|----------|
| `OcrParseDraft` (Freezed, symmetric to VoiceParseResult), entrySource stamps `EntrySource.ocr` (deviates from Phase 17 D-07) | First use of `ocr` enum value; conflicts with Phase 17 D-07. | |
| `OcrParseDraft` (Freezed) + entrySource still stamps `EntrySource.manual` (honors Phase 17 D-07) | Phase 17 D-07 preserved; MOD-005's first commit flips this single line. | ✓ |
| Map<String, dynamic> instead of typed model | Type-unsafe; violates project Freezed convention. | |

**User's choice:** Freezed OcrParseDraft; stamp manual (honor Phase 17 D-07).

### Q3.3 OcrScannerScreen wire-up

| Option | Description | Selected |
|--------|-------------|----------|
| Shutter pushes OcrReviewScreen with `OcrParseDraft.empty()` + i18n banner | Real route push; banner explains OCR is not implemented; user fills manually. | ✓ |
| Shutter pushes OcrReviewScreen with `OcrParseDraft.mock()` (fake data) | Looks like real OCR; would mislead validators and demo audiences. | |
| Add a "Skip review" button; shutter still pops | Confusing UX (why is there a Skip button on a camera?). | |

**User's choice:** Push with empty draft + i18n banner.

### Q3.4 TODO-marker seam test

| Option | Description | Selected |
|--------|-------------|----------|
| Widget test: tap shutter → asserts OcrReviewScreen routed AND `find.byType(TransactionDetailsForm).single` | Behavioral validation of SC-4 ("step 2 mounts the same shared widget"). | ✓ |
| Architecture/import test only: file exists + import present | Validates files, not behavior — could pass while widget never builds. | |
| Both widget + architecture import tests | Defensible but redundant given existing arch test suite. | |

**User's choice:** Widget test.

**Area 3 outcome:** New OcrReviewScreen (step 2); new OcrParseDraft Freezed model; OCR-saved rows still stamp `EntrySource.manual` (Phase 17 D-07 preserved); shutter pushes review with empty draft + i18n banner; widget seam test validates step 2 mounts the shared form.

---

## Claude's Discretion

The user skipped "Update use case + sync" gray area; standard decisions captured in CONTEXT.md `<decisions>`:

- **D-08:** Hash chain frozen on edit (`currentHash`/`prevHash` unchanged) — generalizes Phase 17 D-02 stance.
- **D-15:** Soul celebration plays only on `.new` saves; survival→soul edit does NOT replay celebration (ADR-012 anti-gamification).
- **D-16:** No dirty-state confirmation dialog on cancel; silently discards local edits.
- **D-17:** No delete affordance on edit screen; future UX story.
- **D-18:** Edit screen post-save uses `Navigator.pop(context, true)` (not `popUntil`).
- **D-19:** `UpdateTransactionUseCase.execute(params) -> Future<Result<Transaction>>` — mirrors create.
- **D-20:** `TransactionChangeTracker.trackUpdate` mirrors `trackCreate`; consumes `TransactionSyncMapper.toUpdateOperation(...)`.

Smaller open choices left for planner:
- Exact `OcrParseDraft` factory shape (single ctor with all-nullable fields vs explicit `.empty()` factory — D-11).
- Inline `// MOD-005: flip to EntrySource.ocr when OCR writer ships` comment placement (D-12) — planner discretion.
- Banner UI style in OcrReviewScreen (MaterialBanner vs in-form-card; D-13) — planner discretion within i18n + light/dark constraints.
- Whether to short-circuit save when no field changed in `.edit` mode (D-07 last paragraph) — Phase 18 does not require it.

## Deferred Ideas

See CONTEXT.md `<deferred>` section. Highlights:
- MOD-005 OCR writer (v1.4+): wires real capture; flips OCR review's entrySource literal from `.manual` to `.ocr`.
- Delete-from-row UX (v1.4+): `DeleteTransactionUseCase` already exists; one-line wire-up future story.
- Dirty-state confirmation dialog on cancel (v1.4+ polish).
- Long-press / swipe-to-delete on home recent-tx tile (v1.4+).
- Edit-history audit log (future, contingent on family-sync conflict-resolution needs).
- Hash chain re-derivation on edit (explicitly rejected; would require ADR amendment).
