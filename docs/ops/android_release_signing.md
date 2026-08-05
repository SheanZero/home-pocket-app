# Android release signing

Android release APKs and AABs are signed only with a production upload/app-signing key. The build never falls back to the Android Debug keystore. Debug and profile builds remain credential-free.

For a local release, keep the credentials in the ignored `android/key.properties` file. Start from `android/key.properties.example`; do not commit the copied file or the keystore.

```properties
storeFile=../app/upload-keystore.jks
storePassword=<secret>
keyAlias=<production-upload-key-alias>
keyPassword=<secret>
```

CI may instead inject all four values as masked secrets:

```text
ANDROID_KEYSTORE_PATH
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

`ANDROID_KEYSTORE_PATH` must point to the decoded keystore file. `key.properties` takes priority if a non-empty value is present, so do not leave stale local credentials in CI workspaces.

Before publishing, run:

```bash
cd android
./gradlew :app:verifyReleaseSigning
./gradlew :app:bundleRelease
```

`verifyReleaseSigning` rejects missing values, a missing keystore, a non-X.509 alias, and the `CN=Android Debug` certificate. It never prints passwords. `assembleRelease`, `bundleRelease`, and release packaging tasks depend on this validation automatically.
