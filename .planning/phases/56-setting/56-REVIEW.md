---
phase: 56-setting
reviewed: 2026-07-01T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/core/config/legal_urls.dart
  - lib/features/settings/presentation/screens/legal_doc_screen.dart
  - lib/features/settings/presentation/screens/settings_screen.dart
  - lib/features/settings/presentation/widgets/about_section.dart
  - lib/features/settings/presentation/widgets/legal_sponsor_section.dart
  - test/architecture/legal_asset_parity_test.dart
  - test/widget/features/settings/legal_doc_screen_test.dart
  - test/widget/features/settings/legal_sponsor_section_test.dart
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 56: Code Review Report

**Reviewed:** 2026-07-01
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the Settings 法的情報・応援 section: the offline legal-doc reader (`legal_doc_screen.dart`), the sponsor-link section (`legal_sponsor_section.dart`), the centralized URL holder (`legal_urls.dart`), the slimmed `about_section.dart`, the section wiring in `settings_screen.dart`, and three test files.

The two flagged focus areas hold up well on the injection axis. The asset-path whitelist guard in `LegalDocScreen` is correct: both inputs to `rootBundle.loadString` are closed sets (the `LegalDoc` enum `slug` and the `_supportedLangs`-guarded language code), an unknown locale deterministically falls back to `ja`, and the missing-asset path is covered by the FutureBuilder error branch plus the `legal_asset_parity_test` existence gate. The sponsor launch uses a compile-time `const` https URL (no injection surface), `LaunchMode.externalApplication` (no in-app WebView/IAP), and correctly captures `l10n`/`messenger` before the `await` with a `context.mounted` re-check. All UI strings route through `S.of(context)`; no hardcoded CJK in `lib/`.

Two genuine robustness gaps remain: the sponsor launch only handles the `launchUrl` false-return path (not its thrown-exception path), and the legal reader recreates its load Future on every rebuild. Neither is a security issue; both weaken guarantees the plan explicitly claims.

## Warnings

### WR-01: `launchUrl` thrown exception bypasses the "graceful failure" guarantee

**File:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:34-46`
**Issue:** `url_launcher`'s `launchUrl` does not only return `false` on failure — per its documented contract it returns `false` *or throws a `PlatformException`* depending on the failure mode (unsupported scheme, no handler activity, platform channel error). `_openSponsor` handles only the `!ok` (false-return) branch. A thrown `PlatformException` propagates out of the un-awaited `onTap: () => _openSponsor(context)` callback as an **unhandled async error**: the neutral SnackBar (`l10n.sponsorLaunchError`) is never shown, and the error is routed to the zone/`FlutterError` handler (which may log the failure). This directly contradicts the method's own doc comment ("On failure shows one neutral SnackBar — never crashes") and the T-56-06 requirement. The widget test mock (`_MockLauncher`) only ever *returns* `false`, so this throw path is both unhandled and untested.
**Fix:** Wrap the launch in try/catch and funnel both failure modes to the same neutral SnackBar:
```dart
Future<void> _openSponsor(BuildContext context) async {
  final l10n = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(
      Uri.parse(LegalUrls.donation),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    ok = false; // PlatformException etc. -> treat as launch failure
  }
  if (!ok && context.mounted) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.sponsorLaunchError)));
  }
}
```
Add a test where `_MockLauncher.launchUrl` throws, asserting the SnackBar still appears and no exception escapes (`tester.takeException()` is null).

### WR-02: `FutureBuilder` load Future recreated on every `build()`

**File:** `lib/features/settings/presentation/screens/legal_doc_screen.dart:65-66`
**Issue:** `future: rootBundle.loadString(assetPath)` is constructed inline inside `build()`. `LegalDocScreen` is a `ConsumerWidget`, so any rebuild (device rotation / `MediaQuery` change, theme change, `currentLocaleProvider` re-emit, ancestor rebuild) creates a *new* Future, resetting the `FutureBuilder` to `ConnectionState.waiting` and re-flashing the `CircularProgressIndicator` — plus re-issuing the bundle load each time. This is the classic Flutter "future-in-build" anti-pattern. The reader's own test file documents the symptom directly (`tearDown(rootBundle.clear)` with the comment "a cache-hit reload leaves the FutureBuilder spinner animating the simulated clock, timing out pumpAndSettle"), confirming the Future is not memoized. `rootBundle` caches the decoded string so the cost is small, but the UX flash on rotation is real and the pattern is fragile.
**Fix:** Memoize the load so it fires once per (doc, lang). Cleanest option given the codebase's Riverpod-3 conventions is a small `FutureProvider.family` keyed by the asset path (or `(doc, safeLang)`), watched via `ref.watch(...)` and rendered with `.when(...)`. If keeping `FutureBuilder`, convert to a `ConsumerStatefulWidget` and build the Future once in `initState`/`didChangeDependencies` (recomputing only when `safeLang` changes), storing it in a field.

## Info

### IN-01: App version `'0.1.0'` hardcoded and duplicated

**File:** `lib/features/settings/presentation/widgets/about_section.dart:23`, `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:86`
**Issue:** The version literal `'0.1.0'` appears in the About "version" subtitle and again as `showLicensePage(applicationVersion: '0.1.0')`. On the next version bump one is easily missed, and both drift from the real `pubspec.yaml` version. The project already depends on `package_info_plus`.
**Fix:** Source the version from `PackageInfo.fromPlatform()` (or a single shared `const` in `core/constants/`) and reference it in both places.

### IN-02: Redundant `S.of(context)` re-resolution in the OSS row

**File:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:83-88`
**Issue:** `build()` already captures `final l10n = S.of(context)` (line 50), but the `showLicensePage` `onTap` calls `S.of(context).appName` again instead of `l10n.appName`. Minor inconsistency; every other row in this widget uses the captured `l10n`.
**Fix:** Use `l10n.appName`.

### IN-03: `addPostFrameCallback` registered on every rebuild in `SettingsScreen`

**File:** `lib/features/settings/presentation/screens/settings_screen.dart:123-127`
**Issue:** Inside the `data:` builder a post-frame callback is registered on every build. `_maybeScrollToSecurity` is idempotent (guarded by `widget.scrollToSecurity` and the `_didScrollToSecurity` one-shot flag), so behavior is correct, but a fresh callback is scheduled on each rebuild. This is pre-existing (Phase 54 deep-link scroll), not introduced by Phase 56 — noted for context since the file is in scope. No action required for this phase.
**Fix:** Optional — gate registration on `widget.scrollToSecurity && !_didScrollToSecurity` before scheduling, or move the one-shot scroll to `initState`.

---

_Reviewed: 2026-07-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
