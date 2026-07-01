---
phase: 56-setting
reviewed: 2026-07-01T00:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - assets/legal/privacy_en.md
  - assets/legal/privacy_ja.md
  - assets/legal/privacy_zh.md
  - assets/legal/terms_en.md
  - assets/legal/terms_ja.md
  - assets/legal/terms_zh.md
  - assets/legal/tokusho_en.md
  - assets/legal/tokusho_ja.md
  - assets/legal/tokusho_zh.md
  - lib/core/config/legal_urls.dart
  - lib/features/settings/presentation/screens/legal_doc_screen.dart
  - lib/features/settings/presentation/screens/settings_screen.dart
  - lib/features/settings/presentation/widgets/about_section.dart
  - lib/features/settings/presentation/widgets/legal_sponsor_section.dart
  - lib/generated/app_localizations.dart
  - lib/generated/app_localizations_en.dart
  - lib/generated/app_localizations_ja.dart
  - lib/generated/app_localizations_zh.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/architecture/legal_asset_parity_test.dart
  - test/widget/features/settings/legal_doc_screen_test.dart
  - test/widget/features/settings/legal_sponsor_section_test.dart
findings:
  critical: 1
  warning: 2
  info: 3
  total: 6
status: issues_found
---

# Phase 56: Code Review Report

**Reviewed:** 2026-07-01
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Phase 56 adds the "Legal & Support" settings group: an offline per-locale legal-doc
reader (privacy / terms / 特商法), an OSS-license row, and an external-browser sponsor
row, plus 9 bundled Markdown assets and 9 new ARB keys.

Verified clean: ARB key parity across ja/zh/en (all 9 keys present in all 3 files),
generated getters present in `app_localizations.dart`, `assets/legal/` declared in
`pubspec.yaml` (line 121), all 9 legal assets present and substantive, the V12
locale-whitelist guard in `LegalDocScreen` is correct, and the async-gap
`context.mounted` handling in the sponsor launcher is correct for the SnackBar path.

Primary concern: the sponsor launcher's own documented "never crashes" contract is not
actually met — `launchUrl` can throw and the call is unguarded. Two maintainability
warnings (future-in-build re-issue, duplicated hardcoded version) and three info items.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `launchUrl` can throw `PlatformException` — unguarded, contradicting the "never crashes" contract

**File:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:34-46`
**Issue:** The method doc explicitly claims "On failure shows one neutral SnackBar —
never crashes, never retries (T-56-06)", but the implementation only handles the
`!ok` (returns-false) path:

```dart
final ok = await launchUrl(
  Uri.parse(LegalUrls.donation),
  mode: LaunchMode.externalApplication,
);
if (!ok && context.mounted) { ...snackbar... }
```

`url_launcher.launchUrl` does **not** uniformly return `false` on failure. Per its
documented contract it may **throw a `PlatformException`** instead (e.g. Android
`ActivityNotFoundException` when no app can handle the URL). Because `_openSponsor`
is a fire-and-forget async handler wired to `onTap`, a thrown exception becomes an
uncaught async error (red error screen in debug, silently-dropped future in release)
— the exact crash the contract promises to avoid. The widget test only exercises the
`result = false` branch, so this path is untested. `Uri.parse` can likewise throw
`FormatException` once the placeholder is replaced with a real (possibly malformed) URL.
**Fix:**
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
    ok = false;
  }
  if (!ok && context.mounted) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.sponsorLaunchError)));
  }
}
```
Add a test that sets the mock to throw `PlatformException(...)` and asserts the neutral
SnackBar still shows and no exception escapes.

## Warnings

### WR-01: `FutureBuilder` re-creates the `rootBundle.loadString` future on every rebuild

**File:** `lib/features/settings/presentation/screens/legal_doc_screen.dart:65-66`
**Issue:** `future: rootBundle.loadString(assetPath)` is constructed inline in `build`.
Any rebuild of this `ConsumerWidget` (locale change is intended, but also
inherited-widget changes such as theme/`context.palette`, or `MediaQuery` metrics)
constructs a *new* future, resetting the `FutureBuilder` to `ConnectionState.waiting`
and flashing the spinner over already-rendered legal text. The test file itself
documents the fragility of this pattern — `tearDown(rootBundle.clear)` is required
because "a cache-hit reload leaves the FutureBuilder spinner animating the simulated
clock, timing out pumpAndSettle" (`legal_doc_screen_test.dart:13-16`). That workaround
is direct evidence the future-in-build coupling misbehaves on a cache hit.
**Fix:** Memoize the load outside `build`. Simplest: expose a
`FutureProvider.family<String, ({LegalDoc doc, String lang})>` that calls
`rootBundle.loadString`, and `ref.watch` it — the provider caches per (doc, lang) and
survives unrelated rebuilds. Alternatively convert to a `StatefulWidget` and create the
future in `didChangeDependencies` keyed on `assetPath`.

### WR-02: App version `'0.1.0'` hardcoded in two places; drifts from `pubspec.yaml`

**File:** `lib/features/settings/presentation/widgets/about_section.dart:23` and
`lib/features/settings/presentation/widgets/legal_sponsor_section.dart:86`
**Issue:** The version string is duplicated as a magic literal in the About tile
(`subtitle: const Text('0.1.0')`) and in `showLicensePage(applicationVersion: '0.1.0')`.
`pubspec.yaml` is at `version: 0.1.0+1`; on the next release bump both literals go stale
silently, showing the wrong version in the About screen and the OS license page. The
project already depends on `package_info_plus: ^9.0.1` (pubspec line 54) but does not use
it here. This also violates the project "no hardcoded values" rule (CLAUDE.md /
coding-style).
**Fix:** Read the version once via `PackageInfo.fromPlatform()` (or a small
`FutureProvider<PackageInfo>`) and thread `packageInfo.version` into both the About
subtitle and `showLicensePage`. At minimum, hoist a single `const _appVersion` so the
value lives in one place.

## Info

### IN-01: `privacyPolicyHosted` / `termsOfUseHosted` are unused in code

**File:** `lib/core/config/legal_urls.dart:18-21`
**Issue:** Only `LegalUrls.donation` is referenced by code; `privacyPolicyHosted` and
`termsOfUseHosted` are referenced only in dartdoc comments. The dartdoc explains they
exist as the source of truth to paste into App Store Connect metadata, so this is a
documented deliberate constant rather than accidental dead code — flagged only so a
future dead-code sweep does not remove them by mistake.
**Fix:** No action required now; when the store-metadata step lands, reference them from
that tooling/checklist.

### IN-02: Parity test asserts only file existence, not content or bundle declaration

**File:** `test/architecture/legal_asset_parity_test.dart:17-28`
**Issue:** The gate checks `File(path).existsSync()` for all 9 assets but not that each
file is non-empty, nor that `assets/legal/` is declared in `pubspec.yaml`. A zero-byte
or stub asset would pass this test yet render a blank legal document to users, and a
missing pubspec declaration would pass the test yet fail `rootBundle.loadString` at
runtime. (Both hold correctly today — files are substantive and pubspec line 121 declares
the dir — so this is hardening, not a live defect.)
**Fix:** Add `expect(File(path).lengthSync(), greaterThan(0))` per asset, and optionally
assert `pubspec.yaml` contains `assets/legal/`.

### IN-03: Placeholder `example.com` URLs are launch-blocking (documented TODO)

**File:** `lib/core/config/legal_urls.dart:18-23`
**Issue:** All three URLs are `https://example.com/homepocket/...` placeholders. The
sponsor row will open example.com until replaced, and the hosted privacy/terms URLs are
not real. This is intentional and clearly marked (`上线前填真实值` / `TODO`), so it is
recorded as an info-level launch-gate item, not a code defect.
**Fix:** Replace with production URLs before App Store submission; consider a CI check
that fails if any `LegalUrls` value contains `example.com`.

---

_Reviewed: 2026-07-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
