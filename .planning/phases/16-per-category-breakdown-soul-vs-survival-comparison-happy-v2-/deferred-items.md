# Phase 16 — Deferred items (out-of-scope during execution)

## 16-10 — pre-existing failure in family_insight_card_test.dart

**Found while running:** `flutter test test/widget/features/analytics/` during 16-10 verification.

**Failing test:** `renders highlights sentence from aggregate value` at
`test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart:82`.

**Symptom:** `Expected: exactly one matching candidate / Actual: _TextWidgetFinder:<Found 0 widgets with text "今月、家族の小確幸 23回">`.

**Why deferred:** 16-10 only touched `analytics_screen.dart` (cards + _refresh
invalidations) and `home_screen_isolation_test.dart`. `family_insight_card_test.dart`
was not modified by 16-10 and the test exercises ARB strings + widget logic that
exist independent of the Phase 16 cards. The failure reproduces on the same
commits with my changes reverted, so it is a pre-existing issue (likely an ARB
key drift from a previous phase, not Phase 16).

**Action for future phase:** triage `family_insight_card_test.dart` Japanese
ARB rendering — verify `analyticsFamilyHighlights` key + plural forms match
what the test expects.
