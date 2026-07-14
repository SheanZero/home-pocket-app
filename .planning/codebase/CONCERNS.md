# Codebase Concerns

**Analysis Date:** 2026-07-14

Local-first, encrypted (SQLCipher + 4-layer crypto) Flutter/Dart family accounting app. Overall the codebase is disciplined (arch tests, zero-analyzer-warning gate, 80% coverage gate, structured migrations). Concerns below are concrete residual risks, not systemic rot. Severity: **HIGH** = ship-blocking or data/security risk; **MEDIUM** = fragility / correctness risk under change; **LOW** = cosmetic / hygiene.

---

## Tech Debt

**Placeholder legal/support URLs (HIGH — launch blocker):**
- Issue: Privacy, Terms, and Support URLs are `https://example.com/homepocket/*` placeholders explicitly tagged `TODO 上线前填真实值` (fill before launch).
- Files: `lib/core/config/legal_urls.dart` (lines 19/21/23)
- Impact: App Store / Play Store review rejection; broken legal links in Settings and the donate flow (DONATE-04).
- Fix approach: Replace with real hosted URLs before store submission. Consider an arch/CI test asserting no `example.com` in `legal_urls.dart` to make this a hard gate.

**Legacy text-style migration incomplete (LOW):**
- Issue: `// TODO: Remove after all screens are migrated to Wa-Modern` — a transitional text style kept alive during a design-system migration.
- Files: `lib/core/theme/app_text_styles.dart:180`
- Impact: Dead-code risk / two ways to style text; low functional risk.
- Fix approach: Complete Wa-Modern migration, then delete the legacy style and the TODO.

**Home GroupBar not wired (LOW):**
- Issue: `// TODO: Wire GroupBar with actual group data when available` — the home screen renders a group bar with stubbed/absent data pending family-sync group data.
- Files: `lib/features/home/presentation/screens/home_screen.dart:241`
- Impact: Feature gap only, not a defect. Blocked on family-sync (MOD-003, out of current scope).

**customIndices getter is decorative (MEDIUM — mitigated):**
- Issue: Drift's `customIndices` getter is NOT consumed by Drift's migrator; declaring an index there creates nothing. This previously shipped missing indexes.
- Files: `lib/data/app_database.dart` (`_createAllDeclaredIndexes()` at ~line 501; onCreate ~line 63; upgrade steps ~line 452/479/487)
- Impact: Silent missing-index → query performance regressions if a future dev adds an index only to `customIndices`.
- Current mitigation: FIXED repo-wide at schema **v23** — `_createAllDeclaredIndexes()` emits explicit `CREATE INDEX` in onCreate and each upgrade step, backed by a parse-declarations guard test. Any NEW table must call the same path; the getter alone is a trap.

---

## Known Bugs / Fragile Areas

**Voice-entry amount parsing / ITN (HIGH fragility):**
- Files: `lib/application/voice/voice_text_parser.dart` (596 lines), `voice_chunk_merger.dart`, `parse_voice_input_use_case.dart`, `voice_amount_notice_policy.dart`, `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` (603 lines), `voice_ptt_session_fill_orchestration.dart`, `voice_input_screen.dart`
- Why fragile: iOS zh ITN (inverse text normalization) corrupts spoken amounts BEFORE the STT string reaches Dart (e.g. 两千五百四十六 → "250046"). Defended by four independent layers (positional-value merge in scan, spaced-concat + open-hundreds parser in the merger, spaced-route signature detector, alternates auto-adopt + confirm SnackBar). Each layer guards a distinct variant; changing one silently breaks a variant not covered by the others. Numeral parsing for zh/ja and multi-digit Arabic runs has repeatedly regressed (99999 truncated to 9).
- Trigger: Continuous voice PTT entry, especially zh amounts with 百/千/万 place values, on real iOS hardware (not reproducible in unit tests — the corruption is upstream of the recognizer callback).
- Safe modification: Never edit one parsing layer without re-running the full voice test matrix across zh/ja/en variants. On-device UAT is mandatory; unit tests alone are insufficient.

**SQLCipher must win `dlsym` over system sqlite3 (HIGH):**
- Files: `ios/Podfile` `post_install` (line 38+, strip at line 63); `lib/infrastructure/crypto/database/encrypted_database.dart:47-49`
- Why fragile: The Podfile strips `-l"sqlite3"` from every Pod xcconfig. If removed, FirebaseMessaging (or any pod declaring `s.libraries = 'sqlite3'`) pulls in system `libsqlite3.tbd`, which wins `dlsym(RTLD_DEFAULT, "sqlite3_open")` over SQLCipher at runtime. `PRAGMA cipher_version` then returns empty and `encrypted_database.dart` throws `StateError('SQLCipher not loaded - encryption unavailable')` — the entire encrypted DB fails to open on device.
- Trigger: Removing/altering the strip, adding a pod that links system sqlite3, or a `pod install` regenerating xcconfigs without the strip applied.
- Safe modification: Preserve the strip block verbatim. No automated Podfile lint exists — relies on reviewer + on-device `PRAGMA cipher_version` check. Do NOT add `sqlite3_flutter_libs` (use only `sqlcipher_flutter_libs ^0.6.x`).

**iOS ML Kit simulator arch exclusion (MEDIUM):**
- Files: `ios/Podfile` (`EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`)
- Why fragile: Required for ML Kit to build on Apple-silicon simulators. Removal breaks simulator builds. Coupled to the same `post_install` block as the sqlite3 strip — both are easy to clobber together.
- Safe modification: Preserve alongside the sqlite3 strip when touching `post_install`.

**Dependency pin trio locked by transitive `win32` (MEDIUM):**
- Files: `pubspec.yaml` — `file_picker: ^11.0.2`, `package_info_plus: ^9.0.1`, `share_plus: ^12.0.2`; also `intl: 0.20.2` (pinned by flutter_localizations), `sqlcipher_flutter_libs: ^0.6.7`
- Why fragile: Bumping any one of the trio in isolation fails `flutter pub get` or breaks the iOS native build (`file_picker 12.x` ships a broken iOS Swift module; `package_info_plus 10.x` / `share_plus 13.x` demand `win32 ^6.x` incompatible with `file_picker 11.x`).
- Safe modification: Upgrade the trio together AND verify `flutter build ios --debug --no-codesign`. Never touch `intl` off 0.20.2.

---

## Security Considerations

**No custom crypto, but strip-dependent encryption (see SQLCipher item above):**
- Risk: A build-config regression silently disables at-rest encryption. The runtime guard (`StateError` on empty `cipher_version`) fails closed (app won't open) rather than silently writing plaintext — good — but the failure mode is a bricked app, not a subtle leak.
- Files: `lib/infrastructure/crypto/database/encrypted_database.dart`
- Current mitigation: Runtime `PRAGMA cipher_version` assertion. Recommendation: add a smoke test / CI step that boots the DB and asserts SQLCipher is active.

**Settings persisted in plaintext SharedPreferences (MEDIUM — by design, watch for creep):**
- Risk: `AppSettings` persists via plaintext SharedPreferences (one key per field), NOT SQLCipher, despite the app's encryption branding.
- Files: settings persistence layer (mirror of `biometricLockEnabled`)
- Current mitigation: Only non-secret preference flags belong here. Recommendation: NEVER store secrets (PINs, keys) in SharedPreferences — app-lock PIN must go through secure storage, not settings.

**Logging privacy is test-enforced (LOW — good posture):**
- `test/architecture/production_logging_privacy_test.dart` guards against logging sensitive data. Keep new logging out of crypto/amount paths.

---

## Architecture / Enforcement Gaps

**import_guard deny-mode yamls are INERT (MEDIUM):**
- Issue: ~40 `import_guard.yaml` files exist across `lib/`, but deny-mode rules match `package:` prefixes verbatim while this repo enforces `prefer_relative_imports`. Deny-mode guards therefore enforce NOTHING for intra-project imports. A green `dart run custom_lint` is NOT layer-compliance evidence.
- Files: `lib/import_guard.yaml`, `lib/application/import_guard.yaml`, `lib/data/import_guard.yaml`, `lib/infrastructure/import_guard.yaml`, and per-feature copies (the layer-boundary yamls now carry INERT headers pointing to the arch test).
- Impact: False sense of enforcement; only allow-mode subdirectory yamls actually enforce.
- Current mitigation: Real enforcement moved to `test/architecture/layer_import_rules_test.dart` (scans real relative-normalized imports).

**`*→data` direction NOT scanned by layer test (MEDIUM — residual blind spot):**
- Issue: `layer_import_rules_test.dart` covers domain/application/infrastructure directions and application→data, but does NOT audit the `*→data` direction generally. A violation like `infrastructure/security/providers.dart → app_database` breaks the yaml intent yet no mechanism catches it.
- Files: `test/architecture/layer_import_rules_test.dart`
- Impact: Layer violations toward the data layer can slip in undetected.
- Fix approach: Extend the test to scan `*→lib/data/` imports with a composition-root allowlist. Until then, audit `*→data` by hand-grep during review.

**Common Pitfalls only partially enforced (LOW — documented):**
- CLAUDE.md's "Common Pitfalls" list annotates each rule's enforcement status. Manually-checked-only items (no automated detection): hand-edits matching generator output (#1), general object mutation (#4), Podfile post_install integrity (#7), hardcoded widget defaults (#9), Drift index syntax/naming (#11), "forgot to call initialize()" (#12).
- Impact: These rely on reviewer diligence; regressions won't fail CI.

---

## Testing Gaps

**Golden tests are macOS-only; CI cannot pixel-match (MEDIUM):**
- Issue: Golden masters are macOS-baselined. On non-macOS (CI/ubuntu) exact comparison is impossible — font anti-aliasing alone yields 0.05–5.9% diffs.
- Files: `test/flutter_test_config.dart` (swaps in `BaselineExistenceGoldenComparator` when `!Platform.isMacOS`)
- Impact: CI verifies golden EXISTENCE only, not pixels. A visual regression that lands via CI-only review goes uncaught until a macOS run. Baselines must be regenerated on macOS.
- Safe practice: Update goldens only on macOS. Never `dart format` the whole `test/` tree (repo is not format-clean there). Never pipe `flutter test` through `tail` (masks exit code — the `-N` counter is truth).

**Voice parsing untestable on CI (see Voice item):** device-upstream ITN corruption cannot be reproduced in unit tests — real coverage requires on-device UAT.

**main.dart boot-provider characterization gap (MEDIUM):**
- Issue: A new boot-path provider read in `main.dart` breaks app-root characterization tests (onboarding-gate / data-reset-refresh) that don't override it. Scoped executor self-checks pass; only the FULL `flutter test` catches it.
- Files: `lib/main.dart`, app-root characterization tests
- Impact: Partial test runs give false green. Always run the full suite before claiming done.

---

## Complexity Hotspots

Large hand-written files (generated `app_localizations*` excluded) exceeding the 800-line guideline or approaching it — candidates for extraction under the "many small files" rule:

| File | Lines | Note |
|------|-------|------|
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | 1370 | Over 800 cap; core entry form |
| `lib/shared/constants/default_categories.dart` | 1273 | Data table (acceptable — pure data) |
| `lib/features/home/presentation/widgets/home_hero_card.dart` | 1155 | Over cap; complex custom-painted card |
| `lib/data/daos/analytics_dao.dart` | 799 | At cap; SQL-heavy |
| `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart` | 603 | Fragile voice logic (see above) |
| `lib/application/voice/voice_text_parser.dart` | 596 | Fragile voice logic (see above) |
| `lib/core/theme/app_palette.dart` | 628 | ~120 tokens light+dark (acceptable — palette) |

- Impact: `transaction_details_form.dart` and `home_hero_card.dart` exceed the 800-line hard cap and concentrate risk. Prioritize extracting sub-widgets/helpers.

---

## Dependencies at Risk

- **`file_picker` / `package_info_plus` / `share_plus` trio** — cannot be individually upgraded (win32 transitive conflict). See Fragile Areas. Migration requires coordinated bump + iOS build verification.
- **`intl 0.20.2`** — hard-pinned by `flutter_localizations`; do not change.
- **`sqlcipher_flutter_libs ^0.6.x`** — project has NOT migrated to `sqlite3` 3.x; `0.7.0+eol` is a do-nothing package. Migration is a larger effort tied to the Podfile strip.

---

## Missing / Deferred Features

- **Family Sync (MOD-003)** — out of scope; home GroupBar stubbed pending group data.
- **`.pen` design file on-disk flush** — deferred (Pencil MCP cannot flush in this env); ADR-019 is the authoritative palette record, not any committed `.pen` binary.
- **Real legal/support URLs** — see Tech Debt (launch blocker).

---

*Concerns audit: 2026-07-14*
