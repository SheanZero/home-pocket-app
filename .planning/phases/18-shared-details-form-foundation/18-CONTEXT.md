# Phase 18: Shared Details Form Foundation - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 18 consolidates the transaction-details surface into one shared Freezed-backed widget (`TransactionDetailsForm`) that is reused by manual entry, voice entry, the OCR two-step container, and the new edit-existing path. It introduces `UpdateTransactionUseCase` (matching the existing `CreateTransactionUseCase`), wires `TransactionChangeTracker.trackUpdate` to the family-sync push lane, lights up `HomeTransactionTile.onTap` so a tap on any home recent-tx row opens the form pre-populated in edit mode, and reserves the OCR architectural slot by adding an `OcrReviewScreen` route that step-2-mounts the same shared widget (no OCR writer; `OcrParseDraft.empty()` is the placeholder data contract).

**In scope:**

- **New widget — `TransactionDetailsForm`** (`lib/features/accounting/presentation/widgets/transaction_details_form.dart`):
  - Embeddable `StatefulWidget` (no Scaffold, no AppBar, no save CTA — host owns chrome).
  - Renders the existing fields: amount (tap-to-edit via existing `SmartKeyboard` bottom sheet), category (tap-to-edit via `CategorySelectionScreen`), date (date picker), merchant (`TextField`), note (`TextField`), ledger type toggle (`LedgerTypeSelector`), soul satisfaction picker (`SatisfactionEmojiPicker`, only when `ledgerType == LedgerType.soul`).
  - Configured by a Freezed sealed union `TransactionDetailsFormConfig` (one of `.new(...)` / `.edit(seed)`).
  - Submission via a public `submit()` method on a `GlobalKey<TransactionDetailsFormState>` (host CTA calls it). The form returns a `Future<TransactionDetailsFormResult>` (success/error) so the host can decide post-save navigation (snackbar + popUntil first, or pop-with-result for the edit route).
  - Voice category-correction call (current `recordCategoryCorrectionUseCaseProvider` plumbing) moves into the widget verbatim — `.new` mode reads `voiceKeyword` from the config; `.edit` mode skips that branch entirely.
  - Save flow is mode-aware: `.new` → `CreateTransactionUseCase.execute(...)`; `.edit` → `UpdateTransactionUseCase.execute(...)`.
  - Soul celebration overlay (`SoulCelebrationOverlay`) shows ONLY for `.new` saves of a soul transaction (today's behavior preserved). `.edit` mode never plays the celebration, even when the user edits a survival row into a soul row (D-09).

- **Freezed sealed config — `TransactionDetailsFormConfig`** (`lib/features/accounting/domain/models/transaction_details_form_config.dart`):
  - `.new({required String bookId, int? initialAmount, Category? initialCategory, Category? initialParentCategory, String? initialMerchant, int? initialSatisfaction, DateTime? initialDate, required EntrySource entrySource, String? voiceKeyword})` — initial values from caller; widget never reaches into a repo to default values.
  - `.edit({required Transaction seed})` — full transaction is the seed. All editable fields preload from `seed.*`. The `voiceKeyword`/voice-correction branch is unreachable in edit mode.
  - Pattern-matched via `config.when(...)` / `config.maybeWhen(...)` inside the widget.

- **New application use case — `UpdateTransactionUseCase`** (`lib/application/accounting/update_transaction_use_case.dart`):
  - Mirrors `CreateTransactionUseCase` shape (params class + `execute(params) -> Future<Result<Transaction>>`).
  - Hash chain stance: `currentHash`/`prevHash` are NOT recomputed. They stay as the original create-time snapshot — analogous to Phase 17 D-02 (`entry_source` does not enter the hash chain). The hash chain protects the *creation* event, not subsequent edits.
  - `updatedAt` is stamped to `DateTime.now()` inside the use case.
  - `entrySource` is read from `seed.entrySource` and re-saved verbatim — never flips to `manual` on edit (SC-3).
  - `createdAt`, `id`, `bookId`, `deviceId` are read from the seed and re-saved verbatim. They MUST NOT change.
  - Editable fields: `amount`, `categoryId`, `merchant`, `note`, `timestamp`, `ledgerType`, `soulSatisfaction` (D-07).
  - On success: `_changeTracker?.trackUpdate(TransactionSyncMapper.toUpdateOperation(...))` then `_syncEngine?.onTransactionChanged()`. (Phase 18 adds `trackUpdate` to `TransactionChangeTracker` — `toUpdateOperation` already exists in the sync mapper.)

- **`TransactionChangeTracker` extension** (`lib/application/family_sync/transaction_change_tracker.dart`):
  - Add `void trackUpdate(Map<String, dynamic> operation)` — same shape as `trackCreate`. The receiving end of sync already handles `op: 'update'` (it consumes `toUpdateOperation` output).

- **`TransactionConfirmScreen` refactor** (`lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`):
  - Stays at the same file path with the same class name (so `transaction_entry_screen.dart:225` and `voice_input_screen.dart:352` push sites remain unchanged).
  - Internals slimmed: the screen becomes a thin Scaffold + AppBar + bottom save CTA wrapper that hosts a `TransactionDetailsForm` configured as `.new(...)`. All field-editing logic moves into the form widget.
  - Constructor signature: existing parameters stay the same shape; internally they are funneled into `TransactionDetailsFormConfig.new(...)` and passed to the form widget.
  - Post-save behavior: `Navigator.of(context).popUntil((r) => r.isFirst)` preserved (returns user to main shell after a `.new` save) — today's UX is intentional.

- **New screen — `TransactionEditScreen`** (`lib/features/accounting/presentation/screens/transaction_edit_screen.dart`):
  - Thin Scaffold + AppBar + bottom save CTA wrapper for the `.edit` path, mirroring `TransactionConfirmScreen` but configured as `TransactionDetailsFormConfig.edit(seed: transaction)`.
  - Post-save behavior: `Navigator.pop(context, true)` (returns to the home list, which auto-refreshes via existing transaction stream / provider invalidation).
  - Cancel button (AppBar leading or "Back" text) calls `Navigator.pop(context)` — **no dirty-state confirmation dialog** in Phase 18 (D-10). Tap → form → cancel discards local edits silently.
  - The screen has NO delete button in Phase 18 (D-11) — delete from the row is a separate UX story for a future phase.

- **Home recent-tx tap-to-edit wiring** (`lib/features/home/presentation/screens/home_screen.dart`):
  - The existing `HomeTransactionTile.onTap` parameter is plumbed but currently unused at the call site (home_screen.dart:293–327). Phase 18 wires `onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionEditScreen(transaction: tx)))`.
  - No new providers; no new repositories. The tile already receives the full `Transaction` object in the `transactions.map((tx) => ...)` block.

- **OCR architectural slot — new screen `OcrReviewScreen`** (`lib/features/accounting/presentation/screens/ocr_review_screen.dart`):
  - Thin Scaffold + AppBar + bottom save CTA wrapper, mirrors `TransactionConfirmScreen` shape.
  - Constructor: `OcrReviewScreen({required String bookId, required OcrParseDraft draft})`.
  - Internals: turns the draft into `TransactionDetailsFormConfig.new(bookId: bookId, initialAmount: draft.amount, initialMerchant: draft.merchant, initialDate: draft.date, entrySource: EntrySource.manual)` and passes it to the shared form.
  - **`entrySource` is `EntrySource.manual`** for Phase 18, not `EntrySource.ocr`. This honors Phase 17 D-07: MOD-005's first commit will flip this single line to `EntrySource.ocr` when the real OCR writer ships. The literal `'ocr'` value remains type-system-reserved with no live row.
  - Banner: a localized `Banner`/`MaterialBanner` or top-of-form info card displays a copy like "OCR reader is not implemented yet — fields are empty, please input manually" — gated by `draft.isEmpty` (draft has no parsed fields). Three new ARB keys (ja/zh/en parity).

- **OCR step-1 → step-2 wire-up** (`lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`):
  - Shutter `GestureDetector` `onTap` changes from `Navigator.pop(context)` to `Navigator.of(context).push(MaterialPageRoute(builder: (_) => OcrReviewScreen(bookId: bookId, draft: const OcrParseDraft.empty())))`.
  - Camera/gallery/flash UI unchanged. Status-pill copy can stay.

- **New domain model — `OcrParseDraft`** (`lib/features/accounting/domain/models/ocr_parse_draft.dart`):
  - `@freezed class OcrParseDraft with _$OcrParseDraft { const factory OcrParseDraft({ int? amount, String? merchant, DateTime? date, String? rawOcrText, String? imagePath }) = _OcrParseDraft; const factory OcrParseDraft.empty() = _Empty; }` — or a simpler single-constructor + `isEmpty` getter (planner discretion). MOD-005 extends with future fields (category guess, line items, etc.) without breaking Phase 18 wire-up.
  - Symmetrical with the existing `VoiceParseResult` Freezed model — same shape register so downstream agents can reuse mental model.

- **Edit entry-point validation**:
  - Home tap path verified end-to-end by a widget test that pumps home_screen with a seeded transaction, taps the tile, and asserts the form is mounted with the seed values present in fields.

- **Tests**:
  - Widget test: `tap shutter → OcrReviewScreen routes; finds.byType(TransactionDetailsForm) is single` (D-13). File: `test/widget/features/accounting/presentation/screens/ocr_two_step_seam_test.dart`.
  - Widget test: home recent-tx tap → `TransactionEditScreen` mounts with seeded fields visible.
  - DAO/integration test: edit path exercises all three `EntrySource` literals (`manual`, `voice`, `ocr`) — assert `entry_source` is preserved verbatim after `UpdateTransactionUseCase.execute(...)` round-trip (SC-3).
  - Use-case unit test: `UpdateTransactionUseCase` — happy path, hash chain preservation (current/prev unchanged across edit), `updatedAt` stamped, `entrySource` preserved, immutable fields rejected (or just verified untouched).
  - Atomicity test: `update` is a single Drift transaction (no partial writes verified by an integration test that runs concurrent updates or asserts no partial state on failure injection). The existing `TransactionDao.updateTransaction` already takes a single statement; verify it stays that way.
  - Form widget unit/widget tests: `.new` and `.edit` modes both render correctly with their respective configs; ledger type changes drive satisfaction-picker visibility; voice-keyword correction fires only in `.new` mode.

- **i18n**: ARB additions across `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` (parity enforced by `test/architecture/arb_key_parity_test.dart`):
  - `transactionEditTitle` — AppBar title for `TransactionEditScreen` (e.g., 「明细编辑」/「明細編集」/「Edit Entry」).
  - `ocrReviewTitle` — AppBar title for `OcrReviewScreen`.
  - `ocrReviewEmptyDraftBanner` — explanatory banner when draft is empty.
  - `transactionUpdated` — snackbar after successful edit save (sibling to existing `transactionSaved`).
  - `failedToUpdate` — error snackbar.
  - All UI text via `S.of(context)` per project rule.

**Out of scope:**

- **No Drift schema migration** (SC-5). Current v17 (with `entry_source`) is sufficient. The Phase 19/20/21/22 plans also assume no schema bump.
- **No OCR writer implementation** (MOD-005). Only the architectural slot is reserved. `OcrParseDraft` ships with no producer; `OcrParseDraft.empty()` is the only construction path Phase 18 exercises.
- **No `EntrySource.ocr` live rows** — OCR review save path still stamps `EntrySource.manual`, per Phase 17 D-07. The `'ocr'` enum value remains type-reserved.
- **No delete button on the edit screen** (D-11). Delete-from-row UX is a future story.
- **No dirty-state confirmation dialog on cancel** (D-10). Cancel silently discards local edits in Phase 18.
- **No long-press / swipe-to-delete on home recent-tx tile** — Phase 18 only wires the existing `onTap` plumbing. Long-press / contextual actions are out of scope.
- **No Manual one-step screen collapse** — that is Phase 19 and consumes this form widget. `TransactionConfirmScreen` stays a separate route for Phase 18.
- **No voice one-step integration** — that is Phase 22. `VoiceInputScreen`'s push to `TransactionConfirmScreen` is unchanged in Phase 18.
- **No HomeHero ring/provider impact** (ADR-016 §3). The home-screen wiring touches only the recent-tx list, never `HomeHeroCard` or `homeHero*Provider`s.
- **No new gamification surfaces** (ADR-012). The edit flow does not add streaks, achievements, or progress UI.
- **No edit-history audit log** (e.g., "this row was edited 3 times"). `updatedAt` is updated; no separate audit table.
- **No reopen of the hash chain question** — current/prev hash stay frozen on edit (D-08). Re-deriving the chain on edits would invalidate every existing tip and is explicitly rejected.
- **No survival-ledger satisfaction picker** — ADR-014 boundary, untouched.
- **No persistence of edit-screen state across app restart** — standard `StatefulWidget` semantics; if the user backgrounds the app mid-edit, restart returns them to home with no recovery.
- **No undo-after-save** — Phase 18 does not implement an undo affordance; once save commits, the change is final until a subsequent edit.

</domain>

<decisions>
## Implementation Decisions

### Widget shape, file location, and host responsibility (Area 1)

- **D-01: `TransactionDetailsForm` is an embeddable `StatefulWidget` — NO Scaffold, NO AppBar, NO save CTA inside the widget.** Host screens (`TransactionConfirmScreen`, `TransactionEditScreen`, `OcrReviewScreen`, plus future Phase 19 manual one-step screen and Phase 22 voice one-step screen) own the chrome and the save button.
  - **Why:** Phase 19 and Phase 22 both need to render the form *inline* on a single screen alongside another input affordance (keypad / record button) and share a single bottom CTA across the whole screen. A self-contained form widget with its own Scaffold/CTA would force Phase 19/22 to re-extract the inner body, defeating SC-1. The "host owns chrome" pattern is the standard Flutter form composition.
  - **Drawback:** every host screen has to declare its own Scaffold + AppBar + bottom CTA — three small thin wrappers exist (the original confirm-screen, the new edit-screen, the new OCR-review-screen). Accepted: those wrappers are <50 lines each and the form widget is the single source of truth.

- **D-02: The host CTA invokes the form via `GlobalKey<TransactionDetailsFormState>().currentState!.submit()`.** The form's `submit()` returns `Future<TransactionDetailsFormResult>` where `TransactionDetailsFormResult` is a small sealed union: `.success(Transaction)` / `.validationError(String message)` / `.persistError(String message)`.
  - **Why:** Standard Flutter pattern (`FormState.validate()`/`save()` analog). The host gets a return value and decides post-save navigation (popUntil-first vs pop-with-result) without a second callback round-trip.
  - **Alternative considered:** `onSave: VoidCallback` + `isFormValid: bool` getter — rejected because the host would need a separate `onChanged` broadcast to react to validity changes for CTA enable/disable. The `GlobalKey + submit()` pattern keeps the form's internal validation private and exposes a clean public surface.

- **D-03: File location is `lib/features/accounting/presentation/widgets/transaction_details_form.dart`.** Co-located with the existing widget siblings (`detail_info_card.dart`, `amount_display.dart`, `ledger_type_selector.dart`, `smart_keyboard.dart`). The Thin Feature rule places UI components in `widgets/`, not `screens/` (which is reserved for Route-level Scaffolds).
  - The companion screen wrappers go in `screens/`: `transaction_confirm_screen.dart` (existing, refactored), `transaction_edit_screen.dart` (new), `ocr_review_screen.dart` (new).

- **D-04: `TransactionConfirmScreen` keeps its file path and class name; internally it refactors to a thin route wrapper for `.new` mode.** All existing push sites (`transaction_entry_screen.dart:225`, `voice_input_screen.dart:352`) require ZERO changes in Phase 18. The screen's public constructor signature stays the same. Internally, the constructor parameters fold into a `TransactionDetailsFormConfig.new(...)` instance handed to the embedded `TransactionDetailsForm`.
  - **Why:** Phase 18's blast radius stays small. Phase 19 / 22 will eventually retire the `TransactionConfirmScreen` route when manual / voice flows collapse to one screen — that retirement belongs to those phases. Forcing all call sites to change in Phase 18 inflates the diff and risks introducing regressions for surface-area we are not yet collapsing.

### Mode + seed contract (Area 2)

- **D-05: `TransactionDetailsFormConfig` is a Freezed sealed union (`.new(...)` / `.edit(seed)`).** Located at `lib/features/accounting/domain/models/transaction_details_form_config.dart`.
  - **Why:** Type-safety. `.edit(seed)` cannot accidentally accept `entrySource` (it must come from the seed); `.new(...)` cannot accept a seeded `Transaction` (it has no row yet). Pattern-matching via `config.when(...)` makes the mode branching explicit at every form callsite. Aligns with the existing Freezed sealed pattern in `TimeWindow` (`.week / .month / .quarter / .year / .custom`).
  - **Alternative considered:** Enum mode + nullable seed + lots of nullable initial values — rejected because runtime assertions ("`.editEntry` must have a seed; `.newEntry` must NOT have a seed") were the only enforcement, and the construction site readability is worse.
  - **Alternative considered:** Two named constructors on the widget itself (`TransactionDetailsForm.forNew(...)` / `TransactionDetailsForm.forEdit(...)`) — rejected because the `OcrReviewScreen` (and any future indirect call site) sometimes needs to prepare and pass around a `config` object before construction; you cannot pass a constructor invocation as a first-class value.

- **D-06: `.new` mode does NOT default `category`/`parentCategory` inside the widget. The caller passes `initialCategory`/`initialParentCategory` (both nullable).**
  - **Why:** Keeps the form widget pure (no IO at mount, no `categoryRepositoryProvider` dependency). Each caller already has the right context to resolve a sensible default: `transaction_entry_screen.dart` resolves L1[0] + L2[0] via `_initializeDefaultCategory()`; `voice_input_screen.dart` resolves the parsed category; `ocr_review_screen.dart` passes `null` (empty draft); a future Phase 19 manual one-step screen will inherit the same `_initializeDefaultCategory` pattern.
  - **Resulting widget state default:** if `initialCategory` is `null`, the form renders the category row in its "please select" state (mirrors today's `TransactionConfirmScreen` behavior when `widget.category` is `null`).

- **D-07: Edit-mode mutable fields and immutable fields.**
  - **Mutable** (UI exposes editing affordances): `amount`, `categoryId`, `merchant`, `note`, `timestamp`, `ledgerType`, `soulSatisfaction`. These are the seven fields the user can change via the form.
  - **Immutable** (use case re-saves verbatim from seed): `id`, `bookId`, `deviceId`, `prevHash`, `currentHash`, `createdAt`, `entrySource`. These are identity, hash-chain anchor, origin, and audit-source — none of them are user-editable concepts.
  - **`updatedAt`** is stamped to `DateTime.now()` inside `UpdateTransactionUseCase.execute()` regardless of which mutable fields changed (even if the user edits nothing and re-taps save — though that's a degenerate case; widget can short-circuit if no field changed but Phase 18 does not require it).

- **D-08: Hash chain is NOT recomputed on edit; `currentHash` and `prevHash` stay frozen at the create-time values.**
  - **Why:** The hash chain protects the *creation event* — it gives tamper evidence for "this transaction was created in this order with this amount at this time". Edits are subsequent metadata; re-deriving on edit would invalidate every downstream tip and require an ADR-level migration. Phase 17 D-02 already accepted this stance for `entry_source` ("entry_source does NOT enter the hash chain ... `soulSatisfaction` is also not hash-protected"). Phase 18 generalizes the same rationale to mutable fields. Audit lens: edits are observable via `updatedAt`; tamper resistance is for creates.
  - **Trade-off:** A user who edits an amount can rewrite recorded history without a hash mismatch surfacing. Accepted — this app is single-user-per-device, local-first, and the threat model is honest-mistake recovery, not malicious tampering by the device owner.

- **D-09: `voiceKeyword` lives on `.new` only; voice-correction logic stays inside the form widget.**
  - **`.new` config:** `String? voiceKeyword` optional named field — passed by `voice_input_screen.dart` (via the refactored `TransactionConfirmScreen` wrapper) when the user came through a voice transcript.
  - **Form behavior:** in `.new` mode, on category onChange, `if (voiceKeyword != null && newId != initialCategoryId) await recordCategoryCorrectionUseCase.execute(keyword: voiceKeyword, correctedCategoryId: newId)`. Verbatim port from `TransactionConfirmScreen._editCategory()`.
  - **`.edit` mode:** the voice-correction branch is unreachable. `TransactionDetailsFormConfig.edit(seed)` has no `voiceKeyword`. Edits to category on a previously-saved voice row are NOT treated as a learning signal (the user is no longer in the recall moment).

### OCR architectural slot (Area 3)

- **D-10: Two-step container is two separate screen files, not a single PageView-based screen.** `OcrScannerScreen` (existing, mildly extended) is step 1; `OcrReviewScreen` (new) is step 2.
  - **Why:** Clear route-stack semantics — back from step 2 returns to step 1 (camera UI), back from step 1 returns to the prior screen. PageView/IndexedStack would either force a manual interception of system back or require a sealed "where am I" enum inside one bloated screen. Two routes is also cheaper to reason about for the MOD-005 author: they replace `OcrScannerScreen` (with real camera + parse) and pass a populated `OcrParseDraft` forward; `OcrReviewScreen` stays untouched.

- **D-11: Data contract step 1 → step 2 is a Freezed `OcrParseDraft` model in `lib/features/accounting/domain/models/ocr_parse_draft.dart`.**
  - Shape: nullable `amount: int?`, `merchant: String?`, `date: DateTime?`, `rawOcrText: String?`, `imagePath: String?`. Plus a `const factory OcrParseDraft.empty()` (or const `OcrParseDraft()` if Freezed default-null-fields suffices — planner discretion).
  - Symmetric with `VoiceParseResult` so downstream agents can use the same mental model.
  - MOD-005 extends the model with future fields (category guesses, line items, currency code, etc.) when needed — Freezed sealed/extensible enough for that without breaking Phase 18 wire-up.

- **D-12: OCR-saved rows in Phase 18 stamp `EntrySource.manual`, NOT `EntrySource.ocr`.** Honors Phase 17 D-07: the literal `'ocr'` enum value remains type-system-reserved with no live row in v1.3. MOD-005's first commit will flip `OcrReviewScreen`'s `entrySource:` argument from `.manual` to `.ocr`.
  - **Operational note for downstream agents:** when reviewing the diff, the line `entrySource: EntrySource.manual` inside `OcrReviewScreen.build` SHOULD have an inline `// MOD-005: flip to EntrySource.ocr when OCR writer ships` comment so the future delta is discoverable via grep.

- **D-13: Step 1 → step 2 wire-up is implemented in Phase 18.** `OcrScannerScreen`'s shutter `GestureDetector.onTap` changes from `Navigator.pop(context)` to push `OcrReviewScreen(bookId: bookId, draft: const OcrParseDraft.empty())`. An i18n banner inside `OcrReviewScreen` informs the user that OCR is not implemented yet and fields need manual input. This makes SC-4's "architectural slot reserved" demonstrable, not just structural.

- **D-14: TODO-marker test is a widget test, not just an architecture import test.** File: `test/widget/features/accounting/presentation/screens/ocr_two_step_seam_test.dart`. Pumps `OcrScannerScreen`, taps the shutter, settles, then asserts (a) the route stack contains `OcrReviewScreen`, AND (b) `find.byType(TransactionDetailsForm)` finds exactly one. This validates SC-4 at the behavioral level — step 2 actually mounts the shared widget, not just imports it.

### Implementation choices that flow from the discussion (Claude's discretion within these decisions)

- **D-15: Soul celebration plays ONLY on `.new` saves.** In `.edit` mode, even if the user changes `ledgerType` from `survival` to `soul` and saves, the celebration overlay does NOT trigger. Celebration is for the *moment of recording* a soul moment, not for retroactively recategorizing. (Aligns with ADR-012 anti-gamification posture — celebrations are not behavioral nudges to be earned twice.)

- **D-16: No dirty-state confirmation dialog on cancel.** In Phase 18, cancelling the edit screen with unsaved changes silently discards them. Adding an `AreYouSure?` dialog is a future UX polish, but its omission keeps the cancel path trivial and avoids modal-on-modal during a stage where users primarily use edit to fix a single typo.

- **D-17: No delete affordance on the edit screen.** SC-EDIT-01/02 explicitly scope the path as edit-and-save; delete-from-row is a separate UX decision that the v1.3 milestone does not commit to. `DeleteTransactionUseCase` already exists; wiring it up is one line of Phase X work.

- **D-18: Edit screen post-save uses `Navigator.pop(context, true)` (not `popUntil((r) => r.isFirst)`).** Returning a result lets the home screen invalidate its provider if needed; today the home recent-tx provider already streams from the DB and will pick up the change without an explicit invalidate, but the pop-with-result semantics keeps that integration future-proof.

- **D-19: `UpdateTransactionUseCase` returns `Future<Result<Transaction>>` (matches create).** The form widget's `submit()` decision is informed by the use case's `Result.isSuccess` / `.error` fields.

- **D-20: `TransactionChangeTracker.trackUpdate` mirrors `trackCreate` shape.** No new state in the tracker — it accepts a `Map<String, dynamic> operation` already shaped by `TransactionSyncMapper.toUpdateOperation(...)`. The receiving sync engine already accepts `op: 'update'` payloads (the mapper would not have a `toUpdateOperation` factory otherwise).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — v1.3 milestone goal; Phase 18 listed as the foundation for INPUT-03/04 + EDIT-01/02; MOD-005 OCR writer explicitly deferred out of v1.3.
- `.planning/REQUIREMENTS.md` — v1.3 requirements list; INPUT-03/04/EDIT-01/02 mapped to Phase 18; cross-cutting constraints (i18n parity, quality gates, Thin Feature, immutability, ADR-012/016 boundaries, no schema migration, pubspec pins).
- `.planning/ROADMAP.md` §"Phase 18: Shared Details Form Foundation" — five Success Criteria for Phase 18.
- `.planning/STATE.md` — v1.3 phase map; phase 18 dependencies (none — foundation phase).

### Prior phase hand-off
- `.planning/milestones/v1.2-phases/17-manual-only-joy-sub-metric-happy-v2-03/17-CONTEXT.md` — `entry_source` semantics, `CreateTransactionParams.entrySource` required-no-default contract (D-06), hash-chain exclusion rationale (D-02), `EntrySource.ocr` reserved-but-unused (D-07), `TransactionSyncMapper.toCreateOperation` sync semantics. Phase 18 inherits the `entrySource` contract and extends it to the edit path (preservation in `UpdateTransactionUseCase`).
- `.planning/milestones/v1.2-phases/15-custom-time-windows-happy-v2-02/15-CONTEXT.md` — Freezed sealed union pattern (`TimeWindow.week / .month / ...`) is the template Phase 18 follows for `TransactionDetailsFormConfig.new / .edit`.

### Architecture / ADRs
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Thin Feature rule: features hold only `domain/` (models + repo interfaces) + `presentation/` (screens/widgets/providers). `TransactionDetailsForm` (widget) and `TransactionDetailsFormConfig` (domain model) go in their respective slots; `UpdateTransactionUseCase` lives in `lib/application/accounting/`.
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` — Drift schema (v17) is sufficient; no migration. `transactions.entry_source` column already exists from v16→v17 (Phase 17).
- `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` — Hash chain semantics; Phase 18 explicitly does NOT recompute hash on edit (D-08), consistent with Phase 17 D-02 (`entry_source` excluded from hash) and Phase 9 implicit acceptance (`soul_satisfaction` not hash-protected).
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod 3 conventions; form widget is `StatefulWidget` (not Riverpod notifier — local form state stays in the widget). Use cases wired through `repository_providers.dart` per existing project pattern.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` §4 (no cross-period delta), §6 (no per-member breakdown) — Phase 18 adds no celebration repetition on edit (D-15).
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — `soul_satisfaction` default = 2, soul-only picker; preserved in edit mode (D-07 list).
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §3 — HomeHero isolation invariant; Phase 18 home-screen wiring touches only `home_transaction_tile.onTap`, never `HomeHeroCard` or its providers.

### Source integration points
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart:29-743` — existing details surface; refactor target. Lines 119-226 (`_editAmount` bottom-sheet keyboard), 230-268 (`_editCategory`), 272-292 (`_editDate`), 294-354 (`_save`), 383-500 (`_buildStoreAndMemoSection`), 502-552 (`_buildSaveButton`), 555-735 (`build`). Almost all of this body migrates into `TransactionDetailsForm`; only the Scaffold + AppBar + bottom save CTA stays here.
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart:224-235` — manual-entry push site; `entrySource: EntrySource.manual` already wired. Phase 18 leaves untouched.
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:351-367` — voice push site; `entrySource: EntrySource.voice` + `initialMerchant` + `initialSatisfaction` + `voiceKeyword` already wired. Phase 18 leaves untouched.
- `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart:128-145` — shutter `GestureDetector`; today `onTap: () => Navigator.pop(context)`. Phase 18 changes the onTap to push `OcrReviewScreen`.
- `lib/features/accounting/domain/models/transaction.dart` — `Transaction` Freezed model with `updatedAt` field already in place (line 36); seed for `.edit` mode.
- `lib/features/accounting/domain/models/entry_source.dart` — `EntrySource { manual, voice, ocr }` enum from Phase 17 D-01; reused verbatim.
- `lib/application/accounting/create_transaction_use_case.dart` — template for `UpdateTransactionUseCase`; shape of params class + `execute(params) -> Future<Result<Transaction>>`; hash chain calculation (lines 137-145) — `UpdateTransactionUseCase` does NOT call `_hashChainService.calculateTransactionHash` (D-08).
- `lib/application/accounting/delete_transaction_use_case.dart` — minimal use-case shape reference; `_changeTracker?.trackDelete(...)` pattern is the template for `_changeTracker?.trackUpdate(...)`.
- `lib/application/family_sync/transaction_change_tracker.dart:12-25` — extend with `void trackUpdate(Map<String, dynamic> operation)` mirroring `trackCreate`.
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart:86-106` — `TransactionSyncMapper.toUpdateOperation(...)` already exists; consumed by the new `trackUpdate`.
- `lib/features/accounting/domain/repositories/transaction_repository.dart:16` — `Future<void> update(Transaction transaction)` interface already exists.
- `lib/data/repositories/transaction_repository_impl.dart:85-116` — `update(transaction)` impl already in place; note threaded through `_encryptionService.encryptField` (note encryption preserved on edit).
- `lib/data/daos/transaction_dao.dart:117` — `updateTransaction({...})` DAO method already in place (full-row replacement; single Drift statement = atomic).
- `lib/features/home/presentation/screens/home_screen.dart:290-329` — `TransactionListCard(children: transactions.map((tx) => HomeTransactionTile(... )))` block; add `onTap: () => Navigator.push(... TransactionEditScreen(transaction: tx))`.
- `lib/features/home/presentation/widgets/home_transaction_tile.dart:55` — `final VoidCallback? onTap;` parameter already plumbed; wire it from home_screen.
- `lib/features/accounting/presentation/widgets/detail_info_card.dart` — reused as-is by the new form widget (rows: amount / category / date).
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` — reused as-is, surfaced only when `ledgerType == LedgerType.soul`.
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` — reused as-is.
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` + `lib/features/accounting/presentation/widgets/amount_display.dart` — reused inside the form's amount-edit bottom sheet.
- `lib/features/accounting/presentation/utils/category_display_utils.dart` — `formatCategoryPath(...)`, `resolveCategoryIcon(...)`, `resolveParentCategory(...)`; reused verbatim.
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` — `CategorySelectionScreen(selectedCategoryId: ...)` route push; reused verbatim by the form's category-edit affordance.
- `lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart` — reused for `.new` soul saves only (D-15).
- `lib/features/accounting/presentation/providers/repository_providers.dart` — extend with `updateTransactionUseCaseProvider` (generator wires it).
- `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb` — add five new keys (transactionEditTitle, ocrReviewTitle, ocrReviewEmptyDraftBanner, transactionUpdated, failedToUpdate). Run `flutter gen-l10n`.

### Project rules
- `CLAUDE.md` — Thin Feature rule; Riverpod 3 import boundary (`flutter_riverpod/flutter_riverpod.dart` vs `legacy.dart`); Drift TableIndex syntax (no new table — N/A); Common Pitfall #3 (code-gen after `@freezed` / `@riverpod` annotations — Phase 18 touches `@freezed` for `TransactionDetailsFormConfig` and `OcrParseDraft`, plus `@riverpod` for `updateTransactionUseCaseProvider`); Common Pitfall #4 (immutability via `copyWith` — form widget builds Transaction updates via `seed.copyWith(...)` then hands to the use case).
- `.claude/rules/arch.md` — no new ADR required for Phase 18; honors existing ADR-012 / ADR-014 / ADR-016 boundaries.
- `.claude/rules/coding-style.md` — immutability, file size targets (form widget must stay under 800; aim for 400–500 by leaving the field sub-widgets — keyboard sheet, satisfaction picker, ledger toggle — as their existing standalone files).
- `.claude/rules/testing.md` — TDD workflow; per-file coverage ≥70% on touched files; CI gate `flutter analyze` 0 issues, `dart run custom_lint --no-fatal-infos` 0 errors.
- `.claude/rules/worklog.md` — Phase 18 close requires `doc/worklog/YYYYMMDD_HHMM_*.md` entry.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`TransactionConfirmScreen`** — 743-line existing details surface; almost the entire body migrates into the new `TransactionDetailsForm` widget (only Scaffold + AppBar + bottom save CTA stay in the screen file). All field-editing affordances (amount bottom sheet, category navigation, date picker, merchant/memo TextFields, ledger toggle, soul satisfaction picker) are battle-tested today and stay shape-stable.
- **`TimeWindow` Freezed sealed union** (`lib/features/analytics/domain/models/time_window.dart`) — pattern template for `TransactionDetailsFormConfig.new / .edit`.
- **`VoiceParseResult`** — Freezed model template that `OcrParseDraft` mirrors structurally (nullable fields, sibling to a feature flow's input parse result).
- **`TransactionRepository.update(Transaction)`** + **`TransactionDao.updateTransaction(...)`** + **`TransactionRepositoryImpl.update(...)`** — full-row replace already wired and tested in v1.2; Phase 18 adds the `UpdateTransactionUseCase` orchestration on top. Note encryption is preserved (impl re-encrypts via `_encryptionService.encryptField`).
- **`TransactionSyncMapper.toUpdateOperation(...)`** — already exists at line 86-106; just needs a caller (the new `trackUpdate` in the change tracker).
- **`HomeTransactionTile.onTap` plumbing** — already declared as `final VoidCallback? onTap;`; wiring is one line in `home_screen.dart`.
- **`recordCategoryCorrectionUseCaseProvider`** — voice-learning hook already in `transaction_confirm_screen.dart`; ports verbatim into the new form widget's `.new`-mode category onChange handler.
- **`SoulCelebrationOverlay`** — celebration UI already in place; reused only for `.new` soul saves.

### Established Patterns
- **Embeddable widget + host-owned Scaffold/CTA** — emerges as Phase 18's pattern; Phase 19/22 will repeat.
- **Freezed sealed config object passed to a widget** — established in `TimeWindow`; `TransactionDetailsFormConfig` follows.
- **`@riverpod` provider in `repository_providers.dart`** — single source-of-truth per feature; `updateTransactionUseCaseProvider` joins `createTransactionUseCaseProvider` / `deleteTransactionUseCaseProvider`.
- **Required-no-default explicit `entrySource` on use-case params** (Phase 17 D-06) — `UpdateTransactionUseCase` does NOT need this because it re-saves the seed's `entrySource` verbatim; the use-case params can read it from the seed Transaction.
- **Use case `execute(params) -> Future<Result<Transaction>>`** — consistent shape across create/delete/get; update follows.
- **Atomic Drift transactions** — DAO methods are single statements; `updateTransaction` already qualifies.

### Integration Points
- **`transaction_entry_screen.dart:224-235`** — manual push site untouched.
- **`voice_input_screen.dart:351-367`** — voice push site untouched.
- **`ocr_scanner_screen.dart:128-145`** — shutter onTap changes target from `Navigator.pop` to `push OcrReviewScreen`.
- **`home_screen.dart:290-329`** — `HomeTransactionTile` block gets `onTap: () => Navigator.push(...TransactionEditScreen(transaction: tx))`.
- **`repository_providers.dart`** — extend with `updateTransactionUseCaseProvider`.
- **`l10n/*.arb`** — five new keys in trilingual lockstep.

</code_context>

<specifics>
## Specific Ideas

- **The form widget is the load-bearing artifact of Phase 18.** Downstream agents reading SC-1's "single TransactionDetailsForm widget renders all editable fields" should treat the form widget as the source of truth — every host screen (`TransactionConfirmScreen` refactored, `TransactionEditScreen` new, `OcrReviewScreen` new, plus Phase 19/22 manual/voice one-step screens later) is a thin Scaffold + AppBar + CTA wrapper around it.
- **No Drift schema migration in Phase 18** (SC-5). Current v17 (`entry_source` column + check constraint) is fully sufficient. If something seems to require a schema change, stop and re-evaluate — the requirement may belong in v1.4+.
- **`entrySource` preservation on edit is non-negotiable** (SC-3). The `UpdateTransactionUseCase` re-saves `seed.entrySource` verbatim. There is NO call site where an edit flips entrySource. The DAO test exercises all three literals (`manual`, `voice`, `ocr`) round-tripping through edit.
- **OCR slot stamps `EntrySource.manual` for Phase 18** (D-12) — strictly honors Phase 17 D-07's "ocr enum reserved, no live row in v1.x" promise. The single line that will flip is annotated with an inline comment so MOD-005's diff is discoverable.
- **Hash chain is frozen on edit** (D-08). Phase 18 explicitly does not re-derive `currentHash`/`prevHash` when saving an edited row. Trade-off accepted: tamper-evidence is for the create event, not subsequent metadata.
- **Form internal state stays in `StatefulWidget`, not Riverpod.** Local form state (current amount, current category, current ledger type, current satisfaction, dirty flag) is widget-local. Repository / use-case access is via `ref.read(...)` exactly as today's `TransactionConfirmScreen` does it.
- **No dirty-cancel modal** (D-16) and **no delete affordance** (D-17) on the edit screen in Phase 18. Both are deliberately deferred to keep the cancel and edit paths minimal and the Phase 18 diff focused.
- **Soul celebration plays only on `.new`** (D-15). ADR-012 anti-gamification stance applies: a celebration is the *first-time* signal, not a repeatable reward.

</specifics>

<deferred>
## Deferred Ideas

### Beyond Phase 18 (other v1.3 phases)
- **Manual one-step screen** consuming `TransactionDetailsForm` — Phase 19.
- **Voice one-step screen** consuming `TransactionDetailsForm` — Phase 22.
- **Voice number parser strengthening** — Phase 20.
- **Voice category resolver level-2 enforcement** — Phase 21.
- **Record button UX** — Phase 22.

### Beyond v1.3 (v1.4+)
- **MOD-005 OCR writer landing.** `OcrReviewScreen` exists from Phase 18; MOD-005's first commit replaces `OcrScannerScreen`'s camera stub with real capture + OCR, wires the result into `OcrParseDraft(...)` (no longer `.empty()`), and flips the `entrySource: EntrySource.manual` literal in `OcrReviewScreen` to `EntrySource.ocr`.
- **Delete-from-row UX.** `DeleteTransactionUseCase` already exists; a future story wires it into the edit screen's AppBar action or the home tile long-press. Phase 18 ships neither.
- **Dirty-state confirmation dialog on cancel.** Standard "discard changes?" modal pattern; future polish.
- **Long-press / swipe-to-delete on the home recent-tx tile.** Future UX story; Phase 18 only wires the existing `onTap` plumbing.
- **Edit-history audit log** (e.g., "this row was edited 3 times on these dates"). `updatedAt` is updated on edit but there is no separate audit table. Future story if family-sync conflict resolution needs more detail.
- **Undo-after-save**. Phase 18 does not implement an undo affordance; once save commits, the change is final until a subsequent edit.
- **Hash chain re-derivation on edit.** Explicitly rejected in Phase 18 (D-08); reopening would require an ADR addressing the migration of every existing tip.
- **Edit-screen state persistence across app restart.** Standard `StatefulWidget` semantics; if the user backgrounds the app mid-edit, restart returns them to home with no recovery.
- **`OcrParseDraft` field expansion** (category guesses, line items, merchant fuzzy-match, currency code, totals validation). MOD-005 adds these as it needs them.

### Reviewed Todos (not folded)
`cross_reference_todos` returned 0 matches for Phase 18. Carry-forward v1.2 known close debt (Phase 13/17 VERIFICATION.md gaps, 3 VALIDATION.md drafts, 6 `family_insight_card_test.dart` failures from Phase 15) is unrelated to Phase 18 scope.

</deferred>

---

*Phase: 18-Shared Details Form Foundation*
*Context gathered: 2026-05-22*
