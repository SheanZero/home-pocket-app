---
phase: 22
slug: voice-one-step-integration-record-button-ux
status: verified
threats_open: 0
threats_total: 35
threats_closed: 35
asvs_level: 1
created: 2026-05-25
register_authored_at_plan_time: true
---

# Phase 22 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Phase 22 (Voice One-Step Integration + Record Button UX) introduced one new helper file (`voice_error_toast.dart`), modified `voice_input_screen.dart` + `transaction_details_form.dart`, added ARB error strings × ja/zh/en, and added widget + integration tests. No new packages installed. The phase formally authored a STRIDE register at plan time and includes the gap-closure plans 22-08/09/10 (G-01 + G-02 BLOCKER closure).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| User gesture → platform speech-to-text → app | User holds mic; OS-level speech engine streams partial/final transcripts via plugin callbacks | Audio (device-local) → text transcript (in-memory) |
| Platform speech engine → `_onError` / `_onStatus` callbacks | Native iOS/Android STT engine surfaces opaque English status codes and `errorMsg` strings | Opaque strings — never rendered raw to UI |
| Voice transcript → form widget (via 5 setters) | Parser-validated `VoiceParseResult` fields cross widget boundary into `TransactionDetailsForm` state | Amount (int), category (id), merchant (string), satisfaction (clamped int) |
| Form widget → Drift DB (via use case) | Saved transaction with `entry_source = 'voice'`; v17 schema CHECK constraint validates literal | Plaintext fields → encrypted-at-rest via `TransactionRepositoryImpl` (Phase 18) |
| App lifecycle (foreground → paused) | OS-initiated event breaking "user-still-holding" invariant | None — gestures cancelled, recording disposed |
| ARB file → generated S class | `flutter gen-l10n` consumes developer-authored ARB JSON | Locale strings — version-controlled, no untrusted input |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-22-01 | Tampering | ARB hostile locale override | accept | Version-controlled in git; no untrusted locale loading | closed |
| T-22-02 | Information Disclosure | Generated S-class strings | N/A | Public UI text only; no secrets | closed |
| T-22-SC | Tampering | npm/pip/cargo installs | N/A | Zero new packages this phase | closed |
| T-22-02-01 | Tampering | `_storeController.text = merchant` raw assignment | accept | Voice parser validated upstream (Phase 21); merchant strings encrypt at rest via `TransactionRepositoryImpl` | closed |
| T-22-02-02 | Information Disclosure | `updateNote(String)` raw transcript leak | mitigate | NO-OP in v1.3 voice flow (D-07). Auditor verified: `updateNote` defined at `transaction_details_form.dart:232`; zero production callers; `voice_input_screen.dart:360-370` explicitly omits the call with inline comment "updateNote intentionally absent: parser does not emit a discrete note in v1.3" | closed |
| T-22-02-03 | Tampering | `updateSatisfaction(int)` bypass | accept | `VoiceSatisfactionEstimator` (Phase 11) bounds 1-10 range; `.clamp(...)` enforces at setter | closed |
| T-22-03-01 | n/a | Static color constants | N/A | No data flow / no auth / no persistence | closed |
| T-22-04-01 | Tampering | Voice transcript → form fields | accept | `ParseVoiceInputUseCase` (Phase 21) enforces always-L2 category; form's `submit()` re-validates (validationError on null category / amount ≤ 0) | closed |
| T-22-04-02 | Information Disclosure | `_cancelRecordingAndDiscard` / `_onError` transcript logging | mitigate | Auditor verified: `_cancelRecordingAndDiscard` (voice_input_screen.dart:382-392) calls `_amountMerger?.dispose()` + `_speechService.cancel()` with NO log calls; `_onError` (lines 198-220) calls only `setState` + `showVoiceRecognitionErrorToast(context, errorMsg)`. Grep for `print|debugPrint|log(|logger` in voice_input_screen.dart returns zero matches | closed |
| T-22-04-03 | Information Disclosure | Voice transcript visible in widget tree | accept | In-memory only; never persisted unless saved as transaction note; note field encrypts at rest (Phase 18) | closed |
| T-22-04-04 | Tampering | Stuck recording on app pause (Pitfall 7) | mitigate | Auditor verified: `with WidgetsBindingObserver` (voice_input_screen.dart:55); `addObserver(this)` (line 147); `didChangeAppLifecycleState` (lines 801-808): `if (state == AppLifecycleState.paused && _isRecording) _cancelRecordingAndDiscard();`; `removeObserver` in dispose (line 826) | closed |
| T-22-04-05 | Tampering | Recognizer error mid-session desync (Pitfall 8) | mitigate | Auditor verified: `_onError` (212-218) sets `_isRecording=false`; `_onLongPressEnd` (250-252) guards `final start = _pressStart; _pressStart = null; if (start == null || !_isRecording) return;` — exact pattern declared in mitigation plan | closed |
| T-22-04-06 | Tampering | Satisfaction bypass via voice estimator | accept | `VoiceParseResult.estimatedSatisfaction` bounded by Phase 11 estimator; `updateSatisfaction` clamps at form setter | closed |
| T-22-05-01 | Information Disclosure | Mocked transcript strings in tests | accept | Test fixtures ('1千8百4十元 星巴克', '5千') are non-sensitive | closed |
| T-22-05-02 | n/a | Golden PNG visual snapshot | N/A | Mic button image contains no user data, fixed-palette gradient only | closed |
| T-22-06-01 | Tampering | Schema CHECK constraint on `entry_source` | mitigate | Auditor verified: `test/integration/features/accounting/voice_save_entry_source_test.dart` uses real `AppDatabase.forTesting()` (line 183), real `TransactionDao` + `TransactionRepositoryImpl` + `CreateTransactionUseCase` (lines 184, 242-252), save tap (line 345), DAO query (line 353), literal-string assertion (lines 356-357): `expect(rows.first.entrySource, 'voice', ...)` | closed |
| T-22-06-02 | Information Disclosure | Mocked encryption service in tests | accept | Test mock returns plaintext; production path unchanged; Phase 18 verifies real encryption | closed |
| T-22-07-01 | n/a | Phase verification execution | N/A | Read-only operations against repo state | closed |
| T-22-07-02 | n/a | Coverage measurement | N/A | Metric only; no leakage | closed |
| T-22-08-01 | Tampering | ARB hostile locale (gap-closure error strings) | accept | Mirrors T-22-01 disposition | closed |
| T-22-08-02 | Information Disclosure | Error message strings | N/A | Generic network/audio failure descriptions; no PII / no engine version / no IP | closed |
| T-22-09-01 | Information Disclosure | Raw platform `errorMsg` leak to UI | mitigate | Auditor verified: `voice_error_toast.dart:32-46` switches on `errorMsg`, maps to `l10n.voiceRecognitionError{Network,NoMatch,Audio,Unknown}` (ARB strings); `SoftToast(message: message, ...)` at line 56 receives only the locally-resolved ARB string. Raw `errorMsg` never reaches `SoftToast.message` — WR-05 closed | closed |
| T-22-09-02 | Denial of Service | Permanent error gates mic indefinitely | accept | Documented in `_onError` inline comment + 22-09-SUMMARY.md "Recovery path"; recovery requires screen rebuild / next `_initSpeechService` call; user is informed via the localized toast why mic is gated. In-screen retry is out of scope for gap closure | closed |
| T-22-09-03 | Tampering | `_onStatus` race with concurrent `_onLongPressEnd` | mitigate | Auditor verified: `_onStatus` (voice_input_screen.dart:185-189): `if (_pressStart != null) { _pressStart = null; unawaited(_stopRecordingAndCommit()); return; }` — `_pressStart` cleared on line 187 BEFORE `_stopRecordingAndCommit()` invoked on line 188. Subsequent `_onLongPressEnd` (lines 250-252) hits the `start == null` guard | closed |
| T-22-10-01 | Tampering | Test invokes production callbacks with crafted inputs | accept | Tests are the legitimate consumer of registered callbacks; fake's `onStatus`/`onError` references are exactly what the screen passed in | closed |
| T-22-10-02 | n/a | Test transcript fixture strings | N/A | Engineered fixtures, non-sensitive | closed |
| T-22-XX-SC (×10) | Tampering | npm/pip/cargo supply chain | N/A | Each plan declared zero new packages; verified by RESEARCH.md §Package Legitimacy Audit | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

**Totals: 35 threats — 35 closed (7 verified mitigations + 11 accepted + 17 N/A) — 0 open.**

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-22-01 | T-22-01 / T-22-08-01 | ARB files are git-version-controlled; no untrusted locale loading | Plan author | 2026-05-25 |
| AR-22-02 | T-22-02-01 | Merchant strings sourced from parser-validated voice transcript; encrypt-at-rest via Phase 18 `TransactionRepositoryImpl` | Plan author | 2026-05-25 |
| AR-22-03 | T-22-02-03 / T-22-04-06 | Satisfaction value bounded by Phase 11 estimator + `clamp` at form setter | Plan author | 2026-05-25 |
| AR-22-04 | T-22-04-01 | Voice transcript validated upstream by Phase 21 always-L2 contract; form re-validates at submit | Plan author | 2026-05-25 |
| AR-22-05 | T-22-04-03 | Voice transcript only in-memory; persisted only if user saves as note; note field encrypts at rest | Plan author | 2026-05-25 |
| AR-22-06 | T-22-05-01 / T-22-10-02 | Test fixture strings are engineered non-sensitive utterances | Plan author | 2026-05-25 |
| AR-22-07 | T-22-06-02 | Mocked encryption returns plaintext in tests; production crypto verified by Phase 18 dedicated tests | Plan author | 2026-05-25 |
| AR-22-08 | T-22-09-02 | Permanent-error mic gate intentional; recovery via screen rebuild; in-screen retry deferred to a future phase | Plan author | 2026-05-25 |
| AR-22-09 | T-22-10-01 | Tests are legitimate callback consumers; same callback identities as production registration | Plan author | 2026-05-25 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 35 | 35 | 0 | gsd-security-auditor (a8a52c0406fd3165c) |

### 2026-05-25 audit notes

- `register_authored_at_plan_time: true` — all 10 PLAN files contained `<threat_model>` blocks with STRIDE-classified threats.
- 7 `mitigate` threats verified by code-read against production files:
  - voice_input_screen.dart (832 lines)
  - voice_error_toast.dart (63 lines, new in 22-09)
  - transaction_details_form.dart (relevant setter surface only)
  - voice_save_entry_source_test.dart (integration test, real Drift DB)
- Adversarial sanity checks performed:
  - `updateNote` has zero production callers (grep across `lib/`)
  - Zero logging primitives (`print`, `debugPrint`, `log(`, `logger`) in voice_input_screen.dart — eliminates transcript leakage in cancel/error paths
  - Integration test uses real `AppDatabase.forTesting()` — CHECK constraint actually runs on insert
  - `_pressStart = null` strictly precedes `_stopRecordingAndCommit()` in `_onStatus` (race-idempotency invariant)
- All SUMMARY.md `## Threat Flags` / `## Threat Surface Scan` sections explicitly self-reported "None" / "No new threat surface" and all sub-IDs map to register entries — no unregistered flags.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
