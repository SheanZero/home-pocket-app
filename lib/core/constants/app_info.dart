/// Single source of truth for user-facing app metadata.
///
/// Keep [appVersion] in sync with the `version:` field in `pubspec.yaml`
/// (currently `0.1.0+1`; the build suffix is intentionally omitted here).
/// Hoisted out of the About tile and the OSS license page so the value lives
/// in exactly one place instead of drifting between duplicated literals
/// (WR-01 / WR-02, phase 56 review).
library;

/// The marketing version shown in About and the OSS license page.
const String appVersion = '0.1.0';
