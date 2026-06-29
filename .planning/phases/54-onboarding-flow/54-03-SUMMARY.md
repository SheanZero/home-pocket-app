---
phase: 54-onboarding-flow
plan: 03
subsystem: ui
tags: [flutter, riverpod, settings, deep-link, scroll, onboarding]

# Dependency graph
requires:
  - phase: 54-onboarding-flow
    provides: onboarding flow scaffolding + onboardingComplete flag (54-01/54-02)
provides:
  - "SettingsScreen.scrollToSecurity opt-in deep-link param (default false)"
  - "GlobalKey anchor on the SecuritySection slot — the landing target for 现在设置"
  - "Robust lazy-list scroll-to-section mechanism (jumpTo bottom → ensureVisible)"
affects: [54-06-onboarding-lock-entry, 55-pin-biometric]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lazy-ListView deep-link: ScrollController.jumpTo(maxScrollExtent) mounts the near-end target element, then a one-shot post-frame Scrollable.ensureVisible centers it"
    - "Opt-in widget intent param defaulting to today's behavior (byte-compatible callers)"

key-files:
  created:
    - test/widget/features/settings/settings_screen_scroll_to_security_test.dart
  modified:
    - lib/features/settings/presentation/screens/settings_screen.dart

key-decisions:
  - "Converted SettingsScreen ConsumerWidget → ConsumerStatefulWidget to own the GlobalKey, ScrollController, and one-shot guard"
  - "Wrapped the SecuritySection slot in a KeyedSubtree instead of editing SecuritySection internals (security_section.dart left byte-unchanged)"
  - "jumpTo(maxScrollExtent) before ensureVisible — the planned bare ensureVisible(key.currentContext!) no-ops because a lazy ListView does not mount the off-screen SecuritySection element (its GlobalKey context is null)"

patterns-established:
  - "Deep-link target (D-13): optional bool intent + section GlobalKey + post-frame scroll, default behavior untouched"

requirements-completed: [ONBOARD-06]

coverage:
  - id: D1
    description: "SettingsScreen(scrollToSecurity: true) brings the SecuritySection into view after the first frame"
    requirement: ONBOARD-06
    verification:
      - kind: unit
        ref: "test/widget/features/settings/settings_screen_scroll_to_security_test.dart#scrollToSecurity: true brings SecuritySection into view after first frame"
        status: pass
    human_judgment: false
  - id: D2
    description: "SettingsScreen(scrollToSecurity: false) renders identically to today with no scroll side-effect; existing call site unchanged"
    requirement: ONBOARD-06
    verification:
      - kind: unit
        ref: "test/widget/features/settings/settings_screen_scroll_to_security_test.dart#scrollToSecurity: false renders at the top with no scroll side-effect"
        status: pass
    human_judgment: false

# Metrics
duration: 35min
completed: 2026-06-29
status: complete
---

# Phase 54 Plan 03: SettingsScreen Security Deep-Link Target Summary

**Opt-in `SettingsScreen.scrollToSecurity` flag that deep-links the existing pushed settings list to its SecuritySection via a lazy-list-safe jumpTo→ensureVisible scroll, with default behavior byte-unchanged.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-29T13:40:00Z
- **Completed:** 2026-06-29T14:13:04Z
- **Tasks:** 1
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments
- Added opt-in `scrollToSecurity` param (default `false`) to `SettingsScreen`; the lone existing caller (`main_shell_screen.dart`) is byte-compatible.
- Converted `SettingsScreen` to `ConsumerStatefulWidget` owning a `GlobalKey` anchor on the `SecuritySection` slot, a `ScrollController`, and a one-shot guard.
- Implemented a lazy-list-safe deep-link: `jumpTo(maxScrollExtent)` mounts the near-end SecuritySection element, then a post-frame `Scrollable.ensureVisible` centers it exactly once.
- Added a 2-case widget test (true → scrolls into view; false → no scroll side-effect), both green; `flutter analyze` 0 issues.
- No new PIN/biometric UI introduced; `security_section.dart` left untouched (Phase 55 fills the real lock here).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add scrollToSecurity intent + SecuritySection anchor** - `c35ee8be` (feat, TDD test+impl)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `lib/features/settings/presentation/screens/settings_screen.dart` - Added `scrollToSecurity` param; ConsumerWidget→ConsumerStatefulWidget; GlobalKey/ScrollController deep-link mechanism; KeyedSubtree-wrapped SecuritySection slot.
- `test/widget/features/settings/settings_screen_scroll_to_security_test.dart` - New widget test covering both deep-link states.

## Decisions Made
- **ConsumerStatefulWidget conversion:** needed to own the post-frame callback, GlobalKey, ScrollController, and one-shot guard.
- **KeyedSubtree wrapper:** the GlobalKey is hosted on a wrapper around `SecuritySection(settings:)`, so `security_section.dart` stays byte-unchanged (plan's conditional: only edit it if a parameter is genuinely required — it wasn't).
- **jumpTo-before-ensureVisible:** see Deviations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bare `Scrollable.ensureVisible(key.currentContext!)` no-ops on a lazy ListView**
- **Found during:** Task 1 (deep-link verification)
- **Issue:** The plan's suggested mechanism (`addPostFrameCallback → Scrollable.ensureVisible(key.currentContext!)`) silently does nothing because `ListView(children:)` lazily culls off-screen children. The SecuritySection is the 8th of 9 sections, so at offset 0 its element is never mounted and `_securitySectionKey.currentContext` is `null` (confirmed via debug: section absent from tree, scroll offset stayed 0). This is RESEARCH Pitfall 5's explicit "discretion area."
- **Fix:** Attached a `ScrollController` to the ListView; on deep-link, `jumpTo(position.maxScrollExtent)` first (forces the bottom slice — incl. SecuritySection — to build), then a one-shot post-frame `Scrollable.ensureVisible` centers the now-mounted section. Robust to future section-count growth since the target is near the list end.
- **Files modified:** lib/features/settings/presentation/screens/settings_screen.dart
- **Verification:** `scrollToSecurity: true` test now asserts scroll offset > 0 and the section rect within the viewport; both cases green.
- **Committed in:** c35ee8be (Task 1 commit)

**2. [Rule 1 - Test infra] Family-sync provider Timer leak in the widget test**
- **Found during:** Task 1 (first green run)
- **Issue:** Rendering the full `SettingsScreen` builds `FamilySyncSettingsSection`, whose `syncStatusStreamProvider` constructs the real `SyncEngine` (periodic status timer) → "A Timer is still pending even after the widget tree was disposed" at teardown.
- **Fix:** Overrode `syncStatusStreamProvider` (empty stream) and `activeGroupProvider` (Stream.value(null)) in the test scope, bypassing the real engine. Mirrors the override strategy in `data_reset_refresh_test.dart`.
- **Files modified:** test/widget/features/settings/settings_screen_scroll_to_security_test.dart
- **Verification:** Test suite exits cleanly (no pending-timer assertion); both cases green.
- **Committed in:** c35ee8be (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 — correctness + test infra)
**Impact on plan:** Both fixes were necessary for the feature to actually work / for the test to be green-and-clean. No scope creep; the public API (`scrollToSecurity`), default behavior, and "no new lock UI" constraints are all exactly as planned.

## Issues Encountered
- Diagnosed the silent no-op (scroll offset stayed 0) via a throwaway debug test that printed Scrollable count/positions and `find.byType(SecuritySection)` — revealed the off-screen section was never mounted in the lazy ListView. Resolved by the jumpTo-then-ensureVisible mechanism (Deviation 1).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The deep-link landing TARGET is ready. 54-06's onboarding lock-entry screen can now route `现在设置` → `SettingsScreen(scrollToSecurity: true)` to land the user on the security area.
- Phase 55 fills the real PIN/biometric inside the (unchanged) `SecuritySection`.

## Self-Check: PASSED

- `lib/features/settings/presentation/screens/settings_screen.dart` — FOUND
- `test/widget/features/settings/settings_screen_scroll_to_security_test.dart` — FOUND
- Commit `c35ee8be` — FOUND

---
*Phase: 54-onboarding-flow*
*Completed: 2026-06-29*
