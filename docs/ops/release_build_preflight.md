# Release build preflight

Section 6.3 of the 2026-08-05 code-health report found that running the
device integration suite could leave the ignored native plugin registrants
referencing Flutter's dev-only `integration_test` plugin. A subsequent Android
release compilation then failed until the workspace was cleaned.

Always begin a release candidate build with the deterministic preflight:

```bash
bash scripts/release_preflight.sh --platform android
# On macOS, also run:
bash scripts/release_preflight.sh --platform ios
```

The preflight always performs, in order:

1. `flutter clean` and removal of only ignored Flutter-generated registrants;
2. `flutter pub get`;
3. optional Dart generation, only when this release changed ARB, Riverpod,
   Freezed, or Drift generator inputs;
4. credential-free profile smoke compilation; and
5. a fail-closed scan of the regenerated Android/iOS registrants for
   `integration_test`.

Pass `--regenerate` for step 3 when it is needed:

```bash
bash scripts/release_preflight.sh --platform all --regenerate
```

The default command never makes a production artifact. It deliberately uses
an unsigned/profile smoke compile so local and CI verification do not need
release secrets. Once it passes, production packaging is an explicit and
separate action:

```bash
bash scripts/release_preflight.sh --platform android --package
bash scripts/release_preflight.sh --platform ios --package
```

Android `--package` invokes `flutter build appbundle --release`; the existing
Gradle `verifyReleaseSigning` task still rejects missing credentials, missing
keystores, invalid aliases, and Android Debug certificates. This preflight
never supplies a debug-signing fallback. iOS `--package` likewise uses the
normal signed IPA flow; do not upload a `--no-codesign` smoke artifact.

Use `--dry-run` to review the exact ordered commands without changing the
workspace. A registrant scan failure is a build-chain failure, not an app
regression: fix it by rerunning the preflight, never by editing a generated
registrant.
