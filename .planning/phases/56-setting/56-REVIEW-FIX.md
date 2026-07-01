---
phase: 56-setting
fixed_at: 2026-07-01T00:00:00Z
review_path: .planning/phases/56-setting/56-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 56: Code Review Fix Report

**Fixed at:** 2026-07-01
**Source review:** .planning/phases/56-setting/56-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (1 critical, 2 warning — Info items IN-01/02/03 out of scope for `critical_warning`)
- Fixed: 3
- Skipped: 0

**Verification:** `flutter analyze` on all changed files → "No issues found!". `flutter test` on the two affected widget test files → 17/17 passed (includes the new CR-01 throw test and the WR-01 refactored screen tests).

## Fixed Issues

### CR-01: `launchUrl` can throw `PlatformException` — unguarded, contradicting the "never crashes" contract

**Files modified:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart`, `test/widget/features/settings/legal_sponsor_section_test.dart`
**Commit:** b1557596
**Applied fix:** Wrapped the `launchUrl(Uri.parse(...))` call in `_openSponsor` in a `try/catch` that sets `ok = false` on any thrown error, so a thrown `PlatformException` (e.g. Android `ActivityNotFoundException`) or `Uri.parse` `FormatException` now falls through to the single neutral SnackBar instead of escaping as an uncaught async error. Added a widget test that makes the mock launcher throw `PlatformException` and asserts the neutral SnackBar still shows and `tester.takeException()` is null.

### WR-01: `FutureBuilder` re-creates the `rootBundle.loadString` future on every rebuild

**Files modified:** `lib/features/settings/presentation/screens/legal_doc_screen.dart`
**Commit:** 347b4a76
**Applied fix:** Converted `LegalDocScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` and memoized the load future in a `Future<String>? _content` field keyed on the resolved `_assetPath`. The future is now recreated only when the asset path changes (locale switch); unrelated rebuilds (theme/`context.palette`, `MediaQuery`) reuse the cached future, so the `FutureBuilder` no longer resets to `waiting` and flashes the spinner over rendered legal text. The public `doc` field and constructor are preserved, so `tester.widget<LegalDocScreen>(...).doc` assertions still hold. Chose the `ConsumerStatefulWidget` memoization option (over a new code-gen `FutureProvider.family`) to avoid a build_runner regen step in this fix pass.

### WR-02: App version `'0.1.0'` hardcoded in two places; drifts from `pubspec.yaml`

**Files modified:** `lib/core/constants/app_info.dart` (new), `lib/features/settings/presentation/widgets/about_section.dart`, `lib/features/settings/presentation/widgets/legal_sponsor_section.dart`
**Commit:** 7d4bf088
**Applied fix:** Introduced a single source-of-truth `const String appVersion = '0.1.0'` in a new `lib/core/constants/app_info.dart`, and referenced it from both the About tile subtitle and `showLicensePage(applicationVersion: ...)`, eliminating the duplicated literal. Applied the reviewer's sanctioned "at minimum, hoist a single const" option rather than the full `PackageInfo.fromPlatform()` route: `PackageInfo` is async and unmocked in the existing widget tests, so wiring it into these `StatelessWidget`s (one of which is tapped in the OSS-license test) would have broken the current test setup. A third, unrelated `'0.1.0'` fallback default in `lib/application/settings/export_backup_use_case.dart` was left untouched (outside this finding's scope). Note: the constant still needs manual sync with `pubspec.yaml` on release bumps — a follow-up to source it from `PackageInfo` remains an option.

---

_Fixed: 2026-07-01_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
