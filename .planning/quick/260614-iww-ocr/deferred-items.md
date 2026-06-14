# Deferred Items — Quick Task 260614-iww

## Out-of-scope pre-existing golden drift

- **Test:** `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart`
  → "idle mic button (ja, light) matches golden baseline"
- **Symptom:** Pixel diff 0.98% / 3222px against `goldens/voice_input_screen_mic_button_idle.png` (baseline dated 2026-06-03).
- **Why out of scope:** The golden captures ONLY the isolated `voice-mic-button` AnimatedContainer.
  This task's diff to `voice_input_screen.dart` never touches the mic-button render region, the
  VoiceWaveform, or any gradient/borderRadius (verified: `git diff` of the full task range over the
  mic-button region returns zero hits). The `continuousMode` field defaults to `false`, so the
  idle render is byte-identical to base. The diff is pre-existing macOS-baseline font/AA drift
  (matches the documented golden-CI-platform-gate pattern), not a behavior change.
- **Decision:** NOT re-baselined here — re-baselining an unrelated golden during this task would be
  scope creep. Re-baseline on macOS in a dedicated golden-refresh pass.
