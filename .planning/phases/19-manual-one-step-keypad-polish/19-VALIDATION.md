---
phase: 19
slug: manual-one-step-keypad-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `19-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + mocktail + matchesGoldenFile (vanilla, no alchemist/golden_toolkit) |
| **Config file** | pubspec.yaml (test deps), test/widget/_test_setup.dart (font loading) |
| **Quick run command** | `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` |
| **Full suite command** | `flutter analyze && flutter test --coverage` |
| **Estimated runtime** | ~120 seconds (full suite); ~8 seconds (quick) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` (zero warnings invariant)
- **After every plan wave:** Run plan-scoped test target (see Per-Task Map)
- **Before `/gsd:verify-work`:** `flutter analyze && flutter test --coverage` must be green; coverage ≥ 80%
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

> Tasks fill in from PLAN.md after planning completes. Below is the SC-to-test mapping the planner MUST honor.

| SC | Requirement | Test Type | Test File | Automated Command | Assertion Shape |
|----|-------------|-----------|-----------|-------------------|-----------------|
| SC-1 | INPUT-01 | widget | test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart | `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` | `expect(find.text(S.of(context).next), findsNothing); expect(find.text('下一步'), findsNothing); expect(find.byType(AmountDisplay), findsOneWidget); expect(find.byType(LedgerTypeSelector), findsOneWidget); expect(find.byKey(const ValueKey('category-chip')), findsOneWidget); expect(find.byKey(const ValueKey('date-chip')), findsOneWidget); expect(find.byKey(const ValueKey('merchant-textfield')), findsOneWidget); expect(find.byKey(const ValueKey('note-textfield')), findsOneWidget);` |
| SC-2 | KEYPAD-01 | widget | test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart | `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` | With `MediaQuery(size: Size(390, 844))` and `MediaQuery(size: Size(375, 667))` (iPhone SE): for each `_DigitKey`, `tester.getSize(finder).height >= 48.0`. **Critical:** SE case must pass — proves the `math.max(48.0, ...)` clamp from Pitfall §1 is in place. |
| SC-3 | KEYPAD-01 | golden | test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart | `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` | 6 golden images: `smart_keyboard_{ja,zh,en}_{light,dark}.png`. Each pumps `SmartKeyboard` in isolation under `MaterialApp(localizationsDelegates: ..., supportedLocales: [Locale('ja'), Locale('zh'), Locale('en')], locale: Locale(...), theme: ThemeData(brightness: ...))`. Baseline images committed under `test/widget/.../widgets/goldens/`. |
| SC-4 | INPUT-01 | integration | test/integration/features/accounting/manual_save_entry_source_test.dart | `flutter test test/integration/features/accounting/manual_save_entry_source_test.dart` | Pump `ManualOneStepScreen(bookId: testBookId)` with a real `Drift` test database, simulate digit taps + ledger toggle + Save, query `appDatabase.transactionsDao.findById(savedId)`, assert `tx.entrySource == 'manual'`. |
| SC-5 | INPUT-01 + KEYPAD-01 | manual + tooling | n/a | `flutter gen-l10n` (exit 0) + `grep -r "Text('" lib/features/accounting/presentation/screens/manual_one_step_screen.dart \| grep -v "S.of(context)"` (zero non-localized literals) | Verify `S.of(context).keyboardToolbarDone` resolves to "完了" (ja) / "完成" (zh) / "Done" (en). Run `flutter gen-l10n` and confirm zero warnings. All three ARB files have parity for any new keys. |
| SC-1+SC-4 (voice regression) | INPUT-01 | widget | test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart | `flutter test test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` | Push `ManualOneStepScreen` with all voice-path params (`entrySource: EntrySource.voice`, `voiceKeyword`, pre-filled amount/category/merchant/satisfaction). Simulate Save. Assert saved Transaction has `entrySource == 'voice'`. Assert voice-correction registration (`recordCategoryCorrectionUseCaseProvider`) fires when category changes. Assert soul celebration triggers when `_ledgerType == LedgerType.soul`. |
| Persistent keypad slide | INPUT-01 | widget | manual_one_step_screen_test.dart (same as SC-1) | (in SC-1 file) | Tap merchant TextField → `tester.widget<AnimatedSlide>(find.ancestor(of: find.byType(SmartKeyboard), matching: find.byType(AnimatedSlide))).offset.dy == 1.0`. Tap AmountDisplay → `offset.dy == 0`. Verify `Scaffold.resizeToAvoidBottomInset == false`. |
| KeyboardToolbar | INPUT-01 | widget | manual_one_step_screen_test.dart (same as SC-1) | (in SC-1 file) | Tap merchant TextField → `expect(find.byType(KeyboardToolbar), findsOneWidget)`. Tap toolbar `Done` → SmartKeyboard returns (`offset.dy == 0`). Tap toolbar `记账`/Save → same submit handler runs (assert via spy on `createTransactionUseCaseProvider`). Visibility-only-when-`viewInsets.bottom > 0`. |
| TransactionConfirmScreen deletion | INPUT-01 | static | n/a | `! grep -rn "TransactionConfirmScreen\\|TransactionEntryScreen" lib/ \| grep -v "// removed"` | Zero production references after delete + voice repoint. `grep` returns no matches (exit 1 from grep = pass when wrapped with `!`). |
| Form externalize-amount refactor (D-14) | INPUT-01 | widget (Phase 18 hosts) | test/widget/features/accounting/presentation/screens/transaction_edit_screen_test.dart + ocr_review_screen_test.dart | `flutter test test/widget/features/accounting/presentation/screens/transaction_edit_screen_test.dart test/widget/features/accounting/presentation/screens/ocr_review_screen_test.dart` | Both hosts now render their own `AmountDisplay`. Tap amount → bottom sheet opens (existing UX, just moved). Save still preserves amount. Coverage ≥ 70% per file (project rule). |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — add `keyboardToolbarDone` key (ja: "完了", zh: "完成", en: "Done"). The `done` key was verified ABSENT in all three locales (RESEARCH §Finding 2).
- [ ] `flutter gen-l10n` — regenerate `lib/generated/l10n.dart` so `S.of(context).keyboardToolbarDone` resolves.
- [ ] `test/widget/features/accounting/presentation/widgets/goldens/` — directory must exist with baseline images checked in (6 PNGs after first `flutter test --update-goldens` run on a developer machine).
- [ ] `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` — new file (does not exist before Phase 19).
- [ ] `test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` — new file or extension (verify pre-existence).
- [ ] `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` — new file.
- [ ] `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` — new file.
- [ ] `test/integration/features/accounting/manual_save_entry_source_test.dart` — new file (verify integration test infrastructure with Drift in-memory DB exists; if not, add `test/helpers/test_database.dart` fixture).

*If `mocktail`, `flutter_test`, `drift` test infrastructure are all already in pubspec.yaml dev_dependencies (verified in RESEARCH), Wave 0 is purely additive — no new framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden baseline image approval (SC-3) | KEYPAD-01 | Initial golden images must be visually approved by a human before being committed as the regression baseline. Automated test only catches drift FROM baseline, not whether baseline is correct. | (1) Run `flutter test --update-goldens test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`. (2) Open `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{ja,zh,en}_{light,dark}.png` in image viewer. (3) Visually verify: adjacent keys are clearly separated, Save button gradient is visible, dark mode contrast meets WCAG AA. (4) Commit. |
| Real-device thumb-reach validation (SC-2) | KEYPAD-01 | The 48dp floor is a minimum, but "thumb reach feels comfortable" is subjective. Widget-test asserts geometry; only a human can validate UX. | (1) Run on physical iPhone SE (≤ 4.7"), iPhone 14 (6.1"), iPhone 14 Pro Max (6.7"), and a 5.5"+ Android. (2) Enter 6-digit amount (e.g., 123456) with thumb only, holding device one-handed. (3) Confirm < 5% mistap rate across 20 trials. (4) Confirm no key requires thumb stretch on Pro Max. |
| Soft-keyboard ↔ SmartKeyboard transition smoothness (D-11/D-13) | INPUT-01 | Animation jitter is hard to assert via widget test — visible at 60fps real-device only. | (1) Open ManualOneStepScreen on real device. (2) Tap merchant TextField → soft keyboard slides up, SmartKeyboard slides down. (3) Tap AmountDisplay → soft keyboard dismisses, SmartKeyboard slides back. (4) Verify NO content jump, NO layout shift, NO frame drops during transition (use Flutter DevTools Performance tab if uncertain). |
| Voice flow end-to-end on device (D-16) | INPUT-01 | Voice recognition + push to ManualOneStepScreen + save with `entrySource = 'voice'` involves device microphone permissions and platform plugins not exercisable in widget tests. | (1) On real iOS + Android device, open voice input. (2) Speak "今天午餐花了一千二百日元 in zh / "今日のランチに1200円使った" in ja. (3) Confirm ManualOneStepScreen opens pre-filled with amount=1200, category resolved (or default), merchant null, voiceKeyword set. (4) Tap Save. (5) Query DB via debug tools: `tx.entry_source == 'voice'`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (the planner will fill this column in PLAN.md)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (ARB additions, golden directory, new test files)
- [ ] No watch-mode flags (CI uses one-shot `flutter test`, not `flutter test --watch`)
- [ ] Feedback latency < 120s (full suite)
- [ ] `nyquist_compliant: true` set in frontmatter after planner completes per-task map

**Approval:** pending
