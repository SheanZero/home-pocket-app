# Release Compatibility Report

No validated candidate attestation has been published.

The release owner publishes this surface only after a green, privacy-validated
`build/release_gate/final.json` result by running:

```bash
dart run scripts/release_gate.dart --publish-report --result=build/release_gate/final.json
```

Under RPT-A, that command renders the immutable tested parent candidate into
this file. The resulting metadata-only successor is verified on later `main`
runs and is never rewritten when its candidate-bound rendering is unchanged.
Android physical-device validation is not performed or claimed.
