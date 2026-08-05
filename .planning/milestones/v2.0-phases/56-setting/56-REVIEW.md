---
phase: 56-setting
reviewed: 2026-07-01T20:15:00Z
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
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 56: Code Review Report (re-review, post-fix cycle)

**Reviewed:** 2026-07-01T20:15:00Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Re-review of the CURRENT (post-fix) phase-56 code. The three findings from the prior
cycle are verified FIXED and not regressed:

- **CR-01 (sponsor `launchUrl` crash):** `_openSponsor` now wraps
  `Uri.parse` + `launchUrl` in `try/catch (_)` and treats any throw as `!ok`
  (`legal_sponsor_section.dart:39-49`). Covered by the new
  "sponsor launch that THROWS still shows the neutral SnackBar" test.
- **WR-01 (future-in-build spinner flash):** `LegalDocScreen` now memoizes the load
  future in `_content`, recreated only when `_assetPath` changes
  (`legal_doc_screen.dart:51-80`).
- **WR-02 (hardcoded version):** `appVersion` is now a single-source `const` in
  `lib/core/constants/app_info.dart`, consumed by both `about_section.dart` and
  `legal_sponsor_section.dart`.

Additional verification this pass:

- **Security clean.** The `rootBundle.loadString` path is composed only from the
  closed `LegalDoc.slug` enum and the `{ja,zh,en}` whitelist (`_supportedLangs`);
  unknown locales deterministically fall back to `ja`. No untrusted value reaches the
  bundle. Proven by the "unsupported locale falls back to ja" test.
- **i18n non-stale.** All 9 new ARB keys exist in ja/zh/en, and generated
  `app_localizations_*.dart` values match the ARB source verbatim (spot-checked
  `sponsorLaunchError`, `legalSponsorSectionTitle`, `tokushoNoticeSubtitle`). No
  hardcoded CJK in phase-56 Dart. `assets/legal/` is declared in `pubspec.yaml:121`.

One genuine content defect remains in the phase-56 deliverable (Chinese vocabulary in
the default-locale Japanese legal text), plus four low-severity items. No BLOCKER.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Japanese legal drafts contain Chinese-only vocabulary (上線 / 復核)

**File:** `assets/legal/privacy_ja.md:7,56,58,66`, `assets/legal/terms_ja.md:7,58,62`, `assets/legal/tokusho_ja.md:7,15,23,49`
**Issue:** The Japanese (default-locale) legal documents repeatedly use Chinese
vocabulary that is not natural/correct Japanese:
- **「上線前」** (Chinese *shàngxiàn*, "before go-live") — appears 9× across the three
  ja files. Natural Japanese is 「公開前」/「リリース前」.
- **「復核」** (Chinese *fùhé*, "re-review/re-check") — natural Japanese is
  「確認」/「レビュー」.

The zh variants correctly use 「上线」, confirming the terminology leaked from a
Chinese-authored draft into the Japanese translation. Because `ja` is the default app
language and these are legally-facing store-compliance documents (privacy / terms /
特商法) rendered verbatim to Japanese users via `SelectableText`, incorrect Japanese in
the primary legal text is a user-visible quality defect — distinct from the intentional
「草案」/draft markers, which are fine. No current test would catch this.
**Fix:** Replace across all three `*_ja.md` files:
```
上線前  → 公開前   (or リリース前)
復核    → 確認     (or レビュー)
```
e.g. `本ポリシーは上線前に日本の法務により復核される予定の草案です`
→ `本ポリシーは公開前に日本の法務により確認される予定の草案です`. Fold this into the
"reviewed by Japanese legal counsel before launch" pass the drafts already promise.

## Info

### IN-01: `legal_asset_parity_test` asserts existence only, not parity

**File:** `test/architecture/legal_asset_parity_test.dart:17-28`
**Issue:** The test is named "legal asset **parity**" and its doc-comment claims it
gates the drafts, but it only checks `File(path).existsSync()`. A locale that ships a
one-line stub, an empty file, or a file whose section structure diverges from the other
two locales still passes. The widget tests cover a few content markers
(`contains('プライバシーポリシー')`, `contains('隐私政策')`) but not all doc×locale
combinations, so cross-locale structural drift — and defects like WR-01 — go undetected.
**Fix:** Strengthen the arch test to assert non-trivial content and cross-locale parity,
e.g. each file non-empty, starts with a `#` heading, and the count of `##` section
headers matches across the three locales of the same doc.

### IN-02: Placeholder `example.com` / `support@example.com` ship with no enforced launch gate

**File:** `lib/core/config/legal_urls.dart:18-23`, `assets/legal/*_*.md` (contact lines)
**Issue:** `privacyPolicyHosted`, `termsOfUseHosted`, and `donation` are all
`https://example.com/...` placeholders, and every legal doc's contact line is
`support@example.com`. These are correctly marked (`// TODO 上线前填真实值` / "to be
replaced before launch"), so this is not a leak — but nothing mechanically blocks a
store submission with live placeholders. `donation` is handed to the OS browser and the
hosted URLs are App-Store-mandated, so shipping a placeholder is a plausible foot-gun.
**Fix:** Add a release gate (CI grep or release-mode assert) that fails if any
`LegalUrls.*` still contains `example.com` or the bundled legal assets still contain
`support@example.com`, so the launch checklist is enforced rather than trusted.

### IN-03: Sponsor launch failure swallowed with no diagnostic logging

**File:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:44-49`
**Issue:** `catch (_) { ok = false; }` discards the caught exception entirely. The
user-facing behavior (neutral SnackBar, never crash) is correct and intentional per
T-56-06, but the project coding-style rule is "never silently swallow errors — log
detailed error context." A real production launch failure (malformed `donation` URL,
no browser) leaves zero diagnostic trail.
**Fix:** Keep the neutral UX but capture the error for diagnostics, e.g.
`catch (e, st) { ok = false; debugPrint('sponsor launch failed: $e'); }` (or the
project's audit/log facility if one is wired for this layer).

### IN-04: Non-localized `'Error: $error'` in settings error branch (pre-existing, out of phase scope)

**File:** `lib/features/settings/presentation/screens/settings_screen.dart:165`
**Issue:** The `settingsAsync.when(error: ...)` branch renders a hardcoded English
`'Error: $error'`, which both violates the "all UI text via `S.of(context)`" rule and
interpolates a raw error object into the UI. Git history shows this line predates phase
56 (introduced by MOD-007, commit `05e2cc7f`, 2026-02-10); the only phase-56 change to
this file is the `LegalSponsorSection` + `Divider` insertion at lines 158-159. Recorded
for completeness because the file is in review scope; fix belongs to a settings/i18n
cleanup, not this phase.
**Fix:** Route the error branch through a localized ARB string via `S.of(context)` and
avoid interpolating the raw error object into user-facing text.

---

_Reviewed: 2026-07-01T20:15:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
