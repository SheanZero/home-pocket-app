---
phase: 27
slug: calendar-header-month-summary
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 27-RESEARCH.md §"Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (already configured) |
| **Config file** | `pubspec.yaml` `dev_dependencies` |
| **Quick run command** | `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~5s quick · ~60-120s full suite |

---

## Sampling Rate

- **After every task commit:** Run the quick command (provider unit test).
- **After every plan wave:** Run `flutter test` (full suite).
- **Before `/gsd-verify-work`:** Full suite green **AND** `flutter build ios --debug --no-codesign` passes (SC#5).
- **Max feedback latency:** ~120 seconds (full suite).

---

## Per-Task Verification Map

> Task IDs are assigned by the planner; rows below map each Success Criterion to its
> minimal observable validation. The planner MUST attach the matching `<automated>`
> verify command to the task that delivers each SC.

| SC | Requirement | Behavior | Test Type | Automated Command | File Exists |
|----|-------------|----------|-----------|-------------------|-------------|
| SC#1 | CAL-01 | Month nav: `selectMonth` updates focusedDay; grid re-renders; month label updates (e.g. ja `2026年5月`) | widget | `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | ❌ W0 |
| SC#2 | CAL-02 | Day cell shows expense total; empty days show no amount; expense-only (income excluded); `_dayKey` normalization | provider unit | `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` | ❌ W0 |
| SC#3 | CAL-03 | Tap day → `activeDayFilter` set + highlight; tap same day → cleared (`selectDay(null)`) | widget (provider-state assertion) | `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | ❌ W0 |
| SC#4 | CAL-04 | Month summary = sum of expense-only per-day totals; formatted via `NumberFormatter.formatCurrency` + `AppTextStyles.amountSmall` | widget (text-finder) | `flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | ❌ W0 |
| SC#5 | CAL-01..04 | `table_calendar: ^3.2.0` added; iOS build passes; `intl: 0.20.2` pin unbroken | build | `flutter build ios --debug --no-codesign` | ❌ W0 (pubspec edit) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` — covers SC#2 (expense-only basis, income excluded, `_dayKey` normalization, month-total fold from `Map<DateTime,int>` values)
- [ ] `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` — covers SC#1 (month nav state), SC#3 (day-tap toggle), SC#4 (summary row amount text)
- [ ] `lib/features/list/presentation/widgets/` directory — must exist before `list_calendar_header.dart` is placed there; confirm no `import_guard.yaml` violation for the new subdirectory
- [ ] `pubspec.yaml` — add `table_calendar: ^3.2.0` (Wave 1, task 1); run `flutter pub get` + `build_runner build --delete-conflicting-outputs`
- [ ] Verify `lib/core/initialization/app_initializer.dart` calls `initializeDateFormatting` (RESEARCH open question #1) — add if absent so ja/zh day-of-week headers render correctly

*Mocktail mock of `AnalyticsRepository` + `ProviderContainer.test()` + `waitForFirstValue<T>` per CLAUDE.md Riverpod 3 async-test conventions.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Horizontal swipe gesture changes month | CAL-01 | `table_calendar` native gesture is awkward to drive deterministically in widget tests; arrows path covers the same `onPageChanged` → `selectMonth` wiring | On device/simulator: swipe the calendar left/right; confirm month label + grid update identically to arrow taps |
| iOS device visual rendering of compact amounts in ~40dp cells | CAL-02 | Pixel overflow / font-scaling only observable on a real layout pass | Run app on iOS simulator; inspect a month with 5+ digit JPY day totals; confirm no overflow/clipping |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags (no `flutter test --watch`)
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
