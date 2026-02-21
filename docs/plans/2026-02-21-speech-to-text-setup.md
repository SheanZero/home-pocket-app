# speech_to_text Library Installation & Permission Setup

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install the `speech_to_text` Flutter package and configure all required platform permissions (iOS + Android) so the app can use device speech recognition.

**Architecture:** The `speech_to_text` package wraps native iOS Speech framework and Android SpeechRecognizer. It requires microphone access and speech recognition permissions on both platforms. The iOS Podfile also needs a minimum platform version bump to support the native pod.

**Tech Stack:** Flutter, speech_to_text ^7.3.0, iOS Info.plist, Android AndroidManifest.xml

---

### Task 1: Add speech_to_text dependency to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml:9-56` (dependencies section)

**Step 1: Add the package**

Add `speech_to_text` under the dependencies section, after the "File Operations" group:

```yaml
  # Speech Recognition
  speech_to_text: ^7.3.0
```

Insert this at line 50 (after `package_info_plus: ^8.1.3`), before the `# Database` comment block.

**Step 2: Run `flutter pub get`**

Run: `flutter pub get`
Expected: Resolves successfully, `speech_to_text 7.3.0` appears in output.

**Step 3: Verify installation**

Run: `flutter pub deps | grep speech_to_text`
Expected: Shows `speech_to_text 7.3.0` (or compatible version) in dependency tree.

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add speech_to_text dependency"
```

---

### Task 2: Add iOS microphone & speech recognition permissions

**Files:**
- Modify: `ios/Runner/Info.plist`

**Step 1: Add permission keys to Info.plist**

Add the following two keys inside the top-level `<dict>` block, before the closing `</dict>` tag (before line 69):

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>Home Pocket needs microphone access to record your voice for transaction entry.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Home Pocket uses speech recognition to convert your voice into transaction details.</string>
```

The final file should have these two new key-value pairs added just before `</dict></plist>`.

**Step 2: Verify the plist is valid**

Run: `plutil -lint ios/Runner/Info.plist`
Expected: `ios/Runner/Info.plist: OK`

**Step 3: Commit**

```bash
git add ios/Runner/Info.plist
git commit -m "feat(ios): add microphone and speech recognition permissions"
```

---

### Task 3: Add Android RECORD_AUDIO permission

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Add RECORD_AUDIO permission**

Add the following line inside `<manifest>`, before the `<application>` tag (after line 1):

```xml
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

The result should look like:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <application
        ...
```

**Step 2: Verify the manifest is well-formed**

Run: `xmllint --noout android/app/src/main/AndroidManifest.xml 2>&1 || echo "xmllint not available, skipping"`
Expected: No errors (or xmllint not available, which is fine).

**Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): add RECORD_AUDIO permission for speech recognition"
```

---

### Task 4: Set iOS minimum deployment target

**Files:**
- Modify: `ios/Podfile`

**Step 1: Uncomment and set the platform line**

The `ios/Podfile` line 2 currently reads:

```ruby
# platform :ios, '13.0'
```

Change it to (uncommented, with version 14.0 to match project target iOS 14+):

```ruby
platform :ios, '14.0'
```

**Step 2: Run pod install**

Run: `cd ios && pod install && cd ..`
Expected: Completes successfully. `speech_to_text` pod installed.

**Step 3: Verify pod was installed**

Run: `grep -i speech ios/Podfile.lock`
Expected: Shows `speech_to_text` in the lock file.

**Step 4: Commit**

```bash
git add ios/Podfile ios/Podfile.lock
git commit -m "chore(ios): set minimum deployment target to iOS 14.0"
```

---

### Task 5: Verify the setup compiles on both platforms

**Step 1: Run Flutter analyze**

Run: `flutter analyze`
Expected: No new issues introduced.

**Step 2: Verify iOS build (dry run)**

Run: `flutter build ios --no-codesign --debug 2>&1 | tail -5`
Expected: Build succeeds (or code-signing skip message).

**Step 3: Verify Android build (dry run)**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: Build succeeds.

**Step 4: Quick smoke test - import works**

Create a temporary test to verify the package is importable:

Run: `flutter test --no-pub test/unit/ 2>&1 | tail -3`
Expected: All existing tests still pass (no import conflicts).

**Step 5: Commit (if any cleanup was needed)**

If any fixes were needed during verification, commit them:

```bash
git add -A
git commit -m "fix: resolve speech_to_text integration issues"
```

---

## Summary of Changes

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `speech_to_text: ^7.3.0` |
| `ios/Runner/Info.plist` | Add `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` |
| `android/app/src/main/AndroidManifest.xml` | Add `RECORD_AUDIO` permission |
| `ios/Podfile` | Uncomment platform line, set `iOS 14.0` |

## Permission Descriptions (Localized)

The permission strings in Info.plist are in English. For a multilingual app, iOS shows these strings from `InfoPlist.strings` files. If localized permission descriptions are needed later, create:
- `ios/Runner/ja.lproj/InfoPlist.strings`
- `ios/Runner/zh-Hans.lproj/InfoPlist.strings`
- `ios/Runner/en.lproj/InfoPlist.strings`

This is optional and can be done in a follow-up task.
